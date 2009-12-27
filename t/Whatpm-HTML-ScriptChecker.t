#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use Whatpm::HTML::ScriptChecker;
use Test;

BEGIN { plan tests => 16 }

BEGIN { require 'testfiles.pl' };

my $test_input_f = file (__FILE__)->dir->subdir ('html-misc')->file ('script-inline-docs.dat');
execute_test $test_input_f, {
  data => {is_prefixed => 1},
  errors => {is_list => 1},
}, sub ($) {
  my $test = shift;
  my $data = $test->{data}->[0];

  my @error;
  my $onerror = sub ($) {
    my %args = @_;
    push @error, join ';', map { defined $_ ? $_ : '' } @args{qw(line column level type value)};
  }; # $onerror

  Whatpm::HTML::ScriptChecker->check_inline_documentation (\$data, $onerror);

  ok join ("\n", @error), join ("\n", @{$test->{errors}->[0] or []});
};
