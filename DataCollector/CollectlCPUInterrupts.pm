package DataCollector::CollectlCPUInterrupts;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlCPU';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "interrupts";
  $self->SUPER::initialize();
}

1;
