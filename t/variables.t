use strict;
use warnings;

package Foo;

sub new {
    shift;
    bless {@_};
}
sub method { shift->{bar} }

package main;

use Test::More tests => 16;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render('');
is $output => '', 'empty string renders as empty';

$output = $renderer->render('foo');
is $output => 'foo', 'bare "foo" string renders as "foo"';

$output = $renderer->render('Hello, [user]!');
is $output => 'Hello, [user]!', 'cannot access variable with square brackets [user]';

$output = $renderer->render('Hello, {{user}}!');
is $output => 'Hello, !', 'non-existent variable lookup renders as empty string {{user}}';

$output = $renderer->render('Hello, {{user}}!', {user => 'vti'});
is $output => 'Hello, vti!', 'variable lookup to string renders as string {{user}}';

$output = $renderer->render('{{var}}', {var => 1});
is $output => '1', 'variable lookup to number renders as number {{var}}';

$output = $renderer->render('{{var}}', {var => 0});
is $output => '0', 'variable lookup to zero (0) renders as number {{var}}';

$output = $renderer->render('{{var}}', {var => ''});
is $output => '', 'variable lookup to empty string renders as empty string {{var}}';

$output = $renderer->render('{{var}}', {var => undef});
is $output => '', 'variable lookup as undef renders as empty string {{var}}';

$output = $renderer->render('{{var}}', {var => '1 > 2'});
is $output => '1 &gt; 2', 'HTML escaping of ">" renders as "&gt;"';

$output = $renderer->render('{{&var}}', {var => '1 > 2'});
is $output => '1 > 2', '{{&var}} turns off HTML escaping';

$output = $renderer->render('{{{var}}}', {var => '1 > 2'});
is $output => '1 > 2', '{{{var}}} turns off HTML escaping';

$output = $renderer->render('{{foo.bar}}', {foo => {bar => 'baz'}});
is $output => 'baz', '{{foo.bar}} variable lookup descends into hashref';

$output = $renderer->render('{{foo.bak}}', {foo => {bar => 'baz'}});
is $output => '', '{{foo.bak}} non-existent key renders as empty string';

$output = $renderer->render('{{f1o.bak}}');
is $output => '', '{{foo.bak}} non-existent hashref foo renders as empty string';

$output = $renderer->render('{{foo.method}}', {foo => Foo->new(bar => 'baz')});
is $output => 'baz', '{{foo.method}} object method call renders as return value of method';
