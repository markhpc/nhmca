package DataCollector::JobCount;
use strict;
use warnings;

use Settings;
use Database;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;

  my $xmax = $self->_getXposByEpoch($self->{_endEpoch});  
  my @data;
  for (my $i = 0; $i < $xmax; $i++) {
    $data[$i] = 0;
  }

  my $results = $self->_executeQuery();
  my ($begin, $end) = $self->_getModeValues();
  foreach my $job (@$results) {
    my $threshold = Settings->instance()->{graphs}->{queue_wait_threshold};
    if ($threshold > 0 && $job->{starttime} - $job->{subtime} > $threshold) {
      next;
    }

    my $xstart = $self->_getXStart($job->{$begin});
    my $xend = $self->_getXEnd($job->{$end});
    for (my $i = $xstart; $i < $xend; $i++) {
      $data[$i]++;
    }
  }
  $self->{_data} = \@data;
}

1;
