package Function::Total;
use strict;
use warnings;

sub function {
  my ($array) = @_;
  my $length = scalar @$array;
  my $total = 0;

  foreach my $value (@$array) {
    if (!defined($value)) {
      $length--;
      next;
    }
#    if (ref $value eq 'ARRAY') {
#      $total += @{$value};
#    } else {
      $total += $value;
#    }
  }
  # short circuit if the array is empty.
  return undef if ($length == 0);

  return $total;
}

1;

