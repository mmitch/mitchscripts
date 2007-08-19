#!/usr/bin/perl -w
# $Id: battery.pl,v 1.8 2007-08-19 16:43:25 mitch Exp $
#
# Show laptop battery status
#
use strict;

my $status = 0;
if (defined $ARGV[0] and $ARGV[0] eq '-s') {
    # dwm status bar, short display mode
    $status = 1;
}

# battery location
my $procbattery = '/proc/acpi/battery/BAT0/state';
my $procmax     = '/proc/acpi/battery/BAT0/info';

# temperature information
my $proctemp    = '/proc/acpi/thermal_zone/THM0/temperature';

# cpu speed
my $procminf    = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq';
my $procmaxf    = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq';
my $proccurf    = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq';

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

open CPUFREQ, '<', $procminf
    or die "can't open `$procminf': $1";
my $minfreq = <CPUFREQ>;
chomp $minfreq;
close CPUFREQ
    or die "can't close `$procminf': $1";

open CPUFREQ, '<', $procmaxf
    or die "can't open `$procmaxf': $1";
my $maxfreq = <CPUFREQ>;
chomp $maxfreq;
close CPUFREQ
    or die "can't close `$procmaxf': $1";

open CPUFREQ, '<', $proccurf
    or die "can't open `$proccurf': $1";
my $curfreq = <CPUFREQ>;
chomp $curfreq;
close CPUFREQ
    or die "can't close `$proccurf': $1";

# compute data
my $percent = $remain / $max;
my $p = sprintf "%.0f", $percent*10;
my $battery = '#' x $p . '.' x (10 - $p );
my ($calc, $hours, $mins);
if ($state eq 'DC') {
    $calc = $remain / $rate;
    $hours = int $calc;
    $mins = sprintf '%02d', int (($calc - $hours) * 60);
} elsif ($state eq 'AC') {
    if ($rate > 0) {
	$calc = ($max - $remain) / $rate;
	$hours = int $calc;
	$mins = sprintf '%02d', int (($calc - $hours) * 60);
    } else {
	$hours = '-';
	$mins = '--';
    }
}

# print data
if ($status) {
    printf "%d:%02dh%s [%s] %.1fW %d°C [%s]\n",
    $hours,
    $mins,
    ($state eq 'AC') ? '+' : '-',
    $battery,
    $rate/1000,
    $temp,
    ($curfreq == $minfreq) ? '\\..' : ($curfreq == $maxfreq) ? '../' : '.|.';
} else {
    printf "%s  %s:%sh left \n", $state, $hours, $mins;
    printf "[%s]  %4.1f%% \n%4.1fW  %4.1fV  %4.1fWh  %2d°C\n", $battery, $percent*100, $rate/1000, $volt/1000, $remain/1000, $temp;
    printf "cpu %s\n", ($curfreq == $minfreq) ? 'slow' : (($curfreq == $maxfreq) ? 'fast' : 'intermediate');
}
