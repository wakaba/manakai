
=head1 NAME

Message::Field::CSV --- Perl module for Internet message
field body consist of comma separated values

=cut

package Message::Field::CSV;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

use overload '""' => sub { $_[0]->stringify },
             '0+' => sub { $_[0]->count },
             '.=' => sub { $_[0]->add ($_[1]); $_[0] },
             fallback => 1;

*REG = \%Message::Util::REG;
## Inherited: comment, quoted_string, domain_literal, angle_quoted
	## WSP, FWS, atext

## From usefor-article
	$REG{NON_component} = qr/[^\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5F\x61-\x7A\x80-\xFF\x2F\x3D\x3F]/;
	$REG{NON_distribution} = qr/[^\x21\x2B\x2D\x30-\x39\x41-\x5A\x5F\x61-\x7A]/;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    #encoding_after_encode	## Inherited
    #encoding_before_decode	## Inherited
    -field_name	=> 'keywords',
    #format	## Inherited
    #hook_encode_string	## Inherited
    #hook_decode_string	## Inherited
    -is_quoted_string	=> 1,	## Can itself quoted-string?
    -long_count	=> 10,
    -parse_all	=> 0,
    -remove_comment	=> 1,
    -separator	=> ', ',
    -separator_long	=> ', ',
    -max	=> 0,
    -value_type	=> [':none:'],
    -value_unsafe_rule	=> 'NON_http_token_wsp',
  );
  $self->SUPER::_init (%DEFAULT, %options);
  $self->{value} = [];

## Keywords: foo, bar, "and so on"
## Newsgroups: local.test,local.foo,local.bar
## Accept: text/html; q=1.0, text/plain; q=0.03; *; q=0.01

  my %field_type = qw(accept-charset accept accept-encoding accept 
     accept-language accept
     content-language keywords
     followup-to newsgroups
     list-archive list- list-digest list- list-help list- 
     list-owner list- list-post list- list-subscribe list- 
     list-unsubscribe list- list-url list- uri list-
     posted-to newsgroups
     x-brother x-moe x-daughter x-moe
     x-respect x-moe x-syster x-moe x-wife x-moe);
  my $field_name = lc $self->{option}->{field_name};
  $field_name = $field_type{$field_name} || $field_name;
  if ($field_name eq 'newsgroups') {
    $self->{option}->{separator} = ',';
    $self->{option}->{separator_long} = ', ';
    $self->{option}->{long_count} = 5;
    $self->{option}->{value_unsafe_rule} = 'NON_component';
    $self->{option}->{encoding_after_encode} = 'utf-8';
  } elsif ($field_name eq 'distribution') {
    $self->{option}->{separator} = ',';
    $self->{option}->{separator_long} = ', ';
    $self->{option}->{long_count} = 15;
    $self->{option}->{value_unsafe_rule} = 'NON_distribution';
  } elsif ($field_name eq 'x-moe') {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{value_type} = ['Message::Field::ValueParams', 
      {format => $self->{option}->{format}}];
  } elsif ($field_name eq 'accept') {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{value_type} = ['Message::Field::ValueParams', 
      {format => $self->{option}->{format}}];
  } elsif ($field_name eq 'list-') {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{remove_comment} = 0;
    $self->{option}->{value_type} = ['Message::Field::URI', 
      {-field_name => $self->{option}->{field_name},
      -format => $self->{option}->{format}}];
  } elsif ($field_name eq 'encrypted') {
    $self->{option}->{max} = 2;
  }
  
  if (ref $options{value} eq 'ARRAY') {
    $self->add (@{$options{value}});
  } elsif ($options{value}) {
    $self->add ($options{value});
  }
  $self;
}

=item $csv = Message::Field::CSV->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $csv = Message::Field::CSV->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $field_body = shift;
  $self->_init (@_);
  $field_body = Message::Util::delete_comment ($field_body)
    if $self->{option}->{remove_comment};
  push @{$self->{value}}, $self->_parse_list ($field_body);
  $self;
}

## Parses csv string and returns array
sub _parse_list ($$) {
  my $self = shift;
  my $fb = shift;
  my @ids;
  $fb =~ s{((?:$REG{quoted_string}|$REG{angle_quoted}|$REG{domain_literal}|$REG{comment}|[^\x22\x28\x2C\x3C\x5B])+)}{
    my $s = $1;  $s =~ s/^$REG{WSP}+//;  $s =~ s/$REG{WSP}+$//;
    if ($self->{option}->{is_quoted_string}) {
      $s = $self->_value (Message::Util::decode_quoted_string ($self, $s))
        if $self->{option}->{parse_all};
      push @ids, Message::Util::decode_quoted_string ($self, $s);
    } else {
      $s = $self->_value ($s) if $self->{option}->{parse_all};
      push @ids, $s;
    }
  }goex;
  @ids;
}

=back

=head1 METHODS

=over 4

=head2 $values = $csv->value ($index1, [$index2, $index3,...])

Returns C<$index>'th value(s).

=cut

sub value ($@) {
  my $self = shift;
  my @index = @_;
  my @ret = ();
  for (@index) {
    $self->{value}->[$_] = $self->_value ($self->{value}->[$_]);
    push @ret, $self->{value}->[$_];
  }
  @ret;
}

=item $number = $csv->count

Returns number of values.

=cut

sub count ($) {
  my $self = shift;
  $self->_delete_empty;
  $#{$self->{value}}+1;
}

=iterm $csv->add ($value1, [$value2, $value3,...])

Adds (appends) new value(s).

=iterm $csv->prepend ($value1, [$value2, $value3,...])

Prepends new value(s).

=cut

sub add ($@) {
  my $self = shift;
  push @{$self->{value}}, @_;
}

sub prepend ($@) {
  my $self = shift;
  unshift @{$self->{value}}, @_;
}

=item $field-body = $csv->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $self->_delete_empty;
  $option{max}--;
  $option{max} = $#{$self->{value}} if $option{max} <= 0;
  $option{max} = $#{$self->{value}} if $#{$self->{value}} < $option{max};
  $option{separator} = $option{separator_long}
    if $option{max} >= $option{long_count};
  join $option{separator}, 
    map {
      if ($option{is_quoted_string}) {
        my %s = &{$self->{option}->{hook_encode_string}} ($self, 
          $_, type => 'phrase');
        Message::Util::quote_unsafe_string ($s{value}, 
          unsafe => $option{value_unsafe_rule});
      } else {
        $_;
      }
    } @{$self->{value}}[0..$option{max}];
}
*as_string = \&stringify;

=item $option-value = $ua->option ($option-name)

Gets option value.

=item $csv->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited

=item $type = $csv->value_type

Gets value-type.  Value-type is package name of module
used for value modification.  A special value-type, ':none:'
is used to indicate values are non-structured (and no module
is automatically used).

=item $csv->value_type ([$type])

Set value-type.

=cut

sub value_type ($;$) {
  my $self = shift;
  my $new_value_type = shift;
  if (ref $new_value_type eq 'ARRAY') {
    $self->{option}->{value_type} = $new_value_type;
  } elsif ($new_value_type) {
    $self->{option}->{value_type}->[0] = $new_value_type;
  }
  $self->{option}->{value_type}->[0] || ':none:';
}

=item $clone = $ua->clone ()

Returns a copy of the object.

=cut

sub clone ($) {
  my $self = shift;
  $self->_delete_empty;
  my $clone = $self->SUPER::clone;
  $clone->{value_type} = Message::Util::make_clone ($self->{value_type});
  $clone;
}

=back

=cut

## Internal functions

## Hook called before returning C<value>.
## $csv->_param_value ($name, $value);
sub _value ($$) {
  my $self = shift;
  my $value = shift;
  my $vtype = $self->{option}->{value_type}->[0];
  my %vopt; %vopt = %{$self->{option}->{value_type}->[1]} 
    if ref $self->{option}->{value_type}->[1];
  if (ref $value) {
    return $value;
  } elsif ($vtype eq ':none:') {
    return $value;
  } elsif ($value) {
    eval "require $vtype";
    return $vtype->parse ($value, %vopt);
  } else {
    eval "require $vtype";
    return $vtype->new (%vopt);
  }
}

sub _delete_empty ($) {
  my $self = shift;
  $self->{value} = [grep {length $_} @{$self->{value}}];
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
$Date: 2002/04/21 04:27:42 $

=cut

1;
