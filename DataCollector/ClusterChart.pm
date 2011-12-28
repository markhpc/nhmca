package DataCollector::ClusterChart;
use strict;
use warnings;

use Settings;
use Database;
use Data::Dumper::Simple;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $coresPerNode = $self->{_clusterSettings}->{cores_per_node};
  my $cores = (scalar keys %{$self->{_nodeHash}}) * $coresPerNode;

  my $data;
  for (my $i = 0; $i < $self->{_xmax}; $i++) {
    for (my $j = 0; $j < $cores; $j++) {
      $data->[$i][$j] = undef;
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
    foreach my $nodeName (@nodes) {
      my $node = $self->{_nodeHash}->{$nodeName};
      if (defined $node) {
        my $j = $self->_getFirstUnusedCore($data, $xstart, $node);
        for (my $i = $xstart; $i < $xend; $i++) {
          $data->[$i][$j] = $job->{jobid};
        }
      }
    }
  }
  $self->{_data} = $data;
}

sub _getFirstUnusedCore {
  my ($self, $data, $i, $node) = @_;
  my $coresPerNode = $self->{_clusterSettings}->{cores_per_node};

  my $offset = $node * $coresPerNode;
  for (my $j = 0; $j < $coresPerNode; $j++) {
    if (!defined $data->[$i][$offset+$j]) {
     return $offset+$j;
    }
  }
}

# For now at least we are going to ignore the requested mode and always show
# running utilization.
sub _getModeValues {
  return ("starttime", "endtime");
}

1;
