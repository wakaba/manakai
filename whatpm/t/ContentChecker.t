#!/usr/bin/perl
use strict;

use Test;
BEGIN { plan tests => 1502 }

my @FILES = qw[
  t/content-model-1.dat
  t/content-model-2.dat
  t/content-model-3.dat
  t/content-model-4.dat
  t/content-model-5.dat
  t/table-1.dat
  t/content-model-atom-1.dat
  t/content-model-atom-2.dat
  t/content-model-atom-threading-1.dat
];

require Whatpm::ContentChecker;

## ISSUE: Currently we require manakai XML parser to test arbitrary XML tree.
use lib qw[/home/wakaba/work/manakai2/lib];
require Message::DOM::DOMImplementation;
require Message::DOM::XMLParserTemp;
require Whatpm::HTML;
require Whatpm::NanoDOM;

my $dom = Message::DOM::DOMImplementation->new;

for my $file_name (@FILES) {
  open my $file, '<', $file_name or die "$0: $file_name: $!";
  print "# $file_name\n";

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
    open my $fh, '<', \($test->{data});
    $doc = Message::DOM::XMLParserTemp->parse_byte_stream
      ($fh => $dom, sub { }, charset => 'utf-8');
    $doc->input_encoding (undef);
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
       if ($opt{type} =~ /^status:/ and $opt{level} eq 'i') {
         #
       } else {
         push @error, get_node_path ($opt{node}) . ';' . $opt{type} .
             (defined $opt{level} ? ';'.$opt{level} : '');
       }
     }, sub {
       my $opt = shift;
       push @error, get_node_path ($opt->{container_node}) . ';SUBDOC';
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
## $Date: 2008/03/20 09:38:47 $
