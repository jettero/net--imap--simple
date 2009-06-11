
package slurp_fetchmail;

use strict;
use warnings;
use Carp;
use File::Slurp qw(slurp);
use Net::IMAP::Simple;

sub login {
    my $class = shift;
    my $fetchmailrc = slurp("$ENV{HOME}/.fetchmailrc");
    my ($server)    = $fetchmailrc =~ m/server\s+(.+)/m;
    my ($user)      = $fetchmailrc =~ m/user\s+(.+)/m;
    my ($pass)      = $fetchmailrc =~ m/pass\s+(.+)/m;

    croak "server, user and pass must be in the $ENV{HOME}/.fetchmailrc for this to work"
        unless $server and $user and $pass;

    my $imap = Net::IMAP::Simple->new($server, @_) or croak "connect failed: $Net::IMAP::Simple::errstr";
       $imap->login($user=>$pass) or croak "login failed: " . $imap->errstr;

    return $imap;
}

"True";
