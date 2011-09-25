use strict;
use warnings;

package Foo;

sub new {
    shift;
    bless {@_};
}

sub method { shift->{values} }

package main;

use Test::More tests => 18;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => 1});
is $output => 'Hello';

$output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => Foo->new});
is $output => 'Hello';

$output = $renderer->render('{{#bool.method}}Hello{{/bool.method}}', {bool => Foo->new});
is $output => '';

$output = $renderer->render(
    '{{#bool.method}}Hello{{/bool.method}}',
    {bool => Foo->new(values => 1)}
);
is $output => 'Hello';

$output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => 0});
is $output => '';

$output = $renderer->render("{{#bool}}\nHello\n{{/bool}}", {bool => 0});
is $output => '';

$output =
  $renderer->render("{{#bool}}\nHello\n{{/bool}}\n{{unknown}}", {bool => 0});
is $output => '';

$output =
  $renderer->render('{{#list}}{{n}}{{/list}}',
    {list => [{n => 1}, {n => 2}, {n => 3}]});
is $output => '123';

$output = $renderer->render('{{#list}}{{.}}{{/list}}', {list => [1, 2, 3]});
is $output => '123';

$output = $renderer->render('{{#foo.list}}{{.}}{{/foo.list}}',
    {foo => {list => [1, 2, 3]}});
is $output => '123';

$output = $renderer->render('{{#list}}{{n}}{{/list}}', {list => []});
is $output => '';

$output =
  $renderer->render('{{#list}}{{_idx}}{{/list}}', {list => [1, 2, 3]});
is $output => '012';

$output = $renderer->render('{{#list}}{{#_even}}{{.}}{{/_even}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '13';

$output = $renderer->render('{{#list}}{{#_odd}}{{.}}{{/_odd}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '2';

$output = $renderer->render('{{#list}}{{^_first}}, {{/_first}}{{.}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '1, 2, 3';

$output = $renderer->render('{{#list}}{{.}}{{^_last}}, {{/_last}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '1, 2, 3';

$output =
  $renderer->render('{{#list}}{{#.}}{{.}}{{/.}}{{/list}}', {list => [[1], [2], [3]]});
is $output => '123';

$output =
  $renderer->render('{{#s}}one{{/s}} {{#s}}{{two}}{{/s}} {{#s}}three{{/s}}',
    {s => 1, two => 'two'});
is $output => 'one two three';
