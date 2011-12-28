package GDChart::LineChart;

use strict;
use GD;
use Storable;

use DataProcessor;

use base 'GDChart';

sub initialize {
  my ($self) = @_;
  my $chartSettings = $self->{_chartSettings};
  my $lines = $chartSettings->{line};
  $self->{_lines} = Storable::dclone($lines);  

  foreach my $line (@{$self->{_lines}}) {
    my $dataProcessor = DataProcessor->new();
    $line->{data} = $dataProcessor->parseDataGroup($line, $line->{mode});
  }

  my $scalingfactor = 0;
  my $maxValue = $self->getMaxValue();
  if ($maxValue > 0) {
    $scalingfactor = $chartSettings->{height} / $maxValue;
  }
  $self->{_scalingFactor} = $scalingfactor;

  $self->SUPER::initialize();
}

sub draw {
  my ($self) = @_;

  my $chartSettings = $self->{_chartSettings};
  my $settings  = $self->{_settings};
  my $lines = $self->{_lines};
  my $image = $self->{_image};
  my $xstart = $self->{_xstart};
  my $xend = $self->{_xend};
  my $ystart = $self->{_ystart};
  my $yend = $self->{_yend};

  my $i = 0;
  my $labelypos = $yend;

  foreach my $line (@$lines) {
    # draw the line
    my $array = $self->_drawLine($line);

    # Get the overall average 
    my $avg = sprintf("%.1f", &{FunctionFactory->getFunction("Average")}($array));

    # Get the label name and append the average 
    my $name = $line->{function} . " " . $chartSettings->{name};
    $name = $line->{label} if (defined $line->{label});
    $name .= " (" . $avg . " " . $chartSettings->{ylabel} . " Avg)";

    # Draw the label
    my $labelrows = $self->makelabel($xend + 8, $labelypos, undef, $name, $line);

    $i++;
    $labelypos += $labelrows * 16;
  }
  $self->_drawgrid($chartSettings->{mode});
}

sub getMaxValue {
  my ($self) = shift;
  my $chartSettings = $self->{_chartSettings};
  my $lines = $self->{_lines};
  my $max = 0;

  if (defined $self->{_chartSettings}->{max}) {
    return $self->{_chartSettings}->{max};
  }

  foreach my $line (@$lines) {
    my $data = $line->{data};
    for (my $i = 0; $i < scalar @$data; $i++) {
      my $curdata = @$data[$i];
      $max = $curdata if (defined $curdata && $curdata > $max);
    }
  }
  $self->{_chartSettings}->{max} = $max;
  return $max;
}

sub _drawLine {
  my ($self, $line) = @_;
  my $xstart = $self->{_xstart};
  my $ystart = $self->{_ystart};
  my $data = $line->{data}; 

  for (my $i = 0; $i < scalar @$data; $i++) {
    my ($y1, $y2);

    # Draw requested line
    $y1 = $self->_getPosition($data->[$i]);
    $y2 = $self->_getPosition($data->[$i+1]) if ($i + 1 < scalar @$data);

    $self->_drawSegment($line->{color}, $xstart+$i, $y1, $y2, $ystart);
    if ($line->{fill} eq "true" || $line->{fill} eq "1") {
      $self->_drawFill($line->{color}, $xstart+$i, $y1, $y2, $ystart);
    }
    
    # Hack to fix pack/unpack behavior when computing the average over the whole time period.
    unless (defined $data->[$i]) {
      $data->[$i] = 0;
    }
  }
  return $data;
}

sub _getPosition {
  my ($self, $value) = @_;
  my $chartSettings = $self->{_chartSettings};
  my $ystart = $self->{_ystart};
  my $scalingFactor = $self->{_scalingFactor};
  my $maxValue = $self->getMaxValue();
  my $pos;

  if (defined $value) {
    if ($chartSettings->{mode} eq "logarithmic") {
      if ($value >= 1) {
        $pos = $ystart - int($chartSettings->{height} * (log($value) / log($maxValue)) + .5);
      } else {
        $pos = $ystart;
      }
    } else {
      $pos = $ystart - int($value * $scalingFactor + .5);
    }
  }
  return $pos;
}

sub _drawSegment {
  my ($self, $color, $x, $y1, $y2, $ystart) = @_;
  my $image = $self->{_image};
  if (defined($y1) && defined($y2)) {
    my $lineColor = Common::hex2color($image, $color);
    $image->setAntiAliased($lineColor);
    $image->line($x, $y1, $x+1, $y2, gdAntiAliased);
  }
}

sub _drawFill {
  my ($self, $color, $x, $y1, $y2, $ystart) = @_;
  my $image = $self->{_image};
  my $fillColor = Common::hex2color($image, $color, 64);

  if (defined($y1)) {
    $image->line($x, $ystart, $x, $y1, $fillColor);
  }
}
1;
