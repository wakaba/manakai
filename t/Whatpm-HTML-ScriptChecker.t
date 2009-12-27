#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use Whatpm::HTML::ScriptChecker;
use Test;

BEGIN { plan tests => 47 }

BEGIN { require 'testfiles.pl' };

my $text_input_f = file (__FILE__)->dir->subdir ('html-misc')->file ('script-text.dat');
execute_test $text_input_f, {
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

  Whatpm::HTML::ScriptChecker->check_element_text (\$data, $onerror);

  ok join ("\n", @error), join ("\n", @{$test->{errors}->[0] or []});
};

my $inline_input_f = file (__FILE__)->dir->subdir ('html-misc')->file ('script-inline-docs.dat');
execute_test $inline_input_f, {
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
