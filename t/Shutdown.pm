package Net::IMAP::Server::Command::Shutdown;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub run {
    my $self = shift;

    unlink "imap_server.pid";
    exit 0; # probably not trappable/trapped by Coro
}

1;
