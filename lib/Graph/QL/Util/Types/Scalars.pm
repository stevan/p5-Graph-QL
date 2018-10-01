package Graph::QL::Util::Types::Scalars;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::AST::Node::ScalarTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

## scalar types

our %SCALAR_TYPES; BEGIN {
    %SCALAR_TYPES = (
        BOOLEAN => 'Boolean',
        FLOAT   => 'Float',
        INT     => 'Int',
        STRING  => 'String',
        NULL    => 'Null',
    );

    use constant ();
    foreach my $type ( keys %SCALAR_TYPES ) {
        constant->import( $type, $SCALAR_TYPES{ $type } )
    }
}

sub schema_type_definitions {
    state $schema_type_defs = [
        map Graph::QL::AST::Node::ScalarTypeDefinition->new(
            name => Graph::QL::AST::Node::Name->new(
                value => $_
            )
        ), sort values %SCALAR_TYPES
    ];
    return $schema_type_defs->@*;
}

1;

__END__

=pod

=cut

