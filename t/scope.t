use strict;
use warnings;

use Test::More tests => 8;

use Text::Caml;

my $renderer = Text::Caml->new(templates_path => 't/templates');

my $output = $renderer->render('{{hello}}', {hello => 'bar'});
is $output => 'bar';

$output = $renderer->render(
    '{{#section}}{{hello}}{{/section}}',
    {   section => 'ok',
        hello   => 'bar'
    }
);
is $output => 'bar';

$output = $renderer->render(
    '{{#section}}{{hello}}{{/section}}',
    {   section => [{foo => 'bar'}],
       hello   => 'bar'
    }
);
is $output => 'bar';

$output = $renderer->render('{{#section}}{{hello}}{{/section}}',
    {section => {hello => 'bar'}, hello => 'foo'});
is $output => 'bar';

$output = $renderer->render('{{#section}}{{hello.bar}}{{/section}}',
    {section => {}, hello => {bar => 'foo'}});
is $output => 'foo';

$output = $renderer->render('{{name}} {{>partial-with-directives}}', {name => 'foo'});
is $output => 'foo Hello foo!';

my @array = (
    { foo => 'a' },
    { foo => 'b' },
);

$output = $renderer->render(
    '{{#array}}{{foo}}{{_idx}}{{/array}}',
    {
       array => \@array
    }
);
is $output => 'a0b1';
ok !defined $array[0]{_idx};
