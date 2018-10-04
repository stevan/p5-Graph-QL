package Graph::QL::Schema::Union;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

use Graph::QL::Schema::Type::Named;

use Graph::QL::AST::Node::UnionTypeDefinition;
use Graph::QL::AST::Node::NamedType;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast   => sub {},
    _name  => sub {},
    _types => sub {},
);

sub BUILDARGS : strict(
    ast?   => _ast,
    name?  => _name,
    types? => _types,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {

        throw('The `ast` must be an instance of `Graph::QL::AST::Node::UnionTypeDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::UnionTypeDefinition' );

        # inflate the objects if we only got an AST ...
        $self->{_types} = [ map Graph::QL::Schema::Type::Named->new( ast => $_ ), $self->{_ast}->types->@* ];
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        throw('The `types` value must be an ARRAY ref')
            unless assert_arrayref( $self->{_types} );

        foreach ( $self->{_types}->@* ) {
            throw('The values in `types` must all be of type(Graph::QL::Schema::Type::Named), not `%s`', $_ )
                unless assert_isa( $_, 'Graph::QL::Schema::Type::Named');
        }

        $self->{_ast} = Graph::QL::AST::Node::UnionTypeDefinition->new(
            name  => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            types => [ map $_->ast, $self->{_types}->@* ]
        );
    }
}

sub ast       : ro(_);
sub name      : ro(_);
sub all_types : ro(_types);

## ...

sub to_type_language ($self) {
    return sprintf 'union %s = %s' => $self->name, (join ' | ' => map $_->name, $self->all_types->@*);
}

1;

__END__

=pod

=cut
