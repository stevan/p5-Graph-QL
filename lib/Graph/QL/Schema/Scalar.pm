package Graph::QL::Schema::Scalar;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa';

use Graph::QL::AST::Node::ScalarTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast  => sub {},
    _name => sub {},
);

sub BUILDARGS : strict(
    ast?  => _ast,
    name? => _name,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {

        throw('The `ast` must be an instance of `Graph::QL::AST::Node::ScalarTypeDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::ScalarTypeDefinition' );

        $self->{_name} = $self->{_ast}->name->value;
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        $self->{_ast} = Graph::QL::AST::Node::ScalarTypeDefinition->new(
            name => Graph::QL::AST::Node::Name->new( value => $self->{_name} )
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);

# ...

sub to_type_language ($self) {
    return sprintf 'scalar %s' => $self->name;
}

1;

__END__

=pod

=cut
