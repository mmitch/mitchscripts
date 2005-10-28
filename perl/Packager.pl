#!/usr/bin/perl -w
# $Id: Packager.pl,v 1.1 2005-10-28 18:47:29 mitch Exp $
use strict;

my $entry = {};
my $packages = {};

while (my $line=<>) {
    chomp $line;
    if ($line =~ /^\s*$/) {
	
	# add
	my $key = $entry->{Package};
	$packages->{$key}->{text} = $entry->{text};
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

print <<EOF;
<html><head><title>cgarbs.de Debian package repository</title></head><body>
<h1>Repository</h1>
<p>The repository is available under:</p>
<pre>
deb     http://www.cgarbs.de/stuff ./
deb-src http://www.cgarbs.de/stuff ./
</pre>
<h1>Intention and content</h1>
<p>The repository contains different categories of software:</p><ul>

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
href="http://www.cgarbs.de/download.en.html">homepage</a>.</li>


<li>personal packages<br>As I am lazy, I sometimes transfer personal
setups via packages from one machine to another
(e.g. <i>fluxbox-styles-mitch</i> or <i>mplayer-dep-dev</i>).  Of
course you can install these packages but they might not be of much
use to you.</li>

<li>old packages<br>Some packages once were in Debian but are not any
more (e.g. <i>xmms-nas</i>).  When I still need them, I put them in
here so they are available on my machines.  Perhaps you can use these,
too.  Versions might be a bit outdated.</li>

<li>others</br><i>libdbmdeep-perl</i> is my packaging of the DBM::Deep
module because this module is needed by <i>p0rn-comfort</i>.
<i>lm-batmon-acpi</i> is my patched version of the official
<i>lm-batmon</i> package because my <a
href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=270520">ACPI
patch</a> has not yet been accepted into Debian.</li>

</ul>

<p>Packages for the all and i386 architecture have been built under
Debian Sarge.  They might also work under testing/unstable, if not,
try to build them from source.  If this fails, please <a
href="mailto:debian\@cgarbs.de">contact me</a>.</p>
<p>Packages for the amd64 architecture have been built under Debian
unstable.  They might work under other branches as well (try to build
from source), but don't expect them to.</p>
<h1>Packages</h1>
<p>The following packages are currently available:</p><ul>
EOF
    ;
foreach my $package (sort keys %{$packages}) {
    print "<li><a href=\"#$package\">$package</a> ("
	. join(', ', sort @{$packages->{$package}->{arch}}) . ")\n";
}
print <<EOF;
</ul>
<h1>Details</h1>
EOF
    ;
foreach my $package (sort keys %{$packages}) {
    print "<h2><a name=\"$package\">$package</a></h2><ul>";
    foreach my $file (sort @{$packages->{$package}->{file}}) {
	print "<li><a href=\"http://www.cgarbs.de/stuff/$file\">$file</a></li>\n";
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
<br>
<p align="right">generated $date by <a href="mailto:debian\@cgarbs.de">mitch</a></p>
</body></html>
EOF
    ;
