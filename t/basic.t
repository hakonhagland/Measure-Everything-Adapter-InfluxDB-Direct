use strict;
use warnings;
use Test::MockModule;
use Test::More;

use Measure::Everything::Adapter;

# Mock the Hijk module
my $mock = Test::MockModule->new('Hijk');
my @requests;

$mock->mock(
    request => sub {
        my ($args) = @_;
        push @requests, $args;
        return { status => 204, body => 'mocked response' };
    }
);

# Set the adapter to InfluxDB::Direct
Measure::Everything::Adapter->set( 'InfluxDB::Direct',
    host     => 'influx.example.com',
    port     => 8086,
    db       => 'conversions',
    username => 'user',
    password => 'pass'
);

use Measure::Everything qw($stats);

# Define a subtest for the init method
subtest 'init method' => sub {
    isa_ok($stats, 'Measure::Everything::Adapter::InfluxDB::Direct', 'Adapter is of correct type');
    is($stats->{host}, 'influx.example.com', 'Host is set correctly');
    is($stats->{port}, 8086, 'Port is set correctly');
    is($stats->{db}, 'conversions', 'Database is set correctly');
    like($stats->{_fixed_args}->{Authorization}, qr/^Basic /, 'Authorization header is set');
};

# Define a subtest for the write method
subtest 'write method' => sub {
    $stats->write('metric', 1);
    is(scalar @requests, 1, 'Hijk::request was called once');

    my $call_args = $requests[0];
    is($call_args->{method}, 'POST', 'Request method is POST');
    is($call_args->{host}, 'influx.example.com', 'Host is correct');
    is($call_args->{port}, 8086, 'Port is correct');
    is($call_args->{path}, '/write', 'Path is correct');
    like($call_args->{query_string}, qr/^db=conversions$/, 'Query string is correct');
};

done_testing();



