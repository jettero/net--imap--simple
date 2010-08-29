our $tests;

use strict;
use IO::Socket::INET;
no warnings;

BEGIN {
    eval q [use lib 'inc'] # use our local copy of Net::IMAP::Server
        unless $ENV{USE_SYSTEM_COPY};
}

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

$SIG{CHLD} = $SIG{PIPE} = sub {};

sub shutdown_imap_server {
    if( my $imapfh = IO::Socket::INET->new('localhost:19794') ) {
        print $imapfh "1 Shutdown\n";
    }
}

my $retries = 10;
while( -f "imap_server.pid" ) {
    shutdown_imap_server();
    last if ( -- $retries ) < 1;
}

sub kill_imap_server {
    my $pid = shift;

    warn " killing: $pid";
    for(15,2,9,13,11) {
        kill $_, $pid;
        sleep 1;
    }
}

if( my $pid = fork ) {
    my $imapfh;

    $retries = 10;

    my $line; {
        sleep 1 while (--$retries)>0 and not $imapfh = IO::Socket::INET->new('localhost:19794');

        if( not $imapfh ) {
            warn "unable to start Net::IMAP::Server, skipping all meaningful tests\n";
            skip(1,1,1) for 1 .. $tests;
            exit 0;
        } 

        $line = <$imapfh>;
        redo unless $line =~ m/OK/;
    };

    my $file = $INC{'Net/IMAP/Server.pm'};
    my $ver  = $Net::IMAP::Server::VERSION;

    chomp $line;
    $line =~ s/(\* OK).*/$1 $file ($ver)/;

    my $len = length $line; $len ++;
    print STDERR "\e7\e[5000C\e[${len}D$line\e8" unless $ENV{AUTOMATED_TESTING};
    close $imapfh;

    $0 = "Net::IMAP::Simple($$)";

    if( __PACKAGE__->can('run_tests') ) {
        run_tests()

    } else {
        warn "\nserver started in standalone testing mode...\n";
        warn "if this isn't what you wanted, provide a run_tests() function.\n";
        exit 0;
    }

    shutdown_imap_server();

    exit(0); # doesn't help, see below

} else {
    use POSIX qw(setsid); setsid();
    exit if fork; # setsid() can't save us, Coro hates exit(0) I
                  # guess seriously, without this line, the exit
                  # value after run_tests() will be non-zero, no
                  # matter what you pass to exit.

    $0 = "Net::IMAP::Server($$)";
    $SIG{ALRM} = sub {
        warn " $0, part of Net::IMAP::Simple tests, is comitting suicide ";
        kill_imap_server($$);
    };
    alarm $ENV{SUICIDE_SECONDS} || 60;

    open PIDFILE, ">", "imap_server.pid" or die $!;
    print PIDFILE "$$\n"; # the pid_file option for the server doesn't seem to work...
    close PIDFILE;

    close STDOUT; close STDERR;
    unlink "informal-imap-server-dump.log";
    open STDERR, ">>informal-imap-server-dump.log";
    open STDOUT, ">>informal-imap-server-dump.log";
    # (we don't really care if the above fails...)

    use t::Shutdown;
    Net::IMAP::Server->new(
        port             => 19794,
        ssl_port         => 19795,
        auth_class       => "t::Auth",
        model_class      => "t::Model",
        connection_class => "t::Connection",

        log_file  => "formal-imap-server.log",
        log_level => 4

    )->run;
}

1;
