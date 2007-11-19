package Whatpm::Charset::UniversalCharDet;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

our $DEBUG;

sub _detect ($) { undef }

eval q{
  use Inline Python => '
import chardet

def _detect(s):
  return chardet.detect (s)

';
  1;
} or do {
  warn $@ unless $DEBUG;
  die $@ if $DEBUG;
};

sub detect_byte_string ($$) {
  my $de = _detect ($_[1]);
  if (defined $de and defined $de->{encoding}) {
    return lc $de->{encoding};
  } else {
    return undef;
  }
} # detect_byte_string

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/11/19 12:18:27 $
