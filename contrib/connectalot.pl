#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket::INET;

my $ppid = $$;
END { print "[$$] ", $$==$ppid ? "ppid ":"", "exit\n" };
print "[$$] ppid started\n";

$SIG{__WARN__} = sub { print "[$$] $_[0]" };
$SIG{__DIE__}  = sub { print "[$$] $_[0]"; exit 0 };

my @pids;
for( 1 .. 5 ) {
    if( my $pid = fork ) {
        push @pids, $pid;

    } else {
        print "[$$] start\n";
        my $sock = IO::Socket::INET->new(PeerAddr=>"localhost:7000", Timeout=>2) or die "couldn't bind: $@";
        while( my $line = $sock->getline ) {
            print "[$$] $line";
        }

        my $eof = $sock->eof ? "EOF" : "...";
        my $ced = $sock->connected ? "CONNECTED" : "...";

        print "[$$] eof: $eof; ced: $ced\n";
        exit 0;
    }
}

waitpid( $_, 0 ) for @pids;
