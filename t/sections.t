use strict;
use warnings;

use Test::More tests => 9;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render('{#bool}Hello{/bool}', {bool => 1});
is $output => 'Hello';

$output = $renderer->render('{#bool}Hello{/bool}', {bool => 0});
is $output => '';

$output = $renderer->render("{#bool}\nHello\n{/bool}", {bool => 0});
is $output => '';

$output =
  $renderer->render("{#bool}\nHello\n{/bool}\n{unknown}", {bool => 0});
is $output => '';

$output =
  $renderer->render('{#list}{n}{/list}',
    {list => [{n => 1}, {n => 2}, {n => 3}]});
is $output => '123';

$output = $renderer->render('{#list}{.}{/list}', {list => [1, 2, 3]});
is $output => '123';

$output = $renderer->render('{#foo.list}{.}{/foo.list}',
    {foo => {list => [1, 2, 3]}});
is $output => '123';

$output = $renderer->render('{#list}{n}{/list}', {list => []});
is $output => '';

$output =
  $renderer->render('{#s}one{/s} {#s}{two}{/s} {#s}three{/s}',
    {s => 1, two => 'two'});
is $output => 'one two three';
