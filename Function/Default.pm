package Function::Default;
use strict;
use warnings;
use Data::Dumper::Simple;

sub function {
  my ($array) = @_;

  return $array;
#  if (!(ref $array eq 'ARRAY')) {
#    return $array;
#  }
#  return scalar @$array;
}

1;

