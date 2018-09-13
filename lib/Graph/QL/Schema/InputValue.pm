package Graph::QL::Schema::InputValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `name` must be a defined value')
        unless defined $self->{name};

    throw('The `name` must not start with `__`')
        if $self->{name} =~ /^__/;

    if ( exists $params->{description} ) {
        throw('The `description` must be a defined value')
            unless defined $self->{description};
    }

    throw('The `type` must be an instance of `Graph::QL::Schema::Type` and an input-type, not '.$self->{type})
        unless Ref::Util::is_blessed_ref( $self->{type} )
            && $self->{type}->isa('Graph::QL::Schema::Type')
            && $self->{type}->is_input_type;

    if ( exists $params->{default_value} ) {
        throw('The `default_value` must be a defined value')
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
    return $self->{name}.' : '.$self->{type}->name.($self->{default_value} ? ' = '.$self->{default_value} : '');
}

1;

__END__

=pod

=cut
