package GDChartDrawer;

use strict;
use FileHandle;

use Settings;
use DateTime;
use Common;
use Data::Dumper::Simple;
use GDChartFactory;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->initialize();
  return $self;
}

sub initialize {
  my ($self) = @_;
  my $settings = Settings->instance();
  my $chartSettings = $settings->{graphs}->{graph};
  my $width = $settings->{graphs}->{width};
  my $height = $settings->{graphs}->{margins}->{top};

  # Initialize the charts
  $self->{_charts} = [];
  STDOUT->autoflush(1);
  print "Initializing Charts.";
  foreach my $chartSetting (@$chartSettings) {
    my $type = $chartSetting->{type};
    my $chart = GDChartFactory->getInstance($type, $chartSetting, $height);
    push(@{$self->{_charts}}, $chart);
    $height += $chart->getHeight();
    print "Chart Height: " . $chart->getHeight() . "\n";
    print ".";
  }
  $height += $settings->{graphs}->{margins}->{bottom};
  print "Done!\n";
  STDOUT->autoflush(0);

  # Initialize the image
  my $image = new GD::Image($width, $height, 1);
  my $bgColor = Common::hex2color($image, $settings->{graphs}->{colors}->{background});
  $image->filledRectangle(0, 0, $width, $height, $bgColor);
  $self->{_image} = $image;
  print "Height: $height\n";
}

sub getImage {
  my ($self) = @_;
  return $self->{_image};
}

sub draw {
  my $self = shift;
  my $settings = Settings->instance();
  my $width = $settings->{graphs}->{width};
  my $image = $self->{_image};

  STDOUT->autoflush(1);
  print "Drawing Charts.";
  $self->drawTitle($image);
  my $yoffset = $settings->{graphs}->{margins}->{top};

  foreach my $chart (@{$self->{_charts}}) {
    my $height = $chart->getHeight();

    $chart->draw();
    my $chartImage = $chart->getImage();
    $image->copy($chartImage, 0, $yoffset, 0, 0, $width, $height);
    $yoffset += $height;
    print ".";
  }
  print "Done!\n";
  STDOUT->autoflush(0);

  $self->saveFile();
}

sub drawTitle {
  my ($self, $image) = @_;
  my $settings = Settings->instance();
  my $startDT = Settings->instance()->{parameters}->{startDT};
  my $endDT = Settings->instance()->{parameters}->{endDT};
  my $group = $settings->{parameters}->{group};
  my $user = $settings->{parameters}->{user};
  my $titlestring = "";
  my $xstart = $settings->{graphs}->{margins}->{left} + $settings->{graphs}->{margins}->{chart};
  my $xend = $settings->{graphs}->{width} - $settings->{graphs}->{margins}->{right} - $settings->{graphs}->{margins}->{chart};
  my $xpos = $xstart + ($xend - $xstart) / 2;
  my $ypos = $settings->{graphs}->{margins}->{top} / 2;


  if (defined $group) {
    $titlestring = $group . " group on ";
  }
  if (defined $user) {
    $titlestring = $user . " user on ";
  }

  $titlestring .= $settings->{parameters}->{cluster};
  $titlestring = $titlestring . " (" . $startDT->ymd . " " . $startDT->hms . " - " . $endDT->ymd . " " . $endDT->hms . ")";
  Common::makelabely($image, $xpos, $ypos, $titlestring);
}

sub saveFile {
  my ($self) = @_;
  my $image = $self->{_image};
  my $settings = Settings->instance();
  my $filename = $settings->{parameters}->{output};

  if (!defined $filename || $filename eq "") {
    $filename = "out.png";
  }
  open (my $OUT, ">$filename") or die "output: $!\n";
  binmode($OUT);
  print $OUT $image->png;
  close($OUT);
}

1;
