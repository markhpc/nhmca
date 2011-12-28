package DataCollector::CollectlCPU;
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

  my $coresPerNode = $self->{_clusterSettings}->{cores_per_node};
  my $cores = (scalar keys %{$self->{_nodeHash}}) * $coresPerNode;

  for (my $i = 0; $i < $timespan / $collectlInterval; $i++) {
    for (my $j = 0; $j < $cores; $j++) {
      $data[$i][$j] = 0;
    }
  }

  my ($disk, $timestamp, $data);
  
  my $scale = 1 / $collectlInterval;
  my $dataColumn = $self->{_dataColumn};  

  my $results = $self->_executeQuery();
  foreach my $row (@$results) {
    my $core = $self->{_nodeHash}->{$row->{node}} * $coresPerNode + $row->{cpu};
    $data[int(($row->{timestamp} - $start) * $scale)][$core] += $row->{$dataColumn};
  }

  my $iData = $self->interpolate(\@data, $self->{_xmax});

  if (defined $self->{_mode} && $self->{_mode} eq "percent" || defined $self->{_dataScale}) {
    my $max = $self->getMax($iData);
    if ($max > 0) {
      for (my $i = 0; $i < @$iData; $i++) {
        for (my $j = 0; $j < $cores; $j++) {
          if (defined $self->{_mode} && $self->{_mode} eq "percent") {
            $iData->[$i][$j] = 100 * $iData->[$i][$j] / $max;
          }
        }
      }
    }
  }
  $self->{_data} = $iData;
}

sub interpolate {
  my ($self, $data, $newsize) = @_;
  my $factor = @$data / $newsize;
  my @newdata;

  for (my $i = 0; $i < $newsize; $i++) {
    $newdata[$i] = [];
  }

  my $cores = (scalar keys %{$self->{_nodeHash}}) * $self->{_clusterSettings}->{cores_per_node};
  for (my $j = 0; $j < $cores; $j++) {
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
  
sub getMax {
  my ($self, $iData) = @_;
  my $cores = (scalar keys %{$self->{_nodeHash}}) * $self->{_clusterSettings}->{cores_per_node};
  my $max = 0;

  for (my $i = 0; $i < @$iData; $i++) {
    for (my $j = 0; $j < $cores; $j++) {
      $max = $iData->[$i][$j] if ($iData->[$i][$j] > $max);
    }
  }
#  print $max . "\n";
  return $max;
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

  my $query = "SELECT * from `collectlcpudata` WHERE `system`='" . $cluster . "' AND `timestamp` >= '$start' AND `timestamp` < '$end'";
#  print "$query\n";
  return QueryCache->instance()->doQuery($query);
}

1;
