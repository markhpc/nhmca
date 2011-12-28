package LogParser::CollectlIB;

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
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS collectlibdata (timestamp, system, node, hca INTERGER, inkb INTEGER, outkb INTEGER, PRIMARY KEY (timestamp, system, node))";
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};
  my $file = $self->extractLog($logfile);
  my $node = $self->getNodeFromFilename($logfile);

  open FILE, "/usr/bin/collectl -P -sX -p $file |" or die $!;

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
    my ($hca, $inkb, $outkb) = ($line[2], $line[5], $line[6]);
    my $statement = "REPLACE INTO collectlibdata VALUES ('$epoch', '$name', '$node', '$hca', '$inkb', '$outkb')";
    $dbh->do($statement);
  }
  $dbh->do('COMMIT');
  unlink $file;
  return $count;
}

1;

