package Catalyst::Controller::HTML::FormFu::Action::MultiFormMethod;

use strict;
use warnings;
use base qw( Catalyst::Action );

use NEXT;
use Carp qw( croak );

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;
    
    my $config = $controller->_html_formfu_config;

    return $self->NEXT::execute(@_)
      unless exists $self->attributes->{ActionClass}
      && $self->attributes->{ActionClass}[0] eq $config->{multiform_method_action};

    my $multi = $controller->_multiform;

    for ( @{ $self->{_attr_params} } ) {    
        for my $method ( split ) {
            $c->log->debug($method) if $c->debug;
            
            my $args = $controller->$method($c) || {};
            
            $multi->populate( $args );
        }
    }
    
    $multi->process( $c->request );
    
    $c->stash->{ $config->{multiform_stash} } = $multi;
    
    $self->NEXT::execute(@_);
}

1;
