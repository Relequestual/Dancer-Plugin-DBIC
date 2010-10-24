use strict;
use warnings;
use Test::More tests => 4, import => ['!pass'];
use Test::Exception;

use Dancer qw(:syntax);
use Dancer::Plugin::DBIC;
use DBI;
use File::Temp qw(tempfile);

eval { require DBD::SQLite };
if ($@) {
    plan skip_all => 'DBD::SQLite required to run these tests';
}

my (undef, $dbfile) = tempfile(OPEN => 1);

set plugins => {
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
        },
    }
};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
ok $dbh->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test db.';

my @users = ( ['bob', 2] );
for my $user (@users) { $dbh->do('insert into user values(?,?)', {}, @$user) }

my $user = schema->resultset('User')->find('bob');
ok $user, 'Found bob.';
is $user->age => '2', 'Bob is a baby.';

throws_ok { schema('bar')->resultset('User')->find('bob') }
    qr/schema bar is not configured/, 'Missing schema error thrown';
