#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');

    use_ok('Graph::QL::Operation::Fragment');
    use_ok('Graph::QL::Util::Schemas');
    use_ok('Graph::QL::Operation::Selection::Field');
    use_ok('Graph::QL::Operation::Selection::Field::Argument');
}

subtest '... single root query' => sub {

    my $source =
q[fragment nameAndIdFromUser on User {
    id
    name
}];

    my $fragment = Graph::QL::Operation::Fragment->new(
        name           => 'nameAndIdFromUser',
        type_condition => Graph::QL::Util::Schemas::construct_type_from_name('User'),
        selections     => [
            Graph::QL::Operation::Selection::Field->new( name => 'id' ),
            Graph::QL::Operation::Selection::Field->new( name => 'name' ),
        ]
    );
    isa_ok($fragment, 'Graph::QL::Operation::Fragment');

    is($fragment->name, 'nameAndIdFromUser', '... got the name');

    eq_or_diff($fragment->to_type_language, $source, '... got the expected type language');
};

done_testing;
