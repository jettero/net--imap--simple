use strict;
use warnings;

use Test;

use Net::IMAP::Simple;

plan tests => 1;

my @a = sort { rand()<=>rand() } (1 .. 50, 90 .. 99, 1000 .. 1010, 3..10);
ok( Net::IMAP::Simple->list2range(@a), "1:50,90:99,1000:1010" );
