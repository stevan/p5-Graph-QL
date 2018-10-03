package Graph::QL::Util::Types::SchemaType;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef', 'current_sub';

use Graph::QL::Schema::Type::Named;
use Graph::QL::Schema::Type::NonNull;
use Graph::QL::Schema::Type::List;

our $VERSION = '0.01';

sub construct_type_from_name ($, $type_name) {
    if ( $type_name =~ m/^(.*)\!$/ ) {
        return Graph::QL::Schema::Type::NonNull->new( of_type => __SUB__->( undef, "$1" ) );
    }
    elsif ( $type_name =~ m/^\[(.*)\]$/ ) {
        return Graph::QL::Schema::Type::List->new( of_type => __SUB__->( undef, "$1" ) );
    }
    else {
        return Graph::QL::Schema::Type::Named->new( name => $type_name );
    }
}

1;

__END__

=pod

=cut

