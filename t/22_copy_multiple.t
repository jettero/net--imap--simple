use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 6;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->select("INBOX")+0, 0 );

    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;
    ok( $imap->select("INBOX")+0, 10 );

    ok( $imap->copy( "3:5,9",      'INBOX/working' ) );
    ok( $imap->copy( "1,7",        'INBOX/working' ) );
    #ok(!$imap->copy( "3:4,9,99,1", 'INBOX/working' ) );
    skip(1,1,1);
    ok( $imap->select("INBOX/working"), 6 );
}   

do "t/test_server.pm" or die "error starting imap server: $!$@";

