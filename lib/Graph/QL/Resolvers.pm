package Graph::QL::Resolvers;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

use Graph::QL::Resolvers::TypeResolver;
use Graph::QL::Resolvers::FieldResolver;

use constant DEBUG => $ENV{GRAPHQL_RESOLVERS_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( types => sub {} );

sub new_from_namespace ($class, $root_namespace) {

	$root_namespace = $root_namespace.'::' unless $root_namespace =~ /\:\:$/;

    DEBUG and $class->_debug_log('ROOT NAMESPACE - %s' => $root_namespace);

	my @namespaces;
	{
		no strict 'refs';
		@namespaces = map s/\:\:$//r => grep /\:\:$/ => keys %{ $root_namespace };
	}

    throw('Cannot find any types within the namespace (%s), perhaps you forgot to load them', $root_namespace)
        unless @namespaces;

    DEBUG and $class->_debug_log('NAMESPACES - [ %s ]', join ', ' => @namespaces);

	my @types;
	foreach my $namespace ( @namespaces ) {
		my $r = MOP::Role->new( "${root_namespace}${namespace}" );

		my @fields = map Graph::QL::Resolvers::FieldResolver->new(
			name => $_->name,
			code => $_->body,
		) => $r->methods;

		push @types => Graph::QL::Resolvers::TypeResolver->new(
			name   => $namespace,
			fields => \@fields
		);
	}

	return $class->new( types => \@types );
}

## ...

sub BUILDARGS : strict( types => types );

sub BUILD ($self, $) {

    throw('The `types` value must be an ARRAY ref')
        unless assert_arrayref( $self->{types} );

    foreach ( $self->{types}->@* ) {
        throw('The types in `types` must all be of type(Graph::QL::Resolvers::TypeResolver), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::Resolvers::TypeResolver');
    }
}

## ...

sub all_types : ro(types);

sub get_type ($self, $name) {
    (grep $_->name eq $name, $self->{types}->@*)[0] // undef
}

## ...

sub _debug_log ($self, $depth, $msg, @args) {
    my $indent = '    ' x $depth;
    $msg = sprintf $msg => @args if @args;
    warn "${indent}${msg}\n";
}

1;

__END__

=pod

=cut
