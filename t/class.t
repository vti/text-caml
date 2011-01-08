use strict;
use warnings;

use Test::More tests => 1;

use lib 't/lib';

use TestView;

my $view = TestView->new(title => 'Hello', body => 'there!');
$view->set_format('html');
$view->set_templates_path('t/templates');

my $expected = <<'EOF';
<html>
    <head>
        <title>Hello</title>
    </head>
    <body>
        there!
    </body>
</html>
EOF
chomp $expected;

is $view->render => $expected;
