#!/usr/bin/env perl
#
#   renumber.pl  -  renumber lists of files
#   Copyright (C) 2020  Christian Garbs <mitch@cgarbs.de>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
#  usage:  renumber.pl [dir]
#
#  This program reads all files from the given directory (or the current
#  directory, if no directory is given) and checks them for a common prefix
#  and common suffix.  If neither a common prefix or common suffix can be
#  found, the program exits.
#
#  In the next step file filenames are stripped by their prefix and suffix.
#  If the remaining strings are not all numeric, the program exits.
#
#  The files are then renamed by prefixing their numeric middle part with
#  zeros so that all files are of the same length.
#
#  example:
#  --------
#
#  The filenames (in alphabetical order)
#
#    photo1.jpg
#    photo10.jpg
#    photo21.jpg
#    photo4.jpg
#
#  have the common prefix 'photo' and the common suffix '.jpg'.
#  Their middle parts are all numeric.
#
#  They get renamed to
#
#    photo01.jpg
#    photo10.jpg
#    photo21.jpg
#    photo04.jpg
#
#  Now their alphabetical order makes more sense:
#
#    photo01.jpg
#    photo04.jpg
#    photo10.jpg
#    photo21.jpg
#
#
#  If there were another file like 'photo.txt' in the directory,
#  no common suffix would have been found and the program would
#  exit before wreaking havok with bogus renames.
#

use strict;
use warnings;

sub get_files() {
    opendir my $dh, '.' or die "can't opendir: $!";
    my @files = grep { -f $_ && ! -x _ } readdir($dh);
    closedir $dh or die "can't closedir: $!";
    return @files;
}

sub find_longest_common_prefix(@) {
    my (@in) = @_;
    my $prefix = shift @in;
    foreach my $in (@in) {
	while (substr($in, 0, length $prefix) ne $prefix) {
	    $prefix = substr $prefix, 0, length($prefix) - 1;
	    die "no common prefix" unless length $prefix;
	}
    }
    return $prefix;
}

sub find_longest_common_suffix(@) {
    my (@in) = @_;
    my $suffix = shift @in;
    foreach my $in (@in) {
	while (substr($in, 0 - length($suffix)) ne $suffix) {
	    $suffix = substr $suffix, 1;
	    die "no common suffix" unless length $suffix;
	}
    }
    return $suffix;
}

sub get_middle_parts($$@) {
    my ($prefix, $suffix, @in) = @_;
    my $start  = length $prefix;
    my $remove = length $suffix;
    my @middle;
    return map {
	my $in = $_;
	my $middle = substr $in, $start;
	$middle = substr $middle, 0, -$remove;
	die "middle <$middle> not numeric in <$in>" unless $middle =~ /^\d+$/;
	$middle;
    } @in;
}

sub get_longest_length(@) {
    my (@in) = @_;
    my $longest = 0;
    foreach my $in (@in) {
	next unless length $in > $longest;
	$longest = length $in;
    }
    return $longest;
}

my $dir = $ARGV[0] // '.';

my @files = get_files();

die "no files found" unless @files;

# print "$_\n" foreach @files;

my $prefix = find_longest_common_prefix(@files);
my $suffix = find_longest_common_suffix(@files);

print "prefix: <$prefix>\n";
print "suffix: <$suffix>\n";

my @middles = get_middle_parts($prefix, $suffix, @files);

die "middle part <$_> not numeric\n" foreach grep { $_ !~ /^\d+$/  } @middles;

my $maxlen = get_longest_length(@middles);

# print "maxlen: $maxlen\n";

my $middle_pattern = '%0'.$maxlen.'d';
my $total_pattern  = '%0'.( length($prefix) + $maxlen + length($suffix) ).'s';

print "pattrn: <$middle_pattern>\n";
print "\n";

foreach my $middle (sort { $a <=> $b } @middles) {
    my $old = $prefix.$middle.$suffix;
    my $new = $prefix.sprintf($middle_pattern, $middle).$suffix;
    my $task;
    if ($old ne $new) {
	$task = '-->';

	# this check is not atomic, but using 'mv -n' will save us in that case
	die "won't rename <$old> to <$new>, target exists\n" if -e $new;

	system 'mv', '-n', $old, $new or die "can't rename <$old> to <$new>: $!$?\n";
    } else {
	$task = ' = ';
    }
    printf "$total_pattern  %s  $total_pattern\n", $old, $task, $new;
}
