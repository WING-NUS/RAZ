#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

tag2feats.pl

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
use DB_File;
# use diagnostics;

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; } # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "1.0";
my $defaultInputMode = "rawText";
my $installDir = "/home/wing.nus/tools/citationTools/raz/";
my $singleCPHashLoc = "$installDir/lib/singleCP.db";
my $multiCPHashLoc = "$installDir/lib/multiCP.db";
my $stoplistHashLoc = "$installDir/lib/stoplist.db";
my $TITLE_WORD_WORDCOUNT_THRESHOLD = 100; # number of title words to consider
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
}

### VERSION Sub-procedure
sub Version {
  if (system ("perldoc $0")) {
    die "Need \"perldoc\" in PATH to print version information";
  }
  exit;
}

sub License {
  print STDERR "# Copyright 2007 \251 by Min-Yen Kan\n";
}

###
### MAIN program
###

# Porter stemmer initialization
my %step2list;
my %step3list;
my ($c, $v, $C, $V, $mgr0, $meq1, $mgr1, $_v);
my %stemHash = ();
initialise();

my $cmdLine = $0 . " " . join (" ", @ARGV);
if ($#ARGV == -1) { 		        # invoked with no arguments, possible error in execution? 
  Help();
}

# tie hashes into program
my %multiCPHash;
my %singleCPHash;
my %stoplistHash;
tie(%multiCPHash,'DB_File', $multiCPHashLoc, O_RDONLY, 0644, $DB_HASH) || die "Database \"$multiCPHashLoc\" not found!";
tie(%singleCPHash,'DB_File', $singleCPHashLoc, O_RDONLY, 0644, $DB_HASH) || die "Database \"$singleCPHashLoc\" not found!";
tie(%stoplistHash,'DB_File', $stoplistHashLoc, O_RDONLY, 0644, $DB_HASH) || die "Database \"$stoplistHashLoc\" not found!";

$SIG{'INT'} = 'quitHandler';
getopts ('hqv');

our ($opt_q, $opt_v, $opt_h);
# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		# call License, if asked for
if ($opt_v) { Version(); exit(0); }	# call Version, if asked for
if ($opt_h) { Help(); exit (0); }	# call help, if asked for
my $inputMode = $defaultInputMode;

## standardize input stream (either STDIN on first arg on command line)
my $fh;
my $filename;
if ($filename = shift) {
 NEWFILE:
  if (!(-e $filename)) { die "# $progname crash\t\tFile \"$filename\" doesn't exist"; }
  open (*IF, $filename) || die "# $progname crash\t\tCan't open \"$filename\"";
  $fh = "IF";
}

# get number of sentences
my $lines = 0;
while (<$fh>) {
  $lines++;
}
$lines++;			      # add one line for # format line
my $numLines = $lines;
seek (IF, 0, 0);
$lines = 0;						 # reset lines

my @features = ();
my @labels = ();
my %titleWords = (); # tokens in the first TITLE_WORD_WORDCOUNT_THRESHOLD words up to "introduction" or "abstract"
my $titleWordCounter = 0;
while (<$fh>) {
  if (/^\# flat file from annot input, v1.0/) { $inputMode = "annot"; }
  elsif (/^\# flat file from txt input, v1.0/) { $inputMode = "rawText"; }
  elsif (/^\#/) { next; }			       # skip comments
  elsif (/^\s+$/) { next; }			    # skip blank lines
  else {
    my $label = "";
    my $words = "";
    if ($inputMode eq "annot") {
      ## preprocessing
      chop;
      my @elts = split (/\t/);
      $words = $elts[0];
      $label = $elts[1];
    } else {						# rawText mode
      chop;
      $words = $_;
      $label = "UNDEFINED";
    }

    my @words = split (/ /,$words);
    my @tokens = ();
    my @pos = ();
    my @stems;
    my %overlapTitleWords = ();
    # split off pos tags
    for (my $i = 0; $i <= $#words; $i++) {
      ($tokens[$i], $pos[$i]) = split (/\_/,$words[$i]);
      $tokens[$i] = lc($tokens[$i]);
      $tokens[$i] =~ s/[^a-z0-9]$//g;
      $stems[$i] = stem($tokens[$i]);
      $stems[$i] = "STEMS$stems[$i]";
      if (defined $titleWords{$tokens[$i]}) { $overlapTitleWords{$tokens[$i]} = 1; }

      # build up title words
      if ($titleWordCounter < $TITLE_WORD_WORDCOUNT_THRESHOLD) {
	if ($tokens[$i] eq "introduction" ||
	    $tokens[$i] eq "abstract") {
	  $titleWordCounter = $TITLE_WORD_WORDCOUNT_THRESHOLD;
	} else {
	  if (!defined $stoplistHash{$tokens[$i]}) { $titleWords{$tokens[$i]} = 1; }
	}
      }
      $titleWordCounter++;
    }
    my $tokensBuf = join(" ", @tokens);
    my $stemsBuf = join(" ", @stems);

    ## feature generation

    # position features
    my $relPosition = int($lines/$numLines*10);	   # finer grained pos
    my $relPosition2 = int($lines/$numLines*5);
    my $absPosition = int($lines/50);		   # rougher grained pos
    my $absPosition2 = int($lines/10);
    my $position = "REL_POSITION$relPosition ABS_POSITION$absPosition REL_POSITION2_$relPosition2 ABS_POSITION2$absPosition2";

    # construct bigrams
    my @bigrams = ();					       # clear
    my @bigramStems = ();				       # clear
    for (my $i = 0; $i < $#words; $i++) {
      push (@bigrams, ($words[$i] . "_" . $words[$i+1]));
      push (@bigramStems, ($stems[$i] . "_" . $stems[$i+1]));
    }
    my $bigramBuf = join(" ", @bigrams);
    my $bigramStemsBuf = join(" ", @bigramStems);

    # construct trigrams
    my @trigrams = ();				       # clear
    for (my $i = 0; $i < ($#words-1); $i++) {
      push (@trigrams, ($words[$i] . "_" . $words[$i+1] . "_" . $words[$i+2]));
    }
    my $trigramBuf = join(" ", @trigrams);

    # cue phrase/word features
    my %cuePhraseHash = ();				       # clear

    for (my $i = 0; $i <= $#tokens; $i++) {
      if (defined $singleCPHash{$tokens[$i]}) { $cuePhraseHash{$singleCPHash{$tokens[$i]}}++; }
      elsif (defined $multiCPHash{"$tokens[$i] $tokens[$i+1]"}) { $cuePhraseHash{$multiCPHash{"$tokens[$i] $tokens[$i+1]"}}++; }
      elsif (defined $multiCPHash{"$tokens[$i] $tokens[$i+1] $tokens[$i+2]"}) { $cuePhraseHash{$multiCPHash{"$tokens[$i] $tokens[$i+1] $tokens[$i+2]"}}++; }
      elsif (defined $multiCPHash{"$tokens[$i] $tokens[$i+1] $tokens[$i+2] $tokens[$i+3]"}) { $cuePhraseHash{$multiCPHash{"$tokens[$i] $tokens[$i+1] $tokens[$i+2] $tokens[$i+3]"}}++; }
    }

    my $cuePhraseBuf = "";
    foreach my $cp (keys %cuePhraseHash) {
      $cuePhraseBuf .= "CP$cp ";
    }

    ## KISS citation detector - citation feature
    # 1. year
    my $citeBuf = "";
    my $citeCount = 0;
    while ($words =~ /\b(19|20)\d\d/g) {
      $citeCount++;
    }
    if ($citeCount != 0) { $citeBuf .= "CITEyear "; }
    # 2. et al.
    if ($words =~/\bet_[^ ]+ al/) {
      $citeBuf .= "CITEetal ";
    }
    $citeBuf .= "CITEcount$citeCount";

    # sentence length feature
    my $sentLength = int(scalar(@words) / 10);
    $sentLength = "SENTLENGTH$sentLength";

    # KISS agent and verb
    my $agentBuf = "";
    my $verbBuf = "";
    my $remainder = "";
    if ($words =~ /\b([^ _]+(_N|_PRP)[A-Z]*)\b/) {
      $agentBuf = "AGENT" . lc($1);
      $remainder = $';
      if ($remainder =~ /\b([^ _]+(_V)[A-Z]*)\b/) {
	my $verb = $1;
	$verbBuf = "VERB" . lc($verb);
	$verb =~ /(.+)\_(.+)/;
	$verbBuf .= " VERBTENSE" . lc($2);
	$verb = $1;				    # save actual verb
	if (defined $singleCPHash{$verb}) { # check whether verb is cue phrase
	  $verbBuf .= " VERBASCP" . lc($verb);
	}
      }
    }

    # overlapping title words
    my $otwBuf = "";
    foreach my $overlapTitleWord (keys %overlapTitleWords) {
      $otwBuf .= "OTW_$overlapTitleWord ";
    }

    ## assemble features
    $features[$lines] = "$tokensBuf $position $otwBuf $cuePhraseBuf $citeBuf $sentLength $agentBuf $verbBuf $words $bigramBuf $trigramBuf $stemsBuf $bigramStemsBuf ";
    $labels[$lines] = $label;

    $lines++;					   # increment counter
  }
}

# write out instances with contextual label features
my %seenTag = ();
for (my $i = 0; $i <= $#labels; $i++) {
  print "$labels[$i] $features[$i]";

  if ($inputMode eq "annot" && 0) {
    if ($i == 0) { print " PREVLABELundefined" ; }
    else { print " PREVLABEL" . lc($labels[$i-1]); }

    if ($i <= 1) { print " PPLABELundefined" ; }
    else { print " PPLABEL" . lc($labels[$i-2]); }

    if ($i == $#labels) { print " NEXTLABELundefined" ; }
    else { print " NEXTLABEL" . lc($labels[$i+1]); }

    if ($i >= ($#labels-1)) { print " NNLABELundefined" ; }
    else { print " NNLABEL" . lc($labels[$i+2]); }

    foreach my $seenTag (keys %seenTag) {
      print " SEENTAG$seenTag";
    }
  }
    print "\n";

  # update which tags already seen
  $seenTag{$labels[$i]}++;
}
close ($fh);

if ($filename = shift) {
  goto NEWFILE;
}

###
### END of main program
###


# Porter stemmer in Perl. Few comments, but it's easy to follow against the rules in the original
# paper, in
#
#   Porter, 1980, An algorithm for suffix stripping, Program, Vol. 14,
#   no. 3, pp 130-137,
#
# see also http://www.tartarus.org/~martin/PorterStemmer

# Release 1


sub stem {
  my ($stem, $suffix, $firstch);
  my $w = shift;
  my $orig = $w;
  if (defined $stemHash{$w}) { return $stemHash{$w}; }
  if (length($w) < 3) { return $w; } # length at least 3
  # now map initial y to Y so that the patterns never treat it as vowel:
  $w =~ /^./; $firstch = $&;
  if ($firstch =~ /^y/) { $w = ucfirst $w; }

  # Step 1a
  if ($w =~ /(ss|i)es$/) { $w=$`.$1; }
  elsif ($w =~ /([^s])s$/) { $w=$`.$1; }

  # Step 1b
  if ($w =~ /eed$/) { if ($` =~ /$mgr0/o) { chop($w); } }
  elsif ($w =~ /(ed|ing)$/) {
    $stem = $`;
    if ($stem =~ /$_v/o) {
      $w = $stem;
      if ($w =~ /(at|bl|iz)$/) { $w .= "e"; }
      elsif ($w =~ /([^aeiouylsz])\1$/) { chop($w); }
      elsif ($w =~ /^${C}${v}[^aeiouwxy]$/o) { $w .= "e"; }
    }
  }
  # Step 1c
  if ($w =~ /y$/) { $stem = $`; if ($stem =~ /$_v/o) { $w = $stem."i"; } }

  # Step 2
  if ($w =~ /(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$/) {
    $stem = $`; $suffix = $1;
    if ($stem =~ /$mgr0/o) { $w = $stem . $step2list{$suffix}; }
  }

  # Step 3
  if ($w =~ /(icate|ative|alize|iciti|ical|ful|ness)$/) {
    $stem = $`; $suffix = $1;
    if ($stem =~ /$mgr0/o) { $w = $stem . $step3list{$suffix}; }
  }

  # Step 4
  if ($w =~ /(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$/)
    { $stem = $`; if ($stem =~ /$mgr1/o) { $w = $stem; } }
  elsif ($w =~ /(s|t)(ion)$/)
    { $stem = $` . $1; if ($stem =~ /$mgr1/o) { $w = $stem; } }

  #  Step 5
  if ($w =~ /e$/)
    { $stem = $`;
      if ($stem =~ /$mgr1/o or
	  ($stem =~ /$meq1/o and not $stem =~ /^${C}${v}[^aeiouwxy]$/o))
	{ $w = $stem; }
    }
  if ($w =~ /ll$/ and $w =~ /$mgr1/o) { chop($w); }

  # and turn initial Y back to y
  if ($firstch =~ /^y/) { $w = lcfirst $w; }
  $stemHash{$orig} = $w;
  return $w;
}

sub initialise {
  %step2list =
    ( 'ational'=>'ate', 'tional'=>'tion', 'enci'=>'ence', 'anci'=>'ance', 'izer'=>'ize', 'bli'=>'ble',
      'alli'=>'al', 'entli'=>'ent', 'eli'=>'e', 'ousli'=>'ous', 'ization'=>'ize', 'ation'=>'ate',
      'ator'=>'ate', 'alism'=>'al', 'iveness'=>'ive', 'fulness'=>'ful', 'ousness'=>'ous', 'aliti'=>'al',
      'iviti'=>'ive', 'biliti'=>'ble', 'logi'=>'log');
  %step3list =
    ('icate'=>'ic', 'ative'=>'', 'alize'=>'al', 'iciti'=>'ic', 'ical'=>'ic', 'ful'=>'', 'ness'=>'');
  $c =    "[^aeiou]";          # consonant
  $v =    "[aeiouy]";          # vowel
  $C =    "${c}[^aeiouy]*";    # consonant sequence
  $V =    "${v}[aeiou]*";      # vowel sequence
  $mgr0 = "^(${C})?${V}${C}";               # [C]VC... is m>0
  $meq1 = "^(${C})?${V}${C}(${V})?" . '$';  # [C]VC[V] is m=1
  $mgr1 = "^(${C})?${V}${C}${V}${C}";       # [C]VCVC... is m>1
  $_v   = "^(${C})?${v}";                   # vowel in stem
}

