package Graph::QL::Schema::Field;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `name` must be a defined value')
        unless defined $self->{name};

    throw('The `name` must not start with `__`')
        if $self->{name} =~ /^__/;

    if ( exists $params->{description} ) {
        throw('The `description` must be a defined value')
            unless defined $self->{description};
    }

    throw('The `type` must be an instance of `Graph::QL::Schema::Type` and must be an output-type, not '.$self->{type})
        unless Ref::Util::is_blessed_ref( $self->{type} )
            && $self->{type}->isa('Graph::QL::Schema::Type')
            && $self->{type}->is_output_type;

    if ( exists $params->{args} ) {
        throw('The `args` value must be an ARRAY ref')
            unless Ref::Util::is_arrayref( $self->{args} );

        throw('The `args` value must be one or more args')
            unless scalar $self->{args}->@* >= 1;

        foreach ( $self->{args}->@* ) {
            throw('The values in `args` value must be an instance of `Graph::QL::Schema::InputValue`, not '.$_)
                unless Ref::Util::is_blessed_ref( $_ )
                    && $_->isa('Graph::QL::Schema::InputValue');
        }
    }

    if ( exists $params->{deprecation_reason} ) {
        throw('The `deprecation_reason` must be a defined value')
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
