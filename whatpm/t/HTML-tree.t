#!/usr/bin/perl
use strict;

my $DEBUG = $ENV{DEBUG};

use lib qw[/home/wakaba/work/manakai2/lib];

my $dir_name;
my $test_dir_name;
BEGIN {
  $test_dir_name = 't/';
  $dir_name = 't/tree-construction/';
  my $skip = "You don't have make command";
  eval q{
         system ("cd $test_dir_name; make tree-construction-files") == 0 or die
           unless -f $dir_name.'tests1.dat';
         $skip = '';
        };
  if ($skip) {
    print "1..1\n";
    print "ok 1 # $skip\n";
    exit;
  }
}

use Test;
BEGIN { plan tests => 3105 }

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

my @FILES = grep {$_} split /\s+/, qq[
                      ${test_dir_name}tokenizer-test-2.dat
                      ${test_dir_name}tokenizer-test-3.dat
                      ${dir_name}tests1.dat
                      ${dir_name}tests2.dat
                      ${dir_name}tests3.dat
                      ${dir_name}tests4.dat
                      ${dir_name}tests5.dat
                      ${dir_name}tests6.dat
                      ${dir_name}tests7.dat
                      ${dir_name}tests8.dat
                      ${dir_name}tests9.dat
                      ${dir_name}tests10.dat
                      ${dir_name}tests11.dat
                      ${dir_name}tests12.dat
                      ${test_dir_name}tree-test-1.dat
                      ${test_dir_name}tree-test-2.dat
                      ${test_dir_name}tree-test-3.dat
                      ${test_dir_name}tree-test-void.dat
                      ${test_dir_name}tree-test-flow.dat
                      ${test_dir_name}tree-test-phrasing.dat
                      ${test_dir_name}tree-test-form.dat
                      ${test_dir_name}tree-test-foreign.dat
                     ];

require 't/testfiles.pl';
execute_test ($_, {
  errors => {is_list => 1},
  shoulds => {is_list => 1},
  document => {is_prefixed => 1},
  'document-fragment' => {is_prefixed => 1},
}, \&test) for @FILES;

use Whatpm::HTML;
use Whatpm::NanoDOM;
use Whatpm::Charset::UnicodeChecker;

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
  my @shoulds;
  
  $SIG{INT} = sub {
    print scalar serialize ($doc);
    exit;
  };

  my $onerror = sub {
    my %opt = @_;
    if ($opt{level} eq 's') {
      push @shoulds, join ':', $opt{line}, $opt{column}, $opt{type};
    } else {
      push @errors, join ':', $opt{line}, $opt{column}, $opt{type};
    }
  };

  my $chk = sub {
    return Whatpm::Charset::UnicodeChecker->new_handle ($_[0], 'html5');
  }; # $chk

  my $result;
  unless (defined $test->{element}) {
    Whatpm::HTML->parse_char_string
        ($test->{data}->[0] => $doc, $onerror, $chk);
    $result = serialize ($doc);
  } else {
    my $el = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, $test->{element}]);
    Whatpm::HTML->set_inner_html ($el, $test->{data}->[0], $onerror, $chk);
    $result = serialize ($el);
  }
  
  warn "No #errors section" unless $test->{errors};
    
  ok scalar @errors, scalar @{$test->{errors}->[0] or []},
    'Parse error: ' . Data::Dumper::qquote ($test->{data}->[0]) . '; ' . 
    join (', ', @errors) . ';' . join (', ', @{$test->{errors}->[0] or []});
  ok scalar @shoulds, scalar @{$test->{shoulds}->[0] or []},
    'SHOULD-level error: ' . Data::Dumper::qquote ($test->{data}->[0]) . '; ' .
    join (', ', @shoulds) . ';' . join (', ', @{$test->{shoulds}->[0] or []});

  ok $result, $test->{document}->[0] . "\x0A",
      'Document tree: ' . Data::Dumper::qquote ($test->{data}->[0]);
} # test

## NOTE: Spec: <http://wiki.whatwg.org/wiki/Parser_tests>.
sub serialize ($) {
  my $node = shift;
  my $r = '';

  my @node = map { [$_, ''] } @{$node->child_nodes};
  while (@node) {
    my $child = shift @node;
    my $nt = $child->[0]->node_type;
    if ($nt == $child->[0]->ELEMENT_NODE) {
      $r .= $child->[1] . '<' . $child->[0]->tag_name . ">\x0A"; ## ISSUE: case?

      for my $attr (sort {$a->[0] cmp $b->[0]} map { [$_->name, $_->value] }
                    @{$child->[0]->attributes}) {
        $r .= $child->[1] . '  ' . $attr->[0] . '="'; ## ISSUE: case?
        $r .= $attr->[1] . '"' . "\x0A";
      }
      
      unshift @node,
        map { [$_, $child->[1] . '  '] } @{$child->[0]->child_nodes};
    } elsif ($nt == $child->[0]->TEXT_NODE) {
      $r .= $child->[1] . '"' . $child->[0]->data . '"' . "\x0A";
    } elsif ($nt == $child->[0]->COMMENT_NODE) {
      $r .= $child->[1] . '<!-- ' . $child->[0]->data . " -->\x0A";
    } elsif ($nt == $child->[0]->DOCUMENT_TYPE_NODE) {
      $r .= $child->[1] . '<!DOCTYPE ' . $child->[0]->name;
      my $pubid = $child->[0]->public_id;
      my $sysid = $child->[0]->system_id;
      if (length $pubid or length $sysid) {
        $r .= ' "' . $pubid . '"';
        $r .= ' "' . $sysid . '"';
      }
      $r .= ">\x0A";
    } else {
      $r .= $child->[1] . $child->[0]->node_type . "\x0A"; # error
    }
  }
  
  return $r;
} # serialize

## License: Public Domain.
## $Date: 2008/10/14 06:08:26 $
