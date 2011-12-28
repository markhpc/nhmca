package DataCollector::ScatterPlot;
use strict;
use warnings;

use Settings;
use Database;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;

  my $xmax = $self->_getXposByEpoch($self->{_endDT}->epoch());  
  my @data;
  for (my $i = 0; $i < $xmax; $i++) {
    $data[$i] = [];
  }

  my $results = $self->_executeQuery();
  my ($begin, $end) = $self->_getModeValues();
  foreach my $job (@$results) {
    my $threshold = Settings->instance()->{graphs}->{queue_wait_threshold};
    if ($threshold > 0 && $job->{starttime} - $job->{subtime} > $threshold) {
      next;
    }

    my @nodes = $self->_splitNodeList($job->{nodelist});
    my $xstart = $self->_getXStart($job->{$begin});
    my $xend = $self->_getXEnd($job->{$end});

    my $jobData = {"starttime" => $job->{starttime},
                   "wclimit" => $job->{wclimit} / 3600,
                   "cores" => scalar @nodes,
                   "queueWait" => ($job->{starttime} - $job->{subtime}) / 3600};

    my $index = $self->_getXposByEpoch($job->{starttime});
    if ($index < $xmax && $job->{starttime} < $job->{endtime}) {
      push (@{$data[$index]}, $jobData);
    }
  }
  $self->{_data} = \@data;
}

1;
