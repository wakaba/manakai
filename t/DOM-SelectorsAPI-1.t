#!/usr/bin/perl
use strict;

use lib qw[/home/httpd/html/www/markup/html/whatpm]; ## TODO: ...

use Test;

BEGIN { plan tests => 186 }

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
  my $root;
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      push @{$all_test->{test}}, $test;
      $mode = 'data';
    } elsif (/^#result (\S+)$/) {
      $label = $1;
      $root = '/';
      $test->{result}->{$label}->{$root} = [];
      $mode = 'result';
      $test->{data} =~ s/\x0D?\x0A\z//;       
    } elsif (/^#result (\S+) (\S+)$/) {
      $label = $1;
      $root = $2;
      $test->{result}->{$label}->{$root} = [];
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
        push @{$test->{result}->{$label}->{$root}}, $_;
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
      my $doc = $all_test->{document}->{$label}->{document};
      unless ($doc) {
        die "Test document $label is not defined";
      }
      my $ns = sub {
        my $prefix = shift;
        if (defined $prefix) {
          return $test->{ns}->{$prefix};
        } else {
          return $test->{ns}->{''};
        }
      };

      for my $root (keys %{$test->{result}->{$label}}) {
        my $root_node = get_node_by_path ($doc, $root);

        ## query_selector_all
        my $expected = join "\n", @{$test->{result}->{$label}->{$root}};
        my $actual = join "\n", map {
          get_node_path ($_)
        } @{$root_node->query_selector_all ($test->{data}, $ns)};
        ok $actual, $expected, "$test->{data} $label $root all";

        ## query_selector
        $expected = $test->{result}->{$label}->{$root}->[0];
        undef $actual;
        my $node = $root_node->query_selector ($test->{data}, $ns);
        $actual = get_node_path ($node) if defined $node;
        ok $actual, $expected, "$test->{data} $label $root one";
      }
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

sub get_node_by_path ($$) {
  my ($doc, $path) = @_;
  if ($path eq '/') {
    return $doc;
  } else {
    for (map {$_ - 1} grep {$_} split m#/#, $path) {
      $doc = $doc->child_nodes->[$_];
    }
    return $doc;
  }
} # get_node_by_path
