package DataCollector::CollectlMemBuffered;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlMem';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "membuff";
  $self->SUPER::initialize();
}

1;
