use ExtUtils::MakeMaker;
use IO::Zlib;
use Archive::Tar;

my $tar = Archive::Tar->new;
   $tar->read('Net-IMAP-Simple-1.17.tar.gz', 1);
   $tar->extract_file('Net-IMAP-Simple-1.17/lib', 'lib');

WriteMakefile(
    NAME         => 'Net::IMAP::Simple::Plus',
    VERSION_FROM => 'lib/Net/IMAP/Simple.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
);
