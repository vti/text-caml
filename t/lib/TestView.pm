package TestView;

use strict;
use warnings;

use base 'Text::Caml';

sub to_hash {
    my $self = shift;

    return {title => $self->{title}, body => $self->{body}};
}

1;
