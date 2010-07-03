use strict;
use warnings;

use Test;

BEGIN { 
    if( not -f "test_simplex" ) {
        plan tests => 1;
        print "# skipping all tests, not installing SimpleX\n";
        skip(1,1,1);
        exit 0;
    }
}

use Net::IMAP::SimpleX;

plan tests => our $tests = 
    1;

sub run_tests {
    ok(1);
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
