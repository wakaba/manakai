#!/usr/bin/perl -w 
use strict;

=head1 NAME

mkdisdump.pl - Generating Perl Module Documentation Source

=head1 SYNOPSIS

  perl path/to/mkdisdump.pl input.cdis \
            {--module-name=ModuleName | --module-uri=module-uri} \
            [--for=for-uri] [options] > ModuleName.pm
  perl path/to/cdis2pm.pl --help

=head1 DESCRIPTION

The C<cdis2pm> script generates a Perl module from a compiled "dis"
("cdis") file.  It is intended to be used to generate a manakai 
DOM Perl module files, although it might be useful for other purpose. 

This script is part of manakai. 

=cut

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
  ecore => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/>,
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

=item --for=I<for-uri> (Optional)

Specifies the "For" URI reference for which the outputed module is. 
If this parameter is ommitted, the default "For" URI reference 
for the module, if any, or the C<ManakaiDOM:all> is assumed. 

=item --help

Shows the help message. 

=item --module-uri=I<module-uri>

A URI reference that identifies a module to output.  Either 
C<--module-name> or C<--module-uri> is required. 

=item --verbose / --noverbose (default)

Whether a verbose message mode should be selected or not. 

=item --with-implementators-note / --nowith-implementators-note (default)

Whether the implemetator's notes should also be included
in the result or not.

=back

=cut

use Getopt::Long;
use Pod::Usage;
use Storable;
use Message::Util::Error;
my %Opt = (
  module_uri => {},
);
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-uri=s' => sub {
    shift;
    $Opt{module_uri}->{+shift} = 1;
  },
  'with-implementators-note' => \$Opt{with_impl_note},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage (2) unless keys %{$Opt{module_uri}};

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

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
               ({
                 ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                 '+' . ExpandedURI q<DOMLS:LS> => '3.0',
                 '+' . ExpandedURI q<DIS:Doc> => '2.0',
                 ExpandedURI q<DIS:Dump> => '1.0',
                });

## -- Load input dac database file
  status_msg_ qq<Opening dac file "$Opt{file_name}"...>;
  our $db = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0')
                 ->pl_load_dis_database ($Opt{file_name});
  status_msg qq<done\n>;

  our %ReferredResource;
  our %ClassMembers;
  our %ClassInheritance;
  our @ClassInheritance;
  our %ClassImplements;

sub append_module_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_module ($opt{source_resource}->uri);
  
  add_uri ($opt{source_resource} => $section);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);

    my $path = $opt{source_resource}->get_property_text
                 (ExpandedURI q<dis:FileName>, $pl_full_name);
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);

    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));
    $pl_full_name =~ s/.*:://g;
    $section->perl_name ($pl_full_name);
  }

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  for my $rres (@{$opt{source_resource}->get_property_resource_list
                           (ExpandedURI q<DIS:resource>)}) {
    if ($rres->owner_module eq $opt{source_resource} and## Defined in this module
        not ($ReferredResource{$rres->uri} < 0)) {
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

  my $uri = $opt{source_resource}->name_uri;
  if ($uri) {
    my $fu = $opt{source_resource}->for_uri;
    unless ($fu eq ExpandedURI q<ManakaiDOM:all>) {
      $fu =~ /([\w.-]+)[^\w.-]*$/;
      $uri .= '-' . $1;
    }
  } else {
    $opt{source_resource}->uri;
  }
  $uri =~ s#\b(\d\d\d\d+)/(\d\d?)/(\d\d?)#sprintf '%04d%02d%02d', $1, $2, $3#ge;
  my @file = map {s/[^\w-]/_/g; $_} split m{[/:#?]+}, $uri;

  $section->resource_file_path_stem (join '/', @file);
  $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x (@file - 1));

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

  append_subclassof (source_resource => $opt{source_resource},
                     result_parent => $section);
} # append_datatype_documentation

sub append_interface_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_interface
                                 (my $class_uri = $opt{source_resource}->uri);
  push @ClassInheritance, $class_uri;
  
  add_uri ($opt{source_resource} => $section);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);

    my $path = $opt{source_resource}->get_property_text
                   (ExpandedURI q<dis:FileName>, $pl_full_name);
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);

    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath',
       join '', '../' x ($path =~ tr#/#/#));
    $pl_full_name =~ s/.*:://g;
    $section->perl_name ($pl_full_name);
  }

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
                      result_parent => $section,
                      class_uri => $class_uri);

  for my $memres (@{$opt{source_resource}->get_property_resource_list
                              (ExpandedURI q<DIS:childResource>)}) {
    if ($memres->is_type_uri (ExpandedURI q<DISLang:Method>)) {
      append_method_documentation (source_resource => $memres,
                                   result_parent => $section,
                                   class_uri => $class_uri);
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
      append_attr_documentation (source_resource => $memres,
                                 result_parent => $section,
                                 class_uri => $class_uri);
    } elsif ($memres->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
      append_constgroup_documentation (source_resource => $memres,
                                       result_parent => $section,
                                       class_uri => $class_uri);
    }
  }
} # append_interface_documentation

sub append_class_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_class
    (my $class_uri = $opt{source_resource}->uri);
  push @ClassInheritance, $class_uri;
  
  add_uri ($opt{source_resource} => $section);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);

    my $path = $opt{source_resource}->get_property_text 
                 (ExpandedURI q<dis:FileName>, $pl_full_name);
    $path =~ s#::#/#g;

    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));
    $pl_full_name =~ s/.*:://g;
    $section->perl_name ($pl_full_name);
  }

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  my $has_const = 0;
  for my $memres (@{$opt{source_resource}->get_property_resource_list
                              (ExpandedURI q<DIS:childResource>)}) {
    if ($memres->is_type_uri (ExpandedURI q<DISLang:Method>)) {
      append_method_documentation (source_resource => $memres,
                                   result_parent => $section,
                                   class_uri => $class_uri);
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
      append_attr_documentation (source_resource => $memres,
                                 result_parent => $section,
                                 class_uri => $class_uri);
    } elsif ($memres->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
      $has_const = 1;
      append_constgroup_documentation
        (source_resource => $memres,
         result_parent => $section,
         class_uri => $class_uri);
    }
  }

  ## Inheritance
  append_inheritance (source_resource => $opt{source_resource},
                      result_parent => $section,
                      append_implements => 1,
                      class_uri => $class_uri,
                      has_const => $has_const,
                      is_class => 1);

} # append_class_documentation

sub append_method_documentation (%) {
  my %opt = @_;
  my $perl_name = $opt{source_resource}->pl_name;
  my $m;
  if (defined $perl_name) {
    $m = $opt{result_parent}->create_method ($perl_name);
    $ClassMembers{$opt{class_uri}}->{$perl_name}
      = {
         resource => $opt{source_resource},
         type => 'method',
        };
    
  } else {  ## Anonymous
    ## TODO
    return;
  }
  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m,
                      method_resource => $opt{source_resource});

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

    ## TODO: Exceptions
    } catch Message::Util::DIS::ManakaiDISException with {
      
    };

    append_description (source_resource => $ret,
                        result_parent => $r,
                        has_case => 1,
                        method_resource => $opt{source_resource});

    append_raises (source_resource => $ret,
                   result_parent => $r,
                   method_resource => $opt{source_resource});
  }

  for my $cr (@{$opt{source_resource}->get_property_resource_list
                  (ExpandedURI q<DIS:childResource>)}) {
    if ($cr->is_type_uri (ExpandedURI q<DISLang:MethodParameter>)) {
      append_param_documentation (source_resource => $cr,
                                  result_parent => $m,
                                  method_resource => $opt{source_resource});
    }
  }

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
    $ClassMembers{$opt{class_uri}}->{$perl_name}
      = {
         resource => $opt{source_resource},
         type => 'attr',
        };
    
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

    append_raises (source_resource => $ret,
                   result_parent => $r);
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

    append_raises (source_resource => $set,
                   result_parent => $r);
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
  $ClassMembers{$opt{class_uri}}->{$perl_name}
      = {
         resource => $opt{source_resource},
         type => 'const-group',
        };
  
  add_uri ($opt{source_resource} => $m);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m);
  
  $m->resource_data_type
    (my $u = $opt{source_resource}->dis_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;
  $m->resource_actual_data_type
    ($u = $opt{source_resource}->dis_actual_data_type_resource->uri);
  $ReferredResource{$u} ||= 1;

  append_subclassof (source_resource => $opt{source_resource},
                     result_parent => $m);

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
                      has_case => 1,
                      method_resource => $opt{method_resource});
} # append_param_documentation

sub append_description (%) {
  my %opt = @_;

  my $od = $opt{result_parent}->owner_document;
  my $resd = $opt{source_resource}->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
  my $doc = transform_disdoc_tree
              ($resd->get_description
                        ($od, undef,
                         $Opt{with_impl_note},
                         parent_element_arg => $opt{source_element}),
               method_resource => $opt{method_resource});
  $opt{result_parent}->create_description->append_child ($doc);
  ## TODO: Negotiation

  my $fn = $resd->get_full_name ($od);
  if ($fn) {
    $opt{result_parent}->create_full_name
      ->append_child (transform_disdoc_tree
                        ($fn,
                         method_resource => $opt{method_resource}));
  }

  if ($opt{has_case}) {
    for my $caser (@{$opt{source_resource}->get_property_resource_list
                      (ExpandedURI q<DIS:childResource>)}) {
      if ($caser->is_type_uri (ExpandedURI q<ManakaiDOM:InCase>)) {
        my $case = $opt{result_parent}->append_case;
        my $cased = $caser->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
        my $label = $cased->get_label ($od);
        if ($label) {
          $case->create_label->append_child
            (transform_disdoc_tree ($label,
                                    method_resource => $opt{method_resource}));
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
                            result_parent => $case,
                            method_resource => $opt{method_resource});
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
          my $uri = dd_get_tfqnames_uri ($el);
          if (defined $uri) {
            $ReferredResource{$uri} ||= 1;
            next EL;
          }
        } elsif ($lextype eq ExpandedURI q<dis:TypeQName> or
                 $lextype eq ExpandedURI q<DISCore:NCNameOrQName>) {
          my $uri = dd_get_qname_uri ($el);
          if (defined $uri) {
            $ReferredResource{$uri} ||= 1;
            next EL;
          }
        } elsif ($lextype eq ExpandedURI q<DISPerl:MemRef> or
                 $lextype eq ExpandedURI q<DOMMain:XCodeRef>) {
          my @nm = @{$el->get_elements_by_tag_name_ns
                             (ExpandedURI q<ddel:>, 'name')};
          if (@nm == 1) {
            my $uri = dd_get_tfqnames_uri ($nm[0]);
            if (defined $uri) {
              $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $uri);
              $ReferredResource{$uri} ||= 1;
              next EL;
            }
          } elsif (@nm == 3) {
            my $uri = dd_get_tfqnames_uri ($nm[2]);
            if (defined $uri) {
              $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $uri);
              $ReferredResource{$uri} ||= 1;
              next EL;
            }
          } elsif (@nm == 2) {
            my $uri = dd_get_tfqnames_uri ($nm[0]);
            if (not defined $uri) {
              # 
            } elsif ($nm[1]->get_elements_by_tag_name_ns
                             (ExpandedURI q<ddel:>, 'prefix')->[0]) {
              #my $luri = dd_get_qname_uri ($nm[1]);
              ## QName: Currently not used
            } else {
              my $lnel = $nm[1]->get_elements_by_tag_name_ns
                                  (ExpandedURI q<ddel:>, 'localName')->[0];
              my $lname = $lnel ? $lnel->text_content : '';
              my $res;
              if ($lextype eq ExpandedURI q<DOMMain:XCodeRef> or
                  {
                   ExpandedURI q<ddel:C> => 1,
                   ExpandedURI q<ddel:X> => 1,
                  }->{$el->namespace_uri . $el->local_name}) {
                       ## NOTE: $db
                $res = $db->get_resource ($uri)
                          ->get_const_resource_by_name ($lname);
              } else {
                      ## NOTE: $db
                $res = $db->get_resource ($uri)
                          ->get_child_resource_by_name_and_type
                               ($lname, ExpandedURI q<DISLang:AnyMethod>);
              }
              if ($res) {
                $el->set_attribute_ns
                        (ExpandedURI q<dump:>, 'dump:uri', $res->uri);
                $ReferredResource{$res->uri} ||= 1;
              }
              next EL;
            }
          }
        } # lextype
      } # mmParsed
      elsif ($opt{method_resource} and
             $el->namespace_uri eq ExpandedURI q<ddel:> and
             $el->local_name eq 'P') {
        my $res = $opt{method_resource}
          ->get_child_resource_by_name_and_type
            ($el->text_content, ExpandedURI q<DISLang:MethodParameter>);
        if ($res) {
          $el->set_attribute_ns
            (ExpandedURI q<dump:>, 'dump:uri', $res->uri);
          $ReferredResource{$res->uri} ||= 1;
        }
        next EL;
      }
      push @el, @{$el->child_nodes};
    } elsif ($el->node_type == $el->DOCUMENT_FRAGMENT_NODE or
             $el->node_type == $el->DOCUMENT_NODE) {
      push @el, @{$el->child_nodes};
    }
  } # EL
  $el;
} # transform_disdoc_tree

sub dd_get_tfqnames_uri ($;%) {
  my ($el, %opt) = @_;
  return '' unless $el;
  my $turi = dd_get_qname_uri ($el->get_elements_by_tag_name_ns
                                     (ExpandedURI q<ddel:>, 'nameQName')->[0]);
  my $furi = dd_get_qname_uri ($el->get_elements_by_tag_name_ns
                                     (ExpandedURI q<ddel:>, 'forQName')->[0]);
  return undef if not defined $turi or not defined $furi;
  my $uri = tfuris2uri ($turi, $furi);
  $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $uri);
  $uri;
} # dd_get_tfqnames_uri

sub dd_get_qname_uri ($;%) {
  my ($el, %opt) = @_;
  return undef unless $el;
  my $plel = $el->get_elements_by_tag_name_ns
    (ExpandedURI q<ddel:>, 'prefix')->[0];
  my $lnel = $el->get_elements_by_tag_name_ns
    (ExpandedURI q<ddel:>, 'localName')->[0];
  my $nsuri = ($plel ? $plel : $el)->lookup_namespace_uri
    ($plel ? $plel->text_content : undef);
  $nsuri = '' unless defined $nsuri;
  if ($plel and $nsuri eq '') {
    $plel->remove_attribute_ns
      (ExpandedURI q<xmlns:>, $plel->text_content);
    $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:namespaceURI', $nsuri);
    return undef;
  } else {
    $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:namespaceURI', $nsuri);
  }
  if ($lnel) {
    $nsuri . $lnel->text_content;
  } else {
    $el->get_attribute_ns (ExpandedURI q<ddel:>, 'defaultURI');
  }
} # dd_get_qname_uri

sub tfuris2uri ($$) {
  my ($turi, $furi) = @_;
  my $uri;
  if ($furi eq ExpandedURI q<ManakaiDOM:all>) {
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

  my $has_isa = 0;
  
  for my $isa (@{$opt{source_resource}->get_property_resource_list
                   (ExpandedURI q<dis:ISA>,
                    default_media_type => ExpandedURI q<dis:TFQNames>)}) {
    $has_isa = 1;
    append_inheritance
      (source_resource => $isa,
       result_parent => $opt{result_parent}->append_new_extends ($isa->uri),
       depth => $opt{depth} + 1,
       is_class => $opt{is_class});
    $ReferredResource{$isa->uri} ||= 1;
    if ($opt{class_uri}) {
      unshift @ClassInheritance, $isa->uri;
      push @{$ClassInheritance{$opt{class_uri}} ||= []}, $isa->uri;
    }
  }

  if ($opt{source_resource}->is_defined) {
  for my $isa_pack (@{$opt{source_resource}->pl_additional_isa_packages}) {
    my $isa;
    if ($isa_pack eq 'Message::Util::Error') {
                   ## NOTE: $db
      $isa = $db->get_resource (ExpandedURI q<ecore:MUError>,
                                for_arg => ExpandedURI q<ManakaiDOM:Perl>);
    } elsif ($isa_pack eq 'Tie::Array') {
                   ## NOTE: $db
      $isa = $db->get_resource (ExpandedURI q<DISPerl:TieArray>);
    } elsif ($isa_pack eq 'Error') {
                   ## NOTE: $db
      $isa = $db->get_resource (ExpandedURI q<ecore:Error>,
                                for_arg => ExpandedURI q<ManakaiDOM:Perl>);
    } else {
      ## TODO: What to do?
    }
    if ($isa) {
      $has_isa = 1;
      append_inheritance
        (source_resource => $isa,
         result_parent => $opt{result_parent}->append_new_extends ($isa->uri),
         depth => $opt{depth} + 1,
         is_class => $opt{is_class});
      $ReferredResource{$isa->uri} ||= 1;
      if ($opt{class_uri}) {
        unshift @ClassInheritance, $isa->uri;
        push @{$ClassInheritance{$opt{class_uri}} ||= []}, $isa->uri;
      }
    }
  }} # AppISA

  if ($opt{has_const}) {
                    ## NOTE: $db
    my $isa = $db->get_resource (ExpandedURI q<DISPerl:Exporter>);
    append_inheritance
        (source_resource => $isa,
         result_parent => $opt{result_parent}->append_new_extends ($isa->uri),
         depth => $opt{depth} + 1,
         is_class => $opt{is_class});
    $ReferredResource{$isa->uri} ||= 1;
    if ($opt{class_uri}) {
      unshift @ClassInheritance, $isa->uri;
      push @{$ClassInheritance{$opt{class_uri}} ||= []}, $isa->uri;
    }
  }

  if (not $has_isa and $opt{is_class} and
      $opt{source_resource}->uri ne ExpandedURI q<DISPerl:UNIVERSAL>) {
                    ## NOTE: $db
    my $isa = $db->get_resource (ExpandedURI q<DISPerl:UNIVERSAL>);
    append_inheritance
        (source_resource => $isa,
         result_parent => $opt{result_parent}->append_new_extends ($isa->uri),
         depth => $opt{depth} + 1,
         is_class => $opt{is_class});
    $ReferredResource{$isa->uri} ||= 1;
    if ($opt{class_uri}) {
      unshift @ClassInheritance, $isa->uri;
      push @{$ClassInheritance{$opt{class_uri}} ||= []}, $isa->uri;
    }
  }

  if ($opt{append_implements}) {
            ## NOTE: $db
    my $u = $db->get_resource (ExpandedURI q<DISPerl:UNIVERSALInterface>);
    for my $impl (@{$opt{source_resource}->get_property_resource_list
                      (ExpandedURI q<dis:Implement>,
                       default_media_type => ExpandedURI q<dis:TFQNames>,
                       isa_recursive => 1)}, $u) {
      append_inheritance
        (source_resource => $impl,
         result_parent => $opt{result_parent}->append_new_implements
                                                  ($impl->uri),
         depth => $opt{depth});
      $ReferredResource{$impl->uri} ||= 1;
      $ClassImplements{$opt{class_uri}}->{$impl->uri} = 1
        if $opt{class_uri};
    }
  }
} # append_inheritance

sub append_subclassof (%) {
  my %opt = @_;

  ## NOTE: This subroutine directly access to internal structure
  ##       of ManakaiDISResourceDefinition
  
  my $a;
  $a = sub ($$) {
    my ($gdb, $s) = @_;
    my %s = keys %$s;
    while (my $i = [keys %s]->[0]) {
      ## Removes itself
      delete $s->{$i};
#warn $i;
      
      my $ires = $gdb->get_resource ($i);
      for my $j (keys %$s) {
        next if $i eq $j;
        if ($ires->{subOf}->{$j}) {
          $s->{$i}->{$j} = $s->{$j};
          delete $s->{$j};
          delete $s{$j};
        }
      }
      
      delete $s{$i};
    } # %s
    
    for my $i (keys %$s) {
      $a->($s->{$i}) if keys %{$s->{$i}};
    }
  };
              
  my $b;
  $b = sub ($$) {
    my ($s, $p) = @_;
    for my $i (keys %$s) {
      my $el = $p->append_new_sub_class_of ($i);
      $b->($s->{$i}, $el) if keys %{$s->{$i}};
    }
  };


  my $sub = {$opt{source_resource}->uri =>
             {map {$_ => {}} keys %{$opt{source_resource}->{subOf}}}};
       ## NOTE: $db
  $a->($db, $sub);
  $b->($sub, $opt{result_parent});        
} # append_subclassof

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

sub append_raises (%) {
  my %opt = @_;
  my $parent = $opt{source_resource}->source_element;
  return unless $parent;

  for my $el (@{$parent->dis_child_elements 
                  (for_arg => $opt{source_resource}->for_uri,
                   forp_arg => $opt{source_resource}->forp_uri)}) {
    if ($el->expanded_uri eq ExpandedURI q<ManakaiDOM:raises>) {
                        ## NOTE: $db is used
      my ($a, $b, $c) = @{$db->xcref_to_resource
                                ($el->value, $el,
                                 for_arg => $opt{source_resource}->for_uri)};

      my $rel = $opt{result_parent}->create_raises
                           ($a->uri, $b ? $b->uri : undef, $c ? $c->uri : undef);
      
      append_description (source_resource => $opt{source_resource},
                          source_element => $el,
                          result_parent => $rel,
                          method_resource => $opt{method_resource});
    }
  }
} # append_raises


my $doc = $impl->create_disdump_document;

my $body = $doc->document_element;


## -- Outputs requested modules

for my $mod_uri (keys %{$Opt{module_uri}}) {
  my $mod_for = $Opt{For};
  my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
  unless ($mod_for) {
    my $el = $mod->source_element;
    if ($el) {
      $mod_for = $el->default_for_uri;
      $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
    }
  }
  unless ($mod->is_defined) {
    die qq<$0: Module <$mod_uri> for <$mod_for> is not defined>;
  }

  status_msg qq<Module <$mod_uri> for <$mod_for>...>;

  append_module_documentation
    (result_parent => $body,
     source_resource => $mod);

  status_msg qq<done>;
} # mod_uri

## -- Outputs referenced resources in external modules

status_msg q<Other modules...>;

while (my @ruri = grep {$ReferredResource{$_} > 0} keys %ReferredResource) {
  U: while (defined (my $uri = shift @ruri)) {
    next U if $ReferredResource{$uri} < 0;  ## Already done
    status_msg_ q<*>;
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
        $ReferredResource{$res->uri} = -1;
        next U;
      }      
    } elsif ($res->is_type_uri (ExpandedURI q<ManakaiDOM:Const>)) {
      my $m = $res->get_property_resource
        (ExpandedURI q<dis2pm:parentResource>);
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {
        unshift @ruri, $m->uri;
        $ReferredResource{$res->uri} = -1;
        next U;
      }      
    } elsif ($res->is_type_uri
               (ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>)) {
      my $m = $res->get_property_resource
        (ExpandedURI q<dis2pm:parentResource>);
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<ManakaiDOM:Const>)) {
        unshift @ruri, $m->uri;
        $ReferredResource{$res->uri} = -1;
        next U;
      }      
    } else {  ## Unsupported type
      $ReferredResource{$uri} = -1;
    }
  } # U
}

status_msg q<done>;

## -- Inheriting methods information

{
  verbose_msg_ q<Adding inheritance information...>;
  my %class_done;
  for my $class_uri (@ClassInheritance) {
    next if $class_done{$class_uri};
    $class_done{$class_uri};
    for my $sclass_uri (@{$ClassInheritance{$class_uri}}) {
      for my $scm_name (keys %{$ClassMembers{$sclass_uri}}) {
        if ($ClassMembers{$class_uri}->{$scm_name}) {
          $ClassMembers{$class_uri}->{$scm_name}->{overrides}
            ->{$ClassMembers{$sclass_uri}->{$scm_name}->{resource}->uri} = 1;
        } else {
          $ClassMembers{$class_uri}->{$scm_name}
            = {
               %{$ClassMembers{$sclass_uri}->{$scm_name}},
               is_inherited => 1,
              };
        }
      }
    } # superclasses
  } # classes

  for my $class_uri (keys %ClassImplements) {
    for my $if_uri (keys %{$ClassImplements{$class_uri}||{}}) {
      for my $mem_name (keys %{$ClassMembers{$if_uri}}) {
        unless ($ClassMembers{$class_uri}->{$mem_name}) {
          ## Not defined - error
          $ClassMembers{$class_uri}->{$mem_name}
            = {
               %{$ClassMembers{$if_uri}->{$mem_name}},
               is_inherited => 1,
              };
        }
        $ClassMembers{$class_uri}->{$mem_name}->{implements}
          ->{$ClassMembers{$if_uri}->{$mem_name}->{resource}->uri} = 1;
      }
    } # interfaces
  } # classes

  for my $class_uri (keys %ClassMembers) {
    my $cls_res = $db->get_resource ($class_uri);
    next unless $cls_res->is_defined;
    verbose_msg_ q<.>;
    my $cls_el = $body->create_module ($cls_res->owner_module->uri);
    if ($cls_res->is_type_uri (ExpandedURI q<ManakaiDOM:IF>)) {
      $cls_el = $cls_el->create_interface ($class_uri);
    } else {
      $cls_el = $cls_el->create_class ($class_uri);
    }
    for my $mem_name (keys %{$ClassMembers{$class_uri}}) {
      my $mem_info = $ClassMembers{$class_uri}->{$mem_name};
      my $el;
      if ($mem_info->{type} eq 'const-group') {
        $el = $cls_el->create_const_group ($mem_name);
      } elsif ($mem_info->{type} eq 'attr') {
        $el = $cls_el->create_attribute ($mem_name);
      } else {
        $el = $cls_el->create_method ($mem_name);
      }
      if ($mem_info->{is_inherited}) {
        $el->ref ($mem_info->{resource}->uri);
      }
      for my $or (keys %{$mem_info->{overrides}||{}}) {
        $el->append_new_overrides ($or);
      }
      for my $or (keys %{$mem_info->{implements}||{}}) {
        $el->append_new_implements ($or);
      }
    } # members
  } # classes

  verbose_msg q<done>;
  undef %ClassMembers;
}

{
  status_msg_ qq<Writing file ""...>;

  require Encode;
  my $lsimpl = $impl->get_feature (ExpandedURI q<DOMLS:LS> => '3.0');
  my $serializer = $lsimpl->create_mls_serializer
                        ({ExpandedURI q<DOMLS:SerializeDocumentInstance> => ''});
  my $serialized = $serializer->write_to_string ($doc);
  verbose_msg_ qq< serialized, >;
  my $encoded = Encode::encode ('utf8', $serialized);
  verbose_msg_ qq<bytenized, and >;
  print STDOUT $encoded;
  close STDOUT;
  status_msg qq<done>;
}

verbose_msg_ qq<Checking undefined resources...>;
$db->check_undefined_resource;
verbose_msg qq<done>;

verbose_msg_ qq<Closing database...>;
$db->free;
undef $db;
verbose_msg qq<done>;

END {
  $db->free if $db;
}

=head1 SEE ALSO

L<lib/manakai/dis.pl> and L<bin/cdis2pm.pl> - Old version of 
this script.

L<lib/Message/Util/DIS.dis> - The I<dis> object implementation.

L<lib/Message/Util/PerlCode.dis> - The Perl code generator.

L<lib/manakai/DISCore.dis> - The definition for the "dis" format. 

L<lib/manakai/DISPerl.dis> - The definition for the "dis" Perl-specific 
vocabulary. 

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/09/17 15:03:02 $
