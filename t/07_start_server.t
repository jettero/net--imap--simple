
use strict;
use warnings;

use Test;
use Net::TCP;
use Net::IMAP::Simple;
use Cwd;

plan tests => my $tests = 1;

# test support:

die "there's already a server running, something might be wrong?" if -f "imap_server.pid";

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

    if( not $imapfh ) {
        warn "unable to start Net::IMAP::Server, skipping all meaningful tests\n";
        skip(1,1,1) for 1 .. $tests;
        exit 0;
    } 

    warn "imap server is up: " . <$imapfh>;
    close $imapfh;

    open my $fh, ">imap_server.pid" or die $!;
    ok print $fh "$pid\n";
    exit 0;
}

close STDOUT; close STDERR;
open STDERR, ">informal-imap-server-dump.log";
open STDOUT, ">informal-imap-server-dump.log";
# (we don't really care if the above fails...)

my $dir = getcwd();
eval q | END { unlink "$dir/imap_server.pid" } |;
$SIG{ALRM} = sub { unlink "$dir/imap_server.pid"; exit 0 };
alarm 60; # this server lasts at most 60 seconds, except perhaps on windows (??)

Net::IMAP::Server->new(
    port        => 7000,
    ssl_port    => 8000,
    auth_class  => "t7lib::Auth",
    model_class => "t7lib::Model",
  # user        => "nobody",
  # group       => "nobody",
)->run;
