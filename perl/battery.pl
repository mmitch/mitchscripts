#!/usr/bin/perl -w
# $Id: battery.pl,v 1.2 2004-03-06 17:27:46 mitch Exp $
#
# Show laptop battery status
#
use strict;

# battery location
my $procbattery = '/proc/acpi/battery/BAT0/state';

# defaults
my $state  = 'AC';
my $rate   = 0;
my $volt   = 0;
my $remain = 0;

# read data
open PROCBATTERY, '<', $procbattery
    or die "can't open `$procbattery': $1";
while (my $line = <PROCBATTERY>) {
    chomp $line;
    if ($line =~ /^charging state:\s+discharg/) {
	$state = 'DC';
    } elsif ($line =~ /^present rate:\s+(\d+) mW/) {
	$rate = $1;
    } elsif ($line =~ /^remaining capacity:\s+(\d+) mWh/) {
	$remain = $1;
    } elsif ($line =~ /^present voltage:\s+(\d+) mV/) {
	$volt = $1;
    }
}
close PROCBATTERY
    or die "can't close `$procbattery': $1";

# print data
printf "%s  %4.1fW  %4.1fV  %4.1fWh", $state, $rate/1000, $volt/1000, $remain/1000;
if ($state eq 'DC') {
    my $calc = $remain / $rate;
    my $hours = int $calc;
    my $mins = int (($calc - $hours) * 60);
    printf"  %d:%02dh left", $hours, $mins;
}
print "\n";
