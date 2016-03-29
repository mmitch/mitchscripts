#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Org::Parser;

open my $fh, '<', "$ENV{HOME}/Cryptbox/blog/lisp.org" or die $!;

my $METACHAR = "\x{1a}";

my $article;

my $doc = Org::Parser->new()->parse($fh);

my %style_map = (
    ''  => '',
    'I' => 'em',
    'C' => 'code'
    );

sub add_geshi {
    my ($content, $lang) = (@_);
    $lang = 'text' unless defined $lang;
    chomp $content;

    if ($lang eq 'text') {
	# unchanged
    }
    elsif ($lang eq 'emacs-lisp') {
	$lang = 'lisp';
    }
    else {
	die "unknown geshi language <$lang>";
    }

    # escape empty lines, so they don't get </p><p>ed later
    $content =~ s/^$/$METACHAR/gm;

    return sprintf "</p>\n[geshi lang=%s]%s[/geshi]\n<p>", $lang, $content;
}

sub walker {
    my ($el) = @_;

    my $text = '';

    if ($el->isa('Org::Element::Text')) {
	my $tag = $style_map{$el->style};
	die "unknown text style <".${el}->{style}.">" unless defined $tag;

	if ($tag) {
	    $text .= sprintf '<%s>%s</%s>', $tag, $el->text, $tag;
	}
	else {
	    $text .= $el->text;
	}
    }
    elsif ($el->isa('Org::Element::Headline')) {
	my $level = $el->level;
	die "can't handle heading level <$level>" if $level < 1 or $level > 6;
	$text .= sprintf "</p>\n<h%d>%s</h%d>\n<p>", $level, $el->title->as_string, $level;

	# remove heading so it does not pop up again while walking the tree -> STRANGE
	$el->title(undef);
    }
    elsif ($el->isa('Org::Element::Link')) {
	if (defined $el->description) {
	    $text .= sprintf '<a href="%s">%s</a>', $el->link, $el->description->as_string;
	} else {
	    $text .= sprintf '<a href="%s">%s</a>', $el->link, $el->link;
	}
    }
    elsif ($el->isa('Org::Element::Block')) {
	$text .= add_geshi($el->raw_content, $el->args->[0]);
    }
    elsif ($el->isa('Org::Element::FixedWidthSection')) {
	$text .= add_geshi($el->text);
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

