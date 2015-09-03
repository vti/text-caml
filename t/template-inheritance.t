use strict;
use warnings;

use Test::More;

use Text::Caml;

my $renderer = Text::Caml->new(templates_path => 't/templates');

# testing scenario where we provide the replacement content for a block
my $output = $renderer->render('{{<inheritance}}{{$block}}Replaced Value!{{/block}}{{/inheritance}}');
is $output => 'Replaced Value!', 'basic inheritance works correctly';

# testing the scenario where no replacement is provided for a block and must use the default value
$output = $renderer->render('{{<inheritance}}{{/inheritance}}');
is $output => 'Default Value!', 'basic inheritance uses default values if no custom one provided for blocks';

# testing directive use in replacement block
$output = $renderer->render('{{<inheritance}}{{$block}}Hello {{name}}!{{/block}}{{/inheritance}}', {name => 'boss'});
is $output => 'Hello boss!', 'directives work ok in replacement blocks';

# testing directive use in default block values
$output = $renderer->render('{{<inheritance-with-directives}}{{/inheritance-with-directives}}', {value => 'default'});
is $output => 'This is a default value', 'directives work ok in default block values';

# testing a more complex scenario with multiple levels of inheritance
$output = $renderer->render('{{<inheritance-with-recursion}}{{/inheritance-with-recursion}}');
is $output => 'I\'m recursive', 'recursive inheritance works ok';

done_testing;
