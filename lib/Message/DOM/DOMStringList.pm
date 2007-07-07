package Message::DOM::DOMStringList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Tie::Array', 'Message::IF::DOMStringList';
require Tie::Array;
require Message::DOM::DOMException;

use overload
    '@{}' => sub {
      tie my @list, ref $_[0], $_[0];
      return \@list;
    },
    '==' => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::IF::DOMStringList');
      
      my @v1 = @{$_[0]};
      my @v2 = @{$_[1]};
      return 0 unless @v1 == @v2;

      (@v1) = sort {$a cmp $b} @v1;
      (@v2) = sort {$a cmp $b} @v2;
      for my $i (0..$#v1) {
        return 0 unless $v1[$i] eq $v2[$i];
      }
      return 1;
    },
    '!=' => sub { not $_[0] == $_[1] },
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::DOMStringList');

      return 0 unless ${$_[0]}->[1] eq ${$_[1]}->[1];
      return 0 unless ${$_[0]}->[0] eq ${$_[1]}->[0];
      return 1;
    },
    ne => sub { not $_[0] eq $_[1] },
    fallback => 1;

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |DOMStringList| attributes

sub length ($) {
  return scalar @{${${$_[0]}->[0]}->{${$_[0]}->[1]}};
} # length
*FETCHSIZE = \&length;

## |DOMStringList| methods

sub item ($$) {
  my $self = $_[0];
  my $index = 0+$_[1];
  my $v = ${$$self->[0]}->{$$self->[1]};
  if ($index < 0 or $index > $#$v) {
    return undef;
  } else {
    return $v->[$index];
  }
} # item

sub FETCH ($$) {
  return ${${$_[0]}->[0]}->{${$_[0]}->[1]}->[$_[1]];
} # FETCH

sub STORE ($$$) {
  my $self = $_[0];
  if (${$$self->[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $$self->[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $v = ${$$self->[0]}->{$$self->[1]};
  my $r;
  if ($_[1] > $#$v) {
    push @$v, ''.$_[2];
  } else {
    $r = $v->[$_[1]] if defined wantarray;
    $v->[$_[1]] = ''.$_[2];
  }
  return $r;
} # STORE

sub DELETE ($$) {
  my $self = $_[0];
  if (${$$self->[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $$self->[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $v = ${$$self->[0]}->{$$self->[1]};
  my $r;
  $r = $v->[$_[1]] if defined wantarray;
  splice @$v, $_[1], 1, ();
  return $r;
} # DELETE

sub EXISTS ($$) {
  return exists ${${$_[0]}->[0]}->{${$_[0]}->[1]}->[$_[1]];
} # EXISTS

sub contains ($$) {
  my $v = ${${$_[0]}->[0]}->{${$_[0]}->[1]};
  my $str = ''.$_[1];
  for (@$v) {
    if ($_ eq $str) {
      return 1;
    }
  }
  return 0;
} # contains

sub STORESIZE ($$) {
  my $self = $_[0];
  my $v = ${$$self->[0]}->{$$self->[1]};
  if ($_[1] < $#$v) {
    if (${$$self->[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $$self->[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    $#$v = $_[1];
  }
} # STORESIZE

sub TIEARRAY ($$) { $_[1] }

package Message::IF::DOMStringList;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/07 04:47:29 $
