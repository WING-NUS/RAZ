#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

raz

=head1 SYNOPSYS

 RCS:$Id$

=head1 DESCRIPTION

=head1 HISTORY

 ORIGIN: created from templateApp.pl version 3.4 by Min-Yen Kan <kanmy@comp.nus.edu.sg>

 RCS:$Log$

=cut

require 5.0;
use Getopt::Std;
use strict 'vars';
# use diagnostics;

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; }		      # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $installDir = "/home/wing.nus/tools/citationTools/raz/";
my $outputVersion = "090925";
my $defaultOutputMode = "compact";
### END user customizable section


### Ctrl-C handler
sub quitHandler {
  print STDERR "\n# $progname fatal\t\tReceived a 'SIGINT'\n# $progname - exiting cleanly\n";
  exit;
}

### HELP Sub-procedure
sub Help {
  print STDERR "usage: $progname -h\t\t\t\t[invokes help]\n";
  print STDERR "       $progname -v\t\t\t\t[invokes version]\n";
  print STDERR "       $progname [-q] [-o <mode>]  filename(s)...\n";
  print STDERR "Options:\n";
  print STDERR "\t-o\tOutput mode (default: $defaultOutputMode, inline)\n";
  print STDERR "\t-q\tQuiet Mode (don't echo license)\n";
  print STDERR "\n";
  print STDERR "Will accept input on STDIN as a single file.\n";
  print STDERR "\n";
}
### VERSION Sub-procedure
sub Version {
  if (system ("perldoc $0")) {
    die "Need \"perldoc\" in PATH to print version information";
  }
  exit;
}

sub License {
  print STDERR "# Copyright 2009 \251 by Min-Yen Kan\n";
}

###
### MAIN program
###

my $cmdLine = $0 . " " . join (" ", @ARGV);
if ($#ARGV == -1) { 		        # invoked with no arguments, possible error in execution? 
  print STDERR "# $progname info\t\tNo arguments detected, waiting for input on command line.\n";  
  print STDERR "# $progname info\t\tIf you need help, stop this program and reinvoke with \"-h\".\n";
}

$SIG{'INT'} = 'quitHandler';
getopts ('ho:qv');

our ($opt_q, $opt_v, $opt_o, $opt_h);
# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		# call License, if asked for
if ($opt_v) { Version(); exit(0); }	# call Version, if asked for
if ($opt_h) { Help(); exit (0); }	# call help, if asked for
if (!defined $opt_o) { $opt_o = $defaultOutputMode; }

# generate features
system("$installDir/bin/tag2feats.pl -q $ARGV[0] > $tmpfile.1");

# do classification
system("$installDir/bin/maxent -m $installDir/lib/model.noContext.all -p $tmpfile.1 -o $tmpfile.2 > /dev/null");

open (IF, "$tmpfile.2") || die "$progname fatal\t\tCouldn't open results file";
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
if ($opt_o eq "compact") {
  print "<algorithm name=\"raz\" version=\"$outputVersion\">\n<raz>\n";
} elsif ($opt_o eq "inline") {
  print "<algorithm name=\"raz\" version=\"$outputVersion\" outputVersion=\"inline\">\n<raz>\n";
}

my $sentNum = 1;
my %az = ();
my @revAz = ();
while (<IF>) {
  chop;
  push(@{$az{$_}}, $sentNum);
  $revAz[$sentNum] = $_;
  $sentNum++;
}
close (IF);

if ($opt_o eq "compact") {
  foreach my $key (sort keys %az) {
    my $lckey = lc ($key);
    my $pos = join (",",@{$az{$key}});
    print "<$lckey>$pos</$lckey>\n";
  }
} elsif ($opt_o eq "inline") {
  open (IF, $ARGV[0]) || die;
  $sentNum = 1;
  while (<IF>) {
    chop;
    print "<" . lc($revAz[$sentNum]) . ">";
    print $_;
    print "</" . lc($revAz[$sentNum]) . ">\n";
    $sentNum++;
  }
  close (IF);
}
print "</raz>\n</algorithm>\n";

# clean up filesystem
# system("rm -f $tmpfile.*");

###
### END of main program
###
