package Whatpm::HTML::Serializer;
use strict;
use warnings;
our $VERSION = '1.7';

sub get_inner_html ($$$) {
  my (undef, $node, $onerror) = @_;

  ## Step 1
  my $s = '';

  my $in_cdata = sub ($) {
    my $node = $_[0];

    my $ns = $node->namespace_uri;
    return 0 if not defined $ns; # in no namespace, or not an Element
    return 0 unless $ns eq q<http://www.w3.org/1999/xhtml>;

    my $ln = $node->manakai_local_name;
    return 1 if {
        style => 1,
        script => 1,
        xmp => 1,
        iframe => 1,
        noembed => 1,
        noframes => 1,
        plaintext => 1,
    }->{$ln};
    return $Whatpm::ScriptingEnabled if $ln eq 'noscript';

    return 0;
  }; # $in_cdata

  ## Step 2
  my $node_in_cdata = $in_cdata->($node);
  my @node = map { [$_, $node_in_cdata] } @{$node->child_nodes};
  C: while (@node) {
    ## Step 2.1
    my $c = shift @node;
    my $child = $c->[0];

    ## End tag
    if (not ref $child) {
      $s .= $child;
      next;
    }

    ## Step 2.2
    my $nt = $child->node_type;
    if ($nt == 1) { # Element
      my $tag_name = $child->manakai_tag_name; # In the original (lower) case.
      $s .= '<' . $tag_name;
      ## NOTE: The tag name might contain namespace prefix.  See
      ## <http://permalink.gmane.org/gmane.org.w3c.whatwg.discuss/11191>.

      my @attrs = @{$child->attributes}; # sort order MUST be stable
      for my $attr (@attrs) { # order is implementation dependent
        my $attr_name = $attr->manakai_name;
        $s .= ' ' . $attr_name . '="';
        my $attr_value = $attr->value;
        ## escape
        $attr_value =~ s/&/&amp;/g;
        $attr_value =~ s/\xA0/&nbsp;/g;
        $attr_value =~ s/"/&quot;/g;
        #$attr_value =~ s/</&lt;/g;
        #$attr_value =~ s/>/&gt;/g;
        $s .= $attr_value . '"';
      }
      $s .= '>';
      
      next C if {
        area => 1, base => 1, basefont => 1, bgsound => 1,
        br => 1, col => 1, embed => 1, frame => 1, hr => 1,
        img => 1, input => 1, link => 1, meta => 1, param => 1,
        wbr => 1, keygen => 1,
      }->{$tag_name};

      $s .= "\x0A" if {pre => 1, textarea => 1, listing => 1}->{$tag_name};

      my $child_in_cdata = $in_cdata->($child);
      unshift @node,
          (map { [$_, $child_in_cdata] } @{$child->child_nodes}),
          (['</' . $tag_name . '>', 0]);
    } elsif ($nt == 3 or $nt == 4) { # Text or CDATASection
      if ($c->[1]) { # in CDATA or RCDATA or PLAINTEXT element
        $s .= $child->data;
      } else {
        my $value = $child->data;
        $value =~ s/&/&amp;/g;
        $value =~ s/\xA0/&nbsp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
        #$value =~ s/"/&quot;/g;
        $s .= $value;
      }
    } elsif ($nt == 8) { # Comment
      $s .= '<!--' . $child->data . '-->';
    } elsif ($nt == 10) { # DocumentType
      $s .= '<!DOCTYPE ' . $child->name . '>';
    } elsif ($nt == 7) { # ProcessingInstruction
      $s .= '<?' . $child->target . ' ' . $child->data . '>';
    } elsif ($nt == 5) { # EntityReference
      push @node, map { [$_, $c->[1]] } @{$child->child_nodes};
    } else {
      # INVALID_STATE_ERROR
      $onerror->($child) if defined $onerror;
    }
  } # C
  
  ## Step 3
  return \$s;
} # get_inner_html

=head1 LICENSE

Copyright 2007-2009 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2009/09/06 01:21:44 $
