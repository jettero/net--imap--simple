use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 4;
    
sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:19795', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->put( INBOX => "Subject: test message" );
    $imap->add_flags(1 => qw($blarg \fluurg ^^carmel^^nugget) );

    my @flags = $imap->msg_flags(1);
    ok( @flags+0, 3+1 ); # we get \Recent for free
    ok( (grep {m/blarg/}  @flags), 1 );
    ok( (grep {m/fluurg/} @flags), 1 );
    ok( (grep {m/carmel/} @flags), 1 );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
