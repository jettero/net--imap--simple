use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests =
    (my $puts = 5)*2
    +2 # startup
    +2 # subject searches
    ;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( 0+$imap->search_unseen, 0 );
    ok( 0+$imap->search_recent, 0 );

    for my $pnum (1 .. $puts) {
        $imap->put( INBOX => "Subject: test-$pnum\n\ntest-$pnum" );

        ok( 0+$imap->search_recent, $pnum );
        ok( 0+$imap->search_unseen, $pnum );
    }

    ok( 0+$imap->search_subject("test-"),  $puts );
    ok( 0+$imap->search_subject("test-3"), 1 );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
