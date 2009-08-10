package Catalyst::Controller::HTML::FormFu::ActionBase::Form;

use strict;
use warnings;
use base qw( Catalyst::Action );

sub _form_action_regex {
    return qr/_FORM_(RENDER|(NOT_)?(VALID|COMPLETE|SUBMITTED))\z/;
}

sub dispatch {
    my $self = shift;
    my ($c) = @_;
    
    $self->next::method( @_ );
    
    my $controller = $c->component( $self->class );
    my $config     = $controller->_html_formfu_config;
    
    my $multi = $c->stash->{ $config->{multiform_stash} };
    my $form  = $c->stash->{ $config->{form_stash} };
    
    my $run_form_render_action = 1;
    
    # _FORM_COMPLETE
    
    my $complete_method = $self->name . "_FORM_COMPLETE";
    
    if ( defined $multi
        && ( my $code = $controller->can( $complete_method ) )
        && $multi->complete )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $complete_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $run_form_render_action = 0;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    # _FORM_SUBMITTED
    
    my $submitted_method = $self->name . "_FORM_SUBMITTED";
    
    if ( ( my $code = $controller->can( $submitted_method ) )
        && $form->submitted )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $submitted_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    # _FORM_VALID
    
    my $valid_method = $self->name . "_FORM_VALID";
    
    if ( ( my $code = $controller->can( $valid_method ) )
        && $form->submitted_and_valid )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $valid_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $run_form_render_action = 0
            if !defined $multi;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    # _FORM_NOT_COMPLETE
    
    my $not_complete_method = $self->name . "_FORM_NOT_COMPLETE";
    
    if ( defined $multi &&
        ( my $code = $controller->can( $not_complete_method ) )
        && $form->submitted && !$multi->complete )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $not_complete_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    # _FORM_NOT_VALID
    
    my $not_valid_method = $self->name . "_FORM_NOT_VALID";
    
    if ( ( my $code = $controller->can( $not_valid_method ) )
        && $form->submitted && $form->has_errors )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $not_valid_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    # _FORM_NOT_SUBMITTED
    
    my $not_submitted_method = $self->name . "_FORM_NOT_SUBMITTED";
    
    if ( ( my $code = $controller->can( $not_submitted_method ) )
        && !$form->submitted )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $not_submitted_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    # _RENDER
    
    my $render_method = $self->name . "_FORM_RENDER";
    
    if ( $run_form_render_action
        && ( my $code = $controller->can( $render_method ) ) )
    {
        my @reverse = split /\//, $self->reverse;
        $reverse[-1] = $render_method;
        local $self->{reverse} = join '/', @reverse;
        local $self->{code}    = $code;
        
        $c->execute( $self->class, $self, @{ $c->req->args } );
    }
    
    return;
}

1;
