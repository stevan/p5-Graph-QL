package Graph::QL::Meta::Field;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name               => sub { die 'You must supply a `name`' },
    description        => sub {},
    args               => sub {},
    type               => sub { die 'You must supply a `type`' },
    is_deprecated      => sub { 0 },
    deprecation_reason => sub {}
);

sub BUILDARGS : strict(
    name                => name,
    description?        => description,
    args?               => args,
    type                => type,
    is_deprecated?      => is_deprecated,
    deprecation_reason? => deprecation_reason,
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

    Carp::confess('The `type` must be an instance of `Graph::QL::Meta::Type` and must be an output-type, not '.$self->{type})
        unless Scalar::Util::blessed( $self->{type} )
            && $self->{type}->isa('Graph::QL::Meta::Type')
            && $self->{type}->is_output_type;

    if ( exists $params->{args} ) {
        Carp::confess('The `args` value must be an ARRAY ref')
            unless defined $self->{args}
                && ref $self->{args} eq 'ARRAY';

        Carp::confess('The `args` value must be one or more args')
            unless scalar $self->{args}->@* >= 1;

        foreach ( $self->{args}->@* ) {
            Carp::confess('The values in `args` value must be an instance of `Graph::QL::Meta::InputValue`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::Meta::InputValue');
        }
    }

    if ( exists $params->{deprecation_reason} ) {
        Carp::confess('The `deprecation_reason` must be a defined value')
            unless defined $self->{deprecation_reason};
    }

    # coerce this into boolean ...
    $self->{is_deprecated} = !! $self->{is_deprecated} if exists $params->{is_deprecated};
}

sub name : ro;
sub type : ro;

sub args     : ro;
sub has_args : predicate;

sub description     : ro;
sub has_description : predicate;

sub is_deprecated          : ro;
sub deprecation_reason     : ro;
sub has_deprecation_reason : predicate;

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    # handle the `args` form
    if ( $self->has_args ) {
        return $self->{name}.'('.(join ', ' => map $_->to_type_language, $self->{args}->@*).') : '.$self->{type}->name;
    }
    else {
        return $self->{name}.' : '.$self->{type}->name;
    }
}

1;

__END__

=pod

=cut
