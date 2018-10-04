package Graph::QL::Util::Schemas;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef', 'current_sub';

use Graph::QL::Schema::Type::Named;
use Graph::QL::Schema::Type::NonNull;
use Graph::QL::Schema::Type::List;

our $VERSION = '0.01';

sub construct_type_from_name ($type_name) {
    state $_type_cache = {};

    return $_type_cache->{ $type_name } if exists $_type_cache->{ $type_name };

    my $type;
    if ( $type_name =~ m/^(.*)\!$/ ) {
        $type = Graph::QL::Schema::Type::NonNull->new( of_type => __SUB__->( "$1" ) );
    }
    elsif ( $type_name =~ m/^\[(.*)\]$/ ) {
        $type = Graph::QL::Schema::Type::List->new( of_type => __SUB__->( "$1" ) );
    }
    else {
        $type = Graph::QL::Schema::Type::Named->new( name => $type_name );
    }

    return $_type_cache->{ $type_name } = $type;
}

1;

__END__

=pod

=cut

