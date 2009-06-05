package Net::IMAP::Simple;

use strict;
use warnings;

use Carp;
use IO::File;
use IO::Socket;

our $VERSION = "1.1800";

sub new {
    my ( $class, $server, %opts ) = @_;

    my $self = bless { count => -1, } => $class;

    my ( $srv, $prt ) = split( /:/, $server, 2 );
    $prt ||= ( $opts{port} ? $opts{port} : $self->_port );

    $self->{server}           = $srv;
    $self->{port}             = $prt;
    $self->{timeout}          = ( $opts{timeout} ? $opts{timeout} : $self->_timeout );
    $self->{use_v6}           = ( $opts{use_v6} ? 1 : 0 );
    $self->{retry}            = ( $opts{retry} ? $opts{retry} : $self->_retry );
    $self->{retry_delay}      = ( $opts{retry_delay} ? $opts{retry_delay} : $self->_retry_delay );
    $self->{bindaddr}         = $opts{bindaddr};
    $self->{use_select_cache} = $opts{use_select_cache};
    $self->{select_cache_ttl} = $opts{select_cache_ttl};
    $self->{debug}            = $opts{debug};

    # Pop the port off the address string if it's not an IPv6 IP address
    if ( !$self->{use_v6} && $self->{server} =~ /^[A-Fa-f0-9]{4}:[A-Fa-f0-9]{4}:/ && $self->{server} =~ s/:(\d+)$//g ) {
        $self->{port} = $1;
    }

    my $c;
    for ( my $i = 0 ; $i <= $self->{retry} ; $i++ ) {
        if ( $self->{sock} = $self->_connect ) {
            $c = 1;
            last;

        } elsif ( $i < $self->{retry} ) {
            sleep $self->{retry_delay};

            # Critic NOTE: I'm not sure why this was done, but it was removed
            # beucase the critic said it was bad and sleep makes more sense.
            # select( undef, undef, undef, $self->{retry_delay} );
        }
    }

    if ( !$c ) {
        $@ =~ s/IO::Socket::INET6?: //g;
        $Net::IMAP::Simple::errstr = "connection failed $@";
        return;
    }

    $self->_sock->getline();

    return $self;
}

sub _connect {
    my ($self) = @_;
    my $sock;

    if ( $self->{use_v6} ) {
        require IO::Socket::INET6;
        import  IO::Socket::INET6;
    }

    $sock = $self->_sock_from->new(
        PeerAddr => $self->{server},
        PeerPort => $self->{port},
        Timeout  => $self->{timeout},
        Proto    => 'tcp',
        ( $self->{bindaddr} ? { LocalAddr => $self->{bindaddr} } : () )
    );

    return $sock;
}

sub _port        { 143 }
sub _sock        { $_[0]->{sock} }
sub _count       { $_[0]->{count} }
sub _last        { $_[0]->{last} }
sub _timeout     { 90 }
sub _retry       { 1 }
sub _retry_delay { 5 }
sub _sock_from   { $_[0]->{use_v6} ? 'IO::Socket::INET6' : 'IO::Socket::INET' }

sub starttls {
    my ($self) = @_;

    use IO::Socket::SSL; import IO::Socket::SSL;
    use Net::SSLeay;     import Net::SSLeay;

    # $self->{debug} = 1;
    # warn "Processing STARTTLS command";

    $self->_process_cmd(
        cmd   => ['STARTTLS'],
        final => sub {
            Net::SSLeay::load_error_strings();
            Net::SSLeay::SSLeay_add_ssl_algorithms();
            Net::SSLeay::randomize();

            if (
                not IO::Socket::SSL->start_SSL(
                    $self->{sock},
                    SSL_version        => "SSLv3 TLSv1",
                    SSL_startHandshake => 0,
                )
              )
            {
                croak "Couldn't start TLS: " . IO::Socket::SSL::errstr() . "\n";
            }

            $self->_debug( caller, __LINE__, 'starttls', "TLS initialization done" ) if $self->{debug};
        },

        # process => sub { push @lines, $_[0] if $_[0] =~ /^(?: \s+\S+ | [^:]+: )/x },
    );
}

sub login {
    my ( $self, $user, $pass ) = @_;

    return $self->_process_cmd(
        cmd     => [ LOGIN => qq[$user "$pass"] ],
        final   => sub     { 1 },
        process => sub     { },
    );
}

sub select {
    my ( $self, $mbox ) = @_;

    $mbox = $self->current_box unless $mbox;

    $self->{working_box} = $mbox;

    if ( $self->{use_select_cache} && ( time - $self->{BOXES}->{$mbox}->{proc_time} ) <= $self->{select_cache_ttl} ) {
        return $self->{BOXES}->{$mbox}->{messages};
    }

    $self->{BOXES}->{$mbox}->{proc_time} = time;

    my $t_mbox = $mbox;

    $self->_process_cmd(
        cmd => [ SELECT => _escape($t_mbox) ],
        final => sub { $self->{last} = $self->{BOXES}->{$mbox}->{messages} },
        process => sub {
            if ( $_[0] =~ /^\*\s+(\d+)\s+EXISTS/i ) {
                $self->{BOXES}->{$mbox}->{messages} = $1;
            } elsif ( $_[0] =~ /^\*\s+FLAGS\s+\((.*?)\)/i ) {
                $self->{BOXES}->{$mbox}->{flags} = [ split( /\s+/, $1 ) ];
            } elsif ( $_[0] =~ /^\*\s+(\d+)\s+RECENT/i ) {
                $self->{BOXES}->{$mbox}->{recent} = $1;
            } elsif ( $_[0] =~ /^\*\s+OK\s+\[(.*?)\s+(.*?)\]/i ) {
                my ( $flag, $value ) = ( $1, $2 );
                if ( $value =~ /\((.*?)\)/ ) {
                    $self->{BOXES}->{$mbox}->{sflags}->{$flag} = [ split( /\s+/, $1 ) ];
                } else {
                    $self->{BOXES}->{$mbox}->{oflags}->{$flag} = $value;
                }
            }
        },
    ) || return;

    return $self->{last};
}

sub messages {
    my ( $self, $folder ) = @_;
    return $self->select($folder);
}

sub flags {
    my ( $self, $folder ) = @_;

    $self->select($folder);
    return @{ $self->{BOXES}->{ $self->current_box }->{flags} || [] };
}

sub recent {
    my ( $self, $folder ) = @_;

    $self->select($folder);
    return $self->{BOXES}->{ $self->current_box }->{recent};
}

sub unseen {
    my ( $self, $folder ) = @_;

    $self->select($folder);
    return $self->{BOXES}{ $self->current_box }{oflags}{UNSEEN};
}

sub current_box {
    my ($self) = @_;
    return ( $self->{working_box} ? $self->{working_box} : 'INBOX' );
}

sub top {
    my ( $self, $number ) = @_;

    my @lines;
    $self->_process_cmd(
        cmd   => [ FETCH => qq[$number rfc822.header] ],
        final => sub     { \@lines },
        process => sub { push @lines, $_[0] if $_[0] =~ /^(?: \s+\S+ | [^:]+: )/x },
    );
}

sub seen {
    my ( $self, $number ) = @_;

    my $lines = '';
    $self->_process_cmd(
        cmd => [ FETCH => qq[$number (FLAGS)] ],
        final => sub { $lines =~ /\\Seen/i },
        process => sub { $lines .= $_[0] },
    );
}

sub list {
    my ( $self, $number ) = @_;

    my $messages = $number || '1:' . $self->_last;
    my %list;
    $self->_process_cmd(
        cmd => [ FETCH => qq[$messages RFC822.SIZE] ],
        final => sub { $number ? $list{$number} : \%list },
        process => sub {
            if ( $_[0] =~ /^\*\s+(\d+).*RFC822.SIZE\s+(\d+)/i ) {
                $list{$1} = $2;
            }
        },
    );
}

sub get {
    my ( $self, $number ) = @_;

    my @lines;
    $self->_process_cmd(
        cmd => [ FETCH => qq[$number rfc822] ],
        final => sub { pop @lines; \@lines },
        process => sub {
            if ( $_[0] !~ /^\* \d+ FETCH/ ) {
                push @lines, join( ' ', @_ );
            }
        },
    );

}

sub put {
    my ( $self, $mailbox_name, $msg, @flags ) = @_;

    my $size = length $msg;
    if ( ref $msg eq "ARRAY" ) {
        $size = 0;
        $size += length $_ for @$msg;
    }

    @flags = map { split( m/\s+/, $_ ) } @flags;
    @flags = grep { m/^\\\w+\z/ } @flags;

    # @flags = ('\Seen') unless @flags;

    $self->_process_cmd(
        cmd     => [ APPEND => "$mailbox_name (@flags) {$size}" ],
        final   => sub      { 1 },
        process => sub {
            if ($size) {
                my $sock = $self->_sock;
                if ( ref $msg eq "ARRAY" ) {
                    print $sock $_ for @$msg;

                } else {
                    print $sock $msg;
                }
                $size = undef;
                print $sock "\r\n";
            }
        },
    );
}

sub msg_flags {
    my ( $self, $number ) = @_;

    my $lines = '';
    $self->_process_cmd(
        cmd => [ FETCH => qq[$number (FLAGS)] ],
        final => sub { my ($flags) = $lines =~ m/FLAGS \(([^()]+)\)/i; wantarray ? split( m/\s+/, $flags ) : $flags },
        process => sub { $lines .= $_[0] },
    );
}

sub getfh {
    my ( $self, $number ) = @_;

    my $file = IO::File->new_tmpfile;
    my $buffer;
    $self->_process_cmd(
        cmd => [ FETCH => qq[$number rfc822] ],
        final => sub { seek $file, 0, 0; $file },
        process => sub {
            if ( $_[0] !~ /^\* \d+ FETCH/ ) {
                defined($buffer) and print $file $buffer;
                $buffer = $_[0];
            }
        },
    );
}

sub quit {
    my ( $self, $hq ) = @_;
    $self->_send_cmd('EXPUNGE');

    if ( !$hq ) {
        $self->_process_cmd( cmd => ['LOGOUT'], final => sub { }, process => sub { } );
    } else {
        $self->_send_cmd('LOGOUT');
    }

    $self->_sock->close;
    return 1;
}

sub last { shift->_last }

sub delete {
    my ( $self, $number ) = @_;

    $self->_process_cmd(
        cmd     => [ STORE => qq[$number +FLAGS (\\Deleted)] ],
        final   => sub     { 1 },
        process => sub     { },
    );
}

sub _process_list {
    my ( $self, $line ) = @_;
    $self->_debug( caller, __LINE__, '_process_list', $line ) if $self->{debug};

    my @list;
    if ( $line =~ /^\*\s+(LIST|LSUB).*\s+\{\d+\}\s*$/i ) {
        chomp( my $res = $self->_sock->getline );
        $res =~ s/\r//;
        _escape($res);
        push @list, $res;

        $self->_debug( caller, __LINE__, '_process_list', $res ) if $self->{debug};
    } elsif ( $line =~ /^\*\s+(LIST|LSUB).*\s+(\".*?\")\s*$/i
        || $line =~ /^\*\s+(LIST|LSUB).*\s+(\S+)\s*$/i )
    {
        push @list, $2;
    }
    @list;
}

sub mailboxes {
    my ( $self, $box, $ref ) = @_;

    $ref ||= '""';
    my @list;
    if ( !defined $box ) {

        # recurse, should probably follow
        # RFC 2683: 3.2.1.1.  Listing Mailboxes
        return $self->_process_cmd(
            cmd => [ LIST => qq[$ref *] ],
            final => sub { _unescape($_) for @list; @list },
            process => sub { push @list, $self->_process_list( $_[0] ); },
        );
    } else {
        return $self->_process_cmd(
            cmd => [ LIST => qq[$ref $box] ],
            final => sub { _unescape($_) for @list; @list },
            process => sub { push @list, $self->_process_list( $_[0] ) },
        );
    }
}

sub mailboxes_subscribed {
    my ( $self, $box, $ref ) = @_;

    $ref ||= '""';
    my @list;
    if ( !defined $box ) {

        # recurse, should probably follow
        # RFC 2683: 3.2.2.  Subscriptions
        return $self->_process_cmd(
            cmd => [ LSUB => qq[$ref *] ],
            final => sub { _unescape($_) for @list; @list },
            process => sub { push @list, $self->_process_list( $_[0] ) },
        );
    } else {
        return $self->_process_cmd(
            cmd => [ LSUB => qq[$ref $box] ],
            final => sub { _unescape($_) for @list; @list },
            process => sub { push @list, $self->_process_list( $_[0] ) },
        );
    }
}

sub create_mailbox {
    my ( $self, $box ) = @_;
    _escape($box);

    return $self->_process_cmd(
        cmd     => [ CREATE => $box ],
        final   => sub      { 1 },
        process => sub      { },
    );
}

sub expunge_mailbox {
    my ( $self, $box ) = @_;
    return if !$self->select($box);

    return $self->_process_cmd(
        cmd     => ['EXPUNGE'],
        final   => sub { 1 },
        process => sub { },
    );
}

sub delete_mailbox {
    my ( $self, $box ) = @_;
    _escape($box);

    return $self->_process_cmd(
        cmd     => [ DELETE => $box ],
        final   => sub      { 1 },
        process => sub      { },
    );
}

sub rename_mailbox {
    my ( $self, $old_box, $new_box ) = @_;
    _escape($old_box);
    _escape($new_box);

    return $self->_process_cmd(
        cmd     => [ RENAME => qq[$old_box $new_box] ],
        final   => sub      { 1 },
        process => sub      { },
    );
}

sub folder_subscribe {
    my ( $self, $box ) = @_;
    $self->select($box);    # XXX does it matter if this fails?
    _escape($box);

    return $self->_process_cmd(
        cmd     => [ SUBSCRIBE => $box ],
        final   => sub         { 1 },
        process => sub         { },
    );
}

sub folder_unsubscribe {
    my ( $self, $box ) = @_;
    $self->select($box);
    _escape($box);

    return $self->_process_cmd(
        cmd     => [ UNSUBSCRIBE => $box ],
        final   => sub           { 1 },
        process => sub           { },
    );
}

sub copy {
    my ( $self, $number, $box ) = @_;
    _escape($box);

    return $self->_process_cmd(
        cmd     => [ COPY => qq[$number $box] ],
        final   => sub    { 1 },
        process => sub    { },
    );
}

sub errstr {
    return $_[0]->{_errstr};
}

sub _nextid { ++$_[0]->{count} }

sub _escape {
    $_[0] =~ s/\\/\\\\/g;
    $_[0] =~ s/\"/\\\"/g;
    $_[0] = "\"$_[0]\"";
}

sub _unescape {
    $_[0] =~ s/^"//g;
    $_[0] =~ s/"$//g;
    $_[0] =~ s/\\\"/\"/g;
    $_[0] =~ s/\\\\/\\/g;
}

sub _send_cmd {
    my ( $self, $name, $value ) = @_;
    my $sock = $self->_sock;
    my $id   = $self->_nextid;
    my $cmd  = "$id $name" . ( $value ? " $value" : "" ) . "\r\n";

    $self->_debug( caller, __LINE__, '_send_cmd', $cmd ) if $self->{debug};

    { local $\; print $sock $cmd; }
    return ( $sock => $id );
}

sub _cmd_ok {
    my ( $self, $res ) = @_;
    my $id = $self->_count;

    $self->_debug( caller, __LINE__, '_send_cmd', $res ) if $self->{debug};

    if ( $res =~ /^$id\s+OK/i ) {
        return 1;
    } elsif ( $res =~ /^$id\s+(?:NO|BAD)(?:\s+(.+))?/i ) {
        $self->_seterrstr( $1 || 'unknown error' );
        return 0;
    } else {
        $self->_seterrstr("warning unknown return string: $res");
        return;
    }
}

sub _read_multiline {
    my ( $self, $sock, $count ) = @_;

    my @lines;
    my $read_so_far = 0;
    while ( $read_so_far < $count ) {
        push @lines, $sock->getline;
        $read_so_far += length( $lines[-1] );
    }
    if ( $self->{debug} ) {
        for ( my $i = 0 ; $i < @lines ; $i++ ) {
            $self->_debug( caller, __LINE__, '_read_multiline', "[$i] $lines[$i]" );
        }
    }

    return @lines;
}

sub _process_cmd {
    my ( $self, %args ) = @_;
    my ( $sock, $id )   = $self->_send_cmd( @{ $args{cmd} } );

    my $res;
    while ( $res = $sock->getline ) {
        $self->_debug( caller, __LINE__, '_process_cmd', $res ) if $self->{debug};

        if ( $res =~ /^\*.*\{(\d+)\}$/ ) {
            $args{process}->($res);
            $args{process}->($_) foreach $self->_read_multiline( $sock, $1 );
        } else {
            my $ok = $self->_cmd_ok($res);
            if ( defined($ok) && $ok == 1 ) {
                return $args{final}->($res);
            } elsif ( defined($ok) && !$ok ) {
                return;
            } else {
                $args{process}->($res);
            }
        }
    }
}

sub _seterrstr {
    my ( $self, $err ) = @_;
    $self->{_errstr} = $err;
    $self->_debug( caller, __LINE__, '_seterrstr', $err ) if $self->{debug};
    return;
}

sub _debug {
    my ( $self, $package, $filename, $line, $dline, $routine, $str ) = @_;

    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\cM/^M/g;

    $line = "[$package :: $filename :: $line\@$dline -> $routine] $str\n";
    if ( ref( $self->{debug} ) eq 'GLOB' ) {
        print { $self->{debug} } $line;
    } else {
        print STDOUT $line;
    }
}

"True";
