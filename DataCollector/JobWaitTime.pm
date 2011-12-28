package DataCollector::JobWaitTime;
use strict;
use warnings;

use Settings;
use Database;
use Common;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;

  my $xmax = $self->_getXposByEpoch($self->{_endEpoch});  
  my @data;
  for (my $i = 0; $i < $xmax; $i++) {
    $data[$i] = [];
  }

  my $results = $self->_executeQuery();
  my ($begin, $end) = $self->_getModeValues();
  my $threshold = Settings->instance()->{graphs}->{queue_wait_threshold};

  foreach my $job (@$results) {
    if ($threshold > 0 && $job->{starttime} - $job->{subtime} > $threshold) {
      next;
    }

    my $xstart = $self->_getXStart($job->{$begin});
    my $xend = $self->_getXEnd($job->{$end});
    for (my $i = $xstart; $i < $xend; $i++) {
      my $epoch = $self->_getEpochFromXpos($i);
      $epoch = $job->{$begin} if ($job->{$begin} > $job->{subtime});
      push(@{$data[$i]}, ($epoch - $job->{subtime}) / 3600); 
    }
  }
  $self->{_data} = \@data;
}

1;
