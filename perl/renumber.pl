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
#  and common suffix.
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
    die "ERROR: no files found" unless @files;
    return @files;
}

sub find_longest_common_prefix(@) {
    my (@in) = @_;
    my $prefix = shift @in;
    foreach my $in (@in) {
	while (substr($in, 0, length $prefix) ne $prefix) {
	    $prefix = substr $prefix, 0, length($prefix) - 1;
	    return '' unless length $prefix; # no common prefix, this can be ok
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
	    return '' unless length $suffix; # no common suffix, this can be ok
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
	die "ERROR: middle <$middle> not numeric in <$in>" unless $middle =~ /^\d+$/;
	$middle;
    } @in;
}

sub sort_numeric(@) {
    return sort { $a <=> $b } @_;
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

sub check_all_numeric(@) {
    my (@middles) = @_;
    die "ERROR: middle part <$_> not numeric\n" foreach grep { $_ !~ /^\d+$/  } @middles;
}

sub to_hash(@) {
    return map { $_ => 1 } @_;
}

sub none() {
    return ();
}

my ($total_pattern);

sub format_from_to($$$) {
    my ($old, $symbol, $new) = @_;
    return sprintf "$total_pattern  %s  $total_pattern\n", $old, $symbol, $new;
}

sub rename_file_secure($$) {
    my ($old, $new) = @_;
    
    # this check is not atomic, but using external 'mv -n' will save us in that case
    die "ERROR: won't rename <$old> to <$new>, target exists\n" if -e $new;
    
    system('mv', '-n', $old, $new) == 0 or die "ERROR: can't rename <$old> to <$new>: $?\n";
    
    print format_from_to($old, '-->', $new);
}

sub do_nothing($$) {
    my ($old, $new) = @_;
    print format_from_to($old, ' = ', $new);
}

my (%existing_files, %new_files);

sub check_for_collisions($$) {
    my ($old, $new) = @_;

    if (exists $existing_files{$new}) {
	die "ERROR: target filename already exists:\n" .
	    format_from_to($old, '-->', $new);
    }

    if (exists $new_files{$new}) {
	die "ERROR: target filename is not unique:\n" .
	    format_from_to($old,             '-->', $new) .
	    format_from_to($new_files{$new}, '-->', $new);
    }
}

sub store_planned_rename($$) {
    my ($old, $new) = @_;
    $new_files{$new} = $old;
}

my ($prefix, $suffix);

sub create_middle_pattern($) {
    my ($maxlen) = @_;
    return '%0'.$maxlen.'d';
}

sub create_total_pattern($) {
    my ($maxlen) = @_;
    return '%-'.( length($prefix) + $maxlen + length($suffix) ).'s';
}

my ($middle_pattern);

sub create_task($) {
    my ($middle) = $_;
    my $old = $prefix.$middle.$suffix;
    my $new = $prefix.sprintf($middle_pattern, $middle).$suffix;

    if ($old eq $new) {
	return sub() { do_nothing($old, $new) };
    }

    check_for_collisions($old, $new);
    store_planned_rename($old, $new);
    return sub() { rename_file_secure($old, $new) };
}

sub create_tasks(@) {
    return map { create_task $_ } @_;
}

sub execute_tasks(@) {
    $_->() foreach @_;
}

### main script here

my $dir = $ARGV[0] // '.';

print "folder: $dir\n";

my @files       = get_files();
%existing_files = to_hash @files;
%new_files      = none;

$prefix = find_longest_common_prefix(@files);
$suffix = find_longest_common_suffix(@files);

print "prefix: $prefix\n";
print "suffix: $suffix\n";

my @middles = sort_numeric get_middle_parts($prefix, $suffix, @files);

check_all_numeric(@middles);

my $maxlen = get_longest_length(@middles);

$middle_pattern = create_middle_pattern($maxlen);
$total_pattern  = create_total_pattern($maxlen);

print "format: $middle_pattern\n";
print "\n";

my @tasks = create_tasks @middles;
execute_tasks @tasks;
