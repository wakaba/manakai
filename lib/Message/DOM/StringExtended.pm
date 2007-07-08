package Message::DOM::StringExtended;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::StringExtended', 'Exporter';
require Exporter;
our @EXPORT_OK = qw(find_offset16 find_offset32);

sub find_offset16 ($$) {
  my $v = ''.$_[0];
  my $offset32 = 0+$_[1];

  if ($offset32 < 0 or length $v < $offset32) {
    require Carp;
    Carp::croak ("String index out of bounds");
  }

  my $ss = substr $v, 0, $offset32;
  my $r = $offset32;
  if ($ss =~ /[\x{10000}-\x{10FFFF}]/) {
    while ($ss =~ /[\x{10000}-\x{10FFFF}]+/g) {
      $r += $+[0] - $-[0];
    }
  }
  
  return $r;
} # find_offset16

sub find_offset32 ($$) {
  my $v = ''.$_[0];
  my $offset16 = 0+$_[1];

  if ($offset16 < 0) {
    require Carp;
    Carp::croak ("String index out of bounds");
  }

  my $r = 0;
  my $o = $offset16;
  while ($o > 0) {
    my $c = substr ($v, $r, 1);
    if (length $c) {
      if ($c =~ /[\x{10000}-\x{10FFFF}]/) {
        $o -= 2;
      } else {
        $o--;
      }
      $r++;
    } else {
      require Carp;
      Carp::croak ("String index out of bounds");
    }
  }

  return $r;
} # find_offset32

package Message::IF::StringExtended;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 09:25:17 $
