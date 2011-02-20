#!/usr/bin/perl -w
#
# decode possibly incomplete MIME words into UTF8
#
# Copyright (C) 2010  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#

use strict;
use Encode;
use MIME::Words qw(decode_mimewords);
$|++;
binmode STDOUT, ':utf8';

while (my $line = <>) {
    chomp $line;

    # this is simple and will propably break with multiple encoded parts in one line
    # but still better than nothing
    if ($line =~ /=\?/) {

	if ($line =~ /=\?.*\?=/) {
	    # complete markers
	} elsif ($line =~ /=\?.*\?$/) {
	    # cut-off end marker
	    $line .= '=';
	} else {
	    # incomplete markers
	    $line .= '?=';
	}

	my @parts = decode_mimewords( $line );
	my $result = '';
	foreach my $part (@parts) {
	    my ($text, $charset) = @{$part};
	    if (defined $charset) {
		$result .= decode($charset, $text);
	    } else {
		$result .= $text;
	    }
	}
	print "$result\n";

    } else {
	print "$line\n";
    }
}

