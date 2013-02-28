#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JGoff::App::Rubik' ) || print "Bail out!\n";
}

diag( "Testing JGoff::App::Rubik $JGoff::App::Rubik::VERSION, Perl $], $^X" );
