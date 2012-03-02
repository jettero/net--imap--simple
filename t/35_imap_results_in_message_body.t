BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 1;

my $special_message = <<"HERE";
From: me
To: you
Subject: supz!

1 OK FETCH COMPLETED\r
2 OK FETCH COMPLETED\r
3 OK FETCH COMPLETED\r
4 OK FETCH COMPLETED\r
5 OK FETCH COMPLETED\r

Hi, this is a message, do you like it?

HERE

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->put( INBOX => $special_message );

    ok( $imap->get(1), $special_message );
}   

do "t/test_server.pm";

