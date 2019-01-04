#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Fatal;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');
    use_ok('Graph::QL::Parser');
 	use_ok('Parser::GraphQL::XS');
}

my $JSON = JSON::MaybeXS->new->utf8;

my $source = q[
query {
    find(id: "Bob\tSmith") {
        id
    }
}
];

my $json_string = Parser::GraphQL::XS->new->parse_string( $source );

# this will show you the raw JSON string from the parser
#warn $json_string;

# this will fix this test by cleaning up the bad \t chars ... 
#$json_string =~ s/\t/\\t/g;

# this will currently fail, but should pass 
is(exception {
	$JSON->decode( $json_string )
}, undef, '... we can parse something with a tab in it');


done_testing;
