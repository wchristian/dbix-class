use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use lib qw(t/lib);

use DBICTest;
my $schema = DBICTest->init_schema;

throws_ok (sub {
  $schema->txn_do (sub { die 'lol' } );
}, 'DBIx::Class::Exception', 'a DBIC::Exception object thrown');

throws_ok (sub {
  $schema->txn_do (sub { die [qw/lol wut/] });
}, qr/ARRAY\(0x/, 'An arrayref thrown');

is_deeply (
  $@,
  [qw/ lol wut /],
  'Exception-arrayref contents preserved',
);

for my $ap (qw(
  DBICTest::AntiPattern::TrueZeroLen
  DBICTest::AntiPattern::NullObject
)) {
  eval "require $ap";

  warnings_like {
    eval {
      $schema->txn_do (sub { die $ap->new });
    };

    isa_ok $@, $ap;
  } qr/\QObjects of external exception class '$ap' stringify to '' (the empty string)/,
    'Proper warning on encountered antipattern';
}

done_testing;
