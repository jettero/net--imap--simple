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

my $imap = slurp_fetchmail->login(use_ssl=>1, debug=>$ENV{DEBUG});

my @c;
for my $box (split m/\s+/, (shift||"INBOX")) {
    push @c, [
        selectres => dump($imap->select("jet")), 
        box => $imap->current_box, first_unseen=>$imap->unseen, recent=>$imap->recent,
    ];
}

warn dump(@c);
