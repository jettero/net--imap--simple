#!/usr/bin/perl

use strict;

use Net::IMAP::Simple;
my $goog = login();

$goog->select("jet");

my @id1 = $goog->search(q(SUBJECT "rt.cpan.org #55177"));
my @id2 = $goog->search(q(HEADER Message-ID "<rt-3.8.HEAD-12685-1267618808-430.55177-4-0@rt.cpan.org>"));

print "id1: @id1\n";
print "id2: @id2\n";

# login {{{
sub login {
    my $arg = ""; $arg = ".$_[0]" if $_[0];
    my $fetchmailrc; { open my $in, "$ENV{HOME}/.fetchmailrc$arg" or die $!; local $/ = undef; $fetchmailrc = <$in>; close $in; }
    my $server = $1 if $fetchmailrc =~ m/server\s+(.+)/m;
    my $user   = $1 if $fetchmailrc =~ m/user\s+(.+)/m;
    my $pass   = $1 if $fetchmailrc =~ m/pass\s+(.+)/m;

    print "$server ";
    my $debug = 1;

    my $imap = Net::IMAP::Simple->new($server, debug=>$debug, use_ssl=>1) or die "connect failed: $Net::IMAP::Simple::errstr";
       $imap->login($user=>$pass) or die "login failed: " . $imap->errstr;

    print "[in] ";

    return $imap;
}
# }}}
