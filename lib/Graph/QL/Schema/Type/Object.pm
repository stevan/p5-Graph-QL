package Graph::QL::Schema::Type::Object;
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
    kind        => sub { Graph::QL::Schema::Type->Kind->OBJECT },
    fields      => sub { +[] },
    interfaces  => sub { +[] },
    # internal ...
    _field_map  => sub { +{} },
);

sub BUILDARGS : strict(
    fields?      => fields,
    interfaces?  => interfaces,
    name         => super(name),
    description? => super(description),
);

sub BUILD ($self, $params) {

    throw('The `fields` value must be an ARRAY ref')
        unless defined $self->{fields}
            && Ref::Util::is_arrayref( $self->{fields} );

    #throw('The `fields` value must be one or more fields')
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

    # if this was passed to us ...
    if ( exists $params->{interfaces} ) {

        # look through each one ...
        foreach ( $self->{interfaces}->@* ) {

            throw('The values in `interfaces` value must be an instance of `Graph::QL::Schema::Type::Interface`, not '.$_)
                unless Ref::Util::is_blessed_ref( $_ )
                    && $_->isa('Graph::QL::Schema::Type::Interface');

            # TODO:
            # An object type must be a super‐set of all interfaces it implements:
            #     The object type must include a field of the same name for every field defined in an interface.
            #         The object field must be of a type which is equal to or a sub‐type of the interface field (covariant).
            #             An object field type is a valid sub‐type if it is equal to (the same type as) the interface field type.
            #             An object field type is a valid sub‐type if it is an Object type and the interface field type is either an Interface type or a Union type and the object field type is a possible type of the interface field type.
            #             An object field type is a valid sub‐type if it is a List type and the interface field type is also a List type and the list‐item type of the object field type is a valid sub‐type of the list‐item type of the interface field type.
            #             An object field type is a valid sub‐type if it is a Non‐Null variant of a valid sub‐type of the interface field type.
            #     The object field must include an argument of the same name for every argument defined in the interface field.
            #         The object field argument must accept the same type (invariant) as the interface field argument.
            #     The object field may include additional arguments not defined in the interface field, but any additional argument must not be required, e.g. must not be of a non‐nullable type.
        }
    }
}

sub interfaces : ro;

sub fields ($self, $include_deprecated=0) {
    return $self->{fields} if $include_deprecated;
    return [ grep $_->is_deprecated, $self->{fields}->@* ];
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    my $interfaces = '';
    if ( $self->{interfaces}->@* ) {
        $interfaces = ' implements '.(join ' & ' => map $_->name, $self->{interfaces}->@*);
    }
    return 'type '.$self->{name}.$interfaces.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->{fields}->@*)."\n".
    '}';
}

1;

__END__

=pod

=cut
