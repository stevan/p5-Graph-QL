package Graph::QL::Schema::Type::InputObject;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type::Scalar';
use slots (
    kind         => sub { Graph::QL::Schema::Type->Kind->INPUT_OBJECT },
    input_fields => sub { +[] },
    # internal ...
    _field_map   => sub { +{} },
);

sub BUILDARGS : strict(
    input_fields => input_fields,
    name         => super(name),
    description? => super(description),
);

sub BUILD ($self, $params) {

    throw('The `input_fields` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{input_fields} );

    throw('The `input_fields` value must be one or more types')
        unless scalar $self->{input_fields}->@* >= 1;

    my %map;
    foreach ( $self->{input_fields}->@* ) {
        # make sure it is the right kind of object ...
        throw('The values in `input_fields` value must be an instance of `Graph::QL::Schema::InputValue`, not '.$_)
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::Schema::InputValue');

        # make sure our names are unique ...
        throw('The values in `input_fields` value must have unique names, found duplicate '.$_->name)
            if exists $map{ $_->name };

        # note that we've seen it ...
        $map{ $_->name } = $_;
    }

    # store the map ...
    $self->{_field_map} = \%map;

}

sub input_fields : ro;

# input/output type methods
sub is_input_type  { 1 }
sub is_output_type { 0 }

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return 'input '.$self->{name}.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->{input_fields}->@*)."\n".
    '}';
}


1;

__END__

=pod

=cut
