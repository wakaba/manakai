package Whatpm::HTML::Dumper;
use strict;
use warnings;
our $VERSION = '1.8';
use Exporter::Lite;

our @EXPORT = qw(dumptree);

our $NamespaceMapping;
$NamespaceMapping->{q<http://www.w3.org/1999/xhtml>} = 'html';
$NamespaceMapping->{q<http://www.w3.org/2000/svg>} = 'svg';
$NamespaceMapping->{q<http://www.w3.org/1998/Math/MathML>} = 'math';
$NamespaceMapping->{q<http://www.w3.org/1999/xlink>} = 'xlink';
$NamespaceMapping->{q<http://www.w3.org/XML/1998/namespace>} = 'xml';
$NamespaceMapping->{q<http://www.w3.org/2000/xmlns/>} = 'xmlns';

sub dumptree ($) {
  my $node = shift;
  my $r = '';

  my @node = map { [$_, ''] } @{$node->child_nodes};
  while (@node) {
    my $child = shift @node;
    my $nt = $child->[0]->node_type;
    if ($nt == $child->[0]->ELEMENT_NODE) {
      my $ns = $child->[0]->namespace_uri;
      unless (defined $ns) {
        $ns = '{} ';
      } elsif ($ns eq q<http://www.w3.org/1999/xhtml>) {
        $ns = '';
      } elsif (defined $NamespaceMapping->{$ns}) {
        $ns = $NamespaceMapping->{$ns} . ' ';
      } else {
        $ns = '{' . $ns . '} ';
      }
      $r .= $child->[1] . '<' . $ns . $child->[0]->manakai_local_name . ">\x0A";

      for my $attr (sort {$a->[0] cmp $b->[0]} map { [do {
                      my $ns = $_->namespace_uri;
                      unless (defined $ns) {
                        $ns = '';
                      } elsif (defined $NamespaceMapping->{$ns}) {
                        $ns = $NamespaceMapping->{$ns} . ' ';
                      } else {
                        $ns = '{' . $ns . '} ';
                      }
                      $ns . $_->manakai_local_name;
                    }, $_->value] }
                    @{$child->[0]->attributes}) {
        $r .= $child->[1] . '  ' . $attr->[0] . '="';
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
      if ((defined $pubid and length $pubid) or
          (defined $sysid and length $sysid)) {
        $r .= ' "' . (defined $pubid ? $pubid : '') . '"';
        $r .= ' "' . (defined $sysid ? $sysid : '') . '"';
      }
      $r .= ">\x0A";
      unshift @node,
          map { [$_, $child->[1] . '  '] }
          sort { $a->node_name cmp $b->node_name }
          values %{$child->[0]->element_types};
      unshift @node,
          map { [$_, $child->[1] . '  '] }
          sort { $a->node_name cmp $b->node_name }
          values %{$child->[0]->entities};
      unshift @node,
          map { [$_, $child->[1] . '  '] }
          sort { $a->node_name cmp $b->node_name }
          values %{$child->[0]->notations};
      unshift @node,
          map { [$_, $child->[1] . '  '] } @{$child->[0]->child_nodes};
    } elsif ($nt == $child->[0]->PROCESSING_INSTRUCTION_NODE) {
      $r .= $child->[1] . '<?' . $child->[0]->target . ' ';
      $r .= $child->[0]->data . "?>\x0A";
    } elsif ($nt == $child->[0]->ENTITY_NODE) {
      $r .= $child->[1] . '<!ENTITY ' . $child->[0]->node_name . ' "';
      $r .= $child->[0]->text_content;
      $r .= '" "';
      $r .= $child->[0]->public_id if defined $child->[0]->public_id;
      $r .= '" "';
      $r .= $child->[0]->system_id if defined $child->[0]->system_id;
      $r .= '" ';
      $r .= $child->[0]->notation_name if defined $child->[0]->notation_name;
      $r .= ">\x0A";
      unshift @node,
          map { [$_, $child->[1] . '  '] } @{$child->[0]->child_nodes};
    } elsif ($nt == $child->[0]->NOTATION_NODE) {
      $r .= $child->[1] . '<!NOTATION ' . $child->[0]->node_name . ' "';
      $r .= $child->[0]->public_id if defined $child->[0]->public_id;
      $r .= '" "';
      $r .= $child->[0]->system_id if defined $child->[0]->system_id;
      $r .= qq[">\x0A];
    } elsif ($nt == $child->[0]->ELEMENT_TYPE_DEFINITION_NODE) {
      $r .= $child->[1] . '<!ELEMENT ' . $child->[0]->node_name . ' ';
      $r .= $child->[0]->content_model_text;
      $r .= ">\x0A";
      unshift @node,
          map { [$_, $child->[1] . '  '] }
          sort { $a->node_name cmp $b->node_name }
          values %{$child->[0]->attribute_definitions};
    } elsif ($nt == $child->[0]->ATTRIBUTE_DEFINITION_NODE) {
      $r .= $child->[1] . $child->[0]->node_name . ' ';
      $r .= [
        0, 'CDATA', 'ID', 'IDREF', 'IDREFS', 'ENTITY', 'ENTITIES',
        'NMTOKEN', 'NMTOKENS', 'NOTATION', 'ENUMERATION', 11,
      ]->[$child->[0]->declared_type] || $child->[0]->declared_type;
      $r .= ' (' . join ('|', @{$child->[0]->allowed_tokens}) . ') ';
      $r .= [
        0, 'FIXED', 'REQUIRED', 'IMPLIED', 'EXPLICIT',
      ]->[$child->[0]->default_type] || $child->[0]->default_type;
      $r .= ' "' . $child->[0]->text_content . '"';
      $r .= "\x0A";
    } else {
      $r .= $child->[1] . $child->[0]->node_type . "\x0A"; # error
    }
  }
  
  return $r;
} # dumptree

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
