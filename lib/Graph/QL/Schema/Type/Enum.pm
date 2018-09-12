package Graph::QL::Schema::Type::Enum;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type::Scalar';
use slots (
    kind        => sub { Graph::QL::Schema::Type->Kind->ENUM },
    enum_values => sub { die 'You must supply `enum_values`' },
    # internal ...
    _enum_map   => sub { +{} }
);

sub BUILDARGS : strict(
    enum_values  => enum_values,
    name         => super(name),
    description? => super(description),
);

sub BUILD ($self, $params) {

    Carp::confess('The `enum_values` value must be an ARRAY ref')
        unless defined $self->{enum_values}
            && ref $self->{enum_values} eq 'ARRAY';

    Carp::confess('The `enum_values` value must be one or more types')
        unless scalar $self->{enum_values}->@* >= 1;

    my %map;
    foreach ( $self->{enum_values}->@* ) {
        # make sure it is the right kind of object ...
        Carp::confess('The values in `enum_values` value must be an instance of `Graph::QL::Schema::EnumValue`, not '.$_)
            unless Scalar::Util::blessed( $_ )
                && $_->isa('Graph::QL::Schema::EnumValue');

        # make sure our names are unique ...
        Carp::confess('The values in `enum_values` value must have unique names, found duplicate '.$_->name)
            if exists $map{ $_->name };

        # note that we've seen it ...
        $map{ $_->name } = $_;
    }

    # store the map ...
    $self->{_enum_map} = \%map;
}

sub enum_values ($self, $include_deprecated=0) {
    return $self->{enum_values} if $include_deprecated;
    return [ grep $_->is_deprecated, $self->{enum_values}->@* ];
}


# input/output type methods
sub is_input_type  { 1 }
sub is_output_type { 1 }

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return 'enum '.$self->{name}.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->{enum_values}->@*)."\n".
    '}';
}

1;

__END__

=pod

=cut
