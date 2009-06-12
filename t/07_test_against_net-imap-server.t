
use strict;
use warnings;

use Test;
use Net::TCP;
use Net::IMAP::Simple;

plan tests => my $tests = 5;

sub run_tests() {
    my $imap = Net::IMAP::Simple->new('localhost:7000') or die "\nconnect failed: $Net::IMAP::Simple::errstr";

    ok( not $imap->login(qw(bad login)) );
    ok( $imap->errstr, qr/disabled/ );

    open INFC, ">informal-imap-client-dump.log";
    # we don't care very much if the above command fails

    $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    ok( $imap->login(qw(working login)) )
        or die "\nlogin failure: " . $imap->errstr . "\n";

    my $nm = $imap->select("INBOX");
    ok( defined $nm )
        or die " failure($nm) selecting INBOX: " . $imap->errstr . "\n";

    ok( $imap->put( INBOX => "Subject: test!\n\ntest!" ) )
        or die " error putting test message: " . $imap->errstr . "\n";

    my $c1 = [ $imap->select("fake"),  $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], undef );
    my $c2 = [ $imap->select("INBOX"), $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], 1 );
    my $c3 = [ $imap->select("fake"),  $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], undef );
    my $c4 = [ $imap->select("INBOX"), $imap->unseen, $imap->last, $imap->recent ]; ok( $c1->[0], 1 );
}

# test support:

for my $mod (qw(Coro::EV Net::IMAP::Server IO::Socket::SSL)) {
    my $res = do {
        # NOTE: the imap server emits various startup warnings on import
        local $SIG{__WARN__} = sub {};
        eval "use $mod; 1";
    };

    unless( $res ) {
        warn "$mod not found, skipping all meaningful tests\n";
        skip(1,1,1) for 1 .. $tests;
        exit 0;
    }
}

if( my $pid = fork ) {
    my $imapfh;
    my $retries = 7;
    SIGCHILD_MEANS_DEATH: {
        local $SIG{CHLD} = sub {
            warn "Net::IMAP::Server died while starting, skipping all meaningful tests\n";
            skip(1,1,1) for 1 .. $tests;
            exit 0;
        };
        sleep 1 while (--$retries)>0 and not $imapfh = Net::TCP->new(localhost=>7000);
    }

    eval q &
        END {
          # warn " murdering imap server (if necessary)\n";
            kill $_, $pid for (15, 2, 11, 9);
            waitpid $pid, 0;
        }1;
    & or die $@;

    if( not $imapfh ) {
        warn "unable to start Net::IMAP::Server, skipping all meaningful tests\n";
        skip(1,1,1) for 1 .. $tests;
        exit 0;
    } 

    warn "imap server is up: " . <$imapfh>;
    close $imapfh;

    run_tests();

    kill $_, $pid for (15, 2, 11, 9);
    waitpid $pid, 0;

    exit 0;
}

close STDOUT; close STDERR;
open STDERR, ">informal-imap-server-dump.log";
open STDOUT, ">informal-imap-server-dump.log";
# (we don't really care if the above fails...)

Net::IMAP::Server->new(
    port        => 7000,
    ssl_port    => 8000,
    auth_class  => "t7lib::Auth",
    model_class => "t7lib::Model",
  # user        => "nobody",
  # group       => "nobody",
)->run;
