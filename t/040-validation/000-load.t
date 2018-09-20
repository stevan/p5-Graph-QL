#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Validation::QueryValidator');
}


done_testing;
