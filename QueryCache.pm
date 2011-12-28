package QueryCache;

use strict;
use Database;
use Data::Dumper::Simple;

my $oneTrueSelf;

sub instance {
  unless (defined $oneTrueSelf) {
    my $class = shift;
    my $self = {queries => {}};
    $oneTrueSelf = bless $self, $class;
  }
  return $oneTrueSelf;
}

sub doQuery {
  my ($self, $query, $fields) = @_;
  my $data;

  if (!exists $self->{queries}->{$query}) {
    my $dbh = Database->instance()->getDbh();
    my $sth = $dbh->prepare_cached($query);
    $self->{queries}->{$query} = $dbh->selectall_arrayref($sth, {Slice => {}});
  }
  return $self->{queries}->{$query};
}

1;
