package DataCollector::CollectlCPUUsage;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlCPU';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "usage";
  $self->SUPER::initialize();
}

1;
