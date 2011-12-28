package DataCollector::CollectlIOWriteSpeed;
use strict;
use warnings;

use Settings;
use Database;
use Data::Dumper::Simple;
use base 'DataCollector::CollectlIO';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "wkbytes";
  $self->{_dataScale} = 1/1024;
  $self->SUPER::initialize();
}

1;
