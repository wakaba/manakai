
=head1 NAME

Message::Field::XFace --- X-Face Internet Message Header Field

=cut

package Message::Field::XFace;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Numval> objects:

=over 4

=cut


%DEFAULT = (
  #field_param_name
  #field_name
  #field_ns
  #format
  -line_length	=> 50,
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## $self->_init (%options); Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
}

=item $m = Message::Field::XFace->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $m = Message::Field::XFace->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $fb = shift;
  $self->_init (@_);
  $fb =~ tr/\x00-\x20\x7F-\xFF//d;
  $self->{value} = $fb;
  $self;
}

=back

=head1 METHODS

=over 4

=item $self->value ([$new_value])

Returns or set value.

=cut

sub value ($;$%) {
  my $self = shift;
  my $new_value = shift;
  if ($new_value) {
    $new_value =~ tr/\x00-\x20\x7F-\xFF//d;
    $self->{value} = $new_value;
  }
  $self->{value};
}

=item $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $s = $self->{value};
  my @s;
  my $l = $option{line_length} - length $option{field_name};
  push @s, substr ($s, 0, $l);
  while (push @s, substr ($s, $l, $option{line_length})) {
    last if $l > length $s;
    $l += $option{line_length};
  }
  join ' ', @s;
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
$Date: 2002/06/16 11:02:46 $

=cut

1;
