
=head1 NAME

Message::Field::Addresses --- Perl module for comma separated
Internet mail address list

=cut

package Message::Field::Addresses;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::CSV;
push @ISA, qw(Message::Field::CSV);
%REG = %Message::Field::CSV::REG;
	$REG{SC_angle_addr} = qr/<(?:$REG{quoted_string}|$REG{domain_literal}|$REG{comment}|[^\x22\x28\x5B\x3E])+>|<>/;
	$REG{SC_group} = qr/:(?:$REG{comment}|$REG{quoted_string}|(??{$REG{SC_group}})|$REG{domain_literal}|$REG{SC_angle_addr}|[^\x22\x28\x5B\x3A\x3E\x3B])*;/;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_METHODS	=> [qw|add count delete item display_name is_group value_type scan
                       comment_add comment_count comment_delete comment_item|],
    -_MEMBERS	=> [qw|group_name group_name_comment|],
    -by	=> 'display-name',	## Default key for item, delete,...
    -can_have_group	=> 1,
    #encoding_after_encode
    #encoding_before_decode
    #field_name
    #field_param_name
    #format
    #hook_encode_string
    #hook_decode_string
    -is_group	=> 0,
    #max
    -output_comment	=> 1,
    -output_group_name_comment	=> 1,
    #parse_all
    -remove_comment	=> 0,	## This option works for PARENT class
    #value_type
  );
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
  my (%mailbox, %group);
  
  $self->{option}->{can_have_group} = 0
    if $self->{option}->{field_param_name} eq 'group';
  
  my $field = $self->{option}->{field_name};
  my $format = $self->{option}->{format};
  	## rfc1036 = RFC 1036 + son-of-RFC1036
  if ($field eq 'from' || $field eq 'resent-from') {
    $self->{option}->{can_have_group} = 0;
    $self->{option}->{max} = 1 if $format =~ /rfc1036|http/;
  } elsif ($field eq 'mail-copies-to') {
    $mailbox{-use_keyword} = 1;
  } elsif ($field eq 'reply-to') {
    $self->{option}->{can_have_group} = 0;
    $self->{option}->{max} = 1 if $format =~ /rfc1036/;
  } elsif ($field eq 'approved' || $field eq 'x-approved') {
    $self->{option}->{can_have_group} = 0;
    $self->{option}->{max} = 1 if $format =~ /news-rfc1036/;
  }
  
  $self->{option}->{value_type}->{mailbox} = ['Message::Field::Mailbox',
    {%mailbox}];
  $self->{option}->{value_type}->{group} = ['Message::Field::Addresses',
    {-is_group => 1, %group}];
}

=item $addrs = Message::Field::Addresses->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $addrs = Message::Field::Addresses->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## Inherited

sub _parse_list ($$) {
  my $self = shift;
  my $fb = shift;
  my @ids;
  if ($self->{option}->{is_group}) {
    $fb =~ s{^((?:$REG{quoted_string}|$REG{comment}|[^\x22\x28\x2C\x3A\x3C\x5B])+):}{
      my ($gname, @gcomment) = Message::Util::delete_comment_to_array ($self, $1);
      $self->{group_name} = Message::Util::decode_quoted_string ($self, $gname);
      $self->{group_name_comment} = \@gcomment;
    ''}gex;
    $fb =~ s{;((?:$REG{comment}|$REG{WSP})*)$}{
      my (undef, @gcomment) = Message::Util::delete_comment_to_array ($self, $1);
      $self->{comment} = \@gcomment;
    ''}gex;
  }
  $fb =~ s{(?:$REG{quoted_string}|$REG{comment}|[^\x22\x28\x2C\x3A\x3C\x5B]|$REG{SC_group}|$REG{SC_angle_addr}|$REG{domain_literal})+}{
    my $s = $&;  $s =~ s/^$REG{WSP}+//;  $s =~ s/$REG{WSP}+$//;
    if ($s =~ /^(?:$REG{quoted_string}|$REG{comment}|[^\x22\x28\x2C\x3A-\x3C\x5B])*:/) {
      $s = $self->_parse_value (group => $s) if $self->{option}->{parse_all};
      $s = {type => 'group', value => $s};
    } else {	## address or keyword
      $s = $self->_parse_value (mailbox => $s) if $self->{option}->{parse_all};
      $s = {type => 'mailbox', value => $s};
    }
    push @ids, $s;
  }goex;
  @ids;
}

=back

=head1 METHODS

=over 4

=item $addrs->add ({-name => $value}, $addr1, $addr2, $addr3,...)

Adds mail address(es).

First argument is hash reference to name/value pairs
of options.  This is optional.

Following is list of additional items.  Each item
can be given as array reference.  An array reference
is interpreted as [$item-body, $item-option-name => 
$item-option-value, $name => $value,...].
Available item-options are:

=over 2

=item C<group>

Group name which C<$item-body> belongs to.  If there
is no such name of group, new group is created.

=item C<type> = 'mailbox' / 'group' (default 'group')

Format of C<$item-body>.  If 'group' is specified,
<$item-body> is treated as RFC 2822 group.  Otherwise,
it is added as a mailbox.

=back

=item $count = $addrs->count ([%options])

Returns the number of items.  A 'type' option is available.
For example, C<$addrs-E<gt>count (-type =E<gt> 'group')>
returns the number of groups.

=item $addrs->delete ({%options}, $item-key, $key,...)

Deletes items that are matched with (one of) given key.
C<{%options}> is optional.

C<by> option is used to specify what sort of value given keys are.
C<display-name>, the default value, indicates
keys are display-name of items to be removed.

For C<by> option, value C<index> is also available.

C<type> option is also available.  Its value is 'mailbox'
and 'group'.  Default is both of them.

=cut

## add, count, delete: Inherited

sub _add_array_check ($$\%) {
  my $self = shift;
  my ($value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  if (length $value_option->{group}) {
    my $g = $self->item ($value_option->{group}, -type => 'group');
    delete $value_option->{group};
    $g->add (Message::Util::make_clone ($option), [$value, %$value_option]);
    (0);
  } else {
    my $type = $value_option->{type} || 'mailbox';
    $value = $self->_parse_value ($type => $value) if $$option{parse};
    $$option{parse} = 0;
    (1, value => {type => $type, value => $value});
  }
}

sub _delete_match ($$$\%\%) {
  my $self = shift;
  my ($by, $i, $list, $option) = @_;
  return 0 unless ref $$i;  ## Already removed
  return 0 if $$option{type} && $$i->{type} ne $$option{type};
  if ($by eq 'display-name') {
    $$i->{value} = $self->_parse_value ($$i->{type}, $$i->{value});
    return 1 if ref $$i->{value} && $$list{$$i->{value}->display_name};
  } elsif ($by eq 'addr-spec') {
    $$i->{value} = $self->_parse_value ($$i->{type}, $$i->{value});
    return 1 if ref $$i->{value} && $$list{$$i->{value}->addr_spec};
  }
  0;
}
*_item_match = \&_delete_match;

## Returns returned item value    \$item-value, \%option
sub _item_return_value ($\$\%) {
  if (ref ${$_[1]}->{value}) {
    ${$_[1]}->{value};
  } else {
    ${$_[1]}->{value} = $_[0]->_parse_value (${$_[1]}->{type}, ${$_[1]}->{value});
    ${$_[1]}->{value};
  }
}
*_add_return_value = \&_item_return_value;

## Returns returned (new created) item value    $name, \%option
sub _item_new_value ($$\%) {
  my $type = $_[2]->{type} || 'mailbox';
  my $v = $_[0]->_parse_value ($type, '');
  $v->display_name ($_[1]) if ref $v && length $_[1] && $_[2]->{by} eq 'display-name';
  {type => $type, value => $v};
}

sub is_group ($;$) {
  if (defined $_[1]) {
    $_[0]->{option}->{is_group} = $_[1];
  }
  $_[0]->{option}->{is_group};
}

sub have_group ($) {
  my $self = shift;
  for (@{$self->{$self->{option}->{_ARRAY_NAME}}}) {
    return 1 if $_->{type} eq 'group';
  }
  0;
}

sub display_name ($;$) {
  if (defined $_[1]) {
    $_[0]->{group_name} = $_[1];
  }
  $_[0]->{group_name};
}

sub addr_spec ($;%) {
  my $self = shift;
  my @a;
  for (@{$self->{$self->{option}->{_ARRAY_NAME}}}) {
    $_->{value} = $self->_parse_value
      ($_->{type} => $_->{value}) unless ref $_->{value};
    if (ref $_->{value}) {
      push @a, $_->{value}->addr_spec (@_);
    } elsif (length $_->{value}) {
      push @a, $_->{value};
    }
  }
  wantarray? @a: $a[0];
}

## stringify: Inherited
#*as_string = \&stringify;

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $m = $self->SUPER::stringify (@_);
  my $g = '';
  if ($option{is_group}) {
    my %s = &{$option{hook_encode_string}} ($self, 
          $self->{group_name}, type => 'phrase');
    $g .= Message::Util::quote_unsafe_string
      ($s{value}, unsafe => 'NON_atext_wsp');
  }
  if ($option{output_comment} && $option{output_group_name_comment}) {
    if (!$option{is_group} && length $self->{group_name}) {
      $g .= ' ('. $self->Message::Util::encode_ccontent ($self->{group_name}) .':)';
    }
    for (@{$self->{group_name_comment}}) {
      $g .= ' ('. $self->Message::Util::encode_ccontent ($_) .')';
    }
  }
  if ($option{is_group}) {
    $m = $g . (length $m? ': ': ':') . $m . ';';
  } else {
    $m = $g . (length $g? ' ': '') . $m;
  }
    if ($option{output_comment} && !$option{output_group_name_comment}) {
      for (@{$self->{group_name_comment}}) {
        $m .= ' ('. $self->Message::Util::encode_ccontent ($_) .')';
      }
    }
    if ($option{output_comment}) {
      for (@{$self->{comment}}) {
        $m .= ' ('. $self->Message::Util::encode_ccontent ($_) .')';
      }
    }
  $m;
}
*as_string = \&stringify;
sub _stringify_item ($$\%) {
  my $self = shift;
  my $item = shift;
  my $option = shift;
  if (!$$option{can_have_group} && ref $item->{value}) {
    $item->{value}->stringify (-is_group => 0);
  } else {
    $item->{value};
  }
}

## option, value_type, clone, method_available: Inherited

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
$Date: 2002/06/09 11:08:27 $

=cut

1;
