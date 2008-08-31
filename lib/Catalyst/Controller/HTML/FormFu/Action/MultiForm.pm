package Catalyst::Controller::HTML::FormFu::Action::MultiForm;

use strict;
use warnings;
use base qw( Catalyst::Action );

use Config::Any;
use NEXT;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;
    
    my $config = $controller->_html_formfu_config;

    return $self->NEXT::execute(@_)
      unless exists $self->attributes->{ActionClass}
      && $self->attributes->{ActionClass}[0] eq $config->{multiform_action};

    my $multi = $controller->_multiform;
    
    $multi->process;
    
    $c->stash->{ $config->{multiform_stash} } = $multi;
    
    $self->NEXT::execute(@_);
}

1;
