package LogParser::CollectlIO;

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
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS `collectliodata` (`timestamp` INTEGER, `system` VARCHAR(255), `node` VARCHAR(255), `disk` VARCHAR(32), `reads` INTEGER, `rmerge` INTEGER, `rkbytes` INTEGER, `writes` INTEGER, `wmerge` INTEGER, `wkbytes` INTEGER, `request` INTEGER, `quelen` INTEGER, `wait` INTEGER, `svtim` INTEGER, `util` INTEGER, PRIMARY KEY (`timestamp`, `system`, `node`, 'disk'))";
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};
  my $file = $self->extractLog($logfile);
  my $node = $self->getNodeFromFilename($logfile);

  open FILE, "/usr/bin/collectl -P -sD -p $file |" or die $!;

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
    for (my $i = 2; $i < scalar @line; $i+=12) {
      my ($disk, $reads, $rmerge, $rkbytes, $writes, $wmerge, $wkbytes, $request, $quelen, $wait, $svctim, $util) = @line[$i..$i+12];
      my $statement = "REPLACE INTO collectliodata VALUES ('$epoch', '$name', '$node', '$disk', '$reads', $rmerge, $rkbytes, $writes, $wmerge, $wkbytes, $request, $quelen, $wait, $svctim, $util)";
      $dbh->do($statement);
    }
  }
  $dbh->do('COMMIT');
  unlink $file;
  return $count;
}

1;

