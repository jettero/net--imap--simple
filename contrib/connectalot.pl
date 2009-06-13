#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket::INET;

my @pids;
for( 1 .. 5 ) {
    if( my $pid = fork ) {
        push @pids, $pid;

    } else {
        my $sock = IO::Socket::INET->new("localhost:7000") or die "couldn't bind: $@";
        while( my $line = $sock->getline ) {
            print "[$$] $line";
        }

        my $eof = $sock->eof ? "EOF" : "...";
        my $ced = $sock->connected ? "CONNECTED" : "...";

        print "[$$] eof: $eof; ced: $ced; exit()\n";
        exit 0;
    }
}

waitpid( $_, 0 ) for @pids;
