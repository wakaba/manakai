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

sub _normalize : Tests {
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
  ) {
    is +Whatpm::LangTag->normalize_rfc5646_langtag ($_->[0]), $_->[1];
  }
} # _normalize

sub _parse : Tests {
  execute_test ($_, {
    4646 => {is_list => 1},
  }, sub {
    my $test = shift;
    
    my @errors;
    my $onerror = sub {
      my %opt = @_;
      push @errors, join ';',
          $opt{type},
          defined $opt{text} ? $opt{text} : '',
          defined $opt{value} ? $opt{value} : '',
          $opt{level};
    }; # $onerror
    
    my $parsed = Whatpm::LangTag->parse_rfc4646_langtag
        ($test->{data}->[0], $onerror);
    Whatpm::LangTag->check_rfc4646_langtag ($parsed, $onerror);
    
    if ($test->{4646}) {
      eq_or_diff join ("\n", sort {$a cmp $b} @errors),
         join ("\n", sort {$a cmp $b} @{$test->{4646}->[0]}),
         $test->{data}->[0];
    } else {
      warn qq[No test item: "$test->{data}->[0]];
    }
  }) for map { file (__FILE__)->dir->file ($_)->stringify } qw[
    langtag-1.dat
  ];
} # _parse

__PACKAGE__->runtests;

## License: Public Domain.

1;
