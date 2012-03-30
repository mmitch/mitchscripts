#!/usr/bin/perl -w
#
# download from dwelling of duels
# 
# Copyright (C) 2012  Christian Garbs <mitch@cgarbs.de>
# licensed under the GNU GPL v3 or later
#
# 
# reads month's URLs from stdin, e.g.
# http://dwellingofduels.net/duel.php?dir=10-04-Jaleco_Games&month=jaleco&img=jaleco
# 

use strict;

while (my $url = <>) {

    if ($url =~ /dwellingofduels.net.*\?(.*)$/) {

	my %parm;
	foreach my $parm (split /&/, $1) {
	    if ($parm =~ /^(.*?)=(.*)$/) {
		$parm{$1} = $2;
	    }
	}

	print "\n   START $parm{dir}…\n\n";

	if (exists $parm{img} and exists $parm{dir}) {

	    mkdir($parm{dir});
	    `cd "$parm{dir}" && wget -nvc "http://dwellingofduels.net/images/banners/$parm{img}.jpg"`;
	    `lynx -dump "$url" | cut -c 7- | grep "$parm{dir}" | (cd "$parm{dir}" && wget -nvc -i-)`;

	} else {
	    warn "dir= and/or img= missing";
	}

	print "\n    END  $parm{dir}\n\n";

    } else {
	warn "unrecognized url";
    }

}
