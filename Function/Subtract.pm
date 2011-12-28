package Function::Subtract;
use strict;
use warnings;

use Data::Dumper::Simple;

sub function {
  my ($class, $value1, $value2) = @_;
  my $data = helper($value1, $value2);
#  print Dumper($data);
  return $data;
}

sub helper {
  my ($value1, $value2, $iter) = @_;
#  print Dumper($value1);  
#  print Dumper($value2);
  if (ref $value1 eq 'ARRAY') {
    my @array;
    for (my $i = 0; $i < @$value1; $i++) {
      push (@array, helper($value1->[$i], $value2->[$i], $i));
    }
    return \@array;
  } else {
    print "iter: $iter, $value1, $value2, " . ($value1 - $value2) . "\n";
    return ($value1 - $value2);
  }
}

1;

