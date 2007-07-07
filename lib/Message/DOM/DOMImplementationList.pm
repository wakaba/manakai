package Message::DOM::DOMImplementationList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMImplementationList';

## |DOMImplementationList| attributes

sub length ($) { scalar @{$_[0]} }
*FETCHSIZE = \&length;

## |DOMImplementationList| methods

sub item ($$) {
  my $index = 0+$_[1];
  if ($index < 0 or $index > $#{$_[0]}) {
    return undef;
  } else {
    return $_[0]->[$index];
  }
} # item
*FETCH = \&item;

sub STORE ($$$) {
  my $r;
  if ($_[1] > $#{$_[0]}) {
    push @{$_[0]}, ''.$_[2];
  } else {
    $r = $_[0]->[$_[1]] if defined wantarray;
    $_[0]->[$_[1]] = ''.$_[2];
  }
  return $r;
} # STORE

sub DELETE ($$) {
  my $r;
  $r = $_[0]->[$_[1]] if defined wantarray;
  splice @{$_[0]}, $_[1], 1, ();
  return $r;
} # DELETE

sub EXISTS ($$) {
  return exists ${${$_[0]}->[0]}->{${$_[0]}->[1]}->[$_[1]];
} # EXISTS

sub STORESIZE ($$) {
  if ($_[1] < $#${$_[0]}) {
    $#{$_[0]} = $_[1];
  }
} # STORESIZE

sub TIEARRAY ($$) { $_[1] }

package Message::IF::DOMImplementationList;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/07 05:58:11 $
