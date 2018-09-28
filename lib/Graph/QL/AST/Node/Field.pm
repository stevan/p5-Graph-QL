package Graph::QL::AST::Node::Field;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Selection';
use slots (
    alias         => sub {},
    name          => sub { die 'You must supply a `name`'},
    arguments     => sub { +[] },
    directives    => sub { +[] },
    selection_set => sub {},
);

sub BUILDARGS : strict(
    alias?          => alias,
    name            => name,
    arguments?      => arguments,
    directives?     => directives,
    selection_set?  => selection_set,
    location?       => super(location),
);

sub BUILD ($self, $params) {

    if ( exists $params->{alias} ) {
        throw('The `alias` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{alias})
            unless assert_isa( $self->{alias}, 'Graph::QL::AST::Node::Name');
    }
    
    throw('The `name` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{name})
        unless assert_isa( $self->{name}, 'Graph::QL::AST::Node::Name');
    
    throw('The `arguments` value must be an ARRAY ref')
        unless assert_arrayref( $self->{arguments} );
    
    foreach ( $self->{arguments}->@* ) {
        throw('The values in `arguments` must all be of type(Graph::QL::AST::Node::Argument), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::Argument');
    }
    
    throw('The `directives` value must be an ARRAY ref')
        unless assert_arrayref( $self->{directives} );
    
    foreach ( $self->{directives}->@* ) {
        throw('The values in `directives` must all be of type(Graph::QL::AST::Node::Directive), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::Directive');
    }
    
    if ( exists $params->{selection_set} ) {
        throw('The `selection_set` must be of type(Graph::QL::AST::Node::SelectionSet), not `%s`', $self->{selection_set})
            unless assert_isa( $self->{selection_set}, 'Graph::QL::AST::Node::SelectionSet');
    }
    
}

sub alias         : ro;
sub name          : ro;
sub arguments     : ro;
sub directives    : ro;
sub selection_set : ro;

1;

__END__

=pod

=cut
