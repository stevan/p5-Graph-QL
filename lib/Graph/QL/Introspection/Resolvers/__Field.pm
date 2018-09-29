package Graph::QL::Introspection::Resolvers::__Field;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

sub name ($field, $, $, $) { $field->name }
sub type ($field, $, $, $) { $field->type }

1;

__END__

=pod

=cut
