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

    my ($unseen, $recent, $total) = $imap->status;
    ok( "unseen $unseen", "unseen 0" );
    ok( "recent $recent", "recent 10" );
    ok( "total  $total",  "total  10" );

    $imap->unsee($_) for 5,7;
    ok( "funseen " . $imap->unseen, 'funseen 5' );

    ($unseen, $recent, $total) = $imap->status;
    ok( "unseen $unseen", "unseen 2" );
    ok( "recent $recent", "recent 10" );
    ok( "total  $total",  "total  10" );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
