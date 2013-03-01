package JGoff::App::Rubik;

use Readonly;
use Moose;

Readonly my $X => 0;
Readonly my $Y => 1;
Readonly my $Z => 2;

has corners => (
  is => 'ro',
  isa => 'ArrayRef[ArrayRef[Num]]'
);

has spacing => ( is => 'ro', isa => 'Num' );

=head1 NAME

JGoff::App::Rubik - Generate coordinates

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JGoff::App::Rubik;

    my $foo = JGoff::App::Rubik->new();
    ...

=head1 METHODS

=head2 generate

=cut

# {{{ _vector_sum( $A, $B )

sub _vector_sum {
  my $self = shift;
  my ( $A, $B ) = @_;
  return [
    $A->[$X] + $B->[$X],
    $A->[$Y] + $B->[$Y],
    $A->[$Z] + $B->[$Z],
  ]
}

# }}}

# {{{ _vector_difference( $A, $B )

sub _vector_difference {
  my $self = shift;
  my ( $A, $B ) = @_;
  return [
    $A->[$X] - $B->[$X],
    $A->[$Y] - $B->[$Y],
    $A->[$Z] - $B->[$Z],
  ]
}

# }}}

# {{{ _vector_multiply( $A, $value )

sub _vector_multiply {
  my $self = shift;
  my ( $A, $value ) = @_;
  return [
    $A->[$X] * $value,
    $A->[$Y] * $value,
    $A->[$Z] * $value,
  ]
}

# }}}

# {{{ _vector_abs( $A )

sub _vector_abs {
  my $self = shift;
  my ( $A ) = @_;
  return [
    abs( $A->[$X] ),
    abs( $A->[$Y] ),
    abs( $A->[$Z] ),
  ]
}

# }}}

# {{{ _lerp
#
# Keep in mind the spacing is a *percentage* of the magnitude of the vector
#
sub _lerp {
  my $self = shift;
  my ( $l, $r ) = @_;

  my $d = $self->_vector_abs( $self->_vector_difference( $r, $l ) );

  my $edge = [
    1.0 - ( 2 * $self->spacing ),
    1.0 - ( 2 * $self->spacing ),
    1.0 - ( 2 * $self->spacing ),
  ];

  $edge->[$X] = ( $edge->[$X] / 3 ) * $d->[$X];
  $edge->[$Y] = ( $edge->[$Y] / 3 ) * $d->[$Y];
  $edge->[$Z] = ( $edge->[$Z] / 3 ) * $d->[$Z];

  my $spacing = $self->_vector_multiply( $d, $self->spacing );

  $spacing->[$X] = -$spacing->[$X] if $l->[$X] > $r->[$X];
  $spacing->[$Y] = -$spacing->[$Y] if $l->[$Y] > $r->[$Y];
  $spacing->[$Z] = -$spacing->[$Z] if $l->[$Z] > $r->[$Z];

  $edge->[$X] = -$edge->[$X] if $l->[$X] > $r->[$X];
  $edge->[$Y] = -$edge->[$Y] if $l->[$Y] > $r->[$Y];
  $edge->[$Z] = -$edge->[$Z] if $l->[$Z] > $r->[$Z];

  my @edge;
  push @edge, [ @$l ];
  push @edge, $self->_vector_sum( $edge[0], $edge );
  push @edge, $self->_vector_sum( $edge[1], $spacing );
  push @edge, $self->_vector_sum( $edge[2], $edge );
  push @edge, $self->_vector_sum( $edge[3], $spacing );
  push @edge, [ @$r ];

  return @edge;
}

# }}}

sub generate {
}

#
#  0  1    2  3    4  5
#  6  7    8  9   10 11
#
#
# 12 13   14 15   16 17
# 18 19   20 21   22 23
#
#
# 24 25   26 27   28 29
# 30 31   32 33   34 35
#

sub facets {
  my $self = shift;
  my ( $v ) = @_;

  my @facets = (
    [ 0, 1, 7, 6 ],
    [ 2, 3, 9, 8 ],
    [ 4, 5, 11, 10 ],

    [ 12, 13, 19, 18 ],
    [ 14, 15, 21, 20 ],
    [ 16, 17, 23, 22 ],

    [ 24, 25, 31, 30 ],
    [ 26, 27, 33, 32 ],
    [ 28, 29, 35, 34 ],
  );

#
# What's really needed is actually a way to feed in this array, and say
#
# lerp between (0,0) and (5,0); ...

my @plane_verts = (
  [ $v->[0],  [ 0.9, 0.0 ],[ 1.1, 0.0 ],[ 2.0, 0.0 ],[ 2.2, 0.0 ], $v->[1]    ],
  [[ 0, 0.9 ],[ 0.9, 0.9 ],[ 1.1, 0.9 ],[ 2.0, 0.9 ],[ 2.2, 0.9 ],[ 3.1, 0.9 ]],
  [[ 0, 1.1 ],[ 0.9, 1.1 ],[ 1.1, 1.1 ],[ 2.0, 1.1 ],[ 2.2, 1.1 ],[ 3.1, 1.1 ]],
  [[ 0, 2.0 ],[ 0.9, 2.0 ],[ 1.1, 2.0 ],[ 2.0, 2.0 ],[ 2.2, 2.0 ],[ 3.1, 2.0 ]],
  [[ 0, 2.2 ],[ 0.9, 2.2 ],[ 1.1, 2.2 ],[ 2.0, 2.2 ],[ 2.2, 2.2 ],[ 3.1, 2.2 ]],
  [ $v->[2],  [ 0.9, 3.1 ],[ 1.1, 3.1 ],[ 2.0, 3.1 ],[ 2.2, 3.1 ], $v->[3]    ],
);

  my @flattened;
  for my $y ( 0 .. 5 ) {
    for my $x ( 0 .. 5 ) {
      push @flattened, $plane_verts[$x][$y];
    }
  }

  return ( \@facets, \@flattened );
}

=head1 AUTHOR

Jeff Goff, C<< <jgoff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jgoff-app-rubik at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JGoff-App-Rubik>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JGoff::App::Rubik


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JGoff-App-Rubik>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JGoff-App-Rubik>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JGoff-App-Rubik>

=item * Search CPAN

L<http://search.cpan.org/dist/JGoff-App-Rubik/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jeff Goff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of JGoff::App::Rubik
