#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Execution::ExecuteQuery');
    use_ok('Graph::QL::Execution::QueryValidator');
}

done_testing;
