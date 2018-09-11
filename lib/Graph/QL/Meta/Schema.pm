package Graph::QL::Meta::Schema;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    types             => sub { +[] },
    query_type        => sub { die 'You must supply a `query_type`' },
    mutation_type     => sub {},
    subscription_type => sub {},
    directives        => sub { +[] },
);

sub BUILDARGS : strict(
    types?             => types,
    query_type         => query_type,
    mutation_type?     => mutation_type,
    subscription_type? => subscription_type,
    directives?        => directives,
);

sub BUILD ($self, $params) {

    Carp::confess('The `query_type` value must be an instance of `Graph::QL::Meta::Type::Object`, not '.$self->{query_type})
        unless Scalar::Util::blessed( $self->{query_type} )
            && $self->{query_type}->isa('Graph::QL::Meta::Type::Object');

    if ( exists $params->{mutation_type} ) {
        Carp::confess('The `mutation_type` value must be an instance of `Graph::QL::Meta::Type::Object`, not '.$self->{mutation_type})
            unless Scalar::Util::blessed( $self->{mutation_type} )
                && $self->{mutation_type}->isa('Graph::QL::Meta::Type::Object');
    }

    if ( exists $params->{subscription_type} ) {
        Carp::confess('The `subscription_type` value must be an instance of `Graph::QL::Meta::Type::Object`, not '.$self->{subscription_type})
            unless Scalar::Util::blessed( $self->{subscription_type} )
                && $self->{subscription_type}->isa('Graph::QL::Meta::Type::Object');
    }

    if ( $self->{types}->@* ) {
        foreach ( $self->{types}->@* ) {
            Carp::confess('The values in `types` value must be an instance of `Graph::QL::Meta::Type`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::Meta::Type');
        }
    }

    if ( $self->{directives}->@* ) {
        foreach ( $self->{directives}->@* ) {
            Carp::confess('The values in `directives` value must be an instance of `Graph::QL::Meta::Directive`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::Meta::Directive');
        }
    }

}

sub types : ro;

sub query_type : ro;

sub mutation_type     : ro;
sub has_mutation_type : predicate;

sub subscription_type     : ro;
sub has_subscription_type : predicate;

sub directives : ro;

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `directives`
    return "\n".# print the types first ...
        (join "\n\n" => map $_->to_type_language, $self->{types}->@*)
        ."\n\n". # followed by the base `schema` object
        'schema {'."\n    ".
            'query : '.$self->query_type->name."\n".
            ($self->has_mutation_type     ? (    '    mutation : '.$self->mutation_type->name."\n")     : '').
            ($self->has_subscription_type ? ('    subscription : '.$self->subscription_type->name."\n") : '').
        '}'."\n";
}

1;

__END__

=pod

=cut
