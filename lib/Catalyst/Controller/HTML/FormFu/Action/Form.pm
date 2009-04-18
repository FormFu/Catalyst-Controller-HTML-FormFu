package Catalyst::Controller::HTML::FormFu::Action::Form;

use strict;
use warnings;
use base qw( Catalyst::Action );

use Config::Any;
use MRO::Compat;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    my $config = $controller->_html_formfu_config;

    return $self->next::method(@_)
        unless exists $self->attributes->{ActionClass}
            && $self->attributes->{ActionClass}[0] eq $config->{form_action};

    my $form = $controller->_form;

    $form->process;

    $c->stash->{ $config->{form_stash} } = $form;

    $self->next::method(@_);
}

1;
