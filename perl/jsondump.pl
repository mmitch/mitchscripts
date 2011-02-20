#!/usr/bin/perl -w
use warnings;
use strict;
use Data::Dumper;
use JSON::Any;
$\ = undef;
my $json = <>;
my $j = JSON::Any->new;
print Dumper($j->decode($json));
