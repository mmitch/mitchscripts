#!/usr/bin/perl -w
# 2009 (c) by Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2
use strict;



### process arguments
#

sub die_help()
{
    print STDERR << "EOF";
usage:
    sansafill.pl --shuffle /path/to/shuffle
    sansafill.pl --fill /source/path /target/path kB_free
EOF
    ;
    exit 1;
}

my ($mode, $source, $target, $minfree);

die_help() unless @ARGV > 0;

if ($ARGV[0] eq '--shuffle' and @ARGV == 2) {
    $mode = 1;
    $source = $ARGV[1];
    $target = $ARGV[1];
    die "srcpath does not exist" unless -d $source;
} elsif ($ARGV[0] eq '--fill' and @ARGV == 4) {
    $mode = 2;
    $source = $ARGV[1];
    $target = $ARGV[2];
    $minfree = $ARGV[3];
} else {
    die_help();
}

die "source path `$source' does not exist" unless -d $source;
die "target path `$target' does not exist" unless -d $target;



### gather input files
#

use File::Find;
my @files;

sub wanted()
{
    return unless -f $File::Find::name;
    return unless -r _;
    return unless $File::Find::name =~ /\.mp3$/;
    push @files, $File::Find::name;
}

find(\&wanted, ($source));



### shuffle
#

use List::Util 'shuffle';

@files = shuffle(@files);



### do something
#

sub diskfree($) {
    # poor man's df
    # if you want it portable, use Filesys::Statvfs
    my $dir = shift;
    my $size;

    open DF, "df -P $dir|" or warn "can't open df: $!";
    my $line = <DF>; # skip header

    if ( $line = <DF> ) {
        if ($line =~ /\s(\d+)\s+\d{1,3}% (\/.*)$/) {
            $size = $1;
        }
    } else {
        $size = -1; #some error occurred
    }

    close DF or warn "can't close df: $!";
    return $size;
}

if ($mode == 2) {
    use File::Copy;
    $|++;
}
my $filename = 'aaaaaaaa';

foreach my $file (@files) {

    if ($mode == 1) {

	rename $file, $target.'/'.$filename.'.X.mp3';

    } else {

	my $newfile = $target.'/'.$filename.'.mp3';
	while (-e $newfile) {
	    $filename++;
	    $newfile = $target.'/'.$filename.'.mp3';
	}

	my $free = diskfree $target;
	last if $free < $minfree;
	next if $free*1024 < (stat($file))[7];

	my ($sec,$min,$hour,undef) = localtime(time);
	my $name = $file;
	$name =~ s|^.*/||;
	printf '[%02d:%02d:%02d] (%7dk) %s...', 
	$hour, $min, $sec,
	int $free,
	$name
	    ;

	copy( $file, $newfile.'.tmp' ) or die "could not copy `$file': $!";
	rename $newfile.'.tmp', $newfile;

	print "OK\n";

    }

    $filename++;
}

if ($mode == 1) {
    chdir $target;
    opendir FILES, $target or die $!;
    while (my $file = readdir FILES) {
	if ($file =~ /^(.*)\.X\.mp3$/i and -f $file) {
	    rename $file, $1.'.mp3';
	}
    }
    closedir FILES or die $!;
}
