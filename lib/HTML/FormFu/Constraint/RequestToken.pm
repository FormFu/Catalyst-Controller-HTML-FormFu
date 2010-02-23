package HTML::FormFu::Constraint::RequestToken;

use base 'HTML::FormFu::Constraint';

use strict;
use warnings;

sub new {
	my $self = shift->next::method(@_);
	$self->message($self->parent->message);
	return $self;
}

sub constrain_value {
    my ( $self, $value ) = @_;
    
    return $self->parent->verify_token( $value );
}
1;
