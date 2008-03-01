package Whatpm::HTML::Serializer;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub get_inner_html ($$$) {
  my (undef, $node, $on_error) = @_;

  ## Step 1
  my $s = '';

  my $in_cdata;
  my $parent = $node;
  while (defined $parent) {
    if ($parent->node_type == 1 and
        $parent->namespace_uri eq 'http://www.w3.org/1999/xhtml' and
        {
          style => 1, script => 1, xmp => 1, iframe => 1,
          noembed => 1, noframes => 1, noscript => 1,
        }->{$parent->local_name}) { ## TODO: case thingy
      $in_cdata = 1;
    }
    $parent = $parent->parent_node;
  }

  ## Step 2
  my @node = @{$node->child_nodes};
  C: while (@node) {
    my $child = shift @node;
    unless (ref $child) {
      if ($child eq 'cdata-out') {
        $in_cdata = 0;
      } else {
        $s .= $child; # end tag
      }
      next C;
    }
    
    my $nt = $child->node_type;
    if ($nt == 1) { # Element
      my $tag_name = $child->tag_name; ## TODO: manakai_tag_name
      $s .= '<' . $tag_name;
      ## NOTE: Non-HTML case: 
      ## <http://permalink.gmane.org/gmane.org.w3c.whatwg.discuss/11191>

      my @attrs = @{$child->attributes}; # sort order MUST be stable
      for my $attr (@attrs) { # order is implementation dependent
        my $attr_name = $attr->name; ## TODO: manakai_name
        $s .= ' ' . $attr_name . '="';
        my $attr_value = $attr->value;
        ## escape
        $attr_value =~ s/&/&amp;/g;
        $attr_value =~ s/</&lt;/g;
        $attr_value =~ s/>/&gt;/g;
        $attr_value =~ s/"/&quot;/g;
        $attr_value =~ s/\xA0/&nbsp;/g;
        $s .= $attr_value . '"';
      }
      $s .= '>';
      
      next C if {
        area => 1, base => 1, basefont => 1, bgsound => 1,
        br => 1, col => 1, embed => 1, frame => 1, hr => 1,
        img => 1, input => 1, link => 1, meta => 1, param => 1,
        spacer => 1, wbr => 1,
      }->{$tag_name};

      $s .= "\x0A" if $tag_name eq 'pre' or $tag_name eq 'textarea';

      if (not $in_cdata and {
        style => 1, script => 1, xmp => 1, iframe => 1,
        noembed => 1, noframes => 1, noscript => 1,
        plaintext => 1,
      }->{$tag_name}) {
        unshift @node, 'cdata-out';
        $in_cdata = 1;
      }

      unshift @node, @{$child->child_nodes}, '</' . $tag_name . '>';
    } elsif ($nt == 3 or $nt == 4) {
      if ($in_cdata) {
        $s .= $child->data;
      } else {
        my $value = $child->data;
        $value =~ s/&/&amp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
        $value =~ s/"/&quot;/g;
        $value =~ s/\xA0/&nbsp;/g;
        $s .= $value;
      }
    } elsif ($nt == 8) {
      $s .= '<!--' . $child->data . '-->';
    } elsif ($nt == 10) {
      $s .= '<!DOCTYPE ' . $child->name . '>';
    } elsif ($nt == 5) { # entrefs
      push @node, @{$child->child_nodes};
    } elsif ($nt == 7) { # PIs
      $s .= '<?' . $child->target . ' ' . $target->data . '>';
    } else {
      $on_error->($child) if defined $on_error;
    }
  } # C
  
  ## Step 3
  return \$s;
} # get_inner_html

=head1 LICENSE

Copyright 2007-2008 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2008/03/01 00:42:53 $
