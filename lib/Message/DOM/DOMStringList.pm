package Message::DOM::DOMStringList;
use strict;
use warnings;
our $VERSION = '1.4';
push our @ISA, 'Tie::Array', 'Message::IF::DOMStringList';
require Tie::Array;

use overload
    '@{}' => sub {
      return $_[0] if ref $_[0] eq 'Message::DOM::DOMStringList::StaticList';
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
    require Message::DOM::DOMException;
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
    require Message::DOM::DOMException;
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
      require Message::DOM::DOMException;
      report Message::DOM::DOMException
          -object => $$self->[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    $#$v = $_[1];
  }
} # STORESIZE

sub TIEARRAY ($$) { $_[1] }

package Message::DOM::DOMStringList::StaticList;
push our @ISA, 'Message::DOM::DOMStringList';
use Scalar::Util;

use overload
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::DOMStringList');

      return refaddr ($_[0]) eq refaddr ($_[1]);
    },
    fallback => 1;

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |DOMStringList| attributes

sub length ($) {
  return scalar @{$_[0]};
} # length
*FETCHSIZE = \&length;

## |DOMStringList| methods

sub item ($$) {
  my $index = 0+($_[1] or 0);
  if ($index < 0 or $index > $#{$_[0]}) {
    return undef;
  } else {
    return $_[0]->[$index];
  }
} # item

sub FETCH ($$) { $_[0]->[$_[1]] }

sub STORE ($$$) {
  require Message::DOM::DOMException;
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'NO_MODIFICATION_ALLOWED_ERR',
      -subtype => 'READ_ONLY_NODE_ERR';
} # STORE

*DELETE = \&STORE;

sub EXISTS ($$) { exists $_[0]->[$_[1]] }

sub contains ($$) {
  my $str = ''.$_[1];
  for (@{$_[0]}) {
    if ($_ eq $str) {
      return 1;
    }
  }
  return 0;
} # contains

*STORESIZE = \&STORE;

sub TIEARRAY ($$) { $_[1] }

package Message::IF::DOMStringList;

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
