package Whatpm::XMLSerializer;
use strict;

sub get_outer_xml ($$;$) {
  my $r = '';
  my @src = ($_[1]);
  my $onerror = $_[2] || sub { };
  my $nsbind = [{'' => '', xml => q<http://www.w3.org/XML/1998/namespace>,
                 xmlns => q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef>}];
  my $xescape = sub ($) {
    my $s = shift;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
  };
  while (defined (my $src = shift @src)) {
    if (ref $src eq 'ARRAY') {
      pop @$nsbind;  ## End tag
    } elsif (ref $src) {
      my $srcnt = $src->node_type;
      if ($srcnt == 1) { # ELEMENT_NODE
        my @csrc;
        my $etag;
        push @$nsbind, my $ns = {%{$nsbind->[-1]}};
        my %attrr;

        my @attrs = @{$src->attributes};
        my @nsattrs;
        my @gattrs;
        my @lattrs;

        for my $attr (@attrs) {
          my $nsuri = $attr->namespace_uri;
          if (not defined $nsuri) {
            push @lattrs, $attr;
          } elsif ($nsuri eq q<http://www.w3.org/2000/xmlns/>) {
            push @nsattrs, $attr;
          } else {
            push @gattrs, $attr;
          }
        }

        ## Implied namespace prefixes
        my $etns = $src->namespace_uri;
        my $etpfx = $src->prefix;
        if (defined $etns and defined $etpfx and
            not (defined $ns->{$etpfx} and $ns->{$etpfx} eq $etns)) {
          $ns->{$etpfx} = $etns;
          $attrr{'xmlns:'.$etpfx} = [$xescape->($etns)];
        }

        for my $attr (@gattrs) {
          my $atns = $attr->namespace_uri;
          my $atpfx = $attr->prefix;
          if (defined $atpfx and
              not (defined $ns->{$atpfx} and $ns->{$atpfx} eq $atns)) {
            $ns->{$atpfx} = $atns;
            $attrr{'xmlns:'.$atpfx} = [$xescape->($atns)];
          }
        }

        ## Namespace attributes
        XA: for my $attr (@nsattrs) {
          my $attrval = $attr->value;
          my $lname = $attr->local_name;
          if ($lname eq 'xmlns') {
            $ns->{''} = $attrval;
            $attrr{xmlns} = [@{$attr->child_nodes}];
          } else {
            if (length $attrval) {
              $ns->{$lname} = $attrval;
            } else {
              $ns->{$lname} = q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef>;
            }
            $attrr{'xmlns:'.$lname} = [@{$attr->child_nodes}];
          }
        } # XA

        ## Per-element partition attributes
        for my $attr (@lattrs) {
          $attrr{$attr->local_name} = [@{$attr->child_nodes}];
        }

        ## Global partition attributes
        my $dns = $ns->{''};
        delete $ns->{''};
        my $nsrev = {reverse %$ns};
        $ns->{''} = $dns;
        delete $nsrev->{q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef>}; # for security reason
        for my $attr (@gattrs) {
          my $atns = $attr->namespace_uri;
          my $atpfx = $attr->prefix;
          if (not defined $atpfx or
              $ns->{$atpfx} ne $atns) {
            if (defined $nsrev->{$atns}) {
              $atpfx = $nsrev->{$atns};
            } else {
              ## Prefix is not registered
              my @uritxt = grep {/\A[A-Za-z][A-Za-z0-9_.-]*\z/}
                           split /\W+/, $atns;
              P: {
                for my $pfx (reverse @uritxt) {
                  if (not defined $ns->{$pfx}) {
                    $atpfx = $pfx;
                    $ns->{$pfx} = $atns;
                    $nsrev->{$atns} = $atpfx;
                    $attrr{'xmlns:'.$atpfx} = [$xescape->($atns)];
                    last P;
                  }
                }

                my $i = 1;
                $i++ while exists $ns->{'ns'.$i};
                $atpfx = 'ns'.$i;
                $ns->{$atpfx} = $atns;
                $nsrev->{$atns} = $atpfx;
                $attrr{'xmlns:ns'.$i} = [$xescape->($atns)];
              } # P
            }
          }

          $attrr{$atpfx.':'.$attr->local_name} = [@{$attr->child_nodes}];
        }

        ## Element type name
        if (defined $etns) {
          if (not defined $etpfx or
              (defined $ns->{$etpfx} and $ns->{$etpfx} ne $etns)) {
            if ($ns->{''} eq $etns) {
              $etpfx = undef;
            } else {
              $etpfx = $nsrev->{$etns};
              unless (defined $etpfx) {
                ## Prefix is not registered
                my @uritxt = grep {/\A[A-Za-z][A-Za-z0-9_.-]*\z/}
                             split /\W+/, $etns;
                P: {
                  for my $pfx (reverse @uritxt) {
                    if (not defined $ns->{$pfx}) {
                      $etpfx = $pfx;
                      $ns->{$pfx} = $etns;
                      $nsrev->{$etns} = $etpfx;
                      $attrr{'xmlns:'.$etpfx} = [$xescape->($etns)];
                      last P;
                    }
                  }
  
                  my $i = 1;
                  $i++ while exists $ns->{'ns'.$i};
                  $etpfx = 'ns'.$i;
                  $ns->{$etpfx} = $etns;
                  $nsrev->{$etns} = $etpfx;
                  $attrr{'xmlns:ns'.$i} = [$xescape->($etns)];
                } # P
              }
            }
          }
        } else {
          if ($ns->{''} ne '') {
            $ns->{''} = '';
            $attrr{xmlns} = [''];
          }
        }

        $r .= '<';
        $etag = '</';
        if (defined $etpfx and defined $etns) {
          $r .= $etpfx . ':';
          $etag .= $etpfx . ':';
        }
        my $etln = $src->local_name;
        $r .= $etln;
        $etag .= $etln . '>';
              
        ## Attribute specifications
        for my $an (sort keys %attrr) {
          push @csrc, ' ' . $an . '="', @{$attrr{$an}}, '"';
        }

        ## Children
        push @csrc, '>', @{$src->child_nodes}, $etag, [];
        unshift @src, @csrc;
      } elsif ($srcnt == 3) { # TEXT_NODE
        $r .= $xescape->($src->node_value);
      } elsif ($srcnt == 4) { # CDATA_SECTION_NODE
        my $text = $src->node_value;
        $text =~ s/]]>/]]]]>&gt;<![CDATA[/g;
        $r .= '<![CDATA[' . $text . ']]>';
      } elsif ($srcnt == 5) { # ENTITY_REFERENCE_NODE
        if ($src->manakai_expanded) {
          push @src, @{$src->child_nodes};
        } else {
          $r .= '&' . $src->node_name . ';';
        }
      } elsif ($srcnt == 7) { # PROCESSING_INSTRUCTION_NODE
        $r .= '<?' . $src->node_name;
        my $data = $src->node_value;
        if (length $data) {
          $data =~ s/\?>/?&gt;/g;
          $r .= ' ' . $data;
        }
        $r .= '?>';
      } elsif ($srcnt == 8) { # COMMENT_NODE
        my $data = $src->node_value;
        $data =~ s/--/- - /g;
        $r .= '<!--' . $data . '-->';
      } elsif ($srcnt == 9) { # DOCUMENT_NODE
        unshift @src, map {$_, "\x0A"} @{$src->child_nodes};
        ## ISSUE: |cfg:strict-document-children| cparam
      }
      # document type, entity, notation, etdef, atdef, df
    } else {
      $r .= $src;
    }
  }

  return \$r;
} # get_outer_xml

1;
## $Date: 2007/07/15 06:15:04 $
