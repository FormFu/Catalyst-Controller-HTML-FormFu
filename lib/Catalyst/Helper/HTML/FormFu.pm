package Catalyst::Helper::HTML::FormFu;

use strict;
use warnings;

use File::Spec;
use HTML::FormFu::Deploy;
use Carp qw/ croak /;

sub mk_stuff {
    my ( $self, $helper, $dir ) = @_;
    
    my @files = HTML::FormFu::Deploy::file_list();
    
    my $form_dir = File::Spec->catdir(
        $helper->{base}, 'root', ( defined $dir ? $dir : 'formfu' )
    );
    
    $helper->mk_dir( $form_dir ) unless -d $form_dir;
    
    for my $filename (@files) {
        my $path = File::Spec->catfile( $form_dir, $filename );
        my $data = HTML::FormFu::Deploy::file_source($filename);
        
        $helper->mk_file( $path, $data );
    }
    return;
}

1;

__END__

=head1 NAME

Catalyst::Helper::HTML::FormFu - Helper to deploy HTML::FormFu template files.

=head1 SYNOPSIS

    script/myapp_create.pl HTML::FormFu

=head1 DESCRIPTION

Uses L<HTML::FormFu::Deploy> to copy L<HTML::FormFu> template files into a 
L<Catalyst> application's C<root/formfu> directory.

To change the destination directory, pass it as an extra directory. It will be 
created with the C<root> directory

The following example would deploy the template files into directory 
C<root/forms>.

    script/myapp_create.pl HTML::FormFu forms

=head1 SUPPORT

IRC:

    Join #catalyst on irc.perl.org.

Mailing Lists:

    http://lists.rawmode.org/cgi-bin/mailman/listinfo/html-widget

=head1 SEE ALSO

L<HTML::FormFu>, L<Catalyst::Helper>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
