
=head1 NAME

Message::Field::Numval Perl module

=head1 DESCRIPTION

Perl module for RFC 2822 style C<field-body>'es,
which takes numeric value.

=cut

package Message::Field::Numval;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
use overload '""' => sub {shift->stringify};

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;
$REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*)\x29/;

%DEFAULT = (
  check_max	=> -1,
  check_min	=> 1,
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  field_name	=> 'lines',
  format_pattern	=> '%d',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
  output_comment	=> -1,
  value_default	=> 0,
  value_if_invalid	=> '',
  value_max	=> 100,
  value_min	=> 0,
);

## Initialization for both C<new ()> and C<parse ()> methods.
sub _initialize ($;%) {
  my $self = shift;
  my $fname = lc $self->{option}->{field_name};
  if ($fname eq 'mime-version') {
    $self->{option}->{output_comment} = 1;
    $self->{option}->{format_pattern} = '%1.1f';
    $self->{option}->{check_max} = 1;
    $self->{option}->{value_min} = 1;
  }
  $self;
}

=head2 Message::Field::Numval->new ()

Return empty Message::Field::Numval object.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {comment => [], option => {@_}}, $class;
  $self->_initialize ();
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->{value} = $self->{option}->{value_default};
  $self->{value} = $DEFAULT{value_default} unless defined $self->{value};
  $self;
}

=head2 Message::Field::Numval->parse ($unfolded_field_body)

Parses C<field-body> consist of a numeric value.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $field_body = shift;
  my $self = bless {comment => [], option => {@_}}, $class;
  $self->_initialize ();
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->{option}->{value_default} = $DEFAULT{value_default}
    unless defined $self->{option}->{value_default};
  $field_body =~ s{$REG{M_comment}}{
      my $comment = $self->_decode_ccontent ($1);
      push @{$self->{comment}}, $comment if $comment;
    '';
  }goex;
  $field_body =~ s/[^0-9.-]//g;
  $self->{value} = $& if $field_body =~ /-?[0-9]+(\.[0-9]+)?/;
  $self->{value} = $self->{option}->{value_default} unless defined $self->{value};
  $self;
}

=head2 $self->value ([$new_value])

Returns or set value.  Note that this method
does not check whether value is valid or not.

=head2 $self->value_formatted ()

Returns formatted value string.  Note that this method
does not check whether value is valid or not.
To check min/max value, use C<stringify> with
C<output_comment = -1> option (if necessary).

=cut

sub value ($;$%) {
  my $self = shift;
  my $new_value = shift;
  if ($new_value) {
    $self->{value} = $new_value;
  }
  $self->{value};
}

sub value_formatted ($;%) {
  my $self = shift;
  my %option = @_;
  $option{format_pattern} = $self->{option}->{format_pattern}
    unless defined $option{format_pattern};
  sprintf $option{format_pattern}, $self->{value};
}

=head2 $self->comment_add ($comment, [%option]

Adds a C<comment>.  Comments are outputed only when
the class option (not an option of this method!)
 C<output_comment> is enabled (value C<1>).

On this method, only one option, C<prepend> is available.
With this option, additional comment is prepend
to current comments.  (Default value is C<-1>, append.)

=cut

sub comment_add ($$;%) {
  my $self = shift;
  my ($value, %option) = (shift, @_);
  if ($option{prepend}) {
    unshift @{$self->{comment}}, $value;
  } else {
    push @{$self->{comment}}, $value;
  }
  $self;
}

=head2 $self->comment ()

Returns array reference of comments.  You can add/remove/change
array values.

=cut

sub comment ($) {
  my $self = shift;
  $self->{comment};
}

=head2 $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{check_max} ||= $self->{option}->{check_max};
  $option{check_min} ||= $self->{option}->{check_min};
  $option{output_comment} ||= $self->{option}->{output_comment};
  $option{format_pattern} = $self->{option}->{format_pattern}
    unless defined $option{format_pattern};
  $option{value_max} ||= $self->{option}->{value_max};
  $option{value_min} ||= $self->{option}->{value_min};
  $option{value_if_invalid} ||= $self->{option}->{value_if_invalid};
  return $option{value_if_invalid}
    if $option{check_max}>0 && $option{value_max}<$self->{value};
  return $option{value_if_invalid}
    if $option{check_min}>0 && $option{value_min}>$self->{value};
  my $s = sprintf $option{format_pattern}, $self->{value};
  if ($option{output_comment}>0) {
    for (@{$self->{comment}}) {
      my %f = &{$self->{option}->{hook_encode_string}} ($self, 
         $_, type => 'ccontent');
      $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/
        "\x5C$1".(defined $2?"\x5C$2":'')/ge;
      $s .= ' ('.$f{value}.')' if defined $f{value};
    }
  }
  $s;
}

sub _decode_ccontent ($$) {
  require Message::MIME::EncodedWord;
  &Message::MIME::EncodedWord::decode_ccontent (@_[1,0]);
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
