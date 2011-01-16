package TestView;

use strict;
use warnings;

use base 'Text::Caml';

sub date {time}

sub join {
    my $self = shift;

    return join ',' => @_;
}

sub params {
    shift;
    return [@_];
}

sub to_hash {
    my $self = shift;

    return {title => $self->{title}, body => $self->{body}};
}

1;
