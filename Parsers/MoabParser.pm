package Parsers::MoabParser;

use strict;
use File::stat;

use Database;
use Settings;

sub new {
  my $class = shift;
  my $self = {
    _dbh => Database->instance()->getDbh(),
    _settings => Settings->instance(),
  };
  bless $self, $class;
  return $self;
}

sub parseLogs {
  my ($self) = @_;
  CreateLogRecords($self);
  CreateJobEndRecords($self);
}

sub CreateLogRecords {
  my $self = shift; 
  my $dbh = $self->{_dbh};
  $dbh->do("CREATE TABLE IF NOT EXISTS logfiles (logfile, lastupdate, PRIMARY KEY (logfile))");
}

sub CreateJobEndRecords {
  my $self = shift;
  my $dbh = $self->{_dbh};
  my $settings = $self->{_settings};

  $dbh->do("CREATE TABLE IF NOT EXISTS jobendrecords (system, jobid, userid, groupid, wclimit, subtime, starttime, endtime, nodelist, PRIMARY KEY (system, jobid, starttime))");

#  my $systems = $dbh->selectall_arrayref(q( SELECT * FROM systems), {Slice => {}});
  my $clusters = $settings->{cluster};
  foreach (@$clusters) {
    my $name = $_->{'name'};
    my $logdir = $_->{'logdir'};

#    my @files = <$logdir/events.*>;
    my @files = &getSortedFiles($logdir);
    foreach(@files) {
      my $file = $_;
      my $mtime = stat($_)->mtime;

      my $query = "SELECT * FROM logfiles WHERE logfile=='" . $file . "' AND lastupdate =='" . $mtime . "'";
      my $archived_files = $dbh->selectall_arrayref($query, {Slice => {}});
      if (@$archived_files > 0) {
        print "Skipping previous record: " . $file . "\n";
      } else {
        print "Updating record: " . $file . "\n";
        $dbh->do("REPLACE INTO logfiles VALUES ('" . $file . "', '" . $mtime . "')");
        UpdateRecordsFromMoabLog($self, $name, $file);
      }
    }
  }
}

sub UpdateRecordsFromMoabLog {
  my ($self, $name, $logfile) = @_;
  my $dbh = $self->{_dbh};

  open FILE, "$logfile" or die $!;
  my $count = 0;
  while (<FILE>) {
   if ($_ =~ m/JOBEND/) {
     my @line = split(/ +/, $_);
     my ($jobid, $userid, $groupid, $wclimit, $subtime, $starttime, $endtime, $nodelist) =
        ($line[3], $line[7], $line[8], $line[9], $line[12], $line[14], $line[15], $line[41]);

     $dbh->do("REPLACE INTO jobendrecords VALUES ('" . $name . "', '" .
              $jobid . "', '" . $userid . "', '" . $groupid . "', '" . $wclimit . "', '" .
              $subtime . "', '" . $starttime . "', '" . $endtime . "', '" . $nodelist . "')");

     $count++;
   }
  }
  print "\rrecords: " . $count;
}

sub getSortedFiles {
  my $logdir = shift;
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

