package Catalyst::Controller::HTML::FormFu::Action::MultiForm;

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
            && $self->attributes->{ActionClass}[0] eq
            $config->{multiform_action};

    my $multi = $controller->_multiform;

    $multi->process;

    $c->stash->{ $config->{multiform_stash} } = $multi;

    $self->next::method(@_);
}

1;
