package DataCollector::CollectlMem;
use strict;
use warnings;

use Settings;
use Database;
use Data::Dumper::Simple;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $start = $self->{_startEpoch};
  my $timespan = ($self->{_endEpoch} - $self->{_startEpoch});
  my $collectlInterval = 10;

  my @data;

  $self->_buildNodeHash();
  my $nodes = scalar keys %{$self->{_nodeHash}};

  for (my $i = 0; $i < $timespan / $collectlInterval; $i++) {
    for (my $j = 0; $j < $nodes; $j++) {
      $data[$i][$j] = 0;
    }
  }

  my ($disk, $timestamp, $data);
  
  my $scale = 1 / $collectlInterval;
  my $dataColumn = $self->{_dataColumn};  

  my $results = $self->_executeQuery();
  foreach my $row (@$results) {
    my $node = $self->{_nodeHash}->{$row->{node}};
    $data[int(($row->{timestamp} - $start) * $scale)][$node] += $row->{$dataColumn} / 1024;
  }

  $self->{_data} = $self->interpolate(\@data, $self->{_xmax});
}

sub interpolate {
  my ($self, $data, $newsize) = @_;
  my $factor = @$data / $newsize;
  my @newdata;

  for (my $i = 0; $i < $newsize; $i++) {
    $newdata[$i] = [];
  }

  my $nodes = scalar keys %{$self->{_nodeHash}};
  for (my $j = 0; $j < $nodes; $j++) {
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
  return \@newdata;
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
  my $start = $self->{_startEpoch};
  my $end = $self->{_endEpoch};
  my $dbh = Database->instance()->getDbh();
  my $cluster = Settings->instance()->{parameters}->{cluster};

  my $query = "SELECT * from `collectlmemdata` WHERE `system`='" . $cluster . "' AND `timestamp` >= '$start' AND `timestamp` < '$end'";
#  print "$query\n";
  return QueryCache->instance()->doQuery($query);
}

1;
