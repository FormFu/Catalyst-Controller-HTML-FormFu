package Catalyst::Controller::HTML::FormFu::Action::Config;

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
      && $self->attributes->{ActionClass}[0] eq $config->{config_action};

    my $form  = $controller->_form;
    my @files = grep {length} split /\s+/, $self->{_attr_params}->[0] || '';
    
    if ( !@files ) {
        push @files, $self->reverse . $config->{config_file_ext};
    }
    
    for my $file (@files) {
        $c->log->debug( __PACKAGE__ ." searching for file '$file'" )
            if $c->debug;
        
        $form->load_config_file( $c->path_to('root/forms', $file ) );
    }
    
    $form->process( $c->request );
    
    $c->stash->{ $config->{form_stash} } = $form;
    
    $self->NEXT::execute(@_);
}

1;
