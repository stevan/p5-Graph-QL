package Graph::QL::Introspection::Resolvers::__InputValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

sub name         ($value, $, $, $) { $value->name }
sub description  ($value, $, $, $) { return } # TODO
sub type         ($value, $, $, $) { $value->type }
sub defaultValue ($value, $, $, $) {
    return unless $value->has_default_value;
    return $value->default_value;
}

1;

__END__

=pod

type __InputValue {
    name         : String!
    description  : String
    type         : __Type!
    defaultValue : String
}

=cut
