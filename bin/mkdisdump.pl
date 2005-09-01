use lib qw[../..];

#!/usr/bin/perl -w 
use strict;

=head1 NAME

cdis2pm - Generating Perl Module from a Compiled "dis"

=head1 SYNOPSIS

  perl path/to/cdis2pm.pl input.cdis \
            {--module-name=ModuleName | --module-uri=module-uri} \
            [--for=for-uri] [options] > ModuleName.pm
  perl path/to/cdis2pm.pl --help

=head1 DESCRIPTION

The C<cdis2pm> script generates a Perl module from a compiled "dis"
("cdis") file.  It is intended to be used to generate a manakai 
DOM Perl module files, although it might be useful for other purpose. 

This script is part of manakai. 

=cut

use Message::DOM::DOMHTML;
use Message::DOM::DOMLS;
use Message::Util::DIS::DISDump;
use Message::Util::QName::Filter {
  ddel => q<http://suika.fam.cx/~wakaba/archive/2005/disdoc#>,
  ddoct => q<http://suika.fam.cx/~wakaba/archive/2005/8/disdump-xslt#>,
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DISCore => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Core#>,
  DISLang => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#>,
  DISPerl => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#>,
  disPerl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--Perl-->,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMEvents => q<http://suika.fam.cx/~wakaba/archive/2004/dom/events#>,
  DOMLS => q<http://suika.fam.cx/~wakaba/archive/2004/dom/ls#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  DOMXML => q<http://suika.fam.cx/~wakaba/archive/2004/dom/xml#>,
  dump => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#DISDump/>,
  DX => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#>,
  html5 => q<http://www.w3.org/1999/xhtml>,
  infoset => q<http://www.w3.org/2001/04/infoset#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Markup => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup#>,
  MDOMX => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  pc => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/PerlCode#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
  swcfg21 => q<http://suika.fam.cx/~wakaba/archive/2005/swcfg21#>,
  TreeCore => q<>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
  xhtml1 => q<http://www.w3.org/1999/xhtml>,
  xhtml2 => q<http://www.w3.org/2002/06/xhtml2>,
  xml => q<http://www.w3.org/XML/1998/namespace>,
  xmlns => q<http://www.w3.org/2000/xmlns/>,
};

=head1 OPTIONS

=over 4

=item --enable-assertion / --noenable-assertion (default)

Whether assertion codes should be outputed or not. 

=item --for=I<for-uri> (Optional)

Specifies the "For" URI reference for which the outputed module is. 
If this parameter is ommitted, the default "For" URI reference 
for the module, if any, or the C<ManakaiDOM:all> is assumed. 

=item --help

Shows the help message. 

=item --module-name=I<ModuleName>

The name of module to output.  It is the local name part of 
the C<Module> C<QName> in the source "dis" file.  Either 
C<--module-name> or C<--module-uri> is required. 

=item --module-uri=I<module-uri>

A URI reference that identifies a module to output.  Either 
C<--module-name> or C<--module-uri> is required. 

=item --output-file-path=I<perl-module-file-path> (default: C<STDOUT>)

A platform-dependent file name path for the output.
If it is not specified, then the generated Perl module
content is outputed to the standard output.

=item --output-module-version (default) / --nooutput-module-version

Whether the C<$VERSION> special variable should be generated or not. 

=item --verbose / --noverbose (default)

Whether a verbose message mode should be selected or not. 

=back

=cut

use Getopt::Long;
use Pod::Usage;
use Storable;
use Message::Util::Error;
my %Opt;
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-uri=s' => \$Opt{module_uri},
  'output-file-path=s' => \$Opt{output_file_name},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage (2) unless $Opt{module_uri};

sub status_msg ($) {
  my $s = shift;
  $s .= "\n" unless $s =~ /\n$/;
  print STDERR $s;
}

sub status_msg_ ($) {
  my $s = shift;
  print STDERR $s;
}

sub verbose_msg ($) {
  my $s = shift;
  $s .= "\n" unless $s =~ /\n$/;
  print STDERR $s;
}

sub verbose_msg_ ($) {
  my $s = shift;
  print STDERR $s;
}

my $impl = $Message::DOM::DOMImplementationRegistry->get_dom_implementation
               ({
                 ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
#                 ExpandedURI q<ManakaiDOM:HTML> => '', # 3.0
                 '+' . ExpandedURI q<DOMLS:LS> => '3.0',
                 '+' . ExpandedURI q<DIS:Doc> => '2.0',
                 ExpandedURI q<DIS:Dump> => '1.0',
                });

## -- Load input dac database file
  status_msg_ qq<Opening dac file "$Opt{file_name}"...>;
  my $db = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0')
                ->pl_load_dis_database ($Opt{file_name});
  status_msg qq<done\n>;

## -- Load requested module
  my $mod = $db->get_module ($Opt{module_uri}, for_arg => $Opt{For});
  unless ($Opt{For}) {
    my $el = $mod->source_element;
    if ($el) {
      $Opt{For} = $el->default_for_uri;
      $mod = $db->get_module ($Opt{module_uri}, for_arg => $Opt{For});
    }
  }
  unless ($mod->is_defined) {
    die qq<$0: Module <$Opt{module_uri}> for <$Opt{For}> is not defined>;
  }

  status_msg qq<Module <$Opt{module_uri}> for <$Opt{For}>...>;

  our %ReferredResource;

sub append_module_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_module ($opt{source_resource}->uri);
  
  add_uri ($opt{source_resource} => $section);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);
    my $path = $pl_full_name;
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));
    $pl_full_name =~ s/.*:://g;
    $section->perl_name ($pl_full_name);
  }

  $section->resource_file_name_stem ($opt{source_resource}->pl_file_name_stem);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  for my $rres (@{$opt{source_resource}->get_property_resource_list
                           (ExpandedURI q<DIS:resource>)}) {
    if ($rres->owner_module eq $opt{source_resource}) { ## Defined in this module
                          ## TODO: Modification required to support modplans
      status_msg_ "*";
      if ($rres->is_type_uri (ExpandedURI q<ManakaiDOM:Class>)) {
        append_class_documentation
          (result_parent => $section,
           source_resource => $rres);
      } elsif ($rres->is_type_uri (ExpandedURI q<ManakaiDOM:IF>)) {
        append_interface_documentation
          (result_parent => $section,
           source_resource => $rres);
      } elsif ($rres->is_type_uri (ExpandedURI q<DISCore:AbstractDataType>)) {
        append_datatype_documentation
          (result_parent => $section,
           source_resource => $rres);
      }
    } else {  ## Aliases
      # 
    }
  }
  status_msg "";
} # append_module_documentation

sub append_datatype_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_data_type
                                        ($opt{source_resource}->uri);
  
  add_uri ($opt{source_resource} => $section);

  my $uri = $opt{source_resource}->name_uri || 
            $opt{source_resource}->uri;
  my @file = map {s/[^\w]/_/g; $_} split m{[/:#?]+}, $uri;

  $section->resource_file_name_stem ($file[-1]);
  $section->resource_file_path_stem (join '/', @file);

  my $docr = $opt{source_resource}->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
  my $label = $docr->get_label ($section->owner_document);
  if ($label) {
    $section->create_label->append_child (transform_disdoc_tree ($label));
  }

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  ## Inheritance
  append_inheritance (source_resource => $opt{source_resource},
                      result_parent => $section);
} # append_datatype_documentation

sub append_interface_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_interface
                                        ($opt{source_resource}->uri);
  
  add_uri ($opt{source_resource} => $section);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);
    my $path = $pl_full_name;
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath',
       join '', '../' x ($path =~ tr#/#/#));
    $pl_full_name =~ s/.*:://g;
    $section->perl_name ($pl_full_name);
  }

  $section->resource_file_name_stem ($opt{source_resource}->pl_file_name_stem);

  $section->is_exception_interface (1)
    if $opt{source_resource}->is_type_uri
                                 (ExpandedURI q<ManakaiDOM:ExceptionIF>);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  ## Inheritance
  append_inheritance (source_resource => $opt{source_resource},
                      result_parent => $section);

  for my $memres (@{$opt{source_resource}->get_property_resource_list
                              (ExpandedURI q<DIS:childResource>)}) {
    if ($memres->is_type_uri (ExpandedURI q<DISLang:Method>)) {
      append_method_documentation (source_resource => $memres,
                                   result_parent => $section);
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
      append_attr_documentation (source_resource => $memres,
                                 result_parent => $section);
    } elsif ($memres->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
      append_constgroup_documentation (source_resource => $memres,
                                       result_parent => $section);
    }
  }
} # append_interface_documentation

sub append_class_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_class ($opt{source_resource}->uri);
  
  add_uri ($opt{source_resource} => $section);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);
    my $path = $pl_full_name;
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));
    $pl_full_name =~ s/.*:://g;
    $section->perl_name ($pl_full_name);
  }

  $section->resource_file_name_stem ($opt{source_resource}->pl_file_name_stem);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  ## Inheritance
  append_inheritance (source_resource => $opt{source_resource},
                      result_parent => $section,
                      append_implements => 1);

  for my $memres (@{$opt{source_resource}->get_property_resource_list
                              (ExpandedURI q<DIS:childResource>)}) {
    if ($memres->is_type_uri (ExpandedURI q<DISLang:Method>)) {
      append_method_documentation (source_resource => $memres,
                                   result_parent => $section);
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
      append_attr_documentation (source_resource => $memres,
                                 result_parent => $section);
    } elsif ($memres->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
      append_constgroup_documentation
        (source_resource => $memres,
         result_parent => $section);
    }
  }
} # append_class_documentation

sub append_method_documentation (%) {
  my %opt = @_;
  my $perl_name = $opt{source_resource}->pl_name;
  my $m;
  if (defined $perl_name) {
    $m = $opt{result_parent}->create_method ($perl_name);
    
  } else {  ## Anonymous
    ## TODO
    return;
  }
  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m);

  my $ret = $opt{source_resource}->get_child_resource_by_type
    (ExpandedURI q<DISLang:MethodReturn>);
  if ($ret) {
    my $r = $m->dis_return;

    try {
      $r->resource_data_type (my $u = $ret->dis_data_type_resource->uri);
      $ReferredResource{$u} ||= 1;
      $r->resource_actual_data_type
        ($u = $ret->dis_actual_data_type_resource->uri);
      $ReferredResource{$u} ||= 1;

      append_description (source_resource => $ret,
                          result_parent => $r,
                          has_case => 1);

    ## TODO: Exceptions
    } catch Message::Util::DIS::ManakaiDISException with {
      
    };
  }

  for my $cr (@{$opt{source_resource}->get_property_resource_list
                  (ExpandedURI q<DIS:childResource>)}) {
    if ($cr->is_type_uri (ExpandedURI q<DISLang:MethodParameter>)) {
      append_param_documentation (source_resource => $cr,
                                  result_parent => $m);
    }
  }

  ## TODO: raises

  $m->resource_access ('private')
    if $opt{source_resource}->get_property_boolean
      (ExpandedURI q<ManakaiDOM:isForInternal>, 0);
} # append_method_documentation

sub append_attr_documentation (%) {
  my %opt = @_;
  my $perl_name = $opt{source_resource}->pl_name;
  my $m;
  if (defined $perl_name) {
    $m = $opt{result_parent}->create_attribute ($perl_name);
    
  } else {  ## Anonymous
    ## TODO
    return;
  }
  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m,
                      has_case => 1);

  my $ret = $opt{source_resource}->get_child_resource_by_type
    (ExpandedURI q<DISLang:AttributeGet>);
  if ($ret) {
    my $r = $m->dis_get;

    $r->resource_data_type (my $u = $ret->dis_data_type_resource->uri);
    $ReferredResource{$u} ||= 1;
    $r->resource_actual_data_type
      ($u = $ret->dis_actual_data_type_resource->uri);
    $ReferredResource{$u} ||= 1;

    append_description (source_resource => $ret,
                        result_parent => $r,
                        has_case => 1);

    ## TODO: Exceptions
  }

  my $set = $opt{source_resource}->get_child_resource_by_type
    (ExpandedURI q<DISLang:AttributeSet>);
  if ($set) {
    my $r = $m->dis_set;

    $r->resource_data_type (my $u = $set->dis_data_type_resource->uri);
    $ReferredResource{$u} ||= 1;
    $r->resource_actual_data_type ($set->dis_actual_data_type_resource->uri);
    $ReferredResource{$u} ||= 1;
    
    append_description (source_resource => $set,
                        result_parent => $r,
                        has_case => 1);

    ## TODO: InCase, Exceptions
  } else {
    $m->is_read_only_attribute (1);
  }

  $m->resource_access ('private')
    if $opt{source_resource}->get_property_boolean
      (ExpandedURI q<ManakaiDOM:isForInternal>, 0);
} # append_attr_documentation

sub append_constgroup_documentation (%) {
  my %opt = @_;
  my $perl_name = $opt{source_resource}->pl_name;
  my $m = $opt{result_parent}->create_const_group ($perl_name);
  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m);
  
  $m->resource_data_type
    (my $u = $opt{source_resource}->dis_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;
  $m->resource_actual_data_type
    ($u = $opt{source_resource}->dis_actual_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;


  for my $cr (@{$opt{source_resource}->get_property_resource_list
                  (ExpandedURI q<DIS:childResource>)}) {
    if ($cr->is_type_uri (ExpandedURI q<ManakaiDOM:Const>)) {
      append_const_documentation (source_resource => $cr,
                                  result_parent => $m);
    }
  }
} # append_constgroup_documentation

sub append_const_documentation (%) {
  my %opt = @_;
  my $perl_name = $opt{source_resource}->pl_name;
  my $m = $opt{result_parent}->create_const ($perl_name);
  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m);
  
  $m->resource_data_type
    (my $u = $opt{source_resource}->dis_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;
  $m->resource_actual_data_type
    ($u = $opt{source_resource}->dis_actual_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;

  my $value = $opt{source_resource}->pl_code_fragment;
  if ($value) {
    $m->create_value->text_content ($value->stringify);
  }
  
  for my $cr (@{$opt{source_resource}->get_property_resource_list
                  (ExpandedURI q<DIS:childResource>)}) {
    if ($cr->is_type_uri (ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>)) {
      append_xsubtype_documentation (source_resource => $cr,
                                     result_parent => $m);
    }
  }
  ## TODO: xparam
} # append_const_documentation

sub append_xsubtype_documentation (%) {
  my %opt = @_;
  my $m = $opt{result_parent}->create_exception_sub_code
    ($opt{source_resource}->uri);  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m);
  
  ## TODO: xparam
} # append_xsubtype_documentation

sub append_param_documentation (%) {
  my %opt = @_;
  
  my $is_named_param = $opt{source_resource}->get_property_boolean
    (ExpandedURI q<DISPerl:isNamedParameter>, 0);

  my $perl_name = $is_named_param
    ? $opt{source_resource}->pl_name
    : $opt{source_resource}->pl_variable_name;
  
  my $p = $opt{result_parent}->create_parameter ($perl_name, $is_named_param);
  
  add_uri ($opt{source_resource} => $p);
  
  $p->is_nullable_parameter ($opt{source_resource}->pl_is_nullable);
  $p->resource_data_type
    (my $u = $opt{source_resource}->dis_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;
  $p->resource_actual_data_type
    ($u = $opt{source_resource}->dis_actual_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;

  append_description (source_resource => $opt{source_resource},
                      result_parent => $p,
                      has_case => 1);
} # append_param_documentation

sub append_description (%) {
  my %opt = @_;

  my $od = $opt{result_parent}->owner_document;
  my $resd = $opt{source_resource}->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
  my $doc = transform_disdoc_tree ($resd->get_description ($od));
  $opt{result_parent}->create_description->append_child ($doc);
  ## TODO: Negotiation

  my $fn = $resd->get_full_name ($od);
  if ($fn) {
    $opt{result_parent}->create_full_name
      ->append_child (transform_disdoc_tree ($fn));
  }

  if ($opt{has_case}) {
    for my $caser (@{$opt{source_resource}->get_property_resource_list
                      (ExpandedURI q<DIS:childResource>)}) {
      if ($caser->is_type_uri (ExpandedURI q<ManakaiDOM:InCase>)) {
        my $case = $opt{result_parent}->append_case;
        my $cased = $caser->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
        my $label = $cased->get_label ($od);
        if ($label) {
          $case->create_label->append_child (transform_disdoc_tree ($label));
        }
        my $value = $caser->pl_code_fragment;
        if ($value) {
          $case->create_value->text_content ($value->stringify);
        }
        $case->resource_data_type
          (my $u = $caser->dis_data_type_resource->uri);
        $ReferredResource{$u} ||= 1;
        $case->resource_actual_data_type
          ($u = $caser->dis_actual_data_type_resource->uri);
        $ReferredResource{$u} ||= 1;
        
        append_description (source_resource => $caser,
                            result_parent => $case);
      }
    }
  }
} # append_description

sub transform_disdoc_tree ($;%) {
  my ($el, %opt) = @_;
  my @el = ($el);
  EL: while (defined (my $el = shift @el)) {
    if ($el->node_type == $el->ELEMENT_NODE and
        defined $el->namespace_uri) {
      my $mmParsed = $el->get_attribute_ns (ExpandedURI q<ddel:>, 'mmParsed');
      if ($mmParsed) {
        my $lextype = $el->get_attribute_ns (ExpandedURI q<ddel:>, 'lexType');
        if ($lextype eq ExpandedURI q<dis:TFQNames>) {
          my $turi = dd_get_qname_uri ($el->get_elements_by_tag_name_ns
                                     (ExpandedURI q<ddel:>, 'nameQName')->[0]);
          my $furi = dd_get_qname_uri ($el->get_elements_by_tag_name_ns
                                     (ExpandedURI q<ddel:>, 'forQName')->[0]);
          my $uri = tfuris2uri ($turi, $furi);
          $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $uri);
          $ReferredResource{$uri} ||= 1;
          next EL;
        }
      }
      push @el, children_of ($el);
    } elsif ($el->node_type == $el->DOCUMENT_FRAGMENT_NODE or
             $el->node_type == $el->DOCUMENT_NODE) {
      push @el, children_of ($el);
    }
  } # EL
  $el;
} # transform_disdoc_tree

sub children_of ($) {
  my $cn = $_[0]->child_nodes;
  my $len = $cn->length;
  my @r;
  for (my $i = 0; $i < $len; $i++) {
    push @r, my $l = $cn->item ($i);
  }
  @r;
}

sub dd_get_qname_uri ($;%) {
  my ($el, %opt) = @_;
  return '' unless $el;
  my $plel = $el->get_elements_by_tag_name_ns
    (ExpandedURI q<ddel:>, 'prefix')->[0];
  my $lnel = $el->get_elements_by_tag_name_ns
    (ExpandedURI q<ddel:>, 'localName')->[0];
  my $nsuri = ($plel ? $plel : $el)->lookup_namespace_uri
    ($plel ? $plel->text_content : undef);
  $nsuri = '' unless defined $nsuri;
  if ($plel and $nsuri eq '') {
    $plel->remove_attribute_ns
      (ExpandedURI q<xmlns:>, 'xmlns:'.$plel->text_content);
  }
  $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:namespaceURI', $nsuri);
  if ($lnel) {
    $nsuri . $lnel->text_content;
  } else {
    $el->get_attribute_ns (ExpandedURI q<ddel:>, 'defaultURI');
  }
} # dd_get_qname_uri

sub tfuris2uri ($$) {
  my ($turi, $furi) = @_;
  my $uri;
  if ($furi eq <Q::ManakaiDOM:all>) {
    $uri = $turi;
  } else {
    my $__turi = $turi;
    my $__furi = $furi;
    for my $__uri ($__turi, $__furi) {
      $__uri =~ s{([^0-9A-Za-z:;?=_./-])}{sprintf '%%%02X', ord $1}ge;
    }
    $uri = qq<data:,200411tf#xmlns(t=data:,200411tf%23)>.
      qq<t:tf($__turi,$__furi)>;
  }
  $uri;
} # tfuris2uri

sub append_inheritance (%) {
  my %opt = @_;
  if (($opt{depth} ||= 0) == 100) {
    warn "<".$opt{source_resource}->uri.">: Loop in inheritance";
    return;
  }
  
  for my $isa (@{$opt{source_resource}->get_property_resource_list
                   (ExpandedURI q<dis:ISA>,
                    default_media_type => ExpandedURI q<dis:TFQNames>)}) {
    append_inheritance
      (source_resource => $isa,
       result_parent => $opt{result_parent}->append_new_extends ($isa->uri),
       depth => $opt{depth} + 1);
    $ReferredResource{$isa->uri} ||= 1;
  }

  if ($opt{append_implements}) {
    for my $impl (@{$opt{source_resource}->get_property_resource_list
                      (ExpandedURI q<dis:Implement>,
                       default_media_type => ExpandedURI q<dis:TFQNames>,
                       recursive_isa => 1)}) {
      append_inheritance
        (source_resource => $impl,
         result_parent => $opt{result_parent}->append_new_implements
                                                  ($impl->uri),
         depth => $opt{depth});
      $ReferredResource{$impl->uri} ||= 1;
    }
  }
} # append_inheritance

sub add_uri ($$;%) {
  my ($res, $el, %opt) = @_;
  my $canon_uri = $res->uri;
  for my $uri (@{$res->uris}) {
    $el->add_uri ($uri, $canon_uri eq $uri ? 0 : 1);
    $ReferredResource{$uri} = -1;
  }

  my $nsuri = $res->namespace_uri;
  $el->resource_namespace_uri ($nsuri) if defined $nsuri;
  my $lname = $res->local_name;
  $el->resource_local_name ($lname) if defined $lname;
} # add_uri

my $doc = $impl->create_disdump_document;

my $body = $doc->document_element;

append_module_documentation
  (result_parent => $body,
   source_resource => $mod);


while (my @ruri = grep {$ReferredResource{$_} > 0} keys %ReferredResource) {
  U: while (defined (my $uri = shift @ruri)) {
    next U if $ReferredResource{$uri} < 0;  ## Already done
    my $res = $db->get_resource ($uri);
    unless ($res->is_defined) {
      $res = $db->get_module ($uri);
      unless ($res->is_defined) {
        $ReferredResource{$uri} = -1;
        next U;
      }
      append_module_documentation
        (result_parent => $body,
         source_resource => $res,
         is_partial => 1);
    } elsif ($res->is_type_uri (ExpandedURI q<ManakaiDOM:Class>)) {
      my $mod = $res->owner_module;
      unless ($ReferredResource{$mod->uri} < 0) {
        unshift @ruri, $uri;
        unshift @ruri, $mod->uri;
        next U;
      }
      append_class_documentation
        (result_parent => $body->create_module ($mod->uri),
         source_resource => $res,
         is_partial => 1);
    } elsif ($res->is_type_uri (ExpandedURI q<ManakaiDOM:IF>)) {
      my $mod = $res->owner_module;
      unless ($mod->is_defined) {
        $ReferredResource{$uri} = -1;
        next U;
      } elsif (not ($ReferredResource{$mod->uri} < 0)) {
        unshift @ruri, $uri;
        unshift @ruri, $mod->uri;
        next U;
      }
      append_interface_documentation
        (result_parent => $body->create_module ($mod->uri),
         source_resource => $res,
         is_partial => 1);
    } elsif ($res->is_type_uri (ExpandedURI q<DISCore:AbstractDataType>)) {
      my $mod = $res->owner_module;
      unless ($mod->is_defined) {
        $ReferredResource{$uri} = -1;
        next U;
      } elsif (not ($ReferredResource{$mod->uri} < 0)) {
        unshift @ruri, $uri;
        unshift @ruri, $mod->uri;
        next U;
      }
      append_datatype_documentation
        (result_parent => $body->create_module ($mod->uri),
         source_resource => $res);
    } elsif ($res->is_type_uri (ExpandedURI q<DISLang:AnyMethod>) or
             $res->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
      my $cls = $res->get_property_resource
        (ExpandedURI q<dis2pm:parentResource>);
      if (not ($ReferredResource{$cls->uri} < 0) and
          ($cls->is_type_uri (ExpandedURI q<ManakaiDOM:Class>) or
           $cls->is_type_uri (ExpandedURI q<ManakaiDOM:IF>))) {
        unshift @ruri, $uri;
        unshift @ruri, $cls->uri;
        next U;
      }
      my $model = $body->create_module ($cls->owner_module->uri);
      my $clsel = $cls->is_type_uri (ExpandedURI q<ManakaiDOM:Class>)
        ? $model->create_class ($cls->uri)
        : $model->create_interface ($cls->uri);
      if ($res->is_type_uri (ExpandedURI q<DISLang:Method>)) {
        append_method_documentation
          (result_parent => $clsel,
           source_resource => $res);
      } elsif ($res->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
        append_attr_documentation
          (result_parent => $clsel,
           source_resource => $res);
      } elsif ($res->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
        append_constgroup_documentation
          (result_parent => $clsel,
           source_resource => $res);
      }
    } elsif ($res->is_type_uri (ExpandedURI q<DISLang:MethodParameter>)) {
      my $m = $res->get_property_resource
        (ExpandedURI q<dis2pm:parentResource>);
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<DISLang:Method>)) {
        unshift @ruri, $m->uri;
        next U;
      }      
    } elsif ($res->is_type_uri (ExpandedURI q<ManakaiDOM:Const>)) {
      my $m = $res->get_property_resource
        (ExpandedURI q<dis2pm:parentResource>);
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
        unshift @ruri, $m->uri;
        next U;
      }      
    } elsif ($res->is_type_uri
               (ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>)) {
      my $m = $res->get_property_resource
        (ExpandedURI q<dis2pm:parentResource>);
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<ManakaiDOM:Const>)) {
        unshift @ruri, $m->uri;
        next U;
      }      
    } else {  ## Unsupported type
      $ReferredResource{$uri} = -1;
    }
  } # U
}

my $lsimpl = $impl->get_feature (ExpandedURI q<DOMLS:LS> => '3.0');

status_msg_ qq<Writing file ""...>;

use Encode;
my $serializer = $lsimpl->create_mls_serializer
                        ({ExpandedURI q<DOMLS:SerializeDocumentInstance> => ''});
print Encode::encode ('utf8', $serializer->write_to_string ($doc));

status_msg qq<done>;

verbose_msg_ qq<Checking undefined resources...>;

$db->check_undefined_resource;

verbose_msg qq<done>;

verbose_msg_ qq<Closing database...>;
undef $db;
verbose_msg qq<done>;

=head1 SEE ALSO

L<lib/manakai/dis.pl> and L<bin/cdis2pm.pl> - Old version of 
this script.

L<lib/Message/Util/DIS.dis> - The <QUOTE::dis> object implementation.

L<lib/Message/Util/PerlCode.dis> - The Perl code generator.

L<lib/manakai/DISCore.dis> - The definition for the "dis" format. 

L<lib/manakai/DISPerl.dis> - The definition for the "dis" Perl-specific 
vocabulary. 

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/09/01 17:07:20 $
