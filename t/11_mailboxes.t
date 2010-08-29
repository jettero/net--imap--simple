use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 2;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    my @e = $imap->mailboxes;
    my @E = qw(INBOX INBOX/working);

    ok( $e[$_], $E[$_] ) for 0 .. $#e;
}   

do "t/test_server.pm" or die "error starting imap server: $!$@";

