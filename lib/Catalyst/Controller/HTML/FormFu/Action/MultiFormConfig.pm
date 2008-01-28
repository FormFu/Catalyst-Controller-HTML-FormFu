package Catalyst::Controller::HTML::FormFu::Action::MultiFormConfig;

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
      && $self->attributes->{ActionClass}[0] eq $config->{multiform_config_action};

    my $multi = $controller->_multiform;
    my @files = grep {length} split /\s+/, $self->{_attr_params}->[0] || '';
    
    if ( !@files ) {
        push @files, $self->reverse . $config->{config_file_ext};
    }
    
    for my $file (@files) {
        my $filepath = defined $config->{config_file_path}
            ? $config->{config_file_path} ."/". $file
            : $file;
        
        $c->log->debug( __PACKAGE__ ." searching for file '$filepath'" )
            if $c->debug;
        
        $multi->load_config_file( $filepath );
    }
    
    $multi->process( $c->request );
    
    $c->stash->{ $config->{multiform_stash} } = $multi;
    
    $self->NEXT::execute(@_);
}

1;
