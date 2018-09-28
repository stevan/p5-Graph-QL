package Graph::QL::Schema::Enum;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

use Graph::QL::Schema::Enum::EnumValue;

use Graph::QL::AST::Node::EnumTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?    => _ast,
    name?   => name,
    values? => values,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        throw('You must pass a defined value to `name`')
            unless defined $params->{name};

        throw('The `values` value must be an ARRAY ref')
            unless assert_arrayref( $params->{values} );

        foreach ( $params->{values}->@* ) {
            throw('The values in `values` must all be of type(Graph::QL::Schema::Enum::EnumValue), not `%s`', $_ )
                unless assert_isa( $_, 'Graph::QL::Schema::Enum::EnumValue');
        }

        $self->{_ast} = Graph::QL::AST::Node::EnumTypeDefinition->new(
            name   => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            values => [ map $_->ast, $params->{values}->@* ]
        );
    }
}

sub ast : ro(_);

sub name   ($self) { $self->ast->name->value }
sub values ($self) {
    [ map Graph::QL::Schema::Enum::EnumValue->new( ast => $_ ), $self->ast->values->@* ]
}

## ...

sub to_type_language ($self) {
    return 'enum '.$self->name.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->values->@*)."\n".
    '}';
}

1;

__END__

=pod

=cut
