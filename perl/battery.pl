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
my $sysbattery   = '/sys/class/power_supply/BAT0/';

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
if (open SYSBAT, '<', $sysbattery . 'status') {
    if ( <SYSBAT> =~ /disch/i ) {
	$state = 'DC';
    }
    close SYSBAT
	or die "can't close battery status: $!";
}

if (open SYSBAT, '<', $sysbattery . 'current_now') {
    $rate = <SYSBAT> / 1000;
    close SYSBAT
	or die "can't close battery current_now: $!";
}

if (open SYSBAT, '<', $sysbattery . 'energy_now') {
    $remain = <SYSBAT> / 1000;
    close SYSBAT
	or die "can't close battery energy_now: $!";
}

if (open SYSBAT, '<', $sysbattery . 'energy_full') {
    $max = <SYSBAT> / 1000;
    close SYSBAT
	or die "can't close battery energy_full: $!";
}

if (open SYSBAT, '<', $sysbattery . 'voltage_now') {
    $volt = <SYSBAT> / 1000;
    close SYSBAT
	or die "can't close battery voltage_now: $!";
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

# additional WLAN info
my $wlan = $status ? '~' : 'wlan ';
if ($eth[1]) {
    if (open IWCONFIG, 'LOCALE=C /sbin/iwconfig eth1|') {
	while (my $line = <IWCONFIG>) {
	    if ($line =~ /SSID:"([^"]+)"/) {
		$wlan .= $1;
	    }
	    if ($line =~ m,Link Quality=(\d+)/100,) {
		$wlan = $status ? $1.'%'.$wlan : $wlan.' '.$1.'%';
	    }
	}
	close IWCONFIG;
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
	(defined $temp ? $temp : 0),
	($curfreq == $minfreq) ? '\\..' : ($curfreq == $maxfreq) ? '../' : '.|.',
	$eth[0] ? '=' : '',
	$eth[1] ? $wlan : '';
    } else {
	if (defined $curfreq && defined $temp) {
	    printf "%d°C [%s] %s%s\n",
	    $temp,
	    ($curfreq == $minfreq) ? '\\..' : ($curfreq == $maxfreq) ? '../' : '.|.',
	    $eth[0] ? '=' : '',
	    $eth[1] ? $wlan : '';
	} else {
	    printf "[%s] %s%s\n",
	    $battery,
	    $eth[0] ? '=' : '',
	    $eth[1] ? $wlan : '';
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
    $eth[1] ? $wlan : '',
    (defined $curfreq) ? (($curfreq == $minfreq) ? 'slow' : (($curfreq == $maxfreq) ? 'fast' : 'intermediate')) : '??';
}
