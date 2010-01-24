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

sub _form_table_with_row_group : Test(1) {
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  my $table_el = $doc->create_element ('table');
  $table_el->inner_html (q[<tr><td>1<td>2<tr><th>3<th>4]);

  my $table = Whatpm::HTML::Table->form_table ($table_el);
  eq_or_diff serialize_node $table, {
    column_group => [],
    column => [
      {
        has_data => 1,
        has_header => 1,
      },
      {
        has_data => 1,
        has_header => 1,
      },
    ],
    row_group => [
      {
        element => 'tbody 1234',
        x => 0, y => 0, height => 2,
      },
      {
        element => 'tbody 1234',
        x => 0, y => 0, height => 2,
      },
    ],
    row => [
      {
        element => 'tr 12',
        has_data => 1,
      },
      {
        element => 'tr 34',
        has_header => 1,
      },
    ],
    cell => [
      [
        [{
          element => 'td 1',
          x => 0, y => 0, width => 1, height => 1,
        }],
        [{
          element => 'th 3',
          is_header => 1, scope => '',
          x => 0, y => 1, width => 1, height => 1,
        }],
      ],
      [
        [{
          element => 'td 2',
          x => 1, y => 0, width => 1, height => 1,
        }],
        [{
          element => 'th 4',
          is_header => 1, scope => '',
          x => 1, y => 1, width => 1, height => 1,
        }],
      ],
    ],
    height => 2,
    width => 2,
    element => 'table 1234',
  };
} # _form_table

sub _form_table_without_row_group : Test(1) {
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  my $table_el = $doc->create_element ('table');
  $table_el->inner_html (q[<tr><td>1<td>2<tr><th>3<th>4]);
  $table_el->append_child ($table_el->first_child->first_child)
      while $table_el->first_child->first_child;
  $table_el->remove_child ($table_el->first_child); # tbody

  my $table = Whatpm::HTML::Table->form_table ($table_el);
  eq_or_diff serialize_node $table, {
    column_group => [],
    column => [
      {
        has_data => 1,
        has_header => 1,
      },
      {
        has_data => 1,
        has_header => 1,
      },
    ],
    row_group => [],
    row => [
      {
        element => 'tr 12',
        has_data => 1,
      },
      {
        element => 'tr 34',
        has_header => 1,
      },
    ],
    cell => [
      [
        [{
          element => 'td 1',
          x => 0, y => 0, width => 1, height => 1,
        }],
        [{
          element => 'th 3',
          is_header => 1, scope => '',
          x => 0, y => 1, width => 1, height => 1,
        }],
      ],
      [
        [{
          element => 'td 2',
          x => 1, y => 0, width => 1, height => 1,
        }],
        [{
          element => 'th 4',
          is_header => 1, scope => '',
          x => 1, y => 1, width => 1, height => 1,
        }],
      ],
    ],
    height => 2,
    width => 2,
    element => 'table 1234',
  };
} # _form_table

__PACKAGE__->runtests;

1;
