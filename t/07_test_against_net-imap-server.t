
use Test;

plan tests => 1;

if( my $pid = fork ) {
    # run tests here
    ok(1);
    waitpid $pid, 0;
    exit 0;
}

no warnings;
close STDOUT; close STDERR;
open STDERR, ">>informal-imap-server-dump.log";
open STDOUT, ">>informal-imap-server-dump.log";
# (we don't really care if the above fails...)

require Net::IMAP::Server;
import  Net::IMAP::Server;

Net::IMAP::Server->new(
    port        => 7000,
    ssl_port    => 8000,
  # auth_class  => "Your::Auth::Class",
  # model_class => "Your::Model::Class",
  # user        => "nobody",
  # group       => "nobody",
)->run;

