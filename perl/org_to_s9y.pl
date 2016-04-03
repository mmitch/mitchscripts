#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Org::Parser;

my $filename = $ARGV[0];
die "no filename given" unless defined $filename;

my $html_body = (defined $ARGV[1] && $ARGV[1] eq '-h');

open my $fh, '<', $filename or die "can't open `$filename': $!";

my $METACHAR = "\x{1a}";

my $doc = Org::Parser->new()->parse($fh);

my %style_map = (
    ''  => '',
    'B' => 'b',
    'I' => 'em',
    'U' => 'u',
    'C' => 'code',
    );

my %list_map = (
    'U' => 'ul',
    );

my %geshi_map = (
    'css' => 'css',
    'emacs-lisp' => 'lisp',
    'sh' => 'bash',
    'smarty' => 'smarty',
    'text' => 'text',
    );

my @open_lists;

sub add_geshi($$) {
    my ($content, $lang) = (@_);

    if ($html_body) {
	return add_verbatim($content);
    }

    $lang = 'text' unless defined $lang;
    chomp $content;

    if (exists $geshi_map{$lang}) {
	$lang = $geshi_map{$lang};
    } else {
	die "unknown geshi language <$lang>";
    }

    # escape empty lines, so they don't get </p><p>ed later
    $content =~ s/^$/$METACHAR/gm;

    return sprintf "</p>\n[geshi lang=%s]%s[/geshi]\n<p>", $lang, $content;
}

sub add_verbatim {
    my ($content) = (@_);
    chomp $content;

    # escape empty lines, so they don't get </p><p>ed later
    $content =~ s/^$/$METACHAR/gm;

    return sprintf "</p><pre class=\"output-verbatim\">%s</pre>\n<p>", encode_html($content);
}

sub encode_html($) {
    my ($text) = (@_);

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    return $text;
}

sub a_tag($$) {
    my ($link, $description) = (@_);

    return sprintf '<a href="%s">%s</a>', encode_html($link), encode_html($description);
}

sub abbr_tag($$) {
    my ($text, $popup) = (@_);

    return sprintf '<abbr title="%s">%s</a>', encode_html($popup), encode_html($text);
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
	    return abbr_tag($el->description, 'Artikel folgt später');
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
	my $childtext = parse_children($el);
	$childtext =~ s|</p>\s*<p>$||s; # remove strange leftovers
	$text .= sprintf "</li>\n\n<li>%s", $childtext; # FIXME: list parser issue: <li></li> wrong order
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
	    $text .= sprintf '</li></%s><p>', $list_map{pop @open_lists};
	}
	else {
	    # skip
	}
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

my $article = parse_element($doc);

die "there are ".scalar(@open_lists)." unclosed list elements - close manually with '# LIST-END'" if @open_lists;

# brush up linebreaks
chomp $article;
$article = "<p>$article</p>";
$article =~ s|<ul></li>|<ul>|gm; # FIXME: list parser issue: remove cruft
$article =~ s|</p><p></li>|</li>|gm; # FIXME: list parser issue: remove cruft
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

if ($html_body) {
    print <<'EOF';
  </body>
</html>
EOF
    ;
}
