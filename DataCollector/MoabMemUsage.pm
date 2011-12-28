package DataCollector::MoabMemUsage;
use strict;
use warnings;

use Settings;
use Database;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $nodes = scalar keys %{$self->{_nodeHash}};

  my $data;
  for (my $i = 0; $i < $self->{_xmax}; $i++) {
    for (my $j = 0; $j < $nodes; $j++) {
      $data->[$i][$j] = 0;
    }
  }

  my $results = $self->_executeQuery();
  my ($begin, $end) = $self->_getModeValues();
  foreach my $job (@$results) {
    my $threshold = Settings->instance()->{graphs}->{queue_wait_threshold};
    if ($threshold > 0 && $job->{starttime} - $job->{subtime} > $threshold) {
      next;
    }

    my @nodes = split(/,/, $job->{nodelist});
    my $xstart = $self->_getXStart($job->{$begin});
    my $xend = $self->_getXEnd($job->{$end});
    my $mem = $job->{reqmem};
    $mem = 100 if ($mem == 0); 
    for (my $i = $xstart; $i < $xend; $i++) {
      foreach my $nodeName (@nodes) {
        my $node = $self->{_nodeHash}->{$nodeName};
        $data->[$i][$node] += $mem / 1024 if (defined $node);
      }
    }
  }
#  for (my $i = 0; $i < @data; $i++) {
#    for (my $j = 0; $j < $self->{_clusterSettings}->{nodes}; $j++) {
#      $data[$i][$j] = $data[$i][$j] / $nodeMem;
#    }
#  }
  $self->{_data} = $data;
}

sub getAverage {
  my $self = shift;
} 

# For now at least we are going to ignore the requested mode and always show
# running utilization.
sub _getModeValues {
  return ("starttime", "endtime");
}

1;
