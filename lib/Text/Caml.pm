package Text::Caml;

use strict;
use warnings;

require Carp;
use File::Spec;

our $VERSION = '0.000001';

our $LEADING_SPACE  = qr/(?:\n [ ]*)?/x;
our $TRAILING_SPACE = qr/(?:[ ]* \n)?/x;
our $START_TAG      = qr/{/x;
our $END_TAG        = qr/}/x;

our $START_OF_PARTIAL          = quotemeta '>';
our $START_OF_SECTION          = quotemeta '#';
our $START_OF_INVERTED_SECTION = quotemeta '^';
our $END_OF_SECTION            = quotemeta '/';

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub templates_path { $_[0]->{templates_path} }
sub set_templates_path { $_[0]->{templates_path} = $_[1] }

sub format { $_[0]->{format} }
sub set_format { $_[0]->{format} = $_[1] }

sub render_file {
    my $self    = shift;
    my $file    = shift;
    my $context = shift;

    my $template = $self->_slurp_template($file);
    return $self->render($template, $context);
}

sub render {
    my $self = shift;

    my $template;
    my $context;

    if (@_ == 0) {
        $template = $self->_slurp_template($self->_class_to_template);
        $context  = $self->to_hash;
    }
    else {
        $template = shift;
        $context  = shift;
    }

    my $output = '';

    pos $template = 0;
    while (pos $template < length $template) {
        if ($template =~ m/($LEADING_SPACE)?\G $START_TAG /gcxms) {
            my $chunk = '';

            my $leading_newline = !!$1;

            # Tripple
            if ($template =~ m/\G { (.*?) } $END_TAG/gcxms) {
                $chunk .= $self->_render_tag($1, $context);
            }

            # Comment
            elsif ($template =~ m/\G ! .*? $END_TAG/gcxms) {
            }

            # Section
            elsif ($template
                =~ m/\G $START_OF_SECTION (.*?) $END_TAG ($TRAILING_SPACE)?/gcxms
              )
            {
                my $name = $1;
                my $end_of_section = $name;

                # Method call
                if ($name =~ m/^\./) {
                    $end_of_section =~ s/\(.*//;
                }

                if ($template
                    =~ m/\G (.*?) ($LEADING_SPACE)? $START_TAG $END_OF_SECTION $end_of_section $END_TAG ($TRAILING_SPACE)?/gcxms
                  )
                {
                    $chunk .= $self->_render_section($name, $1, $context);
                }
                else {
                    Carp::croak("Section's '$name' end not found");
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
                      .= $self->_render_inverted_section($name, $1, $context);
                }
                else {
                    Carp::croak("Section's '$name' end not found");
                }
            }

            # End of section
            elsif ($template =~ m/\G $END_OF_SECTION (.*?) $END_TAG/gcxms) {
                Carp::croak("Unexpected end of section '$1'");
            }

            # Partial
            elsif ($template =~ m/\G $START_OF_PARTIAL (.*?) $END_TAG/gcxms) {
                $chunk .= $self->_render_partial($1, $context);
            }

            # Tag
            elsif ($template =~ m/\G (.*?) $END_TAG/gcxms) {
                $chunk .= $self->_render_tag_escaped($1, $context);
            }
            else {
                Carp::croak("Can't find where tag is closed");
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

sub to_hash { {} }

sub _render_tag {
    my $self    = shift;
    my $name    = shift;
    my $context = shift;

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
        return $self->render($content, $context);
    }

    return $value;
}

sub _get_value {
    my $self    = shift;
    my $context = shift;
    my $name    = shift;

    # Method
    if ($name =~ s/^\.//) {
        my $code = "do {use strict;use warnings;\$self->$name;};";
        my $retval = eval $code;
        Carp::croak("Error near method call: $code: $@") if $@;
        return $retval;
    }

    my @parts = split /\./ => $name;

    $name = shift @parts;
    return '' if $self->_is_empty($context, $name);

    my $value = $context->{$name};

    foreach my $part (@parts) {
        return '' if $self->_is_empty($value, $part);
        $value = $value->{$part};
    }

    return $value;
}

sub _render_tag_escaped {
    my $self    = shift;
    my $tag     = shift;
    my $context = shift;

    my $do_not_escape;
    if ($tag =~ s/\A \&//xms) {
        $do_not_escape = 1;
    }

    my $output = $self->_render_tag($tag, $context);

    $output = $self->_escape($output) unless $do_not_escape;

    return $output;
}

sub _render_section {
    my $self     = shift;
    my $name     = shift;
    my $template = shift;
    my $context  = shift;

    my $value = $self->_get_value($context, $name);

    my $output = '';

    if (ref $value eq 'HASH') {
        $output .= $self->render($template, $value);
    }
    elsif (ref $value eq 'ARRAY') {
        my $idx = 0;
        foreach my $el (@$value) {
            my $context = ref $el ? $el : {'.' => $el};
            $context->{'_idx'} = $idx;

            $context->{'_even'} = $idx % 2 == 0;
            $context->{'_odd'}  = $idx % 2 != 0;

            $context->{'_first'} = $idx == 0;
            $context->{'_last'}  = $idx == $#$value;

            $output .= $self->render($template, $context);

            $idx++;
        }
    }
    elsif (ref $value eq 'CODE') {
        $output
          .= $self->render($value->($self, $template, $context), $context);
    }
    elsif ($value) {
        $output .= $self->render($template, $context);
    }

    return $output;
}

sub _render_inverted_section {
    my $self     = shift;
    my $name     = shift;
    my $template = shift;
    my $context  = shift;

    return $self->render($template, $context)
      unless exists $context->{$name};

    my $value  = $context->{$name};
    my $output = '';

    if (ref $value eq 'HASH') {
    }
    elsif (ref $value eq 'ARRAY') {
        return '' if @$value;

        $output .= $self->render($template, $context);
    }
    elsif (!$value) {
        $output .= $self->render($template, $context);
    }

    return $output;
}

sub _render_partial {
    my $self     = shift;
    my $template = shift;
    my $context  = shift;

    my $content = $self->_slurp_template($template);

    return $self->render($content, $context);
}

sub _class_to_template {
    my $self = shift;

    my $class = ref $self;

    my $template = $self->_decamelize($class);
    $template .= '.' . $self->format if defined $self->format;

    return $template;
}

sub _decamelize {
    my $self   = shift;
    my $string = shift;

    my @parts;
    foreach my $module (split '::' => $string) {
        my @tokens = split '([A-Z])' => $module;
        my @p;
        foreach my $token (@tokens) {
            next unless defined $token && $token ne '';

            if ($token =~ m/[A-Z]/) {
                push @p, lc $token;
            }
            else {
                $p[-1] .= $token;
            }
        }

        push @parts, join _ => @p;
    }

    return join '-' => @parts;
}

sub _slurp_template {
    my $self     = shift;
    my $template = shift;

    my $path = File::Spec->catfile($self->templates_path, $template);

    Carp::croak("Can't find '$template'") unless defined $path && -f $path;

    my $content = do {
        local $/;
        open my $file, '<:encoding(UTF-8)', $path or return;
        <$file>;
    };

    Carp::croak("Can't open '$template'") unless defined $content;

    chomp $content;

    return $content;
}

sub _is_empty {
    my $self = shift;
    my ($vars, $var) = @_;

    return 1 unless exists $vars->{$var};
    return 1 unless defined $vars->{$var};
    return 1 if $vars->{$var} eq '';

    return 0;
}

sub _escape {
    my $self  = shift;
    my $value = shift;

    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/"/&quot;/g;

    return $value;
}

1;
