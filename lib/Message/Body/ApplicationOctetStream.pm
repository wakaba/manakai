
=head1 NAME

Message::Body::ApplicationOctetStream --- Perl module
for "application/octet-stream" Internet Media Type

=cut

package Message::Body::ApplicationOctetStream;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Body::Text;
push @ISA, qw(Message::Body::Text);

%DEFAULT = (
  -_METHODS	=> [qw|value|],
  -_MEMBERS	=> [qw||],
  -media_type	=> 'application',
  -media_subtype	=> 'octet-stream',
  -parse_all	=> 0,
  #use_normalization	=> 0,
  #use_param_charset	=> 0,
);

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Structured> objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  my %option = @_;
  $self->SUPER::_init (%$DEFAULT, %option);
}

=item $body = Message::Body::TextPlain->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $body = Message::Body::TextPlain->parse ($body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  $self->{value} = $body;
  $self;
}

=back

=cut

## header: Inherited
## value: Inherited

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $self->{value};
}
*as_string = \&stringify;

## Inherited: option, clone

=head1 SEE ALSO

RFC 2046 <urn:ietf:rfc:2046>

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
$Date: 2002/06/09 10:57:16 $

=cut

1;
