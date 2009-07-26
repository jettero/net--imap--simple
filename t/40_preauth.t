use strict;
use warnings;
no warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 1;

my $time = localtime;
my $msg = <<"HERE";
From: me
To: you
Subject: NiSim Test - $time

$time
NiSim Test

HERE

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:9000', debug=>\*INFC)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->put( INBOX => $msg );

    ok( $imap->get($nm + 1), $msg );
}   

do "t/ppsc_server.pm" or die "error starting imap server: $!$@";

