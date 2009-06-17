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

my $c1 = [ selectres=>dump($imap->select("jet")),         box=>$imap->current_box, first_unseen=>$imap->unseen, recent=>$imap->recent ];
my $c2 = [ selectres=>dump($imap->select("fakemailbox")), box=>$imap->current_box, first_unseen=>$imap->unseen, recent=>$imap->recent ];
my $c3 = [ selectres=>dump($imap->select("bct")),         box=>$imap->current_box, first_unseen=>$imap->unseen, recent=>$imap->recent ];

die "c1=(@$c1); c2=(@$c2); c3=(@$c3)\n";
# c1=(212 jet  212 0); c2=(() jet  212 0); c3=(287 bct 3 287 0)

