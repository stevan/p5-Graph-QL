package Graph::QL::Schema::EnumValue;

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
    is_deprecated      => sub { 0 },
    deprecation_reason => sub {}
);

sub BUILDARGS : strict(
    name                => name,
    description?        => description,
    is_deprecated?      => is_deprecated,
    deprecation_reason? => deprecation_reason,
);

sub BUILD ($self, $params) {

    throw('The `name` must be a defined value')
        unless defined $self->{name};

    if ( exists $params->{description} ) {
        throw('The `description` must be a defined value')
            unless defined $self->{description};
    }

    if ( exists $params->{deprecation_reason} ) {
        throw('The `deprecation_reason` must be a defined value')
            unless defined $self->{deprecation_reason};
    }

    # coerce this into boolean ...
    $self->{is_deprecated} = !! $self->{is_deprecated} if exists $params->{is_deprecated};
}

sub name : ro;

sub description     : ro;
sub has_description : predicate;

sub is_deprecated          : ro;
sub deprecation_reason     : ro;
sub has_deprecation_reason : predicate;

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return $self->{name};
}

1;

__END__

=pod

=cut
