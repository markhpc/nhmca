package LogParser::Moab;

use strict;
use File::stat;

use Database;
use Settings;
use Data::Dumper::Simple;
use base 'LogParser';

sub initialize {
  my ($self) = @_;

  $self->SUPER::initialize();
  $self->{_createStatement} = "CREATE TABLE IF NOT EXISTS jobendrecords (system varchar(255), jobid INTEGER, userid VARCHAR(255), groupid VARCHAR(255), wclimit INTEGER, class VARCHAR(255), subtime INTEGER, starttime INTEGER, endtime INTEGER, reqnodes INTEGER, reqtasks INTEGER, reqmem INTEGER, nodelist BLOB, PRIMARY KEY (system, jobid, starttime))";
  $self->{_package} = __PACKAGE__;
}

sub UpdateRecords {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};

  open FILE, "$logfile" or die $!;
  my $count = 0;
  $dbh->do('BEGIN');
  while (<FILE>) {
   if ($_ =~ m/JOBEND/) {
     my @line = split(/ +/, $_);
     my ($jobid,   $userid,  $groupid, $wclimit, $class,    $subtime,  $starttime, $endtime,  $reqnodes, $reqtasks, $reqmem,   $nodelist);
     if (@line == 55) {
       ($jobid,   $userid,  $groupid, $wclimit, $class,    $subtime,  $starttime, $endtime,  $reqnodes, $reqtasks, $reqmem,   $nodelist) =
       ($line[3], $line[7], $line[8], $line[9], $line[11], $line[12], $line[14],  $line[15], $line[5],  $line[6],  $line[36], $line[41]);
     } elsif (@line == 56) {
       ($jobid,   $userid,  $groupid, $wclimit, $class,    $subtime,  $starttime, $endtime,  $reqnodes, $reqtasks, $reqmem,   $nodelist) =
       ($line[3], $line[7], $line[8], $line[9], $line[11], $line[12], $line[14],  $line[15], $line[5],  $line[6],  $line[35], $line[40]);
     } else {
       print "I don't understand this moab format.  Skipping this line!\n";
       last;
     }
     # Moab puts an M at the end of the memory value (for MB) and we want an integer.
     chop($reqmem);

     $dbh->do("REPLACE INTO jobendrecords VALUES ('$name', '$jobid', '$userid', '$groupid', '$wclimit', '$class', '$subtime', '$starttime', '$endtime', '$reqnodes', '$reqtasks', '$reqmem', '$nodelist')");

     $count++;
   }
  }
  $dbh->do('COMMIT');
  return $count;
}

sub getSortedFiles {
  my ($self, $logdir) = @_;
  my %months = ('Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04',
                'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08',
                'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12');
 
  my @files = <$logdir/events.*>;

  my @sortarray;
  foreach(@files) {
    my $length = length($_);
    my $year = substr($_, $length-4, 4);
    my $day = substr($_, $length-7, 2);
    my $month = substr($_, $length-11, 3);
    my $sortline = $year . $months{$month} . $day . $_;
    push(@sortarray, $sortline);
  }

  @sortarray = sort(@sortarray);

  my @sortedfiles;
  foreach (@sortarray) {
    push(@sortedfiles, substr($_, 8, length($_) - 8));  
  }

  return @sortedfiles;
}

1;

