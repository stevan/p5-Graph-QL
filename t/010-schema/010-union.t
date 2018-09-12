#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Type::Object');
    use_ok('Graph::QL::Schema::Type::Scalar');
    use_ok('Graph::QL::Schema::Type::Union');

    use_ok('Graph::QL::Schema::Field');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-255de
    my $expected_type_language = q[
scalar Int

scalar String

type Person {
    name : String
    age : Int
}

type Photo {
    height : Int
    width : Int
}

union SearchResult = Photo | Person

type SearchQuery {
    firstSearchResult : SearchResult
}

schema {
    query : SearchQuery
}
];

    my $Int    = Graph::QL::Schema::Type::Scalar->new( name => 'Int' );
    my $String = Graph::QL::Schema::Type::Scalar->new( name => 'String' );

    my $Person = Graph::QL::Schema::Type::Object->new(
        name   => 'Person',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name', type => $String ),
            Graph::QL::Schema::Field->new( name => 'age',  type => $Int    ),
        ]
    );

    my $Photo = Graph::QL::Schema::Type::Object->new(
        name   => 'Photo',
        fields => [
            Graph::QL::Schema::Field->new( name => 'height', type => $Int ),
            Graph::QL::Schema::Field->new( name => 'width',  type => $Int ),
        ]
    );

    my $SearchResult = Graph::QL::Schema::Type::Union->new(
        name           => 'SearchResult',
        possible_types => [ $Photo, $Person ]
    );

    my $SearchQuery = Graph::QL::Schema::Type::Object->new(
        name   => 'SearchQuery',
        fields => [
            Graph::QL::Schema::Field->new(
                name => 'firstSearchResult',
                type => $SearchResult,
            )
        ]
    );

    my $schema = Graph::QL::Schema->new(
        query_type => $SearchQuery,
        types => [
            $Int,
            $String,
            $Person,
            $Photo,
            $SearchResult,
            $SearchQuery
        ]
    );

    #warn $schema->to_type_language;

    eq_or_diff($schema->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');
};

done_testing;
