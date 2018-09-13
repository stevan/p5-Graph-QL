package Graph::QL::Schema::Directive;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `name` must be a defined value')
        unless defined $self->{name};

    if ( exists $params->{description} ) {
        throw('The `description` must be a defined value')
            unless defined $self->{description};
    }

    if ( $self->{locations}->@* ) {
        foreach ( $self->{locations}->@* ) {
            throw('The values in `locations` must be a value from the Graph::QL::Schema::Directive->Location enumeration, not '.$_)
                unless $self->Location->has_value_for( $_ );
        }
    }

    if ( $self->{args}->@* ) {
        foreach ( $self->{args}->@* ) {
            throw('The values in `args` value must be an instance of `Graph::QL::Schema::InputValue`, not '.$_)
                unless Ref::Util::is_blessed_ref( $_ )
                    && $_->isa('Graph::QL::Schema::InputValue');
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
