#<<<
use strict; use warnings;
#>>>

package Data::Difference;
# ABSTRACT: Compare simple hierarchical data

use Exporter qw( import );

our @EXPORT_OK = qw( data_diff );

sub data_diff {
  my ( $a, $b ) = @_;

  my $ref_type = ref( $a );
  if ( my $comparator = __PACKAGE__->can( '_diff_' . ( $ref_type eq '' ? 'SCALAR' : "${ref_type}_REF" ) ) ) {
    return $comparator->( $a, $b );
  }
  _croak( 'Cannot handle %s ref type yet', $ref_type );
}

sub _diff_SCALAR {
  my ( $a, $b, @path ) = @_;

  return ( defined $a ? defined $b ? $a ne $b : 1 : defined $b ) ? { path => [ @path ], a => $a, b => $b } : ();
}

sub _diff_HASH_REF {
  my ( $a, $b, @path ) = @_;

  return { path => \@path, a => $a, b => $b } unless ref( $a ) eq ref( $b );

  my @diff;
  my %k;
  @k{ keys %$a, keys %$b } = ();
  foreach my $k ( sort keys %k ) {
    if ( !exists $a->{ $k } ) {
      push @diff, { path => [ @path, "{$k}" ], b => $b->{ $k } };
    } elsif ( !exists $b->{ $k } ) {
      push @diff, { path => [ @path, "{$k}" ], a => $a->{ $k } };
    } else {
      my $ref_type = ref( $a->{ $k } );
      if ( my $comparator = __PACKAGE__->can( '_diff_' . ( $ref_type eq '' ? 'SCALAR' : "${ref_type}_REF" ) ) ) {
        push @diff, $comparator->( $a->{ $k }, $b->{ $k }, @path, "{$k}" );
      } else {
        _croak( 'Cannot handle %s ref type yet', $ref_type );
      }
    }
  }

  return @diff;
}

sub _diff_ARRAY_REF {
  my ( $a, $b, @path ) = @_;
  return { path => \@path, a => $a, b => $b } unless ref( $a ) eq ref( $b );

  my @diff;
  my $n = $#$a > $#$b ? $#$a : $#$b;

  foreach my $i ( 0 .. $n ) {
    if ( $i > $#$a ) {
      push @diff, { path => [ @path, "[$i]" ], b => $b->[ $i ] };
    } elsif ( $i > $#$b ) {
      push @diff, { path => [ @path, "[$i]" ], a => $a->[ $i ] };
    } else {
      my $ref_type = ref( $a->[ $i ] );
      if ( my $comparator = __PACKAGE__->can( '_diff_' . ( $ref_type eq '' ? 'SCALAR' : "${ref_type}_REF" ) ) ) {
        push @diff, $comparator->( $a->[ $i ], $b->[ $i ], @path, "[$i]" );
      } else {
        _croak( 'Cannot handle %s ref type yet', $ref_type );
      }
    }
  }

  return @diff;
}

sub _croak ( $@ ) {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

1;

__END__

=head1 NAME

Data::Difference - Compare simple hierarchical data

=head1 SYNOPSYS

  use Data::Difference qw( data_diff );

  my %from = ( Q => 1, W => 2, E => 3, X => [ 1, 2, 3 ], Y=> [ 5, 6 ] );
  my %to = ( W => 4, E => 3, R => 5, => X => [ 1, 2 ], Y => [ 5, 7, 9 ] );
  my @diff = data_diff( \%from, \%to );

  @diff = (
    # value $a->{ Q } was deleted
    { a    => 1, path => [ '{Q}' ] },

    # value $b->{ R } was added
    { b    => 5, path => [ '{R}' ] },

    # value $a->{ W } was changed
    { a    => 2, b    => 4, path => [ '{W}' ] },

    # value $a->{ X }[ 2 ] was deleted
    { a    => 3, path => [ '{X}', 2 ] },

    # value $a->{ Y }[ 1 ] was changed
    { a    => 6, b    => 7, path => [ '{Y}', '[1]' ] },

    # value $b->{ Y }[ 2 ] was added
    { b    => 9, path => [ '{Y}', '[2]' ] },
  );

=head1 DESCRIPTION

C<Data::Difference> will compare simple data structures returning a list of
details about what was added, removed or changed. It will currently handle
SCALARs, HASH references and ARRAY references.

Each change is returned as a hash reference with the following elements:

=over

=item path

path will be an ARRAY reference containing the hierarchical path to the value,
each element in the array will be either the key of a hash or the index on an
array.

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
