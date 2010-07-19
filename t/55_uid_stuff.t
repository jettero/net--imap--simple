use strict;
use warnings;

use Test;

use Net::IMAP::Simple;

plan tests => our $tests = 6;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    my @uidnext = ($imap->uidnext);
    $imap->put( INBOX => "Subject: test1" ); push @uidnext, $imap->uidnext;
    $imap->put( INBOX => "Subject: test2" );

    my @seq = $imap->search_since("1-Jan-1971");
    my @uid = $imap->uid(do{local $"=","; "@seq"});
    my @aud = $imap->uid();

    for( 0 .. $#uid ) {
        ok($uid[$_], $aud[$_]);
        ok($uid[$_], $uidnext[$_]);
    }

    ok( $imap->uidnext, $uid[-1]+1 ); # this is (perhaps) Net-IMAP-Server specific ... perhaps
    ok( $imap->uidvalidity ); # how could we test this?
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
