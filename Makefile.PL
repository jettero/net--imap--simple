use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::IMAP::Simple',
    'VERSION_FROM' => 'lib/Net/IMAP/Simple.pm', # finds $VERSION
);
