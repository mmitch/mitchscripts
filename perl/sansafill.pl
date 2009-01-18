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
    sansafill.pl --fill /source/path /target/path MB_free
EOF
    ;
    exit 1;
}

my ($mode, $source, $target, $free);

die_help() unless @ARGV > 0;

if ($ARGV[0] eq '--shuffle' and @ARGV == 2) {
    $mode = 1;
    $source = $ARGV[1];
    $target = $ARGV[1];
} elsif ($ARGV[0] eq '--fill' and @ARGV == 4) {
    $mode = 2;
    $source = $ARGV[1];
    $target = $ARGV[2];
    $free = $ARGV[3];
} else {
    die_help();
}



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

my $filename = 'aaaaaaaa';

foreach $file (@files) {
    
    

}
