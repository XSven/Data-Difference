#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT is plan subtest use_ok ) ], tests => 4;

BEGIN { use_ok( 'Data::Difference', 'data_diff' ) or BAIL_OUT 'Cannot load module Data::Difference!' }

my $from = { X => [ 1, 2, 3 ], Y => [ 5, 6 ] };
my $to   = { X => [ 1, 2 ], Y => [ 5, 7, 9 ] };
my @diff = data_diff( $from, $to );

subtest 'something was deleted' => sub {
  plan tests => 2;

  # https://perldoc.perl.org/perlref#Arrow-Notation
  # The arrow is optional between brackets subscripts. That's why we can simply
  # join the array elements of the path.
  my $path = join '', @{ $diff[ 0 ]->{ path } };
  is $path,                '{X}[2]',          'path as string';
  is eval "\$from->$path", $diff[ 0 ]->{ a }, 'apply path to "from"';
};

subtest 'something was changed' => sub {
  plan tests => 3;

  my $path = join '', @{ $diff[ 1 ]->{ path } };
  is $path,                '{Y}[1]',          'path as string';
  is eval "\$from->$path", $diff[ 1 ]->{ a }, 'apply path to "from"';
  is eval "\$to->$path",   $diff[ 1 ]->{ b }, 'apply path to "to"';
};

subtest 'something was added' => sub {
  plan tests => 2;

  my $path = join '', @{ $diff[ 2 ]->{ path } };
  is $path,              '{Y}[2]',          'path as string';
  is eval "\$to->$path", $diff[ 2 ]->{ b }, 'apply path to "to"';
};
