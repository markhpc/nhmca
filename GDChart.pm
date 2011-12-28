package GDChart;

use strict;
use Settings;
use Common;
use GD;
use FunctionFactory;
use DataCollectorFactory;

use Data::Dumper::Simple;

sub new {
  my ($class, $chartSettings, $yoffset) = @_;
  my $settings = Settings->instance();

  my $self = {
    _chartSettings => $chartSettings,
    _yoffset => $yoffset,
    _settings => $settings,
  };
  bless $self, $class;

  $self->initialize();
  return $self;
}

sub initialize {
  my ($self) = @_;
  my $settings = $self->{_settings};
  my $width = $settings->{graphs}->{width};
  my $leftMargin = $settings->{graphs}->{margins}->{left};
  my $rightMargin =  $settings->{graphs}->{margins}->{right};
  my $chartMargin = $settings->{graphs}->{margins}->{chart};

  $self->{_xstart} = $leftMargin + $chartMargin;
  $self->{_xend} = $width - $rightMargin - $chartMargin;
  $self->{_yend} = $chartMargin;
#  $self->{_yend} = 0;
  $self->{_ystart} = $self->{_yend} + $self->getHeight() - $chartMargin * 2;
  $self->{_labelOffset} = $chartMargin;

  my $width = $settings->{graphs}->{width};
  my $height = $self->getHeight();
  my $image = new GD::Image($width, $height, 1);
  my $bgColor = Common::hex2color($image, $settings->{graphs}->{colors}->{background});
  $image->filledRectangle(0, 0, $width, $height, $bgColor);
  $self->{_image} = $image;
}

sub getImage {
  my ($self) = @_;
  return $self->{_image};
}

sub cleanup {
}

sub draw {
}

sub getHeight {
  my ($self) = shift;
  my $chartSettings = $self->{_chartSettings};
  return $self->{_settings}->{graphs}->{margins}->{chart} * 2 + $chartSettings->{height};
}

sub getMaxValue {
  return 0;
}

sub _drawgrid {
  my ($self, $mode) = @_;
  my $image = $self->{_image};
  my $xstart = $self->{_xstart};
  my $xend = $self->{_xend};
  my $ystart = $self->{_ystart};
  my $yend = $self->{_yend};

  my $data = $self->{_data};
  my $initialTime = Settings->instance()->{parameters}->{startDT};
  my $completionTime = Settings->instance()->{parameters}->{endDT}; 

  my $chartSettings = $self->{_chartSettings};
  my $label = $chartSettings->{ylabel};
  my $rows = $chartSettings->{rows};
  my $maxValue = $self->getMaxValue();
  my $valuesPerRow = $maxValue / $rows;

  my $textcolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{text});
  my $linecolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{grid}, 80);
  my $bglinecolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{grid}, 112);
  my $bglinecolordark = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{grid}, 96);

  # Draw horizontal lines
  $image->line($xstart, $yend, $xend, $yend, $linecolor);
  for (my $row = 0; $row < $rows; $row++) {
    my $ypos;
    if ($mode eq "logarithmic") {
      if ($row*$valuesPerRow >= 1) {
        $ypos = $ystart - int(log($row*$valuesPerRow) * ($ystart-$yend) / log($rows*$valuesPerRow) + .5);
      }
    } else {
      $ypos = $ystart - int($row * ($ystart-$yend) / $rows + .5);
    }
    $image->line($xstart, $ypos, $xend, $ypos, $bglinecolor);

    # Draw the line value
    my $value = 0;
    if ($maxValue > 9999) {
      $value = int($row*$valuesPerRow / 1000 + .5) . "k";
    } elsif ($maxValue > 10) {
      $value =  int($row*$valuesPerRow + .5);
    } else {
      $value = sprintf("%.1f", $row*$valuesPerRow);
    }
    $image->string(gdMediumBoldFont, $xstart - 28, $ypos - 6, $value, $textcolor);
  }
  $image->line($xstart, $ystart, $xend, $ystart, $linecolor);
  my $value = 0;
  if ($maxValue > 9999) {
    $value = int($maxValue / 1000 + .5) . "k";
  } elsif ($maxValue > 10) {
    $value =  int($maxValue + .5);
  } else {
    $value = sprintf("%.1f", $maxValue);
  }
  $image->string(gdMediumBoldFont, $xstart - 28, $yend - 6, $value, $textcolor);

  $self->makelabelx($xstart - 48, $ystart - ($ystart-$yend) / 2, $label);

  # Draw days
  $image->line($xstart, $yend, $xstart, $ystart, $linecolor);
  my $yLabel = "";
  # Months
  if ($completionTime->epoch() - $initialTime->epoch() > 60*60*24*90) {
    $self->_drawVertLines("months", "month");
    $yLabel = "Month of the Year";
  } elsif ($completionTime->epoch() - $initialTime->epoch() > 60*60*48) {  
    # Days
    $self->_drawVertLines("days", "day");
    $yLabel = "Day of the Month";
  } elsif ($completionTime->epoch() - $initialTime->epoch() > 60*60) {
    # Hours
    $self->_drawVertLines("hours", "hour");
    $yLabel = "Hour of the Day";
  } else {
   # Minutes
    $self->_drawVertLines("minutes", "minute");
    $yLabel = "Minute of the Hour";
  }

  $image->line($xend, $yend, $xend, $ystart, $linecolor);
  $self->makelabely($xstart + ($xend - $xstart) / 2, $ystart+14, $yLabel);

}

sub _drawVertLines {
  my ($self, $timeUnits, $funcName) = @_;
  my $image = $self->{_image};
  my $xstart = $self->{_xstart};
  my $xend = $self->{_xend};
  my $ystart = $self->{_ystart};
  my $yend = $self->{_yend};

  my $initialTime = Settings->instance()->{parameters}->{startDT};
  my $completionTime = Settings->instance()->{parameters}->{endDT};


  my $gridColor = $self->{_settings}->{graphs}->{colors}->{grid};
  my $bglinecolor = Common::hex2color($image, $gridColor, 112);
  my $bglinecolordark = Common::hex2color($image, $gridColor, 96);

  # Set the starting Value
  my $startingValue = 1;
  if ($timeUnits eq "minute" || $timeUnits eq "hour") {
    $startingValue = 0;
  }

  for (my $dt = $initialTime->clone(); $dt <= $completionTime; $dt->add($timeUnits => 1)) {
    my $xpos = $xstart + $self->_getXPosByEpoch($dt->epoch());
    my $value = $dt->$funcName();
    if ($value == $startingValue) {
      $image->line($xpos, $yend, $xpos, $ystart, $bglinecolordark);
    } else {
      $image->line($xpos, $yend, $xpos, $ystart, $bglinecolor);
    }
    $self->makelabely($xpos, $ystart, $value);
  }
}

sub _getXPosByEpoch {
  my ($self, $epoch) = @_;
  my $initialTime = Settings->instance()->{parameters}->{startDT};
  my $completionTime = Settings->instance()->{parameters}->{endDT};

  my $width = $self->{_settings}->{graphs}->{width} - 
              $self->{_settings}->{graphs}->{margins}->{left} - 
              $self->{_settings}->{graphs}->{margins}->{right} - 
              $self->{_settings}->{graphs}->{margins}->{chart} * 2;

  my $fraction = ($epoch - $initialTime->epoch()) / ($completionTime->epoch() - $initialTime->epoch());
  return int($fraction * $width + .5);
}

sub makelabel {
  my ($self, $labelx, $labely, $height, $label, $input) = @_;
  my $image = $self->{_image};
  my @labelarray;
  my $textcolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{text});
  my $rightMargin = $self->{_settings}->{graphs}->{margins}->{right};

  # split the line on spaces but keep anything in parens together
  my @split = split(/\(/, $label);
  if (@split > 1) {
    @split = (split(" ", $split[0]), "(" . $split[1]);
  }
  else {
    @split = split(" ", $split[0]);
  }

  # split the line based on the space in the right margin
  foreach my $part (@split) {
    if (defined($labelarray[-1]) && length($labelarray[-1] . $part) < $rightMargin / 8) {
      $labelarray[-1] .= " " . $part;
    } else {
      push(@labelarray, $part);
    }
  }

  # draw the text and fill
  my $offset = $labely;
  for (my $i = 0; $i < @labelarray; $i++) {
    $image->string(gdMediumBoldFont, $labelx + 20, $offset, $labelarray[$i], $textcolor);
    $offset += 14;
  }
  if (!defined $height) {
    $height = $offset;
  }
  $self->_fillLabelColor($labelx, $labely, $height, $input);

  return scalar @labelarray;
}

sub _fillLabelColor {
  my ($self, $labelx, $labely, $height, $input) = @_;
  my $image = $self->{_image};
  my $lineColor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{grid}, 80);
  my $fillColor = Common::hex2color($image, $input->{color});
  $image->filledRectangle($labelx, $labely, $labelx + 12, $labely + 12, $lineColor);
  $image->filledRectangle($labelx+1, $labely+1, $labelx + 11, $labely + 11, $fillColor);
}

sub makelabelx {
  my ($self, $labelx, $labely, $label) = @_;
  my $image = $self->{_image};
  my @labelarray = split("\n", $label);
  my $textcolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{text});

  for (my $i = 0; $i < @labelarray; $i++) {
    my $length = length($labelarray[$i]);
    $image->stringUp(gdMediumBoldFont, $labelx - (14 * (@labelarray - $i - 1)), $labely + int($length * 3.5 + .5), $labelarray[$i], $textcolor);
  }
}

sub makelabely {
  my ($self, $labelx, $labely, $label) = @_;
  my $image = $self->{_image};
  my @labelarray = split("\n", $label);
  my $textcolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{text});

  for (my $i = 0; $i < @labelarray; $i++) {
    my $lenght = length($labelarray[$i]);
    $image->string(gdMediumBoldFont, $labelx - int($lenght * 3.5 + .5), $labely + 14 * $i, $labelarray[$i], $textcolor);
  }
}

1;
