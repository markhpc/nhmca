package Function::WeightedAverage;
use strict;
use warnings;

sub function {
  my ($array, $weights) = @_;

  return undef unless (defined @$array && scalar @$array > 0 && defined @$weights && scalar @$weights == scalar @$array);
  my $total = 0;
  my $weightTotal = 0;
  for (my $i = 0; $i < scalar @$array; $i++) {
    $total += ($array->[$i] * $weights->[$i]);
    $weightTotal += $weights->[$i];
  }
  if ($weightTotal == 0) {
    return undef;
  }
  return $total / $weightTotal;
}

1;

