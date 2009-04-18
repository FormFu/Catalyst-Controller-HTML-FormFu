package Catalyst::Controller::HTML::FormFu::Action::FormMethod;

use strict;
use warnings;
use base qw( Catalyst::Action );

use MRO::Compat;
use Carp qw( croak );

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    my $config = $controller->_html_formfu_config;

    return $self->next::method(@_)
        unless exists $self->attributes->{ActionClass}
            && $self->attributes->{ActionClass}[0] eq $config->{method_action};

    my $form = $controller->_form;

    for ( @{ $self->{_attr_params} } ) {
        for my $method (split) {
            $c->log->debug($method) if $c->debug;

            my $args = $controller->$method($c) || {};

            $form->populate($args);
        }
    }

    $form->process;

    $c->stash->{ $config->{form_stash} } = $form;

    $self->next::method(@_);
}

1;
