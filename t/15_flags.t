use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests =
    ((my $puts = 5)+1)*5 -2 # the put lines
    + 8 # some arbitrary flag tests on message 4
    + 8 # some msg_flags return values
    + 8 # grab flags for some nonexistnat messages, and for some existant ones
    ;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( 0+$imap->last, 0 );
    ok( 0+$imap->unseen, 0 );
    ok( 0+$imap->recent, 0 );

    for(1 .. $puts) {
        ok( $imap->put( INBOX => "Subject: test-$_\n\ntest-$_" ) );

        ok( 0+$imap->last, $_ );
        ok( 0+$imap->recent, $_ );

        ok( 0+$imap->unseen, $_ );

        $imap->see($_);
        ok( 0+$imap->unseen, 0 );
    }

    $imap->unsee(4);
    $imap->delete(4);

    ok( not $imap->seen(4) );
    ok(     $imap->deleted(4) );

    $imap->see(4);
    $imap->undelete(4);

    ok(     $imap->seen(4) );
    ok( not $imap->deleted(4) );

    $imap->add_flags( 5, qw(\Seen \Deleted) );

    ok(     $imap->seen(5) );
    ok(     $imap->deleted(5) );

    $imap->sub_flags( 5, qw(\Seen \Deleted) );

    ok( not $imap->seen(5) );
    ok( not $imap->deleted(5) );

    $imap->sub_flags( 4, qw(\Seen \Deleted \Answered) );
    $imap->add_flags( 5, qw(\Seen \Deleted \Answered) );

    my @flags4 = $imap->msg_flags(4); ok( not $imap->waserr );
    my $flags4 = $imap->msg_flags(4); ok( not $imap->waserr );
    my @flags5 = $imap->msg_flags(5); ok( not $imap->waserr );
    my $flags5 = $imap->msg_flags(5); ok( not $imap->waserr );

    ok( 0+@flags4, 1 ); # \Recent
    ok( 0+@flags5, 4 ); # \Recent \Seen \Answered \Deleted
    ok( defined $flags4 );
    ok( defined $flags5 );


    () = $imap->msg_flags(252); ok( $imap->waserr );
    ok( not defined $imap->msg_flags(252) );
    ok( not defined $imap->seen(252) );
    ok( not defined $imap->deleted(252) );

    ok( defined $imap->seen(4) );
    ok( defined $imap->seen(5) );

    ok( defined $imap->deleted(4) );
    ok( defined $imap->deleted(5) );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
