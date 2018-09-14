#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Enum');
    use_ok('Graph::QL::Schema::InputObject');
    use_ok('Graph::QL::Schema::Interface');
    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Scalar');
    use_ok('Graph::QL::Schema::Union');

    use_ok('Graph::QL::Schema::Field');

    use_ok('Graph::QL::Schema::Type::List');
    use_ok('Graph::QL::Schema::Type::NonNull');
    use_ok('Graph::QL::Schema::Type::Named');

    use_ok('Graph::QL::Schema::Enum::EnumValue');
    use_ok('Graph::QL::Schema::InputObject::InputValue');
}


my $Int       = Graph::QL::Schema::Type::Named->new( name => 'Int' );
my $String    = Graph::QL::Schema::Type::Named->new( name => 'String' );
my $Type      = Graph::QL::Schema::Type::Named->new( name => 'Type' );
my $InputType = Graph::QL::Schema::Type::Named->new( name => 'InputType' );

my $nn_InputType = Graph::QL::Schema::Type::NonNull->new( of_type => $InputType );
my $nn_String    = Graph::QL::Schema::Type::NonNull->new( of_type => $String );
my $list_String  = Graph::QL::Schema::Type::List->new( of_type => $String );

# https://raw.githubusercontent.com/graphql/libgraphqlparser/master/test/schema-kitchen-sink.graphql

subtest '... schema' => sub {
    my $string =
q[schema {
    query : QueryType
    mutation : MutationType
}];

    my $schema = Graph::QL::Schema->new(
        query_type    => Graph::QL::Schema::Type::Named->new( name => 'QueryType' ),
        mutation_type => Graph::QL::Schema::Type::Named->new( name => 'MutationType' ),
    );
    isa_ok($schema, 'Graph::QL::Schema');
    eq_or_diff($schema->to_type_language, $string, '... the type language roundtripped');
};

=pod

subtest '... type' => sub {
    my $string =
q[type Foo implements Bar {
    one : Type
    two(argument : InputType!) : Type
    three(argument : InputType, other : String) : Int
    four(argument : String = "string") : String
    five(argument : [String] = ["string", "string"]) : String
    six(argument : InputType = {key: "value"}) : Type
    seven(argument : Int = null) : Type
}];

    my $type = Graph::QL::Schema::Object->new(
        name       => 'Foo',
        interfaces => [ Graph::QL::Schema::Interface->new( name => 'Bar' ) ],
        fields     => [
            Graph::QL::Schema::Field->new( name => 'one', type => $Type ),
            Graph::QL::Schema::Field->new(
                name => 'two',
                args => [ Graph::QL::Schema::InputObject::InputValue->new( name => 'argument', type => $nn_InputType ) ],
                type => $Type
            ),
            Graph::QL::Schema::Field->new(
                name => 'three',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new( name => 'argument', type => $InputType ),
                    Graph::QL::Schema::InputObject::InputValue->new( name => 'other', type => $String )
                ],
                type => $Int
            ),
            Graph::QL::Schema::Field->new(
                name => 'four',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new( name => 'argument', type => $String, default_value => '"string"' ),
                ],
                type => $String
            ),
            Graph::QL::Schema::Field->new(
                name => 'five',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new( name => 'argument', type => $list_String, default_value => '["string", "string"]' ),
                ],
                type => $String
            ),
            Graph::QL::Schema::Field->new(
                name => 'six',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new( name => 'argument', type => $InputType, default_value => '{key: "value"}' ),
                ],
                type => $Type
            ),
            Graph::QL::Schema::Field->new(
                name => 'seven',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new( name => 'argument', type => $Int, default_value => 'null' ),
                ],
                type => $Type
            ),
        ]
    );
    isa_ok($type, 'Graph::QL::Schema::Object');
    eq_or_diff($type->to_type_language, $string, '... the type language roundtripped');
};

=cut

subtest '... interface' => sub {
    my $string =
q[interface Bar {
    one : Type
    four(argument : String) : String
}];

# TODO: `default_value` in Field
# four(argument : String = "string") : String

    my $interface = Graph::QL::Schema::Interface->new(
        name => 'Bar',
        fields => [
            Graph::QL::Schema::Field->new( name => 'one', type => $Type ),
            Graph::QL::Schema::Field->new(
                name => 'four',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name => 'argument',
                        type => $String,
                        # TODO: `default_value` in Field
                        # default_value => '"string"'
                    ),
                ],
                type => $String
            ),
        ]
    );
    isa_ok($interface, 'Graph::QL::Schema::Interface');
    eq_or_diff($interface->to_type_language, $string, '... the type language roundtripped');
};



subtest '... union' => sub {
    my $string = q[union Feed = Story | Article | Advert];

    my $union = Graph::QL::Schema::Union->new(
        name  => 'Feed',
        types => [
            Graph::QL::Schema::Type::Named->new( name => 'Story' ),
            Graph::QL::Schema::Type::Named->new( name => 'Article' ),
            Graph::QL::Schema::Type::Named->new( name => 'Advert' ),
        ]
    );
    isa_ok($union, 'Graph::QL::Schema::Union');
    eq_or_diff($union->to_type_language, $string, '... the type language roundtripped');
};

subtest '... scalar' => sub {
    my $string = q[scalar CustomScalar];
    my $scalar = Graph::QL::Schema::Scalar->new( name => 'CustomScalar' );
    isa_ok($scalar, 'Graph::QL::Schema::Scalar');
    eq_or_diff($scalar->to_type_language, $string, '... the type language roundtripped');
};

subtest '... enum' => sub {
    my $string =
q[enum Site {
    DESKTOP
    MOBILE
}];

    my $enum = Graph::QL::Schema::Enum->new(
        name => 'Site',
        values => [
            Graph::QL::Schema::Enum::EnumValue->new( name => 'DESKTOP' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'MOBILE' ),
        ]
    );
    isa_ok($enum, 'Graph::QL::Schema::Enum');
    eq_or_diff($enum->to_type_language, $string, '... the type language roundtripped');
};

subtest '... input-object' => sub {
    my $string =
q[input InputType {
    key : String
    answer : Int
}];

# TODO: fix types for nullable and list
# key : String!

# TODO: fix `default_value` in InputValue
# answer : Int = 42

    my $input_object = Graph::QL::Schema::InputObject->new(
        name   => 'InputType',
        fields => [
            Graph::QL::Schema::InputObject::InputValue->new( name => 'key', type => $String ),
            Graph::QL::Schema::InputObject::InputValue->new(
                name => 'answer',
                type => $Int,
                # TODO: fix `default_value` in InputValue
                # default_value => '42'
            ),
        ]
    );
    isa_ok($input_object, 'Graph::QL::Schema::InputObject');
    eq_or_diff($input_object->to_type_language, $string, '... the type language roundtripped');
};

done_testing;

__END__

# TODO:
# All the thigns listed below ...

type AnnotatedObject @onObject(arg: "value") {
  annotatedField(arg: Type = "default" @onArg): Type @onField
}

interface AnnotatedInterface @onInterface {
  annotatedField(arg: Type @onArg): Type @onField
}

union AnnotatedUnion @onUnion = A | B

scalar AnnotatedScalar @onScalar

enum AnnotatedEnum @onEnum {
  ANNOTATED_VALUE @onEnumValue
  OTHER_VALUE
}

input AnnotatedInput @onInputObjectType {
  annotatedField: Type @onField
}

extend type Foo {
  seven(argument: [String]): Type
}

# NOTE: out-of-spec test cases commented out until the spec is clarified; see
# https://github.com/graphql/graphql-js/issues/650 .
# extend type Foo @onType {}

#type NoFields {}

directive @skip(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

directive @include(if: Boolean!)
  on FIELD
   | FRAGMENT_SPREAD
   | INLINE_FRAGMENT


