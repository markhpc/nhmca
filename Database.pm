package Database;

use strict;

use Settings;
use Common;
use DBI;

my $settings = Settings->instance();

my $oneTrueSelf;

sub instance {
  unless (defined $oneTrueSelf) {
    my $class = shift;
    my $clusterSettings = Common::getCluster();
    my $dsn = $clusterSettings->{database}->{dbi};
    my $user = $clusterSettings->{database}->{user};
    my $password = $clusterSettings->{database}->{password};   

    my $dbh = DBI->connect($dsn, $user, $password) || die "Cannot connect: $DBI::errstr";
    my $self = {
      _dbh => $dbh,
    };
    $oneTrueSelf = bless $self, $class;
  }
  return $oneTrueSelf;
}

sub getDbh {
  my ($self) = @_;
  return $self->{_dbh};
}

1;
