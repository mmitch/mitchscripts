#!/usr/bin/perl -w
# $Id: vgmix_to_rss.pl,v 1.1 2005-09-04 12:14:46 mitch Exp $
#
# VGMix.com HTTP to RSS gateway
# 2005 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL

use strict;
use POSIX qw(strftime);

my $baseurl = 'http://www.vgmix.vom';
my $line;
my @entries;

sub process_newstitle
{
    my $title = shift;
    $title =~ s|^.+<b>||;
    $title =~s|</b>.+$||;
    chomp $title;
    return { TITLE => $title };
}

sub process_table
{
    my $entry = shift;
    my $line = shift;
    if ($line =~ /href="(topic_view.php\?topic_id=\d+)"/) {
	$entry->{URL} = "$baseurl/$1";
    }
    if ($line =~ m| (\d+)/(\d+)/(\d+) @ (\d+):(\d+) ([AP]M) |) {
	$entry->{DATE} = strftime("%a, %d %b %Y %H:%M:%S +0000", 0, $5, $4+( $6 eq 'P' ? 12 : 0), $2, $1, $3+100);
    }
	
}

# skip trailing garbage

while ($line=<>) {
    last if $line =~ /class="newstitle"/;
}

# process entries

my $entry = process_newstitle($line);

while ($line=<>) {
    last if $line =~ /forum_view.php\?forum_id=8/;

    if ($line =~ /class="newstitle"/) {
	push @entries, $entry;
	$entry = process_newstitle($line);
    } elsif ($line =~ /^<table width="100%"/) {
	process_table($entry, $line);
	# skip next line!
	$line=<>;
    } else {
	$entry->{TEXT} .= $line;
    }
}

push @entries, $entry;

# finished processing input

# create output

foreach my $entry (@entries) {
    print "\n----------------------------------------\n";
    print "Title:\t$entry->{TITLE}\n";
    print "URL:\t$entry->{URL}\n";
    print "Date:\t$entry->{DATE}\n";
    print "Text:\n$entry->{TEXT}\n";
}

