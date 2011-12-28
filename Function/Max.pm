package Function::Max;
use strict;
use warnings;

sub function {
  my ($array) = @_;
  my @sorted = sort {$a <=> $b}(@$array);
  return $sorted[-1];
}

1;

