use strict;
use warnings;

use Test::More tests => 6;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub { }
    }
);
is $output => '';

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub {0}
    }
);
is $output => '0';

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub {'text'}
    }
);
is $output => 'text';

$output = $renderer->render(
    '{{lamda}}',
    {   lamda => sub {'{{var}}'},
        var   => 'text'
    }
);
is $output => 'text';

$output = $renderer->render(
    '{{#lamda}}Hello{{/lamda}}',
    {   lamda => sub {'{{var}}'},
        var   => 'text'
    }
);
is $output => 'text';

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
is $output => "<b>Willy is awesome.</b>";
