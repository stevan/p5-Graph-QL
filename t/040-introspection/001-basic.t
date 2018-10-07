#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Test::Fatal;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');
    use_ok('Graph::QL::Operation');
    use_ok('Graph::QL::Execution::ExecuteQuery');

    use_ok('Graph::QL::Resolvers');
    use_ok('Graph::QL::Resolvers::TypeResolver');
    use_ok('Graph::QL::Resolvers::FieldResolver');
    use_ok('Graph::QL::Schema::TypeKind');

    use_ok('Graph::QL::Introspection');
}

my $schema = Graph::QL::Schema->new_from_source(q[
    scalar Boolean
    scalar String

    type Query {
        hello : String
    }

    schema { query : Query }
]);

my $resolvers = Graph::QL::Resolvers->new(
    types => [
        Graph::QL::Resolvers::TypeResolver->new(
            name   => 'Query',
            fields => [
                Graph::QL::Resolvers::FieldResolver->new( name => 'hello', code => sub ($, $, $, $) { 'Hello World' } )
            ]
        )
    ]
);

my $operation = Graph::QL::Operation->new_from_source(q[
    query TestQuery {
        hello
        __type( name : "Query" ) {
            name
        }
        __schema {
            types {
                kind
                name
                description
                interfaces {
                    name
                }
                possibleTypes {
                    name
                }
                inputFields {
                    name
                }
                fields(includeDeprecated : true) {
                    name
                    args {
                        name
                        type {
                            kind
                            name
                        }
                    }
                    type {
                        kind
                        name
                        ofType {
                            kind
                            name
                            ofType {
                                kind
                                name
                                ofType {
                                    kind
                                    name
                                    ofType {
                                        kind
                                        name
                                    }
                                }
                            }
                        }
                    }
                }
                enumValues(includeDeprecated : true) {
                    name
                }
            }
        }
    }
]);

my $e = Graph::QL::Execution::ExecuteQuery->new(
    schema    => Graph::QL::Introspection->enable_for_schema( $schema ),
    resolvers => Graph::QL::Introspection->enable_for_resolvers( $resolvers ),
    operation => $operation,
);
isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

ok($e->validate, '... the schema and query validated correctly');
ok(!$e->has_errors, '... no errors have been be found');

my $result = $e->execute;

ok($result, '... we got a defined result');

# warn Dumper $result;

done_testing;
