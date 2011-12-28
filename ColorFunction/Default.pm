package ColorFunction::Default;
use strict;
use warnings;

use Common;

sub function {
  my ($value, $max, $color) = @_;

  if (!defined $value) {
     return [255, 255, 255, 127]
  }

  if (defined $color) {
    return Common::hex2rgb($color);
  }
  return [0, 0, 0, 95];
}

1;

