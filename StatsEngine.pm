package StatsEngine;

use strict;
use warnings;

use Data::Dumper::Simple;
use Scalar::Util qw(looks_like_number);

use Settings;
use QueryCache;

my $settings = Settings->instance();

sub new {
  my ($class) = @_;
  my $self = {
  };
  bless $self, $class;
  return $self;
}

sub write {
  my ($self) = @_;
#  my $first = 1;

  print '"Statistics for ' . ucfirst($settings->{parameters}->{cluster}) . '"' . "\n";
  print '"Date Range:",'  . '"' . $settings->{parameters}->{startDT}->mdy . ' to ' . $settings->{parameters}->{endDT}->mdy . '"' . "\n";
  if ($settings->{stats}->{min_runtime}) {
    print '"Restrictions:","Exclude jobs with less than ' . $settings->{stats}->{min_runtime} . ' second runtimes"' . "\n";
  }
  print "\n";
  foreach my $section (@{$settings->{stats}->{section}}) {
    print "\n\n" if ($section->{group_by});
    print '"' . $section->{title} . '"' . "\n";
    print "\n" . $self->formatResults($self->createHeader($section), $section->{bin_label}) unless ($section->{group_by});
    foreach my $bin (@{$section->{bin}}) {
      my $query = $self->buildQuery($section, $bin);
      my $results = QueryCache->instance()->doQuery($query);
      if (scalar @$results > 0) {
        print "\n" . $self->formatResults($self->createHeader($section), $section->{bin_label}) if ($section->{group_by});
        print $self->formatResults($results, $bin->{label});
      }
    }
#    print "\n\n" if ($section->{group_by});
#    $first = 0;
  }
}

sub createHeader {
  my ($self, $section) = @_;
  my $hash = {};
  my $groupby = $section->{group_by};
  $hash->{system} = "Cluster";
  $hash->{jobs} = "Jobs";
  $hash->{usedwt} = "Aggregate CPU Time (Hours)";
  $hash->{avgtasks} = "Avg Req Tasks";
  $hash->{avgmem} = "Avg Req Mem per Task (MB)";
  $hash->{avgwc} = "Avg Req wclimit (Hours)";
  $hash->{avgruntime} = "Avg Runtime (Hours)";
  $hash->{avgqueuewait} = "Avg Queue Wait (Hours)";
  
  if (defined $groupby) {
    if ($groupby =~ m/userid/) {
      $hash->{pi} = "PI";
      $hash->{groupid} = "Group";
      $hash->{department} = "Department";
      $hash->{college} = "College";
      $hash->{userid} = "User";
    } elsif ($groupby =~ m/groupid/) {
      $hash->{pi} = "PI";
      $hash->{groupid} = "Group";
      $hash->{department} = "Department";
      $hash->{college} = "College";
    } elsif ($groupby =~ m/department/) {
      $hash->{department} = "Department";
      $hash->{college} = "College";
    } elsif ($groupby =~ m/college/) { 
      $hash->{college} = "College";
    }
  }
  return [$hash];
}

sub formatResults {
  my ($self, $results, $custField) = @_;
  $custField = "" unless (defined $custField);
  my $buffer = "";
  foreach my $result (@$results) {
    my $line = "";
    $line = $self->addCSV($line, $result->{system});
    $line = $self->addCSV($line, $custField);
    $line = $self->addCSV($line, $result->{jobs});
    $line = $self->addCSV($line, $result->{usedwt});
    $line = $self->addCSV($line, $result->{avgtasks});
    $line = $self->addCSV($line, $result->{avgmem});
    $line = $self->addCSV($line, $result->{avgwc});
    $line = $self->addCSV($line, $result->{avgruntime});
    $line = $self->addCSV($line, $result->{avgqueuewait});
    $line = $self->addCSV($line, $result->{college});
    $line = $self->addCSV($line, $result->{department});
    $line = $self->addCSV($line, $result->{pi});
    $line = $self->addCSV($line, $result->{groupid});
    $line = $self->addCSV($line, $result->{userid}, 1);
    $buffer .= "$line\n";
  }
  return $buffer;
}

sub addCSV {
  my ($self, $buffer, $value, $decimal, $last) = @_;
  $value = "" unless (defined $value);
  if (looks_like_number($value)) {
    $buffer .= sprintf("%.1f", $value);
  } else {
    $buffer .= '"' . $value . '"';
  }
  $buffer .= "," unless (defined $last);
  return $buffer;
}

sub dbConcat {
  my ($self, $field) = @_;
  my @elements = split(/,\s*/, $field);
  my $buffer = shift(@elements);
  foreach my $element (@elements) {
    $buffer .= ' || ", " || ' . $element;
  }
  return $buffer;
}

sub buildQuery {
#  my ($self, $type, $begWC, $endWC, $minRuntime) = @_;
  my ($self, $section, $bin) = @_;
  my $starttime = $settings->{parameters}->{startDT}->epoch();
  my $endtime = $settings->{parameters}->{endDT}->epoch();
  my $groupby = $section->{group_by};

  my $query = "SELECT";


#  $query .= " " . $self->dbConcat($section->{group_by}) . " as gbfield," if (exists $section->{group_by});
  $query .= "
       system,
       count(*) as jobs,
       round(total(reqtasks * (endtime-starttime)) / 3600.0, 1) as usedwt,
       round(avg(reqtasks), 1) as avgtasks, 
       round(avg(reqmem),1) as avgmem, 
       round(avg(wclimit) / 3600.0, 1) as avgwc,
       round(avg(endtime-starttime) / 3600.0, 1) as avgruntime, 
       round(avg(starttime-subtime) / 3600.0, 1) as avgqueuewait";
  $query .= ", college, department, pi, groupid, userid " if (defined $groupby && $groupby eq "userid");
  $query .= ", college, department, pi, groupid" if (defined $groupby && $groupby eq "groupid");
  $query .= ", college, department" if (defined $groupby && $groupby =~ m/department/g);
  $query .= ", college" if (defined $groupby);

  $query .= " FROM jobendrecords";
  $query .= " LEFT OUTER JOIN groups ON jobendrecords.groupid=groups.name" if (exists $section->{group_by});
  $query .= " WHERE 1";
  $query .= " AND starttime > $starttime" if (defined $starttime);
  $query .= " AND endtime <= $endtime" if (defined $endtime);

  $query .= " AND " . $bin->{field} . " > " . $bin->{start} if (exists $bin->{field} && exists $bin->{start});
  $query .= " AND " . $bin->{field} . " <= " . $bin->{end} if (exists $bin->{field} && exists $bin->{end});
  $query .= " AND endtime-starttime > " . $settings->{stats}->{min_runtime} if (exists $settings->{stats}->{min_runtime});
  $query .= " GROUP BY " . $section->{group_by} if (exists $section->{group_by});
  $query .= " ORDER BY " . $section->{order_by} if (exists $section->{group_by});
  $query .= " DESC" if (exists $section->{desc} && $section->{desc} == 1);
#  $query .= " GROUP BY groupid ORDER BY count(*) DESC" if ($type eq "group");
  return $query;
}

1;

