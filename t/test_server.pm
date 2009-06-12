our $tests;

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

$0 = "Test Net::IMAP::Server service on 7000/8000";
Net::IMAP::Server->new(
    port        => 7000,
    ssl_port    => 8000,
    auth_class  => "t7lib::Auth",
    model_class => "t7lib::Model",
  # user        => "nobody",
  # group       => "nobody",
)->run;
