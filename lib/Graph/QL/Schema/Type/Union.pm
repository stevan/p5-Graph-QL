package Graph::QL::Schema::Type::Union;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type::Scalar';
use slots (
    kind           => sub { Graph::QL::Schema::Type->Kind->UNION },
    possible_types => sub { die 'You must specify the `possible_types`' },
);

sub BUILDARGS : strict(
    possible_types => possible_types,
    name           => super(name),
    description?   => super(description),
);

sub BUILD ($self, $params) {

    throw('The `possible_types` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{possible_types} );

    throw('The `possible_types` value must be one or more types')
        unless scalar $self->{possible_types}->@* >= 1;

    foreach ( $self->{possible_types}->@* ) {
        throw('The values in `possible_types` value must be an instance of `Graph::QL::Schema::Type::Object`, not '.$_)
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::Schema::Type::Object');
    }
}

sub possible_types : ro;

# input/output type methods
sub is_input_type  { 0 }
sub is_output_type { 1 }

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return sprintf 'union %s = %s' => $self->{name}, (join ' | ' => map $_->name, $self->{possible_types}->@*);
}

1;

__END__

=pod

=cut
