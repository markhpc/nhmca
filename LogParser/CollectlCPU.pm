package LogParser::CollectlCPU;

use strict;
use File::stat;

use Database;
use Settings;
use Data::Dumper::Simple;
use DateTime;
use Common;
use base 'LogParser::Collectl';

sub initialize {
  my ($self) = @_;
  $self->SUPER::initialize();
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS collectlcpudata (timestamp, system, node, cpu INTEGER, usage INTEGER, irq INTEGER, wait INTEGER, interrupts INTEGER, PRIMARY KEY (timestamp, system, node, cpu))"; 
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};
  my $file = $self->extractLog($logfile);
  my $node = $self->getNodeFromFilename($logfile);

  open FILE, "/usr/bin/collectl -P -sCj -p $file |" or die $!;

  $dbh->do('BEGIN');
  my $count = 0;
  while (<FILE>) {
    $count++;
    next if ($count == 1);
    my $line = $_;
    chomp($line);
    my @line = split(/ +/, $line);
    my $timestamp = $line[0] . " " . $line[1];
    my $epoch = $self->{_tsCache}->{$timestamp} || $self->getEpochFromTimestamp($timestamp);
    my $cpu = 0; 
    for (my $i = 11; $i < scalar @line; $i+=10) {
      my $interrupts = $line[$i];
      my $usage = 100 - $line[$i-2];
      my $irq = $line[$i-5];
      my $wait = $line[$i-6];
      my $statement = "REPLACE INTO collectlcpudata VALUES ('$epoch', '$name', '$node', '$cpu', '$usage', '$irq', '$wait', '$interrupts')";
      $dbh->do($statement);
      $cpu++;
    }
  }
  $dbh->do('COMMIT');
  unlink $file;
  return $count;
}

1;

