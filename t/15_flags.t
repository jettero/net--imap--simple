use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 10;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    for(1 .. 10) {
        $imap->put( INBOX => "Subject: test-$_\n\ntest-$_" );
        ok( $imap->unseen, $_ );
    }
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
