package Graph::QL::Meta::InputValue;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name          => sub { die 'You must supply a `name`' },
    description   => sub {},
    type          => sub { die 'You must supply a `type`' },
    default_value => sub {},
);

sub BUILDARGS : strict(
    name           => name,
    description?   => description,
    type           => type,
    default_value? => default_value,
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` must be a defined value')
        unless defined $self->{name};

    Carp::confess('The `name` must not start with `__`')
        if $self->{name} =~ /^__/;

    if ( exists $params->{description} ) {
        Carp::confess('The `description` must be a defined value')
            unless defined $self->{description};
    }

    Carp::confess('The `type` must be an instance of `Graph::QL::Meta::Type` and an input-type, not '.$self->{type})
        unless Scalar::Util::blessed( $self->{type} )
            && $self->{type}->isa('Graph::QL::Meta::Type')
            && $self->{type}->is_input_type;

    if ( exists $params->{default_value} ) {
        Carp::confess('The `default_value` must be a defined value')
            unless defined $self->{default_value};
    }
}

sub name : ro;
sub type : ro;

sub description     : ro;
sub has_description : predicate;

sub default_value     : ro;
sub has_default_value : predicate;

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    # handle the `default_value`
    return $self->{name}.' : '.$self->{type}->name;
}

1;

__END__

=pod

=cut
