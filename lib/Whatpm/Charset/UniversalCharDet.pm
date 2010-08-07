package Whatpm::Charset::UniversalCharDet;
use strict;
use warnings;
our $VERSION = '1.3';

our $DEBUG;

sub _detect { undef }

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
  my $de;
  eval {
    $de = _detect ($_[1]);
    1;
  } or do {
    ## NOTE: As far as I can tell, Python implementation of UniversalCharDet
    ## is broken for some input (at least for a broken ISO-2022-JP text it
    ## croaks).
    warn $@ unless $DEBUG;
    die $@ if $DEBUG;
  };
  if (defined $de and defined $de->{encoding}) {
    return lc $de->{encoding};
  } else {
    return undef;
  }
} # detect_byte_string

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
