
=head1 NAME

Message::Entity Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<message>.
MIME multipart will be also supported (but not implemented yet).

=cut

package Message::Entity;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';

use Message::Header;
use overload '""' => sub {shift->stringify};

=head2 Message::Entity->new ([%option])

Returns new Message::Entity instance.  Some options can be
specified as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Entity->parse ($message, [%option])

Parses given C<message> and return a new Message::Entity
object.  Some options can be specified as hash.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $message = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  my ($isheader, @header, @body) = 1;
  for my $line (split /\x0D?\x0A/, $message) {
    if ($isheader && !length($line)) {
      $isheader = 0;
    } elsif ($isheader) {
      push @header, $line
    } else {
      push @body, $line;
    }
  }
  $self->{header} = Message::Header->parse (join "\n", @header);
  $self->{body} = join "\n", @body;
  $self;
}

=head2 $self->header ([$new_header])

Returns Message::Header unless $new_header.
Set $new_header instead of current C<header>.
If !ref $new_header, Message::Header->parse is automatically
called.

=cut

sub header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  } elsif ($new_header) {
    $self->{header} = Message::Header->parse ($new_header);
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

Returns the C<message> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %OPT = @_;
  my ($header, $body) = ($self->{header}, $self->{body});
  $header .= "\n" if $header && $header !~ /\n$/;
  $header."\n".$body;
}

=head2 $self->get_option ($option_name)

Returns value of the option.

=head2 $self->set_option ($option_name, $option_value)

Set new value of the option.

=cut

sub get_option ($$) {
  my $self = shift;
  my ($name) = @_;
  $self->{option}->{$name};
}
sub set_option ($$$) {
  my $self = shift;
  my ($name, $value) = @_;
  $self->{option}->{$name} = $value;
  $self;
}

=head1 EXAMPLE

  use Message::Entity;
  my $msg = new Message::Entity;
  $msg->header ($header);
  $msg->body ($body);
  print $msg;

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
$Date: 2002/03/13 14:47:07 $

=cut

1;
