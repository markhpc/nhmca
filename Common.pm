package Common;

use strict;
use GD;
use Data::Dumper::Simple;

my $settings = Settings->instance();

sub hex2rgb {
  return [hex(substr($_[0], 1, 2)),
          hex(substr($_[0], 3, 2)),
          hex(substr($_[0], 5, 2)),
          hex(substr($_[0], 7, 2))];
}

sub hex2color {
  my ($image, $color, $alpha) = @_;
  my $colors = hex2rgb($color);
  if (defined $alpha) {
    return $image->colorResolveAlpha($colors->[0], $colors->[1], $colors->[2], $alpha);
  }
  if (defined $colors->[3]) {
    return $image->colorResolveAlpha($colors->[0], $colors->[1], $colors->[2], $colors->[3]);
  }
  return $image->colorResolve($colors->[0], $colors->[1], $colors->[2]);
}

sub rgb2color {
  my ($image, $color) = @_;
  return $image->colorResolveAlpha($color->[0], $color->[1], $color->[2], $color->[3]);
}

sub blendColors {
  my ($colors, $fractions, $total) = @_;
  my @ret = (0, 0, 0, 0);

  for (my $i = 0; $i < scalar @$colors; $i++) {
    $ret[0] += $colors->[$i][0] * $fractions->[$i];
    $ret[1] += $colors->[$i][1] * $fractions->[$i];
    $ret[2] += $colors->[$i][2] * $fractions->[$i];
    $ret[3] += $colors->[$i][3] * $fractions->[$i];

  }
  return [int ($ret[0] / $total + .5), 
          int ($ret[1] / $total + .5),
          int ($ret[2] / $total + .5),
          int ($ret[3] / $total + .5)];
}

sub blendColorsOld {
my ($colors, $fractions, $total) = @_;
  my ($red, $green, $blue, $alpha) = (0, 0, 0, 0);

  for (my $i = 0; $i < scalar @$colors; $i++) {
    my $scale = $fractions->[$i];
    my ($red2, $green2, $blue2, $alpha2) = @{$colors->[$i]};
    $red += $red2 * $scale;
    $green += $green2 * $scale;
    $blue += $blue2 * $scale;
    $alpha += $alpha2 * $scale;
  } 
  $red = $red / $total;
  $green = $green / $total;
  $blue = $blue / $total;
  $alpha = $alpha / $total;

  return [int($red + .5), int($green + .5), int($blue + .5), int($alpha + .5)];
}


sub blendColorsOld {
  my ($colors, $fractions) = @_;
  my ($red, $green, $blue, $alpha) = (0, 0, 0, 0);

  my $total = 0;
  foreach my $fraction (@$fractions) {
    $total += $fraction;
  }
  print "@$fractions" if ($total == 0);
  for (my $i = 0; $i < scalar @$colors; $i++) {
    my $scale = $fractions->[$i];
    my ($red2, $green2, $blue2, $alpha2) = hex2rgb($colors->[$i]);
    $red += $red2 * $scale;
    $green += $green2 * $scale;
    $blue += $blue2 * $scale;
    $alpha += $alpha2 * $scale;
#    print "red: $red green: $green blue: $blue\n";
  }
  $red = $red / $total;
  $green = $green / $total;
  $blue = $blue / $total;
  $alpha = $alpha / $total;

  my $color = sprintf("#%02X%02X%02X%02X", int($red + .5), int($green + .5), int($blue + .5), int($alpha + .5));
  return $color;
}

sub convertSecondsToHours {
  my $data = shift; 
  my $newdata;
  if (ref $data eq 'ARRAY') {
    for (my $i = 0; $i < scalar @$data; $i++) {
      $newdata->[$i] = convertSecondsToHours($data->[$i]);
    }
  } else {
    $newdata = $data / 3600;
  }
  return $newdata;
}

sub uniq {
  my %seen = ();
  my @r = ();
  foreach my $a (@_) {
    unless ($seen{$a}) {
      push @r, $a;
      $seen{$a} = 1;
    }
  }
  return \@r;
}

sub getMin {
  my $min;
  foreach my $value (@_) {
    if (defined $min && $min < $value) {
      next;
    }
    $min = $value;
  }
  return $min;
}

sub makelabely {
  my ($image, $labelx, $labely, $label) = @_;
  my @labelarray = split("\n", $label);
  my $textcolor = hex2color($image, Settings->instance()->{graphs}->{colors}->{text});

  for (my $i = 0; $i < @labelarray; $i++) {
    my $lenght = length($labelarray[$i]);
    $image->string(gdMediumBoldFont, $labelx - int($lenght * 3.5 + .5), $labely + 14 * $i, $labelarray[$i], $textcolor);
  }
}

sub getDtFromTimestamp {
  my ($timestamp) = @_;
  my $year = substr($timestamp, 0, 4);
  my $month = substr($timestamp, 4, 2);
  my $day = substr($timestamp, 6, 2);
  my $hour = substr($timestamp, 9, 2);
  my $minute = substr($timestamp, 12, 2);
  my $second = substr($timestamp, 15, 2);
  my $dt = DateTime->new(year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second, time_zone => "America/Chicago");
  return $dt; 
}

sub getCluster {
  if (ref $settings->{cluster} eq "ARRAY") {
    foreach my $cluster (@{$settings->{cluster}}) {
      if ($settings->{parameters}->{cluster} eq $cluster->{name}) {
        return $cluster;
      }
    }
  }
  return $settings->{cluster};
}

1;
