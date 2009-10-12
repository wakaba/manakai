#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;

my $test_dir_name = 't/swml/';

use Test;
BEGIN { plan tests => 1573 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

use Whatpm::SWML::Parser;
use Whatpm::NanoDOM;
use Whatpm::HTML::Dumper qw/dumptree/;

sub test ($) {
  my $test = shift;

  my $doc = Whatpm::NanoDOM::Document->new;
  my @errors;
  
  $SIG{INT} = sub {
    print scalar dumptree ($doc);
    exit;
  };

  my $onerror = sub {
    my %opt = @_;
    push @errors, join ';',
        $opt{token}->{line} || $opt{line},
        $opt{token}->{column} || $opt{column},
        $opt{type},
        defined $opt{text} ? $opt{text} : '',
        defined $opt{value} ? $opt{value} : '',
        $opt{level};
  };

  my $p = Whatpm::SWML::Parser->new;
  $p->parse_char_string ($test->{data}->[0] => $doc, $onerror);
  my $result = dumptree ($doc);
  
  warn "No #errors section ($test->{data}->[0])" unless $test->{errors};

  @errors = sort {$a cmp $b} @errors;
  @{$test->{errors}->[0]} = sort {$a cmp $b} @{$test->{errors}->[0] ||= []};
  
  ok join ("\n", @errors), join ("\n", @{$test->{errors}->[0] or []}),
    'Parse error: ' . Data::Dumper::qquote ($test->{data}->[0]);
  
  $test->{document}->[0] .= "\x0A" if length $test->{document}->[0];
  ok $result, $test->{document}->[0],
      'Document tree: ' . Data::Dumper::qquote ($test->{data}->[0]);
} # test

my @FILES = grep {$_} split /\s+/, qq[
  ${test_dir_name}structs-1.dat
  ${test_dir_name}blocks-1.dat
  ${test_dir_name}tables-1.dat
  ${test_dir_name}inlines-1.dat
  ${test_dir_name}forms-specific-1.dat
  ${test_dir_name}forms-generic-1.dat
];

require 't/testfiles.pl';
execute_test ($_, {
  data => {is_prefixed => 1},
  errors => {is_list => 1},
  document => {is_prefixed => 1},
}, \&test) for @FILES;

## License: Public Domain.
## $Date: 2008/11/07 12:35:39 $
