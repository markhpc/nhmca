package DataCollector::CollectlIO;
use strict;
use warnings;

use Settings;
use Database;
use Data::Dumper::Simple;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $diskIO = $self->{_clusterSettings}->{disk_speed};
  my $start = $self->{_startEpoch};
  my $timespan = ($self->{_endEpoch} - $self->{_startEpoch});
  my $collectlInterval = 10;
  my @data;

  my $diskHash = $self->_buildDiskHash();

  my $disks = 0;
  foreach my $nodeKey (keys %$diskHash) {
    $disks += scalar keys %{$diskHash->{$nodeKey}};
  }
  $self->{_disks} = $disks;
#  print "Disk: $disks\n";
  for (my $i = 0; $i < $timespan / $collectlInterval; $i++) {
    for (my $j = 0; $j < $disks; $j++) {
      $data[$i][$j] = 0;
    }
  }

  my $max_rows = 10000;
  my $scale = 1 / $collectlInterval;
  my $dataColumn = $self->{_dataColumn};  
  my $dataScale = $self->{_dataScale} || 1;
  my $results = $self->_executeQuery();
  foreach my $row (@$results) {
    my $node = $row->{node};
    my $disk = $row->{disk};
#    print "node: $node, disk: $disk, value: " . $self->{_diskHash}->{$node}->{$disk} . "\n";
    if (exists $self->{_diskHash}->{$node}->{$disk}) {
      $data[int(($row->{timestamp} - $start) * $scale)][$self->{_diskHash}->{$node}->{$disk}] += $row->{$dataColumn};
    }
  }

  my $iData = $self->interpolate(\@data, $self->{_xmax});

  if (defined $self->{_mode} && $self->{_mode} eq "percent" || defined $self->{_dataScale}) {
    my $max = $self->getMax($iData) * $dataScale;
    if ($max > 0) {
      for (my $i = 0; $i < @$iData; $i++) {
        for (my $j = 0; $j < $disks; $j++) {
          if (defined $self->{_dataScale}) {
            $iData->[$i][$j] = $iData->[$i][$j] * $dataScale;
          }
          if (defined $self->{_mode} && $self->{_mode} eq "percent") {
            $iData->[$i][$j] = 100 * $iData->[$i][$j] / $max;
          }
        }
      }
    }
  }
  $self->{_data} = $iData;
#  print Dumper($iData);
}

sub interpolate {
  my ($self, $data, $newsize) = @_;
  my $factor = @$data / $newsize;
  my @newdata;

  for (my $i = 0; $i < $newsize; $i++) {
    $newdata[$i] = [];
  }

  my $disks = $self->{_disks}; 
  for (my $j = 0; $j < $disks; $j++) {
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
  my $max = 0;
  my $disks = $self->{_disks};

  for (my $i = 0; $i < @$iData; $i++) {
    for (my $j = 0; $j < $disks; $j++) {
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

  my $query = "SELECT * from `collectliodata` WHERE `system`='" . $cluster . "' AND `timestamp` >= '$start' AND `timestamp` < '$end'";
  return QueryCache->instance()->doQuery($query);
}

1;
