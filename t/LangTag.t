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

__PACKAGE__->runtests;

## License: Public Domain.

1;
