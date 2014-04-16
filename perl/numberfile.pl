#!/usr/bin/perl -w
use strict;
use File::Copy 'mv';

# reads a list of filenames and renames the files in the given order with '%04d-' prepended
# (persists the sequence of a manually sorted list of files via their filenames)

my $count = '0001';

while (my $filename = <>)
{
    chomp $filename;
    mv($filename, $count.'-'.$filename) or die $!;
    $count++;
}
