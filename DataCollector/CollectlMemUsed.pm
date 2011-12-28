package DataCollector::CollectlMemUsed;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlMem';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "memused";
  $self->SUPER::initialize();
}

1;
