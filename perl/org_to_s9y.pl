#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Org::Parser;

my $filename = $ARGV[0];
die "no filename given" unless defined $filename;

open my $fh, '<', $filename or die "can't open `$filename': $!";

my $METACHAR = "\x{1a}";

my $article;

my $doc = Org::Parser->new()->parse($fh);

my %style_map = (
    ''  => '',
    'B' => 'b',
    'I' => 'em',
    'U' => 'u',
    'C' => 'code'
    );

my %geshi_map = (
    'css' => 'css',
    'emacs-lisp' => 'lisp',
    'sh' => 'bash',
    'smarty' => 'smarty',
    'text' => 'text',
    );

sub add_geshi($$) {
    my ($content, $lang) = (@_);
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

sub walker {
    my ($el) = (@_);

    my $text = '';

    if ($el->isa('Org::Element::Text')) {
	my $tag = $style_map{$el->style};
	die "unknown text style <".${el}->{style}.">" unless defined $tag;

	if ($tag) {
	    $text .= sprintf '<%s>%s</%s>', $tag, encode_html($el->text), $tag;
	}
	else {
	    $text .= encode_html($el->text);
	}
    }
    elsif ($el->isa('Org::Element::Headline')) {
	my $level = $el->level;
	die "can't handle heading level <$level>" if $level < 1 or $level > 6;
	$text .= sprintf "</p>\n<h%d>%s</h%d>\n<p>", $level, encode_html($el->title->as_string), $level;

	# remove heading so it does not pop up again while walking the tree -> STRANGE
	$el->title(undef);
    }
    elsif ($el->isa('Org::Element::Link')) {
	$text .= convert_link($el);
    }
    elsif ($el->isa('Org::Element::List')) {
	my $type = $el->type();
	if ($type eq 'U') {
	    $text .= sprintf '<ul>%s</ul>', encode_html($el->as_string);
	}
	else {
	    die "unknown list type <$type>";
	}
    }
    elsif ($el->isa('Org::Element::ListItem')) {
	# FIXME TODO
    }
    elsif ($el->isa('Org::Element::Block')) {
	$text .= add_geshi($el->raw_content, $el->args->[0]);
    }
    elsif ($el->isa('Org::Element::FixedWidthSection')) {
 	# $text .= add_geshi($el->text);
	
	my $content = $el->text;
	chomp $content;

	# escape empty lines, so they don't get </p><p>ed later
	$content =~ s/^$/$METACHAR/gm;

	$text .= sprintf "</p><pre class=\"output-verbatim\">%s</pre>\n<p>", $content;
    }
    elsif ($el->isa('Org::Element::Comment')) {
	# skip
    }
    elsif ($el->isa('Org::Element::Setting')) {
	# skip
    }
    elsif ($el->isa('Org::Document')) {
	# skip
    }
    else {
	die "don't know what to do with <$el>";
    }

    $article .= $text;
}

$doc->walk(\&walker);

# brush up linebreaks
chomp $article;
$article = "<p>$article</p>";
$article =~ s|\n{3,}|\n\n|gm;
$article =~ s|\n{2}|</p><p>|gm;
$article =~ s|<p>\n|\n<p>|gm;
$article =~ s|<p></p>|\n|gm;
$article =~ s|</p><p>|</p>\n\n<p>|gm;
$article =~ s|\n{4,}|\n\n|gm;
$article =~ s/$METACHAR//g;
print "$article\n";

