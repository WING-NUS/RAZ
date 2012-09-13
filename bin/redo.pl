#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

redo.pl

=head1 SYNOPSYS

 RCS:$Id$

=head1 DESCRIPTION

=head1 HISTORY

 ORIGIN: created from templateApp.pl version 3.4 by Min-Yen Kan <kanmy@comp.nus.edu.sg>

 RCS:$Log$

=cut

require 5.0;

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; }		      # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $installDir = "/home/wing.nus/tools/citationTools/raz/";
my $binDir = "$installDir/bin/";
my $inputDir = "$installDir/input/";
my $tmpDir = "$installDir/tmp/";
my $outputVersion = "1.0";
my $numFolds = 10;
### END user customizable section

### Ctrl-C handler
sub quitHandler {
  print STDERR "\n# $progname fatal\t\tReceived a 'SIGINT'\n# $progname - exiting cleanly\n";
  exit;
}
$SIG{'INT'} = 'quitHandler';

opendir(DIR, "$inputDir") || die "can't opendir .: $!";
my @inputFiles = grep { /\.annot/ } readdir(DIR);
for (my $i = 0; $i <= $#inputFiles; $i++) {
  $inputFiles[$i] = "$inputDir/$inputFiles[$i]";
}
closedir DIR;

my $cmd = "";
my $i = 0;

my $numFiles = scalar(@inputFiles);
my $numFilesPerFold = $numFiles / $numFolds;
my $fold = 0;
my $j = 0;
my @inputFold = ();
for (my $i = 0; $i <= $#inputFiles; $i++) {
  push (@{$inputFold[$fold]}, $inputFiles[$i]);
  $j++;

  if ($j == $numFilesPerFold) {
    $fold++;
    $j = 0;
  }
}

# prepare data fold files

if (1) {  # redo the feature generation / sentence delimitation / etc?
  if (!-e $tmpDir) {
    $cmd = "mkdir $tmpDir";
    `$cmd`;
  }
  $cmd = "rm -f $tmpDir/fold.[1234567890]\n"; # kill off old files
  `$cmd`;
  print $cmd;
  for (my $i = 0; $i <= $#inputFold; $i++) {
    print "==> creating data for fold # $i\n";
    foreach my $file (@{$inputFold[$i]}) {
      $cmd = "$binDir/annot2txt.pl $file > $tmpfile.1";
      print "$cmd\n";
      system($cmd);
      $cmd = "$binDir/txt2tag.pl -a $tmpfile.1 > $tmpfile.2";
      print "$cmd\n";
      system($cmd);
      $cmd = "$binDir/tag2feats.pl $tmpfile.2 >> $tmpDir/fold.$i";
      print "$cmd\n";
      system($cmd);
    }
  }
}

# prepare training and testing data
# do testing
my @resultFiles = ();
$cmd = "rm -f out.[1234567890] detail.[1234567890] train.[1234567890]\n"; # kill off old files
`$cmd`;
print $cmd;
if (!-e $tmpDir) {
    $cmd = "mkdir $tmpDir";
    `$cmd`;
}
for (my $i = 0; $i <= $#inputFold; $i++) {
  print "> Doing fold $i\n";
  push (@resultFiles, "$tmpDir/result.$i");
  my @trainingFiles = ();
  for (my $j = 0; $j <= $#inputFold; $j++) {
    if ($i == $j) { next; }
    push (@trainingFiles, "$tmpDir/fold.$j");
  }

  if (1) { # redo the learning?
    $cmd = "cat " . join(" ", @trainingFiles) . " > $tmpDir/train.$i";
    print "$cmd\n";
    system($cmd);

    # train
    $cmd = "$binDir/maxent -m $tmpDir/model.$i -i 50 $tmpDir/train.$i";
    print "$cmd\n";
    system($cmd);

    # test ("fold" files are test)
    $cmd = "$binDir/maxent -m $tmpDir/model.$i -p $tmpDir/fold.$i -o $tmpDir/out.$i";
    print "$cmd\n";
    system($cmd);

    $cmd = "$binDir/maxent -m $tmpDir/model.$i -p $tmpDir/fold.$i --detail -o $tmpDir/detail.$i";
    print "$cmd\n";
    system($cmd);
  }

  $cmd = "cut -f 1 -d \" \" $tmpDir/fold.$i | paste $tmpDir/out.$i - > $tmpDir/result.$i";
  print "$cmd\n";
  system($cmd);
}
$cmd = "cat " . join(" ", @resultFiles) . " > $tmpDir/results.all.tsv";
print "$cmd\n";
system($cmd);

$cmd = "$binDir/scores.pl $tmpDir/results.all.tsv";
print "$cmd\n";
system($cmd);

# clean up
`/bin/rm -f $tmpfile*`;
