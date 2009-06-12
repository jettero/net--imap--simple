
use strict;
use warnings;

use Test;
use Net::TCP;
use Net::IMAP::Simple;

plan tests => my $tests = 9;

TOP: if( -f "imap_server.pid" ) {
    my $imap = Net::IMAP::Simple->new('localhost:7000') or die "connect failed: $Net::IMAP::Simple::errstr";

    ok( not $imap->login(qw(bad login)) );
    ok( $imap->errstr, qr/disabled/ );

    open INFC, ">informal-imap-client-dump.log";
    # we don't care very much if the above command fails

    $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "connect failed: $Net::IMAP::Simple::errstr\n";

    ok( $imap->login(qw(working login)) )
        or die " login failure: " . $imap->errstr . "\n";

    my $nm = $imap->select("INBOX");
    ok( defined $nm )
        or die " failure($nm) selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->put( INBOX => "Subject: test!\n\ntest!" ) )
        or die " error putting test message: " . $imap->errstr . "\n";

    my $c1 = [ $imap->select("fake"),  $imap->unseen, $imap->last, $imap->recent ]; ok( not $c1->[0] );
    my $c2 = [ $imap->select("INBOX"), $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0] );
    my $c3 = [ $imap->select("fake"),  $imap->unseen, $imap->last, $imap->recent ]; ok( not $c1->[0] );
    my $c4 = [ $imap->select("INBOX"), $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0] );

} else {
    if( $ENV{TEST_AUTHOR} ) {
        if( my $pid = fork ) {
            waitpid $pid, 0;

        } else {
            system($^X, "t/07_start_server.t");
            exit 0;
        }
        sleep 1;
        goto TOP;

    } else {
        warn "skipping $0\n";
        skip(1,1,1) for 1 .. $tests;
    }
}
