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

    # http://facebook.github.io/graphql/June2018/#example-45e4e
    my $expected_type_language =
'input Point2D {
    x : Float
    y : Float
}';

    my $Float = Graph::QL::Meta::Type::Scalar->new( name => 'Float' );

    my $Point2D = Graph::QL::Meta::Type::InputObject->new(
        name         => 'Point2D',
        input_fields => [
            Graph::QL::Meta::InputValue->new( name => 'x', type => $Float ),
            Graph::QL::Meta::InputValue->new( name => 'y', type => $Float ),
        ]
    );

    #warn $schema->to_type_language;

    eq_or_diff($Point2D->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');
};

done_testing;
