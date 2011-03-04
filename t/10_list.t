use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

sub run_tests {
    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>"file:informal-imap-client-dump.log", use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr";

    $imap->login(qw(working login));
    $imap->create_mailbox("blarg");
    $imap->select("blarg");

    my $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 0 );

    $imap->put( blarg => "Subject: test!\n\ntest!" );
    $imap->select('blarg');

    $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 1 );
    my ($v) = values %$h;
    ok( $v, 21 );
}

do "t/test_server.pm";
