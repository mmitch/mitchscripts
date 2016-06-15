#!/usr/bin/perl
#
# a simple Langton's Ant implementation in Perl
# see https://en.wikipedia.org/wiki/Langton's_ant
#
# Copyright (C) 2016 by  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

use strict;
use warnings;

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
my @M = split //, defined $ARGV[0] && $ARGV[0] ? $ARGV[0] : 'RL';
my $S = scalar @M;

# init field
my $w = 400;
my $h = 300;
my @f;
foreach my $x (0 .. $w-1 ) {
    foreach my $y ( 0 .. $h-1 ) {
	$f[$y*$w+$x] = 0;
    }
}

# init ant
my $x = $w/2;
my $y = $h/2;
my $d = 0;

sub move_ant {
    my $state = $f[$y*$w+$x];
    $f[$y*$w+$x] = ($state + 1) % $S;

    draw( $x, $y, $f[$y*$w+$x] );
    
    if ($M[$state] eq 'L') {
	$d--;
	$d += 4 while $d < 0;
    }
    else {
	$d = ($d + 1) % 4;
    }

    if ($d == 0) {
	$y = ($y + 1) % $h;
    }
    elsif ($d == 1) {
	$x = ($x + 1) % $w;
    }
    elsif ($d == 2) {
	$y--;
	$y += $h while $y < 0;
    }
    else {
	$x--;
	$x += $w while $x < 0;
    }
}

sub print_screen {
    print $CLR;
    foreach my $l ( 0 .. $h-1 ) {
	next if $l % 2;
	my $line = '';
	foreach my $c (0 .. $w-1 ) {
	    $line .= $G[ $f[($l+1)*$w+$c] * 2 + $f[$l*$w+$c] ];
	}
	print "$line\n";
    }
}

my $pixmap;
my $drawing;
my @GC;

sub init_gc {
    my ($widget) = (@_);
    foreach my $i ( 0 .. $S-1) {
	my $v = $i * 255 / ( $S - 1 );
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
$drawing->set_size_request($w*2, $h*2);
$drawing->signal_connect(configure_event => \&configure_event);
$drawing->signal_connect(expose_event => \&expose_event);
$vbox->pack_start( $drawing, TRUE, TRUE, 0 );
$drawing->show;

$window->show;

init_gc($pixmap);

Glib::Timeout->add( 1, \&do_iteration );

Gtk2->main;
