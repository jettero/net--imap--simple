use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->select("INBOX")+0, 0 );

    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;
    ok( $imap->select("INBOX")+0, 10 );

    my @_uid359 = $imap->uid("3:5,9");
    my @_uid17  = $imap->uid("1,7");

    ok($imap->uidcopy( join(",",@_uid359), 'INBOX/working' ) );
    ok($imap->uidcopy( join(",",@_uid17),  'INBOX/working' ) );
    ok($imap->select("INBOX/working"), 6 );
}   

do "t/test_server.pm";

