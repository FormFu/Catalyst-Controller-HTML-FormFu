package HTML::FormFu::Element::RequestToken;

use strict;

use base 'HTML::FormFu::Element::Text';
use Class::C3;

use HTML::FormFu::Util qw( process_attrs );
use Carp qw( croak );

__PACKAGE__->mk_item_accessors(qw(expiration_time session_key context));

*default = \&value;

sub new {
    my $self = shift->next::method(@_);
    
    $self->field_type('hidden');
    $self->session_key('__token');
    $self->context('context');
    $self->name('_token');
    $self->expiration_time(3600);
    $self->constraints( [qw(RequestToken Required)] );
    
    return $self;
}

sub value {
    my $self = shift;
    
    if (@_) {
        $self->{value} = shift;
        return $self;
    }
    
    if ( !defined $self->{value} ) {
        return $self->{value} = $self->get_token;
    }
    
    return $self->{value};
}

sub verify_token {
    my ($self) = @_;
    
    my $form = $self->form;
    
    croak "verify_token() can only be called if form is submitted"
        if !$form->submitted;
    
    my $field_name = $self->name;
    
    croak "verify_token() can only be called after \$form->process() has completed"
        if !$form->valid( $field_name );
    
    return $self->remove_token( $form->param_value( $field_name ) );
}

sub remove_token {
    my ( $self, $token ) = @_;
    
    my $c = $self->form->stash->{ $self->context };
    
    my @token;
    my $found = 0;
    
    for ( @{ $c->session->{ $self->session_key } || [] } ) {
        if ( $_->[0] ne $token ) {
            push( @token, $_ );
        }
        else {
            $found = 1;
        }
    }
    
    $c->session->{ $self->session_key } = \@token;
    
    return $found;
}

sub expire_token {
    my ($self) = @_;
    
    my $c = $self->form->stash->{ $self->context };
    
    my @token;
    for ( @{ $c->session->{ $self->session_key } || [] } ) {
        push( @token, $_ ) if ( $_->[1] > time );
    }
    
    $c->session->{ $self->session_key } = \@token;
}

sub get_token {
    my ($self) = @_;
    
    my $token;
    my $c = $self->form->stash->{ $self->context };
    my @chars = ( 'a' ... 'z', 0 .. 9 );
    
    $token .= $chars[ int( rand() * 36 ) ] for ( 0 .. 15 );
    
    $c->session->{ $self->session_key } ||= [];
    
    push @{ $c->session->{ $self->session_key } },
        [ $token, time + $self->expiration_time ];
    
    $self->expire_token;
    
    return $token;
}

1;

__END__

=head1 NAME

HTML::FormFu::Element::RequestToken - Hidden text field which contains a unique token

=head1 SYNOPSIS

  my $e = $form->element( { type => 'Token' } );
  
  my $p = $form->element( { plugin => 'Token' } );

=head1 DESCRIPTION

This field can prevent CSRF attacks. It contains a random token. After submission the token is checked with the token which is stored in the session of the current user.
See L<Catalyst::Controller::HTML::FormFu/USING TOKENS> for a convenient way how to use it.

=head1 ATTRIBUTES

=head2 context

Value of the stash key for the Catalyst context object (C<< $c >>). Defaults to C<context>.

=head2 expiration_time

Time to life for a token in seconds. Defaults to C<3600>.

=head2 session_key

Session key which is used to store the tokens. Defaults to C<__token>.

=head1 METHODS

=head2 expire_token

This method looks in the session for expired tokens and removes them.

=head2 get_token

Generates a new token and stores it in the stash.

=head2 remove_token

Removes a specific token from the session. Returns C<1> if the key was found. C<0> otherwise.

=head2 verify_token

Checks whether a given token is already in the session. If it exists it is removed and C<verify_token> returns C<1>. C<0> otherwise.

=head1 SEE ALSO

L<Catalyst::Controller::HTML::FormFu>, 
L<HTML::FormFu::Plugin::RequestToken>, 
L<HTML::FormFu::Constraint::RequestToken>

L<HTML::FormFu>

=head1 AUTHOR

Moritz Onken, C<onken@houseofdesign.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.
