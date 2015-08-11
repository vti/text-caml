use strict;
use warnings;

use Test::More tests => 2;

use Text::Caml;

my $builtin = Text::Caml->new(escape_html => undef);
my $custom  = Text::Caml->new(escape_html => \&escape_html_custom);

my $str = '<{o}>';

my $bo = $builtin->render('{{str}}', {str => $str});
my $co = $custom->render('{{str}}', {str => $str});

is $bo => '&lt;{o}&gt;', "built'in escape_func";
is $co => '<&#123;o&#125;>', "custom escape_func";
done_testing;

sub escape_html_custom {
    my $value = shift;

    $value =~ s/{/&#123;/g;
    $value =~ s/}/&#125;/g;

    return $value;
}
