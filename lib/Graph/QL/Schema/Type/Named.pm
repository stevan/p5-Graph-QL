package Graph::QL::Schema::Type::Named;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors 'throw';

use Graph::QL::AST::Node::NamedType;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Schema::Type';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?  => _ast,
    name? => name,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        throw('You must pass a defined value to `name`')
            unless defined $params->{name};

        $self->{_ast} = Graph::QL::AST::Node::NamedType->new(
            name => Graph::QL::AST::Node::Name->new(
                value => $params->{name}
            )
        );
    }
}

sub ast : ro(_);
sub name ($self) { $self->ast->name->value }

1;

__END__

=pod

=cut
