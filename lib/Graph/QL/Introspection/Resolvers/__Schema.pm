package Graph::QL::Introspection::Resolvers::__Schema;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

sub types ($schema, $, $, $) { $schema->all_types }

1;

__END__

=pod

=cut
