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
BEGIN { plan tests => 402 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

for my $file_name (grep {$_} split /\s+/, qq[
                      ${dir_name}tests1.dat
                      ${dir_name}tests2.dat
                      ${dir_name}tests3.dat
                      ${dir_name}tests4.dat
                      ${test_dir_name}tree-test-1.dat
                     ]) {
  open my $file, '<', $file_name
    or die "$0: $file_name: $!";

  my $test;
  my $mode = 'data';
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
    } elsif (/^#errors$/) {
      $test->{errors} = [];
      $mode = 'errors';
      $test->{data} =~ s/\x0D?\x0A\z//;       
    } elsif (/^#document$/) {
      $test->{document} = '';
      $mode = 'document';
    } elsif (defined $test->{document} and /^$/) {
      test ($test);
      undef $test;
    } else {
      if ($mode eq 'data' or $mode eq 'document') {
        $test->{$mode} .= $_;
      } elsif ($mode eq 'errors') {
        tr/\x0D\x0A//d;
        push @{$test->{errors}}, $_;
      }
    }
  }
  test ($test) if $test->{errors};
}

use What::HTML;

sub test ($) {
  my $test = shift;

  my $s = $test->{data};

  my $p = What::HTML->new;
  my $i = 0;
  $p->{set_next_input_character} = sub {
    my $self = shift;
    $self->{next_input_character} = -1 and return if $i >= length $s;
    $self->{next_input_character} = ord substr $s, $i++, 1;
    
    if ($self->{next_input_character} == 0x000D) { # CR
      if ($i >= length $s) {
        #
      } else {
        my $next_char = ord substr $s, $i++, 1;
        if ($next_char == 0x000A) { # LF
          #
        } else {
          push @{$self->{char}}, $next_char;
        }
      }
      $self->{next_input_character} = 0x000A; # LF # MUST
    } elsif ($self->{next_input_character} > 0x10FFFF) {
      $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    } elsif ($self->{next_input_character} == 0x0000) { # NULL
      $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    }
  };
  
  my @errors;
  $p->{parse_error} = sub {
    my $msg = shift;
    push @errors, $msg;
  };
  
  $SIG{INT} = sub {
    print scalar serialize ($p->{document});
    exit;
  };
  
  $p->_initialize_tokenizer;
  $p->_initialize_tree_constructor;
  $p->_construct_tree;
  $p->_terminate_tree_constructor;

  ok scalar @errors, scalar @{$test->{errors}},
    'Parse error: ' . $test->{data} . '; ' . 
    join (', ', @errors) . ';' . join (', ', @{$test->{errors}});

  my $doc = $p->{document};
  my $doc_s = serialize ($doc);
  ok $doc_s, $test->{document}, 'Document tree: ' . $test->{data};
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
## $Date: 2007/05/01 06:22:12 $
