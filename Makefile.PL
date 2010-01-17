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

                (
                    'Class::Accessor'             => 0,
                    'Coro'                        => 0,
                    'DateTime'                    => 0,
                    'DateTime::Format::Mail'      => 0,
                    'DateTime::Format::Strptime'  => 0,
                    'Email::Address'              => 0,
                    'Email::MIME'                 => 1.862,
                    'Email::MIME::ContentType'    => 0,
                    'Email::Simple'               => 1.999,
                    'Encode::IMAPUTF7'            => 0,
                    'MIME::Base64'                => 0,
                    'List::MoreUtils'             => 0,
                    'Net::SSLeay'                 => 0,
                    'Net::Server::Coro'           => 0.3,
                    'Regexp::Common'              => 0,
                    'Test::More'                  => 0,
                    'UNIVERSAL::require'          => 0,

                ) : (),
            )
        },

    ) : ()),
);
