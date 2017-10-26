use strict;
use warnings;

use Test;

use Net::IMAP::Simple;

plan tests => our $tests = 2 * 3 + 3;

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    my @uidnext;
    for ( 1 .. (($tests - 3) / 3) ) {
        push @uidnext, $imap->uidnext;
        $imap->put( testing => "Subject: test$_" );
        ok( @uidnext[-1] != $imap->uidnext );
    }

    my @seq = $imap->search_since("1-Jan-1971");
    my @uid = $imap->uid(do{local $"=","; "@seq"});
    my @aud = $imap->uid();

    for( 0 .. $#uid ) {
        ok($uid[$_], $aud[$_]);
        ok($uid[$_], $uidnext[$_]);
    }

    ok( $imap->uidnext, $uid[-1]+1 ); # this is (perhaps) Net-IMAP-Server specific ... perhaps
    ok( $imap->uidvalidity ); # how could we test this?

    my @ssuid = $imap->uidsearch("since 1-Jan-1971");
    ok( "@ssuid", "@uid" );
}

do "./t/test_runner.pm";
