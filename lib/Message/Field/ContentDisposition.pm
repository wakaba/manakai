
=head1 NAME

Message::Field::ContentDisposition Perl module

=head1 DESCRIPTION

Perl module for C<Content-Disposition:> field body.

=cut

package Message::Field::ContentDisposition;
use strict;
BEGIN {
  no strict;
  use base Message::Field::Params;
  use vars qw(%DEFAULT %REG $VERSION);
}
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

%REG = %Message::Field::Params::REG;

%DEFAULT = (
  use_parameter_extension	=> 1,
  value_type => {'*DEFAULT'	=> ':none:',
    'creation-date'	=> 'Message::Field::Date',
    'modification-date'	=> 'Message::Field::Date',
    'read-date'	=> 'Message::Field::Date',
  },
);

=head2 Message::Field::ContentDisposition->new ([%option])

Returns new Message::Field::ContentDisposition.  Some options can be given as hash.

=cut

## Inherited

## Initialization for new () method.
sub _initialize_new ($;%) {
  my $self = shift;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->{type} = 'inline';
}

## Initialization for parse () method.
sub _initialize_parse ($;%) {
  my $self = shift;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
}

=head2 Message::Field::ContentDisposition->parse ($nantara, [%option])

Parse Message::Field::ContentDisposition and new ContentDisposition instance.  
Some options can be given as hash.

=cut

## Inherited

sub _save_param ($@) {
  my $self = shift;
  my @p = @_;
  if ($p[0]->[1]->{is_parameter} == 0) {
    my $type = shift (@p)->[0];
    if ($type && $type !~ /$REG{NON_token}/) {
      $self->{type} = $type;
    } elsif ($type) {
      push @p, ['x-invalid-type' => {value => $type, is_parameter => 1}];
    }
  }
  $self->{type} ||= 'inline';
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
sub _param_value ($$$) {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my $vtype = $self->{option}->{value_type}->{$name}
           || $self->{option}->{value_type}->{'*DEFAULT'};
  if (ref $value) {
    return $value;
  } elsif ($vtype eq ':none:') {
    return $value;
  } elsif ($value) {
    eval "require $vtype";
    return $vtype->parse ($value);
  } else {
    eval "require $vtype";
    return $vtype->new ();
  }
}

=head2 $self->stringify ([%option])

Returns Content-Disposition C<field-body> as a string.

=head2 $self->as_string ([%option])

An alias of C<stringify>.

=cut

sub stringify ($;%) {
  my $self = shift;
  my $param = $self->SUPER::stringify (@_);
  $self->type ().($param? '; '.$param: '');
}

=head2 $self->type ([$new_value])

Returns or set disposition type.

=cut

sub type ($;$) {
  my $self = shift;
  my $new_value = shift;
  if ($new_value && $new_value !~ m#$REG{NON_http_token}#) {
    $self->{type} = $new_value;
  }
  $self->{type};
}
sub value ($;$) {shift->type}


=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

## Inherited.

=head1 STANDARDS

This module supports MIME (RFC 1806 and RFC 2183, 
ammended by RFC 2184, RFC 2231), HTTP (HTTP/1.0, HTTP/1.1).

On C<Content-Disposition:> header field of non-MIME specifications
(and that of MIME with RFC 1806), extended parameter
syntax (character set and language specification, encoded
parameter value and continuation) is not allowed.
To use such environment, specify use_extended_parameter = -1.
(Even this value is -1, decode of those parameter values
is still enabled.)

  ## Examples
  my $ct = new Message::Field::ContentDisposition (use_extended_parameter => -1);
  ## or
  my $ct = new Message::Field::ContentDisposition;
  $ct->option (use_extended_parameter => -1);

=head1 EXAMPLE

  use Message::Field::ContentDisposition;
  my $cd = new Message::Field::ContentDisposition;
  $cd->type ('attachment');
  $cd->parameter ('filename' => 'foobar');
  $cd->parameter ('creation-date' => '')->unix_time (0);
  print $cd;	## attachment; filename=foobar; 
            	## creation-date="Thr, 01 Jan 1970 00:00:00 +0000"

  use Message::Field::ContentDisposition;
  my $b = q{attachment; filename*=iso-2022-jp''%1B%24B%25U%25%21%25%24%25k%1B%28B};
  my $cd = Message::Field::ContentDisposition->parse ($b);
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
$Date: 2002/04/02 11:52:12 $

=cut

1;
