
# load the module
use Net::IMAP::Server::Mailbox;

# hack in extra flag support by redefining the method

no warnings 'redefine';

my $old_csf;
BEGIN { $old_csf = \&Net::IMAP::Server::Mailbox::can_set_flag; }
sub Net::IMAP::Server::Mailbox::can_set_flag {
    my ($this, $flag) = @_;

    return 1 if $flag =~ m/^[\w%\$\\\^]\S*$/;

    goto &$old_csf;
}

