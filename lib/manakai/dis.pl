#!/usr/bin/perl -w

use strict;

use Message::Util::QName::General [qw/ExpandedURI/], {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/11/3/dis-pl#>,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
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
our $ClassDefElementTypes = {qw/ClassDef 1 IFDef 1 DataTypeDef 1
                                ExceptionDef 1 WarningDef 1/};

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
  my ($typeq, $forq) = split /::/, $qq, 2;
  my ($type, $for);
  if (defined $forq) {
    $type = dis_qname_to_uri ($typeq, %opt);
    if (length $forq) {
      $for = dis_qname_to_uri ($forq, %opt);
    } else {
      $for = ExpandedURI q<ManakaiDOM:all>;
    }
  } else {
    $type = dis_qname_to_uri ($typeq, %opt);
    $for = $opt{For} || ExpandedURI q<ManakaiDOM:all>;
  }
  return dis_typeforuris_to_uri ($type, $for, %opt);
}

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
    if ($_->local_name eq 'For') {
      my $for = [split /\s+/, $_->value];
      my $ok = 1;
      $has_for = 1;
      for my $f (@$for) {
        if ($f eq '*') {
          # 
        } elsif ($f =~ /^!(.+)$/) {
          my $uri = dis_qname_to_uri ($1, use_default_namespace => 1, %opt);
          $State->{def_required}->{For}->{$uri} ||= 1;
          if (dis_uri_for_match ($uri, $for_uri, %opt, node => $_)) {
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
      $State->{def_required}->{Class}->{$uri} ||= 1;
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

=item 1/0 = dis_uri_for_match ($uri $for_uri, %opt)

Return whether the C<$uri> matches to the C<$for_uri>. 

=cut

{our $dis_uri_for_match_loop = 0;
sub dis_uri_for_match ($$%);
sub dis_uri_for_match ($$%) {
  my ($uri, $for_uri, %opt) = @_;
  return 1 if $uri eq $for_uri;
  local $dis_uri_for_match_loop = $dis_uri_for_match_loop + 1;
  if ($dis_uri_for_match_loop == 1024) {
    valid_err (qq'$0: "For" URI inheritance might be looping');
  }
  for (keys %{$State->{For}->{$for_uri}->{ISA}||{}},
       keys %{$State->{For}->{$for_uri}->{Implement}||{}}) {
    if (dis_uri_for_match ($uri, $_, %opt)) {
      return 1;
    }
  }
  return 0;
}}

=item 1/0 = dis_uri_ctype_match ($uri $type_uri, %opt)

Return whether the C<$uri> matches to the C<$type_uri>. 

=cut

{our $dis_uri_ctype_match_loop = 0;
sub dis_uri_ctype_match ($$%);
sub dis_uri_ctype_match ($$%) {
  my ($uri, $type_uri, %opt) = @_;
  return 1 if $uri eq $type_uri;
  local $dis_uri_ctype_match_loop = $dis_uri_ctype_match_loop + 1;
  if ($dis_uri_ctype_match_loop == 1024) {
    valid_err (qq'$0: "ContentType" URI inheritance might be looping');
  }
  for (@{$State->{Type}->{$type_uri}->{ISA}||[]},
       @{$State->{Type}->{$type_uri}->{Implement}||[]}) {
    if (dis_uri_ctype_match ($uri, $_, %opt)) {
      return 1;
    }
  }
  return 0;
}}

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
  for (@{$opt{parent}->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq $en) {
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
    if ($_->local_name eq $en) {
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

=item $path = dis_get_module_file_path (%opt)

Get module file path.

=cut

sub dis_get_module_file_path (%) {
  my (%opt) = @_;
  my $file;
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
    unless (-e $file) {
      valid_err (qq<Included module file "$file" not found>,
                 node => $opt{module_node});
    }
  } else {
    valid_err (q<Included module file name not specified>);
  }
  return $file;
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
    $mod = ($source = $State->{module_file_loaded}->{$file_name})
           ->get_attribute ('Module');
    ## Load Namespace Bindings
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      if ($_->local_name eq 'Namespace') {
        dis_load_namespace_element ($_, %opt);
      }
    }
  } else {
    open my $file, '<', $file_name or impl_err (qq<$file_name: $!>,
                                                node => $opt{module_node});
    impl_msg (qq<Opening file "$file_name"...\n>,
              node => $opt{module_node});
    local $/ = undef;
    $State->{module_file_loaded}->{$file_name} = $source
      = Message::Markup::SuikaWikiConfig20::Parser
                                        ->parse_text (<$file>);
    $mod = $source->get_attribute ('Module');
    unless ($mod) {
      valid_err q<"Module" element required>, node => $source;
    }
    ## Load Namespace Bindings
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      if ($_->local_name eq 'Namespace') {
        dis_load_namespace_element ($_, %opt);
      }
    }
    ## Load For Definitions
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      if ($_->local_name eq 'ForDef') {
        dis_load_fordef_element ($_, %opt);
      }
    }
    unless ($opt{For} eq ExpandedURI q<ManakaiDOM:all>) {
      dis_load_module_file (%opt, use_default_for => 0,
                            For => ExpandedURI q<ManakaiDOM:all>);
    }
  }
  if (not defined $opt{For} and $opt{use_default_for}) {
    my $df = $mod->get_attribute ('DefaultFor');
    if ($df) {
      $State->{DefaultFor} = dis_qname_to_uri ($df->value, %opt, node => $df);
    } else {
      $State->{DefaultFor} = ExpandedURI q<ManakaiDOM:all>;
    }
    $opt{For} = $State->{DefaultFor};
    $State->{def_required}->{For}->{$State->{DefaultFor}} ||= 1;
  }
  ## Load Module Definition
  if (dis_load_module_element ($mod, %opt,
                               module_file_name => $file_name)) {
    ## Load Class Definitions
    for (@{$source->child_nodes}) {
      next unless $_->node_type eq '#element';
      next unless dis_node_for_match ($_, $opt{For}, %opt);
      if ($ClassDefElementTypes->{$_->local_name}) {
        dis_load_classdef_element ($_, %opt);
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
    $mod->{ISA}->{$mod->{NameURI}} = 1
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
    if ($ln eq 'Require') {
      for (@{$_->child_nodes}) {
        next unless $_->node_type eq '#element';
        if ($_->local_name eq 'Module') {
          local $State->{Namespace} = {};
          local $State->{module};
          dis_load_module_file (%opt, module_node => $_,
                                module_file_name => undef,
                                use_default_for => 0);
          push @{$mod->{require_module}||=[]}, $State->{module}
            if defined $State->{module};
        }
      }
    }
  }
  my $bname = dis_get_attr_node (%opt, name => 'BindingName',
                                 parent => $node);
  my $for = $opt{For} || ExpandedURI q<ManakaiDOM:all>;
  if ($bname) {
    if (dis_uri_for_match (ExpandedURI q<ManakaiDOM:Perl>, $for, %opt)) {
      my $pf = $bname->get_attribute ('prefix');
      if ($pf) {
        $mod->{perl_package_prefix} = $pf->value;
        if ($bname->value) {
          $mod->{perl_package_name} = $bname->value;
        } else {
          $mod->{perl_package_name} = $mod->{perl_package_prefix}.
                                      $mod->{Name};
        }
      } else {
        valid_err (q<"prefix" attribute required>, node => $bname);
      }
    }
  } else {
    if (dis_uri_for_match (ExpandedURI q<ManakaiDOM:Perl>, $for, %opt)) {
      valid_err (q<"BindingName" attribute specifying "prefix" required>,
                 node => $node);
    }
  }
  return 1;
}

=item dis_load_fordef_element ($node, %opt)

Load C<For> definitions from a node.

=cut

sub dis_load_fordef_element ($;%) {
  my ($node, %opt) = @_;
  my $uri = dis_qname_to_uri ($node->get_attribute_value ('QName'),
                              use_default_namespace => 1, %opt,
                              node => $node);
  if (defined $State->{For}->{$uri}->{URI}) {
    valid_err (qq<"For" <$uri> already defined>, node => $node);
  }
  $State->{For}->{$uri} = my $for = {
    NameURI => $uri,
    URI => $uri,
    ISA => {},
    Implement => {},
  };
  $State->{def_required}->{For}->{$uri} = -1;

  ## TODO: Use general documentation converter
  my $fn = dis_get_attr_node (%opt, name => 'FullName', parent => $node);
  if ($fn) {
    $for->{FullName} = disdoc_inline2text ($fn->value, %opt, node => $fn);
  }
  
  for (@{$_->child_nodes}) {
    next unless $_->node_type eq '#element';
    my $ln = $_->local_name;
    if ($ln eq 'ISA' or $ln eq 'Implement') {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      $for->{$ln}->{$uri} = 1;
      $State->{def_required}->{For}->{$uri} ||= 1;
    } elsif ({qw/QName 1 FullName 1 Description 1/}->{$ln}) {
      # 
    } else {
      valid_err (q<Unsupported element type>, node => $_);
    }
  }
  $for->{ISA}->{ExpandedURI q<ManakaiDOM:all>} = 1
    if not keys %{$for->{ISA}} and
       not $for->{URI} eq ExpandedURI q<ManakaiDOM:all>;
}

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

=item dis_load_classdef_element ($node, %opt)

Load a class (programming language class, interface, datatype, 
markup language element type, etc.) definition.

=cut

{
our $dis_load_classdef_element_loop = 0;
our $dis_anon_class_id = 0;
sub dis_load_classdef_element ($;%);
sub dis_load_classdef_element ($;%) {
  my ($node, %opt) = @_;
  local $dis_load_classdef_element_loop = $dis_load_classdef_element_loop + 1;
  if ($dis_load_classdef_element_loop == 1024) {
    valid_err (q<Class definition nests too deep>, node => $node);
  }
  my $cls;
  my $qn = $node->get_attribute ('QName');
  my $ln = $node->get_attribute ('Name');
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
        valid_err (qq<Class <$dfuri> already defined>, node => $node);
      }
      $cls->{Name} = $lname;
      $cls->{NameURI} = $uri;
      $cls->{URI} = $dfuri;
    } else {
      my $canon = dis_qname_to_uri ($al->value, %opt, node => $al);
      $cls = $State->{Type}->{$dfuri} = ($State->{Type}->{$canon} ||= {});
      $State->{def_required}->{Class}->{$dfuri} ||= 1;
    }
    $cls->{For}->{$opt{For} ||= ExpandedURI q<ManakaiDOM:all>} = 1;
    if ($State->{current_class_container}) {
      $State->{current_class_container}->{Class}->{$dfuri} = $cls;
    }
    $State->{def_required}->{Class}->{$dfuri} = -1;
    unless ($opt{For} eq ExpandedURI q<ManakaiDOM:all>) {
      my $alluri = dis_typeforuris_to_uri ($uri, ExpandedURI q<ManakaiDOM:all>,
                                           %opt);
      $cls->{ISA}->{$alluri} = 1;
      #$State->{def_required}->{Class}->{$alluri} ||= 1;
    }
  } elsif ($ln) {
    my $lname = $ln->value;
    unless ($State->{current_class_container}) {  ## Root class (global)
      my $uri = $State->{Module}->{$State->{module}}->{Namespace} . $lname;
      my $dfuri = dis_typeforuris_to_uri ($uri, $opt{For}, %opt);
      unless ($al) {
        $cls = ($State->{Type}->{$dfuri} ||= {});
        if (defined $cls->{Name}) {
          valid_err (q<Class <$dfuri> is already defined>, node => $node);
        }
        $cls->{Name} = $lname;
        $cls->{NameURI} = $uri;
        $cls->{URI} = $dfuri;
      } else {
        my $canon = dis_qname_to_uri ($al->value, %opt, node => $al);
        $cls = $State->{Type}->{$dfuri} = ($State->{Type}->{$canon} ||= {});
        $State->{def_required}->{Class}->{$dfuri} ||= 1;
      }
      $cls->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
      $State->{def_required}->{Class}->{$dfuri} = -1;
      unless ($opt{For} eq ExpandedURI q<ManakaiDOM:all>) {
        my $alluri = dis_typeforuris_to_uri ($uri, ExpandedURI q<ManakaiDOM:all>,
                                             %opt);
        $cls->{ISA}->{$alluri} = 1;
        #$State->{def_required}->{Class}->{$alluri} ||= 1;
      }
    } else {  ## Local class
      my $dfuri = dis_typeforuris_to_uri ($lname, $opt{For}, %opt);
      unless ($al) {
        $cls = ($State->{current_class_container}->{Class}->{$dfuri} ||= {});
        if (defined $cls->{Name}) {
          valid_err (q<Local class <$dfuri> is already defined>, node => $node);
        }
        $cls->{Name} = $lname;
      } else {
        my $canon = dis_qname_to_uri ($al->value, %opt, node => $al);
        $cls = $State->{current_class_container}->{Class}->{$dfuri}
             = ($State->{current_class_contaner}->{Class}->{$canon} ||= {});
        $State->{def_required}->{Class}->{$dfuri} ||= 1;
      }
      $cls->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
      unless ($opt{For} eq ExpandedURI q<ManakaiDOM:all>) {
        my $alluri = dis_typeforuris_to_uri ($lname,
                                             ExpandedURI q<ManakaiDOM:all>,
                                             %opt);
        $cls->{ISA}->{$alluri} = 1;
        #$State->{def_required}->{Class}->{$alluri} ||= 1;
      }
    }
  } else { ## Anon class
    if ($al) {
      valid_err (q<Name is required for alias>, node => $node);
    }
    my $lname = sprintf '_:dis-class-%d', $dis_anon_class_id++;
    my $dfuri = dis_typeforuris_to_uri ($lname, $opt{For}, %opt);
    if ($State->{current_class_container}) {
      $cls = ($State->{current_class_container}->{Class}->{$dfuri} ||= {});
    } else {
      $cls = ($State->{Type}->{$dfuri} ||= {});
    }
    if (defined $cls->{Name}) {
      impl_err (q<Anonymous class <$dfuri> already defined>, node => $node);
    }
    $cls->{Name} = '';
    $cls->{For}->{$opt{For} || ExpandedURI q<ManakaiDOM:all>} = 1;
  }

  my $et = $node->local_name;
  if ($et eq 'IFDef') {
    $node->append_new_node (type => '#element',
                            local_name => 'Type')
         ->inner_text (new_value => 'URI:'.ExpandedURI q<ManakaiDOM:IF>);
  } elsif ($et eq 'DataTypeDef') {
    $node->append_new_node (type => '#element',
                            local_name => 'Type')
         ->inner_text (new_value => 'URI:'.ExpandedURI q<ManakaiDOM:DataType>);
  } elsif ($et eq 'ExceptionDef') {
    $node->append_new_node (type => '#element',
                            local_name => 'Type')
         ->inner_text (new_value => 'URI:'.ExpandedURI q<ManakaiDOM:Exception>);
  } elsif ($et eq 'WarningDef') {
    $node->append_new_node (type => '#element',
                            local_name => 'Type')
         ->inner_text (new_value => 'URI:'.ExpandedURI q<ManakaiDOM:Warning>);
  }

  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match ($node, $opt{For}, %opt);
    my $ln = $_->local_name;
    if ($ln eq 'Type') {
      my $uri = dis_typeforqnames_to_uri ($_->value, use_default_namespace => 1,
                                          %opt, node => $_);
      $cls->{Type}->{$uri} = 1;
      $State->{def_required}->{Class}->{$uri} ||= 1;
    } elsif ($ln eq 'ISA' or $ln eq 'Implement') {
      valid_err ("Alias class name cannot be able to have this type of elements",
                 node => $_) if $al;
      my $uri = dis_typeforqnames_to_uri ($_->value, use_default_namespace => 1,
                                          %opt, node => $_);
      $cls->{$ln}->{$uri} = 1;
      $State->{def_required}->{Class}->{$uri} ||= 1;
    } elsif ($ClassDefElementTypes->{$ln}) {
      valid_err ("Alias class name cannot be able to have this type of elements",
                 node => $_) if $al;
      local $State->{current_class_container} = $cls;
      dis_load_classdef_element ($_, %opt);
    }
  }
  unless (keys %{$cls->{Type}}) {
    valid_err (q<Class type must be specified>, node => $node);
  }
  $cls->{ISA}->{ExpandedURI q<DOMMain:any>} = 1
    if not keys %{$cls->{ISA}||{}} and
       (not defined $cls->{NameURI} or
        not $cls->{NameURI} eq ExpandedURI q<DOMMain:any>);
}}

=item dis_check_undef_type_and_for (%opt)

Report an error if a type or for URI remains undefined.

=cut

sub dis_check_undef_type_and_for (%) {
  my %opt = @_;
  for my $type (keys %{$State->{def_required}}) {
    for (keys %{$State->{def_required}->{$type}}) {
      if ($State->{def_required}->{$type}->{$_} > 0) {
        valid_err (qq<Definition for $type <$_> is required>);
      }
    }
  }
}


=head1 FUNCTIONS FOR DISDOC DOCUMENTATION

=over 4

=cut

{
use re 'eval';
our $Element;
$Element = qr/[A-Za-z0-9]+(?>:(?>[^<>]*)(?>(?>[^<>]+|<(??{$Element})>)*))?/;
my $MElement = qr/([A-Za-z0-9]+)(?>:((?>[^<>]*)(?>(?>[^<>]+|<(??{$Element})>)*)))?/;

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
      if ($s =~ s/^(.+?)::\s*//) {
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
      $r = qname_label (undef, qname => $data,
                        no_default_ns => 1);
    } elsif ({Q => 1, EV => 1, 
              XE => 1}->{$type}) {
      $r = qname_label (undef, qname => $data);
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

=cut

1; # $Date: 2004/11/07 07:22:16 $
