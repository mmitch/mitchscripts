#!/usr/bin/perl -w
# (c) 2008 by Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2
#
# split files on a string
#
# usage:
#     split.pl STRING INPUTFILE
#
use strict;

my $split = shift;
my $in = shift;
open IN, '<', $in or die "can't read `$in': $!";
$/ = undef;
my $slurp = <IN>;

my $file = 'out000';
foreach my $wav (split /$split/, $slurp) {
    open OUT, '>', $file.'.wav' or die "can't write `$file.wav': $!";
    print OUT $split;
    print OUT $wav;
    close OUT or die "can't close `$file.wav': $!";
    $file++;
}

close IN or die "can't close `$in': $!";
