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

is $renderer->render($template, {repo => []}) => '  No repos :(', 'inverted section {{^repo}} works for emtpy arrayref';

is $renderer->render($template, {repo => [{name => 'repo'}]}) =>
  '  <b>repo</b>', 'inverted section {{^repo}} not matched for non-empty arrayref';

$template = <<'EOF';
{{text}}
{{^text}}
  No text
{{/text}}
EOF

is $renderer->render($template, {text => 'exists'}) => "exists\n", 'inverted section {{^text}} not matched for non-empty string';
is $renderer->render($template, {text => ''}) => '  No text', 'inverted section {{^text}} matched for empty string';

$template = <<'EOF';
{{text.body}}
{{^text.body}}
  Text not exists
{{/text.body}}
EOF

is $renderer->render($template, {text => {body => 'text exists'}}) => "text exists\n", 'inverted section {{^text.body}} not matched for non-empty hashref';
is $renderer->render($template, {text => {body => ''}}), '  Text not exists', 'inverted section {{^text.body}} matched for empty string in non-empty hashref';
