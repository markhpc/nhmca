package ColorFunction::Random;
use strict;
use warnings;

use Data::Dumper::Simple;

sub function {
  my ($value, $color, $alpha) = @_;

  return [255, 255, 255, 0] unless (defined $value);
  $alpha = 0 unless (defined $alpha);

  my $red = int(rand(255));
  my $green = int(rand(255));
  my $blue = int(rand(255));
  if ($red + $green + $blue > 512) {
    return function($value);
  }
  return [$red, $green, $blue, $alpha];
}

1;

