
=head1 NAME

Message::Body::TextPlainFlowed --- Perl Module for Internet Media Type "text/plain"
with "Format=Flowed" parameter

=cut

package Message::Body::TextPlainFlowed;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Body::Text;
push @ISA, qw(Message::Body::Text);

%DEFAULT = (
  -_METHODS	=> [qw|value|],
  -_MEMBERS	=> [qw|_charset|],
  #default_charset
  -parent_type	=> 'text/plain',
  -use_normalization	=> 1,
  -use_param_charset	=> 1,
);

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Structured> objects:

=over 4

=item $body = Message::Body::TextPlain->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $body = Message::Body::TextPlain->parse ($body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## parse: Inherited
sub _parse ($$) {
  my $self = shift;
  $self->SUPER::_parse (@_);
  unless ($self->{_charset}) {
    my @v;
    my @l = split /\x0D?\x0A/, $self->{value};
    
    for my $i (0..$#l) {
      if ($i == 0 || $l[$i-1] !~ /\x20$/ || $l[$i-1] eq '-- ') {
        $v[$#v+1] = {value => ''};
      }
      if ($l[$i] =~ s/^(>+)//) {
        my $depth = length $1;
        $v[$#v+1] = {value => ''} if defined $v[$#v]->{depth}
                                     && $depth != $v[$#v]->{depth};
        $v[$#v]->{depth} = $depth;
      }
      $l[$i] = substr ($l[$i], 1) if substr ($l[$i], 0, 1) eq ' ';
      $v[$#v]->{value} .= $l[$i];
    }
    $self->{value} = \@v;
  }
  $self;
}

=back

=cut

=item $body->header ([$new_header])


=cut

## Inherited

=item $body->value ([$new_body])

Returns C<body> as string unless $new_body.
Set $new_body instead of current C<body>.

=cut

## Inherited

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

## $self->_prep_stringify ($value, \%option)
sub _prep_stringify ($$\%) {
  my $self = shift;
  my ($s, $option) = @_;
  if (ref $s eq 'ARRAY') {
    join "\x0D\x0A", grep {length $_} map {
      my $quote = ('>' x $_->{depth});
      my $line_body = $_->{value};
      if ($quote) {
        $quote .= ' ';
      } else {
        $line_body = ' ' . $line_body if $line_body =~ /^(?:\x20|[Ff]rom\x20|>)/;
      }
      $line_body = $self->_fold ($line_body, -initial_length => length $quote,
                                 -quote => $quote);
      $line_body .= "\x20\x0D\x0A" . $quote if length $line_body;
      $quote . $line_body;
    } @$s;
  } else {
    $s;
  }
}

## $self->_fold ($string, %option = (-max, -initial_length) )
sub _fold ($$;%) {
  my $self = shift;
  my $string = shift;
  my %option = @_;
  my $max = 66;
  $max = 20 if $max < 20;
  $option{-newline} ||= "\x0D\x0A";
  
  my $l = 0; #$option{-initial_length} || 0;
  $string =~ s{([^\x09\x20]+[\x09\x20])}{
    my $s = $1;
    if ($l && $l + length $s > $max) {
      if (!$option{-quote} && $s =~ /^(?:\x20|[Ff]rom\x20|>)/) {
        $s = $option{-newline} . ' ' . $s;
      } else {
        $s = $option{-newline} . $option{-quote} . $s;
      }
      $l = length ($s) - 2;	## 2 is for CRLF
    } else { $l += length $s }
    $s;
  }gex;
  $string;
}

## Inherited: option, clone

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
$Date: 2002/06/09 10:57:16 $

=cut

1;
