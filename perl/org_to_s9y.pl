#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Org::Parser;

open my $fh, '<', "$ENV{HOME}/Cryptbox/blog/lisp.org" or die $!;

my $doc = Org::Parser->new()->parse($fh);

my %style_map = (
    ''  => '',
    'I' => 'em',
    'C' => 'code'
    );

sub add_geshi {
    my ($content, $lang) = (@_);
    $lang = 'text' unless defined $lang;

    if ($lang eq 'text') {
	# unchanged
    }
    elsif ($lang eq 'emacs-lisp') {
	$lang = 'lisp';
    }
    else {
	die "unknown geshi language <$lang>";
    }

    return sprintf '[geshi lang=%s]%s[/geshi]', $lang, $content;
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
	$text .= sprintf '<h%d>%s</h%d>', $level, $el->title->as_string, $level;
	
    }
    elsif ($el->isa('Org::Element::Link')) {
	if (defined $el->description) {
	    $text .= sprintf '<a href="%s">%s</a>', $el->link, $el->description->walk(\&walker);
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

    print "$text";
    return $text;
}

print $doc->walk(\&walker);
print "\n";

