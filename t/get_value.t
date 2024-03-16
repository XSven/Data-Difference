#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT is plan subtest use_ok ) ], tests => 4;

my $module;

BEGIN {
  $module = 'Data::Difference';
  use_ok( $module, qw( get_value data_diff ) ) or BAIL_OUT "Cannot load module '$module'!";
}

my $from = { X => [ 1, 2, 3 ], Y => [ 5, 6 ] };
my $to   = { X => [ 1, 2 ], Y => [ 5, 7, 9 ] };
my @diff = data_diff( $from, $to );

subtest 'something was deleted' => sub {
  plan tests => 1;

  my $path = $diff[ 0 ]->{ path };
  is get_value( $from, $path ), $diff[ 0 ]->{ a }, 'apply path to "from"';
};

subtest 'something was changed' => sub {
  plan tests => 2;

  my $path = $diff[ 1 ]->{ path };
  is get_value( $from, $path ), $diff[ 1 ]->{ a }, 'apply path to "from"';
  is get_value( $to,   $path ), $diff[ 1 ]->{ b }, 'apply path to "to"';
};

subtest 'something was added' => sub {
  plan tests => 1;

  my $path = $diff[ 2 ]->{ path };
  is get_value( $to, $path ), $diff[ 2 ]->{ b }, 'apply path to "to"';
};
