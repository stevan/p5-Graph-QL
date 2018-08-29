package Graph::QL::Field;

use v5.24;
use warnings;
use experimental 'signatures';
use decorators ':accessors';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    type     => sub { die 'You must supply a `type`' },
    resolver => sub {},
    # ...
    _is_array        => sub {},
    _is_non_nullable => sub { 1 },
);

sub BUILDARGS ($class, @args) {
    my $args = $class->SUPER::BUILDARGS( @args );

    # We are going to ignore the []! or [] on array types, for now ...
    if ( $args->{type} =~ /^\[(.*)\]\!?$/ ) {
        $args->{type}      = $1;
        $args->{_is_array} = 1;
    }

    if ( $args->{type} =~ /(.*)\!$/ ) {
        $args->{type}             = $1;
        $args->{_is_non_nullable} = 1;
    }

    return $args;
}

sub has_resolver : predicate;
sub resolver     : ro;

sub type            : ro;
sub is_array        : ro(_);
sub is_non_nullable : ro(_);

1;

__END__

=pod

=cut
