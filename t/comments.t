use strict;
use warnings;

use Test::More tests => 5;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output =
  $renderer->render('foo{{! Comment}}bar', {'! Comment' => 'ooops'});
is $output => 'foobar', 'in-line {{! Comment}}';

$output =
  $renderer->render("foo{{!\n Comment\n}}bar", {"!\n Comment\n" => 'ooops'});
is $output => 'foobar', 'multi-line {{! Comment}}';

$output =
  $renderer->render("foo\n{{! Comment}}\nbar", {"! Comment" => 'ooops'});
is $output => "foo\nbar", 'trailing new-line {{! Comment}}';

$output =
  $renderer->render("foo\n   {{! Comment}}\nbar", {"! Comment" => 'ooops'});
is $output => "foo\nbar", 'a comment is not a variable name (with new-line)';

$output =
  $renderer->render("foo {{! Comment}} bar", {"! Comment" => 'ooops'});
is $output => "foo  bar", 'a comment is not a variable name (no new-line)';
