
=head1 NAME

Message::Field::ValueParams --- Perl module for "word; parameter(s)" style
Internet message field bodies

=cut

package Message::Field::ValueParams;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Params;
push @ISA, qw(Message::Field::Params);

use overload '+=' => sub { $_[0]->{value} = $_[0]->{value} + $_[1]; $_[0] },
             '-=' => sub { $_[0]->{value} = $_[0]->{value} - $_[1]; $_[0] },
             '*=' => sub { $_[0]->{value} = $_[0]->{value} * $_[1]; $_[0] },
             '**=' => sub { $_[0]->{value} = $_[0]->{value} ** $_[1]; $_[0] },
             '/=' => sub { $_[0]->{value} = $_[0]->{value} / $_[1]; $_[0] },
             '%=' => sub { $_[0]->{value} = $_[0]->{value} % $_[1]; $_[0] },
             fallback => 1;

*REG = \%Message::Field::Params::REG;
## Inherited: comment, quoted_string, domain_literal, angle_quoted
	## WSP, FWS, atext, atext_dot, token, attribute_char
	## S_encoded_word
	## M_quoted_string
	## param, parameter
	## M_parameter, M_parameter_name, M_parameter_extended_value

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
	#output_parameter_extension
	#parameter_rule
	#parameter_attribute_case_sensible
	#parameter_attribute_unsafe_rule
	#parameter_av_Mrule
	#parameter_no_value_attribute_unsafe_rule
	#parameter_value_max_length
	#parameter_value_split_length
	#parameter_value_unsafe_rule
	#parse_all
	#separator
	#separator_rule
	#use_comment
	#use_parameter_extension
	-value_case_sensible	=> 1,
	-value_default	=> '',
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
  push @{$self->{option}->{_METHODS}}, 'value';
  
  my $fname = $self->{option}->{field_name};
  my $format = $self->{option}->{format};
  if ($fname eq 'disposition') {	## Content-Disposition
    $self->{option}->{value_case_sensible} = 0;
    $self->{option}->{value_default} = 'inline';
    unless ($self->{option}->{format} =~ /http/) {
      $self->{option}->{output_parameter_extension} = 1;
    }
    my $dateclass = ['Message::Field::Date', {format => 'mail-rfc822+rfc1123'}];
    $self->{option}->{value_type}->{'creation-date'} = $dateclass;
    $self->{option}->{value_type}->{'modification-date'} = $dateclass;
    $self->{option}->{value_type}->{'read-date'} = $dateclass;
  } elsif ($fname eq 'transfer-encoding') {	## Content-Transfer-Encoding
    $self->{option}->{value_case_sensible} = 0;
    if ($format =~ /http/) {
      $self->{option}->{value_default} = 'binary';
    } else {
      $self->{option}->{value_default} = '7bit';
    }
    $self->{option}->{output_parameter_extension} = 1;
  } elsif ($fname eq 'link') {
    $self->{option}->{value_type}->{'*value'} = ['Message::Field::URI'];
  } elsif ($fname eq 'auto-submitted') {
    $self->{option}->{value_type}->{increment} = ['Message::Field::Numval'];
  } elsif ($fname eq 'opt' || $fname eq 'man') {
    $self->{option}->{value_unsafe_rule} = 'MATCH_ALL';
  }
  $self->{value} = $self->{option}->{value_default};
}

=item $vp = Message::Field::ValueParams->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $vp = Message::Field::ValueParams->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## Inherited

## $self->_save_parameters (\@parameter, \%option)
## -- Save parameters in $self
sub _save_parameters ($\@\%) {
  my $self = shift;
  my ($param, $option) = @_;
  if ($param->[0]->{no_value}) {
    $self->{value} = shift (@$param)->{attribute};
    $self->{value} = $self->_parse_value ('*value' => $self->{value})
      if $option->{parse_all};
  }
  $self->SUPER::_save_parameters ($param, $option);
}

=back

=head1 METHODS

=over 4

=item $vp->add ($name => [$value], [$name => $value,...])

Sets new parameter C<value> of $name.

  Example:
    $vp->add (title => 'foo of bar');	## title="foo of bar"
    $vp->add (subject => 'hogehoge, foo');	## subject*=''hogehoge%2C%20foo
    $vp->add (foo => 'bar', language => 'en')	## foo*='en'bar

This method returns array reference of (name, {value => value, attribute...}).
C<value> is same as returned value of C<$self-E<gt>parameter>.

Available options: charset (charset name), language (language tag),
value (1/0, see example above).

=item $vp->replace ($name => [$value], [$name => $value,...])

=item $count = $vp->count

Returns the number of C<parameter>s.

=item $param-value = $vp->parameter ($name, [$new_value])

Returns given C<name>'ed C<parameter>'s C<value>.

Note that when $self->{option}->{value_type}->{$name}
is defined (and it is class name), returned value
is a reference to the object.

=item $param-name = $vp->parameter_name ($index, [$new_name])

Returns (and set) C<$index>'th C<parameter>'s name.

=item $param-value = $vp->parameter_value ($index, [$new_value])

Returns (and set) C<$index>'th C<parameter>'s value.

Note that when $self->{option}->{value_type}->{$name}
is defined (and it is class name), returned value
is a reference to the object.

=cut

## add, replace, count, parameter, parameter_name, parameter_value: Inherited.

=item $value = $vp->value ([$new_value])

Returns or set value.

=cut

sub value ($;$%) {
  my $self = shift;
  my $new_value = shift;
  my %option = @_;
  if (defined $new_value) {
    $self->{value} = $new_value;
  }
  $self->{value} = $self->_parse_value ('*value' => $self->{value});
  $self->{option}->{value_case_sensible}? $self->{value}: lc $self->{value};
}

=item $value = $vp->stringify_value ([%options])

Returns value.  If necessary, quoted and encoded in
message format.  Same as C<stringify> except that
only first "value" is outputed.

=cut

sub stringify_value ($;%) {
  my $self = shift;
  my (%e) = &{$self->{option}->{hook_encode_string}}
    ($self, $self->{value}, type => 'phrase');
  Message::Util::quote_unsafe_string
    ($e{value}, unsafe => $self->{option}->{value_unsafe_rule});
}


=item $field-body = $vp->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my $param = $self->stringify_params (@_);
  $self->stringify_value (@_).(length $param? '; '.$param: '');
}
*as_string = \&stringify;

## This method is intended to be used by child classes
sub stringify_params ($;%) {
  shift->SUPER::stringify (@_);
}

=item $option-value = $vp->option ($option-name)

Gets option value.

=item $vp->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited.

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  $self->{value}->option (%$o) if ref $self->{value};
  $self->SUPER::_option_recursive (%$o);
}

=item $clone = $ua->clone ()

Returns a copy of the object.

=cut

## Inherited

=head1 EXAMPLE

  use Message::Field::ValueParams;
  my $cd = new Message::Field::ValueParams (-field_name => 'Content-Disposition');
  $cd->type ('attachment');
  $cd->parameter ('filename' => 'foobar');
  $cd->parameter ('creation-date' => '')->unix_time (0);
  print $cd;	## attachment; filename=foobar; 
            	## creation-date="Thr, 01 Jan 1970 00:00:00 +0000"

  use Message::Field::ValueParams;
  my $b = q{attachment; filename*=iso-2022-jp''%1B%24B%25U%25%21%25%24%25k%1B%28B};
  my $cd = Message::Field::ValueParams->parse ($b,
                    -field_name => 'Content-Disposition');
  my $filename = $cd->parameter ('FileName');
  if (!$filename || $filename =~ /[^A-Za-z0-9.,_~=+-]/ || -e $filename) {
    ## $filename can be unsafe, see RFC 2183.
    $filename = 'default';
  }
  open MSG, "> $filename";
    print $something;
  close MSG;

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
$Date: 2002/07/06 10:30:43 $

=cut

1;
