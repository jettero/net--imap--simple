use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

my $special_message = <<"HERE";
From: me
To: you
Subject: supz!


Hi, this is a message, do you like it?
HERE

my $digest = digest($special_message);

sub run_tests {
    open INFC, ">>", "informal-imap-client-dump.log" or die $!;

    my $imap = Net::IMAP::Simple->new('localhost:8000', debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    $imap->login(qw(working login));
    my $nm = $imap->select('INBOX')
        or die " failure selecting INBOX: " . $imap->errstr . "\n";

    $imap->put( INBOX => $special_message );
    ok( digest($imap->get(1)), $digest );

}   

sub sum(&@) {
    my $code = shift;
    my $sum  = 0;
       $sum += $code->($_) for @_;

    $sum;
}

sub digest {
    use bytes;
    my @sums = map {sum {ord $_} $_[0] =~ m/(.{$_})/sg} 1 .. 16;
    my @hash = map {sprintf '%02x', $_ % 256} @sums;

    # (If anyone happens to read this, it's not intended to be cryptographically secure.)

    $"=""; "@hash";
}

do "t/test_server.pm" or die "error starting imap server: $!$@";

