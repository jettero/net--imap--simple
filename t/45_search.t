use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests =
    ((my $puts = 5)+1)*5 -2 # the put lines
    ;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( 0+$imap->last, 0 );
    ok( 0+$imap->search_unseen, 0 );
    ok( 0+$imap->search_recent, 0 );

    for(1 .. $puts) {
        ok( $imap->put( INBOX => "Subject: test-$_\n\ntest-$_" ) );

        ok( 0+$imap->last, $_ );
        ok( 0+$imap->search_recent, $_ );

        ok( 0+$imap->search_unseen, $_ );

        $imap->see($_);
        ok( 0+$imap->search_unseen, 0 );
    }
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
