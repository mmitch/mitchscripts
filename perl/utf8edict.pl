#!/usr/bin/perl -w
# $Id: utf8edict.pl,v 1.1 2006-04-02 14:52:48 mitch Exp $
# 2006 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL
# 
# convert edict to UTF8 and sort shortest first
use strict;
my %len;
open EDICT, 'nkf -w /usr/share/edict/edict|' or die "can't open edict pipe: $!\n";
while (my $line = <EDICT>) {
    if ($line =~ /^([^ \[]+)/) {
	push @{$len{length $1}}, $line;
    }
}
close EDICT or die "can't close EDICT pipe: $!\n";
open EDICT, '>', '/tmp/edict-utf8' or die "can't open /tmp/edict-utf8: $!\n";
foreach my $len (sort {$a <=> $b} keys %len) {
    print EDICT foreach @{$len{$len}};
}
close EDICT or die "can't close /tmp/edict-utf8: $!\n";
