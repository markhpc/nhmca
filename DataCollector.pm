package DataCollector;

use strict;
use warnings;
use Settings;
use QueryCache;
use Data::Dumper::Simple;

my $settings = Settings->instance();

sub new {
  my ($class, $mode) = @_;
  my $startDT = $settings->{parameters}->{startDT};
  my $endDT = $settings->{parameters}->{endDT};
  my $self = {
    _mode => $mode,
    _startEpoch => $startDT->epoch(),
    _endEpoch => $endDT->epoch(),
    _width => $settings->{graphs}->{width} -
              $settings->{graphs}->{margins}->{left} -
              $settings->{graphs}->{margins}->{right} -
              $settings->{graphs}->{margins}->{chart} * 2,
  };
  bless $self, $class;

  $self->{_clusterSettings} = Common::getCluster();
  $self->_buildNodeHash();
  $self->{_xmax} = $self->_getXposByEpoch($self->{_endEpoch}),

  return $self;
}

sub _executeQuery {
  my ($self) = @_;
  my ($begin, $end) = $self->_getModeValues();
  my $params = $settings->{parameters};

  # Build the Query
  $self->{query} = "SELECT * FROM jobendrecords";
  my $prepend = " WHERE (";
  $prepend = $self->queryBuilderHelper("groupid", $params->{group}, "=", $prepend);
  $prepend = $self->queryBuilderHelper("userid", $params->{user}, "=", $prepend);
  $prepend = $self->queryBuilderHelper("jobid", $params->{job}, "=", $prepend);
  $prepend = ") AND NOT (" if (!($prepend eq " WHERE ("));
  $prepend = $self->queryBuilderHelper("groupid", $params->{xgroup}, "=", $prepend);
  $prepend = $self->queryBuilderHelper("userid", $params->{xuser}, "=", $prepend);
  $prepend = $self->queryBuilderHelper("jobid", $params->{xjob}, "=", $prepend);
  $prepend = ") AND (" if (!($prepend eq " WHERE ("));
  $prepend = $self->queryBuilderHelper($end, $self->{_startEpoch}, ">=", $prepend);
  $prepend = ") AND (" if (!($prepend eq " WHERE ("));
  $prepend = $self->queryBuilderHelper($begin, $self->{_endEpoch}, "<", $prepend);
  $prepend = ") AND (" if (!($prepend eq " WHERE ("));
#  $self->{query} .= $prepend . " reqtasks<='8'"; 
  $self->{query} .= $prepend . " system='" . $params->{cluster} . "')";
#  if (defined $params->{"group"} || defined $params->{"user"} || defined $params->{"job"}) {
#    $query .= " (";
#
#    $query .= " groupid='" . $params->{"group"} . "'" if (defined $params->{"group"});
#    $query .= " userid='" . $params->{"user"} . "'" if (defined $params->{"user"});
#    $query .= " jobid='" . $parmas->{"job"} . "'" if (defined $params->{"job"});
#    $query .= " ) AND";
#  }

#  $query .= " system='" . $cluster . "' AND $end >= '" . $startDT->epoch() . "' AND $begin < '" . $endDT->epoch() . "'";

#  my $query = "SELECT * FROM jobendrecords WHERE groupid='kaznessi' AND system='" . $cluster . "' AND $end >= '" . $startDT->epoch() . "' AND $begin < '" . $endDT->epoch() . "'";
  print $self->{query} . "\n";
#  return $dbh->selectall_arrayref($self->{query}, {Slice => {}});
  return QueryCache->instance()->doQuery($self->{query});
}

sub queryBuilderHelper {
  my ($self, $column, $param, $operator, $prepend) = @_;

  if (defined $param) {
    $self->{query} .= "$prepend $column $operator '$param'";
    return " OR";
  }
  return $prepend;
}

sub getData {
  my ($self, $index) = @_;
  if (!(exists $self->{_data})) {
    $self->initialize();
  }
  return $self->{_data};
}

sub _getModeValues {
  my ($self) = @_;
  my $mode = $self->{_mode};

  if (defined $mode && $mode eq "Queued") {
    return ("subtime", "starttime")
  } 
  return ("starttime", "endtime");
}


sub _getXposByEpoch {
  my ($self, $epoch) = @_;
  my $fraction = ($epoch - $self->{_startEpoch}) / ($self->{_endEpoch} - $self->{_startEpoch});
  return int($fraction * $self->{_width} + .5);
}

sub _getEpochFromXpos {
  my ($self, $xpos) = @_;
  my $fraction = $xpos / $self->{_width};
  my $interval = $self->{_endEpoch} - $self->{_startEpoch};
  return ($self->{_startEpoch} + $fraction * $interval);
}

sub _getStart {
  my ($self, $epoch) = @_;
  $epoch = $self->{_startEpoch} if ($epoch < $self->{_startEpoch});
  return $epoch;
}

sub _getEnd {
  my ($self, $epoch) = @_;
  $epoch = $self->{_endEpoch} if ($epoch > $self->{_endEpoch});
  return $epoch;

}

sub _getXStart {
  my ($self, $begin) = @_;
  # Short circuit if null
  print ("no beginning defined!\n") if (!defined $begin);

  my $xstart = $self->_getXposByEpoch($begin);
  $xstart = 0 if ($xstart < 0);
  return $xstart;
}

sub _getXEnd {
  my ($self, $end) = @_;
  # Short circuit if null
  return $self->{_xmax} if (!defined $end);

  my $xend = $self->_getXposByEpoch($end);
  $xend = $self->{_xmax} if ($xend > $self->{_xmax});
  return $xend;
}

sub _buildDiskHash {
  my ($self) = @_;
  my $nodeHash = $self->_buildNodeHash();
  my $cluster = $self->{_clusterSettings};
  $self->{_diskHash} = {};

  my $nodeArray = [];
  foreach my $node (keys %$nodeHash) {
    $nodeArray->[$nodeHash->{$node}] = $node;
  }

  my $count = 0;

  for (my $index = 0; $index < @$nodeArray; $index++) {
    my $diskArray = [];
    my $node = $nodeArray->[$index];

    $diskArray = $cluster->{disk} if (exists $cluster->{disk});
    $diskArray = $cluster->{node}->[$index]->{disk} if (exists $cluster->{node}->[$index]->{disk});

    foreach my $disk (@$diskArray) {
      my $name = $disk->{name};
      $self->{_diskHash}->{$node}->{$name} = $count;
      $count++;
    }
  }
  return $self->{_diskHash};
}

sub _buildNodeHash {
  my ($self) = @_;
  my $cluster = $self->{_clusterSettings};
  
  my $array = [];
  if (exists $cluster->{node_prefix} && exists $cluster->{node_offset} && exists $cluster->{nodes}) {
    $array = $self->_buildArray($cluster->{node_prefix}, $cluster->{node_offset}, $cluster->{nodes});
  } elsif (exists $cluster->{node}) {
    foreach my $node (@{$cluster->{node}}) {
      push(@$array, $node->{name});
    }
  }
  $self->{_nodeHash} = $self->_buildHashFromArray($array, 0);
  return $self->{_nodeHash};
}

sub _buildHashFromArray {
  my ($self, $array, $offset) = @_;
  my $hash = {};
  my $count = scalar @$array;

  for (my $i = 0; $i < $count; $i++) {
    $hash->{$array->[$i]} = $i + $offset;
  }
  return $hash;
}

sub _buildArray {
  my ($self, $prefix, $offset, $count) = @_;
  my $array = [];
  $offset = 0 if (!defined $offset);

  my $sprintfLine = "%01d";
  $sprintfLine = "%02d" if ($count > 9);
  $sprintfLine = "%03d" if ($count > 99);
  $sprintfLine = "%04d" if ($count > 999);
  $sprintfLine = "%05d" if ($count > 9999);

  for (my $i = 0; $i < $count; $i++) {
    my $name = $prefix . sprintf($sprintfLine, ($i + $offset));
    $array->[$i] = $name;
  }
  return $array;
}

sub _splitNodeList {
  my ($self, $nodelist) = @_;
  my $cluster = $self->{_clusterSettings};
#  print Dumper($cluster);
  my $node_prefix = $cluster->{node_prefix};
  my $node_offset = $cluster->{node_offset};
  $node_offset = 0 if (!defined $node_offset);

  $nodelist =~ s/$node_prefix//g;
  my @array = split(/,/, $nodelist);
  for (my $i = 0; $i < @array; $i++) {
    if ($array[$i] =~ /^-?\d/) {
      $array[$i] -= $node_offset;
    } else {
      print "Found a non numeric node value: $array[$i]\n";
      splice(@array, $i, 1);
    }
  }
  return @array;
}

1;

