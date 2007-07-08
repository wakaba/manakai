#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 48 } 

use Message::DOM::StringExtended qw/find_offset16 find_offset32/;
use Message::Util::Error;

{
  my @data = (
              '', # 0
              'a', # 1
              'AbEdwerErsArw', # 2
              "A\x{10000}BC", # 3
              "\x{12001}", # 4
             );

  for my $testdata (
                    # data, 32, 16
                    [0, 0, 0],
                    [0, 1],
                    [0, 2],
                    [0, -1],
                    [0, -2],
                    [1, 0, 0],
                    [1, 1, 1],
                    [1, 2],
                    [1, -1],
                    [1, -2],
                    [2, 0, 0],
                    [2, 1, 1],
                    [2, 13, 13],
                    [2, 14],
                    [3, 0, 0],
                    [3, 1, 1],
                    [3, 2, 3],
                    [3, 3, 4],
                    [3, 4, 5],
                    [3, 5],
                    [4, 0, 0],
                    [4, 1, 2],
                    [4, 2],
                   ) {
    my $label = $testdata->[0] . '.' . $testdata->[1];
    if (defined $testdata->[2]) {
      my $return = find_offset16 $data[$testdata->[0]], $testdata->[1];
      ok $return, $testdata->[2], "find_offset16 $label";
    } else {
      try {
        find_offset16 $data[$testdata->[0]], $testdata->[1];
      } catch Error::Simple with {
        my $err = shift;
        ok $err->text, "String index out of bounds\n", "find_offset16 $label";
      };
    }
  }
}

{
  my @data = (
              '', # 0
              'a', # 1
              'AbEdwerErsArw', # 2
              "A\x{10000}BC", # 3
              "\x{12001}", # 4
             );
  
  for my $testdata (
                    # data, 16, 32
                    [0, 0, 0],
                    [0, 1],
                    [0, 2],
                    [0, -1],
                    [0, -2],
                    [1, 0, 0],
                    [1, 1, 1],
                    [1, 2],
                    [1, -1],
                    [1, -2],
                    [2, 0, 0],
                    [2, 1, 1],
                    [2, 13, 13],
                    [2, 14],
                    [3, 0, 0],
                    [3, 1, 1],
                    [3, 2, 2],
                    [3, 3, 2],
                    [3, 4, 3],
                    [3, 5, 4],
                    [3, 6],
                    [4, 0, 0],
                    [4, 1, 1],
                    [4, 2, 1],
                    [4, 3],
                   ) {
    my $label = $testdata->[0] . '.' . $testdata->[1];
    if (defined $testdata->[2]) {
      my $return = find_offset32 $data[$testdata->[0]], $testdata->[1];
      ok $return, $testdata->[2], "find_offset32 $label";
    } else {
      try {
        find_offset32 $data[$testdata->[0]], $testdata->[1];
      } catch Error::Simple with {
        my $err = shift;
        ok $err->text, "String index out of bounds\n", "find_offset32 $label";
      };
    }
  }
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/08 09:25:21 $
