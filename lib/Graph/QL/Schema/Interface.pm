package Graph::QL::Schema::Interface;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Schema::Field;

use Graph::QL::AST::Node::InterfaceTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?    => _ast,
    name?   => name,
    fields? => fields,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {
        # TODO:
        # - check `fields`

        $self->{_ast} = Graph::QL::AST::Node::InterfaceTypeDefinition->new(
            name   => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            fields => [ map $_->ast, $params->{fields}->@* ]
        );
    }

}

sub ast : ro(_);

sub name   ($self) { $self->ast->name->value }
sub fields ($self) {
    [ map Graph::QL::Schema::Field->new( ast => $_ ), $self->ast->fields->@* ]
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return 'interface '.$self->name.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->fields->@*)."\n".
    '}';
}


1;

__END__

=pod

=cut
