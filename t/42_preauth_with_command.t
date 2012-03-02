BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
no warnings;

# NOTE: To use this test, you have to enter a PREAUTH server command into your
# ~/.ppsc_test file and make sure you have File::Slurp installed.
#
# Example command:
#
# echo ssh -C blarghost exec dovecot --exec-mail imap > ~/.ppsc_test
#

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 1;

sub fixeol($) { $_[0] =~ s/[\x0d\x0a]+/\n/g }

my $time = localtime;
my $msg = <<"HERE";
From: me
To: you
Subject: NiSim Test - $time

$time
NiSim Test

HERE

open INFC, ">>", "informal-imap-client-dump.log" or die $!;

my $cmd;
if( my $t = "$ENV{HOME}/.ppsc_test" ) {
    eval q +
        use File::Slurp qw(slurp);
        $cmd = slurp("$ENV{HOME}/.ppsc_test");
        chomp $cmd;
    +;
}

unless( $cmd ) {
    skip(1,1,1);
    exit 0;
}

my $imap = Net::IMAP::Simple->new("cmd:$cmd", debug=>\*INFC)
    or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

my $nm = $imap->select('INBOX')
    or die " failure selecting INBOX: " . $imap->errstr . "\n";

$imap->put( INBOX => $msg ); my $gmsg =
$imap->get( $nm + 1 );

fixeol($msg);
fixeol($gmsg);

ok( $gmsg, $msg );
