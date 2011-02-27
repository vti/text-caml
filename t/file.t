use strict;
use warnings;

use Test::More tests => 2;

use Text::Caml;

use File::Basename ();
use File::Spec     ();

my $renderer =
  Text::Caml->new(templates_path =>
      File::Spec->catfile(File::Basename::dirname(__FILE__), 'templates'));

my $output = $renderer->render_file('partial');
is $output, 'Hello from partial!';

eval {$output = $renderer->render_file('no_such_file')};
ok $@;

