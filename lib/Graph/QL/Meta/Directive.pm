package Graph::QL::Meta::Directive;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use enumerable Location => qw[
    QUERY
    MUTATION
    SUBSCRIPTION
    FIELD
    FRAGMENT_DEFINITION
    FRAGMENT_SPREAD
    INLINE_FRAGMENT
    SCHEMA
    SCALAR
    OBJECT
    FIELD_DEFINITION
    ARGUMENT_DEFINITION
    INTERFACE
    UNION
    ENUM
    ENUM_VALUE
    INPUT_OBJECT
    INPUT_FIELD_DEFINITION
];

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name        => sub { die 'You must supply a `name`' },
    description => sub {},
    locations   => sub { +[] },
    args        => sub { +[] },
);

sub BUILDARGS : strict(
    name         => name,
    description? => description,
    locations?   => locations,
    args?        => args,
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` must be a defined value')
        unless defined $self->{name};

    if ( exists $params->{description} ) {
        Carp::confess('The `description` must be a defined value')
            unless defined $self->{description};
    }

    if ( $self->{locations}->@* ) {
        foreach ( $self->{locations}->@* ) {
            Carp::confess('The values in `locations` must be a value from the Graph::QL::Meta::Directive->Location enumeration, not '.$_)
                unless $self->Location->has_value_for( $_ );
        }
    }

    if ( $self->{args}->@* ) {
        foreach ( $self->{args}->@* ) {
            Carp::confess('The values in `args` value must be an instance of `Graph::QL::Meta::InputValue`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::Meta::InputValue');
        }
    }
}

sub name      : ro;
sub args      : ro;
sub locations : ro;

sub description     : ro;
sub has_description : predicate;


1;

__END__

=pod

=cut
