package Catalyst::Controller::HTML::FormFu;

use strict;
use warnings;
use base qw( Catalyst::Controller Class::Accessor::Fast );

use HTML::FormFu;
use Scalar::Util qw/ weaken /;
use Carp qw/ croak /;

our $VERSION = '0.01002';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

__PACKAGE__->mk_accessors(qw( _html_formfu_config ));

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    
    return bless { %$self, c => $c }, ref($self);
}

sub new {
    my $class = shift;
    my ($c) = @_;
    my $self = $class->NEXT::new(@_);
    
    $self->_setup( $c );
    
    return $self;
}

sub _setup {
    my $self = shift;
    my ($c)  = @_;

    my $self_config = $self->config->{'Controller::HTML::FormFu'} || {};
    my $parent_config = $c->config->{'Controller::HTML::FormFu'} || {};

    my %defaults = (
        form_method   => 'form',
        form_stash    => 'form',
        context_stash => 'context',
        form_attr     => 'Form',
        config_attr   => 'FormConfig',
        method_attr   => 'FormMethod',
        form_action   => "Catalyst::Controller::HTML::FormFu::Action::Form",
        config_action => "Catalyst::Controller::HTML::FormFu::Action::Config",
        method_action => "Catalyst::Controller::HTML::FormFu::Action::Method",
        constructor   => {},
        config_callback  => 1,
        config_file_ext  => '.yml',
        config_file_path => $c->path_to( 'root', 'forms' ),
    );
    
    my %args = ( %defaults, %$parent_config, %$self_config );
    
    $args{constructor}{render_class_args}{INCLUDE_PATH}
        ||= [ $c->path_to('root','formfu') ];
    
    $args{constructor}{query_type} ||= 'Catalyst';
    
    $self->_html_formfu_config( \%args );
    
    my $form_method = $args{form_method};
    no strict 'refs';
    *{"$form_method"} = \&_form;
}

sub _form {
    my $self = shift;
    
    my $form = HTML::FormFu->new({
        %{ $self->_html_formfu_config->{constructor} },
        ( @_ ? %{ $_[0] } : () ),
    });
    
    my $config = $self->_html_formfu_config;
    
    if ( $config->{config_callback} ) {
            $form->config_callback({
                plain_value => sub {
                    return if !defined $_;
                    s{__uri_for\((.+?)\)__}
                     { $self->{c}->uri_for( split( '\s*,\s*', $1 ) ) }eg
                }
            });
            
            weaken( $self->{c} );
    }
    
    if ( $config->{languages_from_context} ) {
        $form->languages( $self->{c}->languages );
    }
    
    if ( $config->{localize_from_context} ) {
        $form->add_localize_object( $self->{c} );
    }
    
    if ( $config->{default_action_use_name} ) {
        my $action = $self->{c}->uri_for( $self->{c}->{action}->name );
        
        $self->{c}->log->debug(
            "FormFu - Setting default action by name: $action"
        ) if $self->{c}->debug;
        
        $form->action( $action );
    }
    elsif ( $config->{default_action_use_path} ) {
        my $action =
            $self->{c}->{request}->base . $self->{c}->{request}->path;
        
        $self->{c}->log->debug(
            "FormFu - Setting default action by path: $action"
        ) if $self->{c}->debug;
        
        $form->action( $action );
    }
    
    my $context_stash = $config->{context_stash};
    $form->stash->{$context_stash} = $self->{c};
    weaken( $form->stash->{$context_stash} );
    
    return $form;
}

sub create_action {
    my $self = shift;
    my %args = @_;

    my $config = $self->_html_formfu_config;

    for my $type (qw/ form config method /) {
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

Catalyst::Controller::HTML::FormFu

=head1 SYNOPSIS

    package MyApp::Controller::My::Controller;
    
    use base 'Catalyst::Controller::HTML::FormFu';
    
    sub foo : Local : Form {
        my ( $self, $c ) = @_;
        
        # using the Form attribute is equivalent to:
        #
        # my $form = HTML::FormFu->new;
        #
        # $c->stash->{form}   = $form;
    }
    
    sub bar : Local : FormConfig {
        my ( $self, $c ) = @_;
        
        # using the FormConfig attribute is equivalent to:
        #
        # my $form = HTML::FormFu->new;
        #
        # $form->load_config_file('root/forms/my/controller/bar.yml');
        #
        # $c->stash->{form}   = $form;
        #
        # so you only need to do the following...
        
        my $form = $c->stash->{form};
        
        if ( $form->submitted && !$form->has_errors ) {
            do_something();
        }
    }
    
    sub baz : Local : FormConfig('my_config') {
        my ( $self, $c ) = @_;
        
        # using the FormConfig attribute with an argument is equivalent to:
        #
        # my $form = HTML::FormFu->new;
        #
        # $form->load_config_file('root/forms/my_config.yml');
        #
        # $c->stash->{form}   = $form;
        #
        # so you only need to do the following...
        
        my $form = $c->stash->{form};
        
        if ( $form->submitted && !$form->has_errors ) {
            do_something();
        }
    }
    
    sub quux : Local : FormMethod('load_form') {
        my ( $self, $c ) = @_;
        
        # using the FormConfig attribute with an argument is equivalent to:
        #
        # my $form = HTML::FormFu->new;
        #
        # $form->populate( $c->load_form );
        #
        # $c->stash->{form}   = $form;
        #
        # so you only need to do the following...
        
        my $form = $c->stash->{form};
        
        if ( $form->submitted && !$form->has_errors ) {
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

    my $form = $self->form;

=head1 CUSTOMIZATION

You can set your own config settings, using either your controller config 
or your application config.

    $c->config( 'Controller::HTML::FormFu' => \%my_values );
    
    # or
    
    MyApp->config( 'Controller::HTML::FormFu' => \%my_values );

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
which replaces any instance of C<__uri_for(URI)__> found in form config 
files with the result of passing the C<URI> argument to L<Catalyst/uri_for>.

The form C<< __uri_for(URI, PATH, PARTS)__ >> is also supported, which is 
equivalent to C<< $c->uri_for( 'URI', \@ARGS ) >>. At this time, there is no 
way to pass query values equivalent to 
C<< $c->uri_for( 'URI', \@ARGS, \%QUERY_VALUES ) >>. 

Default value: 1

=head2 config_file_ext

Set the default file extension used by the Config() action attribute. This 
setting is appended to both explicit config filenames, and auto-generated 
filenames.

Default value: C<.yml>.

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

default_action_use_name => 1 leads to
    $form->action = /foo/bar

default_action_use_path => 1 leads to
    $form->action = /foo/bar/1

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
