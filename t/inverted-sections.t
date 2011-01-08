use strict;
use warnings;

use Test::More tests => 1;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render(<<'EOF', {repo => []});
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
{{^repo}}
  No repos :(
{{/repo}}
EOF
is $output => '  No repos :(';
