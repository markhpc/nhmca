package FunctionFactory;

use strict;
use XML::Simple;

sub getFunction() {
  my $class = shift;
  my $type = shift;

  if (!defined $type || $type eq "") {
    $type = "Default"
  }

  my $location = "Function/" . $type . ".pm";
  my $function = "Function::" . $type . "::function";

  require $location;
  return \&$function;
}

1;
