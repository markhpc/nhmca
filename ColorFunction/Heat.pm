package ColorFunction::Heat;
use strict;
use warnings;

use Common;

sub function {
  my ($value,$max) = @_;

  my $alpha = 47;
  if (!defined $max || $max == 0 || !defined $value || $value eq "" || $value < 0) {
     return [0, 0, 0, $alpha];
  }

  $value = 255 * $value / $max;

  my ($red, $green, $blue) = (0, 0, 0);
  if ($value < 51) {
    ($red, $green, $blue) = (0, 0, $value * 5);
  } elsif ($value < 102) {
    ($red, $green, $blue) = (0, ($value - 51) * 5, 255);
  } elsif ($value < 153) {
    ($red, $green, $blue) = (0, 255, 255 - (($value - 102) * 5));
  } elsif ($value < 204) {
    ($red, $green, $blue) = ((($value - 153) * 5), 255, 0);
  } else {
    ($red, $green, $blue) = (255, 255 - (($value - 204) * 5), 0);
  }
  return [$red, $green, $blue, $alpha];  
}

1;

