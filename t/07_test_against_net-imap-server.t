
use strict;
use warnings;

use Test;
use Net::TCP;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

sub run_tests() {
    my $imap = Net::IMAP::Simple->new('localhost:7000') or die "\nconnect failed: $Net::IMAP::Simple::errstr";

    ok( not $imap->login(qw(bad login)) );
    ok( $imap->errstr, qr/disabled/ );

    open INFC, ">informal-imap-client-dump.log";
    # we don't care very much if the above command fails

    $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    ok( $imap->login(qw(working login)) )
        or die "\nlogin failure: " . $imap->errstr . "\n";

    my $nm = $imap->select("INBOX");
    ok( defined $nm )
        or die " failure($nm) selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->put( INBOX => "Subject: test!\n\ntest!" ) )
        or die " error putting test message: " . $imap->errstr . "\n";

    my $c1 = [ $imap->select("fake"),  $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], undef );
    my $c2 = [ $imap->select("INBOX"), $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], 1 );
    my $c3 = [ $imap->select("fake"),  $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], undef );
    my $c4 = [ $imap->select("INBOX"), $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], 1 );
}

do "t/test_server.pm";
