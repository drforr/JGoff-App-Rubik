#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'JGoff::App::Rubik' ) || print "Bail out!\n";
}

my $rubik = JGoff::App::Rubik->new( spacing => 0.1 );

my @edge = $rubik->_lerp( [ 0, 0, 1 ], [ 1, 0, 0 ] );
is_deeply( $edge[0], [ 0, 0, 1 ] );
is_deeply( $edge[5], [ 1, 0, 0 ] );

use YAML;die Dump(\@edge);
