package GDChart::HeatMap;

use strict;
use GD;
use Data::Dumper::Simple;
use Storable;

use DataProcessor;
use ColorFunctionFactory;
use base 'GDChart';

sub initialize {
  my ($self) = @_;
  $self->SUPER::initialize();

  $self->{_pixelCache} = [];
  my $cluster = Common::getCluster();
  my $inputs = $self->{_chartSettings}->{input};
  $self->{_inputs} = Storable::dclone($inputs);

  $self->{_max} = 0;  
  $self->{_rows} = 0;
  foreach my $input (@{$self->{_inputs}}) {
    my $dataProcessor = DataProcessor->new();
    $input->{data} = $dataProcessor->parseDataGroup($input);
    $input->{max} = $self->{_chartSettings}->{max} || $self->getMax($input->{data});
    $self->{_max} = $input->{max} if ($input->{max} > $self->{_max});
    my $height = scalar @{$input->{data}->[0]};
    $self->{_rows} = $height if ($height > $self->{_rows});
    $input->{_colorTable} = [];
    $input->{_blendCache} = {};
  }
  $self->{_factor} = $self->{_rows} / $self->{_chartSettings}->{height};
}

sub draw {
  my ($self) = @_;
  my $inputs = $self->{_inputs};
  my $xstart = $self->{_xstart};
  my $ystart = $self->{_ystart};
  my $factor = $self->{_factor};
  my $image = $self->{_image};

#  foreach my $input(@$inputs) {
  for (my $i = 0; $i < @$inputs; $i++) {
    my $input = $inputs->[$i];
    my $data = $input->{data};
    my $blendCache = $input->{_blendCache};

    # Draw the label
    $self->_drawLabel($input, $i);

    # Iterated over rows in the chart.
    for (my $j = 0; $j <$self->{_chartSettings}->{height}; $j++) {
      my $startingPos = $factor * $j;
      my $endingPos = $startingPos + $factor;

      # Get the fraction for this row.
      my ($fractions, $packFormat) = $self->_createFractions($j);

      # Draw the row.
      my $slice = [ @ { $data->[0] } [int($startingPos) .. int($startingPos + $factor)] ];
      my $blendKey = pack($packFormat, @$slice);
      my $gdColor = $blendCache->{$blendKey} || $self->_setBlendColor($input, $blendKey, $slice, $fractions);
      my $pixelCache = [0, $gdColor]; 

      for (my $i = 1; $i < scalar @$data; $i++) {
        my $slice = [ @ { $data->[$i] } [int($startingPos) .. int($startingPos + $factor)] ];
        my $blendKey = pack($packFormat, @$slice);
        my $gdColor = $blendCache->{$blendKey} || $self->_setBlendColor($input, $blendKey, $slice, $fractions);
        if ($pixelCache->[1] != $gdColor) {
          $image->line($xstart + $pixelCache->[0], $ystart-$j, $xstart + $i - 1, $ystart-$j, $pixelCache->[1]);
          $pixelCache->[0] = $i;
          $pixelCache->[1] = $gdColor;
        }
      }
      $image->line($xstart + $pixelCache->[0], $ystart-$j, $xstart + scalar @$data, $ystart-$j, $pixelCache->[1]);
    }
  }
  $self->_drawgrid();
}

sub _drawLabel {
  my ($self, $input, $inputPos) = @_;
  my $image = $self->{_image};
  my $chartSettings = $self->{_chartSettings};
  my $inputCount = scalar @{$self->{_inputs}};
  my $height = int ($chartSettings->{height} / $inputCount);
  my $xend = $self->{_xend};

  my $offset = 0;
  if ($inputPos == $inputCount - 1) {
    $offset = 2;
  } elsif ($inputPos > 0) {
    $offset = 1;
  }

  my $label = $input->{function} . " " . $chartSettings->{name};
  $label = $input->{label} if (defined $input->{label});
  $label .= " (" . sprintf("%.1f", $input->{max}) . " " . $chartSettings->{zlabel} . " Max)";

  my $labelrows = $self->makelabel($xend + 8, $self->{_labelOffset} + $offset, $height - 2, $label, $input);
  $self->{_labelOffset} += $height;
}

sub _fillLabelColor {
  my ($self, $labelx, $labely, $height, $input) = @_;
  my $image = $self->{_image};
  my $lineColor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{grid}, 80);
  my $bgColor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{background});

  $image->filledRectangle($labelx, $labely, $labelx + 12, $labely+$height, $lineColor);
  $image->filledRectangle($labelx+1, $labely+1, $labelx + 11, $labely+$height-1, $bgColor);

  my $size = $height-2;
  my $function = ColorFunctionFactory->getFunction($input->{color_function});
  for (my $i = 0; $i <= $size; $i++) {
    my $value = $input->{max} * $i / $size;
    my $fillColor = $image->colorResolveAlpha(@{&$function($value, $self->{_max}, $input->{color})});
    $image->line($labelx+1, $labely+$height-1-$i, $labelx+11, $labely+$height-1-$i, $fillColor);
  }
}


sub _createFractions {
  my ($self, $j) = @_;
  my $factor = $self->{_factor};
  my $startingPos = $factor * $j;
  my $endingPos = $startingPos + $factor;
  my $fractions = [];
  my $packFormat = "";

  # Create the fractions
  my $i = 0;
  while ($startingPos < $endingPos) {
    my $cont = 0;
    if($endingPos - $startingPos > 1) {
      $cont = int($startingPos + 1) - $startingPos;
      $startingPos += $cont;
    } else {
      $cont = $endingPos - $startingPos;
      $startingPos += $cont;
    }
    $fractions->[$i] = $cont;
    $i++;
    $packFormat .= "l ";
  }
  return ($fractions, $packFormat);
}

sub _setBlendColor {
  my ($self, $input, $blendkey, $slice, $fractions) = @_;
  my $image = $self->{_image};
  my $factor = $self->{_factor};
  my $colorTable = $input->{_colorTable};
  my $colors = [ map { $colorTable->[$_] || $self->_setColorTable($input, $_) } @$slice ];
  my $gdColor = $image->colorResolveAlpha(@{Common::blendColors($colors, $fractions, $factor)});
  $input->{_blendCache}->{$blendkey} = $gdColor;
  return $gdColor;
}

sub _setColorTable {
  my ($self, $input, $value) = @_;
  my $colorTable = $input->{_colorTable};
  my $color = $input->{color};
  my $function = ColorFunctionFactory->getFunction($input->{color_function});
  $colorTable->[$value] = &$function($value, $self->{_max}, $color);
  return $colorTable->[$value];
}

sub getMaxValue {
  my ($self) = @_;
  return $self->{_rows};
}

sub getMax {
  my ($self, $iData) = @_;
  my $max = 0;

  for (my $i = 0; $i < @$iData; $i++) {
    for (my $j = 0; $j < @{$iData->[$i]}; $j++) {
      $max = $iData->[$i][$j] if ($iData->[$i][$j] > $max);
    }
  }
#  print $max . "\n";
  return $max;
}



sub _setColor {
  my ($self, $value, $colorTable) = @_;

  if (!defined $value) {
    $colorTable->[$value] = [255, 255, 255];
    return $colorTable->[$value];
  }

  my $red = int(rand(255));
  my $green = int(rand(255));
  my $blue = int(rand(255));
  if ($red + $green + $blue > 512) {
    return $self->_setColor($value);
  }
  $colorTable->[$value] = [$red, $green, $blue];
  return $colorTable->[$value];
}

1;
