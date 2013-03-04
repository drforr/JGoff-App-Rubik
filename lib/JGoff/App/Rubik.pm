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

# {{{ _v_sum( $A, $B )

sub _v_sum {
  my $self = shift;
  my ( $A, $B ) = @_;
  return [
    $A->[$X] + $B->[$X],
    $A->[$Y] + $B->[$Y],
    $A->[$Z] + $B->[$Z],
  ]
}

# }}}

# {{{ _v_difference( $A, $B )

sub _v_difference {
  my $self = shift;
  my ( $A, $B ) = @_;
  return [
    $A->[$X] - $B->[$X],
    $A->[$Y] - $B->[$Y],
    $A->[$Z] - $B->[$Z],
  ]
}

# }}}

# {{{ _v_multiply( $A, $value )

sub _v_multiply {
  my $self = shift;
  my ( $A, $value ) = @_;
  return [
    $A->[$X] * $value,
    $A->[$Y] * $value,
    $A->[$Z] * $value,
  ]
}

# }}}

# {{{ _v_vector_multiply( $A, $B )

sub _v_v_multiply {
  my $self = shift;
  my ( $A, $B ) = @_;
  return [
    $A->[$X] * $B->[$X],
    $A->[$Y] * $B->[$Y],
    $A->[$Z] * $B->[$Z],
  ]
}

# }}}

# {{{ _v_divide( $A, $value )

sub _v_divide {
  my $self = shift;
  my ( $A, $value ) = @_;
  return [
    $A->[$X] / $value,
    $A->[$Y] / $value,
    $A->[$Z] / $value,
  ]
}

# }}}

# {{{ _v_abs( $A )

sub _v_abs {
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

  my $d = $self->_v_abs( $self->_v_difference( $l, $r ) );

  my $edge = [
    1.0 - ( 2 * $self->spacing ),
    1.0 - ( 2 * $self->spacing ),
    1.0 - ( 2 * $self->spacing ),
  ];

  $edge = $self->_v_v_multiply(
    $self->_v_divide( $edge, 3 ),
    $d
  );

  my $spacing = $self->_v_multiply( $d, $self->spacing );

  $spacing->[$X] = -$spacing->[$X] if $l->[$X] > $r->[$X];
  $spacing->[$Y] = -$spacing->[$Y] if $l->[$Y] > $r->[$Y];
  $spacing->[$Z] = -$spacing->[$Z] if $l->[$Z] > $r->[$Z];

  $edge->[$X] = -$edge->[$X] if $l->[$X] > $r->[$X];
  $edge->[$Y] = -$edge->[$Y] if $l->[$Y] > $r->[$Y];
  $edge->[$Z] = -$edge->[$Z] if $l->[$Z] > $r->[$Z];

  my @edge;
  push @edge, $self->_v_sum( $l, $edge );
  push @edge, $self->_v_sum( $edge[0], $spacing );
  push @edge, $self->_v_sum( $edge[1], $edge );
  push @edge, $self->_v_sum( $edge[2], $spacing );

  return @edge;
}

# }}}

sub generate {
}

# {{{ facets
#
#   4 -- 5
#  /|   /|
# 0 -- 1 |
# | 6 -| 7
# |/   |/
# 2 -- 3
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

  my @plane_verts;
  $plane_verts[ 0 ][ 0 ] = $v->[ 0 ];
  $plane_verts[ 0 ][ 5 ] = $v->[ 1 ];
  $plane_verts[ 5 ][ 0 ] = $v->[ 2 ];
  $plane_verts[ 5 ][ 5 ] = $v->[ 3 ];

  my @v02 = $self->_lerp( $plane_verts[ 0 ][ 0 ], $plane_verts[ 5 ][ 0 ] );
  my @v13 = $self->_lerp( $plane_verts[ 0 ][ 5 ], $plane_verts[ 5 ][ 5 ] );

  for my $idx ( 1 .. 4 ) {
    $plane_verts[$idx][ 0 ] = $v02[ $idx - 1 ];
    $plane_verts[$idx][ 5 ] = $v13[ $idx - 1 ];
  }

  for my $idx ( 0 .. 5 ) {
    @{ $plane_verts[ $idx ] }[ 1 .. 4 ] =
       $self->_lerp( $plane_verts[ $idx ][ 0 ], $plane_verts[ $idx ][ 5 ] );
  }

  my @flattened;
  for my $y ( 0 .. 5 ) {
    for my $x ( 0 .. 5 ) {
      push @flattened, $plane_verts[ $x ][ $y ];
    }
  }

  return ( \@facets, \@flattened );
}

# }}}

# {{{ cubies
#
#   4 -- 5
#  /|   /|
# 0 -- 1 |
# | 6 -| 7
# |/   |/
# 2 -- 3
#
#        144 145 146 147 148 149
#
#      108 109 110 111 112 113
#       /  /    /  /   /  /
#     72 73   74 75  76 77
#   
#   36 37   38 39   40 41
#   /  /    /  /    /  /|
#  0  1    2  3    4  5 48
#  6  7    8  9   10 11
#
#   49 50  51 52   53 54
#   /  /   /  /    /  /
# 12 13   14 15   16 17
# 18 19   20 21   22 23
#
#
# 24 25   26 27   28 29
# 30 31   32 33   34 35
#

my @delta = (
  [ 0, 1, 7, 6 ],
  [ 36, 42, 43, 37 ],
  [ 1, 37, 43, 7 ],
  [ 0, 6, 42, 36 ],
  [ 0, 36, 37, 1 ],
  [ 6, 42, 43, 7 ],
);

sub _to_cubie {
  my $self = shift;
  my ( $idx ) = @_;
  my @temp;
  for my $face ( 0 .. 5 ) {
    for my $edge ( 0 .. 3 ) {
      $temp[$face][$edge] = $delta[$face][$edge] + $idx;
    }
  }
  return \@temp;
}

#
# Assumes [ $idx ][ 0 ][ 0 ],
#         [ $idx ][ 0 ][ 5 ],
#         [ $idx ][ 5 ][ 0 ],
#         [ $idx ][ 5 ][ 5 ],
#
# are populated.
#
sub _lerp_plane {
  my $self = shift;
  my ( $cube, $plane ) = @_;

  # [0][0] . . . . [0][5]
  #    .   . . . .   .
  #    .   . . . .   .
  #    .   . . . .   .
  #    .   . . . .   .
  # [5][0] . . . . [5][5]
  my @v01 = $self->_lerp( $cube->[ $plane ][ 0 ][ 0 ],
                          $cube->[ $plane ][ 0 ][ 5 ] );
  my @v23 = $self->_lerp( $cube->[ $plane ][ 5 ][ 0 ],
                          $cube->[ $plane ][ 5 ][ 5 ] );

  for my $idx ( 1 .. 4 ) {
    $cube->[ $plane ][ 0 ][ $idx ] = $v01[ $idx - 1 ];
    $cube->[ $plane ][ 5 ][ $idx ] = $v23[ $idx - 1 ];
  }
  # [0][0] - - - > [0][5]
  #    .   . . . .   .
  #    .   . . . .   .
  #    .   . . . .   .
  #    .   . . . .   .
  # [5][0] - - - > [5][5]
  for my $idx ( 0 .. 5 ) {
    my @lerp = $self->_lerp( $cube->[ $plane ][ 0 ][ $idx ],
                             $cube->[ $plane ][ 5 ][ $idx ] );
    for my $_idx ( 1 .. 4 ) {
      $cube->[ $plane ][ $_idx ][ $idx ] = $lerp[ $_idx - 1 ];
    }
  }

  # [0][0] X X X X [0][5]
  #    |   | | | |   |
  #    |   | | | |   |
  #    |   | | | |   |
  #    V   V V V V   V
  # [5][0] X X X X [5][5]
}

sub _debug_plane {
  my ($cube,$plane) = @_;

  for my $y ( 0 .. 5 ) {
    for my $x ( 0 .. 5 ) {
      print defined $cube->[$plane][$y][$x] ? 'X' : '.';
    }
    print "\n";
  }
}

sub cubies {
  my $self = shift;
  my ( $v ) = @_;

  my @corners = (
    0, 2, 4,
    12, 14, 16,
    24, 26, 28,

    72, 74, 76,
    84, 86, 88,
    96, 98, 100,

    144, 146, 148,
    156, 158, 160,
    168, 170, 172
  );

  my @cubies;
  for my $corner ( @corners ) {
    push @cubies, $self->_to_cubie( $corner );
  }

  my @cube_verts;
  $cube_verts[ 0 ][ 0 ][ 0 ] = $v->[ 0 ];
  $cube_verts[ 0 ][ 0 ][ 5 ] = $v->[ 1 ];
  $cube_verts[ 0 ][ 5 ][ 0 ] = $v->[ 2 ];
  $cube_verts[ 0 ][ 5 ][ 5 ] = $v->[ 3 ];

  $cube_verts[ 5 ][ 0 ][ 0 ] = $v->[ 4 ];
  $cube_verts[ 5 ][ 0 ][ 5 ] = $v->[ 5 ];
  $cube_verts[ 5 ][ 5 ][ 0 ] = $v->[ 6 ];
  $cube_verts[ 5 ][ 5 ][ 5 ] = $v->[ 7 ];

  $self->_lerp_plane( \@cube_verts, 0 );
  $self->_lerp_plane( \@cube_verts, 5 );

  #
  # Front to back
  #
  my @v04 = $self->_lerp( $v->[ 0 ], $v->[ 4 ] );
  my @v15 = $self->_lerp( $v->[ 1 ], $v->[ 5 ] );
  my @v26 = $self->_lerp( $v->[ 2 ], $v->[ 6 ] );
  my @v37 = $self->_lerp( $v->[ 3 ], $v->[ 7 ] );

  for my $idx ( 1 .. 4 ) {
    $cube_verts[ $idx ][ 0 ][ 5 ] = $v04[ $idx - 1 ];
    $cube_verts[ $idx ][ 0 ][ 5 ] = $v15[ $idx - 1 ];
    $cube_verts[ $idx ][ 5 ][ 5 ] = $v26[ $idx - 1 ];
    $cube_verts[ $idx ][ 5 ][ 5 ] = $v37[ $idx - 1 ];
  }

  for my $y ( 0 .. 5 ) {
    for my $x ( 0 .. 5 ) {
      my @lerp = $self->_lerp( $cube_verts[ 0 ][ $x ][ $y ],
                               $cube_verts[ 5 ][ $x ][ $y ] );
      for my $idx ( 1 .. 4 ) {
        $cube_verts[ $idx ][ $x ][ $y ] = $lerp[ $idx - 1 ];
      }
    }
  }
#_debug_plane(\@cube_verts, 4);
#exit 0;

  my @flattened;
  for my $z ( 0 .. 5 ) {
    for my $y ( 0 .. 5 ) {
      for my $x ( 0 .. 5 ) {
        push @flattened, $cube_verts[ $z ][ $x ][ $y ];
      }
    }
  }
#use YAML;die Dump(\@flattened);
#$use YAML;die Dump(\@cubies);
#$die scalar @cubies;

  return ( \@cubies, \@flattened );
}

# }}}

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
