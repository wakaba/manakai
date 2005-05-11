#!/usr/bin/perl -w

=head1 NAME

dis.pl - The "dis" format interpreting utility

=head1 DESCRIPTION

This Perl library provides a lot of functions that 
is used to interprete the "dis" format source files. 

This library is part of manakai. 

=cut

use strict;
use Message::Util::QName::Filter {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DISLang => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#>,
  DISPerl => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#>,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMEvents => q<http://suika.fam.cx/~wakaba/archive/2004/dom/events#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  infoset => q<http://www.w3.org/2001/04/infoset#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  MDOM_EXCEPTION => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
  xml => q<http://www.w3.org/XML/1998/namespace>,
  xmlns => q<http://www.w3.org/2000/xmlns/>,
  xsd => q<http://www.w3.org/2001/XMLSchema#>,
};
require Message::Markup::SuikaWikiConfig20::Parser;

our $State ||= {
  ## DefaultFor
  ## For         For definition
  ## def_required
  ## Module      Module definitions
  ## module      Namespace URI of the primary module
  ## Namespace   Namespace bindings
  ## Type        Type definitions
};

## For error reporting
our $NodePathKey = [qw/Name QName Label rdf:type Type/,
                    ExpandedURI q<d:QName>];

=head1 FUNCTIONS

This library provides a number of functions in the C<main> namespace 
with the C<dis_> prefix:

=over 4

=item $uri = dis_nsprefix_to_uri ($prefix, %opt)

Expand the C<$prefix> into a URI reference.  If the 
C<$prefix> is an C<undef> value, it means the default namespace;
if C<$opt{use_default_namespace}> is 
C<1>, the C<#default> namespace URI, if any, is used; if
C<$opt{use_default_namespace> is any defined value other than C<1>, 
it is used as a namespace URI; otherwise, the empty string 
is returned.

=cut

sub dis_nsprefix_to_uri ($;%) {
  my ($prefix, %opt) = @_;
  if (defined $prefix) {
    if ($State->{Namespace}->{$prefix}) {
      return $State->{Namespace}->{$prefix}->{uri};
    } else {
      for (keys %{$State->{Module}}) {
        my $uri = $State->{Module}->{$_}->{Namespace};
        if (defined $uri and $State->{Module}->{$_}->{Name} eq $prefix) {
          return $uri;
        }
      }
      valid_err (qq'Namespace prefix "$prefix" not defined',
                 node => $opt{node});
    }
  } else {
    if (defined $opt{use_default_namespace}) {
      if ($opt{use_default_namespace} eq '1') {
        if ($State->{Namespace}->{'#default'}) {
          return $State->{Namespace}->{'#default'}->{uri};
        } else {
          if (defined $State->{module}) {
            return $State->{Module}->{$State->{module}}->{Namespace};
          }
          valid_err (qq'Namespace prefix "#default" not defined',
                     node => $opt{node});
        }
      } else {
        return $opt{use_default_namespace};
      }
    } else {
      return '';
    }
  }  
}

=item $uri = dis_qname_to_uri ($qname, %opt)

Expand the C<$qname> into a prefix and a local name and 
concatate them as a string.  If the C<$qname> does not contains any 
C<COLON>, i.e. it belongs to the default namespace, 
the interpretation may be vary; see the description for 
C<dis_nsprefix_to_uri>.

=cut

sub dis_qname_to_uri ($;%) {
  my ($qname, %opt) = @_;
  $qname =~ s/^\s+//;
  $qname =~ s/\s+$//;
  my ($prefix, $lname) = split /:/, $qname, 2;
  if (defined $lname) {
    if ($prefix eq 'URI') {
      return $lname;
    } else {
      my $uri = dis_nsprefix_to_uri ($prefix, %opt);
      return defined $uri ? $uri . $lname : $lname;
    }
  } else {
    my $uri = dis_nsprefix_to_uri (undef, %opt);
    return defined $uri ? $uri . $prefix : $prefix;
  }
}

=item ($uri, $local_name) = dis_qname_to_pair ($qname, %opt)

Split QName into namespace prefix and local name 
and return pair of namespace URI and local name.

=cut

sub dis_qname_to_pair ($;%) {
  my ($qname, %opt) = @_;
  $qname =~ s/^\s+//;
  $qname =~ s/\s+$//;
  my ($prefix, $lname) = split /:/, $qname, 2;
  if (defined $lname) {
    if ($prefix eq 'URI') {
      return (undef, $lname);
    } else {
      my $uri = dis_nsprefix_to_uri ($prefix, %opt);
      return ($uri, $lname);
    }
  } else {
    my $uri = dis_nsprefix_to_uri (undef, %opt);
    return ($uri, $prefix);
  }
}

=item $uri = dis_typeforuris_to_uri ($type_uri, $for_uri, %opt)

Return the URI reference identifying a pair of "Type" and 
"For".

If the "For" URI reference equals to C<ManakaiDOM:all>, the 
result URI reference is the "Type" URI reference itself.  
Otherwise, a URI reference generated from the two URI references 
are returned.

=cut

sub dis_typeforuris_to_uri ($$;%) {
  my ($type, $for, %opt) = @_;
  $type ||= ExpandedURI q<DOMMain:any>;
  $for ||= ExpandedURI q<ManakaiDOM:all>;
  if ($for eq ExpandedURI q<ManakaiDOM:all>) {
    return dis_type_canon_uri ($type);
  } else {
    for ($type, $for) {
      s{([^0-9A-Za-z:;?=_./-])}{sprintf '%%%02X', ord $1}ge;
    }
    return dis_type_canon_uri
             (qq<data:,200411tf#xmlns(t=data:,200411tf%23)t:tf($type,$for)>);
  }
}

=item $uri = dis_typeforqnames_to_uri ($qnameqname, %opt)

Expand a TypeForQNameQName into a URI reference.

=cut

sub dis_typeforqnames_to_uri ($;%) {
  my ($qq, %opt) = @_;
  my ($typeq, $forq) = split /\s*::\s*/, $qq, 2;
  my ($type, $for);
  my $pt = {
    boolean => ExpandedURI q<DOMMain:boolean>,
    long => ExpandedURI q<DOMMain:long>,
    'unsigned-long' => ExpandedURI q<DOMMain:unsigned-long>,
    any => ExpandedURI q<DOMMain:any>,
    DOMString => ExpandedURI q<DOMMain:DOMString>,
    Object => ExpandedURI q<DOMMain:Object>,
    short => ExpandedURI q<DOMMain:short>,
    'unsigned-short' => ExpandedURI q<DOMMain:unsigned-short>,
  };
  if ($typeq eq '' and $opt{use_default_type}) {
    $type = $opt{use_default_type};
  }
  if (defined $forq) {
    $type ||= $pt->{$typeq} || dis_qname_to_uri ($typeq, %opt);
    if (length $forq) {
      $for = dis_qname_to_uri ($forq, %opt);
    } else {
      $for = ExpandedURI q<ManakaiDOM:all>;
    }
  } else {
    $type ||= $pt->{$typeq} || dis_qname_to_uri ($typeq, %opt);
    $for = $opt{For} || ExpandedURI q<ManakaiDOM:all>;
  }
  return dis_typeforuris_to_uri ($type, $for, %opt);
}

=item $uri = dis_typeforqnames_to_type_uri ($qnameqname, %opt)

Expand a TypeForQNameQName into a URI reference.  If the type with
specified (or implied) "Type" is not defined, depth-first nearest 
super-"For" in which the type is defined is searched.

=cut

sub dis_typeforqnames_to_type_uri ($;%) {
  my ($qq, %opt) = @_;
  my ($typeq, $forq) = split /::/, $qq, 2;
  my ($type, $for);
  my $pt = {
    boolean => ExpandedURI q<DOMMain:boolean>,
    long => ExpandedURI q<DOMMain:long>,
    'unsigned-long' => ExpandedURI q<DOMMain:unsigned-long>,
    any => ExpandedURI q<DOMMain:any>,
    DOMString => ExpandedURI q<DOMMain:DOMString>,
    Object => ExpandedURI q<DOMMain:Object>,
    short => ExpandedURI q<DOMMain:short>,
    'unsigned-short' => ExpandedURI q<DOMMain:unsigned-short>,
  };
  if ($typeq eq '' and $opt{use_default_type}) {
    $type = $opt{use_default_type};
  }
  if (defined $forq) {
    $type ||= $pt->{$typeq} || dis_qname_to_uri ($typeq, %opt);
    if (length $forq) {
      $for = dis_qname_to_uri ($forq, %opt);
    } else {
      $for = ExpandedURI q<ManakaiDOM:all>;
    }
  } else {
    $type ||= $pt->{$typeq} || dis_qname_to_uri ($typeq, %opt);
    $for = $opt{For} || ExpandedURI q<ManakaiDOM:all>;
  }
  
  my @for = $for;
  my $i = 0;
  while (my $for = shift @for) {
    if (++$i == 1024) {
      valid_err (q<Too many super-resources>, node => $opt{node});
    }
    my $uri = dis_typeforuris_to_uri ($type, $for, %opt);
    if (defined $State->{Type}->{$uri}->{Name}) {
      return $State->{Type}->{$uri}->{URI} || $uri;
    }
    if (not ref $State->{For}->{$for}->{ISA} or
        not ref $State->{For}->{$for}->{subsetOf} or
        not ref $State->{For}->{$for}->{Implement}) {
      valid_err (qq<For <$for> in type <$type> must be defined>,
                 node => $opt{node});
    }
    unshift @for, @{$State->{For}->{$for}->{ISA}},
                  @{$State->{For}->{$for}->{subsetOf}},
                  @{$State->{For}->{$for}->{Implement}};
  }
  valid_err (qq<Type <$type> for <$for> must be defined>, node => $opt{node});
} # dis_typeforqnames_to_type_uri

=item dis_type_canon_uri ($type_uri, %opt)

Canonicalize "Type" URI reference.

=cut

sub dis_type_canon_uri ($;%) {
  my ($type_uri, %opt) = @_;
  if ($opt{dont_canon_uri}) {
    return $type_uri;
  } else {
    if (defined $State->{Type}->{$type_uri}->{Namespace}) {
      return $State->{Type}->{$type_uri}->{Namespace};
    } else {
      return $type_uri;
    }
  }
}

=item $for_node/1/undef = dis_node_for_match ($node, $for_uri, %opt)

Return whether the C<$node> matches to the C<$for_uri>. 
C<For> attributes of the C<$node> is checked for the match.

If matched, the C<For> attribute node to which the C<$for_uri> 
has matched is returned.  Otherwise, C<undef> is returned.

=cut

sub dis_node_for_match ($$%) {
  my ($node, $for_uri, %opt) = @_;
  $for_uri ||= ExpandedURI q<ManakaiDOM:all>;
  my $has_for = 0;
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    if (dis_element_type_match ($_->local_name, 'ForCheck', %opt, node => $_)) {
      my $for = [split /\s+/, $_->value];
      FCs: for my $f (@$for) {
        if ($f =~ /^!=(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt);
          $State->{def_required}->{For}->{$uri} ||= 1;
          for my $for_uri ($for_uri, @{$opt{'For+'}||[]}) {
            if ($uri eq $for_uri) {
              return undef;
            }
          }
        } elsif ($f =~ /^!(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt);
          $State->{def_required}->{For}->{$uri} ||= 1;
          for my $for_uri ($for_uri, @{$opt{'For+'}||[]}) {
            if (dis_uri_for_match ($uri, $for_uri, %opt, node => $_)) {
              return undef;
            }
          }
        } elsif ($f =~ /^=(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{def_required}->{For}->{$uri} ||= 1;
          for my $for_uri ($for_uri, @{$opt{'For+'}||[]}) {
            if ($uri eq $for_uri) {
              next FCs;
            }
          }
          return undef;
        } else {
          my $uri = dis_qname_to_uri ($f, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{def_required}->{For}->{$uri} ||= 1;
          for my $for_uri ($for_uri, @{$opt{'For+'}||[]}) {
            if (dis_uri_for_match ($uri, $for_uri, %opt, node => $_)) {
              next FCs;
            }
          }
          return undef;
        }
      }
    }
  }
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    if (dis_element_type_match ($_->local_name, 'For', %opt)) {
      my $for = [split /\s+/, $_->value];
      my $ok = 1;
      $has_for = 1;
      for my $f (@$for) {
        if ($f =~ /^!=(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{def_required}->{For}->{$uri} ||= 1;
          if ($uri eq $for_uri) {
            $ok = 0;
            last;
          }
        } elsif ($f =~ /^!(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{def_required}->{For}->{$uri} ||= 1;
          if (dis_uri_for_match ($uri, $for_uri, %opt, node => $_)) {
            $ok = 0;
            last;
          }
        } elsif ($f =~ /^=(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{def_required}->{For}->{$uri} ||= 1;
          unless ($uri eq $for_uri) {
            $ok = 0;
            last;
          }
        } else {
          my $uri = dis_qname_to_uri ($f, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{def_required}->{For}->{$uri} ||= 1;
          unless (dis_uri_for_match ($uri, $for_uri, %opt, node => $_)) {
            $ok = 0;
            last;
          }
        }
      }
      return $_ if $ok;
    }
  }
  return $has_for ? undef : 1;
}

=item $for_node/1/undef = dis_node_ctype_match ($node, $type_uri, %opt)

Return whether the C<$node> matches to the C<$type_uri>. 
C<ContentType> attributes of the C<$node> is checked for the match.

If matched, the C<Type> attribute node to which the C<$type_uri> 
has matched is returned.  Otherwise, C<undef> is returned. 
If there is no C<ContentType> attribute, C<1> is returned.

=cut

sub dis_node_ctype_match ($$%) {
  my ($node, $type_uri, %opt) = @_;
  $type_uri ||= ExpandedURI q<DOMMain:any>;
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq 'ContentType') {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1, %opt);
      $State->{def_required}->{Class}->{$uri} ||= $_;
      unless (dis_uri_ctype_match ($uri, $type_uri, %opt)) {
        return undef;
      }
      return $_;
    }
  }
  return 1;
}

=item $for_node/1/undef = dis_node_lang_match ($node, $lang_tag, %opt)

Return whether the C<$node> matches to the C<$lang_tag>. 
C<lang> attributes of the C<$node> is checked for the match.

If matched, the C<lang> attribute node to which the C<$lang_tag> 
has matched is returned.  Otherwise, C<undef> is returned. 
If there is no C<lang> attribute, C<1> is returned.

Note:  The default value of the C<lang> attribute is C<i-default>. 

Note:  More study required for the matching way (C<en> vs C<en-GB>).

=cut

sub dis_node_lang_match ($$%) {
  my ($node, $lang_tag, %opt) = @_;
  $lang_tag ||= 'i-default';
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq 'lang') {
      unless ($_->value eq $lang_tag) {
        return undef;
      }
      return $_;
    }
  }
  return $lang_tag eq 'i-default' ? 1 : 0;
}

=item $for_node/1/undef = dis_node_script_match ($node, $script_tag, %opt)

Return whether the C<$node> matches to the C<$script_tag>. 
C<script> attributes of the C<$node> is checked for the match.

If matched, the C<lang> attribute node to which the C<$script_tag> 
has matched is returned.  Otherwise, C<undef> is returned. 
If there is no C<lang> attribute, C<1> is returned.

Note:  The default value of the C<script> attribute is C<s-default>. 

Note:  More study required for the matching way.

=cut

sub dis_node_script_match ($$%) {
  my ($node, $script_tag, %opt) = @_;
  $script_tag ||= 's-default';
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq 'script') {
      unless ($_->value eq $script_tag) {
        return undef;
      }
      return $_;
    }
  }
  return $script_tag eq 's-default' ? 1 : 0;
}

=item 1/0 = dis_uri_for_match ($uri, $for_uri, %opt)

Return whether the C<$uri> matches to the C<$for_uri>. 

=cut

{our $dis_uri_for_match_loop = 0;
my $checked = {};
sub dis_uri_for_match ($$%);
sub dis_uri_for_match ($$%) {
  my ($uri, $for_uri, %opt) = @_;
  return 1 if $uri eq $for_uri;
  return 0 if $checked->{$for_uri};
  if ($State->{ExpandedURI q<dis2pm:forCache>}->{$uri}->{$for_uri}) {
    return $State->{ExpandedURI q<dis2pm:forCache>}->{$uri}->{$for_uri} > 0;
  }
  local $checked->{$for_uri} = 1;
  local $dis_uri_for_match_loop = $dis_uri_for_match_loop + 1;
  if ($dis_uri_for_match_loop == 1024) {
    valid_err (qq'$0: "For" URI inheritance might be looping');
  }
  for (@{$State->{For}->{$for_uri}->{ISA}||[]},
       @{$State->{For}->{$for_uri}->{subsetOf}||[]},
       @{$State->{For}->{$for_uri}->{Implement}||[]}) {
    if (dis_uri_for_match ($uri, $_, %opt)) {
      $State->{ExpandedURI q<dis2pm:forCache>}->{$uri}->{$for_uri} = 1;
      return 1;
    }
  }
  $State->{ExpandedURI q<dis2pm:forCache>}->{$uri}->{$for_uri} = -1;
  return 0;
}}

=item 1/0 = dis_uri_ctype_match ($uri $type_uri, %opt)

Return whether the C<$uri> matches to the C<$type_uri>. 

=cut

sub dis_uri_ctype_match ($$%) {
  my ($uri, $type_uri, %opt) = @_;
  return 1 if $uri eq $type_uri;
  return $State->{Type}->{$type_uri}->{subsetOf}->{$uri};
}

=item 1/0 = dis_resource_ctype_match ($type_uri, $resource, %opt)

Checks and returns whether a resource is of type C<$type_uri> or not.

=cut

sub dis_resource_ctype_match ($$;%) {
  my ($uri, $res, %opt) = @_;
  my @uri = ref $uri ? @$uri : $uri;
  for (@uri) {
    return 1 if $res->{Type}->{$_};
  }
  for (keys %{$res->{Type}||{}}) {
    for my $uri (@uri) {
      if (dis_uri_ctype_match ($uri, $_, %opt)) {
        return 1;
      }
    }
  }
  return 0;
} # dis_resource_ctype_match


=item $uri = dis_element_type_to_uri ($element_type, %opt)

Convert a dis element type into a URI reference.

=cut

sub dis_element_type_to_uri ($;%) {
  my ($et, %opt) = @_;
  return dis_qname_to_uri ($et, %opt,
                           use_default_namespace => ExpandedURI q<d:>);
}

=item 1/0 = dis_element_type_match ($type1, $type2, %opt)

Test whether element type names match or not.

=cut

sub dis_element_type_match ($$;%) {
  my ($t1, $t2, %opt) = @_;
  for ($t1, $t2) {
    if (ref $_) {
      $_ = $_->{uri};
    } else {
      $_ = dis_element_type_to_uri ($_, %opt);
    }
  }
  $t1 eq $t2;
}

=item $node/0/undef = dis_get_attr_node (%opt)

Get attribute node if any.  If there is an C<$opt{name}> attribute but 
it does not match to either requested content type, "for", language or 
writing script, C<0> is returned.

=cut

sub dis_get_attr_node (%) {
  my %opt = @_;
  my $en = defined $opt{name} ? $opt{name}
                              : impl_err (q<"name" parameter required>,
                                          node => $opt{parent});
  impl_err (q<"parent" parameter required>)
    if not $opt{parent} or ref $opt{parent} eq 'HASH' or
       ref $opt{parent} eq 'ARRAY';
  for (@{$opt{parent}->child_nodes}) {
    next unless $_->node_type eq '#element';
    if (dis_element_type_match ($_->local_name, $en, %opt, node => $_)) {
      if (defined $opt{For}) {
        unless (dis_node_for_match ($_, $opt{For}, %opt)) {
          next;
        }
      }
      if (defined $opt{ContentType}) {
        my $ct = dis_node_ctype_match ($_, $opt{ContentType}, %opt);
        if (ref $ct) {
          # 
        } elsif ($ct and $opt{defaultContentType}) {
          next unless dis_uri_ctype_match ($opt{defaultContentType}, 
                                           $opt{ContentType}, %opt);
        } elsif ($ct and not $opt{defaultContentType}) {
          # 
        } else {
          next;
        }
      }
      if (defined $opt{lang}) {
        unless (dis_node_lang_match ($_, $opt{lang}, %opt)) {
          next;
        }
      }
      if (defined $opt{script}) {
        unless (dis_node_script_match ($_, $opt{script}, %opt)) {
          next;
        }
      }
      return $_;
    }
  }
}

=item [$node,...] = dis_get_elements_nodes (%opt)

Get elements nodes.

=cut

sub dis_get_elements_nodes (%) {
  my %opt = @_;
  my $en = defined $opt{name} ? $opt{name}
                              : impl_err (q<name parameter required>,
                                          node => $opt{parent});
  my @r;
  for (@{$opt{parent}->child_nodes}) {
    next unless $_->node_type eq '#element';
    if (dis_element_type_match ($_->local_name, $en, %opt)) {
      if (defined $opt{For}) {
        unless (dis_node_for_match ($_, $opt{For}, %opt)) {
          next;
        }
      }
      if (defined $opt{ContentType}) {
        unless (dis_node_ctype_match ($_, $opt{ContentType}, %opt)) {
          next;
        }
      }
      if (defined $opt{lang}) {
        unless (dis_node_lang_match ($_, $opt{lang}, %opt)) {
          next;
        }
      }
      if (defined $opt{script}) {
        unless (dis_node_script_match ($_, $opt{script}, %opt)) {
          next;
        }
      }
      push @r, $_;
    }
  }
  \@r;
}

=item $under_score_name = dis_camelCase_to_underscore_name ($camelName)

Converts a camelCaseName to underscore_style_name. 

=cut
    
sub dis_camelCase_to_underscore_name ($) {
  my $name = shift;
  $name =~ s/^([A-Z0-9]+)$/lc $1/ge;
  $name =~ s/([A-Z][A-Z0-9]*)$/"_".lc $1/ge;
  $name =~ s/([A-Z0-9])([A-Z0-9]*)([A-Z0-9])/$1.lc ($2)."_".lc $3/ge;
  $name =~ s/([A-Z])/"_".lc $1/ge;
  $name =~ s/(?=[0-9](?!$))/_/g;
  $name;
}

=item {For => for_uri, module => module_uri} = dis_get_module_uri (%opt)

Get module URI reference from either module URI reference (C<$opt{module_uri}>;
either "For"ed or non-"For"ed) or module name (C<$opt{module_name}>) and 
"For" URI reference (C<$opt{For}>).  If C<$opt{For}> is not specified, 
the default "For" (C<Module/DefaultFor>) define in the module is 
returned.

=cut

sub dis_get_module_uri (%) {
  my %opt = @_;
  my $r = {For => $opt{For}};
  if ($opt{module_name}) {
    MOD: {
      for (values %{$State->{Module}}) {
        next unless defined $_->{Name};
        if ($_->{Name} eq $opt{module_name}) {
          $opt{module_uri} = $_->{NameURI};
          $r->{For} ||= $_->{ExpandedURI q<d:DefaultFor>};
          last MOD;
        }
      }
      valid_err (qq<Module "$opt{module_name}" not defined>);
    }
  }
  unless ($r->{For}) {
    MOD: {
      for (values %{$State->{Module}}) {
        next unless defined $_->{Name};
        if ($_->{NameURI} eq $opt{module_uri} or
            $_->{URI} eq $opt{module_uri}) {
          $r->{For} = $_->{ExpandedURI q<d:DefaultFor>};
          last MOD;
        }
      }
      valid_err (qq<Module <$opt{module_uri}> not defined>);
    }
  }
  if (defined $State->{Module}->{$opt{module_uri}}->{Name} and
      $State->{Module}->{$opt{module_uri}}->{For}->{$opt{For}}) {
    $r->{module} = $State->{Module}->{$opt{module_uri}}->{URI};
  } else {
    my $tfuri = dis_typeforuris_to_uri ($opt{module_uri}, $r->{For}, %opt);
    if (defined $State->{Module}->{$tfuri}->{Name}) {
      $r->{module} = $State->{Module}->{$tfuri}->{URI};
    } else {
      valid_err (qq{Module <$opt{module_uri}> for <$r->{For}> not defined});
    }
  }
  return $r;
} # dis_get_module_uri

=item $path = dis_get_module_file_path (%opt)

Get module file path.

=cut

sub dis_get_module_file_path (%) {
  my (%opt) = @_;
  my $file;
  require File::Spec;
  if (defined $opt{module_file_name}) {
    if (-e $opt{module_file_name}) {
      $file = $opt{module_file_name};
    } else {
      valid_err (qq<Included module file "$opt{module_file_name}" not found>,
                 node => $opt{module_node});
    }
  } elsif ($opt{module_name}) {
    if (-e $opt{module_name} . '.dis') {
      $file = $opt{module_name} . '.dis';
    } else {
      valid_err (qq<Included module "$opt{module_name}" not found>,
                 node => $opt{module_node});      
    }
  } elsif ($opt{module_node}) {
    my $filename_node = dis_get_attr_node
                           (%opt, parent => $opt{module_node},
                            ContentType => ExpandedURI q<lang:dis>,
                            name => 'FileName');
    if ($filename_node) {
      $file = $filename_node->value;
    } else {
      my $name_node = dis_get_attr_node (%opt, parent => $opt{module_node},
                                         name => 'Name');
      if ($name_node) {
        $file = $name_node->value . '.dis';
      } else {
        valid_err (q<Included module file name not specified>,
                   node => $opt{module_node});
      }
    }
    for my $dir (@{$opt{module_file_search_path} || []}) {
      my $name = File::Spec->canonpath (File::Spec->catfile ($dir, $file));
      if (-e $name) {
        return $name;
      }
    }
    valid_err (qq<Included module file "$file" not found>,
               node => $opt{module_node});
  } else {
    valid_err (q<Included module file name not specified>);
  }
  return File::Spec->canonpath ($file);
}

=item $root = dis_load_module_file (%opt)

Load a module file and merge type information (such as 
module name, namespace, type inheritance and so on.)

Return Value: The root node of the module loaded.

=cut

{
our $dis_load_module_file_loop = 0;
sub dis_load_module_file (%);
sub dis_load_module_file (%) {
  my (%opt) = @_;
  local $dis_load_module_file_loop = $dis_load_module_file_loop + 1;
  if ($dis_load_module_file_loop == 1024) {
    valid_err (qq'$0: Required module inheritance might be looping',
               node => $opt{module_node});
  }
  my $file_name = dis_get_module_file_path (%opt);
  my $source; ## Root node
  my $mod;    ## Module element
  if ($State->{module_file_loaded}->{$file_name}) {
    $mod = dis_get_attr_node
             (%opt, name => 'Module',
              parent => ($source = $State->{module_file_loaded}->{$file_name}));
    ## Load Namespace Bindings
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      if (dis_element_type_match ($_->local_name, 'Namespace',
                                  %opt, node => $_)) {
        dis_load_namespace_element ($_, %opt);
      }
    }
  } else {
    open my $file, '<', $file_name or impl_err (qq<$file_name: $!>,
                                                node => $opt{module_node});
    impl_msg (qq<Opening file "$file_name"...>,
              node => $opt{module_node});
    local $/ = undef;
    $State->{module_file_loaded}->{$file_name} = $source
      = Message::Markup::SuikaWikiConfig20::Parser
                                        ->parse_text (<$file>);
    $mod = dis_get_attr_node (%opt, parent => $source,
                              name => 'Module');
    unless ($mod) {
      valid_err q<"Module" element required>, node => $source;
    }
    ## Load Namespace Bindings
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      if (dis_element_type_match ($_->local_name, 'Namespace',
                                  %opt, node => $_)) {
        dis_load_namespace_element ($_, %opt);
      } elsif (dis_element_type_match ($_->local_name, 'ElementTypeBinding',
                                       %opt, node => $_)) {
        dis_load_etbinding_element ($_, %opt);
      }
    }
    dis_apply_etbindings ($source, %opt);
    ## Load For Definitions
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      if (dis_element_type_match ($_->local_name, 'ForDef',
                                  %opt, node => $_)) {
        dis_load_fordef_element ($_, %opt);
        $State->{ExpandedURI q<dis2pm:forCache>} = {};
      }
    }
  }
  if (not defined $opt{For} and $opt{use_default_for}) {
    my $df = dis_get_attr_node (%opt, parent => $mod, name => 'DefaultFor');
    if ($df) {
      $State->{DefaultFor} = dis_qname_to_uri ($df->value, %opt, node => $df);
    } else {
      $State->{DefaultFor} = ExpandedURI q<ManakaiDOM:all>;
    }
    $opt{For} = $State->{DefaultFor};
    $State->{def_required}->{For}->{$State->{DefaultFor}} ||= 1;
  }
  if (defined $opt{For} and
      not $opt{For} eq ExpandedURI q<ManakaiDOM:all>) {
    dis_load_module_file (%opt, use_default_for => 0,
                          For => ExpandedURI q<ManakaiDOM:all>);
  }
  ## Load Module Definition
  if (dis_load_module_element ($mod, %opt,
                               module_file_name => $file_name)) {
    impl_msg (qq<Loading definition of "$file_name" for <$opt{For}>...>,
              node => $mod);
    ## Load Class Definitions
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      next unless dis_node_for_match ($_, $opt{For}, %opt);
      my $et = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
      if ($et eq ExpandedURI q<d:ResourceDef>) {
        local $State->{current_class_container};
        dis_load_classdef_element ($_, %opt);
      } elsif ({
                 ExpandedURI q<d:ElementTypeBinding> => 1,
                 ExpandedURI q<d:ForDef> => 1,
                 ExpandedURI q<d:Module> => 1,
                 ExpandedURI q<d:Namespace> => 1,
                 ExpandedURI q<d:ImplNote> => 1,
               }->{$et}) {
        # 
      } else {
        valid_err (q<Unknown element type>, node => $_);
      }
    }
  } else {
    ## Module@For already loaded
  }
  return $source;
}}

=item 1/0 = dis_load_module_element ($node, %opt)

Install module definitions from a node.  If the module 
is already loaded, return C<0>.  Otherwise, C<1> is returned.

=cut

sub dis_load_module_element ($;%) {
  my ($node, %opt) = @_;
  my $mod = {
    FileName => $opt{module_file_name},
    Namespace => $node->get_attribute_value ('Namespace'),
    src => $node,
    nsBinding => $State->{Namespace},
  };
  for ($node->get_attribute ('QName')) {
    valid_err (q<Module "QName" attribute required>, node => $node) unless $_;
    my ($uri, $lname) = dis_qname_to_pair ($_->value, %opt, node => $_);
    $mod->{Name} = $lname;
    $mod->{NameURI} = dis_qname_to_uri ($_->value, %opt, node => $_);
    $mod->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
    $mod->{URI} = dis_typeforuris_to_uri ($mod->{NameURI}, $opt{For}, %opt);
    $mod->{ModuleGroup} = $uri;
    $mod->{def_required}->{ModuleGroup}->{$uri} ||= 1;
    push @{$mod->{ISA}}, $mod->{NameURI}
      unless $mod->{For}->{ExpandedURI q<ManakaiDOM:all>};
  }
  if (not defined $mod->{Namespace}) {
    valid_err (q<Namespace URI of the module not defined>, node => $node);
  } elsif (not defined $mod->{NameURI}) {
    valid_err (q<Module name not defined>, node => $node);
  } elsif (defined $State->{Module}->{$mod->{URI}}->{URI}) {
    ## Already loaded
    $State->{module} = $mod->{URI};
    return 0;
  } else {
    $State->{Module}->{$mod->{URI}} = $mod;
    $State->{module} = $mod->{URI};
  }
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match ($_, $opt{For}, %opt);
    my $ln = $_->local_name;
    if (dis_element_type_match ($ln, 'Require', %opt, node => $_)) {
      for (@{$_->child_nodes}) {
        next unless $_->node_type eq '#element';
        next unless dis_node_for_match ($_, $opt{For}, %opt);
        my $ln = $_->local_name;
        if (dis_element_type_match ($ln, 'Module',
                                    %opt, node => $_)) {
          local $opt{For} = $opt{For};
          my $wf = dis_get_attr_node (%opt, parent => $_,
                                      name => 'WithFor');
          if ($wf) {
            $opt{For} = dis_qname_to_uri ($wf->value, use_default_namespace => 1,
                                          %opt, node => $wf);
            $State->{def_required}->{For}->{$opt{For}} ||= $wf;
          }
          local $State->{Namespace} = {};
          local $State->{ETBinding} = {};
          local $State->{module};
          dis_load_module_file (%opt, module_node => $_,
                                module_file_name => undef,
                                use_default_for => 0);
          push @{$mod->{require_module}||=[]}, $State->{module}
            if defined $State->{module};
        }
      }
    } elsif (dis_element_type_match ($ln, 'DefaultFor', %opt, node => $_)) {
      if (defined $mod->{ExpandedURI q<d:DefaultFor>}) {
        valid_err (q<"DefaultFor" attribute is alerady specified>,
                   node => $_);
      }
      $mod->{ExpandedURI q<d:DefaultFor>}
          = dis_qname_to_uri ($_->value, use_default_namespace => 1, 
                              %opt, node => $_);
    }
  }
  $mod->{ExpandedURI q<d:DefaultFor>} ||= ExpandedURI q<ManakaiDOM:all>;
  return 1;
}

=item dis_load_fordef_element ($node, %opt)

Load C<For> definitions from a node.

=cut

sub dis_load_fordef_element ($;%) {
  my ($node, %opt) = @_;
  my $qn = dis_get_attr_node (%opt, parent => $node, name => 'QName');
  valid_err (q<"QName" attribute required>, node => $node) unless $qn;
  my $uri = dis_qname_to_uri ($qn->value,
                              use_default_namespace => 1, %opt,
                              node => $node);
  if (defined $State->{For}->{$uri}->{URI}) {
    valid_err (qq<"For" <$uri> already defined>, node => $node);
  }
  $State->{For}->{$uri} = my $for = {
    NameURI => $uri,
    URI => $uri,
    ISA => [],
    Implement => [],
    subsetOf => [],
    src => $node,
  };
  $State->{def_required}->{For}->{$uri} = -1;

  ## TODO: Use general documentation converter
  my $fn = dis_get_attr_node (%opt, name => 'FullName', parent => $node);
  if ($fn) {
    $for->{FullName} = disdoc_inline2text ($fn->value, %opt, node => $fn);
  }
  
  for (@{$_->child_nodes}) {
    next unless $_->node_type eq '#element';
    my $ln = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
    if ($ln eq ExpandedURI q<d:ISA>) {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      push @{$for->{ISA}}, $uri;
      $State->{def_required}->{For}->{$uri} ||= 1;
    } elsif ($ln eq ExpandedURI q<d:subsetOf>) {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      push @{$for->{ExpandedURI q<d:subsetOf>}}, $uri;
      $State->{def_required}->{For}->{$uri} ||= 1;
    } elsif ($ln eq ExpandedURI q<d:Implement>) {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      push @{$for->{Implement}}, $uri;
      $State->{def_required}->{For}->{$uri} ||= 1;
    } elsif ({
               ExpandedURI q<d:QName> => 1,
               ExpandedURI q<d:FullName> => 1,
               ExpandedURI q<d:Description> => 1,
             }->{$ln}) {
      # 
    } else {
      valid_err (q<Unsupported element type>, node => $_);
    }
  }
  push @{$for->{ISA}}, ExpandedURI q<ManakaiDOM:all>
    if not @{$for->{ISA}} and
       not $for->{URI} eq ExpandedURI q<ManakaiDOM:all>;
} # dis_load_fordef_element

=item dis_load_namespace_element ($node, %opt)

Install namespace bindings from a node.

=cut

sub dis_load_namespace_element ($;%) {
  my ($node, %opt) = @_;
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    my $ln = $_->local_name;
    if ($ln eq 'URI') {
      valid_err (q<Namespace prefix "URI" cannot be defined>, node => $_);
    } else {
      $State->{Namespace}->{$ln} = {uri => $_->value};
    }
  }
}

=item dis_load_etbinding_element ($node, %opt)

Load element type binding.

=cut

sub dis_load_etbinding_element ($;%) {
  my ($node, %opt) = @_;
  my $etb = {src => $node};
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    my $et = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
    if ($et eq ExpandedURI q<d:Name>) {
      $etb->{Name} = $_->value;
      if (defined $State->{ETBinding}->{$etb->{Name}}->{Name}) {
        valid_err (qq{Binding "$etb->{Name}" is already defined}, node => $node);
      } else {
        $State->{ETBinding}->{$etb->{Name}} = $etb;
      }
    } elsif ($et eq ExpandedURI q<d:ElementType>) {
      $etb->{ElementType} = dis_qname_to_uri ($_->value, %opt, node => $_);
    } elsif ($et eq ExpandedURI q<d:ShadowContent>) {
      $etb->{ShadowContent} = $_;
    } elsif ($et eq ExpandedURI q<d:ShadowSibling>) {
      $etb->{ShadowSibling} = $_;
      my $v = $_->value;
      if (defined $v and length $v) {
        valid_err (q<ShadowSibling cannot have its value>, node => $_);
      }
    } else {
      valid_err (q<Unknown element type>, node => $_);
    }
  }
  valid_err (q<Binding element type is not specified>, node => $node)
    unless defined $etb->{Name};
  valid_err (q<Binded element type is not specified>, node => $node)
    unless defined $etb->{ElementType};
}

=item dis_apply_etbinding ($node, %opt)

Apply element type bindings.

=cut

sub dis_apply_etbindings ($;%);
sub dis_apply_etbindings ($;%) {
  my ($src, %opt) = @_;
  for (@{$src->child_nodes}) {
    next unless $_->node_type eq '#element';
    dis_apply_etbindings ($_, %opt);
  }
  return unless $src->node_type eq '#element';
  if (defined $State->{ETBinding}->{$src->local_name}->{Name}) {
    my $etb = $State->{ETBinding}->{$src->local_name};
    $src->local_name ('URI:'.$etb->{ElementType}) if defined $etb->{ElementType};
    if ($etb->{ShadowContent}) {
      for (@{$etb->{ShadowContent}->child_nodes}) {
        $src->append_node ($_->clone);
      }
      $src->inner_text (new_value => $etb->{ShadowContent}->inner_text);
         ## Note: Value is not changed if ShadowContent.value is undef.
    }
    if ($etb->{ShadowSibling}) {
      for (@{$etb->{ShadowSibling}->child_nodes}) {
        $src->parent_node->append_node ($_->clone);
      }
    }
  }
}

=item dis_load_classdef_element ($node, %opt)

Load a class (programming language class, interface, datatype, 
markup language element type, etc.) definition.

=cut

{
our $dis_load_classdef_element_loop = 0;
our $dis_load_classdef_seq = 0;
sub dis_load_classdef_element ($;%);
sub dis_load_classdef_element ($;%) {
  my ($node, %opt) = @_;
  local $dis_load_classdef_element_loop = $dis_load_classdef_element_loop + 1;
  if ($dis_load_classdef_element_loop == 256) {
    valid_err (q<Class definition nests too deep>, node => $node);
  }
  my $cls;
  my $oldcls = '';
  my $qn = dis_get_attr_node (%opt, parent => $node, name => 'QName');
  my $ln = dis_get_attr_node (%opt, parent => $node, name => 'Name');
  my $al = dis_get_attr_node (%opt, parent => $node, name => 'AliasFor');
  if ($qn) { ## Global class
    my ($nuri, $lname) = dis_qname_to_pair ($qn->value, 
                                            use_default_namespace => 1,
                                            %opt, node => $node);
    my $uri = dis_qname_to_uri ($qn->value, use_default_namespace => 1,
                                %opt, node => $node);
    my $dfuri = dis_typeforuris_to_uri ($uri, $opt{For}, %opt);
    unless ($al) {
      $cls = ($State->{Type}->{$dfuri} ||= {});
      if (defined $cls->{Name}) {
        valid_err (qq<Class <$dfuri> is already defined>, node => $node);
      }
      $cls->{seq} = ++$dis_load_classdef_seq;
      $cls->{Name} = $lname;
      $cls->{NameURI} = $uri;
      $cls->{URI} = $dfuri;
      $cls->{parentModule} = $State->{module};
      $cls->{src} = $node;
    } else {
      my $canon = dis_typeforqnames_to_uri ($al->value, 
                                    use_default_namespace => 1,
                                    %opt, node => $al,
                                    use_default_type => $uri);
      if (defined $State->{Type}->{$dfuri}->{Name}) {
        valid_err (qq<Class <$dfuri> is already defined>, node => $node);
      }
      $oldcls = $State->{Type}->{$dfuri};
      $cls = ($State->{Type}->{$canon} ||= {});
      for (keys %{$State->{Type}->{$dfuri}->{aliasURI}||{}}, $dfuri, $canon) {
        $cls->{aliasURI}->{$_} = 1;
        $State->{Type}->{$_} = $cls;
        $State->{Resource}->{$_} = $cls
          unless defined $State->{current_class_container};
      }
      $State->{def_required}->{Class}->{$dfuri} = -1;
      $State->{def_required}->{Class}->{$canon} ||= $al;

      $cls->{subsetOf}->{$_} = 1 if grep {$oldcls->{subsetOf}->{$_}}
                                    keys %{$oldcls->{subsetOf}};
      $cls->{ExpandedURI q<d:supersetOf>}->{$_} = 1
                          if grep {$oldcls->{ExpandedURI q<d:supersetOf>}->{$_}}
                             keys %{$oldcls->{ExpandedURI q<d:supersetOf>}};
      my @from =($canon, $dfuri, grep {$cls->{ExpandedURI q<d:supersetOf>}->{$_}}
                         keys %{$cls->{ExpandedURI q<d:supersetOf>}});
      my @to =($canon, $dfuri, grep {$cls->{subsetOf}->{$_}}
                       keys %{$cls->{subsetOf}});
      for my $from (@from) {
        for my $to (@to) {
          $State->{Type}->{$from}->{subsetOf}->{$to} = 1;
          $State->{Type}->{$to}->{ExpandedURI q<d:supersetOf>}->{$from} = 1;
        }
      }
    }
    $cls->{For}->{$opt{For} ||= ExpandedURI q<ManakaiDOM:all>} = 1;
    $cls->{'For+'}->{$_} = 1 for @{$opt{'For+'}||[]};
    if ($State->{current_class_container}) {
      $State->{current_class_container}->{Resource}->{$dfuri} = $cls;
      ## Note: Alias to alias might make confusion.
    } else {
      $State->{Resource}->{$dfuri} = $cls;
    }
    $State->{def_required}->{Class}->{$dfuri} = -1;
    my $alluri = dis_typeforuris_to_uri ($uri, ExpandedURI q<ManakaiDOM:all>,
                                         %opt);
    if ($opt{For} ne ExpandedURI q<ManakaiDOM:all> and
        not $cls->{aliasURI}->{$alluri}) {
      push @{$cls->{ISA}||=[]}, $alluri;
      #$State->{def_required}->{Class}->{$alluri} ||= $node;
    }
  } elsif ($ln) {
    my $lname = $ln->value;
    $lname =~ s/^\s+//;
    $lname =~ s/\s+$//;
    unless ($State->{current_class_container}) {  ## Root class (global)
      my $uri = $State->{Module}->{$State->{module}}->{Namespace} . $lname;
      my $dfuri = dis_typeforuris_to_uri ($uri, $opt{For}, %opt);
      unless ($al) {
        $cls = ($State->{Type}->{$dfuri} ||= {});
        if (defined $cls->{Name}) {
          valid_err (qq<Class <$dfuri> is already defined>, node => $node);
        }
        $cls->{seq} = ++$dis_load_classdef_seq;
        $State->{Resource}->{$dfuri} = $cls;
        $cls->{Name} = $lname;
        $cls->{NameURI} = $uri;
        $cls->{URI} = $dfuri;
        $cls->{parentModule} = $State->{module};
        $cls->{src} = $node;
      } else {
        my $canon = dis_typeforqnames_to_uri
                              ($al->value, use_default_namespace => 1,
                               %opt, node => $al, use_default_type => $uri);
        $oldcls = $State->{Type}->{$dfuri};
        $cls = ($State->{Type}->{$canon} ||= {});
        for (keys %{$State->{Type}->{$dfuri}->{aliasURI}||{}}, $dfuri, $canon) {
          $cls->{aliasURI}->{$_} = 1;
          $State->{Type}->{$_} = $cls;
          $State->{Resource}->{$_} = $cls;
        }
        $State->{def_required}->{Class}->{$dfuri} ||= -1;
        $State->{def_required}->{Class}->{$canon} ||= $al;

        $cls->{subsetOf}->{$_} = 1 if grep {$oldcls->{subsetOf}->{$_}}
                                      keys %{$oldcls->{subsetOf}};
        $cls->{ExpandedURI q<d:supersetOf>}->{$_} = 1
                          if grep {$oldcls->{ExpandedURI q<d:supersetOf>}->{$_}}
                             keys %{$oldcls->{ExpandedURI q<d:supersetOf>}};
        my @from = $canon, $dfuri,
                           grep {$cls->{ExpandedURI q<d:supersetOf>}->{$_}}
                           keys %{$cls->{ExpandedURI q<d:supersetOf>}};
        my @to = $canon, $dfuri, grep {$cls->{subsetOf}->{$_}}
                         keys %{$cls->{subsetOf}};
        for my $from (@from) {
          for my $to (@to) {
            $State->{Type}->{$from}->{subsetOf}->{$to} = 1;
            $State->{Type}->{$to}->{ExpandedURI q<d:supersetOf>}->{$from} = 1;
          }
        }
      }
      $cls->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
      $cls->{'For+'}->{$_} = 1 for @{$opt{'For+'}||[]};
      $State->{def_required}->{Class}->{$dfuri} = -1;
      my $alluri = dis_typeforuris_to_uri ($uri, ExpandedURI q<ManakaiDOM:all>,
                                           %opt);
      if ($opt{For} ne ExpandedURI q<ManakaiDOM:all> and
          not $cls->{aliasURI}->{$alluri}) {
        push @{$cls->{ISA}||=[]}, $alluri;
        #$State->{def_required}->{Class}->{$alluri} ||= $node;
      }
    } else {  ## Local class
      my $dfuri = dis_typeforuris_to_uri ($lname, $opt{For}, %opt);
      unless ($al) {
        $cls = ($State->{current_class_container}->{Resource}->{$dfuri} ||= {});
        if (defined $cls->{Name}) {
          valid_err (qq<Local class <$dfuri> is already defined>, node => $node);
        }
        $cls->{seq} = ++$dis_load_classdef_seq;
        $cls->{Name} = $lname;
        $cls->{parentModule} = $State->{module};
        $cls->{src} = $node;
      } else {
        valid_err (q<Local class aliasing is not supported>, node => $al);
      }
      $cls->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
      $cls->{'For+'}->{$_} = 1 for @{$opt{'For+'}||[]};
    }
  } else { ## Anon class
    if ($al) {
      valid_err (q<Anonymous class aliasing is not supported>, node => $node);
    }
    no warnings 'uninitialized';
    my $lname = sprintf '_:dis-class-%d', 
                        $State->{ExpandedURI q<d:anonClassID>}++;
    my $dfuri = dis_typeforuris_to_uri ($lname, $opt{For}, %opt);
    if ($State->{current_class_container}) {
      $cls = ($State->{current_class_container}->{Resource}->{$dfuri} ||= {});
    } else {
      $cls = ($State->{Type}->{$dfuri} ||= {});
      $State->{Resource}->{$dfuri} = $cls;
    }
    if (defined $cls->{Name}) {
      impl_err (qq<Anonymous class <$dfuri> already defined>, node => $node);
    }
    $cls->{seq} = ++$dis_load_classdef_seq;
    $cls->{Name} = '';
      ## Note: To know whether a resource is defined or not, check
      ##       whether its Name is defined or not. 
    $cls->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
    $cls->{'For+'}->{$_} = 1 for @{$opt{'For+'}||[]};
    $cls->{parentModule} = $State->{module};
    $cls->{src} = $node;
  }
  push @{$State->{multiple_resource_parent}->{hasResource}||=[]}, $cls;
  $cls->{multiple_resource_parent} = $State->{multiple_resource_parent};

  my $is_multiresource = 0;
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match ($_, $opt{For}, %opt);
    my $ln = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
    if (dis_uri_ctype_match (ExpandedURI q<rdf:type>, $ln, %opt)) {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      $cls->{Type}->{$uri} = 1;
      $State->{def_required}->{Class}->{$uri} ||= $_;
      $is_multiresource = 1 if dis_uri_ctype_match
                                   (ExpandedURI q<d:MultipleResource>,
                                    $uri, %opt);
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:ISA>, $ln, %opt)) {
      my $uri = dis_typeforqnames_to_uri ($_->value, use_default_namespace => 1,
                                          %opt, node => $_,
                                          use_default_type => $cls->{NameURI});
      if (not defined $cls->{URI} or $uri ne $cls->{URI}) {
        push @{$cls->{ISA}||=[]}, $uri;
        $State->{def_required}->{Class}->{$uri} ||= $_;
      }
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:subsetOf>, $ln, %opt)) {
      my $uri = dis_typeforqnames_to_uri ($_->value, use_default_namespace => 1,
                                          %opt, node => $_,
                                          use_default_type => $cls->{NameURI});
      if (not defined $cls->{URI} or $uri ne $cls->{URI}) {
        $State->{def_required}->{Class}->{$uri} ||= $_;
        my @from = grep {$cls->{ExpandedURI q<d:supersetOf>}->{$_}}
                   keys %{$cls->{ExpandedURI q<d:supersetOf>}};
        push @from, $cls->{URI} if defined $cls->{URI};
        my @to = $uri, grep {$State->{Type}->{$uri}->{subsetOf}->{$_}}
                       keys %{$State->{Type}->{$uri}->{subsetOf}};
        for my $from (@from) {
          for my $to (@to) {
            $State->{Type}->{$from}->{subsetOf}->{$to} = 1;
            $State->{Type}->{$to}->{ExpandedURI q<d:supersetOf>}->{$from} = 1;
          }
        }
      }
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:Implement>, $ln, %opt)) {
      my $uri = dis_typeforqnames_to_uri ($_->value, use_default_namespace => 1,
                                          %opt, node => $_,
                                          use_default_type => $cls->{NameURI});
      if (not defined $cls->{URI} or $uri ne $cls->{URI}) {
        push @{$cls->{Implement}||=[]}, $uri;
        $State->{def_required}->{Class}->{$uri} ||= $_;
      }
    } elsif (not $is_multiresource and
             dis_uri_ctype_match (ExpandedURI q<d:ResourceDef>, $ln, %opt)) {
      my $p = $al ? 0 : 1;
      if ($al) {
        my $ac = dis_get_attr_node (%opt, parent => $_, 
                                    name => 'aliasChild');
        $p = 1 if $ac and $ac->value;
      }
      if ($p) {
        local $State->{current_class_container} = $cls;
        local $State->{multiple_resource_parent} = {};
        dis_load_classdef_element ($_, %opt);
      }
    }
  }
  unless (keys %{$cls->{Type}}) {
    valid_err (q<Class type must be specified>, node => $node);
  }


  if ($is_multiresource) {
    $cls->{Resource} = {}; ## MultipleResource does not have child resource
    for (@{$node->child_nodes}) {
      next unless $_->node_type eq '#element';
      next unless dis_node_for_match ($_, $opt{For}, %opt);
      if (dis_element_type_match ($_->local_name, 'resourceFor', %opt)) {
        my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                    %opt, node => $_);
        $State->{def_required}->{For}->{$uri} ||= 1;
        local $opt{'For+'} = [@{$opt{'For+'}||[]}, $uri];
        local $State->{multiple_resource_parent} = $cls;
        dis_load_classdef_element ($node, %opt);
      }
    }
  }
}}

=item dis_check_undef_type_and_for (%opt)

Report an error if a type or for URI remains undefined.

=cut

sub dis_check_undef_type_and_for (%) {
  my %opt = @_;
  for my $type (keys %{$State->{def_required}}) {
    for (keys %{$State->{def_required}->{$type}}) {
      if (ref $State->{def_required}->{$type}->{$_} or
          $State->{def_required}->{$type}->{$_} > 0) {
        valid_err (qq<Definition for $type <$_> is required>,
                   node => ref $State->{def_required}->{$type}->{$_}
                           ? $State->{def_required}->{$type}->{$_} : undef);
      }
    }
  }
}



=back

=cut

=head2 APPLICATION-SPECIFIC FUNCTIONS

Application-specific initializations and operations. 
These functions should be used after C<dis_check_undef_type_and_for> 
is done.

=head3 Perl-specific Functions

=over 4

=item dis_perl_init ($root_node, %opt)

Read Perl-specific basic properties.

=cut

sub dis_perl_init ($;%) {
  my ($src, %opt) = @_;
  ## Perl package name
  for my $mod (values %{$State->{Module}}) {
    next if $mod->{ExpandedURI q<dis2pm:done>};
    local $opt{For} = [keys %{$mod->{For}}]->[0];
    local $opt{'For+'} = [keys %{$mod->{'For+'}}];
    local $State->{module} = $mod->{URI};
    local $State->{Namespace} = $mod->{nsBinding};
    ## Perl package name
    my $mg = $State->{Type}->{$mod->{ModuleGroup}};
    my $an = dis_get_attr_node (%opt, parent => $mg->{src}, name => 'AppName');
    if ($an) {
      my $pn = $an->value;
      $pn =~ s/(?:::)+$//;
      $pn .= '::' . $mod->{Name};
      my $suffix = dis_get_attr_node
                      (%opt, parent => $an, 
                       name => {uri => ExpandedURI q<ManakaiDOM:moduleSuffix>});
      $pn .= $suffix->value if $suffix;
      $mod->{ExpandedURI q<dis2pm:packageName>} = $pn;
    }
    ## Perl interface name
    my $if = dis_get_attr_node (%opt, parent => $mod->{src}, name => 'AppName',
                                'For+' => [ExpandedURI q<ManakaiDOM:ForIF>],
                                ContentType => ExpandedURI q<lang:Perl>) ||
             dis_get_attr_node (%opt, parent => $mod->{src}, name => 'AppName',
                                'For+' => [ExpandedURI q<ManakaiDOM:ForIF>],
                                ContentType => ExpandedURI q<lang:Java>) ||
             dis_get_attr_node (%opt, parent => $mg->{src}, name => 'AppName',
                                'For+' => [ExpandedURI q<ManakaiDOM:ForIF>],
                                ContentType => ExpandedURI q<lang:Perl>) ||
             dis_get_attr_node (%opt, parent => $mg->{src}, name => 'AppName',
                                'For+' => [ExpandedURI q<ManakaiDOM:ForIF>],
                                ContentType => ExpandedURI q<lang:Java>);
    if ($if) {
      my $if_name = $if->value;
      $if_name =~ s/\./::/g;
      $if_name =~ s/(?:::)+$//;
      $mod->{ExpandedURI q<dis2pm:ifPackagePrefix>} = $if_name . '::';
    }
    $mod->{ExpandedURI q<dis2pm:done>} = 1;
  }  

  for my $res (values %{$State->{Resource}}) {
    next if $res->{ExpandedURI q<dis2pm:done>};
    next unless defined $res->{Name};
    local $State->{ExpandedURI q<dis2pm:parentResource>}
             = $State->{Module}->{$res->{parentModule}};
    dis_perl_init_classdef ($res, %opt);
  }
} # dis_perl_init

=item dis_perl_init_classdef ($resource, %opt)

Load Perl-specific properties for class.

=cut

sub dis_perl_init_classdef ($;%);
sub dis_perl_init_classdef ($;%) {
  my ($res, %opt) = @_;
  local $opt{For} = [keys %{$res->{For}}]->[0];
  local $opt{'For+'} = [keys %{$res->{'For+'}}];
  local $State->{module} = $res->{parentModule};
  my $mod = $State->{Module}->{$res->{parentModule}};
  local $State->{Namespace} = $mod->{nsBinding};

  ## Check resource type
  my $type = $res->{ExpandedURI q<dis2pm:type>} || '';
  TYPES: for (
         ExpandedURI q<DISLang:Method>,
         ExpandedURI q<DISLang:Attribute>,
         ExpandedURI q<DISLang:MethodParameter>,
         ExpandedURI q<DISLang:MethodReturn>,
         ExpandedURI q<DISLang:AttributeGet>,
         ExpandedURI q<DISLang:AttributeSet>,
         (defined $mod->{ExpandedURI q<dis2pm:packageName>} ?
           (ExpandedURI q<ManakaiDOM:WarningClass>,
            ExpandedURI q<ManakaiDOM:ExceptionClass>,
            ExpandedURI q<DOMMain:ErrorClass>,
            ExpandedURI q<ManakaiDOM:Class>,
            ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>) : ()),
         (defined $mod->{ExpandedURI q<dis2pm:ifPackagePrefix>} ?
           (ExpandedURI q<ManakaiDOM:ExceptionIF>,
            ExpandedURI q<ManakaiDOM:IF>) : ()),
         ExpandedURI q<ManakaiDOM:ConstGroup>,
         ExpandedURI q<ManakaiDOM:Const>,
         ExpandedURI q<ManakaiDOM:InCase>,
         ExpandedURI q<ManakaiDOM:DataType>,
         ExpandedURI q<DOMMain:DOMFeature>,
         ExpandedURI q<DISPerl:ScalarVariable>) {
    for my $t (keys %{$res->{Type}}) {
      if (dis_uri_ctype_match ($_, $t, %opt)) {
        $type = $_;
        last TYPES;
      }
    }
  }
  $res->{ExpandedURI q<dis2pm:type>} = $type;

  my $pack;
  if ({
       ExpandedURI q<ManakaiDOM:Class> => 1,
       ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
       ExpandedURI q<DOMMain:ErrorClass> => 1,
       ExpandedURI q<ManakaiDOM:WarningClass> => 1,
      }->{$type}) {
    ## Class package name
    $pack = $State->{Module}->{$res->{parentModule}}
                  ->{ExpandedURI q<dis2pm:packageName>};
    valid_err ("Perl package name for <$res->{parentModule}> not defined",
               node => $res->{src})
      unless defined $pack;
    my $an = dis_get_attr_node (%opt, parent => $res->{src}, name => 'AppName',
                                ContentType => ExpandedURI q<Perl:package-name>);
    if ($an) {
      $pack = $res->{ExpandedURI q<dis2pm:packageName>}
            = $an->value;
    } else {
      $an = dis_get_attr_node (%opt, parent => $res->{src}, name => 'AppName');
      if ($an) {
        $pack = $res->{ExpandedURI q<dis2pm:packageName>}
              = $pack . '::' . $an->value;
      } else {
        valid_err ("Class name required", node => $res->{src})
          unless $res->{Name};
        $pack = $res->{ExpandedURI q<dis2pm:packageName>}
              = $pack . '::' . $res->{Name};
      }
    }
    ## This class implements...
    if ($res->{multiple_resource_parent}) {
      IF: for my $if (@{$res->{multiple_resource_parent}->{hasResource}}) {
        for my $iftypeuri (keys %{$if->{Type}}) {
          if (dis_uri_ctype_match ({
                ExpandedURI q<ManakaiDOM:Class> => ExpandedURI q<ManakaiDOM:IF>,
                ExpandedURI q<DOMMain:ErrorClass>
                                     => ExpandedURI q<ManakaiDOM:IF>,
                ExpandedURI q<ManakaiDOM:ExceptionClass>
                                     => ExpandedURI q<ManakaiDOM:ExceptionIF>,
                ExpandedURI q<ManakaiDOM:WarningClass> => 'dummy',
                                   }->{$type}, $iftypeuri, %opt)) {
            ## Commented out because it has bug...
            #push @{$res->{Implement}||=[]}, $if->{URI};
            last IF;
          }
        }
      }
    }
  } elsif ({
            ExpandedURI q<ManakaiDOM:IF> => 1,
            ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
           }->{$type}) {
    ## Interface package name is...
    $pack = $State->{Module}->{$res->{parentModule}}
                     ->{ExpandedURI q<dis2pm:ifPackagePrefix>};
    valid_err ("Perl interface package name for <$res->{parentModule}> not ".
               "defined", node => $res->{src})
      unless defined $pack;
    my $an = dis_get_attr_node (%opt, parent => $res->{src}, name => 'AppName',
                                ContentType => ExpandedURI q<lang:Java>);
    if ($an) {
      $an = $an->value;
      if ($an =~ /\./) {
        $an =~ s/\./::/g;
        $pack = $res->{ExpandedURI q<dis2pm:packageName>} = $an;
      } else {
        $pack = $res->{ExpandedURI q<dis2pm:packageName>} = $pack . $an;
      }
    } else {
      valid_err ("Interface name required", node => $res->{src})
        unless $res->{Name};
      $pack = $res->{ExpandedURI q<dis2pm:packageName>} = $pack . $res->{Name};
    }    
  } elsif ({
            ExpandedURI q<DISLang:Method> => 1,
            ExpandedURI q<DISLang:Attribute> => 1,
           }->{$type}) {
    ## - Method or attribute name
    my $name = dis_camelCase_to_underscore_name $res->{Name};
    
    ## Prefixes "_" if it is an internal method or attribute
    my $int = dis_get_attr_node
                 (%opt, name => {uri => ExpandedURI q<ManakaiDOM:isForInternal>},
                  parent => $res->{src});
    if ($int and $int->value) {
      $res->{ExpandedURI q<ManakaiDOM:isForInternal>} = 1;
      $name = '_' . $name if length $name;
    }
    
    ## Checks against special-purpose method names
    if ({
         import => 1,
         unimport => 1,
         isa => 1,
         can => 1,
         new => 1,
         as_string => 1,
         stringify => 1,
         clone => 1,
        }->{$name} or $name =~ /^___/) {
      valid_err (qq<Method name "$name" is reserved>,
                 node => $res->{src});
    }
    
    $res->{ExpandedURI q<dis2pm:methodName>} = $name;
    
    my $re = dis_get_attr_node
                 (%opt, name => {uri => ExpandedURI q<ManakaiDOM:isRedefining>},
                  parent => $res->{src});
    if ($re and $re->value) {
      $res->{ExpandedURI q<ManakaiDOM:isRedefining>} = 1;
    }
    
    ## Value type
    my $t = dis_get_attr_node (%opt, name => 'Type', parent => $res->{src});
    if ($t) {
      $res->{ExpandedURI q<d:Type>}
        = dis_typeforqnames_to_type_uri ($t->value, use_default_namespace => 1,
                                         %opt, node => $t);
      $res->{ExpandedURI q<dis2pm:TypeNode>} = $t;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (defined $pr->{ExpandedURI q<d:Type>}) {
        $res->{ExpandedURI q<d:Type>} = $pr->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:TypeNode>}
          = $pr->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }
    my $i = dis_get_attr_node (%opt, name => 'actualType',
                               parent => $res->{src});
    if ($i) {
      $res->{ExpandedURI q<d:actualType>}
        = dis_typeforqnames_to_type_uri ($i->value, use_default_namespace => 1,
                                         %opt, node => $i);
      $res->{ExpandedURI q<dis2pm:actualTypeNode>} = $i;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (not $t and defined $pr->{ExpandedURI q<d:actualType>}) {
        $res->{ExpandedURI q<d:actualType>} = $pr->{ExpandedURI q<d:actualType>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $pr->{ExpandedURI q<dis2pm:actualTypeNode>};
      } else {
        $res->{ExpandedURI q<d:actualType>} = $res->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $res->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }

    ## Register the method
    if (length $name) {
      valid_err (qq<Perl method "$name" already defined>, node => $res->{node})
        if defined $State->{ExpandedURI q<dis2pm:parentResource>}
                         ->{ExpandedURI q<dis2pm:method>}->{$name}->{Name};
    } else {
      my $i = 0;
      $i++ while defined $State->{ExpandedURI q<dis2pm:parentResource>}
                               ->{ExpandedURI q<dis2pm:method>}
                               ->{'#anon'.$i};
      $name = '#anon'.$i;
    }
    $res->{ExpandedURI q<dis2pm:methodName+>} = $name;
    $State->{ExpandedURI q<dis2pm:parentResource>}
          ->{ExpandedURI q<dis2pm:method>}->{$name} = $res;
  } elsif ({ExpandedURI q<DISLang:MethodReturn> => 1,
            ExpandedURI q<DISLang:AttributeGet> => 1,
            ExpandedURI q<DISLang:AttributeSet> => 1}->{$type}) {
    ## Value type
    my $t = dis_get_attr_node (%opt, name => 'Type', parent => $res->{src});
    if ($t) {
      $res->{ExpandedURI q<d:Type>}
        = dis_typeforqnames_to_type_uri ($t->value, use_default_namespace => 1,
                                         %opt, node => $t);
      $res->{ExpandedURI q<dis2pm:TypeNode>} = $t;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (defined $pr->{ExpandedURI q<d:Type>}) {
        $res->{ExpandedURI q<d:Type>} = $pr->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:TypeNode>} 
          = $pr->{ExpandedURI q<dis2pm:TypeNode>};
      } else {
        if ({
             ExpandedURI q<DISLang:AttributeGet> => 1,
             ExpandedURI q<DISLang:AttributeSet> => 1,
            }->{$type}) {
          valid_err (q<Attribute value type must be declared>,
                     node => $res->{src});
        }
      }
    }
    my $i = dis_get_attr_node (%opt, name => 'actualType',
                               parent => $res->{src});
    if ($i) {
      $res->{ExpandedURI q<d:actualType>}
        = dis_typeforqnames_to_type_uri ($i->value, use_default_namespace => 1,
                                         %opt, node => $i);
      $res->{ExpandedURI q<dis2pm:actualTypeNode>} = $i;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (not $t and defined $pr->{ExpandedURI q<d:actualType>}) {
        $res->{ExpandedURI q<d:actualType>} = $pr->{ExpandedURI q<d:actualType>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $pr->{ExpandedURI q<dis2pm:actualTypeNode>};
      } else {
        $res->{ExpandedURI q<d:actualType>} = $res->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $res->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }

    my $p = {ExpandedURI q<DISLang:MethodReturn>
              => ExpandedURI q<dis2pm:return>,
             ExpandedURI q<DISLang:AttributeGet>
              => ExpandedURI q<dis2pm:getter>,
             ExpandedURI q<DISLang:AttributeSet>
              => ExpandedURI q<dis2pm:setter>};
    valid_err (qq{<$p->{$type}> already defined}, node => $res->{node})
      if defined $State->{ExpandedURI q<dis2pm:parentResource>}
                       ->{$p->{$type}}->{Name};
    $State->{ExpandedURI q<dis2pm:parentResource>}
          ->{$p->{$type}} = $res;
  } elsif ({ExpandedURI q<DISLang:MethodParameter> => 1}->{$type}) {
    ## Parameter name
    valid_err (qq<Parameter name required>, node => $res->{src})
      unless $res->{Name};
    my $name = $res->{Name};
    $res->{ExpandedURI q<dis2pm:paramName>} = $name;

    ## Parameter value type
    my $t = dis_get_attr_node (%opt, name => 'Type', parent => $res->{src});
    valid_err (q<Parameter type required>, node => $res->{src})
      unless $t;
    $res->{ExpandedURI q<d:Type>}
      = dis_typeforqnames_to_type_uri ($t->value, use_default_namespace => 1,
                                       %opt, node => $t);
    $res->{ExpandedURI q<dis2pm:TypeNode>} = $t;
    my $i = dis_get_attr_node (%opt, name => 'actualType',
                               parent => $res->{src});
    if ($i) {
      $res->{ExpandedURI q<d:actualType>}
        = dis_typeforqnames_to_type_uri ($i->value, use_default_namespace => 1,
                                         %opt, node => $i);
      $res->{ExpandedURI q<dis2pm:actualTypeNode>} = $i;
    } else {
      $res->{ExpandedURI q<d:actualType>} = $res->{ExpandedURI q<d:Type>};
      $res->{ExpandedURI q<dis2pm:actualTypeNode>}
        = $res->{ExpandedURI q<dis2pm:TypeNode>};
    }

    ## Input or output?
    my $read = dis_get_attr_node (%opt, name => 'Read', parent => $res->{src});
    $res->{ExpandedURI q<d:Read>} = ($read and $read->value) ? 1 : 0;
    my $write = dis_get_attr_node (%opt, name => 'Write', parent => $res->{src});
    $res->{ExpandedURI q<d:Write>} = ($write and not $write->value) ? 0 : 1;

    if ($res->{ExpandedURI q<d:Write>} and
        dis_uri_ctype_match ($res->{ExpandedURI q<d:actualType>},
                             ExpandedURI q<DOMMain:boolean>, %opt)) {
      $res->{ExpandedURI q<dis2pm:nullable>} = 1;
    }
    
    ## Register the parameter
    push @{$State->{ExpandedURI q<dis2pm:parentResource>}
                 ->{ExpandedURI q<dis2pm:param>}||=[]}, $res;
  } elsif ({ExpandedURI q<ManakaiDOM:ConstGroup> => 1}->{$type}) {
    ## Constant group name
    my $name = $res->{Name};
    $res->{ExpandedURI q<dis2pm:constGroupName>} = $name;

    ## Value type
    my $t = dis_get_attr_node (%opt, name => 'Type', parent => $res->{src});
    if ($t) {
      $res->{ExpandedURI q<d:Type>}
        = dis_typeforqnames_to_type_uri ($t->value, use_default_namespace => 1,
                                         %opt, node => $t);
      $res->{ExpandedURI q<dis2pm:TypeNode>} = $t;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (defined $pr->{ExpandedURI q<d:Type>}) {
        $res->{ExpandedURI q<d:Type>} = $pr->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:TypeNode>}
          = $pr->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }
    my $i = dis_get_attr_node (%opt, name => 'actualType',
                               parent => $res->{src});
    if ($i) {
      $res->{ExpandedURI q<d:actualType>}
        = dis_typeforqnames_to_type_uri ($i->value, use_default_namespace => 1,
                                         %opt, node => $i);
      $res->{ExpandedURI q<dis2pm:actualTypeNode>} = $i;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (not $t and defined $pr->{ExpandedURI q<d:actualType>}) {
        $res->{ExpandedURI q<d:actualType>} = $pr->{ExpandedURI q<d:actualType>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $pr->{ExpandedURI q<dis2pm:actualTypeNode>};
      } else {
        $res->{ExpandedURI q<d:actualType>} = $res->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $res->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }
    
    ## Register the constant group
    if (defined $name) {
      if (defined $State->{ExpandedURI q<dis2pm:parentResource>}
                        ->{ExpandedURI q<dis2pm:constGroup>}->{$name}->{Name}) {
        valid_err (qq<Constant group "$name" already defined >.
                   qq{[<$State->{ExpandedURI q<dis2pm:parentResource>
                          }->{ExpandedURI q<dis2pm:constGroup>}->{$name
                          }->{URI}>, <$res->{URI}>]},
                   node => $res->{src});
      }
    } else {
      my $i = 0;
      ++$i while defined $State->{ExpandedURI q<dis2pm:parentResource>}
                           ->{ExpandedURI q<dis2pm:constGroup>}->{$i}->{Name};
      $name = $i;
    }
    $res->{ExpandedURI q<dis2pm:parentResource>}
      = $State->{ExpandedURI q<dis2pm:parentResource>};
    $res->{ExpandedURI q<dis2pm:grandParentResource>}
        ->{ExpandedURI q<dis2pm:xConstGroup>}
        ->{$res} = $res;
    $State->{ExpandedURI q<dis2pm:parentResource>}
          ->{ExpandedURI q<dis2pm:constGroup>}->{$name} = $res;
  } elsif ({ExpandedURI q<ManakaiDOM:Const> => 1}->{$type}) {
    ## - Error severity - if specified, this const defines an error code
    my $es = dis_get_attr_node (%opt,
                                name => {uri => ExpandedURI q<DOMCore:severity>},
                                parent => $res->{src});
    if ($es) {
      my $v = $es->value;
      valid_err (qq<Error severity "$v" is invalid>, node => $es)
        unless {Warning => 1, Error => 1, FatalError => 1}->{$v};
      $res->{ExpandedURI q<DOMCore:severity>} = $v;
    }

    ## - Constant value name
    valid_err (qq<Constant value name required>, node => $res->{src})
      unless $res->{Name};
    if ($es) {
      my $ename = dis_get_attr_node (%opt, parent => $res->{src},
                                     name => 'AppName',
                                     ContentType =>
                                       ExpandedURI q<DOMCore:DOMErrorType>);
      my $v;
      if ($ename) {
        $v = $ename->value;
        $res->{ExpandedURI q<DOMCore:type>} = $v;
      } else {
        valid_err (q<DOMError type must have its URI>, node => $res->{src})
          unless defined $res->{NameURI};
        $v = $res->{NameURI};
      }
      $res->{ExpandedURI q<DOMCore:type>} = $v;
    }
    ## Const name
    my $name = uc $res->{Name};
    $name =~ tr/-/_/;
    $res->{ExpandedURI q<dis2pm:constName>} = $name;

    ## - Value type
    my $t = dis_get_attr_node (%opt, name => 'Type', parent => $res->{src});
    if ($t) {
      $res->{ExpandedURI q<d:Type>}
        = dis_typeforqnames_to_type_uri ($t->value, use_default_namespace => 1,
                                         %opt, node => $t);
      $res->{ExpandedURI q<dis2pm:TypeNode>} = $t;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (defined $pr->{ExpandedURI q<d:Type>}) {
        $res->{ExpandedURI q<d:Type>} = $pr->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:TypeNode>}
          = $pr->{ExpandedURI q<dis2pm:TypeNpde>};
      } else {
        valid_err (q<Constant value type required>, node => $res->{src});
      }
    }
    my $i = dis_get_attr_node (%opt, name => 'actualType',
                               parent => $res->{src});
    if ($i) {
      $res->{ExpandedURI q<d:actualType>}
        = dis_typeforqnames_to_type_uri ($i->value, use_default_namespace => 1,
                                         %opt, node => $i);
      $res->{ExpandedURI q<dis2pm:actualTypeNode>} = $i;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (not $t and defined $pr->{ExpandedURI q<d:actualType>}) {
        $res->{ExpandedURI q<d:actualType>} = $pr->{ExpandedURI q<d:actualType>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $pr->{ExpandedURI q<dis2pm:actualTypeNode>};
      } else {
        $res->{ExpandedURI q<d:actualType>} = $res->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $res->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }
    
    ## Register the constant value
    my @p;
    {no warnings 'uninitialized';
      $res->{ExpandedURI q<dis2pm:parentResource>}
        = $State->{ExpandedURI q<dis2pm:parentResource>};
      if ({
           ExpandedURI q<ManakaiDOM:ConstGroup> => 1,
           ExpandedURI q<ManakaiDOM:Class> => 1,
           ExpandedURI q<ManakaiDOM:IF> => 1,
           ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
           ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
           ExpandedURI q<DOMMain:ErrorClass> => 1,
           ExpandedURI q<ManakaiDOM:WarningClass> => 1,
          }->{$res->{ExpandedURI q<dis2pm:parentResource>}
                  ->{ExpandedURI q<dis2pm:type>}}) {
        push @p, $res->{ExpandedURI q<dis2pm:parentResource>};
      }
      $res->{ExpandedURI q<dis2pm:grandParentResource>}
        = $State->{ExpandedURI q<dis2pm:parentResource>}
                ->{ExpandedURI q<dis2pm:parentResource>};
      if ({
           ExpandedURI q<ManakaiDOM:Class> => 1,
           ExpandedURI q<ManakaiDOM:IF> => 1,
           ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
           ExpandedURI q<ManakaiDOM:ExceptionIF> => 1,
           ExpandedURI q<DOMMain:ErrorClass> => 1,
           ExpandedURI q<ManakaiDOM:WarningClass> => 1,
          }->{$res->{ExpandedURI q<dis2pm:grandParentResource>}
                  ->{ExpandedURI q<dis2pm:type>}}) {
        push @p, $res->{ExpandedURI q<dis2pm:grandParentResource>};
      }
      $res->{ExpandedURI q<dis2pm:grandParentResource>}
          ->{ExpandedURI q<dis2pm:xConstGroup>}
          ->{$res->{ExpandedURI q<dis2pm:parentResource>}}
            = $res->{ExpandedURI q<dis2pm:parentResource>};
      $res->{ExpandedURI q<dis2pm:grandParentResource>}
          ->{ExpandedURI q<dis2pm:xConst>}
          ->{$res} = $res;
    }
    for (@p) {
      if (defined $_->{ExpandedURI q<dis2pm:const>}->{$name}->{Name}) {
        valid_err (qq<Constant value "$name" already defined in >.
                   q<the same scope>, node => $res->{src});
      }
      $_->{ExpandedURI q<dis2pm:const>}->{$name} = $res;
    }
  } elsif ({ExpandedURI q<ManakaiDOM:InCase> => 1}->{$type}) {
    ## Value type
    my $t = dis_get_attr_node (%opt, name => 'Type', parent => $res->{src});
    if ($t) {
      $res->{ExpandedURI q<d:Type>}
        = dis_typeforqnames_to_type_uri ($t->value, use_default_namespace => 1,
                                         %opt, node => $t);
      $res->{ExpandedURI q<dis2pm:TypeNode>} = $t;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (defined $pr->{ExpandedURI q<d:Type>}) {
        $res->{ExpandedURI q<d:Type>} = $pr->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:TypeNode>} 
          = $pr->{ExpandedURI q<dis2pm:TypeNode>};
      } elsif ($pr->{ExpandedURI q<dis2pm:type>} eq 
               ExpandedURI q<ManakaiDOM:DataType>) {
        $res->{ExpandedURI q<d:Type>} = $pr->{URI};
        $res->{ExpandedURI q<dis2pm:TypeNode>} = $pr->{src};
      } else {
        valid_warn (q<InCase value type required>, node => $res->{src});
      }
    }
    my $i = dis_get_attr_node (%opt, name => 'actualType',
                               parent => $res->{src});
    if ($i) {
      $res->{ExpandedURI q<d:actualType>}
        = dis_typeforqnames_to_type_uri ($i->value, use_default_namespace => 1,
                                         %opt, node => $i);
      $res->{ExpandedURI q<dis2pm:actualTypeNode>} = $i;
    } else {
      my $pr = $State->{ExpandedURI q<dis2pm:parentResource>};
      if (not $t and defined $pr->{ExpandedURI q<d:actualType>}) {
        $res->{ExpandedURI q<d:actualType>} = $pr->{ExpandedURI q<d:actualType>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $pr->{ExpandedURI q<dis2pm:actualTypeNode>};
      } else {
        $res->{ExpandedURI q<d:actualType>} = $res->{ExpandedURI q<d:Type>};
        $res->{ExpandedURI q<dis2pm:actualTypeNode>}
          = $res->{ExpandedURI q<dis2pm:TypeNode>};
      }
    }
    
    ## Value
    my $v = dis_get_attr_node (%opt, name => 'Value', parent => $res->{src},
                               ContentType => ExpandedURI q<lang:dis>);
    if ($v) {
      my $null = dis_get_attr_node (%opt, name => 'is-null', parent => $v);
      if ($null and $null->value) {
        $State->{ExpandedURI q<dis2pm:parentResource>}
              ->{ExpandedURI q<dis2pm:nullable>} = 1;
        $res->{ExpandedURI q<dis2pm:valueIsNull>} = 1;
      }
    }
    
    ## Register the InCase
    push @{$State->{ExpandedURI q<dis2pm:parentResource>}
                 ->{ExpandedURI q<dis2pm:inCase>}||=[]}, $res;
  } elsif ({ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType> => 1}->{$type}) {
    ## - Error severity - if specified, this const defines an error code
    my $es = dis_get_attr_node (%opt,
                                name => {uri => ExpandedURI q<DOMCore:severity>},
                                parent => $res->{src});
    if ($es) {
      my $v = $es->value;
      valid_err (qq<Error severity "$v" is invalid>, node => $es)
        unless {Warning => 1, Error => 1, FatalError => 1}->{$v};
      $res->{ExpandedURI q<DOMCore:severity>} = $v;
    }

    ## - Subtype name
    valid_err (qq<Subtype URI required>, node => $res->{src})
      unless defined $res->{NameURI};
    if ($es) {
      my $ename = dis_get_attr_node (%opt, parent => $res->{src},
                                     name => 'AppName',
                                     ContentType =>
                                       ExpandedURI q<DOMCore:DOMErrorType>);
      my $v;
      if ($ename) {
        $v = $ename->value;
        $res->{ExpandedURI q<DOMCore:type>} = $v;
      } elsif (defined $State->{ExpandedURI q<dis2pm:parentResource>}
                             ->{ExpandedURI q<DOMCore:type>}) {
        $v = $State->{ExpandedURI q<dis2pm:parentResource>}
                   ->{ExpandedURI q<DOMCore:type>};
      } else {
        $v = $res->{NameURI};
      }
      $res->{ExpandedURI q<DOMCore:type>} = $v;
    }

    ## - Parent exception class/type
    $res->{ExpandedURI q<dis2pm:parentResource>}
      = $State->{ExpandedURI q<dis2pm:parentResource>};
    $res->{ExpandedURI q<dis2pm:grandParentResource>}
      = $res->{ExpandedURI q<dis2pm:parentResource>}
              ->{ExpandedURI q<dis2pm:parentResource>};
    $res->{ExpandedURI q<dis2pm:grandGrandParentResource>}
      = $res->{ExpandedURI q<dis2pm:grandParentResource>}
              ->{ExpandedURI q<dis2pm:parentResource>};
    {
      no warnings 'uninitialized';
      valid_err qq{Parent of an exception/warning subtype <$res->{URI}> }.
                qq{[<$res->{ExpandedURI q<dis2pm:parentResource>
                         }->{ExpandedURI q<dis2pm:type>}>] }.
                qq{must be a "ManakaiDOM:Const"}, node => $res->{src}
            unless $res->{ExpandedURI q<dis2pm:parentResource>}
                       ->{ExpandedURI q<dis2pm:type>} eq
                   ExpandedURI q<ManakaiDOM:Const>;
      valid_err qq{Grandparent of an exception/warning subtype <$res->{URI}> }.
                qq{[<$res->{ExpandedURI q<dis2pm:grandParentResource>
                         }->{ExpandedURI q<dis2pm:type>}>] }.
                qq{must be a "ManakaiDOM:ConstGroup"}, node => $res->{src}
            unless $res->{ExpandedURI q<dis2pm:grandParentResource>}
                       ->{ExpandedURI q<dis2pm:type>} eq
                   ExpandedURI q<ManakaiDOM:ConstGroup>;
      valid_err qq{Parent pf grandparent of an exception/warning subtype }.
                qq{<$res->{URI}> }.
                qq{[<$res->{ExpandedURI q<dis2pm:grandGrandParentResource>
                         }->{ExpandedURI q<dis2pm:type>}>] }.
                qq{must be a "ManakaiDOM:ExceptionClass"}, node => $res->{src}
            unless {
                     ExpandedURI q<ManakaiDOM:ExceptionClass> => 1,
                     ExpandedURI q<DOMMain:ErrorClass> => 1,
                     ExpandedURI q<ManakaiDOM:WarningClass> => 1,
                   }->{$res->{ExpandedURI q<dis2pm:grandGrandParentResource>}
                           ->{ExpandedURI q<dis2pm:type>}};              
    }
    $res->{ExpandedURI q<dis2pm:grandGrandParentResource>}
        ->{ExpandedURI q<dis2pm:xConstGroup>}
        ->{$res->{ExpandedURI q<dis2pm:grandParentResource>}}
          = $res->{ExpandedURI q<dis2pm:grandParentResource>};
    $res->{ExpandedURI q<dis2pm:grandGrandParentResource>}
        ->{ExpandedURI q<dis2pm:xConst>}
        ->{$res->{ExpandedURI q<dis2pm:parentResource>}}
          = $res->{ExpandedURI q<dis2pm:parentResource>};
    $res->{ExpandedURI q<dis2pm:grandGrandParentResource>}
        ->{ExpandedURI q<dis2pm:xSubType>}
        ->{$res} = $res;

    $State->{ExpandedURI q<dis2pm:parentResource>}
          ->{ExpandedURI q<dis2pm:xSubType>}->{$res->{NameURI}} = $res;
  } elsif ($type eq ExpandedURI q<DOMMain:DOMFeature>) {
    ## Feature name/version
    valid_err (q<Feature requires its URI reference>, node => $res->{node})
      unless defined $res->{URI};
    my $has_name = 0;
    for (@{$res->{src}->child_nodes}) {
      next unless $_->node_type eq '#element';
      next unless dis_node_for_match ($_, $opt{For}, %opt);
      my $et = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
      my $fn;
      if ($et eq ExpandedURI q<d:AppName>) {
        my $ct = dis_get_attr_node (%opt, parent => $_, name => 'ContentType');
        my $ctu = dis_qname_to_uri ($ct->value, %opt, node => $ct,
                                    use_default_namespace => 1);
        if (dis_uri_ctype_match (ExpandedURI q<d:TypeQName>,
                                  $ctu, %opt)) {
          $fn = dis_qname_to_uri ($_->value, %opt, node => $_,
                                  use_default_namespace => 1);
        } elsif (dis_uri_ctype_match (ExpandedURI q<d:String>,
                                       $ctu, %opt)) {
          $fn = $_->value;
        }
      } elsif ($et eq ExpandedURI q<d:Version>) {
        $res->{ExpandedURI q<d:Version>} = $_->value;
      }
      if (defined $fn) {
        $res->{ExpandedURI q<dis2pm:featureName>}->{lc $fn} = 1;
        $has_name = 1;
      }
    }
    unless ($has_name) {
      for (keys %{$State->{ExpandedURI q<dis2pm:parentResource>}
                        ->{ExpandedURI q<dis2pm:featureName>}||{}}) {
        $res->{ExpandedURI q<dis2pm:featureName>}->{$_} = 1;
        $has_name = 1;
      }
    }
    unless ($has_name) {
      if (defined $res->{NameURI}) {
        $res->{ExpandedURI q<dis2pm:featureName>}->{lc $res->{NameURI}} = 1;
      } elsif (length $res->{Name}) {
        $res->{ExpandedURI q<dis2pm:featureName>}->{lc $res->{Name}} = 1;
      } else {
        valid_err (q<Feature name is required>, node => $res->{src});
      }
    }

    ## Register this feature
    $State->{Module}->{$State->{module}}
                    ->{ExpandedURI q<dis2pm:feature>}->{$res->{URI}} = $res;
  } elsif ($type eq ExpandedURI q<DISPerl:ScalarVariable>) {
    ## Variable name
    my $an = dis_get_attr_node (%opt, parent => $res->{src}, name => 'AppName',
                                ContentType => ExpandedURI q<lang:Perl>);
    if ($an) {
      $res->{ExpandedURI q<dis2pm:variableName>} = $an->value;
    } elsif (length $res->{Name}) {
      $res->{ExpandedURI q<dis2pm:variableName>} = $res->{Name};
    } else {
      valid_err (q<Variable name is required>, node => $res->{src});
    }

    $res->{ExpandedURI q<dis2pm:variableType>} = '$';
    
    ## ISSUE: Variable scope

    my $xp = dis_get_attr_node
                   (%opt, parent => $res->{src},
                    name => {uri => ExpandedURI q<DISPerl:isExportOK>});
    if ($xp and $xp->value) {
      $res->{ExpandedURI q<DISPerl:isExportOK>} = 1;
    }
    
    my $var = $State->{ExpandedURI q<dis2pm:parentResource>}
                    ->{ExpandedURI q<dis2pm:variable>} ||= {};
    if (defined $var->{$res->{ExpandedURI q<dis2pm:variableName>}}->{Name}) {
      valid_err (qq{Variable "\$$res->{ExpandedURI q<dis2pm:variableName>}" }.
                 q{is already defined}, node => $res->{src});
    }
    $var->{$res->{ExpandedURI q<dis2pm:variableName>}} = $res;
  } # $type
  
  ## Register the package
  if ($pack) {
    valid_err (qq<Perl package "$pack" is already defined>, node => $res->{src})
      if defined $State->{ExpandedURI q<dis2pm:package>}->{$pack}->{Name} and
         $pack !~ /::IF::/;
           ## NOTE: Dupulication is allowed if it is an interface package
           ##       to avoid some bug
    $State->{ExpandedURI q<dis2pm:package>}->{$pack} = $res;
    impl_err (qq<Perl package "$pack" is already defined>, node => $res->{src})
      if defined $State->{Module}->{$res->{parentModule}}
                       ->{ExpandedURI q<dis2pm:package>}->{Pack}->{Name};
    $State->{Module}->{$res->{parentModule}}
          ->{ExpandedURI q<dis2pm:package>}->{$pack} = $res;
  }
  
  ## Validate children
  my $has_def = 0;
  N: for (@{$res->{src}->child_nodes}) {
    next if $_->node_type ne '#element';
    next unless dis_node_for_match ($_, $opt{For}, %opt);
    my $ln = dis_element_type_to_uri ($_->local_name, %opt, node => $_);
    if ($ln eq ExpandedURI q<d:ResourceDef>) {
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:Def>, $ln, %opt)) {
      $has_def = 1;
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<DOMMain:implementFeature>,
                                  $ln, %opt)) {
      my $f = dis_qname_to_uri ($_->value, %opt, node => $_,
                                use_default_namespace => 1);
      valid_err (qq<Feature <$f> must be defined>, node => $_)
        unless defined $State->{Type}->{$f}->{Name};
      $res->{ExpandedURI q<DOMMain:implementFeature>}->{$f} = 1;
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<DOMMain:requireFeature>,
                                  $ln, %opt)) {
      my $f = dis_qname_to_uri ($_->value, %opt, node => $_,
                                use_default_namespace => 1);
      valid_err (qq<Feature <$f> must be defined>, node => $_)
        unless defined $State->{Type}->{$f}->{Name};
      $res->{ExpandedURI q<DOMMain:requireFeature>}->{$f} = 1;
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:Role>, $ln, %opt)) {
      my $f = dis_typeforqnames_to_uri ($_->value, %opt, node => $_,
                                        use_default_namespace => 1);
      valid_err (qq<Interface <$f> must be defined>, node => $_)
        unless defined $State->{Type}->{$f}->{Name};
      my $role = $res->{ExpandedURI q<d:Role>}->{$f} = {Role => $f, node => $_};
      my $c = dis_get_attr_node (%opt, parent => $_, name => 'compat');
      if ($c) {
        $f = dis_typeforqnames_to_uri ($c->value, %opt, node => $c,
                                       use_default_namespace => 1);
        valid_err (qq<Class <$f> must be defined>, node => $_)
          unless defined $State->{Type}->{$f}->{Name};
        $role->{compat} = $f;
      }
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<DOMEvents:createEventType>,
                                  $ln, %opt)) {
      $res->{ExpandedURI q<DOMEvents:createEventType>}->{$_->value} = 1;
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:Operator>, $ln, %opt)) {
      my $t = dis_get_attr_node (%opt, name => 'ContentType', parent => $_);
      if ($t) {
        my $tu = dis_qname_to_uri ($t->value, %opt, node => $t);
        if (dis_uri_ctype_match (ExpandedURI q<lang:Perl>, $tu, %opt)) {
          my $op = $_->value;
          unless ({qw[
                    +  1 -  1 *  1 /  1 %  1 **  1 <<  1 >>  1 x  1 .  1
                    += 1 -= 1 *= 1 /= 1 %= 1 **= 1 <<= 1 >>= 1 x= 1 .= 1
                    <  1 <= 1 >  1 >= 1 == 1 != 1 <=> 1
                    lt 1 le 1 gt 1 ge 1 eq 1 ne 1 cmp 1
                    & 1 | 1 ^ 1 neg 1 ! 1 ~ 1
                    ++ 1 -- 1 = 1
                    atan2 1 cos 1 sin 1 exp 1 abs 1 log 1 sqrt 1
                    bool 1 "" 1 0+ 1 ${} 1 @{} 1 %{} 1 &{} 1 *{} 1 <> 1
                    nomethod 1
                    DESTROY 1
                    TIESCALAR 1 TIEARRAY 1 TIEHASH 1 TIEHANDLE 1 CLOSE 1 UNTIE 1
                    FETCH 1 STORE 1 FIRSTKEY 1 NEXTKEY 1
                    EXISTS 1 DELETE 1 CLEAR 1
                    PUSH 1 POP 1 SHIFT 1 UNSHIFT 1 SPLICE 1
                    FETCHSIZE 1 STORESIZE 1 EXTEND 1 SCALAR 1
                    WRITE 1 PRINT 1 PRINTF 1 READ 1 READLINE 1 GETC 1
                    PUSHED 1 POPED 1 OPEN 1 UTF8 1 BINMODE 1 FDOPEN 1 SYSOPEN 1
                    FILENO 1 FILL 1 SEEK 1 TELL 1UNREAD 1 FLUSH 1
                    SETLINEBUF 1 CLEARERR 1 ERROR 1 EOF 1
                  ]}->{$op}) {
            valid_err qq<Operator "$op" is not supported>, node => $_;
          }
          valid_err qq<Overloading for operator "$op" is already declared>,
            node => $_
              if defined $State->{ExpandedURI q<dis2pm:parentResource>}
                               ->{ExpandedURI q<dis2pm:overload>}->{$op}
                               ->{resource}->{Name};
          $State->{ExpandedURI q<dis2pm:parentResource>}
                ->{ExpandedURI q<dis2pm:overload>}->{$op}
                  = {
                     resource => $res,
                     operator => $op,
                    };
        } elsif (dis_uri_ctype_match (ExpandedURI q<d:TypeQName>, $tu, %opt)) {
          my $op = dis_qname_to_uri ($_->value, %opt, node => $_,
                                     use_default_namespace => 1);
          valid_err qq<Operator <$op> must be defined>, node => $_
            unless defined $State->{Type}->{$op}->{Name};
          valid_err qq<Overloading for operator <$op> is already declared>,
            node => $_
              if defined $State->{ExpandedURI q<dis2pm:parentResource>}
                               ->{ExpandedURI q<d:Operator>}->{$op}
                               ->{resource}->{Name};
          $State->{ExpandedURI q<dis2pm:parentResource>}
                ->{ExpandedURI q<d:Operator>}->{$op}
                  = {
                     resource => $res,
                     operator => $op,
                    };
        } else {
          valid_err qq<<$tu>: Unsupported content type for "dis:Operator">, 
            node => $t;
        }
      } else {
        valid_err q<"dis:ContentType" attribute is required>, node => $_;
      }
      next N;
    } elsif (dis_uri_ctype_match (ExpandedURI q<d:AppISA>, $ln, %opt)) {
      my $t = dis_get_attr_node (%opt, name => 'ContentType', parent => $_);
      if ($t) {
        my $tu = dis_qname_to_uri ($t->value, %opt, node => $t);
        if (dis_uri_ctype_match (ExpandedURI q<lang:Perl>, $tu, %opt)) {
          push @{$res->{ExpandedURI q<dis2pm:AppISA>}||=[]}, $_->value;
          next N;
        }
      }
      valid_err q<Unsupported <dis:AppISA> description>, node => $_;
    }

    if (defined $State->{Type}->{$ln}->{Name}) {
      for (%{$State->{Type}->{$ln}->{Type}}) {
        if (dis_uri_ctype_match (ExpandedURI q<rdf:Property>, $_, %opt)) {
          next N;
        }
      }
    }
    valid_err (qq<<$ln>: Undefined element type>, node => $_);
  } # N

  $res->{ExpandedURI q<DOMMain:implementFeature>}
    ||= $State->{ExpandedURI q<dis2pm:parentResource>}
              ->{ExpandedURI q<DOMMain:implementFeature>};

  ## Child resources
  for my $cres (values %{$res->{Resource}}) {
    next if $cres->{ExpandedURI q<dis2pm:done>};
    next unless defined $cres->{Name};
    local $State->{ExpandedURI q<dis2pm:parentResource>} = $res;
    dis_perl_init_classdef ($cres, %opt);
  }

  if ($type eq ExpandedURI q<DISLang:Method>) {
    valid_err (q<Method "dis:Return" element is required>, node => $res->{src})
      unless defined $res->{ExpandedURI q<dis2pm:return>}->{Name};
  } elsif ($type eq ExpandedURI q<DISLang:Attribute>) {
    valid_err (q<Attribute "dis:Get" element is required>, node => $res->{src})
      unless defined $res->{ExpandedURI q<dis2pm:getter>}->{Name};    
  } elsif ({
            ExpandedURI q<DISLang:MethodReturn> => 1,
            ExpandedURI q<DISLang:AttributeGet> => 1,
            ExpandedURI q<DISLang:AttributeSet> => 1,
           }->{$type}) {
    unless ($has_def) {
      $res->{ExpandedURI q<dis2pm:notImplemented>} = 1;
      for (keys %{$res->{ExpandedURI q<DOMMain:implementFeature>}||{}}) {
        $State->{Type}->{$_}
              ->{ExpandedURI q<dis2pm:notImplemented>} = 1;
      }
    }
  }

  for (ExpandedURI q<dis2pm:param>, ExpandedURI q<dis2pm:inCase>) {
    if ($res->{$_}) {
      $res->{$_} = [sort {$a->{seq} <=> $b->{seq}} @{$res->{$_}}];
    }
  }

  $res->{ExpandedURI q<dis2pm:done>} = 1;
} # dis_perl_init_classdef

=back

=head3 Functions for "disdoc" Documentation

=over 4

=cut

{
use re 'eval';
our $Element;
$Element = qr/[A-Za-z0-9]+(?>::(?>[^<>]*)(?>(?>[^<>]+|<(??{$Element})>)*))?/;
my $MElement = qr/([A-Za-z0-9]+)(?>::((?>[^<>]*)(?>(?>[^<>]+|<(??{$Element})>)*)))?/;

=item $text = disdoc2text ($disdoc, %opt)

Simple converter from disdoc text (block level) to plain text.

=cut
  
sub disdoc2text ($;%);
sub disdoc2text ($;%) {
  my ($s, %opt) = @_;
  $s =~ s/\x0D\x0A/\x0A/g;
  $s =~ tr/\x0D/\x0A/;
  my @s = split /\x0A\x0A+/, $s;
  my @r;
  for my $s (@s) {
    if ($s =~ s/^\{([0-9A-Za-z-]+)::\s*//) { ## Start tag'ed element
      my $et = $1;
      if ($et eq 'P') { ## Paragraph
        push @r, (disdoc_inline2text ($s, %opt));
      } elsif ($et eq 'LI' or $et eq 'OLI') { ## List
        my $marker = '* ';
        if ($et eq 'OLI') {
          $marker = '# ';
        }
        if ($s =~ s/^(.+?)::\s*//) {
          $marker = disdoc_inline2text ($1, %opt) . ': ';
        }
        push @r, $marker . (disdoc_inline2text ($s, %opt));
      } elsif ($et eq 'NOTE') {
        push @r, "NOTE: ". disdoc_inline2text ($s, %opt);
      } elsif ($et eq 'eg') {
        push @r, "Example. ";
        $s =~ s/^\s+//;
        valid_err (qq<Invalid content for DISDOC "eg" element: "$s">,
                   node => $opt{node}) if length $s;
      } else {
        valid_err (qq<Unknown DISDOC element type "$et">, node => $opt{node});
      }
    } elsif ($s =~ /^\}\s*$/) { ## End tag
      #
    } elsif ($s =~ s/^([-=])\s*//) { ## List
      my $marker = $1;
      if ($marker eq '=') {
        $marker = '# ';
      } elsif ($marker eq '-') {
        $marker = '* ';
      }
      if ($s =~ s/^(.+?):::\s*//) {
        $marker = disdoc_inline2text ($1, %opt) . ': ';
      }
      push @r, $marker . (disdoc_inline2pod ($s, %opt));
    } elsif ($s =~ /^[^\w\s<]/) { ## Reserved for future extension
      valid_err (qq<Broken DISDOC: "$s">, node => $opt{node});
    } else {
      $s =~ s/^\s+//;
      push @r, disdoc_inline2text ($s, %opt);
    }
  }
  join "\n\n", @r;
} # disdoc2text

=item $text = disdoc2text_inline ($disdoc, %opt)

Simple converter from disdoc text (inline) to plain text.

=cut

sub disdoc_inline2text ($;%);
sub disdoc_inline2text ($;%) {
  my ($s, %opt) = @_;
  $s =~ s{\G(?:([^<>]+)|<$MElement>|(.))}{
    my ($cdata, $type, $data, $err) = ($1, $2, defined $3 ? $3 : '', $4);
    my $r = '';
    if (defined $err) {
      valid_err (qq<Invalid character "$err" in DISDOC>,
                 node => $opt{node});
    } elsif (defined $cdata) {
      $r = $cdata;
    } elsif ({DFN => 1, CITE => 1, KEY => 1}->{$type}) {
      $r = disdoc_inline2text $data;
    } elsif ({SRC => 1}->{$type}) {
      $r = q<[>. disdoc_inline2text ($data) . q<]>;
    } elsif ({EM => 1}->{$type}) {
      $r = q<*>. disdoc_inline2text ($data) . q<*>;
    } elsif ({URI => 1}->{$type}) {
      $r = q{<} . $data . q{>};
    } elsif ({CODE => 1, Perl => 1}->{$type}) {
      $r = q<"> . disdoc_inline2text ($data) . q<">;
    } elsif ({IF => 1, TYPE => 1, P => 1, XML => 1, SGML => 1, DOM => 1,
              FeatureVer => 1, CHAR => 1, HTML => 1, Prefix => 1,
              Module => 1, QUOTE => 1, PerlModule => 1,
              FILE => 1}->{$type}) {
      $r = q<"> . $data . q<">;
    } elsif ({Feature => 1, CP => 1, ERR => 1,
              HA => 1, HE => 1, XA => 1, SA => 1, SE => 1}->{$type}) {
      $r = q<"> . $data . q<">;
    } elsif ({Q => 1, EV => 1, 
              XE => 1}->{$type}) {
      $r = q<"> . $data . q<">;
    } elsif ({M => 1, A => 1, X => 1, WARN => 1}->{$type}) {
      if ($data =~ /^([^.]+)\.([^.]+)$/) {
        $r = q<"> . $1 . '->' . $2 . q<">;
      } else {
        $r = q<"> . $data . q<">;
      }
    } elsif ({InfosetP => 1}->{$type}) {
      $r = q<[> . $data . q<]>;
    } elsif ($type eq 'lt') {
      $r = '<';
    } elsif ($type eq 'gt') {
      $r = '>';
    } else {
      valid_err (qq<DISDOC element type "$type" not supported>,
                 node => $opt{node});
    }
    $r;
  }ges;
  $s;
} # disdoc_inline2text

=item $pod = disdoc2pod ($disdoc, %opt)

Converter from disdoc text (block-level) to plain text.

=cut

sub disdoc2pod ($;%);
sub disdoc2pod ($;%) {
  my ($s, %opt) = @_;
  $s =~ s/\x0D\x0A/\x0A/g;
  $s =~ tr/\x0D/\x0A/;
  my @s = split /\x0A\x0A+/, $s;
  my @el = ({type => '#document'});
  my @r;
  for my $s (@s) {
    if ($s =~ s/^\{([0-9A-Za-z-]+)::\s*//) { ## Start tag'ed element
      my $et = $1;
      if ($el[-1]->{type} eq '#list' and
          not {qw/LI 1 OLI 1/}->{$et}) {
        push @r, '=back';
        pop @el;
      }
      push @el, {type => $et};
      if ($et eq 'P') { ## Paragraph
        push @r, pod_para (disdoc_inline2pod ($s, %opt));
      } elsif ($et eq 'NOTE') {
        push @r, pod_para (pod_em ('NOTE').": ".disdoc_inline2pod ($s, %opt));
      } elsif ($et eq 'eg') {
        push @r, pod_para (pod_em ('Example').". ");
        $s =~ s/^\s+//;
        valid_err (qq<Invalid content for DISDOC "eg" element: "$s">,
                   node => $opt{node}) if length $s;
      } elsif ($et eq 'LI' or $et eq 'OLI') { ## List
        my $marker = '*';
        unless ($el[-1]->{type} eq '#list') {
          push @el, {type => '#list', n => 0};
          push @r, '=over 4';
        }
        if ($et eq 'OLI') {
          $marker = ++($el[-1]->{n}) . '. ';
        }
        if ($s =~ s/^(.+?)::\s*//) {
          $marker = disdoc_inline2pod ($1, %opt);
        }
        push @r, pod_item ($marker), pod_para (disdoc_inline2pod ($s, %opt));
      } else {
        valid_err (qq<Unknown DISDOC element type "$et">, node => $opt{node});
      }
    } elsif ($s =~ /^\}\s*$/) { ## End tag
      while (@el > 1 and $el[-1]->{type} =~ /^\#/) {
        if ($el[-1]->{type} eq '#list') {
          push @r, '=back';
        }
        pop @el;
      }
      if ($el[-1]->{type} eq '#document') {
        valid_err (qq<Unmatched DISDOC end tag>, node => $opt{node});
      } else {
        pop @el;
      }
    } elsif ($s =~ s/^([-=])\s*//) { ## List
      my $marker = $1;
      unless ($el[-1]->{type} eq '#list') {
        push @el, {type => '#list', n => 0};
        push @r, '=over 4';
      }
      if ($marker eq '=') {
        $marker = ++($el[-1]->{n}) . '. ';
      } elsif ($marker eq '-') {
        $marker = '*';
      }
      if ($s =~ s/^(.+?)::\s*//) {
        $marker = disdoc_inline2pod ($1, %opt);
      }
      push @r, pod_item ($marker), pod_para (disdoc_inline2pod ($s, %opt));
    } elsif ($s =~ /^[^\w\s<]/) { ## Reserved for future extension
      valid_err (qq<Broken DISDOC: "$s">, node => $opt{node});
    } else {
      if ($el[-1]->{type} eq '#list') {
        push @r, '=back';
        pop @el;
      }
      $s =~ s/^\s+//;
      push @r, pod_para disdoc_inline2pod ($s, %opt);
    }
  }
  while (@el and $el[-1]->{type} =~ /^\#/) {
    if ($el[-1]->{type} eq '#list') {
      push @r, '=back';
    }
    pop @el;
  }
  if (@el) {
    valid_err (qq[DISDOC end tag required for "$el[-1]->{type}"],
               node => $opt{node});
  }
  wantarray ? @r : join "\n\n", @r;
} # disdoc2pod

=item $pod = disdoc_inline2pod ($disdoc, %opt)

Convert disdoc text (inline) to pod.

=cut

sub disdoc_inline2pod ($;%);
sub disdoc_inline2pod ($;%) {
  my ($s, %opt) = @_;
  $s =~ s{\G(?:([^<>]+)|<$MElement>|(.))}{
    my ($cdata, $type, $data, $err) = ($1, $2, defined $3 ? $3 : '', $4);
    my $r = '';
    if (defined $err) {
      valid_err (qq<Invalid character "$err" in DISDOC>,
                 node => $opt{node});
    } elsif (defined $cdata) {
      $r = pod_cdata $cdata; 
    } elsif ({CODE => 1, KEY => 1}->{$type}) {
      $r = pod_code disdoc_inline2pod $data;
    } elsif ({EM => 1}->{$type}) {
      $r = pod_em disdoc_inline2pod $data;
    } elsif ({DFN => 1}->{$type}) {
      $r = pod_dfn disdoc_inline2pod $data;
    } elsif ({CITE => 1}->{$type}) {
      $r = q[I<] . disdoc_inline2pod ($data) . q[>];
    } elsif ({SRC => 1}->{$type}) {
      $r = q<[>. disdoc_inline2pod ($data) . q<]>;
    } elsif ({URI => 1}->{$type}) {
      $r = pod_uri $data;
    } elsif ({
              IF => 1, TYPE => 1, P => 1, DOM => 1, XML => 1, HTML => 1,
              SGML => 1, FeatureVer => 1, CHAR => 1, Prefix => 1,
              Perl => 1, FILE => 1,
             }->{$type}) {
      $r = pod_code $data;
    } elsif ({Feature => 1, CP => 1, ERR => 1,
              HA => 1, HE => 1, XA => 1, SA => 1, SE => 1}->{$type}) {
      $r = qname_label (undef, qname => $data,
                        out_type => ExpandedURI q<lang:pod>,
                        no_default_ns => 1);
    } elsif ({Q => 1, EV => 1, 
              XE => 1}->{$type}) {
      $r = qname_label (undef, qname => $data,
                        out_type => ExpandedURI q<lang:pod>);
    } elsif ({
              M => 1, A => 1,
             }->{$type}) {
      if ($data =~ /^([^.]+)\.([^.]+)$/) {
        $r = pod_code ($1 . '->' . $2);
      } else {
        $r = pod_code $data;
      }
    } elsif ({X => 1, WARN => 1}->{$type}) {
      if ($data =~ /^([^.]+)\.([^.]+)$/) {
        $r = pod_code ($1) . '.' . pod_code ($2);
      } else {
        $r = pod_code $data;
      }
    } elsif ({InfosetP => 1}->{$type}) {
      $r = q<[> . $data . q<]>;
    } elsif ({QUOTE => 1}->{$type}) {
      $r = q<"> . $data . q<">;
    } elsif ({PerlModule => 1}->{$type}) {
      $r = pod_link label => pod_code ($data), module => $data;
    } elsif ({Module => 1}->{$type}) {
      $r = pod_link label => pod_code ($data),
                    module => perl_package_name (name => $data);
    } elsif ($type eq 'lt' or $type eq 'gt') {
      $r = qq<E<$type>>;
    } else {
      valid_err (qq<DISDOC element type "$type" not supported>,
                 node => $opt{node});
    }
    $r;
  }ges;
  $s;
}
}

=back

=head1 SEE ALSO

=over 4

=item F<lib/manakai/DISCore.dis> - The "dis" language core module

=item F<bin/disc.pl> - The "dis" compiler

=item F<bin/cdis2pm.pl> - Compiled "dis" to Perl module converter

=back

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/05/11 14:07:42 $
