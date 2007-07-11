#!/usr/bin/perl -w
# $Id: edictsort.pl,v 1.4 2007-07-11 18:56:38 mitch Exp $
# 2006-2007 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL
# 
# sort entries from edict/wadokujt
use strict;
my %len;
while (my $line = <>) {
    if ($line =~ /^([^ \[;|]+)/) {
	push @{$len{length $1}}, $line;
    }
}
foreach my $len (sort {$a <=> $b} keys %len) {
    print foreach @{$len{$len}};
}
