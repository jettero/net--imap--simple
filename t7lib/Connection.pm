
package t7lib::Connection;

use strict;
use warnings;

use base 'Net::IMAP::Server::Connection';

sub greeting {
    my $self = shift;

    my $c = @{$self->server->connections};

    if( $c>4 ) {
        $self->out("* BYE for testing purposes, we only allow 4 connections at a time.");
        $self->close;
        die "close right now please";
        return;
    }

    return $self->untagged_response("OK Net::IMAP::Simple Test Server ($c)");
}

1;
