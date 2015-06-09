use strict;
use warnings;

use Test::More tests => 8;

use Text::Caml;

my $renderer = Text::Caml->new(templates_path => 't/templates');

my $output = $renderer->render('{{hello}}', {hello => 'bar'});
is $output => 'bar', 'base scope works as expected';

$output = $renderer->render(
    '{{#section}}{{hello}}{{/section}}',
    {   section => 'ok',
        hello   => 'bar'
    }
);
is $output => 'bar', 'section scope falls back on base scope if section is scalar';

$output = $renderer->render(
    '{{#section}}{{hello}}{{/section}}',
    {   section => [{foo => 'bar'}],
       hello   => 'bar'
    }
);
is $output => 'bar', 'section scope falls back on base scope if hello does not exist in section arrayref';

$output = $renderer->render('{{#section}}{{hello}}{{/section}}',
    {section => {hello => 'bar'}, hello => 'foo'});
is $output => 'bar', 'section scope overrides base scope if hello exists in both';

$output = $renderer->render('{{#section}}{{hello.bar}}{{/section}}',
    {section => {}, hello => {bar => 'foo'}});
is $output => 'foo', 'base scope works for more complex declaration {{hello.bar}}';

$output = $renderer->render('{{name}} {{>partial-with-directives}}', {name => 'foo'});
is $output => 'foo Hello foo!', 'base scope works outside and inside partials';

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
is $output => 'a0b1', 'special variable {{_idx}} gives index for array loop';
ok !defined $array[0]{_idx}, '$array[0]{_idx} not inadvertantly created on the hashref';
