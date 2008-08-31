package TestApp::Controller::Basic;

use strict;
use warnings;
use base 'Catalyst::Controller::HTML::FormFu';

sub basic : Chained : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'form.tt';
}

sub form : Chained('basic') : Args(0) : Form {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    $form->element({ name => 'basic_form' });
}

sub formconfig : Chained('basic') : Args(0) : FormConfig { }

sub formconfig_conf_ext
    : Chained('basic')
    : Args(0)
    : FormConfig('basic/formconfig_conf_ext')
{ }

sub formmethod : Chained('basic') : Args(0) : FormMethod('_load_form') { }

sub _load_form : Private {
    return {
        element => {
            name => 'basic_formmethod',
        }
    };
}

1;
