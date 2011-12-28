package DataCollectorFactory;

use strict;
use XML::Simple;

my $hash = {};

sub getInstance() {
  my $class = shift;
  my $type = shift;

  if (!defined $type || $type eq "") {
    $type = "Default"
  }

  my $location = "DataCollector/" . $type . ".pm";
  my $newClass = "DataCollector::" . $type;

#  if (!exists $hash->{$newClass}) {
#    require $location;
#    $hash->{$newClass} = $newClass->new(@_);
#  }
#  return $hash->{$newClass};
  require $location;
  return $newClass->new(@_);
}

1;
