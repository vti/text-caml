use strict;
use warnings;

use Test::More tests => 6;

use Text::Caml;

my $renderer = Text::Caml->new;

my $template = <<'EOF';
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
{{^repo}}
  No repos :(
{{/repo}}
EOF

is $renderer->render($template, {repo => []}) => '  No repos :(';

is $renderer->render($template, {repo => [{name => 'repo'}]}) =>
  '  <b>repo</b>';

$template = <<'EOF';
{{text}}
{{^text}}
  No text
{{/text}}
EOF

is $renderer->render($template, {text => 'exists'}) => "exists\n";
is $renderer->render($template, {text => ''}) => '  No text';

$template = <<'EOF';
{{text.body}}
{{^text.body}}
  Text not exists
{{/text.body}}
EOF

is $renderer->render($template, {text => {body => 'text exists'}}) => "text exists\n";
is $renderer->render($template, {text => {body => ''}}), '  Text not exists';
