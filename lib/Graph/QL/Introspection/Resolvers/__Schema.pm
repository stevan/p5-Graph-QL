package Graph::QL::Introspection::Resolvers::__Schema;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

sub types ($schema, $, $, $) { $schema->all_types }

sub queryType        ($schema, $, $, $) { return }
sub mutationType     ($schema, $, $, $) { return }
sub subscriptionType ($schema, $, $, $) { return }

1;

__END__

=pod

type __Schema {
    types            : [__Type!]!
    queryType        : __Type!
    mutationType     : __Type!
    subscriptionType : __Type!
}

=cut
