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
  ## for_def_required
  ## Module      Module definitions
  ## module      Namespace URI of the primary module
  ## Namespace   Namespace bindings
  ## Type        Type definitions
  ## type_def_required
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
            return $State->{module};
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
          $State->{for_def_required}->{$uri} ||= 1;
          if (dis_uri_for_match ($uri, $for_uri, %opt, node => $_)) {
            $ok = 0;
            last;
          }
        } else {
          my $uri = dis_qname_to_uri ($f, use_default_namespace => 1, %opt,
                                      node => $_);
          $State->{for_def_required}->{$uri} ||= 1;
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
      $State->{type_def_required}->{$uri} ||= 1;
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
  for (@{$State->{For}->{$for_uri}->{ISA}||[]},
       @{$State->{For}->{$for_uri}->{Implement}||[]}) {
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
  open my $file, '<', $file_name or impl_err (qq<$file_name: $!>,
                                              node => $opt{module_node});
  impl_msg (qq<Opening file "$file_name"...\n>,
            node => $opt{module_node});
  local $/ = undef;
  my $source = Message::Markup::SuikaWikiConfig20::Parser->parse_text (<$file>);
  my $mod = $source->get_attribute ('Module');
  unless ($mod) {
    valid_err q<"Module" element required>, node => $source;
  }
  for (@{$source->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq 'Namespace') {
      dis_load_namespace_element ($_, %opt);
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
    $State->{for_def_required}->{$State->{DefaultFor}} ||= 1;
  }
  for (@{$source->child_nodes}) {
    next unless $_->node_type eq '#element';
    if ($_->local_name eq 'Module') {
      unless (dis_load_module_element ($_, %opt,
                                       module_file_name => $file_name)) {
        ## Module is already loaded
        return $source;
      }
    }
  }
  for (@{$source->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match ($_, $opt{For}, %opt);
    if ($ClassDefElementTypes->{$_->local_name}) {
      dis_load_classdef_element ($_, %opt);
    }
  }
  return $source;
}}

=item 1/0 = dis_load_module_element ($node, %opt)

Install module definitions from a node.  If the module 
is already loaded, return C<0>.  Otherwise, C<1> is returned.

=cut

sub dis_load_module_element ($;%) {
  my ($node, %opt) = @_;
  my $mod = {FileName => $opt{module_file_name}};
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    my $ln = $_->local_name;
    if ($ln eq 'Namespace') {
      my $uri = $_->value;
      if (not defined $State->{module}) {
        $State->{module} = $uri;
      }
      if (defined $State->{Module}->{$uri}->{Namespace}) {
        ## Already loaded
        return 0;
      } else {
        $State->{Module}->{$uri} = $mod;
        $mod->{Namespace} = $uri;
      }
    } elsif ($ln eq 'Name') {
      $mod->{Name} = $_->value;
    } elsif ($ln eq 'ForDef') {
      dis_load_fordef_element ($_, %opt);
    }
  }
  unless (defined $mod->{Namespace}) {
    valid_err (q<Namespace URI of the module not defined>, node => $node);
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
  my $for = {};
  my $uri = dis_qname_to_uri ($node->get_attribute_value ('QName'),
                              use_default_namespace => 1, %opt,
                              node => $node);
  if (defined $State->{For}->{$uri}->{Namespace}) {
    valid_err (q<"For" <$uri> already defined>, node => $node);
  }
  $for->{Namespace} = $uri;
  $State->{For}->{$uri} = $for;
  $State->{for_def_required}->{$uri} = -1;
  
  for (@{$_->child_nodes}) {
    next unless $_->node_type eq '#element';
    my $ln = $_->local_name;
    if ($ln eq 'ISA' or $ln eq 'Implement') {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      push @{$for->{$ln}||=[]}, $uri;
      $State->{for_def_required}->{$uri} ||= 1;
    } elsif ({qw/QName 1 FullName 1 Description 1/}->{$ln}) {
      # 
    } else {
      valid_err (q<Unsupported element type>, node => $_);
    }
  }
  push @{$for->{ISA}}, ExpandedURI q<ManakaiDOM:all>
    if not @{$for->{ISA}||=[]} and
       not $for->{Namespace} eq ExpandedURI q<ManakaiDOM:all>;
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
sub dis_load_classdef_element ($;%);
sub dis_load_classdef_element ($;%) {
  my ($node, %opt) = @_;
  local $dis_load_classdef_element_loop = $dis_load_classdef_element_loop + 1;
  if ($dis_load_classdef_element_loop == 1024) {
    valid_err (q<Class definition nests too deep>, node => $node);
  }
  my $cls = {Type => [], ISA => [], Implement => []};
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
  my $alias = dis_get_attr_node (%opt, parent => $node,
                                 name => 'AliasOf');
  if ($alias) {
    my $uri = dis_qname_to_uri ($alias->value, use_default_namespace => 1,
                                %opt, node => $_);
    if (defined $State->{Type}->{$uri}->{Namespace}) {
      $cls = $State->{Type}->{$uri};
    } else {
      $State->{Type}->{$uri} = $cls;
      $State->{type_def_required}->{$uri} ||= 1;
    }
  }
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match ($node, $opt{For}, %opt);
    my $ln = $_->local_name;
    if ($ln eq 'Type') {
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      push @{$cls->{Type}}, $uri;
      $State->{type_def_required}->{$uri} ||= 1;
    } elsif ($ln eq 'QName' or $ln eq 'Name') {
      my $uri = dis_qname_to_uri ($_->value, %opt, node => $_,
                                  use_default_namespace => $State->{module});
      if (defined $State->{Type}->{$uri}->{Namespace} and
          not defined $cls->{Namespace}) {
        valid_err (qq<Type <$uri> is already defined>, node => $_);
      } else {
        if ($State->{Type}->{$uri}) {
          push @{$cls->{ISA}||=[]}, @{$State->{Type}->{$uri}->{ISA}||[]};
          push @{$cls->{Implement}||=[]}, @{$State->{Type}->{$uri}->{Implement}||[]};
          push @{$cls->{Type}||=[]}, @{$State->{Type}->{$uri}->{Type}||[]};
        }
        $State->{Type}->{$uri} = $cls;
      }
      if (not defined $cls->{Namespace}) {
        $cls->{Namespace} = $uri;
      }
      $State->{type_def_required}->{$uri} = -1;
    } elsif ($ln eq 'ISA' or $ln eq 'Implement') {
      if ($alias) {
        valid_err ("Type alias cannot add inherit relationship",
                   node => $_);
      }
      my $uri = dis_qname_to_uri ($_->value, use_default_namespace => 1,
                                  %opt, node => $_);
      push @{$cls->{$ln}}, $uri;
      $State->{type_def_required}->{$uri} ||= 1;
    } elsif ($ClassDefElementTypes->{$ln}) {
      dis_load_classdef_element ($_, %opt);
    }
  }
  unless (@{$cls->{Type}}) {
    valid_err (q<The "Type" of this class not specified>, node => $node);
  }
  push @{$cls->{ISA}}, ExpandedURI q<DOMMain:any>
    if not @{$cls->{ISA}||=[]} and
       not $cls->{Namespace} eq ExpandedURI q<DOMMain:any>;
}}

=item dis_check_undef_type_and_for (%opt)

Report an error if a type or for URI remains undefined.

=cut

sub dis_check_undef_type_and_for (%) {
  my %opt = @_;
  for (keys %{$State->{type_def_required}}) {
    if ($State->{type_def_required}->{$_} > 0) {
      valid_err ("Type definition for <$_> not found");
    }
  }
  for (keys %{$State->{for_def_required}}) {
    if ($State->{for_def_required}->{$_} > 0) {
      valid_err ("For definition for <$_> not found");
    }
  }
}

1;
