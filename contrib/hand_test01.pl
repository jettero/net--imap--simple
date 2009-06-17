#!/usr/bin/perl

BEGIN {
    use IPC::System::Simple qw(systemx);
    systemx($^X, "Makefile.PL") if not -f "Makefile" or ((stat "Makefile")[9] > (stat "Makefile.PL")[9]);
    systemx("make");
}

use strict;
use warnings;
use lib 'contrib', "blib/lib", "blib/arch";
use slurp_fetchmail;
use Data::Dump qw(dump);

my $imap = slurp_fetchmail->login(use_ssl=>1, debug=>1);

my $c1 = [ dump($imap->select("jet")),         $imap->current_box, $imap->unseen, $imap->last, $imap->recent ];
my $c2 = [ dump($imap->select("fakemailbox")), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ];
my $c3 = [ dump($imap->select("bct")),         $imap->current_box, $imap->unseen, $imap->last, $imap->recent ];

die "c1=(@$c1); c2=(@$c2); c3=(@$c3)\n";
# c1=(212 jet  212 0); c2=(() jet  212 0); c3=(287 bct 3 287 0)

