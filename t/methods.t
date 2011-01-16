use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use TestView;

my $view = TestView->new(title => 'Hello', body => 'there!');

is $view->render('{.date}',                          {}) => time;
is $view->render('{#.date}ok{/.date}',               {}) => 'ok';
is $view->render('{.join(1, 2, 3)}',                 {}) => '1,2,3';
is $view->render('{#.params(1, 2, 3)}{.}{/.params}', {}) => '123';
