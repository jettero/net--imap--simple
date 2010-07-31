#!/usr/bin/perl

use common::sense;
use Parse::RecDescent;
use Data::Dump qw(dump);

my $grammar = q&
    top: string(s)

    string: '{' /(\d+)/ "}\x0d\x0a" {
        warn "$item[2]";
        $return = length($text) >= $item[2]
                ? substr($text,0,$item[2],"")
                : undef;
    }
&;

my $parser = Parse::RecDescent->new($grammar);

print dump( $parser->top("{4}\x0d\x0atest{2}\x0d\x0a#2{0}\x0d\x0a") ), "\n";


$parser;
