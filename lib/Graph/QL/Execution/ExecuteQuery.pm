package Graph::QL::Execution::ExecuteQuery;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

use Graph::QL::Execution::QueryValidator;

use constant DEBUG => $ENV{GRAPHQL_EXECUTOR_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema    => sub {}, # Graph::QL::Schema
    query     => sub {}, # Graph::QL::Operation::Query
    resolvers => sub {}, # a mapping of TypeName to Resolver instance
    validator => sub {}, # Graph::QL::Execution::QueryValidator
);

sub BUILDARGS : strict(
    schema     => schema,
    query      => query,
    resolvers  => resolvers,
    validator? => validator,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

    throw('The `query` must be of an instance that does the `Graph::QL::Operation` role, not `%s`', $self->{query})
        unless assert_isa( $self->{query}, 'Graph::QL::Operation::Query' );

    # TODO:
    # - handle `initial-value`
    # - handle `variables`
    # - handle `context-value`

    throw('The `resolvers` must be a as instance of `Graph::QL::Resolvers`, not `%s`', $self->{resolvers})
        unless assert_isa( $self->{resolvers}, 'Graph::QL::Resolvers' );

    if ( $params->{validator} ) {
        throw('The `validator` must be an instance of `Graph::QL::Execution::QueryValidator`, not `%s`', $self->{validator})
            unless assert_isa( $self->{validator}, 'Graph::QL::Execution::QueryValidator' );
    }
    else {
        $self->{validator} = Graph::QL::Execution::QueryValidator->new(
            schema => $self->{schema},
            query  => $self->{query},
        );
    }
}

sub schema    : ro;
sub query     : ro;
sub resolvers : ro;

## ...

sub validate   ($self) { $self->{validator}->validate   }
sub has_errors ($self) { $self->{validator}->has_errors }
sub get_errors ($self) { $self->{validator}->get_errors }

sub execute ($self) {

    throw("You cannot execute a query that has errors:\n%s" => join "\n" => $self->get_errors)
        if $self->has_errors;

    my $root_type = $self->{schema}->lookup_root_type( $self->{query} );

    my $data = $self->execute_selections(
        $root_type,
        $self->{query}->selections,
        $self->{resolvers}->get_type( $root_type->name ),
        {},
    );

    return $data;
}

sub execute_selections ($self, $schema_type, $selections, $type_resolver, $initial_value) {

    my %results;
    foreach my $selection ( $selections->@* ) {
        my $response_key = $selection->has_alias ? $selection->alias : $selection->name;
        my $schema_field = $schema_type->lookup_field( $selection );

        $results{ $response_key } = $self->execute_field(
            $schema_field,
            $selection,
            $type_resolver->get_field( $schema_field->name ),
            $initial_value
        );
    }

    return \%results;
}

sub execute_field ($self, $schema_field, $selection, $field_resolver, $initial_value) {

    my %field_args = map { $_->name => $_->value } $selection->args->@*;
    my $resolved   = $field_resolver->resolve( $initial_value, \%field_args );

    my $schema_field_type = $self->{schema}->lookup_type(
        $self->_find_base_schema_type( $schema_field->type )
    );

    if ( $selection->has_selections ) {

        my $selections    = $selection->selections;
        my $type_resolver = $self->{resolvers}->get_type( $schema_field_type->name );

        if ( $schema_field->type->isa('Graph::QL::Schema::Type::Named') ) {
            $resolved = $self->execute_selections(
                $schema_field_type,
                $selections,
                $type_resolver,
                $resolved,
            );
        }
        else {
            if ( $schema_field->type->isa('Graph::QL::Schema::Type::List') ) {
                $resolved = [
                    map {
                        $self->execute_selections(
                            $schema_field_type,
                            $selections,
                            $type_resolver,
                            $_,
                        )
                    } $resolved->@*
                ]
            }
            elsif ( $schema_field->type->isa('Graph::QL::Schema::Type::NonNull') ) {

            }
        }
    }

    return $resolved;
}

## ...

sub _find_base_schema_type ($self, $schema_type) {
    $schema_type = $schema_type->of_type
        while $schema_type->isa('Graph::QL::Schema::Type::NonNull')
           || $schema_type->isa('Graph::QL::Schema::Type::List');
    return $schema_type;
}

sub _add_error ($self, $msg, @args) {
    $msg = sprintf $msg => @args if @args;
    push $self->{_errors}->@* => $msg;
    return;
}

sub _absorb_validation_errors ($self, $msgs, $e) {
    push $self->{_errors}->@* => $msgs, map "[VALIDATION] $_", $e->get_errors;
    return;
}

1;

__END__

=pod

=head1 DESCRIPTION

This object contains the data that must be available at all points
during query execution.

Namely, schema of the type system that is currently executing, and
the fragments defined in the query document.

=cut
