package test::Whatpm::LangTag;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
require (file (__FILE__)->dir->file ('testfiles.pl')->stringify);
require Whatpm::LangTag;
use Test::Differences;

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
  }) for qw[
    t/langtag-1.dat
  ];
} # _parse

__PACKAGE__->runtests;

## License: Public Domain.

1;
