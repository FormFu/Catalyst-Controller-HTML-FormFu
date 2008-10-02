package Catalyst::Controller::HTML::FormFu::Action::FormConfig;

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
        push @files, $self->reverse;
    }
    
    my $ext_regex = $config->{_file_ext_regex};
    
    for my $file (@files) {
        $c->log->debug( __PACKAGE__ ." loading config file '$file'" )
            if $c->debug;
        
        if ( $file =~ m/ \. $ext_regex \z /x ) {
            $form->load_config_file( $file );
        }
        else {
            $form->load_config_filestem( $file );
        }
    }
    
    $form->process;
    
    $c->stash->{ $config->{form_stash} } = $form;
    
    $self->NEXT::execute(@_);
}

1;
