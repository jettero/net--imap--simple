our $tests;

use strict;
use IO::Socket::INET;
use Fcntl qw(:flock);
no warnings;

# 
# There used to be a little stand alone server than ran in this test suite.  It
# was totally unreliable and I tired of trying to maintain it.  You must now
# test against your own server if you wish to test.  I highly recommend
# skipping the tests.  If you choose to report errors, please also explain why
# they failed.
# 
# For example, the last failures from CPAN Testers seemed to be segmentation
# faults in SSL that I couldn't reproduce at my house or at work.  Not really a
# perl problem and not really something I can fix.
#
# On the other hand, it could be a simple network or process management error.
# How can I tell from here?  TAP wasn't really set up to deal with process
# management the way I was doing it.  I gave up.
#
# If you want to test, set these environment variables and run the tests.
#
#     export NIS_TEST_HOST=someserver.org
#     export NIS_TEST_USER=someguyname
#     export NIS_TEST_PASS=blarg
#
#

unless( exists $ENV{NIS_TEST_HOST} and exists $ENV{NIS_TEST_USER} and exists $ENV{NIS_TEST_PASS} and Net::IMAP::Simple->new($ENV{NIS_TEST_HOST}) ) {
    ok($_) for 1 .. $tests;  # just skip everything
    my $line = "[not actually running any tests -- see t/test_runner.pm]";
    my $len = length $line; $len ++;
    print STDERR "\e7\e[5000C\e[${len}D$line\e8";
    exit 0;
}

if( __PACKAGE__->can('run_tests') ) {
    run_tests()

} else {
    warn "weird, no tests";
}

