package Graph::QL::Meta::Type::InputObject;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'Graph::QL::Meta::Type::Scalar';
use slots (
    kind         => sub { Graph::QL::Meta::Type->Kind->INPUT_OBJECT },
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

    Carp::confess('The `input_fields` value must be an ARRAY ref')
        unless defined $self->{input_fields}
            && ref $self->{input_fields} eq 'ARRAY';

    Carp::confess('The `input_fields` value must be one or more types')
        unless scalar $self->{input_fields}->@* >= 1;

    my %map;
    foreach ( $self->{input_fields}->@* ) {
        # make sure it is the right kind of object ...
        Carp::confess('The values in `input_fields` value must be an instance of `Graph::QL::Meta::InputValue`, not '.$_)
            unless Scalar::Util::blessed( $_ )
                && $_->isa('Graph::QL::Meta::InputValue');

        # make sure our names are unique ...
        Carp::confess('The values in `input_fields` value must have unique names, found duplicate '.$_->name)
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

1;

__END__

=pod

=cut
