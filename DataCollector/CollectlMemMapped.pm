package DataCollector::CollectlMemMapped;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlMem';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "memmapped";
  $self->SUPER::initialize();
}

1;
