#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;

use Test;
BEGIN {
  require 't/testfiles.pl';
  plan (tests => 133);
}

require Whatpm::LangTag;

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
    ok join ("\n", sort {$a cmp $b} @errors),
        join ("\n", sort {$a cmp $b} @{$test->{4646}->[0]}),
        $test->{data}->[0];
  } else {
    warn qq[No test item: "$test->{data}->[0]];
  }
}) for qw[
  t/langtag-1.dat
];

## License: Public Domain.
## $Date: 2008/09/18 14:32:48 $
