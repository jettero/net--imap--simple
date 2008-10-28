use ExtUtils::MakeMaker;
use IO::Zlib;
use Archive::Tar;

my $tar = Archive::Tar->new;
   $tar->read('Net-IMAP-Simple-1.17.tar.gz', 1);

for my $f ($tar->list_files) {
    next unless $f =~ m/1\.17\/(?:lib|t)/;

    my $x = $f;
       $x =~ s/^Net-IMAP-Simple-1\.17\///;

    $tar->extract_file($f, $x);
}

die "problem extracting Net::IMAP::Simple" unless -d 'lib' and -d 't';

print "\n\npatching ...\n\n";

patcher("collect1.patch", '-p1');
patcher("collect2.patch", '-p1');
patcher("corion.patch");
patcher("useless-hash-bug.patch");
patcher("10-28-08.flags-bug.patch", '-p1');

sub patcher {
    my ($file, @switches) = @_;

    return if -f ".enable_skipper" and $ENV{SKIP_PATCH} and $file =~ m/$ENV{SKIP_PATCH}/;

    open IN, $file or die $!;
    open OUT, "|-", $^X, patch => @switches or die $!;
    print OUT $_ while <IN>;
    close IN; close OUT;

    unlink $_ for glob("lib/Net/IMAP/Simple.pm.*"); # some patches add .orig
    unlink $_ for glob("lib/Net/IMAP/Simple.pm[A-Za-z]*"); # some add Orig
}

print "\n\n";

WriteMakefile(
    NAME         => 'Net::IMAP::Simple::Plus',
    VERSION_FROM => 'Plus.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',

    clean => { FILES => ".devnull" }
);
