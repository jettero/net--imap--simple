use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->select("INBOX")+0, 0 );

    $imap->put( INBOX => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;
    ok( $imap->select("INBOX")+0, 10 );

    my @res;
    ok( $res[0] = $imap->copy( "3:5,9", 'INBOX/working' ) );
    ok( $res[1] = $imap->copy( "1,7",   'INBOX/working' ) );
    ok( $res[2] = $imap->select("INBOX/working"), 6 );

    if( $ENV{AUTOMATED_TESTING} ) {
        unless( $res[0] and $res[1] and $res[2] ) {
            warn "\n\n multi-copy test restuls have been vexing module maintainer, logdump follows( @res )\n";
            sleep 1;

            for my $file(qw(informal-imap-client-dump.log informal-imap-server-dump.log)) {
                if( open my $in, "<", $file ) {
                    print STDERR "dumping $file\n";
                    my @log = <$in>;
                       @log = @log[-200 .. -1] if @log > 200;

                    print STDERR @log;
                }
            }
        }
    }
}   

do "t/test_server.pm" or die "error starting imap server: $!$@";

