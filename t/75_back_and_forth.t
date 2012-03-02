BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => (our $tests = 10 + 3);

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->create_mailbox('test');

    ok( $imap->select("INBOX")+0, 0 );
    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_" . "\n" . (" xxxxxx " x 2_000), '\Seen' ) for 1 .. $tests;
    ok( $imap->select("INBOX")+0, $tests );

    for my $i ( 1 .. ($tests-3) ) {
        my $errors = 0;
        my $msg = $imap->get($i)   or do { $errors ++; warn " " . $imap->errstr };
        $imap->put( test => $msg ) or do { $errors ++; warn " " . $imap->errstr };
        $imap->delete( $i )        or do { $errors ++; warn " " . $imap->errstr };

        ok($errors, 0);
    }

    $imap->get($tests + 9_00); # finishing move
    ok( $imap->errstr, qr(message not found) ); # SPURIOUS: there's really no such error in imap
}   

do "t/test_server.pm";

