use strict;
use warnings;

use Test::More tests => 17;

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/token/form');

my ($form) = $mech->forms;

ok( $form, 'Found form' );

ok( $form->find_input('basic_form'), 'found input field' );

ok( my $token = $form->find_input('_token'), 'found token field' );

$token = $token->value;

like( $token, qr/^[a-z0-9]+$/, 'token value looks like a token' );

ok( my $res = $mech->submit_form( fields => { '_token' => "123" } ),
    'submit with different token' );

unlike( $res->as_string, qr/VALID/, 'form is not valid' );

ok( $res = $mech->submit_form( fields => { '_token' => $token } ),
    'submit with valid token' );

like( $res->as_string, qr/VALID/, 'form is valid' );
$mech->get_ok( 'http://localhost/token/dump_session', 'get session content' );

my $VAR1;
eval $mech->content;
is( @{ $VAR1->{'__token'} }, 2, "3 requests minus one submit equals 2" );

$mech->get_ok(
    'http://localhost/tokenexpire/form',
    'get token with negative expiration time'
);

($form) = $mech->forms;

ok( $form, 'Found form' );

ok( $form->find_input('basic_form'), 'found input field' );

ok( $token = $form->find_input('token'), 'found token field' );

$mech->get_ok( 'http://localhost/token/dump_session', 'get session data' );

eval $mech->content;

is( @{ $VAR1->{'__token'} }, 2, "still 2 token" );

