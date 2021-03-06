
=head1 NAME

Message::Field::CSV --- Perl module for Internet message
field body consist of comma separated values

=cut

package Message::Field::CSV;
require 5.6.0;	## eval 're'
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.18 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

use overload '""' => sub { $_[0]->stringify },
             '0+' => sub { $_[0]->count },
             '.=' => sub { $_[0]->add ($_[1]); $_[0] },
             fallback => 1;

*REG = \%Message::Util::REG;
	## We need this is Msg::Util::REG itself (not copy of it)
	## to carry out $self->stringify correctly.  (This bad
	## implemention should be done away by making new module
	## for Newsgroups: and Distribution:.
## Inherited: comment, quoted_string, domain_literal, angle_quoted
	## WSP, FWS, atext
	
	## From usefor-article
	$REG{NON_component} = qr/[^\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5F\x61-\x7A\x80-\xFF\x2F\x3D\x3F]/;
	$REG{NON_distribution} = qr/[^\x21\x2B\x2D\x30-\x39\x41-\x5A\x5F\x61-\x7A]/;

%DEFAULT = (
	-_ARRAY_NAME	=> 'value',
	-_MEMBERS	=> [qw|value_type|],
	-_METHODS	=> [qw|add  count delete item
	               comment_add comment_delete comment_count
	               comment_item|],	# replace (not implemented yet)
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
    -is_quoted_string	=> 1,	## Can it be itself a quoted-string?
    -long_count	=> 10,
	#parse_all
    -remove_comment	=> 1,
    -separator	=> ', ',
    -separator_long	=> ', ',
    -use_comment	=> 1,
    -max	=> 0,
    #value_type
    -value_unsafe_rule	=> 'NON_http_token_wsp',
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
  
  my %field_type = qw(accept-charset accept accept-encoding accept 
     accept-language accept followup-to newsgroups
     posted-to newsgroups
     x-brother x-moe x-boss x-moe x-classmate x-moe x-daughter x-moe 
     x-dearfriend x-moe x-favoritesong x-moe 
     x-friend x-moe x-me x-moe
     x-respect x-moe x-sister x-moe x-son x-moe x-sublimate x-moe x-wife x-moe);
  my $field_name = $self->{option}->{field_name};
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
    $self->{option}->{value_type}->{'*default'} = ['Message::Field::XMoe'];
  } elsif ($field_name eq 'accept') {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{remove_comment} = 0;
    $self->{option}->{value_type}->{'*default'} = ['Message::Field::ValueParams'];
  } elsif ($self->{option}->{field_ns} eq $Message::Header::NS_phname2uri{'x-rfc822-list'}) {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{remove_comment} = 0;
    $self->{option}->{value_type}->{'*default'} = ['Message::Field::URI'];
  } elsif ($field_name eq 'man' || $field_name eq 'opt') {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{remove_comment} = 0;
    $self->{option}->{value_type}->{'*default'} = ['Message::Field::ValueParams'];
  } elsif ($field_name eq 'uri') {
    $self->{option}->{is_quoted_string} = 0;
    $self->{option}->{remove_comment} = 0;
    $self->{option}->{value_type}->{'*default'} = ['Message::Field::URI'];
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
    if $self->{option}->{use_comment} && $self->{option}->{remove_comment};
  push @{$self->{value}}, $self->_parse_list ($field_body);
  $self;
}

## Parses csv string and returns array
sub _parse_list ($$) {
  use re 'eval';
  my $self = shift;
  my $fb = shift;
  my @ids;
  $fb =~ s{((?:$REG{quoted_string}|$REG{angle_quoted}|$REG{domain_literal}|$REG{comment}|[^\x22\x28\x2C\x3C\x5B])+)}{
    my $s = $1;  $s =~ s/^$REG{WSP}+//;  $s =~ s/$REG{WSP}+$//;
    if ($self->{option}->{is_quoted_string}) {
      $s = $self->_parse_value ('*default' => 
        Message::Util::decode_quoted_string ($self, $s))
        if $self->{option}->{parse_all};
      push @ids, Message::Util::decode_quoted_string ($self, $s);
    } else {
      $s = $self->_parse_value ('*default' => $s) if $self->{option}->{parse_all};
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

sub value ($@) { shift->item (@_) }

=item $number = $csv->count

Returns number of values.

=cut

## Inherited

=item $csv->add ($value1, [$value2, $value3,...])

Adds (appends) new value(s).

=cut

sub _add_array_check ($$\%) {
  my $self = shift;
  my ($value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  (1, value => $value);
}
*_replace_array_check = \&_add_array_check;

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
  $option{max} = $#{$self->{value}} if $option{max} < 0;
  $option{max} = $#{$self->{value}} if $#{$self->{value}} < $option{max};
  $option{separator} = $option{separator_long}
    if $option{max} >= $option{long_count};
  join $option{separator}, 
    map {$self->_stringify_item ($_, \%option)} @{$self->{value}}[0..$option{max}];
}
*as_string = \&stringify;

sub _stringify_item ($$\%) {
  my $self = shift;
  my $item = shift;
  my $option = shift;
      if ($$option{is_quoted_string}) {
        my %s = &{$$option{hook_encode_string}} ($self, 
          $item, type => 'phrase');
        Message::Util::quote_unsafe_string ($s{value}, 
          unsafe => $$option{value_unsafe_rule});
      } else {
        $item;
      }
}

=item $option-value = $csv->option ($option-name)

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

=item $clone = $ua->clone ()

Returns a copy of the object.

=cut

## value_type, clone, method_available: Inherited

=back

=cut

## Internal functions

sub _delete_empty ($) {
  my $self = shift;
  $self->{value} = [grep {ref $_ || length $_} @{$self->{value}}];
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
$Date: 2004/02/14 11:26:34 $

=cut

1;
