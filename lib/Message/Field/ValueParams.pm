
=head1 NAME

Message::Field::ValueParams Perl module

=head1 DESCRIPTION

Perl module for "word; parameter(s)" style field body.

=cut

package Message::Field::ValueParams;
use strict;
BEGIN {
  no strict;
  use base Message::Field::Params;
  use vars qw(%DEFAULT %REG $VERSION);
}
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

%REG = %Message::Field::Params::REG;

%DEFAULT = (
  use_parameter_extension	=> 1,
  value_default	=> '',
  value_no_regex	=> qr/(?!)/,	## default = (none)
  value_regex	=> qr/[\x00-\xFF]+/,
  value_unsafe_rule	=> 'NON_http_token_wsp',
);

## Initialization for both C<new ()> and C<parse ()> methods.
sub _initialize ($;%) {
  my $self = shift;
  my $fname = lc $self->{option}->{field_name};
  if ($fname eq 'link') {
    $REG{r_nomatch} = qr/(?!)/;
    $self->{option}->{value_unsafe_rule} = 'r_nomatch';
    $self->{option}->{value_type}->{'*value'} = ['Message::Field::URI',
      {field_name => $self->{option}->{field_name},
      format => $self->{option}->{format}}];
  }
  $self;
}

=head2 Message::Field::ValueParams->new ([%option])

Returns new Message::Field::ValueParams.  Some options can be given as hash.

=cut

## Inherited

## Initialization for new () method.
sub _initialize_new ($;%) {
  my $self = shift;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->{word} = $self->{option}->{value_default};
}

## Initialization for parse () method.
sub _initialize_parse ($;%) {
  my $self = shift;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
}

=head2 Message::Field::ValueParams->parse ($nantara, [%option])

Parse Message::Field::ValueParams and new ValueParams instance.  
Some options can be given as hash.

=cut

## Inherited

sub _save_param ($@) {
  my $self = shift;
  my @p = @_;
  if ($p[0]->[1]->{is_parameter} == 0) {
    my $type = shift (@p)->[0];
    if ($type && $type !~ /$self->{option}->{value_no_regex}/) {
      $self->{value} = $type;
    } elsif ($type) {
      push @p, ['x-invalid-value' => {value => $type, is_parameter => 1}];
    }
  }
  $self->{value} ||= $self->{option}->{value_default};
  $self->{param} = \@p;
  $self;
}

=head2 $self->replace ($name, $value, [%option]

Sets new parameter C<value> of $name.

  Example:
    $self->add (title => 'foo of bar');	## title="foo of bar"
    $self->add (subject => 'hogehoge, foo');	## subject*=''hogehoge%2C%20foo
    $self->add (foo => 'bar', language => 'en')	## foo*='en'bar

This method returns array reference of (name, {value => value, attribute...}).
C<value> is same as returned value of C<$self-E<gt>parameter>.

Available options: charset (charset name), language (language tag),
value (1/0, see example above).

=head2 $self->count ()

Returns the number of C<parameter>.

=head2 $self->parameter ($name, [$new_value])

Returns given C<name>'ed C<parameter>'s C<value>.

Note that when $self->{option}->{value_type}->{$name}
is defined (and it is class name), returned value
is a reference to the object.

=head2 $self->parameter_name ($index, [$new_name])

Returns (and set) C<$index>'th C<parameter>'s name.

=head2 $self->parameter_value ($index, [$new_value])

Returns (and set) C<$index>'th C<parameter>'s value.

Note that when $self->{option}->{value_type}->{$name}
is defined (and it is class name), returned value
is a reference to the object.

=cut

## replace, count, parameter, parameter_name, parameter_value: Inherited.
## add: inherited but should not be used.

## Hook called before returning C<value>.
## $self->_param_value ($name, $value);
## -- Inherited.

=head2 $self->stringify ([%option])

Returns Content-Disposition C<field-body> as a string.

=head2 $self->as_string ([%option])

An alias of C<stringify>.

=cut

sub stringify ($;%) {
  my $self = shift;
  my $param = $self->SUPER::stringify (@_);
  $self->value_as_string (@_).($param? '; '.$param: '');
}

=head2 $self->value ([$new_value])

Returns or set value.

=cut

sub value ($;$%) {
  my $self = shift;
  my $new_value = shift;
  my %option = @_;
  if ($new_value && $new_value !~ m#$self->{option}->{value_no_regex}#) {
    $self->{value} = $new_value;
  }
  $self->{value} = $self->_param_value ('*value', $self->{value});
  $self->{value};
}

=head2 $self->value_as_string ([%options])

Returns value.  If necessary, quoted and encoded in
message format.  Same as C<stringify> except that
only first "value" is outputed.

=cut

sub value_as_string ($;%) {
  my $self = shift;
  my %option = @_;
  my (%e) = &{$self->{option}->{hook_encode_string}} ($self, 
          $self->{value}, type => 'phrase');
  my $unsafe_rule = $option{unsafe_rule} || $self->{option}->{value_unsafe_rule};
  $self->_quote_unsafe_string ($e{value}, unsafe_regex => $REG{$unsafe_rule});
}


=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

## Inherited.


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
$Date: 2002/03/31 13:11:55 $

=cut

1;
