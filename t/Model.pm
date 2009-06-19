
package t::Model;

use strict;
use warnings;

use base 'Net::IMAP::Server::DefaultModel';

sub init {
    my $this = shift;
    my ($ret,@ret);

    if( wantarray ) {
        @ret = $this->SUPER::init(@_);

    } else {
        $ret = $this->SUPER::init(@_);
    }

    {
        # fix a bug in Net::IMAP::Server::Mailbox 1.18
        no warnings;
        die $@ unless
        eval q [
            sub Net::IMAP::Server::Mailbox::unseen {
                my $self = shift;
                return scalar grep { not $_->has_flag('\Seen') } @{ $self->messages };
            }
        1];
    }

    return wantarray ? @ret : $ret;
}

1;
