package TestApp::Controller::MultiForm;

use strict;
use warnings;
use base 'Catalyst::Controller::HTML::FormFu';

sub multiform : Chained : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'multiform.tt';
}

sub formconfig : Chained('multiform') : Args(0) : MultiFormConfig {
    my ( $self, $c ) = @_;

    my $multi = $c->stash->{multiform};

    if ( $multi->complete ) {
        my $params = $multi->current_form->params;

        $c->stash->{results} = join "\n", map {
            sprintf "%s: %s", $_, $params->{$_}
        } keys %$params;

        $c->stash->{message} = 'Complete';
    }
}

sub end : ActionClass('RenderView') {}

1;
