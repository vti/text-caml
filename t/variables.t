use strict;
use warnings;

use Test::More tests => 15;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render('');
is $output => '';

$output = $renderer->render('foo');
is $output => 'foo';

$output = $renderer->render('Hello, [user]!');
is $output => 'Hello, [user]!';

$output = $renderer->render('Hello, {{user}}!');
is $output => 'Hello, !';

$output = $renderer->render('Hello, {{user}}!', {user => 'vti'});
is $output => 'Hello, vti!';

$output = $renderer->render('{{var}}', {var => 1});
is $output => '1';

$output = $renderer->render('{{var}}', {var => 0});
is $output => '0';

$output = $renderer->render('{{var}}', {var => ''});
is $output => '';

$output = $renderer->render('{{var}}', {var => undef});
is $output => '';

$output = $renderer->render('{{var}}', {var => '1 > 2'});
is $output => '1 &gt; 2';

$output = $renderer->render('{{&var}}', {var => '1 > 2'});
is $output => '1 > 2';

$output = $renderer->render('{{{var}}}', {var => '1 > 2'});
is $output => '1 > 2';

$output = $renderer->render('{{foo.bar}}', {foo => {bar => 'baz'}});
is $output => 'baz';

$output = $renderer->render('{{foo.bak}}', {foo => {bar => 'baz'}});
is $output => '';

$output = $renderer->render('{{f1o.bak}}');
is $output => '';
