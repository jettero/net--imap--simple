use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 1;

sub run_tests {
    my @works = grep {$_} map { Net::IMAP::Simple->new('localhost:8000', use_ssl=>1) } 1 .. 5;
    ok( int @works, 4 );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
