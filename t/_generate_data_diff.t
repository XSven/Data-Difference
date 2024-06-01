use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT like ok use_ok ) ], tests => 4;
use Test::Fatal qw( exception );

my $module;

BEGIN {
  $module = 'Data::Difference';
  use_ok( $module ) or BAIL_OUT "Cannot load module '$module'!";
}

like exception { $module->_generate_data_diff( undef, { -version => 'alpha' } ) }, qr/\AImproper/,
  'improper version format';
like exception { $module->_generate_data_diff( undef, { -version => 'v2' } ) }, qr/has no version 'v2' implementation/,
  'data_diff() has no implementation for the given version';
ok $module->_generate_data_diff( undef, { -version => 'v0' } ) == $module->can( 'data_diff0' ),
  'generate original implementation of data_diff()'
