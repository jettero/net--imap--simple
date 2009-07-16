use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	       => 'Net::IMAP::Simple',
    'VERSION_FROM' => 'Simple.pm',
    AUTHOR         => 'Paul Miller <jettero@cpan.org>',

    PREREQ_PM => {
        'IO::Socket' => 0,
        'IO::Select' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => [qw(imap simple)],
                resources=> {
                    repository => 'http://github.com/jettero/net--imap--simple',
                },
            },

        LICENSE	=> 'Perl Artistic',

        CONFIGURE_REQUIRES => {
            ( $ENV{TEST_AUTHOR}
                || $ENV{AUTOMATED_TESTING} ? # thank you BinGOs
                (map {($_=>0)} qw(DateTime IO::Socket::SSL Net::IMAP::Server Coro Coro::EV)) : ())
        },

    ) : ()),
);
