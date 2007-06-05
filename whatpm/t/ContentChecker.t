#!/usr/bin/perl
use strict;

use Test;
BEGIN { plan tests => 873 }

my @FILES = qw[
  t/content-model-1.dat
  t/content-model-2.dat
  t/content-model-3.dat
];

require Whatpm::ContentChecker;

## ISSUE: Currently we require manakai XML parser to test arbitrary XML tree.
use lib qw[/home/wakaba/work/manakai/lib];
require Message::DOM::DOMCore;
require Message::DOM::XMLParser;
require Whatpm::HTML;
require Whatpm::NanoDOM;

my $dom = $Message::DOM::DOMImplementationRegistry->get_dom_implementation;
my $parser = $dom->create_ls_parser (1);

for my $file_name (@FILES) {
  open my $file, '<', $file_name or die "$0: $file_name: $!";

  my $test;
  my $mode = 'data';
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
      $test->{parse_as} = 'xml';
    } elsif (/^#data html$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
      $test->{parse_as} = 'html';
    } elsif (/^#errors$/) {
      $test->{errors} = [];
      $mode = 'errors';
      $test->{data} =~ s/\x0D?\x0A\z//;       
    } elsif (defined $test->{errors} and /^$/) {
      test ($test);
      undef $test;
    } else {
      if ($mode eq 'data') {
        $test->{$mode} .= $_;
      } elsif ($mode eq 'errors') {
        tr/\x0D\x0A//d;
        push @{$test->{errors}}, $_;
      }
    }
  }
} # @FILES

sub test ($) {
  my $test = shift;

  my $doc;
  if ($test->{parse_as} eq 'xml') {
    $doc = $parser->parse ({string_data => $test->{data}});
    ## NOTE: There should be no well-formedness error; if there is,
    ## then it is an error of the test case itself.
  } else {
    $doc = Whatpm::NanoDOM::Document->new;
    Whatpm::HTML->parse_string ($test->{data} => $doc);
  }

  my @error;
  Whatpm::ContentChecker->check_element
    ($doc->document_element, sub {
       my %opt = @_;
       push @error, get_node_path ($opt{node}) . ';' . $opt{type};
     });
  
  ok join ("\n", sort {$a cmp $b} @error),
    join ("\n", sort {$a cmp $b} @{$test->{errors}}), $test->{data};
} # test

sub get_node_path ($) {
  my $node = shift;
  my @r;
  while (defined $node) {
    my $rs;
    if ($node->node_type == 1) {
      $rs = $node->manakai_local_name;
      $node = $node->parent_node;
    } elsif ($node->node_type == 2) {
      $rs = '@' . $node->manakai_local_name;
      $node = $node->owner_element;
    } elsif ($node->node_type == 3) {
      $rs = '"' . $node->data . '"';
      $node = $node->parent_node;
    } elsif ($node->node_type == 9) {
      $rs = '';
      $node = $node->parent_node;
    } else {
      $rs = '#' . $node->node_type;
      $node = $node->parent_node;
    }
    unshift @r, $rs;
  }
  return join '/', @r;
} # get_node_path

## License: Public Domain.
## $Date: 2007/06/05 00:56:43 $
