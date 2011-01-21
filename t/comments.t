use strict;
use warnings;

use Test::More tests => 5;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output =
  $renderer->render('foo{{! Comment}}bar', {'! Comment' => 'ooops'});
is $output => 'foobar';

$output =
  $renderer->render("foo{{!\n Comment\n}}bar", {"!\n Comment\n" => 'ooops'});
is $output => 'foobar';

$output =
  $renderer->render("foo\n{{! Comment}}\nbar", {"! Comment" => 'ooops'});
is $output => "foo\nbar";

$output =
  $renderer->render("foo\n   {{! Comment}}\nbar", {"! Comment" => 'ooops'});
is $output => "foo\nbar";

$output =
  $renderer->render("foo {{! Comment}} bar", {"! Comment" => 'ooops'});
is $output => "foo  bar";
