package Catalyst::Controller::HTML::FormFu;

use strict;
use warnings;
use Moose qw( extends with );
extends 'Catalyst::Controller', 'Class::Accessor::Fast';
with 'Catalyst::Component::InstancePerContext';

use HTML::FormFu;
eval "use HTML::FormFu::MultiForm";    # ignore errors
use Config::Any;
use Regexp::Assemble;
use Scalar::Util qw/ isweak weaken /;
use Carp qw/ croak /;
use MRO::Compat;

our $VERSION = '0.04003';
$VERSION = eval $VERSION;              # see L<perlmodstyle>

__PACKAGE__->mk_accessors(qw( _html_formfu_config ));

sub build_per_context_instance {
    my ( $self, $c ) = @_;

    $self->{c} = $c;

    return $self;
}

sub new {
    my $class = shift;
    my ($c)   = @_;
    my $self  = $class->next::method(@_);

    $self->_setup($c);

    return $self;
}

sub _setup {
    my ( $self, $app ) = @_;

    my $self_config   = $self->config->{'Controller::HTML::FormFu'} || {};
    my $parent_config = $app->config->{'Controller::HTML::FormFu'}  || {};

    my %defaults = (
        request_token_enable          => 0,
        request_token_field_name      => '_token',
        request_token_session_key     => '__token',
        request_token_expiration_time => 3600,
        form_method                   => 'form',
        form_stash                    => 'form',
        form_attr                     => 'Form',
        config_attr                   => 'FormConfig',
        method_attr                   => 'FormMethod',
        form_action => "Catalyst::Controller::HTML::FormFu::Action::Form",
        config_action =>
            "Catalyst::Controller::HTML::FormFu::Action::FormConfig",
        method_action =>
            "Catalyst::Controller::HTML::FormFu::Action::FormMethod",

        multiform_method      => 'multiform',
        multiform_stash       => 'multiform',
        multiform_attr        => 'MultiForm',
        multiform_config_attr => 'MultiFormConfig',
        multiform_method_attr => 'MultiFormMethod',
        multiform_action =>
            "Catalyst::Controller::HTML::FormFu::Action::MultiForm",
        multiform_config_action =>
            "Catalyst::Controller::HTML::FormFu::Action::MultiFormConfig",
        multiform_method_action =>
            "Catalyst::Controller::HTML::FormFu::Action::MultiFormMethod",

        context_stash => 'context',

        model_stash => {},

        constructor           => {},
        multiform_constructor => {},

        config_callback => 1,
    );

    my %args = ( %defaults, %$parent_config, %$self_config );

    my $local_path = $app->path_to( 'root', 'formfu' );

    if (   !exists $args{constructor}{tt_args}
        || !exists $args{constructor}{tt_args}{INCLUDE_PATH} && -d $local_path )
    {
        $args{constructor}{tt_args}{INCLUDE_PATH} = [$local_path];
    }

    $args{constructor}{query_type} ||= 'Catalyst';

    # handle config_file_path
    if ( exists $args{config_file_path} ) {
        warn <<'DEPRECATED';
config_file_path configuration setting is deprecated,
use $config->{constructor}{config_file_path} instead.
DEPRECATED

        my $path = delete $args{config_file_path};

        $args{constructor}{config_file_path} = $path;
    }

    if ( !exists $args{constructor}{config_file_path} ) {
        $args{constructor}{config_file_path} = $app->path_to( 'root', 'forms' );
    }

    # build regexp of file extensions
    my $regex_builder = Regexp::Assemble->new;

    map { $regex_builder->add($_) } Config::Any->extensions;

    $args{_file_ext_regex} = $regex_builder->re;

    # save config for use by action classes
    $self->_html_formfu_config( \%args );

    # add controller methods
    no strict 'refs';
    *{"$args{form_method}"}      = \&_form;
    *{"$args{multiform_method}"} = \&_multiform;
}

sub _form {
    my $self   = shift;
    my $config = $self->_html_formfu_config;
    my $form   = HTML::FormFu->new( {
            %{ $self->_html_formfu_config->{constructor} },
            ( @_ ? %{ $_[0] } : () ),
        } );

    $self->_common_construction($form);

    if ( $config->{request_token_enable} ) {
        $form->plugins( {
                type            => 'RequestToken',
                context         => $config->{context_stash},
                field_name      => $config->{request_token_field_name},
                session_key     => $config->{request_token_session_key},
                expiration_time => $config->{request_token_expiration_time} } );
    }

    return $form;
}

sub _multiform {
    my $self = shift;

    my $multi = HTML::FormFu::MultiForm->new( {
            %{ $self->_html_formfu_config->{constructor} },
            %{ $self->_html_formfu_config->{multiform_constructor} },
            ( @_ ? %{ $_[0] } : () ),
        } );

    $self->_common_construction($multi);

    return $multi;
}

sub _common_construction {
    my ( $self, $form ) = @_;

    croak "form or multi arg required" if !defined $form;

    $form->query( $self->{c}->request );

    my $config = $self->_html_formfu_config;

    if ( exists $config->{config_file_ext} ) {
        warn <<WARNING;
Configuration setting 'config_file_ext' has been removed.
We now use Config::Any's load_stems() which automatically finds files with
known file extensions.
WARNING
    }

    if ( $config->{config_callback} ) {
        $form->config_callback( {
                plain_value => sub {
                    return if !defined $_;
                    s{__uri_for\((.+?)\)__}
                     { $self->{c}->uri_for( split( '\s*,\s*', $1 ) ) }eg;
                    s{__path_to\(\s*(.+?)\s*\)__}
                     { $self->{c}->path_to( split( '\s*,\s*', $1 ) ) }eg;
                    s{__config\((.+?)\)__}
                     { $self->{c}->config->{$1}  }eg;
                    }
            } );

        weaken( $self->{c} )
            if !isweak( $self->{c} );
    }

    if ( $config->{languages_from_context} ) {
        $form->languages( $self->{c}->languages );
    }

    if ( $config->{localize_from_context} ) {
        $form->add_localize_object( $self->{c} );
    }

    if ( $config->{default_action_use_name} ) {
        my $action = $self->{c}->uri_for( $self->{c}->{action}->name );

        $self->{c}
            ->log->debug( "FormFu - Setting default action by name: $action" )
            if $self->{c}->debug;

        $form->action($action);
    }
    elsif ( $config->{default_action_use_path} ) {
        my $action = $self->{c}->{request}->base . $self->{c}->{request}->path;

        $self->{c}
            ->log->debug( "FormFu - Setting default action by path: $action" )
            if $self->{c}->debug;

        $form->action($action);
    }

    my $context_stash = $config->{context_stash};
    $form->stash->{$context_stash} = $self->{c};
    weaken( $form->stash->{$context_stash} );

    my $model_stash = $config->{model_stash};

    for my $model ( keys %$model_stash ) {
        $form->stash->{$model} = $self->{c}->model( $model_stash->{$model} );
    }

    return;
}

sub create_action {
    my $self = shift;
    my %args = @_;

    my $config = $self->_html_formfu_config;

    for my $type (
        qw/
        form
        config
        method
        multiform
        multiform_config
        multiform_method /
        )
    {
        my $attr = $config->{"${type}_attr"};

        if ( exists $args{attributes}{$attr} ) {
            $args{_attr_params} = delete $args{attributes}{$attr};
        }
        elsif ( exists $args{attributes}{"$attr()"} ) {
            $args{_attr_params} = delete $args{attributes}{"$attr()"};
        }
        else {
            next;
        }

        push @{ $args{attributes}{ActionClass} }, $config->{"${type}_action"};
        last;
    }

    $self->SUPER::create_action(%args);
}

1;

__END__

=head1 NAME

Catalyst::Controller::HTML::FormFu - Catalyst integration for HTML::FormFu

=head1 SYNOPSIS

    package MyApp::Controller::My::Controller;
    
    use base 'Catalyst::Controller::HTML::FormFu';
    
    sub index : Local {
        my ( $self, $c ) = @_;
        
        # doesn't use an Attribute to make a form
        # can get an empty form from $self->form()
        
        my $form = $self->form();
    }
    
    sub foo : Local : Form {
        my ( $self, $c ) = @_;
        
        # using the Form attribute is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->process;
        # 
        # $c->stash->{form} = $form;
    }
    
    sub bar : Local : FormConfig {
        my ( $self, $c ) = @_;
        
        # using the FormConfig attribute is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->load_config_filestem('root/forms/my/controller/bar');
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
        #
        # so you only need to do the following...
        
        my $form = $c->stash->{form};
        
        if ( $form->submitted_and_valid ) {
            do_something();
        }
    }
    
    sub baz : Local : FormConfig('my_config') {
        my ( $self, $c ) = @_;
        
        # using the FormConfig attribute with an argument is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->load_config_filestem('root/forms/my_config');
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
        #
        # so you only need to do the following...
        
        my $form = $c->stash->{form};
        
        if ( $form->submitted_and_valid ) {
            do_something();
        }
    }
    
    sub quux : Local : FormMethod('load_form') {
        my ( $self, $c ) = @_;
        
        # using the FormConfig attribute with an argument is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->populate( $c->load_form );
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
        #
        # so you only need to do the following...
        
        my $form = $c->stash->{form};
        
        if ( $form->submitted_and_valid ) {
            do_something();
        }
    }
    
    sub load_form {
        my ( $self, $c ) = @_;
        
        # Automatically called by the above FormMethod('load_form') action.
        # Called as a method on the controller object, with the context 
        # object as an argument.
        
        # Must return a hash-ref suitable to be fed to $form->populate()
    }

=head1 METHODS

=head2 form

This creates a new L<HTML::FormFu> object, passing as it's argument the 
contents of the L</constructor> config value.

This is useful when using the ConfigForm() or MethodForm() action attributes, 
to create a 2nd form which isn't populated using a config-file or method 
return value.

    sub foo : Local {
        my ( $self, $c ) = @_;
        
        my $form = $self->form;
    }

Note that when using this method, the form's L<query|HTML::FormFu/query> 
method is not populated with the Catalyst request object.

=head1 CUSTOMIZATION

You can set your own config settings, using either your controller config 
or your application config.

    $c->config( 'Controller::HTML::FormFu' => \%my_values );
    
    # or
    
    MyApp->config( 'Controller::HTML::FormFu' => \%my_values );
    
    # or, in myapp.conf
    
    <Controller::HTML::FormFu>
        default_action_use_path 1
    </Controller::HTML::FormFu>

=head2 form_method

Override the method-name used to create a new form object.

See L</form>.

Default value: C<form>.

=head2 form_stash

Sets the stash key name used to store the form object.

Default value: C<form>.

=head2 form_attr

Sets the attribute name used to load the 
L<Catalyst::Controller::HTML::FormFu::Action::Form> action.

Default value: C<Form>.

=head2 config_attr

Sets the attribute name used to load the 
L<Catalyst::Controller::HTML::FormFu::Action::Config> action.

Default value: C<FormConfig>.

=head2 method_attr

Sets the attribute name used to load the 
L<Catalyst::Controller::HTML::FormFu::Action::Method> action.

Default value: C<FormMethod>.

=head2 form_action

Sets which package will be used by the Form() action.

Probably only useful if you want to create a sub-class which provides custom 
behaviour.

Default value: C<Catalyst::Controller::HTML::FormFu::Action::Form>.

=head2 config_action

Sets which package will be used by the Config() action.

Probably only useful if you want to create a sub-class which provides custom 
behaviour.

Default value: C<Catalyst::Controller::HTML::FormFu::Action::Config>.

=head2 method_action

Sets which package will be used by the Method() action.

Probably only useful if you want to create a sub-class which provides custom 
behaviour.

Default value: C<Catalyst::Controller::HTML::FormFu::Action::Method>.

=head2 constructor

Pass common defaults to the L<HTML::FormFu constructor|HTML::FormFu/new>.

These values are used by all of the action attributes, and by the 
C<< $self->form >> method.

Default value: C<{}>.

=head2 config_callback

Arguments: bool

If true, a coderef is passed to C<< $form->config_callback->{plain_value} >> 
which replaces any instance of C<__uri_for(URI)__> found in form config files
with the result of passing the C<URI> argument to L<Catalyst/uri_for>.

The form C<< __uri_for(URI, PATH, PARTS)__ >> is also supported, which is 
equivalent to C<< $c->uri_for( 'URI', \@ARGS ) >>. At this time, there is no 
way to pass query values equivalent to 
C<< $c->uri_for( 'URI', \@ARGS, \%QUERY_VALUES ) >>.

The second codeword that is being replaced is C<__path_to( @DIRS )__>. Any
instance is replaced with the result of passing the C<DIRS> arguments to
L<Catalyst/path_to>.
Don't use qoutationmarks as they would become part of the path.

Default value: 1

=head2 config_file_path

Location of the form config files, used when creating a form with the 
C<FormConfig> action controller.

Default Value: C<< $c->path_to( 'root', 'forms' ) >>

=head2 default_action_use_name

If set to a true value the action for the form will be set to the currently 
called action name.

Default value: C<false>.

=head2 default_action_use_path

If set to a true value the action for the form will be set to the currently 
called action path.
The action path includes concurrent to action name additioal parameters which
were code inside the path.

Default value: C<false>.

Example:

    action: /foo/bar
    called uri contains: /foo/bar/1
    
    # default_action_use_name => 1 leads to:
    $form->action = /foo/bar
    
    # default_action_use_path => 1 leads to:
    $form->action = /foo/bar/1

=head2 model_stash

Arguments: \%stash_keys_to_model_names

Used to place Catalyst models on the form stash.

If it's being used to make a L<DBIx::Class> schema available for
L<HTML::FormFu::Model::DBIC/options_from_model>, for C<Select> and other
Group-type elements - then the hash-key must be C<schema>. For example, if
your schema model class is C<MyApp::Model::MySchema>, you would set
C<model_stash> like so:

    <Controller::HTML::FormFu>
        <model_stash>
            schema MySchema
        </model_stash>
    </Controller::HTML::FormFu>

=head2 context_stash

To allow your form validation packages, etc, access to the catalyst context, 
a weakened reference of the context is copied into the form's stash.

    $form->stash->{context};

This setting allows you to change the key name used in the form stash.

Default value: C<context>

=head2 languages_from_context

If you're using a L10N / I18N plugin such as L<Catalyst::Plugin::I18N> which 
provides a C<languages> method that returns a list of valid languages to use 
for the currect request - and you want to use formfu's built-in I18N packages, 
then setting L</languages_from_context>

=head2 localize_from_context

If you're using a L10N / I18N plugin such as L<Catalyst::Plugin::I18N> which 
provides it's own C<localize> method, you can set L<localize_from_context> to 
use that method for formfu's localization.

=head2 request_token_enable

If true, adds an instance of L<HTML::FormFu::Plugin::RequestToken> to every
form, to stop accidental double-submissions of data.

=head2 request_token_field_name

Defaults to C<_token>.

=head2 request_token_session_key

Defaults to C<__token>.

=head2 request_token_expiration_time

Defaults to C<3600>.

=head1 DEPRECATED CONFIG SETTINGS

=head2 config_file_ext

This is now unnecessary, and has been removed. Config files are now searched
for, with any file extension supported by Config::Any.

=head1 CAVEATS

When using the C<Form> action attribute to create an empty form, you must 
call L<< $form->process|HTML::FormFu/process >> after populating the form.
However, you don't need to pass any arguments to C<process>, as the 
Catalyst request object will have automatically been set in 
L<< $form->query|HTML::FormFu/query >>.

When using the C<FormConfig> and C<FormMethod> action attributes, if you 
make any modifications to the form, such as adding or changing it's 
elements, you must call L<< $form->process|HTML::FormFu/process >> before 
rendering the form.

=head1 SEE ALSO

L<HTML::FormFu>, L<Catalyst::Helper::HTML::FormFu>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Carl Franks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
