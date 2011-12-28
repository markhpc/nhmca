package LogParser::CollectlProcess;

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
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS collectlprocessdata (timestamp, system, node, pid, ppid, command, user, cpu, percent, vmsize, vmrss, rkb, wkb, rkbc, wkbc, PRIMARY KEY (timestamp, system, node, pid))";
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};
  my $file = $self->extractLog($logfile);
  my $node = $self->getNodeFromFilename($logfile);

  open FILE, "/usr/bin/collectl -P -sZ -p $file |" or die $!;

  my $count = 0;
  while (<FILE>) {
    my $line = $_;
    chomp($line);
    my @line = split(/ +/, $line, 29);

    if ($line[3] =~ /^-?\d/ && $line[3] > 1000) {
      my $epoch = Common::getDtFromTimestamp($line[0] . " " . $line[1])->epoch();
      my ($pid, $ppid, $command, $user, $cpu, $percent, $vmsize, $vmrss, $rkb, $wkb, $rkbc, $wkbc) = 
         ($line[2], $line[5], $line[28], $line[3], $line[14], $line[17], $line[7], $line[9], $line[19], $line[20], $line[21], $line[22]);
      my $statement = "REPLACE INTO collectlprocessdata VALUES ('$epoch', '$name', '$node', '$pid', '$ppid', '$command', '$user', '$cpu', '$percent', '$vmsize', '$vmrss', '$rkb', '$wkb', '$rkbc', '$wkbc')";
      $dbh->do($statement);
      $count++;
    }
  }
  unlink $file;
  return $count;
}

1;

