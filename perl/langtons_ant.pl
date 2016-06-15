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

package main;

use Glib qw/TRUE FALSE/;
use Gtk2 '-init';

# init output:
# 2 states in 1x2 grid -> 4 combinations
# bits are placed like this:
#  1
#  0
my @G = (
    ' ', "'", '.', ':'
#    ' ', '"', 'o', '8'
    );

my $CLR = `tput clear`;

# init states
my $rule = Rule->new( ruleset => (defined $ARGV[0] && $ARGV[0] ? $ARGV[0] : 'RL') );

# init field
my $field = Field->new( rule => $rule, width => 400, height => 300 );

# init ant
my $ant = Ant->new( field => $field );

sub move_ant {
    my ($x, $y) = ($ant->x, $ant->y);
    my $state = $field->advance($x, $y);

    draw($x, $y, $state);
    
    if ($rule->command($state) eq 'L') {
	$ant->turn_left;
    }
    else {
	$ant->turn_right;
    }

    $ant->step_forward;
}

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
