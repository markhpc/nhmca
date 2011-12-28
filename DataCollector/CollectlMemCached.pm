package DataCollector::CollectlMemCached;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlMem';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "memcached";
  $self->SUPER::initialize();
}

1;
