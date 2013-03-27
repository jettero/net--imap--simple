our $tests;
our $imap;

use strict;
use IO::Socket::INET;
use Time::HiRes qw(time);
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
#
#     THIS WILL DELETE ALL MAIL IN THIS ACCOUNT
#     BE SURE IT IS A TEST ACCOUNT
#
#
#     export NIS_TEST_HOST=someserver.org
#     export NIS_TEST_USER=someguyname
#     export NIS_TEST_PASS=blarg
#
#  
# HOST will get connections on 143 and 993, specifying a port is not possible
# at this time.
#
#

unless( exists $ENV{NIS_TEST_HOST} and exists $ENV{NIS_TEST_USER} and exists $ENV{NIS_TEST_PASS} and Net::IMAP::Simple->new($ENV{NIS_TEST_HOST}) ) {
    ok($_) for 1 .. $tests;  # just skip everything
    my $line = "[not actually running any tests -- see t/test_runner.pm]";
    my $len = length $line; $len ++;
    print STDERR "\e7\e[5000C\e[${len}D$line\e8";
    exit 0;
}

open INFC, ">/tmp/client-run-" . time . ".log";
# we don't care very much if the above command fails

$imap = Net::IMAP::Simple->new($ENV{NIS_TEST_HOST}, debug=>\*INFC, use_ssl=>1) or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";
$imap->login(@ENV{qw(NIS_TEST_USER NIS_TEST_PASS)});

if( __PACKAGE__->can('run_tests') ) {
    eval {
        run_tests();

    1} or warn "\nfail: $@\n";

} else {
    warn "weird, no tests";
}

