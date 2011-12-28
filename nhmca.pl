#!/usr/bin/perl
#
# Copyright (c) 2010 Regents of the University of Minnesota
#
# This Software was initially written at the Minnesota Supercomputing Institute
# and is now being maintained independently by Mark Nelson.
#
# All rights reserved. The following statement of license applies only to this
# file, and and not to the other files distributed with it or derived 
# therefrom.  This file is made available under the terms of the GNU Public 
# License v2.0 which is available at:
# www.gnu.org/licesnes/gpl-2.0.html
#
# Contributors:
# Mark Nelson <nhm@clusterfaq.org>
# Minnesota Supercomputing Institute <http://www.msi.umn.edu>

use strict;
use Getopt::Long;
use Pod::Usage;

use Settings;
use Data::Dumper::Simple;
use GDChartDrawer;
use Updater;
use StatsEngine;

my $settings = Settings->instance();
my $params = $settings->getInitialParameters();
GetOptions($params, keys %{$settings->getParamsList()}) || pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if ($params->{help});
pod2usage(-verbose => 2) if ($params->{man});

if (!$settings->parseConfig($params->{config})) {
  my @files = $settings->getConfigFiles();
  print "  [ERROR] None of the following configuration files were found:\n\n";

  foreach my $file (@files) {
    print "  * $file\n";
  }
  print "\n  Please create one of the configuration files listed above or specify\n";
  print "  the path to a valid configuration file using the --config parameter.\n";
  print "  Example configuration files can be found in the examples/config directory.\n";
  exit 1;
}

if (!exists $settings->{parameters}->{cluster}) {
  pod2usage(-verbose => 0);
}

if ($settings->{parameters}->{update} == 1) {
  my $updater = new Updater;
  $updater->update();
} elsif ($settings->{parameters}->{genstats} == 1) {
  my $statsEngine = new StatsEngine;
  $statsEngine->write();
} else {
  my $drawer = new GDChartDrawer;
  $drawer->draw();
}

=head1 NAME

nhmca - a supercomputer and cluster utilization tool.

=head1 VERSION

nhmca version 0.1 alpha

=head1 SYNOPSIS

 nhmca.pl [options]

 Help Options:

 --help     Show help information.
 --man      Show man page.

=head1 DESCRIPTION

 Generate graphs and charts to visualize supercomputer and cluster utilization.

=head1 OPTIONS

=head2 GENERAL OPTIONS

 --help     Print Options and Arguments
 --man      Print complete man page
 --config   Manually specify the configuration file
 --update   Update the database instead of drawing graphs
 --genstats Generate statisticals reports instead of drawing graphs
 --output   Name of the png file to save
 --cluster  Graph data for the specified cluster
 --start    The ISO8601 formatted date/time to begin the charts
 --end      The ISO8601 formatted date/time to end the charts

=head2 MOAB SPECIFIC OPTIONS 

 --user     Include the specified user(s)
 --group    Include the specified group(s)
 --job      Include the specified job(s)
 --xuser    Exclude the specified user(s)
 --xgroup   Exclude the specified group(s)
 --xjob     Exclude the specified job(s)

=head1 EXAMPLES

 Graph all usage on the cluster 'calhoun':

 nhmca.pl --cluster=calhoun

 Graph usage on itasca from 12:37 CST to 16:05 CST on September 14th, 2010:

 nhmca.pl --cluster=itasca --start=2010-09-14T12:37:00-05 --end=2010-09-14T16:05:00-05

 (MOAB specific) Graph all usage of users except fred in the namd group on blade:

 nhmca.pl --cluster=blade --group=namd --xuser=fred

=head1 FILES

 /etc/nhmca/settings.xml
 ~/.nhmca/settings.xml

=cut

