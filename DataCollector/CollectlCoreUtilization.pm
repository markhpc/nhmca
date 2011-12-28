package DataCollector::CollectlCoreUtilization;
use strict;
use warnings;

use Settings;
use Database;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $coreCount = $self->{_clusterSettings}->{nodes} * $self->{_clusterSettings}->{cores_per_node};
  my $start = $self->{_startEpoch};
  my $timespan = ($self->{_endEpoch} - $self->{_startEpoch});
  my $collectlinterval = 60;
  my @data;

  for (my $i = 0; $i < $timespan / $collectlinterval; $i++) {
    $data[$i] = 0;
  }

  my $results = $self->_executeQuery();
  foreach my $record (@$results) {   
    my $xpos = int(($record->{timestamp} - $start) / $collectlinterval);
    $data[$xpos] += $record->{percent};
  }

  my @iData = $self->interpolate(\@data, $self->{_xmax});
  for (my $i = 0; $i < @iData; $i++) {
    $iData[$i] = $iData[$i] / $coreCount;
  }
  $self->{_data} = \@iData;
}


# Linear interpolation routine
sub interpolate {
  my ($self, $data, $newsize) = @_;
  my $factor = @$data / $newsize;
  my @newdata;

  for (my $i = 0; $i < $newsize; $i++) {
    my $pos = $factor * $i;
    my $low = int ($pos);
    my $high = $low + 1;
    my $remainder = $pos - $low;

    my $lowVal = 0;
    my $highVal = 0;
    if ($low >= 0 && $low < @$data) {
      $lowVal = $data->[$low];
    }
    if ($high >= 0 && $high < @$data) {
      $highVal = $data->[$high];
    } else {
      $highVal = $data->[$low];
    }
    $newdata[$i] = ($highVal * $remainder) + ($lowVal * (1 - $remainder));
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
  my $start = $self->{_startEpoch};
  my $end = $self->{_endEpoch};
  my $dbh = Database->instance()->getDbh();
  my $cluster = $self->{_cluster};

  my $query = "SELECT timestamp,percent from collectlprocessdata WHERE system='" . $cluster . "' AND timestamp >= '$start' AND timestamp < '$end'";
#  print "$query\n";
  return $dbh->selectall_arrayref($query, {Slice => {}});
}

1;
