package Message::DOM::SelectorsAPI;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::DOM::DOMException;

package Message::DOM::Document;

use Whatpm::CSS::SelectorsParser qw(:match :combinator :selector);

my $get_elements_by_selectors = sub {
  # $node, $selectors, $resolver, $node_conds, $is_html, $all

  my $p = Whatpm::CSS::SelectorsParser->new;

  my $ns_error;
  my $resolver = $_[2] || sub { return undef };
  if (UNIVERSAL::can ($_[2], 'lookup_namespace_uri')) {
    my $re = $resolver;
    $resolver = sub {
      local $Error::Depth = $Error::Depth + 1;
      return $re->lookup_namespace_uri ($_[0]);
    };
  }
  $p->{lookup_namespace_uri} = sub {
    local $Error::Depth = $Error::Depth + 2;
    ## NOTE: MAY assume that $resolver returns consistent results.
    ## NOTE: MUST be case-sensitive.
    if (defined $_[0] and $_[0] ne '') {
      my $uri = $resolver->($_[0]);
      if (defined $uri) {
        $uri = ''.$uri;
        if ($uri eq '') {
          $ns_error = $_[0];
          return undef;
        } else {
          return $uri;
        }
      } else {
        $ns_error = $_[0];
        return undef;
      }
    } else {
      my $uri = $resolver->(undef);
      if (defined $uri) {
        $uri = ''.$uri;
        if ($uri eq '') {
          return undef;
        } else {
          return $uri;
        }
      } else {
        return undef;
      }
    }
  };

  ## NOTE: SHOULD ensure to remain stable when facing a hostile $_[2].

  $p->{pseudo_class}->{$_} = 1 for qw/
  /;
#    active checked disabled empty enabled first-child first-of-type
#    focus hover indeterminate last-child last-of-type link only-child
#    only-of-type root target visited
#    lang nth-child nth-last-child nth-of-type nth-last-of-type not

  ## NOTE: MAY treat all links as :link rather than :visited

  $p->{pseudo_element}->{$_} = 1 for qw/
    after before first-letter first-line
  /;

  my $selectors = $p->parse_string (''.$_[1]);
  unless (defined $selectors) {
    local $Error::Depth = $Error::Depth - 1;
    # MUST
    if (defined $ns_error) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NAMESPACE_ERR',
          -subtype => 'UNDECLARED_PREFIX_ERR',
          namespace_prefix => $ns_error;
    } else {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'SYNTAX_ERR',
          -subtype => 'INVALID_SELECTORS_ERR';
    }
  }

  my $is_html = $_[4];
  my $r;
  if ($_[5]) {
    # MUST
    require Message::DOM::NodeList;
    $r = bless [], 'Message::DOM::NodeList::StaticNodeList';
  }
  
  my @node_cond = map {$_->[1] = [@$selectors]; $_} @{$_[3]};
  while (@node_cond) {
    my $node_cond = shift @node_cond;
    if ($node_cond->[0]->node_type == 1) { # ELEMENT_NODE
      my @new_cond;
      my $matched;
      for my $selector (@{$node_cond->[1]}) {
        my $sss_matched = 1;
        for my $simple_selector (@{$selector->[1]}) {
          if ($simple_selector->[0] == LOCAL_NAME_SELECTOR) {
            if ($simple_selector->[1] eq
                $node_cond->[0]->manakai_local_name) {
              #
            } elsif ($is_html) {
              my $nsuri = $node_cond->[0]->namespace_uri;
              if (defined $nsuri and
                  $nsuri eq q<http://www.w3.org/1999/xhtml>) {
                if (lc $simple_selector->[1] eq
                    $node_cond->[0]->manakai_local_name) {
                  ## TODO: What kind of case-insensitivility?
                  ## TODO: Is this checking method OK?
                  #
                } else {
                  $sss_matched = 0;
                }
              } else {
                $sss_matched = 0;
              }
            } else {
              $sss_matched = 0;
            }
          } elsif ($simple_selector->[0] == NAMESPACE_SELECTOR) {
            my $nsuri = $node_cond->[0]->namespace_uri;
            if (defined $simple_selector->[1]) {
              if (defined $nsuri and $nsuri eq $simple_selector->[1]) {
                #
              } else {
                $sss_matched = 0;
              }
            } else {
              if (defined $nsuri) {
                $sss_matched = 0;
              }
            }
          } elsif ($simple_selector->[0] == ATTRIBUTE_SELECTOR) {
            my @attr_node;
            ## Namespace URI
            if (not defined $simple_selector->[1]) {
              my $ln = $simple_selector->[2];
              if ($is_html) {
                my $nsuri = $node_cond->[0]->namespace_uri;
                if (defined $nsuri and
                    $nsuri eq q<http://www.w3.org/1999/xhtml>) {
                  $ln =~ tr/A-Z/a-z/; ## ISSUE: Case-insensitivity
                }
              }

              ## Any Namespace, Local Name
              M: {
                for my $attr_node (@{$node_cond->[0]->attributes}) {
                  my $node_ln = $attr_node->manakai_local_name;
                  if ($node_ln eq $simple_selector->[2]) {
                    push @attr_node, $attr_node;
                    last M if $simple_selector->[3] == EXISTS_MATCH;
                  } elsif (not defined $attr_node->namespace_uri and
                           $node_ln eq $ln) {
                    push @attr_node, $attr_node;
                    last M if $simple_selector->[3] == EXISTS_MATCH;
                  }
                }
                last M if @attr_node;
                $sss_matched = 0;
              } # M
            } elsif ($simple_selector->[1] eq '') {
              my $ln = $simple_selector->[2];
              if ($is_html) {
                my $nsuri = $node_cond->[0]->namespace_uri;
                if (defined $nsuri and
                    $nsuri eq q<http://www.w3.org/1999/xhtml>) {
                  $ln =~ tr/A-Z/a-z/; ## ISSUE: Case-insensitivity
                }
              }

              ## ISSUE: Does <p>.setAttributeNS (undef, 'Align')'ed <p>
              ## match with [align]?

              ## Null Namespace, Local Name
              my $attr_node = $node_cond->[0]->get_attribute_node_ns
                  (undef, $ln);
              if ($attr_node) {
                push @attr_node, $attr_node;
              } else {
                $sss_matched = 0;
              }
            } else {
              ## Non-null Namespace, Local Name
              my $attr_node = $node_cond->[0]->get_attribute_node_ns
                      ($simple_selector->[1], $simple_selector->[2]);
              if ($attr_node) {
                push @attr_node, $attr_node;
              } else {
                $sss_matched = 0;
              }
            }

            if ($sss_matched) {
              if ($simple_selector->[3] == EXISTS_MATCH) {
                #
              } else {
                for my $attr_node (@attr_node) {
                  ## TODO: Attribute value case-insensitivility
                  my $value = $attr_node->value;
                  if ($simple_selector->[3] == EQUALS_MATCH) {
                    if ($value eq $simple_selector->[4]) {
                      #
                    } else {
                      $sss_matched = 0;
                    }
                  } elsif ($simple_selector->[3] == DASH_MATCH) {
                    ## ISSUE: [a|=""] a="a--b" a="-" ?
                    if ($value eq $simple_selector->[4]) {
                      #
                    } elsif (substr ($value, 0,
                                     1 + length $simple_selector->[4]) eq
                             $simple_selector->[4] . '-') {
                      #
                    } else {
                      $sss_matched = 0;
                    }
                  } elsif ($simple_selector->[3] == INCLUDES_MATCH) {
                    ## ISSUE: [a~=""] [a~=" "] [a~="b c"] [a~=" b"] [a~="b "] ?
                    M: {
                      for (split /[\x09\x0A\x0C\x0D\x20]+/, $value, -1) {
                        if ($_ eq $simple_selector->[4]) {
                          last M;
                        }
                      }
                      $sss_matched = 0;
                    } # M
                  } elsif ($simple_selector->[3] == PREFIX_MATCH) {
                    if (substr ($value, 0, length $simple_selector->[4]) eq
                        $simple_selector->[4]) {
                      #
                    } else {
                      $sss_matched = 0;
                    }
                  } elsif ($simple_selector->[3] == SUFFIX_MATCH) {
                    if (substr ($value, -length $simple_selector->[4]) eq
                        $simple_selector->[4]) {
                      #
                    } else {
                      $sss_matched = 0;
                    }
                  } elsif ($simple_selector->[3] == SUBSTRING_MATCH) {
                    if (index ($value, $simple_selector->[4]) > -1) {
                      #
                    } else {
                      $sss_matched = 0;
                    }
                  } else {
                    ## NOTE: New match type.
                    report Message::DOM::DOMException
                        -object => $_[0],
                        -type => 'SYNTAX_ERR',
                        -subtype => 'INVALID_SELECTORS_ERR';
                  }
                }
              }
            }
          } elsif ($simple_selector->[0] == PSEUDO_ELEMENT_SELECTOR) {
            $sss_matched = 0;
          } else {
            ## NOTE: New simple selector type.
            report Message::DOM::DOMException
                -object => $_[0],
                -type => 'SYNTAX_ERR',
                -subtype => 'INVALID_SELECTORS_ERR';
          }
        }
        
        if ($sss_matched) {
          if (@$selector == 2) {
            unless ($node_cond->[3]) {
              return $node_cond->[0] unless defined $r;
              push @$r, $node_cond->[0] unless $matched;
              $matched = 1;
            }
          } else {
            my $new_selector = [@$selector[2..$#$selector]];
            if ($new_selector->[0] == DESCENDANT_COMBINATOR or
                $new_selector->[0] == CHILD_COMBINATOR) {
              push @new_cond, $new_selector;
            } else { # ADJACENT_SIBLING_COMBINATOR | GENERAL_SIBLING_COMBINATOR
              push @{$node_cond->[2]->[1] || []}, $new_selector;
            }
          }
        }
        if ($selector->[0] == DESCENDANT_COMBINATOR) {
          push @new_cond, $selector;
        } elsif ($selector->[0] == GENERAL_SIBLING_COMBINATOR) {
          push @{$node_cond->[2]->[1] || []}, $selector;
        } elsif ($selector->[0] == CHILD_COMBINATOR or
                 $selector->[0] == ADJACENT_SIBLING_COMBINATOR) {
          #
        } else {
          ## NOTE: New combinator.
          report Message::DOM::DOMException
              -object => $_[0],
              -type => 'SYNTAX_ERR',
              -subtype => 'INVALID_SELECTORS_ERR';
        }
      }

      if (@new_cond) {
        unless ($node_cond->[3]) {
          my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
            $_->node_type == 1 or $_->node_type == 5
          } @{$node_cond->[0]->child_nodes};
          my $next_sibling_cond;
          for (reverse @children) {
            my $new_node_cond = [$_, [@new_cond], $next_sibling_cond];
            unshift @node_cond, $new_node_cond;
            $next_sibling_cond = $new_node_cond;
          }
        } else {
          for (@{$node_cond->[4]}) {
            $_->[1] = [@new_cond];
          }
          $node_cond->[4]->[0]->[1] = \@new_cond if @{$node_cond->[4]};
        }
      }
    } elsif ($node_cond->[0]->node_type == 5) { # ENTITY_REFERENCE_NODE
      my @new_cond = @{$node_cond->[1]};
      my @new_cond2 = grep {
        $_->[0] != ADJACENT_SIBLING_COMBINATOR and
        $_->[0] != GENERAL_SIBLING_COMBINATOR
      } @new_cond;
      unless ($node_cond->[3]) {
        my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
          $_->node_type == 1 or $_->node_type == 5
        } @{$node_cond->[0]->child_nodes};
        my $next_sibling_cond;
        for (reverse @children) {
          my $new_node_cond = [$_, [@new_cond2], $next_sibling_cond];
          unshift @node_cond, $new_node_cond;
          $next_sibling_cond = $new_node_cond;
        }
        $next_sibling_cond->[1] = \@new_cond;
      } else {
        for (@{$node_cond->[4]}) {
          $_->[1] = [@new_cond2];
        }
        $node_cond->[4]->[0]->[1] = \@new_cond if @{$node_cond->[4]};
      }
    }
  }
  return $r;
}; # $get_elements_by_selectors

sub query_selector ($$;$) {
  local $Error::Depth = $Error::Depth + 1;

  ## Children of the Element.
  my @node_cond;
  my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
    $_->node_type == 1 or $_->node_type == 5
  } @{$_[0]->child_nodes};
  my $next_sibling_cond;
  for (reverse @children) {
    my $new_node_cond = [$_, undef, $next_sibling_cond];
    unshift @node_cond, $new_node_cond;
    $next_sibling_cond = $new_node_cond;
  }

  return $get_elements_by_selectors
      ->($_[0], $_[1], $_[2], \@node_cond,
         $_[0]->manakai_is_html, 0);
} # query_selector

sub query_selector_all ($$;$) {
  local $Error::Depth = $Error::Depth + 1;

  ## Children of the Element.
  my @node_cond;
  my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
    $_->node_type == 1 or $_->node_type == 5
  } @{$_[0]->child_nodes};
  my $next_sibling_cond;
  for (reverse @children) {
    my $new_node_cond = [$_, undef, $next_sibling_cond];
    unshift @node_cond, $new_node_cond;
    $next_sibling_cond = $new_node_cond;
  }

  return $get_elements_by_selectors
      ->($_[0], $_[1], $_[2], \@node_cond,
         $_[0]->manakai_is_html, 1);
} # query_selector_all

package Message::DOM::Element;

my $get_node_cond = sub {
  my @node_cond;
  my $child_conds = [];

  ## Children of the Element.
  my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
    $_->node_type == 1 or $_->node_type == 5
  } @{$_[0]->child_nodes};
  my $next_sibling_cond;
  for (reverse @children) {
    my $new_node_cond = [$_, undef, $next_sibling_cond];
    unshift @node_cond, $new_node_cond;
    $next_sibling_cond = $new_node_cond;
  }
  @$child_conds = @node_cond;

  ## Ancestors and previous siblings of ancestors
  my $node = $_[0];
  my $parent = $node->parent_node;
  while (defined $parent) {
    my $conds = [];
    for (grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
      $_->node_type == 1 or $_->node_type == 5
    } @{$parent->child_nodes}) {
      push @$conds, my $cond = [$_, undef, undef, 1, $child_conds];
      if ($_ eq $node) {
        $child_conds = $conds;
        ($node, $parent) = ($parent, $parent->parent_node);
        last;
      }
    }
    my $nsib_cond;
    for (reverse @$child_conds) {
      $_->[2] = $nsib_cond;
      $nsib_cond = $_;
    }
    unshift @node_cond, @$conds;
  }
  if ($node->node_type == 1) { # ELEMENT_NODE
    unshift @node_cond, [$node, undef, undef, 1, $child_conds];
  }

  return \@node_cond;
}; # $get_node_cond

sub query_selector ($$;$) {
  local $Error::Depth = $Error::Depth + 1;

  return $get_elements_by_selectors
      ->($_[0], $_[1], $_[2], $get_node_cond->($_[0]),
         $_[0]->owner_document->manakai_is_html, 0);
} # query_selector

sub query_selector_all ($$;$) {
  local $Error::Depth = $Error::Depth + 1;

  return $get_elements_by_selectors
      ->($_[0], $_[1], $_[2], $get_node_cond->($_[0]),
         $_[0]->owner_document->manakai_is_html, 1);
} # query_selector_all

=head1 SEE ALSO

Selectors API Editor's Draft 29 August 2007
<http://dev.w3.org/cvsweb/~checkout~/2006/webapi/selectors-api/Overview.html?rev=1.28&content-type=text/html;%20charset=utf-8>

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/09/29 14:03:04 $
