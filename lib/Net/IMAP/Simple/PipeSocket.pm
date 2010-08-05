package Net::IMAP::Simple::PipeSocket;

use strict;
use warnings;
use Carp;
use IPC::Open3;
use IO::Select;

sub new {
    my $class = shift;
    my $this  = bless(ref($_[0]) ? $_[0] : {@_}, $class);

    croak "cmd=>'ssh imap-host blarg' is a required argument" unless $this->{cmd};

    return $this;
}

__END__

=head1 NAME

Net::IMAP::Simple::PipeSocket - a little wrapper around IPC-Open3 that feels like a socket

=head1 SYNOPSIS

This module is really just a wrapper around IPC-Open3 that can be dropped in
place of a socket handle.  The L<Net::IMAP::Simple> code assumes the socket is
always a socket and is never a pipe and re-writing it all would be horrible.

This abstraction is used only for that purpose.
