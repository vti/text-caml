use strict;
use warnings;

package Foo;

sub new {
    shift;
    bless {@_};
}

sub method { shift->{values} }

package main;

use Test::More;

use Text::Caml;

my $renderer = Text::Caml->new;
my $output;

$output = $renderer->render(do {local $/; <DATA>}, {
    h => {
        foo => { a => 42, b => 43, },
        bar => { a => 52, b => 53, }}});

is $output => 'bar5253foo4243', 'iteration over hash keys';

done_testing;

__DATA__
{{#h.keys}}
{{.}}{{a}}{{b}}
{{/h.keys}}
