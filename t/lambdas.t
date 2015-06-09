use strict;
use warnings;

use Test::More tests => 7;

use Text::Caml;

my $renderer = Text::Caml->new;
my $output;

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub { }
    }
);
is $output => '', 'empty sub works';

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub {0}
    }
);
is $output => '0', 'sub returning "0" renders as "0"';

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub {'text'}
    }
);
is $output => 'text', 'sub returning "text" renders as "text"';

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub {'{{var}}'},
        var   => 'text'
    }
);
is $output => 'text', 'sub returning partial "{{var}}" renders as expected';

$output = $renderer->render(
    '{{#lamda}}Hello{{/lamda}}',
    {   lamda => sub {'{{var}}'},
        var   => 'text'
    }
);
is $output => 'text', 'sub can be used as {{#lambda}}';

my $wrapped = sub {
    my $self = shift;
    my $text = shift;

    return '<b>' . $self->render($text, @_) . '</b>';
};

$output = $renderer->render(<<'EOF', {name => 'Willy', wrapped => $wrapped});
{{#wrapped}}
{{name}} is awesome.
{{/wrapped}}
EOF
is $output => "<b>Willy is awesome.</b>", 'sub takes renderer as first parameter and template text as second parameter';

$output = $renderer->render(<<'EOF', {wrapper => sub {$_[1] =~ s/r/z/; $_[1]}, list => [qw/foo bar/]});
{{#list}}
  {{#wrapper}}
    {{.}}
  {{/wrapper}}
{{/list}}
EOF
like $output => qr/foo\s+baz/, 'sub can manipulate the template text directly';
