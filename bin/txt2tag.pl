#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

txt2tag.pl

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
my $outputVersion = "1.0";
# Min: fix this later if aye symblink is corrected
my $mxTermDir = "~wing.nus/tools/taggers/mxTag/";
my $mxterminatorCmd = "java -cp $mxTermDir/mxpost.jar eos.TestEOS $mxTermDir/eos.project/";
my $mxpostCmd = "java -mx30m -cp $mxTermDir/mxpost.jar tagger.TestTagger $mxTermDir/tagger.project/";
my $rerankParserCmd = "~/reranking-parser/parse.sh";
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
  print STDERR "       $progname [-aq] [-s <filename>] filename\n";
  print STDERR "Options:\n";
  print STDERR "\t-a\tAnnot file mode\n";
  print STDERR "\t-s <filename> \tOutput sentence delimited file to <filename>\n";
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
  print STDERR "# Copyright 2005 \251 by Min-Yen Kan\n";
}

###
### MAIN program
###

my $cmdLine = $0 . " " . join (" ", @ARGV);
if ($#ARGV == -1) { 		        # invoked with no arguments, possible error in execution? 
  die"# $progname fatal\t\tNo arguments detected!\n";
}

$SIG{'INT'} = 'quitHandler';
getopts ('ahqs:v');

our ($opt_a, $opt_q, $opt_v, $opt_h, $opt_s);
if (defined $opt_s and $opt_a) {
  die "-a and -s are mutually exclusive!";
}
# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		# call License, if asked for
if ($opt_v) { Version(); exit(0); }	# call Version, if asked for
if ($opt_h) { Help(); exit (0); }	# call help, if asked for

my $filename = shift;

if (!$opt_a) {							    # testing mode
  # run sentence delimitation
  my $cmd = "$mxterminatorCmd < $filename |";
  print STDERR "$cmd\n";
  open (IF, $cmd) || die;
  open (OF, ">$tmpfile.1");
  while (<IF>) {
    if (0) { chop; print OF "<s> $_ </s>\n"; }
    if (1) { print OF; }
  }
  close (OF);
  close (IF);

  # save delimited file if asked for
  if (defined $opt_s) { 
    $cmd = "cp $tmpfile.1 $opt_s";
    print STDERR "$cmd\n";
    `$cmd`;
  }

  # output header
  print "# flat file from txt input, v1.0\n";
  # run pos tagger
  my $cmd = "$mxpostCmd < $tmpfile.1 2> /dev/null";
  system($cmd);
} else {							    # annotation (training) mode
  my $cmd = "cut -f1 $filename | $mxpostCmd 2> /dev/null";
  print STDERR "$cmd\n";
  open (IF, "$cmd|") || die;
  my @lines = <IF>;
  close (IF);
  $cmd = "cut -f2 $filename";
  open (IF, "$cmd|") || die;
  my @labels = <IF>;
  close (IF);

  print "# flat file from annot input, v1.0\n";
  for (my $i = 0; $i <= $#lines; $i++) {
    chop $labels[$i];
    if (!defined $labels[$i] || $labels[$i] =~ /^\s*$/) { $labels[$i] = "UNDEFINED"; }
    chop $lines[$i];
    print "$lines[$i]\t$labels[$i]\n";
  }

}

# clean up
`rm -Rf $tmpfile\*`;

###
### END of main program
###
