#!/usr/bin/perl -w
# $Id: battery.pl,v 1.10 2007-08-19 16:44:58 mitch Exp $
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
my $procbattery  = '/proc/acpi/battery/BAT0/state';
my $procmax      = '/proc/acpi/battery/BAT0/info';

# temperature information
my $proctemp     = '/proc/acpi/thermal_zone/THM0/temperature';

# cpu speed
my $procminf     = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq';
my $procmaxf     = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq';
my $proccurf     = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq';

# network configuration
my $procnetroute = '/proc/net/route';

# defaults
my $state  = 'AC';
my $rate   = undef;
my $volt   = 0;
my $remain = 0;
my $max    = 0;
my $temp   = 0;
my @eth    = (0, 0);

# read data
if (open PROCBATTERY, '<', $procbattery) {
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
	or die "can't close `$procbattery': $!";
}

if (open PROCMAX, '<', $procmax) {
    while (my $line = <PROCMAX>) {
	chomp $line;
	if ($line =~ /^last full capacity:\s+(\d+) m[AW]h/) {
	    $max = $1;
	    last;
	}
    }
    close PROCMAX
	or die "can't close `$procmax': $!";
}

if (open PROCTEMP, '<', $proctemp) {
    while (my $line = <PROCTEMP>) {
	chomp $line;
	if ($line =~ /^temperature:\s+(\d+) C/) {
	    $temp = $1;
	    last;
	}
    }
    close PROCTEMP
	or die "can't close `$proctemp': $!";
} else {
    $temp = undef;
}

my $minfreq = undef;
if (open CPUFREQ, '<', $procminf) {
    $minfreq = <CPUFREQ>;
    chomp $minfreq;
    close CPUFREQ
	or die "can't close `$procminf': $!";
} 

my $maxfreq = undef;
if (open CPUFREQ, '<', $procmaxf) {
    $maxfreq = <CPUFREQ>;
    chomp $maxfreq;
    close CPUFREQ
	or die "can't close `$procmaxf': $!";
}
 
my $curfreq = undef;
if (open CPUFREQ, '<', $proccurf) {
    $curfreq = <CPUFREQ>;
    chomp $curfreq;
    close CPUFREQ
	or die "can't close `$proccurf': $!";
}

open ROUTE, '<', $procnetroute
    or die "can't open `$procnetroute': $!";
while (<ROUTE>) {
    if (/^eth([01])/) {
	$eth[$1]++;
    }
};
close ROUTE
    or die "can't close `$procnetroute': $!";

# compute data
my $percent = $max ? $remain / $max : 0;
my $p = sprintf "%.0f", $percent*10;
my $battery = '#' x $p . '.' x (10 - $p );
my ($calc, $hours, $mins);
$hours = '-';
$mins = '--';
if (defined $rate and $rate > 0) {
    if ($state eq 'DC') {
	$calc = $remain / $rate;
	$hours = int $calc;
	$mins = sprintf '%02d', int (($calc - $hours) * 60);
    } elsif ($state eq 'AC') {
	$calc = ($max - $remain) / $rate;
	$hours = int $calc;
	$mins = sprintf '%02d', int (($calc - $hours) * 60);
    }
}

# print data
if ($status) {
    if (defined $rate and $rate > 0) {
	printf "%s:%sh%s [%s] %.1fW %d°C [%s] %s%s\n",
	$hours,
	$mins,
	($state eq 'AC') ? ($rate > 0 ? '+' : ' ' ) : '-',
	$battery,
	$rate/1000,
	$temp,
	($curfreq == $minfreq) ? '\\..' : ($curfreq == $maxfreq) ? '../' : '.|.',
	$eth[0] ? '=' : '',
	$eth[1] ? '~' : '';
    } else {
	if (defined $curfreq && defined $temp) {
	    printf "%d°C [%s] %s%s\n",
	    $temp,
	    ($curfreq == $minfreq) ? '\\..' : ($curfreq == $maxfreq) ? '../' : '.|.',
	    $eth[0] ? '=' : '',
	    $eth[1] ? '~' : '';
	} else {
	    printf "[%s] %s%s\n",
	    $battery,
	    $eth[0] ? '=' : '',
	    $eth[1] ? '~' : '';
	}
    }
} else {
    printf "%s  %s:%sh left \n", $state, $hours, $mins;
    if (defined $temp and defined $rate) {
	printf "[%s]  %4.1f%% \n%4.1fW  %4.1fV  %4.1fWh  %2d°C\n", $battery, $percent*100, $rate/1000, $volt/1000, $remain/1000, $temp;
    } else {
	printf "[%s]  %4.1f%% \n%4.1fV  %4.1fWh\n", $battery, $percent*100, $volt/1000, $remain/1000;
    }
    printf "%s%s  cpu %s\n",
    $eth[0] ? 'cable ' : '',
    $eth[1] ? 'wlan ' : '',
    (defined $curfreq) ? (($curfreq == $minfreq) ? 'slow' : (($curfreq == $maxfreq) ? 'fast' : 'intermediate')) : '??';
}
