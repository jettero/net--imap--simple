BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 2;

my $append_ok = 0;
my $get_ok    = 0;

sub callback_test {
    my ($line) = @_;

    # e.g.: 5 OK [APPENDUID 1283347568 1002] APPEND COMPLETED
    $append_ok ++ if $line =~ m/\d+\s+OK.+?APPEND COMPLETED/;
    $get_ok    ++ if $line =~ m/test-\d+!/;
}

sub run_tests {
    my $imap = Net::IMAP::Simple->new('localhost:19795',
        debug   => "file:informal-imap-client-dump.log",
        use_ssl => 1,

        readline_callback => \&callback_test,

    ) or die "\nconnect failed: $Net::IMAP::Simple::errstr";

    $imap->login(qw(working login));
    $imap->create_mailbox('callbacktest');
    $imap->select("callbacktest");
    $imap->put( callbacktest => "Subject: test!\n\ntest-$_!" ) for 1 .. 5;
    $imap->get( $_ ) for 1 .. 5;

    ok( $append_ok, 5 );
    ok( $get_ok,    5 );
}

do "t/test_server.pm";
