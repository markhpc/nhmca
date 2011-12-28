package ColorFunctionFactory;

use strict;
use XML::Simple;

sub getFunction() {
  my $class = shift;
  my $type = shift;

  if (!defined $type || $type eq "") {
    $type = "Default"
  }

  my $location = "ColorFunction/" . $type . ".pm";
  my $function = "ColorFunction::" . $type . "::function";

  require $location;
  return \&$function;
}

1;
