
=head1 NAME

Message::Field::XMoe --- Perl module for
Internet message C<X-Moe:> field body items

=cut

package Message::Field::XMoe;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::ValueParams;
push @ISA, qw(Message::Field::ValueParams);
*REG = \%Message::Field::Params::REG;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    #delete_fws
    #encoding_after_encode
    #encoding_before_decode
    #field_name
    #field_param_name
    #format
    #hook_encode_string
    #hook_decode_string
    #parameter_name_case_sensible
    -parameter_rule	=> 'param_free',
    #parameter_value_max_length
    #parse_all
    -use_parameter_extension	=> 1,
    -value_default	=> 'Moe',
    -value_style	=> 'slash',	## name / slash / at
    #value_type
  );
  $self->SUPER::_init (%DEFAULT, %options);
}

## Initialization for new () method.
#sub _initialize_new ($;%) {
#  my $self = shift;
#}

## Initialization for parse () method.
#sub _initialize_parse ($;%) {
  ## Inherited
#}

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

sub _restore_param ($@) {
  my $self = shift;
  my @p = @_;
  my ($name, $from) = ('', '');
  if ($p[0]->[1]->{is_parameter} == 0) {
    $name = shift (@p)->[0];
    if ($name =~ m#^((?:$REG{quoted_string}|[^\x22\x2F])+)/((?:$REG{quoted_string}|[^\x22])+)$#) {
      ($from, $name) = ($1, $2);
    } elsif ($name =~ m#^((?:$REG{quoted_string}|[^\x22\x40])+)$REG{FWS}\@$REG{FWS}((?:$REG{quoted_string}|[^\x22])+)$#) {
      ($name, $from) = ($1, $2);
    }
    $self->{value} = Message::Util::decode_quoted_string ($self, $name);
    $from = Message::Util::decode_quoted_string ($self, $from) if $from;
    if (length $from) {
      push @p, [of => {value => $from, is_parameter => 1, is_internal => 1}];
    }
  }
  $self->SUPER::_restore_param (@p);
}

sub _save_param ($@) {
  my $self = shift;
  $self->SUPER::__save_param (@_);
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

=item $field-body = $moe->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my $param = $self->SUPER::stringify_params (@_);
  my $name = $self->value_as_string || $self->{option}->{value_default};
  if ($self->{option}->{value_style} eq 'slash') {
    my %e = &{$self->{option}->{hook_encode_string}} ($self, 
            $self->parameter ('of') || '', type => 'phrase');
    my $v = Message::Util::quote_unsafe_string ($e{value}, 
          unsafe => 'NON_http_token_wsp');
    $name = $v.'/'.$name if length $v;
  } elsif ($self->{option}->{value_style} eq 'at') {
    my %e = &{$self->{option}->{hook_encode_string}} ($self, 
            $self->parameter ('of') || '', type => 'phrase');
    my $v = Message::Util::quote_unsafe_string ($e{value}, 
          unsafe => 'NON_http_token_wsp');
    $name .= ' @ '.$v if length $v;
  }
  $name.(length $param? '; '.$param: '');
}

sub _stringify_params_check ($$$) {
  my $self = shift;
  my ($name, $value) = @_;
  if ($self->{option}->{value_style} eq 'slash'
   || $self->{option}->{value_style} eq 'at') {
    return 0 if $name eq 'of' && $value->{is_parameter};
  }
  1;
}

sub value ($;$) {
  my $self = shift;
  my $new_value = shift;
  if (defined $new_value) {
    $self->{value} = $new_value;
  }
  $self->{value};
}
sub value_as_string ($) {
  my $self = shift;
  my %e = &{$self->{option}->{hook_encode_string}} ($self, 
            $self->{value}, type => 'phrase');
  Message::Util::quote_unsafe_string ($e{value}, 
          unsafe => 'NON_http_token_wsp');
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
$Date: 2002/05/04 06:03:58 $

=cut

1;
