
=head1 NAME

Message::Field::CSV --- Perl module for Internet message
field body consist of comma separated values

=cut

package Message::Field::Addresses;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::CSV;
push @ISA, qw(Message::Field::CSV);
*REG = \%Message::Field::CSV::REG;
	$REG{SC_angle_addr} = qr/<(?:$REG{quoted_string}|$REG{domain_literal}|$REG{comment}|[^\x22\x28\x5B\x3E])+>|<>/;
	$REG{SC_group} = qr/:(?:$REG{comment}|$REG{quoted_string}|(??{$REG{SC_group}})|$REG{domain_literal}|$REG{SC_angle_addr}|[^\x22\x28\x5B\x3A\x3E\x3B])+;/;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -_METHODS => [qw(add count delete item display_name is_group value_type scan)],
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
    -output_comment	=> 1,
    -output_group_name_comment	=> 1,
    #parse_all
    -remove_comment	=> 0,	## This option works for PARENT class
    #value_type
  );
  $self->SUPER::_init (%DEFAULT, %options);
  
  $self->{option}->{value_type}->{'*group'} = ['Message::Field::Addresses',
    {-is_group => 1}];
  $self->{option}->{can_have_group} = 0 if $self->{option}->{field_param_name} eq '*group';
}

## new, parse: Inherited

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
    if ($s =~ /^(?:$REG{quoted_string}|$REG{comment}|[^\x22\x28\x2C\x3A\x3C\x5B])*:/) {
      $s = $self->_parse_value ('*group' => $s) if $self->{option}->{parse_all};
      $s = {type => '*group', value => $s};
    } else {	## address or keyword
      $s = $self->_parse_value ('*mailbox' => $s) if $self->{option}->{parse_all};
      $s = {type => '*mailbox', value => $s};
    }
    push @ids, $s;
  }goex;
  @ids;
}

=back

=head1 METHODS

=over 4

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
    ## TODO:
  }
  $$option{parse} = 0;
  (1, value => {type => 'address', value => $value});
}

sub _delete_match ($$$\%\%) {
  my $self = shift;
  my ($by, $i, $list, $option) = @_;
  return 0 unless ref $$i;  ## Already removed
  return 0 if $$option{type} && $$i->{type} ne $$option{type};
  my $item = $$i->{value};
  if ($by eq 'display-name') {
    $item = $self->_parse_value ($$i->{type}, $item);
    return 1 if ref $item && $$list{$item->display_name};
  }
  0;
}
*_item_match = \&_delete_match;

## Returns returned item value    \$item-value, \%option
sub _item_return_value ($\$\%) {
  if (ref ${$_[1]}) {
    ${$_[1]}->{value};
  } else {
    ${$_[1]} = $_[0]->_parse_value (${$_[1]});
    ${$_[1]};
  }
}

sub is_group ($;$) {
  if (defined $_[1]) {
    $_[0]->{option}->{is_group} = $_[1];
  }
  $_[0]->{option}->{is_group};
}

sub display_name ($;$) {
  if (defined $_[1]) {
    $_[0]->{group_name} = $_[1];
  }
  $_[0]->{group_name};
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
    $m = $g . (length $m? ' ': '') . $m;
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
$Date: 2002/05/08 09:11:31 $

=cut

1;
