
=head1 NAME

Message::Field::Numval --- Perl module for
Internet message header field body that takes numeric values

=cut

package Message::Field::Numval;
use strict;
use vars qw(@ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
use overload '.=' => sub { $_[0]->comment_add ($_[1]); $_[0] },
             '0+' => sub { $_[0]->{value} || $_[0]->{option}->{value_default} },
             '+=' => sub {
               my $n = 0;#$_[0]->{value} + $_[1];
               $_[0]->{value} = $n if $n <= $_[0]->{option}->{value_max};
               $_[0]
             },
             '-=' => sub {
               my $n = $_[0]->{value} - $_[1];
               $_[0]->{value} = $n if $_[0]->{option}->{value_min} <= $n;
               $_[0]
             },
             '*=' => sub {
               my $n = $_[0]->{value} * $_[1];
               $_[0]->{value} = $n if $n <= $_[0]->{option}->{value_max};
               $_[0]
             },
             '**=' => sub {
               my $n = $_[0]->{value} ** $_[1];
               $_[0]->{value} = $n if $n <= $_[0]->{option}->{value_max};
               $_[0]
             },
             '/=' => sub {
               my $n = $_[0]->{value} / $_[1];
               $_[0]->{value} = $n if $_[0]->{option}->{value_min} <= $n;
               $_[0]
             },
             '%=' => sub {
               my $n = $_[0]->{value} % $_[1];
               $_[0]->{value} = $n if $_[0]->{option}->{value_min} <= $n;
               $_[0]
             },
             'eq' => sub { $_[0]->stringify eq $_[1] },
             'ne' => sub { $_[0]->stringify eq $_[1] },
             fallback => 1;

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Numval> objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -check_max	=> 0,
    -check_min	=> 1,
    #encoding_after_encode	## Inherited
    #encoding_before_decode	## Inherited
    -field_name	=> 'lines',
    -field_param_name	=> '',
    -format_pattern	=> '%d',
    #hook_encode_string	## Inherited
    #hook_decode_string	## Inherited
    -output_comment	=> 0,
    -value_default	=> 0,
    -value_if_invalid	=> '',
    -value_max	=> 100,
    -value_min	=> 0,
  );
  $self->SUPER::_init (%DEFAULT, %options);
  $self->{value} = $self->{options}->{value_default};
  $self->{value} = $options{value} if defined $options{value};
  $self->{comment} = [];
  push @{$self->{comment}}, $options{comment} if length $options{comment};
  
  my $fname = lc $self->{option}->{field_name};
  my $pname = lc $self->{option}->{field_param_name};
  if ($fname eq 'mime-version') {
    $self->{option}->{output_comment} = 1;
    $self->{option}->{format_pattern} = '%1.1f';
    $self->{option}->{value_min} = 1;
  } elsif ($fname eq 'x-priority' || $fname eq 'x-jsmail-priority') {
    $self->{option}->{output_comment} = 1;
    $self->{option}->{check_max} = 1;
    $self->{option}->{check_min} = 1;
    $self->{option}->{value_min} = 1;	## Highest
    $self->{option}->{value_max} = 5;	## some implemention uses larger number...
  } elsif ($fname eq 'auto-submitted' && $pname eq 'increment') {
    $self->{option}->{output_comment} = 0;
    $self->{option}->{check_min} = 1;
    $self->{option}->{value_min} = 0;
    $self->{option}->{value_if_invalid} = undef;
  }
}

=item Message::Field::Numval->new ([%options])

Constructs a new C<Message::Field::Numval> object.  You might pass some 
options as parameters to the constructor.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  $self;
}

=item Message::Field::Numval->parse ($field-body, [%options])

Constructs a new C<Message::Field::Numval> object with
given field body.  You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $fb = shift;
  $self->_init (@_);
  push @{$self->{comment}}, $self->Message::Util::comment_to_array ($fb);
  $fb =~ s/[^0-9.-]//g;
  $self->{value} = $& if $fb =~ /-?[0-9]+(\.[0-9]+)?/;
  $self;
}

=back

=head1 METHODS FOR FIELD BODY VALUE

=over 4

=item $self->value ([$new_value])

Returns or set value.  Note that this method
does not check whether value is valid or not.

=item $self->value_formatted ()

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

=item $self->comment ()

Returns array reference of comments.  You can add/remove/change
array values.

=cut

sub comment ($) {
  my $self = shift;
  $self->{comment};
}

=item $self->comment_add ($comment, [%option]

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

=item $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  for (qw(check_max check_min output_comment value_max value_min value_if_invalid)) {
    $option{$_} ||= $self->{option}->{$_};
  }
  $option{format_pattern} = $self->{option}->{format_pattern}
    unless defined $option{format_pattern};
  return $option{value_if_invalid}
    if $option{check_max} && $option{value_max} < $self->{value};
  return $option{value_if_invalid}
    if $option{check_min} && $option{value_min} > $self->{value};
  my $s = sprintf $option{format_pattern}, $self->{value};
  if ($option{output_comment}) {
    for (@{$self->{comment}}) {
      my $t = $self->Message::Util::encode_ccontent ($_);
      $s .= ' ('.$t.')' if length $t;
    }
  }
  $s;
}
*as_string = \&stringify;

=back

=over 4

=item $self->option ( $option-name / $option-name, $option-value, ...)

Set/gets option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited

=item $self->clone ()

Returns a copy of the object.

=cut

## Inherited

=back

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
$Date: 2002/04/22 08:28:20 $

=cut

1;
