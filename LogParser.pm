package LogParser;

use strict;
use File::stat;

use Database;
use Settings;

sub new {
  my $class = shift;
  my $self = {
    _dbh => Database->instance()->getDbh(),
    _settings => Settings->instance(),
    _cluster => shift,
    _logdir => shift,
  };
  bless $self, $class;
  $self->initialize();
  return $self;
}

sub initialize {
  my ($self) = @_;
  $self->{_package} = __PACKAGE__;
}

sub parseLogs {
  my ($self) = @_;
  $self->CreateLogRecords();
  $self->CreateDataRecords();
}

sub CreateLogRecords {
  my $self = shift;
  my $dbh = $self->{_dbh};
  $dbh->do("CREATE TABLE IF NOT EXISTS logfiles (logfile VARCHAR(1000), logparser VARCHAR(32), lastupdate INTEGER, PRIMARY KEY (logfile, logparser))");
}

sub CreateDataRecords {
  my ($self) = @_; 
  my $dbh = $self->{_dbh};
  my $settings = $self->{_settings};
  my $name = $self->{_cluster};
  my $logdir = $self->{_logdir};
  my $createStatement = $self->{_createStatement};
  $self->{_tsCache} = {};

  $dbh->do($createStatement);

  my @files  = $self->getSortedFiles($logdir);
  foreach my $file (@files) {
    my $mtime = stat($file)->mtime;

    my $query = "SELECT * FROM logfiles WHERE logfile='" . $file . "' AND logparser='" . $self->{_package} . "' AND lastupdate ='" . $mtime . "'";
    my $archived_files = $dbh->selectall_arrayref($query, {Slice => {}});
    if (@$archived_files > 0) {
      print "Skipping previous record: " . $file . "\n";
    } else {
      print "Updating records for: " . $file . "...";
      my $count = $self->UpdateRecords($name, $file) ;
      print "wrote $count records.\n";
      $dbh->do("REPLACE INTO logfiles VALUES ('" . $file . "', '" . $self->{_package} . "', '" . $mtime . "')");
    }
  }
}

sub getSortedFiles {
  my ($self, $logdir) = @_;
  my @files = <$logdir/*>;
  return sort(@files);
}

sub UpdateRecords {
}

1;
