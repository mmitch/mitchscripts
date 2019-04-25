#!/usr/bin/perl
#
# show download URLs for Debian/Ubuntu packages plus all non-essential dependencies
#
# Copyright (C) 2019  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
use strict;
use warnings;

use constant REPOURL => 'http://de.archive.ubuntu.com/ubuntu/';

sub split_dependencies
{
    my $depline = shift;

    my @deps = map { my $tmp = $_; $tmp =~ s/\s.*$//; $tmp } split /\s*,\s*/, $depline;

    return \@deps;
}

sub get_info
{
    my $pkg = shift;

    my $data = { 'Essential' => 'no' };
    
    open my $apt, '-|', "apt-cache show $pkg" or die "can't open apt data for <$pkg>: $!";

    while (my $line = <$apt>) {
	chomp $line;
	last if $line eq '';

	if ($line =~ /^(\S+?): (.*)$/) {
	    my ($key, $value) = ($1, $2);
	    
	    if ($key =~ /^(?:Filename|Essential|Priority)$/) {
		$data->{$key} = $value;
	    }
	    elsif ($key =~ /^(?:Depends|Recommends|Suggests)$/) {
		$data->{$key} = split_dependencies $value;
	    }
	}
    }
    
    close $apt; # or die "can't close apt data for <$pkg>: $!";

    return $data;
}

my %PKG;

sub recurse;

sub recurse
{
    my $pkg = shift;

    return if exists $PKG{$pkg};

    $PKG{$pkg} = get_info $pkg;

    recurse $_ foreach @{$PKG{$pkg}->{Depends}};
}

recurse $_ foreach @ARGV;

print $_
    foreach
    map { REPOURL . $_ . "\n" }
    sort
    map { $_->{Filename} }
    grep { $_->{Priority} ne 'required' }
#    grep { $_->{Essential} ne 'yes' }
    values %PKG;
