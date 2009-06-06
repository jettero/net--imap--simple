
use Test;
use Net::TCP;
plan tests => my $tests = 1;

SHHH: {
    # NOTE: the imap server emits various startup warnings on import
    local $SIG{__WARN__} = sub {};
    unless( eval "use Coro; use EV; use Net::IMAP::Server; 1" ) {
        warn " Net::IMAP::Server not found, skipping all meaningful tests\n";
        skip(1,1,1) for 1 .. $tests;
        exit 0;
    }
}

if( my $pid = fork ) {
    my $imapfh;
    my $retries = 15;
    sleep 1 while (--$retries)>0 and not $imapfh = Net::TCP->new(localhost=>7000);
    warn " imap server is up: " . <$imapfh> . "\n";
    close $imapfh;

    # run tests here
    ok(1);

    # murder the imap server
    kill 15, $pid;
    waitpid $pid, 0;
    exit 0;
}

close STDOUT; close STDERR;
unlink "informal-imap-server-dump.log";
open STDERR, ">>informal-imap-server-dump.log";
open STDOUT, ">>informal-imap-server-dump.log";
# (we don't really care if the above fails...)

Net::IMAP::Server->new(
    port        => 7000,
    ssl_port    => 8000,
  # auth_class  => "Your::Auth::Class",
  # model_class => "Your::Model::Class",
  # user        => "nobody",
  # group       => "nobody",
)->run;

