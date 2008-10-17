#!/usr/bin/perl
use strict;

my $DEBUG = $ENV{DEBUG};

use lib qw[/home/wakaba/work/manakai2/lib];
my $test_dir_name = 't/xml/';

use Test;
BEGIN { plan tests => 4935 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

if ($DEBUG) {
  my $not_found = {%{$Whatpm::HTML::Debug::cp or {}}};
  $Whatpm::HTML::Debug::cp_pass = sub {
    my $id = shift;
    delete $not_found->{$id};
  };

  END {
    for my $id (sort {$a <=> $b || $a cmp $b} keys %$not_found) {
      print "# checkpoint $id is not reached\n";
    }
  }
}

use Whatpm::XML::Parser;
use Whatpm::NanoDOM;
use Whatpm::Charset::UnicodeChecker;
use Whatpm::HTML::Dumper qw/dumptree/;

sub test ($) {
  my $test = shift;

  if ($test->{'document-fragment'}) {
    if (@{$test->{'document-fragment'}->[1]}) {
      ## NOTE: Old format.
      $test->{element} = $test->{'document-fragment'}->[1]->[0];
      $test->{document} ||= $test->{'document-fragment'};
    } else {
      ## NOTE: New format.
      $test->{element} = $test->{'document-fragment'}->[0];
    }
  }

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

  my $chk = sub {
    return $_[0];
    #return Whatpm::Charset::UnicodeChecker->new_handle ($_[0], 'html5');
  }; # $chk

  my $result;
  unless (defined $test->{element}) {
    Whatpm::XML::Parser->parse_char_string
        ($test->{data}->[0] => $doc, $onerror, $chk);
    $result = dumptree ($doc);
  } else {
    ## TODO: ...
    my $el = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, $test->{element}]);
    Whatpm::HTML->set_inner_html ($el, $test->{data}->[0], $onerror, $chk);
    $result = dumptree ($el);
  }
  
  warn "No #errors section ($test->{data}->[0])" unless $test->{errors};

  @errors = sort {$a cmp $b} @errors;
  @{$test->{errors}->[0]} = sort {$a cmp $b} @{$test->{errors}->[0] ||= []};
  
  ok join ("\n", @errors), join ("\n", @{$test->{errors}->[0] or []}),
    'Parse error: ' . Data::Dumper::qquote ($test->{data}->[0]);

  if ($test->{'xml-version'}) {
    ok $doc->xml_version, $test->{'xml-version'}->[0],
        'XML version: ' . Data::Dumper::qquote ($test->{data}->[0]);
  }

  if ($test->{'xml-encoding'}) {
    if ($test->{'xml-encoding'}->[1]->[0] eq 'null') {
      ok $doc->xml_encoding, undef, 
        'XML encoding: ' . Data::Dumper::qquote ($test->{data}->[0]);
    } else {
      ok $doc->xml_encoding, $test->{'xml-encoding'}->[0],
          'XML encoding: ' . Data::Dumper::qquote ($test->{data}->[0]);
    }
  }

  if ($test->{'xml-standalone'}) {
    ok $doc->xml_standalone ? 1 : 0,
        $test->{'xml-standalone'}->[1]->[0] eq 'true' ? 1 : 0,
        'XML standalone: ' . Data::Dumper::qquote ($test->{data}->[0]);
  }
  
  $test->{document}->[0] .= "\x0A" if length $test->{document}->[0];
  ok $result, $test->{document}->[0],
      'Document tree: ' . Data::Dumper::qquote ($test->{data}->[0]);
} # test

my @FILES = grep {$_} split /\s+/, qq[
  ${test_dir_name}elements-1.dat
  ${test_dir_name}attrs-1.dat
  ${test_dir_name}texts-1.dat
  ${test_dir_name}cdata-1.dat
  ${test_dir_name}charref-1.dat
  ${test_dir_name}comments-2.dat
  ${test_dir_name}pis-1.dat
  ${test_dir_name}pis-2.dat
  ${test_dir_name}xmldecls-1.dat
  ${test_dir_name}tree-1.dat
  ${test_dir_name}ns-elements-1.dat
  ${test_dir_name}ns-attrs-1.dat
  ${test_dir_name}doctypes-1.dat
  ${test_dir_name}doctypes-2.dat
  ${test_dir_name}attlists-1.dat
];

require 't/testfiles.pl';
execute_test ($_, {
  errors => {is_list => 1},
  document => {is_prefixed => 1},
  'document-fragment' => {is_prefixed => 1},
}, \&test) for @FILES;

## License: Public Domain.
## $Date: 2008/10/17 07:14:29 $
