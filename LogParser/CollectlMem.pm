package LogParser::CollectlMem;

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
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS collectlmemdata (timestamp, system, node, memused INTEGER, membuff INTEGER, memcached INTEGER, memmapped INTEGER, memcommit INTEGER, swapused INTEGER, PRIMARY KEY (timestamp, system, node))";
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};
  my $file = $self->extractLog($logfile);
  my $node = $self->getNodeFromFilename($logfile);

  open FILE, "/usr/bin/collectl -P -sm -p $file |" or die $!;

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
    my $memused = $line[3];
    my $membuff = $line[6];
    my $memcached = $line[7];
    my $memmapped = $line[9];
    my $memcommit = $line[10];
    my $swapused = $line[12];
    my $statement = "REPLACE INTO collectlmemdata VALUES ('$epoch', '$name', '$node', '$memused', '$membuff', '$memcached', '$memmapped', '$memcommit', '$swapused')";
    $dbh->do($statement);
  }
  $dbh->do('COMMIT');
  unlink $file;
  return $count;
}

1;

