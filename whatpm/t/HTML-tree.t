#!/usr/bin/perl
use strict;

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
BEGIN { plan tests => 774 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

for my $file_name (grep {$_} split /\s+/, qq[
                      ${test_dir_name}tokenizer-test-2.dat
                      ${dir_name}tests1.dat
                      ${dir_name}tests2.dat
                      ${dir_name}tests3.dat
                      ${dir_name}tests4.dat
                      ${dir_name}tests5.dat
                      ${dir_name}tests6.dat
                      ${test_dir_name}tree-test-1.dat
                      ${test_dir_name}tree-test-2.dat
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
      undef $escaped;
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
      }
    }
  }
  test ($test) if $test->{errors};
}

use Whatpm::HTML;
use Whatpm::NanoDOM;

sub test ($) {
  my $test = shift;

  my $doc = Whatpm::NanoDOM::Document->new;
  my @errors;
  
  $SIG{INT} = sub {
    print scalar serialize ($doc);
    exit;
  };

  my $onerror = sub {
    my %opt = @_;
    push @errors, join ':', $opt{line}, $opt{column}, $opt{type};
  };
  my $result;
  unless (defined $test->{element}) {
    Whatpm::HTML->parse_string ($test->{data} => $doc, $onerror);
    $result = serialize ($doc);
  } else {
    my $el = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, $test->{element}]);
    Whatpm::HTML->set_inner_html ($el, $test->{data}, $onerror);
    $result = serialize ($el);
  }
    
  ok scalar @errors, scalar @{$test->{errors}},
    'Parse error: ' . $test->{data} . '; ' . 
    join (', ', @errors) . ';' . join (', ', @{$test->{errors}});

  ok $result, $test->{document}, 'Document tree: ' . $test->{data};
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
      $r .= '| ' . $child->[1] . '<!DOCTYPE ' . $child->[0]->name . ">\x0A";
    } else {
      $r .= '| ' . $child->[1] . $child->[0]->node_type . "\x0A"; # error
    }
  }
  
  return $r;
} # serialize

## License: Public Domain.
## $Date: 2007/07/16 07:48:19 $
