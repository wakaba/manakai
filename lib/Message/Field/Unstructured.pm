
=head1 NAME

Message::Field::Unstructured Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 Unstructured C<field>s.

=cut

package Message::Field::Unstructured;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
use overload '""' => sub {shift->stringify};

%DEFAULT = (
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
);

=head2 Message::Field::Unstructured->new ()

Returns new Unstructured Header Field object.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Field::Unstructured->new ($field_body)

Reads and returns Unstructured Header Field object.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $field_body = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  my %s = &{$self->{option}->{hook_decode_string}} ($self, $field_body,
            type => 'text');
  $self->{field_body} = $s{value};
  $self;
}

=head2 $self->stringify ([%options])

Returns C<field-body>.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  my (%e) = &{$self->{option}->{hook_encode_string}} ($self, 
          $self->{field_body}, type => 'text');
  $e{value};
}
sub as_string ($;%) {shift->stringify (@_)}

sub as_plain_string ($;%) {
  shift->{field_body};
}

=head1 LICENSE

Copyright 2002 wakaba E<lt>w@suika.fam.cxE<gt>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=head1 CHANGE

See F<ChangeLog>.

=cut

1;
