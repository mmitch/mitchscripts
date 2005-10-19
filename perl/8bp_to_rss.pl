#!/usr/bin/perl -w
# $Id: 8bp_to_rss.pl,v 1.3 2005-10-19 17:36:49 mitch Exp $
#
# VGMix.com HTTP to RSS gateway
# 2005 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL

use strict;
use POSIX qw(strftime);

my $version   = ' vgmix_to_rss.pl $Revision: 1.3 $ ';
$version =~ tr/$//d;
$version =~ s/Revision: /v/;
$version =~ s/^\s+//;
$version =~ s/\s+$//;

my $baseurl = 'http://www.8bitpeoples.com';
my $line;
my @entries;

# skip to interesting part of page

while ($line=<>) {
    last if $line =~ /FONT FACE="Arial"/;
}

# process entries

while ($line=<>) {
    last unless $line =~ /^\s+(\d\d)\.(\d\d)\.(\d\d)/;

    my $entry = {DATE => strftime("%a, %d %b %Y %H:%M:%S +0000", 0, 0, 12, $2, $1-1, $3+100) };

    $line = <>;

    $line =~ m|<a href="(.+)"><font color="\#ffffff">(.+)</font></a>|i;

    $entry->{URL} = "$baseurl/$1";
    $entry->{TITLE} = $2;

    $line = <>;

    push @entries, $entry;

}

# finished processing input

# create output

print <<"EOF";
<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2.0"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>8bitpeoples News</title>
    <link>$baseurl</link>
    <description>RSS gateway to $baseurl</description>
    <language>en</language>
    <generator>$version</generator>
EOF
;
foreach my $entry (@entries) {
    print "    <item>\n";
    print "      <title><![CDATA[$entry->{'TITLE'}]]></title>\n";
    print "      <content:encoded>\n<![CDATA[$entry->{'TITLE'}]]></content:encoded>\n";
    print "      <pubDate>$entry->{'DATE'}</pubDate>\n";
    print "      <link>$entry->{'URL'}</link>\n";
    print "    </item>\n";
}

print "  </channel>\n";
print "</rss>\n";

