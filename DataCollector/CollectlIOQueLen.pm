package DataCollector::CollectlIOQueLen;
use strict;
use warnings;

use Database;
use base 'DataCollector::CollectlIO';

sub initialize {
  my ($self) = @_;
  $self->{_dataColumn} = "quelen";
  $self->SUPER::initialize();
}


#sub _executeQuery {
#  my ($self) = @_;
#  my $start = $self->{_startDT}->epoch();
#  my $end = $self->{_endDT}->epoch();
#  my $dbh = Database->instance()->getDbh();
#  my $cluster = $self->{_cluster};
#
#  my $query = "SELECT node,timestamp,quelen from collectliodata WHERE system='" . $cluster . "' AND timestamp >= '$start' AND timestamp < '$end'";
#  print "$query\n";
#  return $dbh->prepare_cached($query);
#  return $dbh->selectall_arrayref($query, {Slice => {}});
#}

1;
