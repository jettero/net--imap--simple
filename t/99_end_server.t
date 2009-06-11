
use strict;
use warnings;
use Test;

plan tests => my $tests = 1;

# NOTE: this is pretty sloppy, but it probably works much of the time.
# suggestions welcome.

if( -f "imap_server.pid" ) {
    my $pid = do {
        local $/; my $p;
        open $p, "imap_server.pid" and $p = <$p>; chomp $p;
        $p;
    };

    if( $pid ) {
        for my $i (qw(15 2 9 11)) {
            kill $i, $pid;
        }
    }

    unlink "imap_server.pid";
    ok(1);

} else {
    skip(1,1,1);
}
