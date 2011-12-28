package DataProcessor;

use strict;
use Settings;
use Common;
use DataCollectorFactory;
use FunctionFactory;
use Data::Dumper::Simple;

sub new {
  my ($class) = @_;
  my $settings = Settings->instance();

  my $self = {
    _settings => $settings,
  };
  bless $self, $class;
  return $self;
}

sub parseDataGroup {
  my ($self, $dataGroup, $mode) = @_;
  my $dataGroupArray = $dataGroup->{datagroup};
  my $collectorName = $dataGroup->{collector};
  my $functionName = $dataGroup->{function};
  my $function = FunctionFactory->getFunction($functionName);

  if (defined @$dataGroupArray && scalar @$dataGroupArray > 0) {
    my $dataArray = [];
    for (my $i = 0; $i < @$dataGroupArray; $i++) {
      my $data = $self->parseDataGroup($dataGroupArray->[$i], $mode);
      for (my $j = 0; $j < @$data; $j++) {
        $dataArray->[$j][$i] = $data->[$j];
      }
    }
    for (my $i = 0; $i < @$dataArray; $i++) {
      $dataArray->[$i] = $function->(@{$dataArray->[$i]});
    }
 
   return $dataArray;
  } elsif (defined $collectorName) {
    my $dataCollector = $self->_getDataCollector($collectorName, $mode);
    my $data = $dataCollector->getData();
    for (my $i = 0; $i < @$data; $i++) {
      $data->[$i] = $function->($data->[$i]);
    }
    return $data;
  }
  return [];
}
  
sub _getDataCollector {
  my ($self, $dataCollector, $mode) = @_;
  return DataCollectorFactory->getInstance($dataCollector, $mode);
}

1;

