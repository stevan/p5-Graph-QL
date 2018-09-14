package Graph::QL::Schema::Type::Enum;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

use Graph::QL::Schema::Type;

use Graph::QL::AST::Node::EnumTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

#use parent 'Graph::QL::Schema::Type::Scalar';
use parent 'UNIVERSAL::Object::Immutable';
use slots (
    kind => sub { Graph::QL::Schema::Type->Kind->ENUM },
    _ast => sub {},
);

sub BUILDARGS : strict(
    ast?    => _ast,
    name?   => name,
    values? => values,
);

sub BUILD ($self, $params) {
    $self->{_ast} //= Graph::QL::AST::Node::EnumTypeDefinition->new(
        name => Graph::QL::AST::Node::Name->new(
            value => $params->{name}
        ),
        values => [ map $_->ast, $params->{values}->@* ]
    )
}

sub ast : ro(_);

sub name   ($self) { $self->ast->name->value }
sub values ($self) {
    [ map Graph::QL::Schema::EnumValue->new( ast => $_ ), $self->ast->values->@* ]
}

# input/output type methods
sub is_input_type  { 1 }
sub is_output_type { 1 }

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
