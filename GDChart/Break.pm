package GDChart::Break;

use strict;
use GD;

use base 'GDChart';

sub draw {
  my ($self) = @_;
  my $image = $self->{_image};
  my $linecolor = Common::hex2color($image, $self->{_settings}->{graphs}->{colors}->{grid}, 100);
  my $xstart = $self->{_xstart};
  my $xend = $self->{_xend};
  my $y = $self->{_ystart};
  
  $image->line($xstart, $y, $xend, $y, $linecolor);
}

sub getHeight {
  my ($self) = @_;
  return $self->{_settings}->{graphs}->{margins}->{chart} * 2;
}

1;
