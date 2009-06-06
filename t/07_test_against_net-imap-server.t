
use Test;

plan tests => 1;

if( my $pid = fork ) {
    # run tests here
    ok(1);
    waitpid $pid;
    exit 0;
}

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

