package Graph::QL::Util::Types;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

sub ast_type_to_schema_type ($ast) {
    if ( $ast->isa('Graph::QL::AST::Node::NamedType') ) {
        require Graph::QL::Schema::Type::Named;
        return Graph::QL::Schema::Type::Named->new( ast => $ast );
    }
    elsif ( $ast->isa('Graph::QL::AST::Node::NonNullType') ) {
        require Graph::QL::Schema::Type::NonNull;
        return Graph::QL::Schema::Type::NonNull->new( ast => $ast );
    }
    elsif ( $ast->isa('Graph::QL::AST::Node::ListType') ) {
        require Graph::QL::Schema::Type::List;
        return Graph::QL::Schema::Type::List->new( ast => $ast );
    }
    else {
        throw('Do not recognize the ast type(%s), unable to convert to schema type', $ast);
    }
}


1;

__END__

=pod

=cut

