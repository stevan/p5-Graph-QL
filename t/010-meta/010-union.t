#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Meta::Schema');

    use_ok('Graph::QL::Meta::Directive');
    use_ok('Graph::QL::Meta::Type');

    use_ok('Graph::QL::Meta::Type::Enum');
    use_ok('Graph::QL::Meta::Type::InputObject');
    use_ok('Graph::QL::Meta::Type::Interface');
    use_ok('Graph::QL::Meta::Type::List');
    use_ok('Graph::QL::Meta::Type::NonNull');
    use_ok('Graph::QL::Meta::Type::Object');
    use_ok('Graph::QL::Meta::Type::Scalar');
    use_ok('Graph::QL::Meta::Type::Union');

    use_ok('Graph::QL::Meta::Field');
    use_ok('Graph::QL::Meta::EnumValue');
    use_ok('Graph::QL::Meta::InputValue');
}

subtest '... testing my schema' => sub {

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

    my $Int    = Graph::QL::Meta::Type::Scalar->new( name => 'Int' );
    my $String = Graph::QL::Meta::Type::Scalar->new( name => 'String' );

    my $Person = Graph::QL::Meta::Type::Object->new(
        name   => 'Person',
        fields => [
            Graph::QL::Meta::Field->new( name => 'name', type => $String ),
            Graph::QL::Meta::Field->new( name => 'age',  type => $Int    ),
        ]
    );

    my $Photo = Graph::QL::Meta::Type::Object->new(
        name   => 'Photo',
        fields => [
            Graph::QL::Meta::Field->new( name => 'height', type => $Int ),
            Graph::QL::Meta::Field->new( name => 'width',  type => $Int ),
        ]
    );

    my $SearchResult = Graph::QL::Meta::Type::Union->new(
        name           => 'SearchResult',
        possible_types => [ $Photo, $Person ]
    );

    my $SearchQuery = Graph::QL::Meta::Type::Object->new(
        name   => 'SearchQuery',
        fields => [
            Graph::QL::Meta::Field->new(
                name => 'firstSearchResult',
                type => $SearchResult,
            )
        ]
    );

    my $schema = Graph::QL::Meta::Schema->new(
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
