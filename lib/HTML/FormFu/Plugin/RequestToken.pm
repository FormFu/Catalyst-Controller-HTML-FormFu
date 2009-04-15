package HTML::FormFu::Plugin::RequestToken;

use strict;
use base 'HTML::FormFu::Plugin';

__PACKAGE__->mk_item_accessors(
    qw(context field_name session_key expiration_time));

sub process {
    my ($self) = @_;
    
    return if $self->form->get_all_element( { name => $self->field_name } );
    
    my $c = $self->form->stash->{'context'};
    
    $self->form->elements( [ {
                type            => 'RequestToken',
                name            => $self->field_name,
                expiration_time => $self->expiration_time,
                context         => $self->context,
                session_key     => $self->session_key
            } ] );

    return;
}

1;
