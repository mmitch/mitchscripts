#!/usr/bin/perl
use warnings;
use strict;

my $H = rand()*360;
my $S = 0.15;
my $V = 0.15;

##########

# see http://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV

my $C = $S * $V;
my $H_ = $H / 60;
my $X = $C * ( 1 - abs( $H_ % 2 - 1 ) );
my ($R, $G, $B);
if ($H_ < 1) {
    ($R, $G, $B) = ($C, $X, 0);
} elsif ($H_ < 2) {
    ($R, $G, $B) = ($X, $C, 0);
} elsif ($H_ < 3) {
    ($R, $G, $B) = (0, $C, $X);
} elsif ($H_ < 4) {
    ($R, $G, $B) = (0, $X, $C);
} elsif ($H_ < 5) {
    ($R, $G, $B) = ($X, 0, $C);
} elsif ($H_ < 6) {
    ($R, $G, $B) = ($C, 0, $X);
}
my $m = $V - $C;

($R, $G, $B) = ($R + $m, $G + $m, $B + $m);

print "$R, $G, $B, $m, $H_, $X, $C\n";

#####

my $hexval = sprintf('#%2x%2x%2x', $R*256, $G*256, $B*256);

print "$hexval\n";

my @run = ('x-terminal-emulator', '-bg', $hexval, @ARGV);
exec(@run);
