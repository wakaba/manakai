
=head1 NAME

Message::Field::TypedText --- Perl module for Internet message
field body ...

=cut

package Message::Field::TypedText;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;

%DEFAULT = (
	-_MEMBERS	=> [qw/type/],
	-_METHODS	=> [qw/type value/],
	#encoding_after_encode
	#encoding_before_decode
	#field_param_name
	#field_name
	#field_ns
	#format
	#hook_encode_string
	#hook_decode_string
	-output_comment	=> 1,
	#parse_all
	-separator	=> '; ',
	-type_default	=> '',
	-use_comment	=> 1,
	-value_default	=> '',
	#value_type
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->SUPER::_init (%DEFAULT, %options);
  $self->{type} = $self->{type_default};
  $self->{value} = $self->{value_default};
}

=item $p = Message::Field::Params->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $p = Message::Field::Params->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my @param;
  use re 'eval';
  if ($body =~ /
    ((?:$REG{comment}|$REG{quoted_string}|[^\x22\x28;])*)
    (?:
    ;
    ([\x00-\xFF]*)
    )?
  /x) {
    my ($type, $value) = ($1, $2);
    ($type, @{$self->{comment}})
      = $self->Message::Util::delete_comment_to_array ($type)
      if $self->{option}->{use_comment};
    $type = Message::Util::unquote_if_quoted_string ($type);
    $self->{type} = $type || $self->{type_default};
    $value =~ s/^$REG{WSP}+//;  $value =~ s/$REG{WSP}+$//;
    $self->{value} = $value;
    $self->{value} = $self->_parse_value ($self->{type} => $self->{value})
      if $self->{option}->{parse_all};
  };
  $self;
}


=back

=head1 METHODS

=over 4

=cut

sub type ($;$) {
  my $self = shift;
  my $newtype = shift;
  if ($newtype) {
    $self->{type} = $newtype;
  }
  $self->{type};
}

sub value ($;$) {
  my $self = shift;
  my $newtype = shift;
  if ($newtype) {
    $self->{value} = $newtype;
    $self->{value} = $self->_parse_value ($self->{type} => $self->{value})
      if $self->{option}->{parse_all};
  }
  $self->{value};
}

=item $field-body = $p->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $type = $self->{type} || $option{type_default};
  my $value = $self->{value} || $option{value_default};
  $type = Message::Util::quote_unsafe_string ($type, unsafe => 'NON_atext');
  my $comment = $self->_comment_stringify;
  $comment = sprintf ' %s ', $comment if $comment;
  $type . $comment . $option{separator} . $value;
}
*as_string = \&stringify;

=item $option-value = $p->option ($option-name)

Gets option value.

=item $p->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  $self->{value}->option (%$o) if ref $self->{value};
}

## value_type: Inherited

=item $clone = $p->clone ()

Returns a copy of the object.

=cut

## Inherited

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
$Date: 2002/07/08 11:44:29 $

=cut

1;
