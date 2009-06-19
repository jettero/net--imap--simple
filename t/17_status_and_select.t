use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->select("INBOX")+0, 0 );

    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_" ) for 1 .. 10;

    ok( $imap->select("INBOX"),  10 );

    my ($unseen, $recent, $total) = $imap->status;
    ok( $unseen, 10 );
    ok( $recent, 10 );
    ok( $total,  10 );

    # $imap->unsee($_) for 1,2,7,8;
    # ok( $imap->unseen, 3 );
    # ok( $unseen,  6 );
    # ok( $recent, 10 );
    # ok( $total,  10 );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
