#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Plack;
use Plack::Builder;
use Plack::Request;
use Plack::App::File;

use Graph::QL::Schema;
use Graph::QL::Operation;
use Graph::QL::Introspection;
use Graph::QL::Execution::ExecuteQuery;

use Graph::QL::Resolver::SchemaResolver;
use Graph::QL::Resolver::TypeResolver;
use Graph::QL::Resolver::FieldResolver;

use Graph::QL::Util::JSON;

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

# add introspection ...

$schema    = Graph::QL::Introspection->enable_for_schema( $schema );
$resolvers = Graph::QL::Introspection->enable_for_resolvers( $resolvers );

builder {

    mount '/css/graphiql.css'   => Plack::App::File->new( file => './root/static/css/graphiql.css'   )->to_app;
    mount '/js/graphiql.min.js' => Plack::App::File->new( file => './root/static/js/graphiql.min.js' )->to_app;
    mount '/index.html'         => Plack::App::File->new( file => './root/static/index.html'         )->to_app;

    mount '/graphql' => sub {
        my $r = Plack::Request->new( $_[0] );

        my $query = $r->param('query');

        if ( not $query ) {
            $query = Graph::QL::Util::JSON::decode( $r->content )->{query};
        }

        my $operation = Graph::QL::Operation->new_from_source( $query );

        my $e = Graph::QL::Execution::ExecuteQuery->new(
            schema    => $schema,
            resolvers => $resolvers,
            operation => $operation,
        );

        $e->validate;
        if ( $e->has_errors ) {
            return [ 500, [], [ Graph::QL::Util::JSON::encode( { errors => [ $e->get_errors ] } ) ]];
        }
        else {
            my $result = $e->execute;
            return [ 200, [], [ Graph::QL::Util::JSON::encode( { data => $result } ) ]]
        }
    };

    mount '/' => sub { [ 302, [ Location => '/index.html' ], []] };
};



