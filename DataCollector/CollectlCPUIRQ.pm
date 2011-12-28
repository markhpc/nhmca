package DataCollector::CollectlCPUIRQ;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlCPU';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "irq";
  $self->SUPER::initialize();
}

1;
