
=head1 NAME

Message::Field::MsgIDs --- Perl module for Internet message
field bodies contains of Message-IDs, such as C<References:>,
C<In-Reply-To:> field bodies

=cut

package Message::Field::MsgIDs;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

use overload '""' => sub { $_[0]->stringify },
             '0+' => sub { $_[0]->count },
             '.=' => sub { $_[0]->add ($_[1]); $_[0] },
             fallback => 1;

*REG = \%Message::Util::REG;
## Inherited: comment, quoted_string, domain_literal
	## WSP, FWS, phrase, NON_atom
	## msg_id
	## M_quoted_string


=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -_ARRAY_NAME	=> 'value',
    #dont_croak
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #format
    #hook_encode_string
    #hook_decode_string
    -output_comment	=> 1,
    -output_phrase	=> 0,
    -parse	=> 1,	## Default value for add method
    -parse_all	=> 1,
    -reduce_save_last	=> 3,
    -reduce_save_change_subject	=> 1,
    -reduce_save_top	=> 1,
    -reduce_max_count	=> 21,
    -separator	=> ' ',
  );
  $self->SUPER::_init (%DEFAULT, %options);
  $self->{option}->{value_type}->{'*msg-id'} = ['Message::Field::MsgID'];
  #$self->{option}->{value_type}->{'*phrase'} = [':none:'];
  #$self->{option}->{value_type}->{'*comment'} = [':none:'];
  
  ## Initial value(s)
  if (ref $options{value} eq 'ARRAY') {
    $self->add (@{$options{value}});
  } elsif ($options{value}) {
    $self->add ($options{value});
  }
}

=item $id = Message::Field::MsgIDs->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $id = Message::Field::MsgIDs->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my (@ids, @idc);
  ($body, @idc) = $self->Message::Util::delete_comment_to_array ($body);
  $body =~ s{($REG{msg_id})|($REG{atext_dot})|($REG{quoted_string})}{
    my ($msgid, $atom, $qstr) = ($1, $2, $3);
    if ($msgid) {
      $msgid = $self->_parse_value ('*msg-id' => $msgid)
        if $self->{option}->{parse_all};
      push @ids, {value => $msgid, type => 'msg-id'};
    } elsif ($atom) {
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $atom,
                type => 'phrase/atom');
      push @ids, {value => $s{value}, type => 'phrase'};
    } else {
      $qstr = Message::Util::unquote_quoted_string ($qstr);
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $qstr,
                type => 'phrase/quoted_string');
      push @ids, {value => $s{value}, type => 'phrase'};
    }
  }goex;
  push @{$self->{value}}, @ids, map {{value => $_, type => 'comment'}} @idc;
  $self;
}

=head1 METHODS

=over 4

=cut

## add: Inherited

sub _add_array_check ($$\%) {
  my $self = shift;
  my ($value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  $value_option->{type} ||= 'msg-id';
  if ($value_option->{type} eq 'msg-id') {
    if ($$option{validate} && $value !~ /^$REG{msg_id}$/) {
      if ($$option{dont_croak}) {
        return (0);
      } else {
        Carp::croak qq{add: $value: Invalid msg-id};
      }
    }
    $value = $self->_parse_value ('*msg-id' => $value) if $$option{parse};
  }
  (1, value => {value => $value, type => $value_option->{type}});
}

## count: Inherited

## Delete empty items
sub _delete_empty ($) {
  my $self = shift;
  $self->{value} = [grep {ref $_ && length $_->{value}} @{$self->{value}}];
  $self;
}

sub reduce ($;%) {
  my $self = shift;
  my %p = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  return $self if $#{$self->{value}}+1 <= $option{reduce_max_count};
  return $self if $#{$self->{value}}+1 <= $option{reduce_save_top}
                                        + $option{reduce_save_last};
  my @nid;	## By this operation, non-msg-id values are losted.
  $self->{value} = [grep {ref $_ && $_->{type} eq 'msg-id'} @{$self->{value}}];
  push @nid, @{$self->{value}}[0..$option{reduce_save_top}-1];
  push @nid, grep {$_->{value} =~ '-_-@'} @{$self->{value}}
    [$option{reduce_save_top}..($#{$self->{value}} - $option{reduce_save_last})]
    if $option{reduce_save_change_subject};
  push @nid, @{$self->{value}}[-$option{reduce_save_last}..-1];
  $self->{value} = \@nid;
  $self;
}

sub stringify ($;%) {
  my $self = shift;
  my %p = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  $self->_delete_empty;
  join $option{separator}, grep {length $_} map {
    my $v = '';
    if ($_->{type} eq 'msg-id') {
      $v = $_->{value};
    } elsif ($_->{type} eq 'phrase') {
      if ($option{output_phrase}) {
        my %e = &{$self->{option}->{hook_encode_string}} ($self, 
           $_->{value}, type => 'phrase');
        $v = Message::Util::quote_unsafe_string ($e{value},
           unsafe => 'NON_atext');
      } elsif ($option{output_comment}) {
        $v = '('. $self->Message::Util::encode_ccontent ($_->{value}) .')';
      }
    } elsif ($_->{type} eq 'comment') {
      if ($option{output_comment}) {
        $v = '('. $self->Message::Util::encode_ccontent ($_->{value}) .')';
      }
    }
    $v;
  } @{$self->{value}};
}
*as_string = \&stringify;

=item $option-value = $r->option ($option-name)

Gets option value.

=item $r->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited

=item $clone = $r->clone ()

Returns a copy of the object.

=cut

## Inherited

=head1 STANDARDS

This module supports formats defined by:

=over 2

=item RFC 822

=item RFC 850

=item RFC 1036

=item son-of-RFC1036

=item RFC 2822

=item usefor-atricle

=back

but doesn't support:

=over 2

=item RFC 724

=item RFC 733

=back

=head1 EXAMPLE

 require Message::Field::MsgIDs;
 my $m = new Message::Field::MsgIDs 
   value => [qw(<foo1@bar.example> <foo2@bar.example>),
             [q{parent messages}, type => 'comment']],
 ;
 print $m;	# <foo1@bar.example> <foo2@bar.example> (parent messages)

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
$Date: 2002/05/08 09:11:31 $

=cut

1;
