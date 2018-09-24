package Graph::QL::Parser;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Parser::GraphQL::XS;
use JSON::MaybeXS   ();
use Module::Runtime ();

use Graph::QL::Util::Errors 'throw';
use Graph::QL::Util::Strings;

our $VERSION = '0.01';

sub parse_schema ($class, $source) {
    my $document = $class->parse( $source );

    throw('Unable to find the SchemaDefinition node, not a schema')
        if 0 == scalar grep $_->isa('Graph::QL::AST::Node::SchemaDefinition'), $document->definitions->@*;

    return $document;
}

sub parse_operation ($class, $source) {
    my $document = $class->parse( $source );

    throw('Unable to find the OperationDefinition node, not an operation')
        if 0 == scalar grep $_->isa('Graph::QL::AST::Node::OperationDefinition'), $document->definitions->@*;

    return $document;
}

sub parse ($class, $source) {
    my $ast  = $class->parse_raw( $source );
    my $node = $class->build_from_ast( $ast );
    return $node;
}

sub parse_raw ($class, $source) {
    state $JSON = JSON::MaybeXS->new->utf8;

    my $ast;
    eval {
        my $json = Parser::GraphQL::XS->new->parse_string( $source );
           $ast  = $JSON->decode( $json );
        1;
    } or do {
        throw('Parsing failed because:[ %s ]', $@);
    };

    return $ast;
}

sub build_from_ast ($class, $ast) {

    my $node_kind  = $ast->{kind};
    my $node_loc   = $ast->{loc};
    my $node_class = 'Graph::QL::AST::Node::'.$node_kind;

    Module::Runtime::use_module($node_class);

    my %args;
    foreach my $key ( keys $ast->%* ) {

        next if $key eq 'kind' or $key eq 'loc';

        next unless defined $ast->{ $key };

        my $slot = Graph::QL::Util::Strings::camel_to_snake( $key );

        if ( ref $ast->{ $key } eq 'ARRAY' ) {
            $args{ $slot } = [ map $class->build_from_ast( $_ ), $ast->{ $key }->@* ];
        }
        elsif ( ref $ast->{ $key } eq 'HASH' ) {
            $args{ $slot } = $class->build_from_ast( $ast->{ $key } );
        }
        else {
            $args{ $slot } = $ast->{ $key };
        }
    }

    return $node_class->new( %args, location => $node_loc );
}

1;

__END__

=pod

=cut

