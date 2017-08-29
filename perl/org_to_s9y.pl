#!/usr/bin/perl
#
# org_to_s9y.pl -- orgmode to serendipity converter
#
# This script converts an OrgMode file into HTML that is properly
# formatted to be directly used as an entry in my s9y driven blog.
#
#  Copyright (C) 2016  Christian Garbs <mitch@cgarbs.de>
#  Licensed under GNU GPL v2 or later
#
# see also:
#
#  - OrgMode (documentation format and more):
#    http://orgmode.org/
#  
#  - s9y (Serendipity blog software): 
#    http://www.s9y.org/
#
#  - Org::Parser (Perl parser for OrgMode files):
#    https://metacpan.org/release/Org-Parser
#

use strict;
use warnings;
use utf8;

use Org::Parser;

my $filename = $ARGV[0];
die "no filename given" unless defined $filename;

my $html_body = (defined $ARGV[1] && $ARGV[1] eq '-h');
my $tree_debug = (defined $ARGV[1] && $ARGV[1] eq '-d');

open my $fh, '<', $filename or die "can't open `$filename': $!";

my $METACHAR = "\x{1a}";

my $doc = Org::Parser->new()->parse($fh);

my %style_map = (
    ''  => '',
    'B' => 'b',
    'I' => 'em',
    'U' => 'u',
    'C' => 'code',
    'S' => 'strike',
    'V' => 'code',
    );

my %list_map = (
    'O' => 'ol',
    'U' => 'ul',
    'D' => 'dl',
    );

my %geshi_map = (
    'css' => 'css',
    'emacs-lisp' => 'lisp',
    'java' => 'java5',
    'latex' => 'latex',
    'sh' => 'bash',
    'smarty' => 'smarty',
    'text' => 'text',
    );

my @open_lists;

my @footnotes;

sub add_geshi {
    my ($content, $lang) = (@_);

    if (defined $lang and $lang eq 'quote') {
	return add_blockquote($content);
    }

    if ($html_body) {
	return add_verbatim($content);
    }

    $lang = 'text' unless defined $lang;
    chomp $content;

    if (exists $geshi_map{$lang}) {
	$lang = $geshi_map{$lang};
    } else {
	die "unknown geshi language <$lang>.\nchoose from <" . join('>, <', keys %geshi_map) . ">\n ";
    }

    # escape empty lines, so they don't get </p><p>ed later
    $content =~ s/^$/$METACHAR/gm;

    return sprintf "</p>\n[geshi lang=%s]%s[/geshi]\n<p>", $lang, $content;
}

sub add_blockquote {
    my ($content) = (@_);
    chomp $content;

    # escape empty lines, so they don't get </p><p>ed later
    $content =~ s/^$/$METACHAR/gm;

    return sprintf "</p><blockquote>%s</blockquote>\n<p>", encode_html($content);
}

sub add_verbatim {
    my ($content) = (@_);
    chomp $content;

    # escape empty lines, so they don't get </p><p>ed later
    $content =~ s/^$/$METACHAR/gm;

    return sprintf "</p><pre class=\"output-verbatim\">%s</pre>\n<p>", encode_html($content);
}

sub encode_html {
    my ($text) = (@_);

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    die "stray [fn: encountered, is there a footnote with a linebreak?" if $text =~ /\[fn:/;

    return $text;
}

sub a_tag {
    my ($link, $description) = (@_);

    die "link <$link> with = encoded as %3D -> check!" if $link =~ /%3D/i;

    return sprintf '<a href="%s">%s</a>', encode_html($link), encode_html($description);
}

sub abbr_tag {
    my ($text, $popup) = (@_);

    return sprintf '<abbr title="%s">%s</abbr>', encode_html($popup), encode_html($text);
}

sub convert_link {
    my ($el) = (@_);
    my $link = $el->link;

    if ($link =~ /^([^:]+):/) {
	my $schema = $1;
	if ($schema =~ /^(http|https)$/) {
	    # continue
	}
	elsif ($schema eq 'todo') {
	    die "todo: link without description" unless defined $el->description;
	    return abbr_tag($el->description->as_string, 'Artikel folgt');
	}
	else {
	    die "unknown schema <$schema> in link <$link>";
	}
    }
    
    if (defined $el->description) {
	return a_tag($link, $el->description->as_string);
    } else {
	return a_tag($link, $link);
    }
}

sub add_footnote {
    my ($text) = (@_);

    push @footnotes, $text;
    my $idx = @footnotes;
    
    return sprintf('<a class="footnote" id="fn-from-%d" href="#fn-to-%d">[%d]</a>', $idx, $idx, $idx);
}

sub parse_element {
    my ($el) = (@_);

    my $text = '';

    if ($el->isa('Org::Element::Text')) {
	my $tag = $style_map{$el->style};
	die "unknown text style <".${el}->{style}.">" unless defined $tag;

	my $eltext = encode_html($el->text);
	$eltext =~ s|\n\n|</p><p>|g;
	$eltext =~ s/\s+/ /g;

	if ($tag) {
	    $text .= sprintf '<%s>%s</%s>', $tag, $eltext, $tag;
	}
	else {
	    $text .= $eltext;
	}

    }
    elsif ($el->isa('Org::Element::Headline')) {
	my $level = $el->level;
	die "can't handle heading level <$level>" if $level < 1 or $level > 6;
	$text .= sprintf "</p>\n<h%d>%s</h%d>\n<p>", $level, parse_element($el->title), $level;

	# extra walkables seem to contain the headline again for closing tags on the way up - skip them!
	$text .= parse_children_noextra($el);
    }
    elsif ($el->isa('Org::Element::Link')) {
	$text .= convert_link($el);
    }
    elsif ($el->isa('Org::Element::List')) {
	my $type = $el->type();
	push @open_lists, $type;
	my $list_tag = $list_map{$type};
	if (defined $list_tag) {
	    $text .= sprintf '</p><%s>%s', $list_tag, parse_children($el); # FIXME: list parser issue: closing list tag missing
	}
	else {
	    die "unknown list type <$type>";
	}
    }
    elsif ($el->isa('Org::Element::ListItem')) {
	my $list_type = $open_lists[-1];
	my $childtext = parse_children($el);
	die "list underrun @ $childtext" unless defined $list_type;
	$childtext =~ s|</p>\s*<p>$||s; # remove strange leftovers
	if ($list_type eq 'D') {
	    $childtext =~ s|^\s+||;
	    $text .= sprintf "</dd>\n\n<dt>%s</dt><dd>%s", encode_html($el->desc_term->as_string), $childtext; # FIXME: list parser issue: <dd></dd> wrong order
	} else {
	    $text .= sprintf "</li>\n\n<li>%s", $childtext; # FIXME: list parser issue: <li></li> wrong order
	}
    }
    elsif ($el->isa('Org::Element::Block')) {
	$text .= add_geshi($el->raw_content, $el->args->[0]);
    }
    elsif ($el->isa('Org::Element::FixedWidthSection')) {
 	# $text .= add_geshi($el->text);
	$text .= add_verbatim($el->text);
    }
    elsif ($el->isa('Org::Element::Comment')) {
	if ($el->as_string eq "# LIST-END\n") {
	    # FIXME: list parser issue: manually close a list
	    if ($open_lists[-1] eq 'D') {
		$text .= sprintf "</dd></%s>\n<p>", $list_map{pop @open_lists};
	    } else {
		$text .= sprintf '</li></%s><p>', $list_map{pop @open_lists};
	    }
	}
	else {
	    # skip
	}
    }
    elsif ($el->isa('Org::Element::Footnote')) {
	die "no support for named Footnotes yet" if ($el->name);
	die "no support for non-ref Footnotes yet" unless ($el->is_ref);
	die "no support for non-def Footnotes yet" unless ($el->def);
	$text .= add_footnote($el->def);
    }
    elsif ($el->isa('Org::Element::Setting')) {
	# skip
    }
    elsif ($el->isa('Org::Document')) {
	$text .= parse_children($el);
    }
    else {
	die "don't know what to do with <$el>";
    }

    return $text;
}

sub parse_children_noextra {
    my ($el) = (@_);

    my $text = '';

    if ($el->children) {
	$text .= parse_element($_) for @{$el->children};
    }

    return $text;
}

sub parse_children {
    my ($el) = (@_);

    my $text = parse_children_noextra($el);

    $text .= parse_element($_) for $el->extra_walkables;

    return $text;
}

sub tree_element {
    my ($el, $lvl) = (@_);

    my $object = scalar $el;
    $object =~ s/^Org::Element://;
    my $content = substr($el->as_string, 0, 20);
    $content =~ tr/\n//d;
    my $text = sprintf "%-40s %s\n", '  ' x $lvl . $object, $content;
    
    return $text;
}

sub tree_children {
    my ($el, $lvl) = (@_);

    my $text = tree_element($el, $lvl);

    if ($el->children) {
	$text .= tree_children($_, $lvl + 1) for @{$el->children};
    }

    $text .= tree_element($_, $lvl + 1) for $el->extra_walkables;

    return $text;
}

if ($tree_debug) {
    print tree_element($doc, 0) . tree_children($doc, 0);
    exit 0;
}

my $article = parse_element($doc);

if (@open_lists) {
    my $tags = join ", ", map { $list_map{$_} } @open_lists;
    die "there are ".scalar(@open_lists)." unclosed list elements ($tags) - close manually with '# LIST-END'";
}

# brush up linebreaks
chomp $article;
$article = "<p>$article</p>";
$article =~ s|<ul></li>|<ul>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|</p><p></li>|</li>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|<dl></dd>|<dl>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|</p><p></dd>|</dd>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|<ul></li>|<ul>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|<ol></li>|<ol>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|<p> |<p>|gm;
$article =~ s| </p>|</p>|gm;
$article =~ s|<p></p>|\n|gm;
$article =~ s|</p><p>|</p>\n<p>|gm;
$article =~ s|<p>|\n<p>|gm;
$article =~ s|\n{3,}|\n\n|gm;
$article =~ s/$METACHAR//g;

if ($html_body) {
    print <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>
      none
    </title>
  </head>
  <body>
EOF
    ;
}

print "$article\n";

if (@footnotes) {
    print "<div id=\"footnotes\">\n";
    my $idx = 1;
    for my $footnote (@footnotes) {
	printf(
	    '  <div class="footnote" id="fn-to-%d"><a href="#fn-from-%d">[%d]</a>: %s</div>%s',
	    $idx, $idx, $idx,
	    parse_element($footnote),
	    "\n"
	    );
	$idx++;
    }
    print "</div>\n";
}

if ($html_body) {
    print <<'EOF';
  </body>
</html>
EOF
    ;
}
