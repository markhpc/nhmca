package LogParser::Collectl;

use strict;
use File::stat;

use Database;
use Settings;
use Data::Dumper::Simple;
use DateTime;
use Common;
use base 'LogParser';

sub initialize {
  my ($self) = @_;

  $self->SUPER::initialize();
  $self->{_tsCache} = {};
  $self->{_package} = __PACKAGE__;
}

sub getSortedFiles {
  my ($self, $logdir) = @_;
  my @files = <$logdir/*.raw.gz>;
  return sort(@files);
}

sub getEpochFromTimestamp {
  my ($self, $timestamp) = @_;
  my $year = substr($timestamp, 0, 4);
  my $month = substr($timestamp, 4, 2);
  my $day = substr($timestamp, 6, 2);
  my $hour = substr($timestamp, 9, 2);
  my $minute = substr($timestamp, 12, 2);
  my $second = substr($timestamp, 15, 2);

  my $dt = DateTime->new(year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second);
  my $epoch = $dt->epoch();
  $self->{_tsCache}->{$timestamp} = $epoch;
  return $epoch;
}

sub getNodeFromFilename {
  my ($self, $logfile) = @_;
  my @shortfile = split(/\//, $logfile);
  my @nodeNameArray = split(/-/, $shortfile[-1]);
  pop(@nodeNameArray);
  pop(@nodeNameArray);
  return join("-", @nodeNameArray);
}

sub extractLog {
  my ($self, $logfile) = @_;
  my $extractedFile = substr($logfile, 0, -3);
  system("gunzip -c $logfile > $extractedFile");
  return $extractedFile;
}

1;

