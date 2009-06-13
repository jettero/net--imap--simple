
package t7lib::Connection;

use strict;
use warnings;

use base 'Net::IMAP::Server::Connection';

sub greeting {
    my $self = shift;

    return $self->untagged_response('OK Net::IMAP::Simple Test Server');
}



"Connect!";
