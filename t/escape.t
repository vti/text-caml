use strict;
use warnings;

use Test::More tests => 4;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render('{{foo}}', {foo => '<b>&bar;</b>'});
is $output => '&lt;b&gt;&amp;bar;&lt;/b&gt;', 'escape HTML by default';

$output = $renderer->render('{{&foo}}', {foo => '<b>&bar;</b>'});
is $output => '<b>&bar;</b>', '& disable escaping';

$renderer = Text::Caml->new(do_not_escape => 1);

$output = $renderer->render('{{foo}}', {foo => '<b>&bar;</b>'});
is $output => '<b>&bar;</b>', 'do_not_escape mode';

$output = $renderer->render('{{&foo}}', {foo => '<b>&bar;</b>'});
is $output => '&lt;b&gt;&amp;bar;&lt;/b&gt;', '& switches between modes';
