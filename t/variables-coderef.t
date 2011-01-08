use strict;
use warnings;

use Test::More tests => 2;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render(
    '{{foo}}',
    {   foo => sub {'bar'}
    }
);
is $output => 'bar';

$output = $renderer->render(
    '{{foo a="b" c=bar}}',
    {   foo => sub { join ',', sort values %{$_[2]} },
        bar => 'd'
    }
);
is $output => 'b,d';
