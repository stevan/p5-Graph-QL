package Graph::QL::Schema::InputObject;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

use Graph::QL::AST::Node::InputObjectTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast    => sub {},
    _name   => sub {},
    _fields => sub {},
);

sub BUILDARGS : strict(
    ast?    => _ast,
    name?   => _name,
    fields? => _fields,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::InputObjectTypeDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::InputObjectTypeDefinition' );

        $self->{_name}   = $self->{_ast}->name->value;
        $self->{_fields} = [ map Graph::QL::Schema::InputObject::InputValue->new( ast => $_ ), $self->{_ast}->fields->@* ];
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        throw('The `fields` value must be an ARRAY ref')
            unless assert_arrayref( $self->{_fields} );

        foreach ( $self->{_fields}->@* ) {
            throw('The values in `fields` must all be of type(Graph::QL::Schema::InputObject::InputValue), not `%s`', $_ )
                unless assert_isa( $_, 'Graph::QL::Schema::InputObject::InputValue');
        }

        $self->{_ast} = Graph::QL::AST::Node::InputObjectTypeDefinition->new(
            name   => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            fields => [ map $_->ast, $self->{_fields}->@* ]
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);

sub all_fields : ro(_fields);

## ...

sub to_type_language ($self) {
    return 'input '.$self->name.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->all_fields->@*)."\n".
    '}';
}


1;

__END__

=pod

=cut
