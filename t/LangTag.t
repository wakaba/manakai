package test::Whatpm::LangTag;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
if (-f file (__FILE__)->dir->file ('testfiles')->stringify) {
  require (file (__FILE__)->dir->file ('testfiles')->stringify);
} else {
  require (file (__FILE__)->dir->file ('testfiles.pl')->stringify);
}
require Whatpm::LangTag;
use Test::More;
use Test::Differences;

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

      my $parsed = Whatpm::LangTag->parse_rfc4646_tag
          ($test->{data}->[0], $onerror);
      my $result = Whatpm::LangTag->check_rfc4646_parsed_tag
          ($parsed, $onerror);
      
      my $expected = $test->{4646};
      if ($expected) {
        eq_or_diff join ("\n", sort {$a cmp $b} @errors),
            join ("\n", sort {$a cmp $b} @{$expected->[0]}),
            '_parse ' . $test->{data}->[0];
        is !$result->{well_formed},
            !! grep { $_ eq 'ill-formed' } @{$expected->[1] or []};
        is !$result->{valid},
            !! grep { $_ eq 'ill-formed' or $_ eq 'invalid' } @{$expected->[1] or []};
      } else {
        warn qq[No test item: "$test->{data}->[0]];
      }
    }

    {
      local @errors;
      
      my $parsed = Whatpm::LangTag->parse_rfc5646_tag
          ($test->{data}->[0], $onerror);
      my $result = Whatpm::LangTag->check_rfc5646_parsed_tag
          ($parsed, $onerror);

      my $expected = $test->{5646} || $test->{4646};
      if ($expected) {
        eq_or_diff join ("\n", sort {$a cmp $b} @errors),
            join ("\n", sort {$a cmp $b} @{$expected->[0]}),
            '_parse ' . $test->{data}->[0];
        is !$result->{well_formed},
            !! grep { $_ eq 'ill-formed' } @{$expected->[1]};
        is !$result->{valid},
            !! grep { $_ eq 'ill-formed' or $_ eq 'invalid' } @{$expected->[1]};

        my $canon = Whatpm::LangTag->canonicalize_rfc5646_tag
            ($test->{data}->[0]);
        is $canon, ($test->{canon5646} || $test->{data})->[0];

        my $extlang = Whatpm::LangTag->to_extlang_form_rfc5646_tag
            ($test->{data}->[0]);
        is $extlang, ($test->{extlang5646} || $test->{canon5646} || $test->{data})->[0];
      }
    }
  }) for map { file (__FILE__)->dir->file ($_)->stringify } qw[
    langtag-1.dat
    langtag-u-1.dat
  ];
} # _parse

sub _parse_zh_min_nan : Test(2) {
  my $parsed1 = Whatpm::LangTag->parse_rfc4646_tag ('zh-min-nan');
  eq_or_diff $parsed1, {
    language => 'zh',
    extlang => [qw(min nan)],
    variant => [],
    illegal => [],
    privateuse => [],
    extension => [],
  };

  my $parsed2 = Whatpm::LangTag->parse_rfc5646_tag ('zh-min-nan');
  eq_or_diff $parsed2, {
    extlang => [],
    variant => [],
    illegal => [],
    privateuse => [],
    extension => [],
    grandfathered => 'zh-min-nan',
  };
} # _parse_zh_min_nan

sub _parse_u_extension : Test(10) {
  for (
    ['en-u-ab', [qw[u ab]], [[], [qw[ab]]]],
    ['en-u-ab-cde-fgh', [qw[u ab cde fgh]], [[], [qw[ab cde fgh]]]],
    ['en-u-ab-cd', [qw[u ab cd]], [[], [qw[ab]], [qw[cd]]]],
    ['en-u-ab-cde-ab', [qw[u ab cde ab]], [[], [qw[ab cde]], [qw[ab]]]],
    ['en-u-ab-12-xyz-AB', [qw[u ab 12 xyz AB]], [[], [qw[ab]], [qw[12 xyz]], [qw[AB]]]],
    ['en-u-abc', [qw[u abc]], [[qw[abc]]]],
    ['en-u-abc-def', [qw[u abc def]], [[qw[abc def]]]],
    ['en-u-abc-12', [qw[u abc 12]], [[qw[abc]], [qw[12]]]],
    ['en-U-abc', [qw[U abc]], [[qw[abc]]]],
    ['en-u-1ab', [qw[u 1ab]], [[qw[1ab]]]],
  ) {
    my $parsed = Whatpm::LangTag->parse_rfc5646_tag ($_->[0]);
    eq_or_diff $parsed, {
      language => 'en',
      extlang => [],
      variant => [],
      illegal => [],
      privateuse => [],
      extension => [$_->[1]],
      u => $_->[2],
  };
  }
} # _parse_u_extension

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
    is +Whatpm::LangTag->normalize_rfc5646_tag ($_->[0]), $_->[1];
  }
} # _normalize

sub _basic_filtering_rfc4647_range : Test(70) {
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
     ['x-hoge', 'en-x-hoge-fuga', 0],
     ['x', 'x-hoge-fuga', 1],
     ['x-', 'x-hoge-fuga', 0],
  ) {
    is !!Whatpm::LangTag->basic_filtering_rfc4647_range ($_->[0], $_->[1]),
       !!$_->[2];
    is !!Whatpm::LangTag->match_rfc3066_range ($_->[0], $_->[1]),
       !!$_->[2];
  }
} # _basic_filtering_rfc4647_range

sub _extended_filtering_rfc4647_range : Test(68) {
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
     ['de-ch', 'de-Latn-ch', 1],
     ['de-ch', 'de', 0],
     ['de-ch', 'x-de-ch', 0],
     ['de', 'de-ch-1996', 1],
     ['de', 'de-ch', 1],
     ['x-hoge', 'de-ch', 0],
     ['x-hoge', 'x-hoge', 1],
     ['x-hoge', 'x-hoge-fuga', 1],
     ['x-hoge', 'en-x-hoge-fuga', 0],
     ['x', 'x-hoge-fuga', 1],
     ['x-', 'x-hoge-fuga', 0],
     ['de-DE', 'de-de', 1],
     ['de-DE', 'de-De', 1],
     ['de-DE', 'de-DE', 1],
     ['de-DE', 'de-Latn-DE', 1],
     ['de-DE', 'de-Latf-DE', 1],
     ['de-DE', 'de-DE-x-goethe', 1],
     ['de-DE', 'de-Latn-DE-1996', 1],
     ['de-DE', 'de-Deva-DE', 1],
     ['de-DE', 'de', 0],
     ['de-DE', 'de-x-DE', 0],
     ['de-DE', 'de-Deva', 0],
     ['ja-*', 'ja', 1],
     ['ja-*', 'ja-jp', 1],
     ['ja-*', 'ja-x-hoge', 1],
     ['ja-*-*', 'ja', 1],
     ['ja-*-*', 'ja-jp', 1],
     ['ja-*-*', 'ja-x-hoge', 1],
     ['ja-*-*-jp', 'ja-jp', 1],
     ['ja-*-*-jp', 'ja-latn-jp', 1],
     ['ja-*-*-jp', 'ja-latn-us', 0],
     ['*-*-jp', 'ja-latn-jp', 1],
     ['*-*-jp', 'ja-latn-us', 0],
     ['*-*-jp', 'ja-jp', 1],
     ['*-*-jp', 'ja-us', 0],
     ['*-jp', 'ja-latn-jp', 1],
     ['*-jp', 'ja-latn-us', 0],
     ['*', 'ja-latn-jp', 1],
     ['*', 'ja-latn-us', 1],
     ['*-x', 'ja-x-latn', 1],
     ['*-y', 'ja-x-latn', 0],
     ['x', 'ja-x-latn', 0],
     ['x', 'x-latn', 1],
     ['latn', 'x-latn', 0],
  ) {
    is !!Whatpm::LangTag->extended_filtering_rfc4647_range ($_->[0], $_->[1]),
       !!$_->[2];
  }
} # _extended_filtering_rfc4647_range

sub _tag_registry_data : Test(40) {
  for my $method (qw(
    tag_registry_data_rfc4646
    tag_registry_data_rfc5646
  )) {
    my $ja = Whatpm::LangTag->$method (language => 'ja');
    ok !$ja->{_canon};
    is $ja->{_added}, '2005-10-16';
    is $ja->{_suppress}, 'jpan';
    ok !$ja->{_deprecated};
    ok !$ja->{_preferred};
    ok !$ja->{Prefix};
    eq_or_diff $ja->{Description}, ['Japanese'];
    
    my $us = Whatpm::LangTag->$method (region => 'us');
    is $us->{_canon}, '_uppercase';
    is $us->{_added}, '2005-10-16';
    ok !$us->{_suppress};
    ok !$us->{_deprecated};
    ok !$us->{_preferred};
    ok !$us->{Prefix};
    eq_or_diff $us->{Description}, ['United States'];
    
    my $not_registered = Whatpm::LangTag->$method (script => 123);
    is $not_registered, undef;
    
    my $no_type = Whatpm::LangTag->$method (bad => 'ja');
    is $no_type, undef;
    
    my $grandfathered = Whatpm::LangTag->$method (grandfathered => 'i-ami');
    ok $grandfathered->{_deprecated};
    is $grandfathered->{_preferred}, 'ami';
    
    my $redundant = Whatpm::LangTag->$method (redundant => 'zh-yue');
    ok $redundant->{_deprecated};
    is $redundant->{_preferred}, 'yue';
  }
} # tag_registry_data

__PACKAGE__->runtests;

## License: Public Domain.

1;
