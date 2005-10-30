#!/usr/bin/perl -w
# $Id: battery.pl,v 1.6 2005-10-30 00:52:24 mitch Exp $
#
# Show laptop battery status
#
use strict;

# battery location
my $procbattery = '/proc/acpi/battery/BAT0/state';
my $procmax     = '/proc/acpi/battery/BAT0/info';

# temperature information
my $proctemp    = '/proc/acpi/thermal_zone/THM0/temperature';

# defaults
my $state  = 'AC';
my $rate   = 0;
my $volt   = 0;
my $remain = 0;
my $max    = 0;
my $temp   = 0;

# read data
open PROCBATTERY, '<', $procbattery
    or die "can't open `$procbattery': $1";
while (my $line = <PROCBATTERY>) {
    chomp $line;
    if ($line =~ /^charging state:\s+discharg/) {
	$state = 'DC';
    } elsif ($line =~ /^present rate:\s+(\d+) m[AW]/) {
	$rate = $1;
    } elsif ($line =~ /^remaining capacity:\s+(\d+) m[AW]h/) {
	$remain = $1;
    } elsif ($line =~ /^present voltage:\s+(\d+) mV/) {
	$volt = $1;
    }
}
close PROCBATTERY
    or die "can't close `$procbattery': $1";

open PROCMAX, '<', $procmax
    or die "can't open `$procmax': $1";
while (my $line = <PROCMAX>) {
    chomp $line;
    if ($line =~ /^last full capacity:\s+(\d+) m[AW]h/) {
	$max = $1;
	last;
    }
}
close PROCMAX
    or die "can't close `$procmax': $1";

open PROCTEMP, '<', $proctemp
    or die "can't open `$proctemp': $1";
while (my $line = <PROCTEMP>) {
    chomp $line;
    if ($line =~ /^temperature:\s+(\d+) C/) {
	$temp = $1;
	last;
    }
}
close PROCTEMP
    or die "can't close `$proctemp': $1";

# print data
my $percent = $remain / $max;
my $p = sprintf "%.0f", $percent*10;
my $battery = '#' x $p . '.' x (10 - $p );
printf "%s", $state;
if ($state eq 'DC') {
    my $calc = $remain / $rate;
    my $hours = int $calc;
    my $mins = int (($calc - $hours) * 60);
    printf "  %d:%02dh left", $hours, $mins;
} elsif ($state eq 'AC' and $rate > 0) {
    my $calc = ($max - $remain) / $rate;
    my $hours = int $calc;
    my $mins = int (($calc - $hours) * 60);
    printf "  %d:%02dh left", $hours, $mins;
}
printf " \n[%s]  %4.1f%% \n%4.1fW  %4.1fV  %4.1fWh  %2d°C\n", $battery, $percent*100, $rate/1000, $volt/1000, $remain/1000, $temp;
