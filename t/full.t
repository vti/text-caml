use strict;
use warnings;

use Test::More tests => 1;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render(
    <<'EOF', {name => 'Chris', value => 10000, taxed_value => 10000 - (10000 * 0.4), in_ca => 1});
Hello {{name}}
You have just won ${{value}}!
{{#in_ca}}
Well, ${{taxed_value}}, after taxes.
{{/in_ca}}
EOF

my $expected = <<'EOF';
Hello Chris
You have just won $10000!
Well, $6000, after taxes.
EOF
chomp $expected;

is $output => $expected;
