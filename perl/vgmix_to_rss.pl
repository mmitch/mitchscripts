#!/usr/bin/perl -w
# $Id: vgmix_to_rss.pl,v 1.6 2005-09-07 07:29:50 mitch Exp $
#
# VGMix.com HTTP to RSS gateway
# 2005 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL

use strict;
use POSIX qw(strftime);

my $version   = ' vgmix_to_rss.pl $Revision: 1.6 $ ';
$version =~ tr/$//d;
$version =~ s/Revision: /v/;
$version =~ s/^\s+//;
$version =~ s/\s+$//;

my $baseurl = 'http://www.vgmix.com';
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
	$entry->{DATE} = strftime("%a, %d %b %Y %H:%M:%S +0000", 0, $5, $4+( $6 eq 'P' ? 12 : 0), $2, $1-1, $3+100);
    }
	
}

# skip to interesting part of page

while ($line=<>) {
    last if $line =~ /class="newstitle"/;
}

# process entries

my $entry = process_newstitle($line);

while ($line=<>) {
    last if $line =~ /forum_view.php\?forum_id=8/;

    $line =~ s/\r//g;

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

print <<"EOF";
<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2.0"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>VGMix Community News</title>
    <link>http://www.vgmix.com</link>
    <description>RSS gateway to http://www.vgmix.com</description>
    <language>en</language>
    <generator>$version</generator>
EOF
;
foreach my $entry (@entries) {
    print "    <item>\n";
    print "      <title><![CDATA[$entry->{'TITLE'}]]></title>\n";
    print "      <content:encoded>\n<![CDATA[$entry->{'TEXT'}]]></content:encoded>\n";
    print "      <pubDate>$entry->{'DATE'}</pubDate>\n";
    print "      <link>$entry->{'URL'}</link>\n";
    print "    </item>\n";
}

print "  </channel>\n";
print "</rss>\n";

