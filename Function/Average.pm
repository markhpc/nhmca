# optimized implementation of a function to find the average of numbers in an
# array.  This only works on positive integers but is very fast!
package Function::Average;
use strict;
use warnings;

sub function {
  my ($array) = @_;

  return undef unless (defined @$array && scalar @$array > 0);
  my $total = unpack "%123d*" , pack( "d*", @$array);
  return scalar ($total / scalar @$array);
}

1;

