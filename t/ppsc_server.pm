our $tests;

use strict;
use IO::Socket::INET;
no warnings;

# NOTE: To use this test, you have to enter a PREAUTH server command into your
# ~/.ppsc_test file and make sure you have File::Slurp installed.
#
# Example command:
#
# echo ssh -C blarghost exec dovecot --exec-mail imap > ~/.ppsc_test
#

my $tests = 1;
my $cmd;
if( my $t = "$ENV{HOME}/.ppsc_test" ) {
    eval q { # string eval :P
        use File::Slurp qw(slurp);
        $cmd = slurp("$ENV{HOME}/.ppsc_test");
        chomp $cmd;
    };
}

unless( $cmd ) {
    warn "not set up for PREAUTH tests, skipping all meaningful tests\n";
    skip(1,1,1) for 1 .. $tests;
    exit 0;
}

$SIG{CHLD} = $SIG{PIPE} = sub {};

sub kill_imap_server {
    my $pid = shift;

    #warn " killing: $pid";
    for(15,2,9,13,11) {
        kill $_, $pid;
        sleep 1;
    }
}

if( my $pid = fork ) {
    my $imapfh;

    my $retries = 10;

    my $line; {
        sleep 1 while (--$retries)>0 and not $imapfh = IO::Socket::INET->new('localhost:9000');

        if( not $imapfh ) {
            warn "unable to start pipe-server, skipping all meaningful tests\n";
            skip(1,1,1) for 1 .. $tests;
            exit 0;
        } 

        $line = <$imapfh>;
        redo unless $line =~ m/PREAUTH/;
    };

    if( __PACKAGE__->can('run_tests') ) {
        run_tests()

    } else {
        warn "\nserver started in standalone testing mode...\n";
        warn "if this isn't what you wanted, provide a run_tests() function.\n";
        exit 0;
    }

    kill_imap_server($pid);

    exit(0); # doesn't help, see below

} else {
    exec "contrib/preauth-pipe-server.pl", 9000, $cmd;
}

1;
