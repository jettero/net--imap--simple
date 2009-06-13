use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

sub run_tests {
    open my $out, ">>", "informal-imap-client-dump.log" or die $!;

    my @c;
    my $c = sub {
        my $c = Net::IMAP::Simple->new('localhost:8000', debug=>$out, use_ssl=>1);
        push @c, $c;
        $c;
    };

    ok( $c->() );
    ok( $c->() );
    ok( $c->() );
    ok( $c->() );
    ok( not $c->() );
}

do "t/test_server.pm" or die "error starting imap server: $!$@";
