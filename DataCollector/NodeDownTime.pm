package DataCollector::NodeDownTime;
use strict;
use warnings;

use Settings;
use Database;
use Data::Dumper::Simple;
use base 'DataCollector';

sub initialize {
  my ($self) = @_;
  my $nodeCount = $self->{_clusterSettings}->{nodes};

  my $data;
  for (my $i = 0; $i < $self->{_xmax}; $i++) {
    $data->[$i] = [];
  }

  my $results = $self->_executeQuery();
  my ($begin, $end) = $self->_getModeValues();
  my $dtHash = {}; 
  my $firsttime = $results->[0]->{"time"};

#  print "results: @$results\n";
  foreach my $result (@$results) {
    my $node = $result->{"node"};
    my $state = $result->{"status"};
    my $time = $result->{"time"};

    $dtHash->{$node} = [] if (!(exists $dtHash->{$node}));
    my $array = $dtHash->{$node};

    if ($state eq "+") {
      if (scalar @$array > 0 && !exists($array->[-1]->{endtime})) {
        # Possibly Offline
        $array->[-1]->{state} = "2";
      } else {
        # Likely Offline
        push(@$array, {starttime => $time, state=>"1"});
      }
    } else {
      if (scalar @$array > 0 && exists $array->[-1]->{endtime}) {
        # Unknown
        push(@$array, {starttime => $array->[-1]->{endtime} + 1, endtime => $time, state => "3"});
      } elsif (scalar @$array > 0) {
        $array->[-1]->{endtime} = $time;
      } else {
        # Unknown
        push(@$array, {starttime => $firsttime, endtime => $time, state => "3"});
      }
    }
  }
  foreach my $nodeName ( keys %$dtHash ) {
    my $records = $dtHash->{$nodeName};
    foreach my $record (@$records) {
      my $xstart = $self->_getXStart($record->{starttime});
      my $xend = $self->_getXEnd($record->{endtime});
      my $node = $self->{_nodeHash}->{$nodeName};
      for (my $i = $xstart; $i < $xend; $i++) {
        $data->[$i][$node] = $record->{state};
      }
    }
  }
  $self->{_data} = $data;      
}

sub _executeQuery {
  my ($self) = @_;
  my $dbh = Database->instance()->getDbh();
  my ($begin, $end) = $self->_getModeValues();
  my $cluster = Settings->instance()->{parameters}->{cluster};
  my $query = "SELECT * FROM nodestatusrecords WHERE system='" . $cluster . "' ORDER BY 'time'";
  return $dbh->selectall_arrayref($query, {Slice => {}});
}

# For now at least we are going to ignore the requested mode and always show
# running utilization.
sub _getModeValues {
  return ("starttime", "endtime");
}

sub _getFirstUnusedCore {
  my ($self, $data, $i, $node) = @_;
  my $coresPerNode = $self->{_clusterSettings}->{cores_per_node};

  my $offset = $node * $coresPerNode;
  for (my $j = 0; $j < $coresPerNode; $j++) {
    if (!defined $data->[$i][$offset+$j]) {
     return $offset+$j;
    }
  }
}

1;
