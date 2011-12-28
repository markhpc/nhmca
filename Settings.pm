package Settings;

use strict;
use XML::Simple;
use DateTime::Format::ISO8601;
use Data::Dumper::Simple;

my $oneTrueSelf;
my @configFiles = ('/etc/nhmca/settings.xml', $ENV{HOME} . '/.nhmca/settings.xml');

sub instance {
  unless (defined $oneTrueSelf) {
    my $class = shift;
    my $self = {_params => {}, parameters => {}};
    $oneTrueSelf = bless $self, $class;
  }
  return $oneTrueSelf;
}

sub parseConfig {
  my ($self, $passedFile) = @_;
  my $xml = new XML::Simple;
  my $found = 0;

  @configFiles = ($passedFile, @configFiles) if (defined $passedFile && $passedFile ne "");
  
  foreach my $file (@configFiles) {
    if (-e $file) {
      my $xmlhash = $xml->XMLin($file, GroupTags => {}, KeyAttr => {}, forcearray => ['disk', 'graph','line','log','data', 'datagroup', 'collector', 'input', 'node', 'section', 'bin']); 
      mergeHashes($self, $xmlhash);
      $found = 1;
      last;
    }
  }
  mergeHashes($self->{parameters}, $self->{_params});
  $self->{parameters}->{startDT} = DateTime::Format::ISO8601->parse_datetime($self->{parameters}->{start});
  $self->{parameters}->{endDT} = DateTime::Format::ISO8601->parse_datetime($self->{parameters}->{end});
  return $found;
}

sub mergeHashes {
  my ($x, $y) = @_;

  foreach my $key (keys %$y) {
    if (!defined $x->{$key}) {
      $x->{$key} = $y->{$key};
    } elsif (ref($y->{$key}) eq "HASH") {
      mergeHashes($x->{$key}, $y->{$key});
    } else {
      $x->{$key} = $y->{$key};
    }
  }
}

sub getConfigFiles {
  my $self = shift;
  return @configFiles;
}

sub getParamsList {
  return {
    'help' => "",
    'man' => "",
    'config=s' => "",
    'update' => undef,
    'genstats' => undef,
    'output=s' => "",
    'cluster=s' => "",
    'start=s' => "",
    'end=s' => "",
    'user=s' => "",
    'group=s' => "",
    'job=s' => "",
    'xuser=s' => "",
    'xgroup=s' => "",
    'xjob=s' => "",
  };
}

sub getInitialParameters {
  my $self = shift;
  return $self->{_params};
}

1;
