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

open IN, "collected.patch" or die $!;
open OUT, "|-", $^X, patch => '-p1' or die $!;
print OUT $_ while <IN>;
close IN; close OUT;

print "\n\n";

unlink $_ for glob("lib/Net/IMAP/Simple.pm.*");

WriteMakefile(
    NAME         => 'Net::IMAP::Simple::Plus',
    VERSION_FROM => 'Plus.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
);
