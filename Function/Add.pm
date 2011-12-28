package Function::Add;
use strict;
use warnings;

use Data::Dumper::Simple;

sub function {
  my ($array1, $array2) = @_;
#  print "@_\n";
  my $array = [];
  for (my $i = 0; $i < scalar @$array1; $i++) {
    $array->[$i] = $array1->[$i] + $array2->[$i];
  }
  return $array;
}

#sub function {
#  my ($class, $value1, $value2) = @_;
#  my $data = helper($value1, $value2);
#  return $data;
#}
#
#sub helper {
#  my ($value1, $value2, $iter) = @_;
#  if (ref $value1 eq 'ARRAY') {
#    my @array;
#    for (my $i = 0; $i < @$value1; $i++) {
#      push (@array, helper($value1->[$i], $value2->[$i], $i));
#    }
#    return \@array;
#  } else {
#    return ($value1 + $value2) if (defined $value1 && defined $value2);
#    return 0;
#  }
#}

1;

