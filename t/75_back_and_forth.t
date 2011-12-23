use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => 2 + (our $tests = 200);

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->select("INBOX")+0, 0 );
    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_" . "\n" . (" xxxxxx " x 2_000), '\Seen' ) for 1 .. $tests;
    ok( $imap->select("INBOX")+0, $tests );
}   

do "t/test_server.pm";

