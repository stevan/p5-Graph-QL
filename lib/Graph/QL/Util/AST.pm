package Graph::QL::Util::AST;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Module::Runtime ();

use Graph::QL::Util::Errors 'throw';
use Graph::QL::Util::Types;
use Graph::QL::Util::Strings;

our $VERSION = '0.01';

## ----------------------------------------------
## Constructors
## ----------------------------------------------

# Given a `raw` AST, we build the AST graph
sub build_from_ast ($ast) {

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
            $args{ $slot } = [ map build_from_ast( $_ ), $ast->{ $key }->@* ];
        }
        elsif ( ref $ast->{ $key } eq 'HASH' ) {
            $args{ $slot } = build_from_ast( $ast->{ $key } );
        }
        else {
            $args{ $slot } = $ast->{ $key };
        }
    }

    return $node_class->new( %args, location => $node_loc );
}

## ----------------------------------------------
## AST Converters (to/from)
## ----------------------------------------------

# If you do not have the type, but have a literal
# value, so want to have the system guess for you
# on what is the right Value node.
sub guess_literal_to_ast_node ($literal) {
    # NOTE:
    # this needs help, lots of help. Perhaps
    # we can rely on the Parser to do the right
    # thing here, we shall see.

    # not defined is obvious, it is null ...
    if ( not defined $literal ) {
        require Graph::QL::AST::Node::NullValue;
        return Graph::QL::AST::Node::NullValue->new;
    }
    # float values have floating point values
    elsif ( $literal =~ /^\d+\.\d+$/ ) {
        require Graph::QL::AST::Node::FloatValue;
        return Graph::QL::AST::Node::FloatValue->new( value => $literal );
    }
    # this is a very simplistic view of numbers,
    # and ignores scientific notation, etc.
    elsif ( $literal =~ /^\d+$/ ) {
        require Graph::QL::AST::Node::IntValue;
        return Graph::QL::AST::Node::IntValue->new( value => $literal );
    }
    # this is a bad way to handle Booleans, should
    # likely also check for JSON::PP::Booleans and
    # other such esoteria ...
    elsif ( $literal eq '' || $literal =~ /^1$/ || $literal =~ /^0$/  ) {
        require Graph::QL::AST::Node::BooleanValue;
        return Graph::QL::AST::Node::BooleanValue->new( value => $literal );
    }
    # fuck it, it is probably a string ¯\_(ツ)_/¯
    else {
        require Graph::QL::AST::Node::StringValue;
        return Graph::QL::AST::Node::StringValue->new( value => $literal );
    }
}

# If you know the type, then we can wrap
# it up accordingly and get you on your
# way without trouble ...
sub literal_to_ast_node ($literal, $type) {

    if ( not defined $literal ) {
        require Graph::QL::AST::Node::NullValue;
        return Graph::QL::AST::Node::NullValue->new;
    }
    elsif ( $type->name eq Graph::QL::Util::Types->BOOLEAN ) {
        require Graph::QL::AST::Node::BooleanValue;
        return Graph::QL::AST::Node::BooleanValue->new( value => $literal );
    }
    elsif ( $type->name eq Graph::QL::Util::Types->FLOAT ) {
        require Graph::QL::AST::Node::FloatValue;
        return Graph::QL::AST::Node::FloatValue->new( value => $literal );
    }
    elsif ( $type->name eq Graph::QL::Util::Types->INT ) {
        require Graph::QL::AST::Node::IntValue;
        return Graph::QL::AST::Node::IntValue->new( value => $literal );
    }
    elsif ( $type->name eq Graph::QL::Util::Types->STRING ) {
        require Graph::QL::AST::Node::StringValue;
        return Graph::QL::AST::Node::StringValue->new( value => $literal );
    }
    else {
        throw('Do not recognize the expected type(%s), unable to convert to ast-node', $type->name);
    }
}

# This is basically just because NullValue does
# not have a `value` method of its own to call
# so we do this, oh well :/
sub ast_node_to_literal ($ast_node) {
    # TODO:
    # type check $ast_node does (Graph::QL::AST::Node::Role::Value)

    return undef if $ast_node->isa('Graph::QL::AST::Node::NullValue');
    return $ast_node->value;
}

# simple util for the type-language pretty printer
sub ast_node_to_type_language ($ast_node) {

    if ( $ast_node->isa('Graph::QL::AST::Node::NullValue') ) {
        return 'null';
    }
    elsif ( $ast_node->isa('Graph::QL::AST::Node::BooleanValue') ) {
        return $ast_node->value ? 'true' : 'false';
    }
    elsif ( $ast_node->isa('Graph::QL::AST::Node::FloatValue') || $ast_node->isa('Graph::QL::AST::Node::IntValue') ) {
        return $ast_node->value;
    }
    elsif ( $ast_node->isa('Graph::QL::AST::Node::StringValue') ) {
        return '"'.$ast_node->value.'"';
    }
    else {
        throw('Do not recognize the expected ast-node(%s), unable to convert to type-language', $ast_node);
    }
}

# When a type is referred to, we might need to convert
# that type-name to the schema and AST types, so here ...
sub ast_type_to_schema_type ($ast) {
    if ( $ast->isa('Graph::QL::AST::Node::NamedType') ) {
        require Graph::QL::Schema::Type::Named;
        return Graph::QL::Schema::Type::Named->new( ast => $ast );
    }
    elsif ( $ast->isa('Graph::QL::AST::Node::NonNullType') ) {
        require Graph::QL::Schema::Type::NonNull;
        return Graph::QL::Schema::Type::NonNull->new( ast => $ast );
    }
    elsif ( $ast->isa('Graph::QL::AST::Node::ListType') ) {
        require Graph::QL::Schema::Type::List;
        return Graph::QL::Schema::Type::List->new( ast => $ast );
    }
    else {
        throw('Do not recognize the ast type(%s), unable to convert to schema type', $ast);
    }
}

## ----------------------------------------------
## General utils for AST data structures
## ----------------------------------------------

use constant NULL_LOCATION => +{
    start => { line => 0, column => 0 },
    end   => { line => 0, column => 0 },
};

sub null_out_source_locations ( $ast, @paths ) {

    $ast->{loc}         = NULL_LOCATION if $ast->{loc};
    $ast->{name}->{loc} = NULL_LOCATION if $ast->{name};

    foreach my $path ( @paths ) {
        my ($start, @rest) = split /\./ => $path;

        #warn "PATH: $path";
        #warn "START: $start";
        #warn "REST: ". (join ', ' => @rest);

        #use Data::Dumper;
        #use Carp;
        #Carp::confess(Dumper [ $ast, \@paths ]) unless defined $start;

        if ( Ref::Util::is_arrayref( $ast->{ $start } ) ) {
            foreach my $sub_ast ( $ast->{ $start }->@* ) {
                null_out_source_locations( $sub_ast, @rest ? (join '.' => @rest) : () );
            }
        }
        else {
            null_out_source_locations( $ast->{ $start }, @rest ? (join '.' => @rest) : () );
        }
    }
}

1;

__END__

=pod

=cut



