use strict;
use warnings;

package Data::Difference;
# ABSTRACT: Compare simple hierarchical data

use subs qw( _croak );

use Exporter::Shiny our @EXPORT_OK = qw( get_value data_diff );

sub _DELETE () { 1 }
sub _ADD ()    { 2 }
sub _CHANGE () { 4 }

# https://metacpan.org/dist/Exporter-Tiny/view/lib/Exporter/Tiny/Manual/QuickStart.pod#Generators
sub _generate_data_diff {
  my ( undef, undef, $args, undef ) = @_;

  if ( my $version = delete $args->{ -version } ) {
    _croak "Improper version format '%s'", $version
      unless $version =~ m/\Av0 | v[1-9]\d*\z/x;
    return \&data_diff1 if $version eq 'v1';
    _croak "data_diff() has no version '%s' implementation", $version
      unless $version eq 'v0';
  }

  return \&data_diff0;
}

sub get_value {
  my ( $a_or_b, $path ) = @_;

  my @tmp = @$path;
  # pairwise read type and element
  while ( my ( $t, $e ) = splice @tmp, 0, 2 ) {
    if ( $t eq 'k' ) {
      $a_or_b = $a_or_b->{ $e };
    } elsif ( $t eq 'i' ) {
      $a_or_b = $a_or_b->[ $e ];
    } else {
      _croak "Unknown path element type (got: '%s', expected: 'i' or 'k')", $t;
    }
  }

  return $a_or_b;
}

# original implemenation
sub data_diff0 {
  my @diff = data_diff1( @_ );

  for ( @diff ) {
    # $path is always defined and an ARRAY reference
    my $path = $_->{ path };
    my $i    = 0;
    # patch $path: remove type information
    @$path = grep { $_ if $i++ % 2 } @$path;
  }

  return @diff;
}

sub data_diff1 {
  my ( $a, $b ) = @_;

  my $comparator = _choose_comparator( $a, $b );
  return ( defined $comparator ? $comparator->( $a, $b ) : _create_data_diff_detail( _CHANGE, $a, $b ) );
}

sub _choose_comparator {
  my ( $comparator_a, $comparator_b );
  for ( @_ ) {
    my $ref_type = ref;
    _croak( 'Cannot handle %s ref type yet', $ref_type )
      unless $comparator_b = __PACKAGE__->can( '_diff_' . ( $ref_type eq '' ? 'SCALAR' : "${ref_type}_REF" ) );
    $comparator_a = $comparator_b, next if not defined $comparator_a;
    return $comparator_a if $comparator_a == $comparator_b;
  }
  return;    # signal different comparators
}

sub _create_data_diff_detail {
  my ( $type, $a, $b, @path ) = @_;

  return {
    path => [ @path ],
    $type & ( _DELETE | _CHANGE ) ? ( a => $a ) : (), $type & ( _ADD | _CHANGE ) ? ( b => $b ) : ()
  };
}

sub _croak {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

sub _diff_ARRAY_REF {
  my ( $a, $b, @path ) = @_;

  my @diff;
  my $n = $#$a > $#$b ? $#$a : $#$b;

  foreach my $i ( 0 .. $n ) {
    if ( $i > $#$a ) {
      push @diff, _create_data_diff_detail( _ADD, undef, $b->[ $i ], @path, i => $i );
    } elsif ( $i > $#$b ) {
      push @diff, _create_data_diff_detail( _DELETE, $a->[ $i ], undef, @path, i => $i );
    } else {
      my $comparator = _choose_comparator( $a->[ $i ], $b->[ $i ] );
      push @diff,
        (
        defined $comparator
        ? $comparator->( $a->[ $i ], $b->[ $i ], @path, i => $i )
        : _create_data_diff_detail( _CHANGE, $a->[ $i ], $b->[ $i ], @path, i => $i )
        );
    }
  }

  return @diff;
}

sub _diff_HASH_REF {
  my ( $a, $b, @path ) = @_;

  my @diff;
  my %k;
  @k{ keys %$a, keys %$b } = ();

  foreach my $k ( sort keys %k ) {
    if ( !exists $a->{ $k } ) {
      push @diff, _create_data_diff_detail( _ADD, undef, $b->{ $k }, @path, k => $k );
    } elsif ( !exists $b->{ $k } ) {
      push @diff, _create_data_diff_detail( _DELETE, $a->{ $k }, undef, @path, k => $k );
    } else {
      my $comparator = _choose_comparator( $a->{ $k }, $b->{ $k } );
      push @diff,
        (
        defined $comparator
        ? $comparator->( $a->{ $k }, $b->{ $k }, @path, k => $k )
        : _create_data_diff_detail( _CHANGE, $a->{ $k }, $b->{ $k }, @path, k => $k )
        );
    }
  }

  return @diff;
}

# TODO: fix hard coded string comparison
sub _diff_SCALAR {
  my ( $a, $b, @path ) = @_;

  return ( defined $a ? defined $b ? $a ne $b : 1 : defined $b )
    ? _create_data_diff_detail( _CHANGE, $a, $b, @path )
    : ();
}

1;

__END__

=head1 NAME

Data::Difference - Compare simple hierarchical data

=head1 SYNOPSYS

  use Data::Difference data_diff => { -version => 'v1' };

  my %from = ( Q => 1, W => 2, E => 3, X => [ 1, 2, 3 ], Y=> [ 5, 6 ] );
  my %to = ( W => 4, E => 3, R => 5, => X => [ 1, 2 ], Y => [ 5, 7, 9 ] );
  my @diff = data_diff( \%from, \%to );

  @diff = (
    # value $a->{ Q } was deleted
    { a    => 1, path => [ k => 'Q' ] },

    # value $b->{ R } was added
    { b    => 5, path => [ k => 'R' ] },

    # value $a->{ W } was changed
    { a    => 2, b    => 4, path => [ k => 'W' ] },

    # value $a->{ X }[ 2 ] was deleted
    { a    => 3, path => [ k => 'X', i => 2 ] },

    # value $a->{ Y }[ 1 ] was changed
    { a    => 6, b    => 7, path => [ k => 'Y', i => 1 ] },

    # value $b->{ Y }[ 2 ] was added
    { b    => 9, path => [ k => 'Y', i => 2 ] },
  );

=head1 DESCRIPTION

C<Data::Difference> will compare simple data structures returning a list of
details about what was added, removed or changed. It will currently handle
SCALARs, HASH references and ARRAY references.

Each change is returned as a HASH reference with the following elements:

=over

=item path

path will be an ARRAY reference containing the hierarchical path to the value.
The array is either empty or has an even number of elements. The elements
with an even index specify the type of the following element. The type is
either "k" for a hash key or "i" for an array index.

If you import C<data_diff> without specifying an implementation version or with
the implementation version "v0", you will get the original one that is part of
C<Data::Difference> version 0.112850. This original implementation does not
show type information in the path.

=item a

If it exists it will contain the value from the first argument passed to
C<data_diff>. If it does not exist then this element did not exist in the first
argument.

=item b

If it exists it will contain the value from the second argument passed to
C<data_diff>. If it does not exist then this element did not exist in the
second argument.

=back

=head1 SEE ALSO

=over

=item *

L<Data::Comparator>

=item *

L<Data::Diff>

=item *

L<Test2::Compare::Delta>

=back

=head1 AUTHOR

Graham Barr C<< <gbarr@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2011 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
