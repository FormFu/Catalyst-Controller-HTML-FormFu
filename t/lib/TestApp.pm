package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use FindBin;

use Catalyst qw/ ConfigLoader /;

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestApp',
    home => $FindBin::Bin,
);

__PACKAGE__->setup;

1;
