package DataCollector::CollectlCPUWait;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlCPU';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "wait";
  $self->SUPER::initialize();
}

1;
