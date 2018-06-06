use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

our $imap;

sub run_tests {
    $imap->create_mailbox("blarg");
    my $n = $imap->select("blarg");
    $imap->delete("1:$n");
    $imap->expunge_mailbox;

    $imap->select("blarg");

    my $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 0 );

    my $msg = "Subject: test!\n\ntest!";
    $imap->put( blarg => $msg );
    $imap->select('blarg');

    $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 1 );
    my ($v) = values %$h;

    # Some servers add two bytes, some don't.  Fine with us.
    my($l0, $l2) = (length($msg), length($msg)+2);
    ok( $v, qr/^(?:$l0|$l2)$/ )
}

do "./t/test_runner.pm";
