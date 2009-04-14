package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use FindBin;

use Catalyst
    qw/ Session Session::State::Cookie Session::Store::File ConfigLoader /;

our $VERSION = '0.01';

__PACKAGE__->config(
    name                       => 'TestApp',
    home                       => $FindBin::Bin,
    'Controller::HTML::FormFu' => { default_action_use_path => 1, },
);

__PACKAGE__->setup;

1;
