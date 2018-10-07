package Graph::QL::Execution::ExecuteQuery;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

use Graph::QL::Execution::QueryValidator;

use constant DEBUG => $ENV{GRAPHQL_EXECUTE_QUERY_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema    => sub {}, # Graph::QL::Schema
    operation => sub {}, # Graph::QL::Operation
    resolvers => sub {}, # a mapping of TypeName to Resolver instance
    validator => sub {}, # Graph::QL::Execution::QueryValidator
    context   => sub { +{} }, # HashRef[Any]
    info      => sub { +{} }, # HashRef[Any]
);

sub BUILDARGS : strict(
    schema     => schema,
    operation  => operation,
    resolvers  => resolvers,
    context?   => context,
    validator? => validator,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

    throw('The `operation` must be of an instance of `Graph::QL::Operation` role, not `%s`', $self->{operation})
        unless assert_isa( $self->{operation}, 'Graph::QL::Operation' );

    # TODO:
    # - handle `initial-value`
    # - handle `variables`
    # - handle `context-value`

    throw('The `resolvers` must be a as instance of `Graph::QL::Resolvers`, not `%s`', $self->{resolvers})
        unless assert_isa( $self->{resolvers}, 'Graph::QL::Resolvers' );

    if ( $params->{context} ) {
        throw('The `context` must be a defined value, not `%s`', $self->{context})
            unless defined $self->{context};
    }

    if ( $params->{validator} ) {
        throw('The `validator` must be an instance of `Graph::QL::Execution::QueryValidator`, not `%s`', $self->{validator})
            unless assert_isa( $self->{validator}, 'Graph::QL::Execution::QueryValidator' );
    }
    else {
        $self->{validator} = Graph::QL::Execution::QueryValidator->new(
            schema => $self->{schema},
            query  => $self->{operation}->get_query,
        );
    }
}

sub schema    : ro;
sub operation : ro;
sub resolvers : ro;

sub get_query ($self) { $self->{operation}->get_query }

## ...

sub validate   ($self) { $self->{validator}->validate   }
sub has_errors ($self) { $self->{validator}->has_errors }
sub get_errors ($self) { $self->{validator}->get_errors }

sub execute ($self) {

    throw("You cannot execute a query that has errors:\n%s" => join "\n" => $self->get_errors)
        if $self->has_errors;

    my $query = $self->get_query;

    DEBUG && $self->__log(0, 'Starting to execute query(%s)', $query->name );

    my $root_type = $self->{schema}->lookup_root_type( $query );

    DEBUG && $self->__log(0, 'Found root-type(%s) for query(%s)', $root_type->name, $query->name );

    my $data = $self->execute_selections(
        $root_type,
        $query->selections,
        $self->{resolvers}->get_type( $root_type->name ),
        {},
    );

    DEBUG && $self->__log(0, 'Finished executing selections for query(%s)', $query->name );

    return $data;
}

sub execute_selections ($self, $schema_type, $selections, $type_resolver, $initial_value) {

    DEBUG && $self->__log(1, 'Executing selections for query(%s) for type(%s)', $self->get_query->name, $schema_type->name);

    my %results;
    foreach my $selection ( $selections->@* ) {
        my $response_key = $selection->has_alias ? $selection->alias : $selection->name;
        my $schema_field = $schema_type->lookup_field( $selection );
        my $resolver     = $type_resolver->get_field( $schema_field->name );

        throw('Unable to find a resolver for type(%s).field(%s)', $schema_type->name, $schema_field->name)
            unless assert_isa($resolver, 'Graph::QL::Resolvers::FieldResolver');

        $results{ $response_key } = $self->execute_field(
            $schema_field,
            $selection,
            $resolver,
            $initial_value
        );
    }

    return \%results;
}

sub execute_field ($self, $schema_field, $selection, $field_resolver, $initial_value) {

    DEBUG && $self->__log(2, 'Executing query(%s).field(%s) for type.field(%s)', $self->get_query->name, $selection->name, $schema_field->name);

    my %field_args = $selection->has_args ? (map { $_->name => $_->value } $selection->args->@*) : ();
    my $resolved   = $field_resolver->resolve(
        $initial_value,
        \%field_args,
        $self->{context},
        {
            $self->{info}->%*,
            schema    => $self->{schema},
            operation => $self->{operation},
            field     => $schema_field,
            selection => $selection,
        },
    );

    return unless $resolved;

    # TODO
    # we need to test the resolved value
    # and be sure it matches the type we
    # expect and is a valid value.
    # - SL

    if ( $selection->has_selections ) {

        my $selections = $selection->selections;

        DEBUG && $self->__log(2, 'Executing sub-selections(%s) for query(%s).field(%s) for type.field(%s)', (join ', ' => map $_->name, $selections->@*), $self->{query}->name, $selection->name, $schema_field->name);

        if ( $schema_field->type->isa('Graph::QL::Schema::Type::Named') ) {
            $resolved = $self->_resolve_named_type( $schema_field->type, $selections, $resolved );
        }
        else {
            if ( $schema_field->type->isa('Graph::QL::Schema::Type::List') ) {
               throw('Expected ARRAY ref from the resolver for type(%s)', $schema_field->name)
                    unless assert_arrayref( $resolved );

                $resolved = $self->_resolve_list_type( $schema_field->type, $selections, $resolved );
            }
            elsif ( $schema_field->type->isa('Graph::QL::Schema::Type::NonNull') ) {
                $resolved = $self->_resolve_non_null_type( $schema_field->type, $selections, $resolved );
            }
            else {
               throw('This should never happen, unable to determine type of schema.field, got `%s`', $schema_field->type);
            }
        }
    }

    return $resolved;
}

## ...

sub _resolve_named_type ($self, $schema_type, $selections, $resolved) {

    DEBUG && $self->__log(3, 'Resolving named-type(%s) for selections(%s)', $schema_type->name, (join ', ' => map $_->name, $selections->@*));

    my $schema_field_type = $self->{schema}->lookup_type( $schema_type );
    my $type_resolver     = $self->{resolvers}->get_type( $schema_field_type->name );

    return $self->execute_selections(
        $schema_field_type,
        $selections,
        $type_resolver,
        $resolved,
    );
}

sub _resolve_list_type ($self, $schema_type, $selections, $resolved) {

    my $of_type = $schema_type->of_type;

    DEBUG && $self->__log(3, 'Resolving list-type(%s) for selections(%s)', $of_type->name, (join ', ' => map $_->name, $selections->@*));

    if ( $of_type->isa('Graph::QL::Schema::Type::Named') ) {
        return [ map { $self->_resolve_named_type( $of_type, $selections, $_ ) } $resolved->@* ];
    }
    elsif ( $of_type->isa('Graph::QL::Schema::Type::List') ) {
        return [ map { $self->_resolve_list_type( $of_type, $selections, $_ ) } $resolved->@* ];
    }
    elsif ( $of_type->isa('Graph::QL::Schema::Type::NonNull') ) {
        return [ map { $self->_resolve_non_null_type( $of_type, $selections, $_ ) } $resolved->@* ];
    }
    else {
        throw('This should never happen, unable to determine type of schema.field, got `%s`', $schema_type);
    }
}

sub _resolve_non_null_type ($self, $schema_type, $selections, $resolved) {

    my $of_type = $schema_type->of_type;

    DEBUG && $self->__log(3, 'Resolving non-null(%s) for selections(%s)', $of_type->name, (join ', ' => map $_->name, $selections->@*));

    if ( $of_type->isa('Graph::QL::Schema::Type::Named') ) {
        return $self->_resolve_named_type( $of_type, $selections, $resolved );
    }
    elsif ( $of_type->isa('Graph::QL::Schema::Type::List') ) {
        return $self->_resolve_list_type( $of_type, $selections, $resolved );
    }
    elsif ( $of_type->isa('Graph::QL::Schema::Type::NonNull') ) {
        return $self->_resolve_non_null_type( $of_type, $selections, $resolved );
    }
    else {
        throw('This should never happen, unable to determine type of schema.field, got `%s`', $schema_type);
    }
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

## ...

sub __log ($self, $depth, $msg, @args) {
    my $indent = '  ' x $depth;
    $msg = sprintf $msg => @args if @args;
    warn "${indent}${msg}\n";
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
