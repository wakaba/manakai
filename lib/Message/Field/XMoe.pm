
=head1 NAME

Message::Field::XMoe --- Perl module for
Internet message C<X-Moe:> field body items

=cut

package Message::Field::XMoe;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::ValueParams;
push @ISA, qw(Message::Field::ValueParams);
*REG = \%Message::Field::ValueParams::REG;
$REG{MS_parameter_avpair_noslash} = qr/([^\x22\x2F\x3C\x3D]+)=([\x00-\xFF]*)/;

%DEFAULT = (
	#_HASH_NAME
	#_MEMBERS
	#_METHODS
	#accept_coderange
	#encoding_after_encode
	#encoding_before_decode
	#field_param_name
	#field_name
	#field_ns
	#format
	#header_default_charset
	#header_default_charset_input
	#hook_encode_string
	#hook_decode_string
	#output_comment
	-output_parameter_extension	=> 1,
	#parameter_rule
	#parameter_attribute_case_sensible
	#parameter_attribute_unsafe_rule
	-parameter_av_Mrule	=> 'MS_parameter_avpair_noslash',
	#parameter_no_value_attribute_unsafe_rule
	#parameter_value_max_length
	#parameter_value_split_length
	#parameter_value_unsafe_rule
	#parse_all
	#separator
	#separator_rule
	-use_comment	=> 1,
	-use_parameter_extension	=> 1,
	-value_case_sensible	=> 0,
	-value_default	=> '',
	-value_style	=> 'slash',	## name / slash / at
	#value_type
	-value_unsafe_rule	=> 'NON_http_attribute_char',
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
}

=item $moe = Message::Field::XMoe->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $moe = Message::Field::XMoe->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## Inherited


## $self->_decode_parameters (\@parameter, \%option)
## -- join RFC 2231 splited fragments and decode each parameter
sub _decode_parameters ($\@\%) {
  my $self = shift;
  my ($param, $option) = @_;
  my @a;
  if ($param->[0]->{no_value} && $param->[0]->{charset} eq '*bare') {
    ## first item doesn't have value and is not a quoted-string itself,
    my $name = shift (@$param)->{attribute};
    my $from = '';
    if ($name =~ m#^((?:$REG{quoted_string}|[^\x22\x2F])+)/((?:$REG{quoted_string}|[^\x22])+)$#) {
      ($from, $name) = ($1, $2);
    } elsif ($name =~ m#^((?:$REG{quoted_string}|[^\x22\x40])+)$REG{FWS}\@$REG{FWS}((?:$REG{quoted_string}|[^\x22])+)$#) {
      ($name, $from) = ($1, $2);
    }
    $name =~ s/^$REG{WSP}+//; $name =~ s/$REG{WSP}+$//;
    $self->{value} = Message::Util::decode_quoted_string ($self, $name);
    $from =~ s/^$REG{WSP}+//; $from =~ s/$REG{WSP}+$//;
    $from = Message::Util::decode_quoted_string ($self, $from) if length $from;
    if (length $from) {
      push @a, {attribute => 'of', value => $from};
    }
  } elsif ($param->[0]->{no_value}) {	## was A quoted-string
    my %s = &{$option->{hook_decode_string}}
        ($self, shift (@$param)->{attribute}, type => 'phrase/quoted-string');
    $self->{value} = $s{value};
  }
  $self->SUPER::_decode_parameters ($param, $option);
  push @$param, @a;
}

=back

=head1 METHODS

=over 4

=item $moe->replace ($name => [$value], [$name => $value,...])

Sets new parameter C<value> of $name.

  Example:
    $self->replace (age => 18);
    $self->replace (of => 'Kizuato');

=item $count = $moe->count ()

Returns the number of C<parameter>s.

=item $param-value = $moe->parameter ($name, [$new_value])

Returns given C<name>'ed C<parameter>'s C<value>.

=item $param-name = $moe->parameter_name ($index, [$new_name])

Returns (and set) C<$index>'th C<parameter>'s name.

=item $param-value = $moe->parameter_value ($index, [$new_value])

Returns (and set) C<$index>'th C<parameter>'s value.

=cut

## replace, add, count, parameter, parameter_name, parameter_value: Inherited.
## (add should not be used for these field)

sub value ($;$) {
  my $self = shift;
  my $new_value = shift;
  if (defined $new_value) {
    $self->{value} = $new_value;
  }
  $self->{value};
}

=item $field-body = $moe->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my $param = $self->SUPER::stringify_params (@_);
  my %o = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $name = $self->stringify_value || $option{value_default};
  if ($option{value_style} eq 'slash') {
    my %e = &{$option{hook_encode_string}}
      ($self,$self->parameter ('of') || '', type => 'parameter/value/quoted-string');
    my $v = Message::Util::quote_unsafe_string
      ($e{value}, unsafe => 'NON_http_token_wsp');
    $name = $v.'/'.$name if length $v;
  } elsif ($option{value_style} eq 'at') {
    my %e = &{$option{hook_encode_string}}
      ($self,$self->parameter ('of') || '', type => 'parameter/value/quoted-string');
    my $v = Message::Util::quote_unsafe_string
      ($e{value}, unsafe => 'NON_http_token_wsp');
    $name .= ' @ '.$v if length $v;
  }
  $name.(length $param? '; '.$param: '');
}

## $self->_stringify_param_check (\%item, \%option)
## -- Checks parameter (and modify if necessary).
##    Returns either 1 (ok) or 0 (don't output)
sub _stringify_param_check ($\%\%) {
  my $self = shift;
  my ($item, $option) = @_;
  if ($option->{value_style} eq 'slash' || $option->{value_style} eq 'at') {
    return (0) if $item->{attribute} eq 'of' && !$item->{no_value};
  }
  (1, $item);
}


=item $option-value = $moe->option ($option-name)

Gets option value.

=item $moe->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited.

=item $clone = $moe->clone ()

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
$Date: 2002/07/22 02:42:17 $

=cut

1;
