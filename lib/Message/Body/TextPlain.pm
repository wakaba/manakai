
=head1 NAME

Message::Body::TextPlain Perl module

=head1 DESCRIPTION

Perl module for text/plain media type.

=cut

package Message::Body::TextPlain;
use strict;
use vars qw($VERSION %DEFAULT);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Header;
use overload '""' => sub {shift->stringify};

%DEFAULT = (
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_body_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_body_string,
);

=head2 Message::Body::TextPlain->new ([%option])

Returns new Message::Body::TextPlain instance.  Some options can be
specified as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Body::TextPlain->parse ($body, [%option])

Returns a new Message::Body::TextPlain with given body
object.  Some options can be specified as hash.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $body = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->header ($self->{option}->{header});
  my %s = &{$self->{option}->{hook_decode_string}} ($self, $body, type => 'body');
  $self->{body} = $s{value};
  $self;
}

=head2 $self->header ([$new_header])


=cut

sub header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  } elsif ($new_header) {
    $self->{header} = Message::Header->parse ($new_header);
  }
  unless ($self->{header}) {
    $self->{header} = new Message::Header;
  }
  $self->{header};
}

=head2 $self->body ([$new_body])

Returns C<body> as string unless $new_body.
Set $new_body instead of current C<body>.

=cut

sub body ($;$) {
  my $self = shift;
  my $new_body = shift;
  if ($new_body) {
    $self->{body} = $new_body;
  }
  $self->{body};
}

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %OPT = @_;
  my (%e) = &{$self->{option}->{hook_encode_string}} ($self, 
          $self->{body}, type => 'body');
  $e{value} .= "\n" unless $e{value} =~ /\n$/;
  $e{value};
}
sub as_string ($;%) {shift->stringify (@_)}

=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $newval) = @_;
  if ($newval) {
    $self->{option}->{$name} = $newval;
  }
  $self->{option}->{$name};
}

=head1 SEE ALSO

RFC 822 <urn:ietf:rfc:822>,
RFC 2046 <urn:ietf:rfc:2046>, RFC 2646 <urn:ietf:rfc:2646>.

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
$Date: 2002/03/25 10:18:35 $

=cut

1;
