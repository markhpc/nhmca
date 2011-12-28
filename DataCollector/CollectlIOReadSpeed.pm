package DataCollector::CollectlIOReadSpeed;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlIO';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "rkbytes";
  $self->{_dataScale} = 1 / 1024;
  $self->SUPER::initialize();
}

1;
