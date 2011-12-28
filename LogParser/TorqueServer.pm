package LogParser::TorqueServer;

use strict;
use File::stat;

use Database;
use Settings;
use DateTime;
use Data::Dumper::Simple;
use base 'LogParser';

sub initialize {
  my ($self) = @_;

  $self->SUPER::initialize();
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS nodestatusrecords (system, node, time, status, PRIMARY KEY(system, node, time))"; 
  $self->{_uphash} = {};
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};
  my $cluster = $self->{_cluster};

  open FILE, "$logfile" or die $!;
  my $count = 0;
  while (<FILE>) {
    my $uphash = $self->{_uphash};
    
    if ($_ =~ m/set\: state/) {
      my @line = split(/;/, $_);
      my $node = $line[4];
      my ($date, $time) = split(/ /, $line[0]);
      my ($month, $day, $year) = split(/\//, $date);
      my ($hour, $minute, $second) = split(/\:/, $time);
      my $dt = DateTime->new(year => $year, month=> $month, day=>$day, hour=>$hour, minute=>$minute, second=>$second, time_zone=>'America/Chicago');

      my (undef,undef,undef,$state) = split(/ /, $line[5]);

      $uphash->{$node} = [] if (!(exists $uphash->{$node}));

      $dbh->do("REPLACE INTO nodestatusrecords VALUES('$cluster', '$node', '" . $dt->epoch() . "', '$state')");
      $count++;
    }
  }
  return $count;
}

1;

