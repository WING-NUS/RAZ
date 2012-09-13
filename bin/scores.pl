#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME


=head1 SYNOPSYS

 RCS:$Id$

=head1 DESCRIPTION

=head1 HISTORY

 ORIGIN: created from templateApp.pl version 3.4 by Min-Yen Kan <kanmy@comp.nus.edu.sg>

 RCS:$Log$

=cut

require 5.0;
use Getopt::Std;
# use strict 'vars';
# use diagnostics;

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; }		      # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "1.0";
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
  print STDERR "       $progname [-q] filename(s)...\n";
  print STDERR "Options:\n";
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
  print STDERR "# Copyright 2004 \251 by Min-Yen Kan\n";
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
getopts ('hqv');

# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		# call License, if asked for
if ($opt_v) { Version(); exit(0); }	# call Version, if asked for
if ($opt_h) { Help(); exit (0); }	# call help, if asked for

## standardize input stream (either STDIN on first arg on command line)
my $fh;
my $filename;
if ($filename = shift) {
 NEWFILE:
  if (!(-e $filename)) { die "# $progname crash\t\tFile \"$filename\" doesn't exist"; }
  open (IF, $filename) || die "# $progname crash\t\tCan't open \"$filename\"";
  $fh = "IF";
} else {
  $filename = "<STDIN>";
  $fh = "STDIN";
}

while (<$fh>) {
  if (/^\#/) { next; }			# skip comments
  elsif (/^\s+$/) { next; }		# skip blank lines
  else {
    chop;
    my ($answer, $guess) = split (/\s+/);
    $total++;
    $confMatrix{$answer}{$guess}++;
    $answers{$answer} = 1;
    $answers{$guess} = 1;
  }
}
close ($fh);

my $totalPrec = 0;
my $totalRec = 0;
my $totalF1 = 0;
my $totalCorrect = 0;
my %f1 = ();
foreach my $guess (sort keys %answers) {
  if ($guess eq "UNDEFINED") { next; }
  my $precDenom = 0;
  my $recDenom = 0;
  foreach my $cat (sort keys %answers) {
    $recDenom += (defined $confMatrix{$cat}{$guess}) ? $confMatrix{$cat}{$guess} : 0;
    $precDenom += (defined $confMatrix{$guess}{$cat}) ? $confMatrix{$guess}{$cat} : 0;
  }
  my $catCorrect = (defined $confMatrix{$guess}{$guess}) ? $confMatrix{$guess}{$guess} : 0;
  my $prec = ($precDenom == 0) ? 0 : ($catCorrect/$precDenom);
  my $rec = ($recDenom == 0) ? 0 : ($catCorrect/$recDenom);
  my $f1 = (($rec + $prec) == 0) ? 0 : (2 * $prec * $rec) / ($rec + $prec);
  #      print "$precDenom $recDenom $catCorrect\n";
  printf ("%s\tRd\t$recDenom\tPd\t$precDenom\tCC\t$catCorrect\tP\t%2.2f\tR\t%2.2f\tF\t%2.2f\n", 
	  $guess, $prec, $rec, $f1);
  $f1{$guess} = $f1;
  $totalPrec += $prec;
  $totalRec += $rec;
  $totalCorrect += $catCorrect;
  $totalF1 += $f1;
}
my $numCat = scalar (keys %answers) - 1;			    # BUG: for undefined
printf ("Total %d TotalCat %d Acc %4.4f TP: %4.4f TR: %4.4f TF1: %4.4f\n", 
	$total, $numCat, ($totalCorrect/$total), $totalPrec/$numCat, $totalRec/$numCat, $totalF1/$numCat);

# show confusion matrix
if (1) {
  print "Gold standard answers in rows, system guess in columns\n";
  foreach my $guess (sort keys %answers) {
    print "\t$guess";
  }
  print "\n";
  foreach my $answer (sort keys %answers) {
    print "$answer";
    foreach my $guess (sort keys %answers) {
      print "\t$confMatrix{$answer}{$guess}";
    }
    printf ("\t%3.3f\n",$f1{$answer});
  }
  print "\n";
}

if ($filename = shift) {
  goto NEWFILE;
}

###
### END of main program
###
