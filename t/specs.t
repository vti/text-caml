use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Basename qw(basename);
use FindBin '$Bin';
use Text::Caml;

# To run the tests, set the environment variable like this:
# RUN_SPECS=1 prove t/specs.t

BEGIN {
    require Test::More;

    if ( $ENV{RUN_SPECS} ) {
        require YAML::XS;
        import Test::More tests => 124;
    }
    else {
        import Test::More skip_all
            => 'to run the tests set the environment variable:'
            .  ' RUN_SPECS=1 prove ' . __FILE__ ;
    }
}

my $PARTS_DIR = "$Bin/partials/";
my $engine = Text::Caml->new;
$engine->set_templates_path( $PARTS_DIR );

sub startup {
    # remove partials directory
    &shutdown();

    # create partials directory
    make_path( $PARTS_DIR, { error => \my $err } );
    if ( @$err ) {
        for my $diag ( @$err ) {
            my ($file, $message) = %$diag;

            if ( $file eq '' ) {
                die "General error: [$message]";
            }
            else {
                die "Can't create [$file]: [$message]";
            }
        }
    }
}

sub setup {
    my $t = shift;

    # create and fill partials files
    foreach my $k ( keys %{ $t->{partials} } ) {
        my $parts_filename = $PARTS_DIR . $k;

        open my $fh, '>', $parts_filename
            or die "Can't create [$parts_filename]: [$!]";
        print $fh $t->{partials}->{$k};
        close $fh;
    }
}

sub teardown {
    my $t = shift;

    # remove partials files
    foreach my $k ( keys %{ $t->{partials} } ) {
        my $parts_filename = $PARTS_DIR . $k;

        unless ( unlink $parts_filename ) {
            die "Can't remove [$parts_filename]: [$!]";
        }
    }
}

sub shutdown {
    # remove partials directory
    remove_tree( $PARTS_DIR, { error => \my $err } );
    if ( @$err ) {
        for my $diag ( @$err ) {
            my ($file, $message) = %$diag;

            if ( $file eq '' ) {
                die "General error: [$message]";
            }
            else {
                die "Can't remove [$file]: [$message]";
            }
        }
    }
}

while ( my $filename = <$Bin/../ext/spec/specs/*.yml> ) {
    my $basename = basename $filename;

    startup();

    my $spec  = YAML::XS::LoadFile($filename);
    my $tests = $spec->{tests};

    note "\n---------\n$spec->{overview}";

    foreach my $t ( @{$tests} ) {
        setup($t);

        $t->{signature} = "$basename: $t->{name}\n$t->{desc}\n";
        my $out = '';

        eval {
            # ensure that lambdas are properly setup
            my $data = $t->{data};
            my @hashes = $data;
            for my $hash ( @hashes ) {
                while ( my ($k, $v) = each %$hash ) {
                    $hash->{$k} = eval $v->{perl} if ref $v eq 'code';
                    push @hashes, $v              if ref $v eq 'HASH';
                }
            }
            $out = $engine->render( $t->{template}, $t->{data} );
        };
        if ( $@ ) {
            fail( $t->{signature} . "ERROR: $@" );
        }
        else {
            is $out => $t->{expected}, $t->{signature};
        }

        teardown($t);
    }

    &shutdown();
}
