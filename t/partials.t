use strict;
use warnings;

use Test::More;

use Text::Caml;

my $renderer = Text::Caml->new(templates_path => 't/templates');

my $output = $renderer->render('{{>partial}}');
is $output => 'Hello from partial!', 'partial renders correctly {{>partial}}';

$output = $renderer->render('{{>partial-with-directives}}', {name => 'foo'});
is $output => 'Hello foo!', 'partial can use directives {{>partial-with-directives}}';

$output = $renderer->render('{{>partial-with-recursion}}', {name => 'foo'});
is $output => '*Hello foo!*', 'partials can recurse {{>partial-with-recursion}}';

$output = $renderer->render('{{> partial }}');
is $output => 'Hello from partial!', 'partial call ignores spaces, eg. {{^ partial }}';

done_testing;
