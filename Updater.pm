package Updater;

use strict;
use warnings;

use Data::Dumper::Simple;

use Settings;
use LogParserFactory;

my $settings = Settings->instance();

sub new {
  my ($class) = @_;
  my $self = {
  };
  bless $self, $class;

  $self->{_clusterSettings} = Common::getCluster();
  return $self;
}

sub update {
  my ($self) = @_;
  foreach my $log (@{$self->{_clusterSettings}->{log}}) {
    my $clusterName = $settings->{parameters}->{cluster};
    my $parser = LogParserFactory->getInstance($log->{parser}, $clusterName, $log->{logdir});
    print "Updating " . $log->{parser} . " records...\n";
    $parser->parseLogs();
    print "\n";
  }
}

1;

