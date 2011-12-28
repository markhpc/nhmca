package DataCollector::Default;
use strict;
use warnings;

use Settings;
use Database;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  $self->{_data} = [];
}

1;
