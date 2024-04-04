use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT like use_ok ) ], tests => 16;
use Test::Differences qw( eq_or_diff );
use Test::Fatal       qw( exception );

my $module;

BEGIN {
  $module = 'Data::Difference';
  use_ok( $module, data_diff => { -version => 'v2' } ) or BAIL_OUT "Cannot load module '$module'!";
}

my @tests = (
  { from => undef, to => undef, diff => [], name => 'no change ($from and $to are undefined)' },
  { from => 1,     to => 2,     diff => [ { path => [], a => 1, b => 2 } ], name => 'value $from was changed' },
  {
    from => 1,
    to   => undef,
    diff => [ { path => [], a => 1, b => undef } ],
    name => 'value $from was changed to undef (rt.cpan.org #109262)'
  },
  {
    from => undef,
    to   => 2,
    diff => [ { path => [], a => undef, b => 2 } ],
    name => 'value $from was changed from undef to defined value (rt.cpan.org #109262)'
  },
  {
    from => [ 1, 2, 3 ],
    to   => { W => 4, E => 3, R => 5 },
    diff => [ { path => [], a => [ 1, 2, 3 ], b => { W => 4, E => 3, R => 5 } } ],
    name => 'compare incompatible ref types'
  },
  {
    from => { D => { VERTICAL => 'down', HORIZONTAL => 'right' } },
    to   => { D => { VERTICAL => 'down', HORIZONTAL => 'right', FOO => 42 } },
    diff => [ { path => [ k => 'D', k => 'FOO' ], b => 42 } ],
    name => 'value $to->{ D }{ FOO } was added'
  },
  {
    from => [ 1, 2, 3 ],
    to   => [ 1, 2 ],
    diff => [ { path => [ i => 2 ], a => 3 } ],
    name => 'value $from->[ 2 ] was deleted'
  },
  {
    from => [ 1, 2 ],
    to   => [ 1, 2, 3 ],
    diff => [ { path => [ i => 2 ], b => 3 } ],
    name => 'value $to->[ 2 ] was added'
  },
  {
    from => { Q => 1, W => 2, E => 3 },
    to   => { W => 4, E => 3, R => 5 },
    diff =>
      [ { path => [ k => 'Q' ], a => 1 }, { path => [ k => 'R' ], b => 5 }, { path => [ k => 'W' ], a => 2, b => 4 } ],
    name => 'value $from->{ Q } was deleted, value $to->{ R } was added, value $from->{ W } was changed'
  },
  {
    from => { X => [ 1, 2, 3 ], Y => [ 5, 6 ] },
    to   => { X => [ 1, 2 ], Y => [ 5, 7, 9 ] },
    diff => [
      { path => [ k => 'X', i => 2 ], a => 3 },
      { path => [ k => 'Y', i => 1 ], a => 6, b => 7 },
      { path => [ k => 'Y', i => 2 ], b => 9 }
    ],
    name => 'value $from->{ X }[ 2 ] was deleted, value $from->{ Y }[ 1 ] was changed, value $to->{ Y }[ 2 ] was added'
  },
  {
    from => { Z => 'foo' },
    to   => { Z => undef },
    diff => [ { path => [ k => 'Z' ], a => 'foo', b => undef } ],
    name => 'value $from->{ Z } was changed to undef (rt.cpan.org #109262)'
  },
  {
    from => { Z => undef },
    to   => { Z => 'foo' },
    diff => [ { path => [ k => 'Z' ], a => undef, b => 'foo' } ],
    name => 'value $from->{ Z } was changed from undef to defined value (rt.cpan.org #109262)'
  },
  {
    from => { Z => 'foo' },
    to   => { Z => [ 'foo' ] },
    diff => [ { path => [ k => 'Z' ], a => 'foo', b => [ 'foo' ] } ],
    name => 'value $from->{ Z } was changed (SCALAR to ARRAY REF type)'
  },
  {
    from => [ qw( foo bar baz ) ],
    to   => [ qw( foo bar ), [ 'baz' ] ],
    diff => [ { path => [ i => 2 ], a => 'baz', b => [ 'baz' ] } ],
    name => 'value $from->[ 2 ] was changed (SCALAR to ARRAY REF type)'
  },
);

foreach my $t ( @tests ) {
  eq_or_diff( [ data_diff( $t->{ from }, $t->{ to } ) ], $t->{ diff }, $t->{ name } || () );
}

like exception { data_diff( \1, 2 ) }, qr/\A Cannot\ handle/x, '$from has an unsupported ref type';
