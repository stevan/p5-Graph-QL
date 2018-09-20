package Graph::QL::Execution::FieldResolver;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

# class or role?
# use parent 'UNIVERSAL::Object::Immutable';
use slots (
    # internals ...
);

# What to do ...

# source  => any source data, either it is root_value (from Context) or a decendant
# args    => arguments in case the field takes them
# context => the context (from Context), usually a hash-ref with callbacks
# info    => information about the field (name, parent_type, schema, etc.)

# Are these arguments to `resolve`
# or are they slots?

sub resolve;


1;

__END__

=pod

=head1 DESCRIPTION

=cut
