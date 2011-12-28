package ColorFunction::Opacity;
use strict;
use warnings;

use Common;

sub function {
  my ($value, $max, $color) = @_;

  if (!defined $value || $value eq "" || $value <= 0) {
     return [255, 255, 255, 127];
  }

#  $value = 0 if ($value < 0);
#  $value = 100 if ($value > 100);
  $value = int(127 * $value / $max);
  my $alpha = 127 - $value;
  my $rgbColor = Common::hex2rgb($color); 
  $rgbColor->[3] = $alpha;

  return $rgbColor;
}

1;

