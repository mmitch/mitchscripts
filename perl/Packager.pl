#!/usr/bin/perl -w
# 
# 2005-2008 (c) by Christian Garbs <mitch@cgarbs.de>
#
# usage:
# (zcat Packages.gz ; echo ~~~START~SOURCES~~~ ; zcat Sources.gz) | Packager.pl > some.html
#
use strict;

my $entry = {};
my $packages = {};
my $sources = {};

my $line;
while ($line=<>) {
    chomp $line;
    if ($line =~ /^~~~START~SOURCES~~~$/) {
	last;

    } elsif ($line =~ /^\s*$/) {
	
	# add
	my $key = $entry->{Package};
	$packages->{$key}->{text} = $entry->{text};
	$packages->{$key}->{description} = $entry->{Description};
	$packages->{$key}->{source} = exists $entry->{Source} ? $entry->{Source} : $key;
	push @{$packages->{$key}->{arch}}, $entry->{Architecture};
	$entry->{Filename} =~ s:^.*/::;
	push @{$packages->{$key}->{file}}, $entry->{Filename};

	$entry = {};
	    
    } elsif ($line =~ /^\s/) {

	$line =~ s/</&lt;/g;
	$line =~ s/>/&gt;/g;
	$entry->{text} .= "$line\n";

    } else {

	my ($keyword, $value) = split /: /, $line, 2;
	$entry->{$keyword} = $value;

    }

}

if ($line and $line =~ /^~~~START~SOURCES~~~$/) {
    $entry = {};
    while ($line=<>) {
	chomp $line;
	if ($line =~ /^\s*$/) {
	    
	    # add
	    my $key = $entry->{Package};
	    $sources->{$key}->{files} = [ keys %{$entry->{files}} ];
	    
	    $entry = {};
	    
	} elsif ($line =~ /^\s\S+\s\d+\s(\S+)$/) {
	    
	    $entry->{files}->{$1}++;

	} else {

	    my ($keyword, $value) = split /: /, $line, 2;
	    $entry->{$keyword} = $value;

	}
    }

}

print <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
<html><head>
<title>cgarbs.de Debian package repository</title>
<link rel="shortcut icon" type="image/ico" href="/pics/favicon.ico">
<meta name="generator" content="Packager.pl">
<meta name="robots" content="index,follow">
<meta name="keywords" content="debian package repository">
<meta name="author" content="Christian Garbs (debian\@cgarbs.de)">
<meta name="language" content="en">
<meta http-equiv="revisit-after" content="7 days">
<meta http-equiv="content-language" content="en">
<meta http-equiv="content-type" content="text/html; charset=ISO-8859-15">
</head><body>
<h1>Contents</h1><ul>
<li><a href="#1">Repository access</a></li>
<li><a href="#2">Repository content</a></li>
<li><a href="#3">Package overview</a></li>
<li><a href="#4">Package details</a></li>
</ul>
<h1><a name="1">Repository access</a></h1>
<p>The repository is available under:</p>
<pre>
deb     https://www.cgarbs.de/stuff ./
deb-src https://www.cgarbs.de/stuff ./
</pre>
<p>Put these lines in your <tt>/etc/apt/sources.list</tt> and you are ready to go.<br>
My repository key is available <a href="/gpg-key">here</a>.</p>
<p>(As the repository is available via HTTPS only, be sure to have <tt>apt-transport-https</tt> installed.)</p>

<h1><a name="2">Repository content</a></h1>

<p>This repository contains different categories of software for the
<i>i386</i>, <i>amd64</i> and <i>sparc</i> architectures (the focus
being on i386):</p><ul>

<li>official packages for distribution<br>Here I offer packages of
software that is available on my <a
href="http://www.cgarbs.de/download.en.html">homepage</a>
(e.g. <i>gbsplay</i> or <i>japana</i>) to make them easy to install
and update for everybody.  Normally these will be release versions,
but when I want to test new features on different machines you might
find release-candidates or even CVS snapshots inside.  Usually,
everything will work.</li>


<li>inofficial packages<br>Some packages are not yet to be officially
released, but I already use them on multiple machines so I put them in
here.  These packages might be finished but without proper
documentation or a page on my website (e.g. <i>grabcd-encode</i> and
<i>grabcd-rip</i>) or they are too experimental to be released
(e.g. <i>soundconvert</i> - see the note in the package description).
You might try them, but don't expect them to be working as smoothly as
those things that are listed on my <a
href="http://www.cgarbs.de/download.en.html">homepage</a>.<br> Most of
these packages live inside my <a
href="https://github.com/mmitch">git
repository</a>.</li>


<li>personal packages<br>As I am lazy, I sometimes transfer personal
setups via packages from one machine to another
(e.g. <i>fluxbox-styles-mitch</i> or <i>mplayer-dep-dev</i>).  Of
course you can install these packages but they might not be of much
use to you.</li>


<li>backports and updates<br>Some things that I do need on my systems
are not yet available in Etch or on <a
href="http://www.backports.org">backports.org</a>, so sometimes I
build a backport by myself.  To distribute it to all my machines these
packages are put here.  This ranges from simple repackagings for Etch
to genuine updates to CVS snapshots or new releases (e.g. <i>hugin</i>
or <i>qtpfsgui</i>).


<li>old packages<br>Some packages once were in Debian but are not any
more.  When I still need them, I put them in here so they are
available on my machines (e.g. <i>xmms-nas</i>).  And when I don't
need them any more, I still keep them for whatever reasen
(<i>v2strip</i>).  Perhaps you can use these, too.  Versions might be
a bit outdated.</li>


<li>others<br><i>libdbmdeep-perl</i> is my packaging of the DBM::Deep
module because this module is needed by <i>p0rn-comfort</i>.</li>

</ul>

<p>Currently, I'm in a transition phase.  Some packages are already
packaged for Lenny, others are still packaged for Etch.  When a
package is officially available only from Lenny, I'll try to keep the
Etch version around.  The packages might also work under
testing/unstable, if not, try to build them from source.  If this
fails, please <a href="mailto:debian\@cgarbs.de">contact me</a>.</p>

<p align="right">--January 2008</p>

<h1><a name="3">Package overview</a></h1>
<p>The following packages are currently available:</p><ul>
EOF
    ;
foreach my $package (sort keys %{$packages}) {
    print "<li><a href=\"#$package\">$package</a> ("
	. join(', ', sort @{$packages->{$package}->{arch}}) . ")\n";
}
print <<EOF;
</ul>
<h1><a name="4">Package details</a></h1>
EOF
    ;
foreach my $package (sort keys %{$packages}) {
    print "<h2><a name=\"$package\">$package</a></h2>\n";
    print "<p>$packages->{$package}->{description}</p><ul>";
    foreach my $file (sort @{$packages->{$package}->{file}}) {
	print "<li><a href=\"http://www.cgarbs.de/stuff/$file\">$file</a></li>\n";
    }
    foreach my $file (sort @{$sources->{$packages->{$package}->{source}}->{files}}) {
	print "<li><small><a href=\"http://www.cgarbs.de/stuff/$file\">$file</a></small></li>\n";
    }
    print <<"EOF";
</ul><pre>
$packages->{$package}->{text}
</pre>
EOF
    ;
}
my $date = `LANG=C date`;
print <<"EOF";
<hr>
<p align="right">generated $date by <a href="mailto:debian\@cgarbs.de">mitch</a></p>
</body></html>
EOF
    ;
