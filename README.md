# NAME

Text::Caml - Mustache template engine

# SYNOPSIS

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

# DESCRIPTION

[Text::Caml](https://metacpan.org/pod/Text::Caml) is a Mustache-like ([http://mustache.github.com/](http://mustache.github.com/)) template engine.
That means it tends to have no logic in template files.

## Syntax

### Context

Context is the data passed to the template. Context can change during template
rendering and be specific in various cases.

### Variables

Variables are inserted using `{{foo}}` syntax. If a variable is not defined or
empty it is simply ignored.

    Hello {{user}}!

By default every variable is escaped when parsed. This can be omitted using `&`
flag.

    # user is '1 > 2'
    Hello {{user}}! => Hello 1 &gt; 2!

    Hello {{&user}}! => Hello 1 > 2!

Using a `.` syntax it is possible to access deep hash structures.

    # user => {name => 'Larry'}
    {{user.name}}

    Larry

### Comments

Comments are ignored. They can be multiline too.

    foo{{! Comment}}bar

    foo{{!
    Comment
    }}bar

### Sections

Sections are like iterators that iterate over your data. Depending on a
variable type different iterators are created.

- Boolean, `have_comments` is defined, not zero and not empty.

        # have_comments => 1
        {{#have_comments}}
        We have comments!
        {{/have_comments}}

        We have comments!

- Array, `list` is a non-empty array reference. Special variable `{{.}}` is
created to point to the current element.

        # list => [1, 2, 3]
        {{#list}}{{.}}{{/list}}

        123

- Hash, `hash` is a non-empty hash reference. Context is swithed to the
elements.

        # hash => {one => 1, two => 2, three => 3}
        {{#hash}}
        {{one}}{{two}}{{three}}
        {{/hash}}

        123

- Lambda, `lambda` is an anonymous subroutine, that's called with three
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

### Inverted sections

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

### Partials

Partials are like `inludes` in other templates engines. They are run with the
current context and can be recursive.

    {{#articles}}
    {{>article_summary}}
    {{/articles}}

# ATTRIBUTES

## `templates_path`

    my $path = $engine->templates_path;

Return path where templates are searched.

## `set_templates_path`

    my $path = $engine->set_templates_path('templates');

Set base path under which templates are searched.

# METHODS

## `new`

    my $engine = Text::Caml->new;

Create a new [Text::Caml](https://metacpan.org/pod/Text::Caml) object.

## `render`

    $engine->render('{{foo}}', {foo => 'bar'});

Render template from string.

## `render_file`

    $engine->render_file('template.mustache', {foo => 'bar'});

Render template from file.

# DEVELOPMENT

## Repository

    http://github.com/vti/text-caml

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`

# CREDITS

Sergey Zasenko (und3f)

Andrew Rodland (arodland)

# COPYRIGHT AND LICENSE

Copyright (C) 2011-2012, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
