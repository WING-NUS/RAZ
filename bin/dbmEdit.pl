#!/usr/bin/perl
# $Id: dbmEdit,v 1.10 2001/09/15 01:28:15 min Exp min $ / Min-Yen Kan 
#
#	GDBM line editor utility
#
#	RCS: $Id: dbmEdit,v 1.10 2001/09/15 01:28:15 min Exp min $
#
#	RCS: $Log: dbmEdit,v $
#	RCS: Revision 1.10  2001/09/15 01:28:15  min
#	RCS: Added -D dump switch
#	RCS:
#	RCS: Revision 1.9  2000/02/19 20:41:43  min
#	RCS: changed $0 to $progname.
#	RCS:
#	RCS: Revision 1.8  2000/02/10 18:16:57  min
#	RCS: Corrected small typo in getops lib.
#	RCS:
#	RCS: Revision 1.7  2000/02/10 18:12:42  min
#	RCS: Updated to perl 5 libraries.
#	RCS: Removed flush library.
#	RCS:
#	RCS: Revision 1.6  2000/01/09 00:11:42  min
#	RCS: Converted source control to RCS
#	RCS:
#	RCS: Revision 1.5  2000/01/09 00:11:23  min
#	RCS: added -v option and functionality
#	RCS: canonicalized name to dbmEdit
#	RCS: added Ctrl-C handler and license
#	RCS: fixed small bug in return function
#	RCS: fixed add option such that adding fields with tabs works
#	RCS:
#	RCS: Revision 1.1  2000/01/09 00:09:35  min
#	RCS: Initial revision
#	RCS:
#
require 5.0;
use DB_File;							      # perl5 library
use Getopt::Std;						      # perl5 library
$0 =~ /([^\/]+)$/; $progname = $1;
$progname =~ s/(\..+)//g;

### HELP Sub-procedure
sub Help {
    print STDERR "usage: $progname -h\t\t\t\t[invokes help]\n";
    print STDERR "       $progname -v\t\t\t\t[invokes version]\n";
    print STDERR "       $progname [-dD] [-f <command_file>] [-q] [db_filename]\n";
    print STDERR "\n";
    print STDERR "-c\tcreate the database\n";
    print STDERR "-D\tdump database into text file, ready to recompiled by -f\n";
    print STDERR "-d\tuse GDBM .dir and .pag files instead of DB files\n";
    print STDERR "-f\tread $progname commands from <command_file>\n";
    print STDERR "-q\tquiet mode (for STDIN input mode)n";
    print STDERR "\n";
    print STDERR "Assumes input on STDIN if no filename given.\n";
    print STDERR "Assumes database is named \"index\" if no alternate name is given.\n";
    print STDERR "\n";
}

### VERSION Sub-procedure
sub Version {
    open (IF, $progname);
    while (<IF>) {
	if (/^\#/) { 
	    if (/^\#\!/) { next; } else { s/^\#//; print STDERR $_; }
	} else { last; }
    }
}

### Ctrl-C handler
sub quitHandler {
    print STDERR "\n# $progname fatal - received a 'SIGINT'\n# $progname - exiting cleanly";
    print STDERR "\n";
    exit -1;
}

### print LICENSE
sub License {
    print STDERR "Copyright \251 1998 by The Trustees of Columbia University in the City of\n";
    print STDERR "New York.  All rights reserved.  This software is being provided at no cost\n";
    print STDERR "for educational and/or research purposes only.\n";
}

###
### MAIN program
###

$SIG{'INT'} = 'quitHandler';
getopts ('hcdDqf:v');

if ($opt_h) { &Help; &License; exit (0); }            # call help, if asked for
if ($opt_v) { &Version; &License; exit (0); }	      # call version, if asked for
if (!$opt_q) { &License; }			      # shut up, if asked for

# initialize and open database file
if (!($dbmFile = shift)) { $dbmFile = "index"; }
if ($opt_c) {
    if ($opt_d) {
	dbmopen (%db, $dbmFile, 0644) ||
	    die "Cannot create database \"$dbmFile\"";
    } else {
	tie (%db, 'DB_File', $dbmFile, O_RDWR | O_CREAT, 0644, $DB_HASH) || 
	    die "Cannot create database \"$dbmFile\"";
    }
} else {
    if ($opt_d) {
	dbmopen (%db, $dbmFile, 0644) ||
	    die "Database \"$dbmFile\" not found, use -c to create";
    } else {
	tie (%db, 'DB_File', $dbmFile, O_RDWR, 0644, $DB_HASH) || 
	    die "Database \"$dbmFile\" not found, use -c to create";
    }
}
    
## standardize input stream (either STDIN or $opt_f or $opt_D)
if ($opt_D) {
    while (($key,$value) = each %db) {
        print "a\t$key\t$value\n";
    }
    exit;
} elsif ($opt_f) {
    $filename = $opt_f;
    if (!(-e $filename)) { die "$progname crash\t\tFile $filename doesn't exist"; }
    open (IF, "$filename") || die "$progname crash\t\tCan't open \"$filename\"";
    $fh = "IF";
} else {
    $filename = "<STDIN>";
    $fh = "STDIN";
}

if ($fh eq "STDIN" && !$opt_q) { 
    print STDERR "Welcome to dbmEdit.  For help type \"h\"\n\n";
    print STDERR "dbmEdit> ";
}

while (<$fh>) {
    $val = &Process ($_);
    # print "[$val]\n";
    if ($val == 2) { last; }
    if ($fh eq "STDIN") { print STDERR "dbmEdit> "; }
}

## Finish up
if ($opt_d) {
    dbmclose %db;
} else {
    untie %db;
}

###
### END of main program
###

### OTHER subroutines
sub Process {
    local($line) = pop @_;
    local($command, $arg1, $arg2) = ("","","");
    chop $line;
    if ($line =~ /^([^\t]+)\t([^\t]+)\t(.+)/) {
	$command = $1;
	$arg1 = $2;
	$arg2 = $3;
    } elsif ($line =~ /^([^\t]+)\t(.+)/) {
	$command = $1;
	$arg1 = $2;
    } elsif ($line =~ /^(.+)/) {
	$command = $1;
    } else {
	&ErrCommand;
    }

#    print "[$command][$arg1][$arg2]";
    if ($command eq "h") { &HelpCommands; }
    elsif ($command eq "a") { 
	if (!$opt_q) { print STDERR "Adding key $arg1 with value $arg2\n"; }
	$db{$arg1} = $arg2;
    } elsif ($command eq "d") { 
	if (!$opt_q) { print STDERR "Deleting key $arg1 with value ", $db{$arg1}, "\n"; }
	delete $db{$arg1};
    } elsif ($command eq "s") { 
	if (!$opt_q) { print STDERR "Showing database key $arg1\n"; }
	print "Key's value = \"", $db{$arg1}, "\"\n";
    } elsif ($command eq "v") {
	if (!$opt_q) { print STDERR "Showing database keys/vals that match pattern $arg1\n"; }
	foreach $key (keys %db) {
	    if ($key =~ /$arg1/) {
		print "$key\t$db{$key}\n";
	    }
	}
    } elsif ($command eq "q") {
	if (!$opt_q) { print STDERR "Quitting and saving database...\n"; }
	return 2;
    }
    return 0;
}

sub HelpCommands {
    print STDERR "dbmEdit help menu\n\n";
    print STDERR "All commands are in the format of:\n";
    print STDERR "\tcommand <TAB> arg1 <TAB> arg2\n\n";
    print STDERR "Commands are:\n";
    print STDERR "\th\tthis help screen\n";
    print STDERR "\ta\tadd key arg1 with value arg2\n";
    print STDERR "\td\tdelete key arg1\n";
    print STDERR "\ts\tshow key arg1's value\n";
    print STDERR "\tv\tshow k/v pairs with keys matching perl regexp arg1\n";
    print STDERR "\tq\tquit and save\n";
    print STDERR "\n";
    print STDERR "NOTE: there is no way to undo an action!\n";
    print STDERR "\n";
}

sub ErrCommand {
    print STDERR "## Couldn't understand your command!\n";
}
