# optimized implementation of a function to find the average of numbers in an
# array.  This only works on positive integers but is very fast!
package Function::CoresToNodes;
use strict;
use warnings;

use Settings;
use Common;

my $coresPerNode = Common::getCluster()->{cores_per_node};

sub function {
  my ($array) = @_;

  return [] unless (defined @$array && scalar @$array > 0);
  my $retArray = [];
  for (my $i = 0; $i < scalar @$array; $i += $coresPerNode) {
    my $j = $i + $coresPerNode - 1;
    my $total = unpack "%123d*" , pack( "d*", @$array[$i..$j]);
    push (@$retArray, $total);
  }
  return $retArray;;
}

1;

