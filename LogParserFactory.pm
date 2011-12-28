package LogParserFactory;

use strict;
use XML::Simple;

sub getInstance() {
  my $class = shift;
  my $type = shift;

  if (!defined $type || $type eq "") {
    return undef; 
  }

  my $location = "LogParser/" . $type . ".pm";
  my $newClass = "LogParser::" . $type;

  require $location;
  return $newClass->new(@_);
}

1;
