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

END { warn " $$ END" }
$SIG{CHLD} = $SIG{PIPE} = sub {};

if( my $pid = fork ) {
    my $imapfh;
    my $retries = 7;
    sleep 1 while (--$retries)>0 and not $imapfh = Net::TCP->new(localhost=>7000);

    if( not $imapfh ) {
        warn "unable to start Net::IMAP::Server, skipping all meaningful tests\n";
        skip(1,1,1) for 1 .. $tests;
        exit 0;
    } 

    warn "imap server is up: " . <$imapfh>;
    close $imapfh;

    $0 = "Net::IMAP::Simple($$)";
    warn " $0";

    run_tests();

} else {
    use POSIX qw(setsid); setsid();
    exit if fork; # setsid() can't save us, Coro hates exit(0) I guess

    $0 = "Net::IMAP::Server($$)";
    warn " $0";
    $SIG{ALRM} = sub { kill 15, $$ };
    alarm 20;

    close STDOUT; close STDERR;
    unlink "informal-imap-server-dump.log";
    open STDERR, ">>informal-imap-server-dump.log";
    open STDOUT, ">>informal-imap-server-dump.log";
    # (we don't really care if the above fails...)

    Net::IMAP::Server->new(
        port        => 7000,
        ssl_port    => 8000,
        pid_file    => "imap_server.pid",
        auth_class  => "t7lib::Auth",
        model_class => "t7lib::Model",
      # user        => "nobody",
      # group       => "nobody",
    )->run;
}
