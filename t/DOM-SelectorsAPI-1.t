#!/usr/bin/perl
use strict;

use lib qw[/home/httpd/html/www/markup/html/whatpm]; ## TODO: ...

use Test;

BEGIN { plan tests => 61 }

require Message::DOM::DOMImplementation;
my $dom = Message::DOM::DOMImplementation->new;

for my $file_name (qw(
  selectors-test-1.dat
)) {
  print "# $file_name\n";
  open my $file, '<', $file_name or die "$0: $file_name: $!";

  my $all_test = {document => {}, test => []};
  my $test;
  my $mode = 'data';
  my $label;
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      push @{$all_test->{test}}, $test;
      $mode = 'data';
    } elsif (/^#result (\S+)$/) {
      $label = $1;
      $test->{result}->{$label} = [];
      $mode = 'result';
      $test->{data} =~ s/\x0D?\x0A\z//;       
    } elsif (/^#ns (\S+)$/) {
      $test->{ns}->{''} = $1;
    } elsif (/^#ns (\S+) (\S+)$/) {
      $test->{ns}->{$1} = $2;
    } elsif (/^#html (\S+)$/) {
      undef $test;
      $test->{format} = 'html';
      $test->{data} = '';
      $all_test->{document}->{$1} = $test;
      $mode = 'data';
    } elsif (defined $test->{data} and /^$/) {
      undef $test;
    } else {
      if ($mode eq 'data' or $mode eq 'document') {
        $test->{$mode} .= $_;
      } elsif ($mode eq 'result') {
        tr/\x0D\x0A//d;
        push @{$test->{result}->{$label}}, $_;
      }
    }
  }

  for my $data (values %{$all_test->{document}}) {
    if ($data->{format} eq 'html') {
      my $doc = $dom->create_document;
      $doc->manakai_is_html (1);
      $doc->inner_html ($data->{data});
      $data->{document} = $doc;
    } else {
      die "Test data format $data->{format} is not supported";
    }
  }

  for my $test (@{$all_test->{test}}) {
    for my $label (keys %{$test->{result}}) {
      my $expected = join "\n", @{$test->{result}->{$label}};
      my $doc = $all_test->{document}->{$label}->{document};
      unless ($doc) {
        die "Test document $label is not defined";
      }
      my $actual = join "\n", map {
        get_node_path ($_)
      } @{$doc->query_selector_all ($test->{data}, sub {
        my $prefix = shift;
        if (defined $prefix) {
          return $test->{ns}->{$prefix};
        } else {
          return $test->{ns}->{''};
        }
      })};
      ok $actual, $expected;
    }
  }
}

sub get_node_path ($) {
  my $node = shift;
  my $r = '';
  my $parent = $node->parent_node;
  while ($parent) {
    my $i = 0;
    for (@{$parent->child_nodes}) {
      $i++;
      if ($_ eq $node) {
        $r = '/' . $i . $r;
      }
    }
    ($parent, $node) = ($parent->parent_node, $parent);
  }
  return $r;
} # get_node_path
