package Function::Utilization;
use strict;
use warnings;
use Settings;
use Data::Dumper::Simple;

sub function {
  my $settings = Settings->instance();
  my $nodes = 0;
  my $coresPerNode = 0;
  my $cpuCount = @_;

  foreach my $cluster (@{$settings->{cluster}}) {
    if ($settings->{graphs}->{clustername} eq $cluster->{name}) {
      $nodes = $cluster->{nodes};
      $coresPerNode = $cluster->{cores_per_node};
    }
  }

#  my %count = ();
#  foreach my $node (@_) {
#    if (!exists($count{$node})) {
#      $count{$node} = 1;
#      $cpuCount++;
#    } elsif ($count{$node} < $coresPerNode) {
#      $count{$node} += 1;
#      $cpuCount++;
#    }
#  }
#  print Dumper(%count);
  if ($nodes * $coresPerNode  == 0) {
    return undef;
  }
  print $cpuCount . "\n";
  return 100 * $cpuCount / ($nodes * $coresPerNode);

}

1;

