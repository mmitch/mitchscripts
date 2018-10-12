#!/usr/bin/perl
#
# get info from FRITZ!Box
#
# see Net::Fritz(3pm) for details
#
use strict;
use warnings;

use Net::Fritz::Box;
use Number::Bytes::Human qw(format_bytes);
use Time::Duration;

# get credentials
my ($user, $pass);
my $rcfile = $ENV{HOME}.'/.fritzrc';
if (-r $rcfile) {
    open FRITZRC, '<', $rcfile or die $!;
    while (my $line = <FRITZRC>) {
	chomp $line;
	if ($line =~ /^(\S+)\s*=\s*(.*?)$/) {
	    if ($1 eq 'username') {
		$user = $2;
	    }
	    elsif ($1 eq 'password') {
		$pass = $2
	    }
	}
    }
    close FRITZRC or die $!;
}

# connect to FRITZ!Box
my $fritz = Net::Fritz::Box->new(
    username => $user,
    password => $pass
    );
$fritz->errorcheck;

my $device = $fritz->discover;
$device->errorcheck;

# check if connected and get connection type
my $dsl_service = $device->find_service(':WANDSLLinkConfig:');
$dsl_service->errorcheck;

my $dsl_link_info = $dsl_service->call('GetDSLLinkInfo');
$dsl_link_info->errorcheck;

if ($dsl_link_info->data->{'NewLinkStatus'} ne 'Up') {
    # no connection/offline
    exit;
}

# determine service to use to get external IP address
my $wan_connection_service;
if ($dsl_link_info->data->{'NewLinkType'} eq 'PPPoE') {
    $wan_connection_service = $device->find_service(':WANPPPConnection:');
    $wan_connection_service->errorcheck;
}
elsif ($dsl_link_info->data->{'NewLinkType'} eq 'IP') {
    $wan_connection_service = $device->find_service(':WANIPConnection:');
    $wan_connection_service->errorcheck;
}
else {
    die "unknown link type: " . $dsl_link_info->data->{'NewLinkType'};
}

# get external IP address
my $external_ip_response = $wan_connection_service->call('GetExternalIPAddress');
$external_ip_response->errorcheck();

# print result
printf "external IP:\t%s\n",
    $external_ip_response->data->{'NewExternalIPAddress'};

# get online status
my $status_info = $wan_connection_service->call('GetStatusInfo');
$status_info->errorcheck();

# print result
printf "uptime: \t%s\n",
    duration($status_info->data->{'NewUptime'});

# get bytes in/out
my $wan_common_service = $device->find_service(':WANCommonInterfaceConfig:');
$wan_common_service->errorcheck;
my $sent_response = $wan_common_service->call('GetTotalBytesSent');
$sent_response->errorcheck;
my $received_response = $wan_common_service->call('GetTotalBytesReceived');
$received_response->errorcheck;

# print bytes in/out
printf "bytes in/out:\t%s / %s\n",
    format_bytes($received_response->data->{'NewTotalBytesReceived'}),
    format_bytes($sent_response->data->{'NewTotalBytesSent'});
