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

for my $file_name (grep {$_} split /\s+/, qq[
                      ${test_dir_name}tokenizer-test-2.dat
                      ${test_dir_name}tokenizer-test-3.dat
                      ${dir_name}tests1.dat
                      ${dir_name}tests2.dat
                      ${dir_name}tests3.dat
                      ${dir_name}tests4.dat
                      ${dir_name}tests5.dat
                      ${dir_name}tests6.dat
                      ${dir_name}tests7.dat
                      ${test_dir_name}tree-test-1.dat
                      ${test_dir_name}tree-test-2.dat
                      ${test_dir_name}tree-test-3.dat
                      ${test_dir_name}tree-test-void.dat
                      ${test_dir_name}tree-test-flow.dat
                      ${test_dir_name}tree-test-phrasing.dat
                      ${test_dir_name}tree-test-form.dat
                      ${test_dir_name}tree-test-foreign.dat
                     ]) {
  open my $file, '<', $file_name
    or die "$0: $file_name: $!";
  print "# $file_name\n";

  my $test;
  my $mode = 'data';
  my $escaped;
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
      undef $escaped;
    } elsif (/^#data escaped$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
      $escaped = 1;
    } elsif (/^#errors$/) {
      $test->{errors} = [];
      $mode = 'errors';
      $test->{data} =~ s/\x0D?\x0A\z//;       
      $test->{data} =~ s/\\u([0-9A-Fa-f]{4})/chr hex $1/ge if $escaped;
      $test->{data} =~ s/\\U([0-9A-Fa-f]{8})/chr hex $1/ge if $escaped;
      undef $escaped;
    } elsif (/^#shoulds$/) {
      $test->{shoulds} = [];
      $mode = 'shoulds';
    } elsif (/^#document$/) {
      $test->{document} = '';
      $mode = 'document';
      undef $escaped;
    } elsif (/^#document escaped$/) {
      $test->{document} = '';
      $mode = 'document';
      $escaped = 1;
    } elsif (/^#document-fragment$/) {
      $test->{element} = '';
      $mode = 'element';
      undef $escaped;
    } elsif (/^#document-fragment (\S+)$/) {
      $test->{document} = '';
      $mode = 'document';
      $test->{element} = $1;
      undef $escaped;
    } elsif (/^#document-fragment (\S+) escaped$/) {
      $test->{document} = '';
      $mode = 'document';
      $test->{element} = $1;
      $escaped = 1;
    } elsif (defined $test->{document} and /^$/) {
      $test->{document} =~ s/\\u([0-9A-Fa-f]{4})/chr hex $1/ge if $escaped;
      $test->{document} =~ s/\\U([0-9A-Fa-f]{8})/chr hex $1/ge if $escaped;
      test ($test);
      undef $test;
    } else {
      if ($mode eq 'data' or $mode eq 'document') {
        $test->{$mode} .= $_;
      } elsif ($mode eq 'element') {
        tr/\x0D\x0A//d;
        $test->{$mode} .= $_;
      } elsif ($mode eq 'errors') {
        tr/\x0D\x0A//d;
        push @{$test->{errors}}, $_;
      } elsif ($mode eq 'shoulds') {
        tr/\x0D\x0A//d;
        push @{$test->{shoulds}}, $_;
      }
    }
  }
  test ($test) if $test->{errors};
}

use Whatpm::HTML;
use Whatpm::NanoDOM;
use Whatpm::Charset::UnicodeChecker;

sub test ($) {
  my $test = shift;

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
    Whatpm::HTML->parse_char_string ($test->{data} => $doc, $onerror, $chk);
    $result = serialize ($doc);
  } else {
    my $el = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, $test->{element}]);
    Whatpm::HTML->set_inner_html ($el, $test->{data}, $onerror, $chk);
    $result = serialize ($el);
  }
    
  ok scalar @errors, scalar @{$test->{errors}},
    'Parse error: ' . Data::Dumper::qquote ($test->{data}) . '; ' . 
    join (', ', @errors) . ';' . join (', ', @{$test->{errors}});
  ok scalar @shoulds, scalar @{$test->{shoulds} or []},
    'SHOULD-level error: ' . Data::Dumper::qquote ($test->{data}) . '; ' . 
    join (', ', @shoulds) . ';' . join (', ', @{$test->{shoulds} or []});

  ok $result, $test->{document},
      'Document tree: ' . Data::Dumper::qquote ($test->{data});
} # test

sub serialize ($) {
  my $node = shift;
  my $r = '';

  my @node = map { [$_, ''] } @{$node->child_nodes};
  while (@node) {
    my $child = shift @node;
    my $nt = $child->[0]->node_type;
    if ($nt == $child->[0]->ELEMENT_NODE) {
      $r .= '| ' . $child->[1] . '<' . $child->[0]->tag_name . ">\x0A"; ## ISSUE: case?

      for my $attr (sort {$a->[0] cmp $b->[0]} map { [$_->name, $_->value] }
                    @{$child->[0]->attributes}) {
        $r .= '| ' . $child->[1] . '  ' . $attr->[0] . '="'; ## ISSUE: case?
        $r .= $attr->[1] . '"' . "\x0A";
      }
      
      unshift @node,
        map { [$_, $child->[1] . '  '] } @{$child->[0]->child_nodes};
    } elsif ($nt == $child->[0]->TEXT_NODE) {
      $r .= '| ' . $child->[1] . '"' . $child->[0]->data . '"' . "\x0A";
    } elsif ($nt == $child->[0]->COMMENT_NODE) {
      $r .= '| ' . $child->[1] . '<!-- ' . $child->[0]->data . " -->\x0A";
    } elsif ($nt == $child->[0]->DOCUMENT_TYPE_NODE) {
      $r .= '| ' . $child->[1] . '<!DOCTYPE ' . $child->[0]->name;
      my $pubid = $child->[0]->public_id;
      $r .= ' PUBLIC "' . $pubid . '"' if length $pubid;
      my $sysid = $child->[0]->system_id;
      $r .= ' SYSTEM' if not length $pubid and length $sysid;
      $r .= ' "' . $sysid . '"' if length $sysid;
      $r .= ">\x0A";
    } else {
      $r .= '| ' . $child->[1] . $child->[0]->node_type . "\x0A"; # error
    }
  }
  
  return $r;
} # serialize

## License: Public Domain.
## $Date: 2008/10/04 12:20:36 $
