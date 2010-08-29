package Net::IMAP::Simple::PipeSocket;

use strict;
use warnings;
use Carp;
use IPC::Open3;
use IO::Select;
use Symbol 'gensym';
use base 'Tie::Handle';

sub new {
    my $class = shift;
    my $cmd   = shift;

    croak "command (e.g. 'ssh hostname dovecot') argument required" unless $cmd;

    open my $fake, "+>", undef or die "initernal error dealing with blarg: $!";

    my($wtr, $rdr, $err); $err = gensym;
    my $pid = eval { open3($wtr, $rdr, $err, $cmd) } or croak $@;
    my $sel = IO::Select->new($err);

    my $this = tie *{$fake}, $class,
        (pid=>$pid, wtr=>$wtr, rdr=>$rdr, err=>$err, sel=>$sel)
            or croak $!;

    return $fake;
}

sub UNTIE   { $_[0]->_waitpid }
sub DESTROY { $_[0]->_waitpid }

sub TIEHANDLE {
    my $class = shift;
    my $this  = bless {@_}, $class;

    return $this;
}

sub _chkerr {
    my $this = shift;
    my $sel = $this->{sel};

    while( my @rdy = $sel->can_read ) {
        for my $fh (@rdy) {
            if( eof($fh) ) {
                $sel->remove($fh);
                next;
            }
            my $line = <$fh>;
            warn "PIPE ERR: $line";
        }
    }
}

sub PRINT {
    my $this = shift;
    my $wtr  = $this->{wtr};

    $this->_chkerr;
    print $wtr @_;
}

sub READLINE {
    my $this = shift;
    my $rdr  = $this->{rdr};

    $this->_chkerr;
    <$rdr>
}

sub _waitpid {
    my $this = shift;

    if( my $pid = delete $this->{pid} ) {
        for my $key (qw(wtr rdr err)) {
            close delete $this->{$key} if exists $this->{$key};
        }

        kill 1, $pid;
        # doesn't really matter if this works... we hung up all the
        # filehandles, so ... it's probably dead anyway.

        waitpid( $pid, 0 );
        my $child_exit_status = $? >> 8;
        return $child_exit_status;
    }

    return;
}

1;

__END__

=head1 NAME

Net::IMAP::Simple::PipeSocket - a little wrapper around IPC-Open3 that feels like a socket

=head1 SYNOPSIS

This module is really just a wrapper around IPC-Open3 that can be dropped in
place of a socket handle.  The L<Net::IMAP::Simple> code assumes the socket is
always a socket and is never a pipe and re-writing it all would be horrible.

This abstraction is used only for that purpose.
