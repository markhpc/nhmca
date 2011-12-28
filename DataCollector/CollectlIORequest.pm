package DataCollector::CollectlIORequest;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlIO';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "request";
  $self->SUPER::initialize();
}

1;
