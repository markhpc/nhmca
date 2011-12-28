package DataCollector::CollectlMemCommit;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlMem';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "memcommit";
  $self->SUPER::initialize();
}

1;
