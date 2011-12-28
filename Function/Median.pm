package Function::Median;
use strict;
use warnings;

sub function {
  my ($array) = @_;
  return undef if (@$array == 0);
  my @sorted = sort {$a <=> $b}(@$array);
  my $mid = int(@sorted / 2 - .5);

  return $sorted[$mid];
}

1;

