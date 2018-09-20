#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Execution::Executor');
    use_ok('Graph::QL::Execution::FieldResolver');
}

done_testing;
