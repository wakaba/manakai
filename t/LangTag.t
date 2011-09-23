package test::Whatpm::LangTag;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
require (file (__FILE__)->dir->file ('testfiles.pl')->stringify);
require Whatpm::LangTag;
use Test::More;
use Test::Differences;

sub _normalize : Test(13) {
  for (
    ['', ''],
    ['ja', 'ja'],
    ['ja-jp', 'ja-JP'],
    ['ja-JP', 'ja-JP'],
    ['en-CA-x-ca', 'en-CA-x-ca'],
    ['sgn-BE-FR', 'sgn-BE-FR'],
    ['az-Latn-x-latn', 'az-Latn-x-latn'],
    ['in-in', 'in-IN'],
    ["\x{0130}n-\x{0130}n", "\x{0130}n-\x{0130}N"],
    ["\x{0131}n-\x{0131}n", "\x{0131}n-\x{0131}N"],
    ['ja-latn-jp-u-ja-JP-Latn' => 'ja-Latn-JP-u-ja-jp-latn'],
    ['ja-latn-jp-i-ja-JP-Latn' => 'ja-Latn-JP-i-ja-JP-Latn'],
    ['ja-latn-jp-x-ja-JP-Latn' => 'ja-Latn-JP-x-ja-JP-Latn'],
  ) {
    is +Whatpm::LangTag->normalize_rfc5646_langtag ($_->[0]), $_->[1];
  }
} # _normalize

sub _parse : Tests {
  execute_test ($_, {
    4646 => {is_list => 1},
    5646 => {is_list => 1},
  }, sub {
    my $test = shift;
    
    our @errors = ();
    my $onerror = sub {
      my %opt = @_;
      push @errors, join ';',
          $opt{type},
          defined $opt{text} ? $opt{text} : '',
          defined $opt{value} ? $opt{value} : '',
          $opt{level};
    }; # $onerror
    
    {
      local @errors;

      my $parsed = Whatpm::LangTag->parse_rfc4646_langtag
          ($test->{data}->[0], $onerror);
      Whatpm::LangTag->check_rfc4646_langtag ($parsed, $onerror);
      
      if ($test->{4646}) {
        eq_or_diff join ("\n", sort {$a cmp $b} @errors),
            join ("\n", sort {$a cmp $b} @{$test->{4646}->[0]}),
            '_parse ' . $test->{data}->[0];
      } else {
        warn qq[No test item: "$test->{data}->[0]];
      }
    }

    {
      local @errors;
      
      my $parsed = Whatpm::LangTag->parse_rfc5646_langtag
          ($test->{data}->[0], $onerror);
      Whatpm::LangTag->check_rfc5646_langtag ($parsed, $onerror);

      if ($test->{5646} || $test->{4646}) {
        eq_or_diff join ("\n", sort {$a cmp $b} @errors),
            join ("\n", sort {$a cmp $b} @{$test->{5646}->[0] || $test->{4646}->[0]}),
            '_parse ' . $test->{data}->[0];
      }
    }
  }) for map { file (__FILE__)->dir->file ($_)->stringify } qw[
    langtag-1.dat
  ];
} # _parse

sub _basic_filtering_range_rfc4647 : Test(68) {
  for (
     [undef, undef, 1],
     ['*', undef, 1],
     ['', undef, 1],
     ['', '', 1],
     ['*', '', 1],
     ['', undef, 1],
     ['ja', 'ja', 1],
     ['JA', 'ja', 1],
     ['ja', 'JA', 1],
     ['InValid', 'invalid', 1],
     ['ja-jp', 'ja', 0],
     ['ja', 'ja-jp', 1],
     ['jajp', 'ja', 0],
     ['ja', 'jajp', 0],
     ['ja-', 'jajp', 0],
     ['ja-', 'ja-jp', 0],
     ['ja-', 'ja--', 1],
     ['ja-j', 'ja-jp', 0],
     ['ja-', 'ja-', 1],
     ['de-ch', 'de-ch-1996', 1],
     ['de-ch', 'de-CH-1996', 1],
     ['de-ch', 'de-ch', 1],
     ['de-ch', 'de-ch-1901-x-hoge', 1],
     ['de-ch', 'de-zh-1996', 0],
     ['de-ch', 'de-Latn-ch', 0],
     ['de-ch', 'de', 0],
     ['de-ch', 'x-de-ch', 0],
     ['de', 'de-ch-1996', 1],
     ['de', 'de-ch', 1],
     ['x-hoge', 'de-ch', 0],
     ['x-hoge', 'x-hoge', 1],
     ['x-hoge', 'x-hoge-fuga', 1],
     ['x', 'x-hoge-fuga', 1],
     ['x-', 'x-hoge-fuga', 0],
  ) {
    is !!Whatpm::LangTag->basic_filtering_range_rfc4647 ($_->[0], $_->[1]), !!$_->[2];
    is !!Whatpm::LangTag->match_range_rfc3066 ($_->[0], $_->[1]), !!$_->[2];
  }
} # _basic_filtering_range_rfc4647

__PACKAGE__->runtests;

## License: Public Domain.

1;
