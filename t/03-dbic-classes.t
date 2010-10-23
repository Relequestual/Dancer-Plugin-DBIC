use strict;
use warnings;
use Test::More tests => 3, import => ['!pass'];

use Dancer ':syntax';
use DBI;
use FindBin '$RealBin';
use lib "$RealBin/lib";

use File::Spec;
use File::Temp qw/tempdir/;

eval { require DBD::SQLite };
if ($@) {
    plan skip_all => 'DBD::SQLite required to run these tests';
}

my $dir = tempdir( CLEANUP => 1 );
my $dbfile = File::Spec->catfile($dir, 'test3.db');

set plugins => {
    DBIC => {
        foo => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfile",
        }
    }
};

unlink $dbfile;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

ok $dbh->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test db.';

my @users = ( ['bob', 40] );
for my $user (@users) { $dbh->do('insert into user values(?,?)', {}, @$user) }

use lib "$RealBin/../lib";
use Dancer::Plugin::DBIC;

my $user = schema('foo')->resultset('User')->find('bob');
ok $user, 'Found bob.';
is $user->age => '40', 'Bob is even older.';

unlink $dbfile;
