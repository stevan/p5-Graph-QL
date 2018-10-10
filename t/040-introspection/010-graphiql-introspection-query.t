#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Test::Fatal;

use Path::Tiny;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');
    use_ok('Graph::QL::Operation');
    use_ok('Graph::QL::Execution::ExecuteQuery');

    use_ok('Graph::QL::Resolver::SchemaResolver');
    use_ok('Graph::QL::Resolver::TypeResolver');
    use_ok('Graph::QL::Resolver::FieldResolver');
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

my $resolvers = Graph::QL::Resolver::SchemaResolver->new(
    types => [
        Graph::QL::Resolver::TypeResolver->new(
            name   => 'Query',
            fields => [
                Graph::QL::Resolver::FieldResolver->new( name => 'hello', code => sub ($, $, $, $) { 'Hello World' } )
            ]
        )
    ]
);

my $operation = Graph::QL::Operation->new_from_source(q[
    query IntrospectionQuery {
      __schema {
        queryType { name }
        mutationType { name }
        subscriptionType { name }
        types {
          ...FullType
        }
        directives {
          name
          description
          locations
          args {
            ...InputValue
          }
        }
      }
    }

    fragment FullType on __Type {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args {
          ...InputValue
        }
        type {
          ...TypeRef
        }
        isDeprecated
        deprecationReason
      }
      inputFields {
        ...InputValue
      }
      interfaces {
        ...TypeRef
      }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
        deprecationReason
      }
      possibleTypes {
        ...TypeRef
      }
    }

    fragment InputValue on __InputValue {
      name
      description
      type { ...TypeRef }
      defaultValue
    }

    fragment TypeRef on __Type {
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

my $expected = JSON::MaybeXS->new->decode( Path::Tiny::path( 't/040-introspection/010-expected-response.json' )->slurp );

eq_or_diff( $result, $expected, '... got the expected query results');

done_testing;

