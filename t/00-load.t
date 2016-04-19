#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Group::Git::Cmd::Stats' );
}

diag( "Testing Group::Git::Cmd::Stats $Group::Git::Cmd::Stats::VERSION, Perl $], $^X" );
done_testing();
