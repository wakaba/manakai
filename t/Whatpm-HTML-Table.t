#!/usr/bin/perl
package test::Whatpm::HTML::Table;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use base qw(Test::Class);
use Test::More;
use Test::Differences;
use Whatpm::HTML::Table;
use Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;

sub serialize_node ($);
sub serialize_node ($) {
  my $obj = shift;
  if (not defined $obj or not ref $obj or ref $obj eq 'CODE') {
    return $obj;
  } elsif (ref $obj eq 'ARRAY') {
    return [map { serialize_node $_ } @$obj];
  } elsif (ref $obj eq 'HASH') {
    return {map { serialize_node $_ } %$obj};
  } elsif ($obj->isa ('Message::DOM::Node')) {
    return $obj->node_name . ' ' . $obj->text_content;
  } else {
    return $obj;
  }
} # serialize_node

sub cr ($) {
  my $s = shift;
  my $r = {};
  if ($s =~ s[^([dh]+)/?][]) {
    my $v = $1;
    $r->{has_data} = 1 if $v =~ /d/;
    $r->{has_header} = 1 if $v =~ /h/;
  }
  
  $r->{element} = $s if length $s;
  
  return $r;
} # cr

sub cell ($) {
  my $s = shift;
  my $r = {};

  if ($s =~ s[^(\d+),(\d+),(\d+),(\d+)/(.+)$][]) {
    $r->{x} = $1+1-1;
    $r->{y} = $2+1-1;
    $r->{width} = $3+1-1;
    $r->{height} = $4+1-1;
    $r->{element} = $5;

    if ($r->{element} =~ /^th/) {
      $r->{is_header} = 1;
      $r->{scope} = '';
    }
  }
  
  return $r;
} # cell

sub rg ($) {
  my $s = shift;
  my $r = {};

  if ($s =~ s[^(\d+),(\d+),(\d+)/(.+)$][]) {
    $r->{x} = $1+1-1;
    $r->{y} = $2+1-1;
    $r->{height} = $3+1-1;
    $r->{element} = $4;
  }
  
  return $r;
} # rg

sub remove_tbody ($) {
  my $table_el = shift;
  $table_el->append_child ($table_el->first_child->first_child)
      while $table_el->first_child->first_child;
  $table_el->remove_child ($table_el->first_child); # tbody
} # remove_tbody

sub _form_table : Test(2) {
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for (
    {
      input => q[<tr><td>1<td>2<tr><th>3<th>4],
      result => {
        column_group => [], column => [cr 'dh', cr 'dh'],
        row_group => [rg '0,0,2/tbody 1234', rg '0,0,2/tbody 1234'],
        row => [cr 'd/tr 12', cr 'h/tr 34'],
        cell => [
          [[cell '0,0,1,1/td 1'], [cell '0,1,1,1/th 3']],
          [[cell '1,0,1,1/td 2'], [cell '1,1,1,1/th 4']],
        ],
        width => 2, height => 2, element => 'table 1234',
      },
    },
    {
      input => q[<tr><td>1<td>2<tr><th>3<th>4],
      without_tbody => 1,
      result => {
        column_group => [], column => [cr 'dh', cr 'dh'],
        row_group => [], row => [cr 'd/tr 12', cr 'h/tr 34'],
        cell => [
          [[cell '0,0,1,1/td 1'], [cell '0,1,1,1/th 3']],
          [[cell '1,0,1,1/td 2'], [cell '1,1,1,1/th 4']],
        ],
        width => 2, height => 2, element => 'table 1234',
      },
    },
  ) {
    my $table_el = $doc->create_element ('table');
    $table_el->inner_html ($_->{input});
    remove_tbody $table_el if $_->{without_tbody};
    
    my $table = Whatpm::HTML::Table->form_table ($table_el);
    eq_or_diff serialize_node $table, $_->{result};
  }
} # _form_table

__PACKAGE__->runtests;

1;
