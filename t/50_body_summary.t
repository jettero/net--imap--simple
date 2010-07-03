use strict;
use warnings;

use Test;

BEGIN { 
    if( not -f "test_simplex" ) {
        plan tests => 1;
        print "# skipping all tests, not installing SimpleX\n";
        skip(1,1,1);
        exit 0;
    }
}

use Net::IMAP::SimpleX;

plan tests => our $tests = 
    3;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::SimpleX->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->put( INBOX => "Subject: test" );

    my $bs = $imap->body_summary(1);
    ok( int(@{ $bs->{parts} }), 1 );
    ok( $bs->{type}, "SINGLE" );
    ok( $bs->{parts}[0]{content_type}, "text/plain" );

}

do "t/test_server.pm" or die "error starting imap server: $!$@";
