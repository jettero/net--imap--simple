package Net::IMAP::Simple::PipeSocket;

use strict;
use warnings;
use Carp;
use IPC::Open3;
use IO::Select;
use Symbol 'gensym';
use base 'Tie::Handle';

my %inn;
my %out;
my %err;
my %pid;

sub new {
    my $class = shift;
    my $cmd   = shift;

    croak "command (e.g. 'ssh hostname dovecot') argument required" unless $cmd;

    open my $fake, "+>", undef or die "initernal error dealing with blarg: $!";

    my($wtr, $rdr, $err); $err = gensym;
    my $pid  = eval { open3($wtr, $rdr, $err, $cmd) } or croak $@;
    my $this = bless $fake, $class or croak $!;

    $inn{$this} = $rdr;
    $out{$this} = $wtr;
    $err{$this} = $err;
    $pid{$this} = $pid;

    return $this;
}

sub UNTIE   { $_[0]->_waitpid }
sub DESTROY { $_[0]->_waitpid }

sub PRINT {
    my $this = shift;
    my $wtr  = $out{$this};

    print $wtr @_;
}

sub READLINE {
    my $this = shift;
    my $rdr  = $inn{$this};

    <$rdr>
}

sub _waitpid {
    my $this = shift;

    if( my $pid = delete $pid{$this} ) {
        close delete $inn{$this} if exists $inn{$this};
        close delete $out{$this} if exists $out{$this};
        close delete $err{$this} if exists $err{$this};

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
