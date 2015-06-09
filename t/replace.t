use strict;
use warnings;

use Test::More tests => 1;

use Text::Caml;

my $renderer = Text::Caml->new;

my $output = $renderer->render('{{-hello}}');
is $output => '{{hello}}', 'can escape with {{-hello}} for literal {{hello}}';
