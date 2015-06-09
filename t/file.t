use strict;
use warnings;

use Test::More tests => 4;

use Text::Caml;

use Cwd ();
use File::Basename ();
use File::Spec     ();

my $renderer = Text::Caml->new;
my $templates_path =
  File::Spec->catfile(File::Basename::dirname(__FILE__), 'templates');

my $output =
  $renderer->render_file(File::Spec->catfile($templates_path, 'partial'));
is $output, 'Hello from partial!', "partial rendered from relative path ($templates_path)";

$renderer = Text::Caml->new;
$templates_path = Cwd::abs_path($templates_path);

$output =
  $renderer->render_file(File::Spec->catfile($templates_path, 'partial'));
is $output, 'Hello from partial!', "partial rendered from full path ($templates_path)";

$renderer = Text::Caml->new(templates_path => $templates_path);

$output = $renderer->render_file('partial');
is $output, 'Hello from partial!', "partial rendered from renderer path ($templates_path)";

eval { $output = $renderer->render_file('no_such_file') };
ok $@, 'exception thrown on non-existent partial file';
