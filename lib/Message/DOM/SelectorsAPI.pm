package Message::DOM::SelectorsAPI;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::DOM::Document;

use Whatpm::CSS::SelectorsParser qw(:match :combinator :selector);

sub query_selectors_all ($$;$) {
  local $Error::Depth = $Error::Depth + 1;

  my $p = Whatpm::CSS::SelectorsParser->new;
  $p->{lookup_namespace_uri} = $_[2] || sub { return undef }; ## TODO: ...
  $p->{pseudo_class}->{$_} = 1 for qw/
  /;
#    active checked disabled empty enabled first-child first-of-type
#    focus hover indeterminate last-child last-of-type link only-child
#    only-of-type root target visited
#    lang nth-child nth-last-child nth-of-type nth-last-of-type not
  $p->{pseudo_element}->{$_} = 1 for qw/
  /;
#    after before first-letter first-line
  my $selectors = $p->parse_string (''.$_[1]);
  my $r = [];

  ## TODO: invalid selectors
  return $r unless defined $selectors;

  my $is_html = ($_[0]->owner_document || $_[0])->manakai_is_html;
  
  my @node_cond = map {[$_, [@$selectors]]} @{$_[0]->child_nodes};
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
          } else {
            die "$0: $simple_selector->[0]: Unknown simple selector type";
          }
        }
        
        if ($sss_matched) {
          if (@$selector == 2) {
            push @$r, $node_cond->[0] unless $matched;
            $matched = 1;
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
        }
      }

      if (@new_cond) {
        my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
          $_->node_type == 1 or $_->node_type == 5
        } @{$node_cond->[0]->child_nodes};
        my $next_sibling_cond;
        for (reverse @children) {
          my $new_node_cond = [$_, [@new_cond], $next_sibling_cond];
          unshift @node_cond, $new_node_cond;
          $next_sibling_cond = $new_node_cond;
        }
      }
    } elsif ($node_cond->[0]->node_type == 5) { # ENTITY_REFERENCE_NODE
      my @new_cond = @{$node_cond->[1]};
      my @new_cond2 = grep {
        $_->[0] != ADJACENT_SIBLING_COMBINATOR and
        $_->[0] != GENERAL_SIBLING_COMBINATOR
      } @new_cond;
      my @children = grep { # ELEMENT_NODE or ENTITY_REFERENCE_NODE
        $_->node_type == 1 or $_->node_type == 5
      } @{$node_cond->[0]->child_nodes};
      my $next_sibling_cond;
      for (reverse @children) {
        my $new_node_cond = [$_, \@new_cond2, $next_sibling_cond];
        unshift @node_cond, $new_node_cond;
        $next_sibling_cond = $new_node_cond;
      }
      $next_sibling_cond->[1] = \@new_cond;
    }
  }
  return $r;
} # get_elements_by_selectors

package Message::DOM::Element;

package Message::DOM::DocumentSelector;
package Message::DOM::ElementSelector;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/09/23 13:32:41 $
