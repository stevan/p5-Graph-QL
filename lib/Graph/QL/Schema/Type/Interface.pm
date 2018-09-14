package Graph::QL::Schema::Type::Interface;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type::Scalar';
use slots (
    kind           => sub { Graph::QL::Schema::Type->Kind->INTERFACE },
    fields         => sub { +[] },
    possible_types => sub { +[] },
    # internal ...
    _field_map     => sub { +{} },
);

sub BUILDARGS : strict(
    fields?         => fields,
    possible_types? => possible_types,
    name            => super(name),
    description?    => super(description),
);

sub BUILD ($self, $params) {

    throw('The `fields` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{fields} );

    #throw('The `fields` value must be one or more types')
    #    unless scalar $self->{fields}->@* >= 1;

    my %field_map;
    foreach ( $self->{fields}->@* ) {
        # make sure it is the right kind of object ...
        throw('The values in `fields` value must be an instance of `Graph::QL::Schema::Field`, not '.$_)
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::Schema::Field');

        # make sure our names are unique ...
        throw('The values in `fields` value must have unique names, found duplicate '.$_->name)
            if exists $field_map{ $_->name };

        # note that we've seen it ...
        $field_map{ $_->name } = $_;
    }

    # store the mapping ...
    $self->{_field_map} = \%field_map;

    # check the possible types that implement this interface ...
    if ( $self->{possible_types}->@* ) {
        foreach ( $self->{possible_types}->@* ) {
            throw('The values in `possible_types` value must be an instance of `Graph::QL::Schema::Type::Object`, not '.$_)
                unless Ref::Util::is_blessed_ref( $_ )
                    && $_->isa('Graph::QL::Schema::Type::Object');
        }
    }
}

sub possible_types : ro;

sub fields ($self, $include_deprecated=0) {
    return $self->{fields} if $include_deprecated;
    return [ grep $_->is_deprecated, $self->{fields}->@* ];
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return 'interface '.$self->{name}.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->{fields}->@*)."\n".
    '}';
}


1;

__END__

=pod

=cut
