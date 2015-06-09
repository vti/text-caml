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

$output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => 1});
is $output => 'Hello', 'boolean section true enters section';

$output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => Foo->new});
is $output => 'Hello', 'boolean section object enters section';

$output = $renderer->render('{{#bool.method}}Hello{{/bool.method}}',
    {bool => Foo->new});
is $output => '', 'boolean section object method call which returns undef does not enter section';

$output = $renderer->render(
    '{{#bool.method}}Hello{{/bool.method}}',
    {bool => Foo->new(values => 1)}
);
is $output => 'Hello', 'boolean section object method call which returns 1 enters section';

$output = $renderer->render('{{#bool}}{{method}}{{/bool}}',
    {bool => Foo->new(values => '1')});
is $output => '1', 'boolean section object method call (with scope) which returns 1 enters section';

$output = $renderer->render('{{#bool}}{{#method}}{{method}}{{/method}}{{/bool}}',
    {bool => Foo->new(values => '1')});
is $output => '1', 'boolean section object method call with existence check {{#method}} which returns 1 enters section';

$output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => 0});
is $output => '', 'boolean section false does not enter section';

$output = $renderer->render("{{#bool}}\nHello\n{{/bool}}", {bool => 0});
is $output => '', 'boolean section false (with new-lines) does not enter section';

$output =
  $renderer->render("{{#bool}}\nHello\n{{/bool}}\n{{unknown}}", {bool => 0});
is $output => '', 'boolean section false (with even more new-lines) does not enter section';

$output =
  $renderer->render('{{#list}}{{n}}{{/list}}',
    {list => [{n => 1}, {n => 2}, {n => 3}]});
is $output => '123', 'list section loops over list with scope';

$output = $renderer->render('{{#list}}{{.}}{{/list}}', {list => [1, 2, 3]});
is $output => '123', 'list section loops over list and {{.}} gives current list item';

$output = $renderer->render('{{#foo.list}}{{.}}{{/foo.list}}',
    {foo => {list => [1, 2, 3]}});
is $output => '123', 'list section {{#foo.list}} loops over list and {{.}} gives current list item';

$output = $renderer->render('{{#list}}{{n}}{{/list}}', {list => []});
is $output => '', 'empty list has no values';

$output =
  $renderer->render('{{#list}}{{_idx}}{{/list}}', {list => [1, 2, 3]});
is $output => '012', 'special variable {{_idx}} gives list item index (zero-based)';

$output = $renderer->render('{{#list}}{{#_even}}{{.}}{{/_even}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '13', 'special check {{_even}} works (based on index)';

$output = $renderer->render('{{#list}}{{#_odd}}{{.}}{{/_odd}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '2', 'special check {{_odd}} works (based on index)';

$output = $renderer->render('{{#list}}{{^_first}}, {{/_first}}{{.}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '1, 2, 3', 'special check {{_first}} checks for index zero';

$output = $renderer->render('{{#list}}{{.}}{{^_last}}, {{/_last}}{{/list}}',
    {list => [1, 2, 3]});
is $output => '1, 2, 3', 'special check {{_last}} checks for last index';

$output = $renderer->render('{{#list}}{{#.}}{{.}}{{/.}}{{/list}}',
    {list => [[1], [2], [3]]});
is $output => '123', 'loop over lists of lists with {{#.}}';

$output = $renderer->render('{{#list}}{{method}}{{/list}}',
    {list => [Foo->new(values => 1), Foo->new(values => 2)]});
is $output => '12', 'list of objects with method calls';

$output =
  $renderer->render('{{#s}}one{{/s}} {{#s}}{{two}}{{/s}} {{#s}}three{{/s}}',
    {s => 1, two => 'TWO'});
is $output => 'one TWO three', 'variable lookup within boolean check scope works';

$output = $renderer->render('{{# bool }}Hello{{/bool}}', {bool => 1});
is $output => 'Hello', 'ignore scpaces {{# bool }}';

done_testing;
