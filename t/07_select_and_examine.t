use strict;
no warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 16;

our $imap;
my $nm;

sub run_tests {
    my $nm = $imap->select("fake");
    if( $nm ) {
        $imap->delete("1:$nm");
        $imap->expunge_mailbox;
    }

    $nm = $imap->select("INBOX") or die "imap error: " . $imap->errstr;
    $imap->delete("1:$nm");
    $imap->expunge_mailbox;
    $nm = $imap->select("INBOX");

    $imap->put( INBOX => "Subject: test!\n\ntest!" ) or die "problem putting message: " . $imap->errstr;

    my @c = (
        [ scalar $imap->select("fake"),  $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("INBOX"), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("fake"),  $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("INBOX"), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
    );

    ok( $c[$_][1], "INBOX" ) for 0 .. $#c;

    ok( $c[0][0], undef );
    ok( $c[1][0], $nm+1 );
    ok( $c[2][0], undef );
    ok( $c[3][0], $nm+1 );
    ok( "@{ $c[$_] }[2,3,4]", "1 1 0" ) for 0 .. $#c;

    ## Test EXMAINE

    ok( $imap->examine('INBOX') );
    # ok( not $imap->put( INBOX => "Subject: test!\n\ntest!" ) );
    # ok( $imap->errstr, qr/read.*only/ );
    # this worked in Net::IMAP::Server -- dovecot apparently lets you append after examine... heh

    ok( $nm = $imap->select('INBOX') );
    ok( $imap->put( INBOX => "Subject: test!\n\ntest!" ), 1 )
        or die " error putting test message: " . $imap->errstr . "\n";
    ok( $imap->select('INBOX'), 2 );
}

do "t/test_runner.pm";
