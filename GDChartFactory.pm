package GDChartFactory;

use strict;
use XML::Simple;

sub getInstance() {
  my $class = shift;
  my $type = shift;

  if (!defined $type || $type eq "") {
    $type = "LineChart"
  }

  my $location = "GDChart/" . $type . ".pm";
  my $class = "GDChart::" . $type;

  require $location;
  return $class->new(@_);
}

1;
