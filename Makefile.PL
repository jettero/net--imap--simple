use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	       => 'Net::IMAP::Simple',
    'VERSION_FROM' => 'Simple.pm',
    AUTHOR         => 'Paul Miller <jettero@cpan.org>',

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => [qw(imap simple)],
                resources=> {
                    repository => 'http://github.com/jettero/net--imap--simple',
                },
            },

        LICENSE	=> 'Perl Artistic',
    ) : ()),
);
