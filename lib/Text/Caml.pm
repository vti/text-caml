package Text::Caml;

use strict;
use warnings;

require Scalar::Util;
use File::Spec ();

our $VERSION = '0.12';

our $LEADING_SPACE  = qr/(?:\n [ ]*)?/x;
our $TRAILING_SPACE = qr/(?:[ ]* \n)?/x;
our $START_TAG      = qr/{{/x;
our $END_TAG        = qr/}}/x;

our $START_OF_PARTIAL          = quotemeta '>';
our $START_OF_SECTION          = quotemeta '#';
our $START_OF_INVERTED_SECTION = quotemeta '^';
our $END_OF_SECTION            = quotemeta '/';

my  %CACHE = ();

sub croak {require Carp; goto &Carp::croak}

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;
    $self->{use_cache} = $params{use_cache} ||= 0;
    $self->{cache} = \%CACHE;
    $self->{templates_path}            = $params{templates_path};
    $self->{default_partial_extension} = $params{default_partial_extension};
    $self->escape_func($params{escape_func}) if exists $params{escape_func};
    $self->set_templates_path('.')
      unless $self->templates_path;

    return $self;
}

sub templates_path { $_[0]->{templates_path} }
sub set_templates_path { $_[0]->{templates_path} = $_[1] }

sub render {
    my $self     = shift;
    my $template = shift;
    my $context  = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    $self->_parse($template, $context);
}

sub render_file {
    my $self     = shift;
    my $template = shift;
    my $context  = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    $template = $self->_slurp_template($template);
    return $self->_parse($template, $context);
}

sub escape_html {
    my $self = shift;
    return '' unless defined $_[0];
    $self->escape_func->($_[0]);
}

sub escape_func {
    my $self = shift;

    unless (defined $self->{escape_func}) {
        if (@_ && ref($_[0]) eq 'CODE') {
            $self->{escape_func} = $_[0];
        }
        else {
            $self->{escape_func} = sub {
                my $value = shift;

                $value =~ s/&/&amp;/g;
                $value =~ s/</&lt;/g;
                $value =~ s/>/&gt;/g;
                $value =~ s/"/&quot;/g;

                return $value;
            };
        }
    }

    $self->{escape_func};
}

sub use_cache {
    my $self = shift;
    $self->{use_cache} = $_[0] if @_;
    $self->{use_cache};
}

sub _parse {
    my $self     = shift;
    my $template = shift;
    my $context  = shift;

    my $output = '';

    pos $template = 0;
    while (pos $template < length $template) {
        if ($template =~ m/($LEADING_SPACE)?\G $START_TAG /gcxms) {
            my $chunk = '';

            my $leading_newline = !!$1;

            # Tripple
            if ($template =~ m/\G { (.*?) } $END_TAG/gcxms) {
                $chunk .= $self->_parse_tag($1, $context);
            }

            # Replace
            elsif ($template =~ m/\G - (.*?) $END_TAG/gcxms) {
                $chunk .= '{{' . $1 . '}}';
            }

            # Comment
            elsif ($template =~ m/\G ! .*? $END_TAG/gcxms) {
            }

            # Section
            elsif ($template
                =~ m/\G $START_OF_SECTION \s* (.*?) \s* $END_TAG ($TRAILING_SPACE)?/gcxms
              )
            {
                my $name           = $1;
                my $end_of_section = $name;

                if ($template
                    =~ m/\G (.*?) ($LEADING_SPACE)? $START_TAG $END_OF_SECTION $end_of_section $END_TAG ($TRAILING_SPACE)?/gcxms
                  )
                {
                    $chunk .= $self->_parse_section($name, $1, $context);
                }
                else {
                    croak("Section's '$name' end not found");
                }
            }

            # Inverted section
            elsif ($template
                =~ m/\G $START_OF_INVERTED_SECTION (.*?) $END_TAG ($TRAILING_SPACE)?/gcxms
              )
            {
                my $name = $1;

                if ($template
                    =~ m/ \G (.*?) ($LEADING_SPACE)? $START_TAG $END_OF_SECTION $name $END_TAG ($TRAILING_SPACE)?/gcxms
                  )
                {
                    $chunk
                      .= $self->_parse_inverted_section($name, $1, $context);
                }
                else {
                    croak("Section's '$name' end not found");
                }
            }

            # End of section
            elsif ($template =~ m/\G $END_OF_SECTION (.*?) $END_TAG/gcxms) {
                croak("Unexpected end of section '$1'");
            }

            # Partial
            elsif ($template =~ m/\G $START_OF_PARTIAL \s* (.*?) \s* $END_TAG/gcxms) {
                $chunk .= $self->_parse_partial($1, $context);
            }

            # Tag
            elsif ($template =~ m/\G (.*?) $END_TAG/gcxms) {
                $chunk .= $self->_parse_tag_escaped($1, $context);
            }
            else {
                croak("Can't find where tag is closed");
            }

            if ($chunk ne '') {
                $output .= $chunk;
            }
            elsif ($output eq '' || $leading_newline) {
                if ($template =~ m/\G $TRAILING_SPACE/gcxms) {
                    $output =~ s/[ ]*\z//xms;
                }
            }
        }

        # Text before tag
        elsif ($template =~ m/\G (.*?) (?=$START_TAG\{?)/gcxms) {
            $output .= $1;
        }

        # Other text
        else {
            $output .= substr($template, pos($template));
            last;
        }
    }

    return $output;
}

sub _parse_tag {
    my $self = shift;
    my ($name, $context) = @_;

    my $value;
    my %args;

    # Current element
    if ($name eq '.') {
        return '' if $self->_is_empty($context, $name);

        $value = $context->{$name};
    }

    else {
        $value = $self->_get_value($context, $name);
    }

    if (ref $value eq 'CODE') {
        my $content = $value->($self, '', $context);
        $content = '' unless defined $content;
        return $self->_parse($content, $context);
    }

    return $value;
}

sub _find_value {
    my $self = shift;
    my ($context, $name) = @_;

    my @parts = split /\./ => $name;

    my $value = $context;

    foreach my $part (@parts) {
        if (   exists $value->{'_with'}
            && Scalar::Util::blessed($value->{'_with'})
            && $value->{'_with'}->can($part))
        {
            $value = $value->{'_with'}->$part;
            next;
        }

        if (   exists $value->{'.'}
            && Scalar::Util::blessed($value->{'.'})
            && $value->{'.'}->can($part))
        {
            $value = $value->{'.'}->$part;
            next;
        }

        return undef if $self->_is_empty($value, $part);
        $value =
          Scalar::Util::blessed($value) ? $value->$part : $value->{$part};
    }

    return \$value;
}

sub _get_value {
    my $self = shift;
    my ($context, $name) = @_;

    if ($name eq '.') {
        return '' if $self->_is_empty($context, $name);
        return $context->{$name};
    }

    my $value = $self->_find_value($context, $name);

    return $value ? $$value : '';
}

sub _parse_tag_escaped {
    my $self = shift;
    my ($tag, $context) = @_;

    my $do_not_escape;
    if ($tag =~ s/\A \&//xms) {
        $do_not_escape = 1;
    }

    my $output = $self->_parse_tag($tag, $context);

    $output = $self->escape_html($output) unless $do_not_escape;

    return $output;
}

sub _parse_section {
    my $self = shift;
    my ($name, $template, $context) = @_;

    my $value = $self->_get_value($context, $name);

    my $output = '';

    if (ref $value eq 'HASH') {
        $output .= $self->_parse($template, {%$context, %$value});
    }
    elsif (ref $value eq 'ARRAY') {
        my $idx = 0;
        foreach my $el (@$value) {
            my %subcontext = ref $el eq 'HASH' ? %$el : ('.' => $el);
            $subcontext{'_idx'} = $idx;

            $subcontext{'_even'} = $idx % 2 == 0;
            $subcontext{'_odd'}  = $idx % 2 != 0;

            $subcontext{'_first'} = $idx == 0;
            $subcontext{'_last'}  = $idx == $#$value;

            $output .= $self->_parse($template, {%$context, %subcontext});

            $idx++;
        }
    }
    elsif (ref $value eq 'CODE') {
        $template = $self->_parse($template, $context);
        $output
          .= $self->_parse($value->($self, $template, $context), $context);
    }
    elsif (ref $value) {
        $output .= $self->_parse($template, {%$context, _with => $value});
    }
    elsif ($value) {
        $output .= $self->_parse($template, $context);
    }

    return $output;
}

sub _parse_inverted_section {
    my $self = shift;
    my ($name, $template, $context) = @_;

    my $value = $self->_find_value($context, $name);
    return $self->_parse($template, $context)
      unless defined $value;

    $value = $$value;
    my $output = '';

    if (ref $value eq 'HASH') {
    }
    elsif (ref $value eq 'ARRAY') {
        return '' if @$value;

        $output .= $self->_parse($template, $context);
    }
    elsif (!$value) {
        $output .= $self->_parse($template, $context);
    }

    return $output;
}

sub _parse_partial {
    my $self = shift;
    my ($template, $context) = @_;

    if (my $ext = $self->{default_partial_extension}) {
        $template = "$template.$ext";
    }

    my $content = $self->_slurp_template($template);

    return $self->_parse($content, $context);
}

sub _slurp_template {
    my $self = shift;
    my ($template) = @_;

    my $path =
      defined $self->templates_path
      && !(File::Spec->file_name_is_absolute($template))
      ? File::Spec->catfile($self->templates_path, $template)
      : $template;

    # return cached entry
    if ($self->{use_cache} == 2) {
        if (my $e = $self->{cache}->{$path}) {
            return $e->[1];
        }
    }

    croak("Can't find '$path'") unless defined $path && -f $path;

    my @st = stat $path;

    # return cached entry after comparing mtime
    if (my $e = $self->{cache}->{$path}) {
        return $e->[1]
          if $st[9] == $e->[0]; # compare mtime
    }

    my $content = do {
        local $/;
        open my $file, '<:encoding(UTF-8)', $path or return;
        <$file>;
    };

    croak("Can't open '$template'") unless defined $content;

    chomp $content;

    $self->{cache}->{$path} = [
        $st[9], # mtime
        $content,
    ] if $self->{use_cache};

    return $content;
}

sub _is_empty {
    my $self = shift;
    my ($vars, $name) = @_;

    my $var;

    if (Scalar::Util::blessed($vars)) {
        $var = $vars->$name;
    }
    else {
        return 1 unless exists $vars->{$name};
        $var = $vars->{$name};
    }

    return 1 unless defined $var;
    return 1 if $var eq '';

    return 0;
}


1;
__END__

=head1 NAME

Text::Caml - Mustache template engine

=head1 SYNOPSIS

    my $view = Text::Caml->new;

    my $output = $view->render_file('template', {title => 'Hello', body => 'there!'});

    # template
    <html>
        <head>
            <title>{{title}}</title>
        </head>
        <body>
            {{body}}
        </body>
    </html>

    $output = $view->render('{{hello}}', {hello => 'hi'});

=head1 DESCRIPTION

L<Text::Caml> is a Mustache-like (L<http://mustache.github.com/>) template engine.
That means it tends to have no logic in template files.

=head2 Syntax

=head3 Context

Context is the data passed to the template. Context can change during template
rendering and be specific in various cases.

=head3 Variables

Variables are inserted using C<{{foo}}> syntax. If a variable is not defined or
empty it is simply ignored.

    Hello {{user}}!

By default every variable is escaped when parsed. This can be omitted using C<&>
flag.

    # user is '1 > 2'
    Hello {{user}}! => Hello 1 &gt; 2!

    Hello {{&user}}! => Hello 1 > 2!

Using a C<.> syntax it is possible to access deep hash structures.

    # user => {name => 'Larry'}
    {{user.name}}

    Larry

=head3 Comments

Comments are ignored. They can be multiline too.

  foo{{! Comment}}bar

  foo{{!
  Comment
  }}bar

=head3 Sections

Sections are like iterators that iterate over your data. Depending on a
variable type different iterators are created.

=over 4

=item *

Boolean, C<have_comments> is defined, not zero and not empty.

    # have_comments => 1
    {{#have_comments}}
    We have comments!
    {{/have_comments}}

    We have comments!

=item *

Array, C<list> is a non-empty array reference. Special variable C<{{.}}> is
created to point to the current element.

    # list => [1, 2, 3]
    {{#list}}{{.}}{{/list}}

    123

=item *

Hash, C<hash> is a non-empty hash reference. Context is swithed to the
elements.

    # hash => {one => 1, two => 2, three => 3}
    {{#hash}}
    {{one}}{{two}}{{three}}
    {{/hash}}

    123

=item *

Lambda, C<lambda> is an anonymous subroutine, that's called with three
arguments: current object instance, template and the context. This can be used
for subrendering, helpers etc.

    wrapped => sub {
        my $self = shift;
        my $text = shift;

        return '<b>' . $self->render($text, @_) . '</b>';
    };

    {{#wrapped}}
    {{name}} is awesome.
    {{/wrapped}}

    <b>Willy is awesome.</b>

=back

=head3 Inverted sections

Inverted sections are run in those situations when normal sections don't. When
boolean value is false, array is empty etc.

    # repo => []
    {{#repo}}
      <b>{{name}}</b>
    {{/repo}}
    {{^repo}}
      No repos :(
    {{/repo}}

    No repos :(

=head3 Partials

Partials are like C<inludes> in other templates engines. They are run with the
current context and can be recursive.

    {{#articles}}
    {{>article_summary}}
    {{/articles}}

=cut

=head1 ATTRIBUTES

=head2 C<templates_path>

  my $path = $engine->templates_path;

Return path where templates are searched.

=head2 C<set_templates_path>

  my $path = $engine->set_templates_path('templates');

Set base path under which templates are searched.

=head2 C<default_partial_extension>

If this option is set that the extension is automatically added to the partial
filenames.

  my $engine = Text::Caml->new(default_partial_extension => 'caml');

  ---
  {{#articles}}
  {{>article_summary}} # article_summary.caml will be searched
  {{/articles}}

=head2 C<escape_func>

This option is set a custom escape function instead of builtin

  my $engine = Text::Caml->new(escape_func => \&HTML::Escape::escape_html);

=head2 C<use_cache>

Cache mode (0: no cache (default), 1: cache with update check, 2: cache but do not check updates)

=head1 METHODS

=head2 C<new>

  my $engine = Text::Caml->new;

Create a new L<Text::Caml> object.

=head2 C<render>

    $engine->render('{{foo}}', {foo => 'bar'});

Render template from string.

=head2 C<render_file>

    $engine->render_file('template.mustache', {foo => 'bar'});

Render template from file.

=head2 C<escape_func>

Set a custom escape function instead of builtin , if it's not defined in attribute escape_func and return sub reference

    $engine->escape_func(\&HTML::Escape::escape_html);

=head2 C<escape_html>

Escapes HTML's special chars in string with escape_func

    my $str = $engine->escape_html("nonono <&> yesyesyes");

=head1 DEVELOPMENT

=head2 Repository

  http://github.com/vti/text-caml

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>

=head1 CREDITS

Sergey Zasenko (und3f)

Andrew Rodland (arodland)

Alex Balhatchet (kaoru)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
