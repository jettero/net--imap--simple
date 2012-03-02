BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 8;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->select("INBOX")+0, 0 );

    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;
    $imap->delete( "3:4,6" ) or die $imap->errstr;
    my @e = $imap->expunge_mailbox;
    ok( not $imap->waserr );
    ok( "@e", "3 3 4" );
     
    $imap->delete( "3,4" ) or die $imap->errstr;
    my $e = $imap->expunge_mailbox;
    ok( not $imap->waserr );
    ok( $e, "2" );

    $imap->delete( "4:7,9,10" ) or die $imap->errstr;
    @e = $imap->expunge_mailbox;
    ok( not $imap->waserr );
    ok( "@e", "4 4" );

    ok( $imap->last, 3 );
}   

do "t/test_server.pm";

