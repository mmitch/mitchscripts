#!/usr/bin/perl
#
# a simple Langton's Ant implementation in Perl
# see https://en.wikipedia.org/wiki/Langton's_ant
#
# Copyright (C) 2016 by  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

use strict;
use warnings;

package Rule;

use Moo;
has ruleset => ( is => 'ro', required => 1 );
has length  => ( is => 'lazy' );
has _rule   => ( is => 'lazy' );

sub command {
    my ($self, $value) = (@_);
    return $self->_rule->[ $value ];
}

sub _build_length {
    my $self = shift;
    return length $self->ruleset;
}

sub _build__rule {
    my $self = shift;
    return [ split//, $self->ruleset ];
}

package Field;

use Moo;
has rule   => ( is => 'ro', required => 1 );
has width  => ( is => 'ro', required => 1 );
has height => ( is => 'ro', required => 1 );
has _cell  => ( is => 'lazy' );

sub state {
    my ($self, $x, $y) = (@_);
    return $self->_cell->[$self->_index($x, $y)];
}

sub advance {
    my ($self, $x, $y) = (@_);
    my $state = $self->state($x, $y);
    $state = ($state + 1) % $self->rule->length;
    return $self->_put($x, $y, $state);
}

sub _put {
    my ($self, $x, $y, $state) = (@_);
    return $self->_cell->[$self->_index($x, $y)] = $state;
}

sub _index {
    my ($self, $x, $y) = (@_);
    return $y*$self->width+$x;
}

sub _build__cell {
    my $self = shift;
    my @cells;
    foreach my $x (0 .. $self->width-1 ) {
	foreach my $y ( 0 .. $self->height-1 ) {
	    $cells[$self->_index($x, $y)] = 0;
	}
    }
    return \@cells;
}

package Ant;

use Moo;
has field => ( is => 'ro', required => 1 );
has x     => ( is => 'rwp', lazy => 1, builder => 1 );
has y     => ( is => 'rwp', lazy => 1, builder => 1 );
has dir   => ( is => 'rwp', default => 0 );

use constant DIRECTIONS => 4; # TODO: make configurable (hex fields, triangles, ...)

sub turn_left {
    my $self = shift;
    $self->_set_dir( $self->dir - 1 );
    $self->_set_dir( $self->dir + DIRECTIONS ) while $self->dir < 0;
}

sub turn_right {
    my $self = shift;
    $self->_set_dir( ($self->dir + 1) % DIRECTIONS );
}

sub step_forward {
    my $self = shift;
    if ($self->dir == 0) {
	$self->_set_y( ($self->y + 1) % $self->field->height );
    }
    elsif ($self->dir == 1) {
	$self->_set_x( ($self->x + 1) % $self->field->width );
    }
    elsif ($self->dir == 2) {
	$self->_set_y( $self->y - 1 );
	$self->_set_y( $self->y + $self->field->height ) while $self->y < 0;
    }
    else {
	$self->_set_x( $self->x - 1 );
	$self->_set_x( $self->x + $self->field->width ) while $self->x < 0;
    }
}

sub _build_x {
    my $self = shift;
    return $self->field->width / 2;
}

sub _build_y {
    my $self = shift;
    return $self->field->height / 2;
}

package Render::Text::Simple;

use Moo;
use Time::HiRes qw(usleep);

has field    => ( is => 'ro', required => 1 );
has langton  => ( is => 'ro', required => 1 );
has _cls     => ( is => 'ro', default => `tput clear` );
# charset for two pixels per character: [ empty, upper half, bottom half, both ]
has _charset => ( is => 'ro', default => sub { [ ' ', "'", '.', ':' ] } ); 
#has _charset => ( is => 'ro', default => sub { [ ' ', '"', 'o', '8' ] } );

sub draw {
    my ($self, $x, $y) = (@_);
    my $charset = $self->_charset;
    my $field = $self->field;
    print $self->_cls;
    foreach my $l ( 0 .. $field->height-1 ) {
	next if $l % 2;
	my $line = '';
	foreach my $c (0 .. $field->width-1 ) {
	    $line .= $charset->[ $field->state($c, $l+1) * 2 + $field->state($c, $l) ];
	}
	print "$line\n";
    }
}

sub loop {
    my $self = shift;
    die "Render::Text::Simple only works with 2 colors (ruleset length 2)" unless $self->field->rule->length == 2;

    my $langton = $self->langton;
    while (1) {
	$langton->step;
	usleep 10000;
    }
}

package Langton;

use Moo;
has ruleset => ( is => 'ro', required => 1 );
has width   => ( is => 'ro', default => 400 );
has height  => ( is => 'ro', default => 300 );
has _rule   => ( is => 'lazy' );
has _field  => ( is => 'lazy' );
has _ant    => ( is => 'lazy' );
has _render => ( is => 'lazy' );

sub step {
    my $self = shift;
    
    my ($x, $y) = ($self->_ant->x, $self->_ant->y);

    # advance field state
    my $state = $self->_field->advance($x, $y);

    # update output
    $self->_render->draw($x, $y, $state);

    # move ant
    if ($self->_rule->command($state) eq 'L') {
	$self->_ant->turn_left;
    }
    else {
	$self->_ant->turn_right;
    }

    $self->_ant->step_forward;
}

sub start {
    my $self = shift;
    $self->_render->loop;
}

sub _build__rule {
    my $self = shift;
    return Rule->new( ruleset => $self->ruleset );
}

sub _build__field {
    my $self = shift;
    return Field->new( rule => $self->_rule, width => $self->width, height => $self->height );
}

sub _build__ant {
    my $self = shift;
    return Ant->new( field => $self->_field );
}

sub _build__render {
    my $self = shift;
    return Render::Text::Simple->new( field => $self->_field, langton => $self );
}

package main;

use Glib qw/TRUE FALSE/;
use Gtk2 '-init';

my $langton = Langton->new(
    ruleset => (defined $ARGV[0] && $ARGV[0] ? $ARGV[0] : 'RL'),
    width => 80,
    height => 40
    );
$langton->start;

__DATA__

sub print_screen {
    print $CLR;
    foreach my $l ( 0 .. $field->height-1 ) {
	next if $l % 2;
	my $line = '';
	foreach my $c (0 .. $field->width-1 ) {
	    $line .= $G[ $field->state($c, $l+1) * 2 + $field->state($c, $l) ];
	}
	print "$line\n";
    }
}

my $pixmap;
my $drawing;
my @GC;

sub init_gc {
    my ($widget) = (@_);
    foreach my $i ( 0 .. $rule->length-1) {
	my $v = $i * 255 / ( $rule->length - 1 );
	my $rgb = $v << 16 | $v << 8 | $v;
	my $gc = Gtk2::Gdk::GC->new( $widget );
	$gc->set_rgb_foreground( $rgb );
	push @GC, $gc;
    }
}

sub draw {
    my ($x, $y, $c) = (@_);
    $pixmap->draw_rectangle(
	$GC[$c],
	TRUE,
	$x*2, $y*2,
	2, 2
	);
    $drawing->window->draw_drawable(
	$drawing->style->fg_gc($drawing->state),
	$pixmap,
	$x*2, $y*2,
	$x*2, $y*2,
	2, 2
	);
}

sub configure_event {
    my ($widget, $event) = (@_);
    if (! defined $pixmap) {
	$pixmap = Gtk2::Gdk::Pixmap->new( $widget->window, $widget->allocation->width, $widget->allocation->height, -1);
	$pixmap->draw_rectangle($widget->style->black_gc, TRUE, 0, 0, $widget->allocation->width, $widget->allocation->height);
    }
    return TRUE;
}

sub expose_event {
   my ($widget, $event) = (@_);
   $widget->window->draw_drawable(
       $widget->style->fg_gc($widget->state),
       $pixmap,
       $event->area->x, $event->area->y,
       $event->area->x, $event->area->y,
       $event->area->width, $event->area->height
       );
   return FALSE;
}

sub do_iteration {
    move_ant();
    return TRUE;
}

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect(delete_event => sub { FALSE; } );
$window->signal_connect(destroy => sub { Gtk2->main_quit; } );

my $vbox = Gtk2::VBox->new( FALSE, 0 );
$window->add($vbox);
$vbox->show;

$drawing = Gtk2::DrawingArea->new;
$drawing->set_size_request($field->width*2, $field->height*2);
$drawing->signal_connect(configure_event => \&configure_event);
$drawing->signal_connect(expose_event => \&expose_event);
$vbox->pack_start( $drawing, TRUE, TRUE, 0 );
$drawing->show;

$window->show;

init_gc($pixmap);

Glib::Timeout->add( 1, \&do_iteration );

Gtk2->main;
