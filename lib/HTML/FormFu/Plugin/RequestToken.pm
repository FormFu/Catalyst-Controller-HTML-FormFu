package HTML::FormFu::Plugin::RequestToken;
use Moose;

extends 'HTML::FormFu::Plugin';

has context         => ( is => 'rw', traits  => ['Chained'] );
has field_name      => ( is => 'rw', traits  => ['Chained'] );
has session_key     => ( is => 'rw', traits  => ['Chained'] );
has expiration_time => ( is => 'rw', traits  => ['Chained'] );

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
