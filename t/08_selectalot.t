BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 3;

sub run_tests {
    my $imap = Net::IMAP::Simple->new('localhost:19794') or die "\nconnect failed: $Net::IMAP::Simple::errstr";

    open INFC, ">informal-imap-client-dump.log";
    # we don't care very much if the above command fails

    $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login)) or die "\nlogin failure: " . $imap->errstr . "\n";

    $imap->select("INBOX") or warn " \e[1;33m" . $imap->errstr . "\e[m\n";
    ok( $imap->current_box, "INBOX" );

    $imap->select("blarg");
    ok( $imap->current_box, "INBOX" );

    $imap->select("INBOX/working") or warn " \e[1;33m" . $imap->errstr . "\e[m\n";
    ok( $imap->current_box, "INBOX/working" );
}

do "t/test_server.pm";
