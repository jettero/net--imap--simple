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

plan tests => our $tests = (1+1);

my $sample = q/FETCH (FLAGS (\Recent) INTERNALDATE "23-Jul-2010 22:21:37 -0400" RFC822.SIZE 402/
          . q/ ENVELOPE (NIL "something" NIL NIL NIL NIL NIL NIL NIL NIL) BODY (("text" "plain" ("charset" "fake-charset-1")/
        . qq/ NIL NIL "7BIT" 15 2)("text" "html" ("charset" "fake-charset-2") NIL NIL "7BIT" 21 2) "alternative"))\x0d\x0a/;

sub run_tests {

    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::SimpleX->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    my $parser = $imap->{parser}{fetch};
    my $bool   = $parser->fetch($sample) ? 1:0;

    ok( $bool );

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->put( INBOX => <<TEST2 );
From jettero\@cpan.org Wed Jun 30 11:34:39 2010
Subject: something
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="0-1563833763-1277912078=:86501"

--0-1563833763-1277912078=:86501
Content-Type: text/plain; charset=fake-charset-1

Text Content.

--0-1563833763-1277912078=:86501
Content-Type: text/html; charset=fake-charset-2

<p>HTML Content</p>

--0-1563833763-1277912078=:86501--

TEST2

    my %parts = $imap->fetch(1=>'FULL');
    ok( int( keys %parts ), 5 ) or warn do {my @a = keys %parts; "parts(@a)"};
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
