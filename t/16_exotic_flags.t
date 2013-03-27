use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 4;

our $imap;
    
sub run_tests {
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    if( $nm ) {
        $imap->delete("1:$nm");
        $imap->expunge_mailbox;
    }

    $imap->put( INBOX => "Subject: test message" );
    $imap->add_flags(1 => qw(blarg fluurg carmel) );

    my @flags = $imap->msg_flags(1);
    ok( @flags+0, 3 );
    ok( (grep {m/blarg/}  @flags), 1 );
    ok( (grep {m/fluurg/} @flags), 1 );
    ok( (grep {m/carmel/} @flags), 1 );
}

do "t/test_runner.pm";
