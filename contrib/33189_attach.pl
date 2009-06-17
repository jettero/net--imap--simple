#!/usr/bin/perl

# Warning: the returned message numbers are not always correct!

use strict;
use warnings;

use Net::IMAP::Simple;
use Email::Simple;

my $show_subjects = 0;

my $server = "XXXeditedXXX";
my $user   = "XXXeditedXXX";
my $pass   = "XXXeditedXXX";
my $folder = shift;
$folder = "INBOX" unless $folder;

my $imap = Net::IMAP::Simple->new( $server, debug => 1 )
  || die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";

my ( $newmsg, $unseenmsg, $oldmsg, $flags );

# Log on
if ( !$imap->login( $user => $pass ) ) {
    print STDERR "Login failed: " . $imap->errstr . "\n";
    exit(64);
}

my $nm = $imap->select($folder);

print "folder $folder: $nm total";

$newmsg = $imap->recent;
$flags  = $imap->flags;

$unseenmsg = 0;
for ( my $i = 1 ; $i <= $nm ; $i++ ) {
    $unseenmsg++ if not $imap->seen($i);
}

$oldmsg = $unseenmsg - $newmsg;

print ", $newmsg new, $unseenmsg unseen, $oldmsg old\n";

# Print the subjects of all the messages in the INBOX
if ($show_subjects) {
    for ( my $i = 1 ; $i <= $nm ; $i++ ) {
        if ( $imap->seen($i) ) {
            print "  ";
        } else {
            print "N ";
        }

        my $es = Email::Simple->new( join '', @{ $imap->top($i) } );

        printf( "[%03d] %s\n", $i, $es->header('Subject') );
    }
}

$imap->quit;

