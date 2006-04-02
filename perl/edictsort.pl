#!/usr/bin/perl -w
# $Id: edictsort.pl,v 1.2 2006-04-02 19:28:27 mitch Exp $
# 2006 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL
# 
# sort entries from edict/wadokujt
use strict;
my %len;
while (my $line = <>) {
    if ($line =~ /^([^ \[]+)/) {
	push @{$len{length $1}}, $line;
    }
}
foreach my $len (sort {$a <=> $b} keys %len) {
    print foreach @{$len{$len}};
}
