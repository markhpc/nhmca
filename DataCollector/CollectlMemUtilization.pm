package DataCollector::CollectlMemUtilization;
use strict;
use warnings;

use Settings;
use Database;
use Data::Dumper::Simple;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $nodeMem = $self->{_clusterSettings}->{mem_per_node};
  my $start = $self->{_startEpoch};
  my $timespan = ($self->{_endEpoch} - $self->{_startEpoch});
  my $collectlinterval = 60;
  my @data;

  $self->_buildNodeHash();
#  print Dumper($self->{_nodeHash});
  for (my $i = 0; $i < $timespan / $collectlinterval; $i++) {
    for (my $j = 0; $j < $self->{_clusterSettings}->{nodes}; $j++) {
      $data[$i][$j] = 0;
    }
  }

  my $results = $self->_executeQuery();
#  print "timespan: $timespan xmax: $xmax\n";
#  print "Results: " . @$results . "\n";
  foreach my $record (@$results) {   
    my $xpos = int(($record->{timestamp} - $start) / $collectlinterval);
    my $node = $self->{_nodeHash}->{$record->{node}};
    $data[$xpos][$node] += $record->{vmsize};
  }

  my @iData = $self->interpolate(\@data, $self->{_xmax});
  for (my $i = 0; $i < @iData; $i++) {
    for (my $j = 0; $j < $self->{_clusterSettings}->{nodes}; $j++) {
      $iData[$i][$j] = 100 * $iData[$i][$j] / ($nodeMem * 1024);
    }
  }
  $self->{_data} = \@iData;
}

sub interpolate {
  my ($self, $data, $newsize) = @_;
  my $factor = @$data / $newsize;
  my @newdata;
  for (my $i = 0; $i < $newsize; $i++) {
    $newdata[$i] = [];
  }

  for (my $j = 0; $j < $self->{_clusterSettings}->{nodes}; $j++) {
    for (my $i = 0; $i < $newsize; $i++) {
      my $pos = $factor * $i;
      my $low = int ($pos);
      my $high = $low + 1;
      my $remainder = $pos - $low;

      my $lowVal = 0;
      my $highVal = 0;
      if ($low >= 0 && $low < @$data) {
        $lowVal = $data->[$low][$j];
      }
      if ($high >= 0 && $high < @$data) {
        $highVal = $data->[$high][$j];
      } else {
        $highVal = $data->[$low][$j];
      }
      $newdata[$i][$j] = ($highVal * $remainder) + ($lowVal * (1 - $remainder));
    }
  }
  return @newdata;
} 
  

sub getAverage {
  my $self = shift;
} 

# For now at least we are going to ignore the requested mode and always show
# running utilization.
sub _getModeValues {
  return ("starttime", "endtime");
}

sub _executeQuery {
  my ($self) = @_;
  my $start = $self->{_startDT}->epoch();
  my $end = $self->{_endDT}->epoch();
  my $dbh = Database->instance()->getDbh();
  my $cluster = $self->{_cluster};

  my $query = "SELECT node,timestamp,vmsize from collectlprocessdata WHERE system='" . $cluster . "' AND timestamp >= '$start' AND timestamp < '$end'";
#  print "$query\n";
  return $dbh->selectall_arrayref($query, {Slice => {}});
}

1;
