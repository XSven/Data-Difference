#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT done_testing use_ok ) ];
use Test::Differences qw( eq_or_diff );

BEGIN { use_ok( 'Data::Difference', 'data_diff' ) or BAIL_OUT 'Cannot load module Data::Difference!' }

my @tests = (
  { from => undef, to => undef, changes => [], name => 'no change (from and to are undefined)' },
  {
    from    => { D => { VERTICAL => 'down', HORIZONTAL => 'right' } },
    to      => { D => { VERTICAL => 'down', HORIZONTAL => 'right', FOO => 42 } },
    changes => [ { path => [ 'D', 'FOO' ], b => 42 } ],
    name    => 'value $b->{D}{FOO} was added'
  },
  { from => 1, to => 2, changes => [ { path => [], a => 1, b => 2 } ], name => 'value $a was changed' },
  {
    from    => [ 1, 2, 3 ],
    to      => [ 1, 2 ],
    changes => [ { path => [ 2 ], a => 3 } ],
    name    => 'value $a->[2] was deleted'
  },
  { from => [ 1, 2 ], to => [ 1, 2, 3 ], changes => [ { path => [ 2 ], b => 3 } ], name => 'value $b->[2] was added' },
  {
    from    => { Q => 1, W => 2, E => 3 },
    to      => { W => 4, E => 3, R => 5 },
    changes => [ { path => [ 'Q' ], a => 1 }, { path => [ 'R' ], b => 5 }, { path => [ 'W' ], a => 2, b => 4 }, ],
    name    => 'value $a->{Q} was deleted, value $b->{R} was added, value $a->{W} was changed'
  },
  {
    from    => { X => [ 1, 2, 3 ], Y => [ 5, 6 ] },
    to      => { X => [ 1, 2 ], Y => [ 5, 7, 9 ] },
    changes =>
      [ { path => [ 'X', 2 ], a => 3 }, { path => [ 'Y', 1 ], a => 6, b => 7 }, { path => [ 'Y', 2 ], b => 9 }, ],
    name => 'value $a->{X}[2] was deleted, value $a->{Y}[1] was changed, value $b->{Y}[2] was added'
  },
  {
    from    => { Z => 'foo' },
    to      => { Z => undef },
    changes => [ { path => [ 'Z' ], a => 'foo', b => undef } ],
    name    => 'value $a->{Z} was changed to undef (rt.cpan.org #109262)'
  },
  {
    from    => { Z => undef },
    to      => { Z => 'foo' },
    changes => [ { path => [ 'Z' ], a => undef, b => 'foo' } ],
    name    => 'value $a->{Z} was changed from undef to defined value (rt.cpan.org #109262)'
  },
);

foreach my $t ( @tests ) {
  eq_or_diff( [ data_diff( $t->{ from }, $t->{ to } ) ], $t->{ changes }, $t->{ name } || () );
}

done_testing();
