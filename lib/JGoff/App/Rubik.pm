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

  my @v02 = $self->_lerp( $v->[0], $v->[2] );
  my @v13 = $self->_lerp( $v->[1], $v->[3] );

  my @plane_verts;
  $plane_verts[0][0] = $v->[0];
  $plane_verts[0][5] = $v->[1];
  $plane_verts[5][0] = $v->[2];
  $plane_verts[5][5] = $v->[3];

  for my $idx ( 1 .. 4 ) {
    $plane_verts[$idx][0] = $v02[$idx - 1];
    $plane_verts[$idx][5] = $v13[$idx - 1];
  }

  for my $idx ( 0 .. 5 ) {
    @{ $plane_verts[$idx] }[ 1 .. 4 ] =
       $self->_lerp( $plane_verts[$idx][0], $plane_verts[$idx][5] );
  }

#  @{ $plane_verts[0] }[1 .. 4] = $self->_lerp( $v->[0], $v->[1] );

  my @flattened;
  for my $y ( 0 .. 5 ) {
    for my $x ( 0 .. 5 ) {
      push @flattened, $plane_verts[$x][$y];
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

sub cubies {
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

  my @verts = (
    [ [ $v->[0], undef, undef, undef, undef, $v->[1] ],
      [ ],
      [ ],
      [ ],
      [ ],
      [ $v->[2], undef, undef, undef, undef, $v->[3] ] ],
    [ ],
    [ ],
    [ ],
    [ ],
    [ [ $v->[4], undef, undef, undef, undef, $v->[5] ],
      [ ],
      [ ],
      [ ],
      [ ],
      [ $v->[6], undef, undef, undef, undef, $v->[7] ] ],
  );

  @{$verts[0][0][1..4]} = $self->lerp( $verts[0][0][0], $verts[0][5][0] );

  my @v02 = $self->_lerp( $v->[0], $v->[2] );
  my @v13 = $self->_lerp( $v->[1], $v->[3] );
  my @v46 = $self->_lerp( $v->[4], $v->[6] );
  my @v57 = $self->_lerp( $v->[5], $v->[7] );


  my @v04 = $self->_lerp( $v->[0], $v->[4] );
  my @v15 = $self->_lerp( $v->[1], $v->[5] );
  my @v26 = $self->_lerp( $v->[2], $v->[6] );
  my @v37 = $self->_lerp( $v->[3], $v->[7] );
  my @plane_verts = (
    [ [ $v->[0], $self->_lerp( $v->[0], $v->[1] ), $v->[1] ],
      [ $v02[0], $self->_lerp( $v02[0], $v13[0] ), $v13[0] ],
      [ $v02[1], $self->_lerp( $v02[1], $v13[1] ), $v13[1] ],
      [ $v02[2], $self->_lerp( $v02[2], $v13[2] ), $v13[2] ],
      [ $v02[3], $self->_lerp( $v02[3], $v13[3] ), $v13[3] ],
      [ $v->[2], $self->_lerp( $v->[2], $v->[3] ), $v->[3] ] ],

    [ [ $v04[0], $self->lerp( $v04[0], $v15[0] ), $v15[0] ],
      [ $v26[0], $self->lerp( $v26[0], $v37[0] ), $v37[0] ] ],

    [ [ $v04[1], $self->lerp( $v04[1], $v15[1] ), $v15[1] ],
      [ $v26[1], $self->lerp( $v26[1], $v37[1] ), $v37[1] ] ],

    [ [ $v04[2], $self->lerp( $v04[2], $v15[2] ), $v15[2] ],
      [ $v26[2], $self->lerp( $v26[2], $v37[2] ), $v37[2] ] ],
# ...
    [ [ $v->[4], $self->_lerp( $v->[4], $v->[5] ), $v->[5] ],
      [ $v46[0], $self->_lerp( $v46[0], $v57[0] ), $v57[0]],
      [ $v46[1], $self->_lerp( $v46[1], $v57[1] ), $v57[1]],
      [ $v46[2], $self->_lerp( $v46[2], $v57[2] ), $v57[2]],
      [ $v46[3], $self->_lerp( $v46[3], $v57[3] ), $v57[3]],
      [ $v->[6], $self->_lerp( $v->[6], $v->[7] ), $v->[7] ] ],
  );

  my @flattened;
  for my $z ( 0 .. 0 ) {
    for my $y ( 0 .. 5 ) {
      for my $x ( 0 .. 5 ) {
        push @flattened, $plane_verts[0][$x][$y];
      }
    }
  }

  return ( \@facets, \@flattened );
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
