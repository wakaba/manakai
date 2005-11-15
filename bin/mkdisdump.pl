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

use Message::Util::QName::Filter {
  ddel => q<http://suika.fam.cx/~wakaba/archive/2005/disdoc#>,
  ddoct => q<http://suika.fam.cx/~wakaba/archive/2005/8/disdump-xslt#>,
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DISCore => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Core#>,
  DISLang => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#>,
  DISPerl => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#>,
  doc => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Document#>,
  DOMLS => q<http://suika.fam.cx/~wakaba/archive/2004/dom/ls#>,
  dump => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#DISDump/>,
  dx => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#>,
  ecore => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/>,
  idl => q<http://suika.fam.cx/~wakaba/archive/2004/dis/IDL#>,
  infoset => q<http://www.w3.org/2001/04/infoset#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Markup => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
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
  resource_uri => {},
);
GetOptions (
  'debug' => \$Opt{debug},
  'dis-file-suffix=s' => \$Opt{dis_suffix},
  'daem-file-suffix=s' => \$Opt{daem_suffix},
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-uri=s' => sub {
    shift;
    my ($nuri, $furi) = split /\s+/, shift, 2;
    $furi ||= '';
    $Opt{module_uri}->{$nuri}->{$furi} = 1;
  },
  'resource-uri=s' => sub {
    shift;
    my ($nuri, $furi) = split /\s+/, shift, 2;
    $furi ||= '';
    $Opt{resource_uri}->{$nuri}->{$furi} = 1;
  },
  'search-path|I=s' => sub {
    shift;
    my @value = split /\s+/, shift;
    while (my ($ns, $path) = splice @value, 0, 2, ()) {
      unless (defined $path) {
        die qq[$0: Search-path parameter without path: "$ns"];
      }
      push @{$Opt{input_search_path}->{$ns} ||= []}, $path;
    }
  },
  'search-path-catalog-file-name=s' => sub {
    shift;
    require File::Spec;
    my $path = my $path_base = shift;
    $path_base =~ s#[^/]+$##;
    $Opt{search_path_base} = $path_base;
    open my $file, '<', $path or die "$0: $path: $!";
    while (<$file>) {
      if (s/^\s*\@//) {     ## Processing instruction
        my ($target, $data) = split /\s+/;
        if ($target eq 'base') {
          $Opt{search_path_base} = File::Spec->rel2abs ($data, $path_base);
        } else {
          die "$0: $target: Unknown target";
        }
      } elsif (/^\s*\#/) {  ## Comment
        #
      } elsif (/\S/) {      ## Catalog entry
        s/^\s+//;
        my ($ns, $path) = split /\s+/;
        push @{$Opt{input_search_path}->{$ns} ||= []},
             File::Spec->rel2abs ($path, $Opt{search_path_base});
      }
    }
    ## NOTE: File paths with SPACEs are not supported
    ## NOTE: Future version might use file: URI instead of file path.
  },
  'with-implementators-note' => \$Opt{with_impl_note},
  'verbose!' => \$Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage (2) unless (keys %{$Opt{module_uri}}) + (keys %{$Opt{resource_uri}});
$Message::DOM::DOMFeature::DEBUG = 1 if $Opt{debug};
$Opt{dis_suffix} = '.dis' unless defined $Opt{dis_suffix};
$Opt{daem_suffix} = '.daem' unless defined $Opt{daem_suffix};

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
  print STDERR $s if $Opt{verbose};
}

sub verbose_msg_ ($) {
  my $s = shift;
  print STDERR $s if $Opt{verbose};
}

{
my $ResourceCount = 0;
sub progress_inc (;$) {
  $ResourceCount += (shift || 1);
  if (($ResourceCount % 10) == 0) {
    print STDERR "*";
    print STDERR " " if ($ResourceCount % (10 * 10)) == 0;
    print STDERR "\n" if ($ResourceCount % (10 * 50)) == 0;
  }
}

sub progress_reset () {
  $ResourceCount = 0;
}
}

my $start_time;
BEGIN { $start_time = time }

use Message::DOM::GenericLS;
use Message::DOM::SimpleLS;
use Message::Util::DIS::DISDump;
use Message::Util::DIS::DISDoc;
use Message::Util::DIS::DNLite;

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
               ({
                 ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                 '+' . ExpandedURI q<DOMLS:Generic> => '3.0',
                 '+' . ExpandedURI q<DIS:Doc> => '2.0',
                 '+' . ExpandedURI q<DIS:DNLite> => '1.0',
                 ExpandedURI q<DIS:Dump> => '1.0',
                });

## -- Load input dac database file
  status_msg_ qq<Opening dac file "$Opt{file_name}"...>;
  our $db = $impl->get_feature (ExpandedURI q<DIS:DNLite> => '1.0')
                 ->pl_load_dis_database ($Opt{file_name}, sub ($$) {
    my ($db, $mod) = @_;
    my $ns = $mod->namespace_uri;
    my $ln = $mod->local_name;
    verbose_msg qq<Database module <$ns$ln> is requested>;
    my $name = dac_search_file_path_stem ($ns, $ln, $Opt{daem_suffix});
    if (defined $name) {
      return $name.$Opt{daem_suffix};
    } else {
      return $ln.$Opt{daem_suffix};
    }
  });
  status_msg qq<done\n>;

  our %ReferredResource;
  our %ClassMembers;
  our %ClassInheritance;
  our @ClassInheritance;
  our %ClassImplements;

sub append_module_group_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}
    ->append_child ($opt{result_parent}->owner_document
                    ->create_element_ns (ExpandedURI q<dump:>, 'moduleGroup'));
  
  add_uri ($opt{source_resource} => $section);

  my $path = $opt{source_resource}->get_property_text
                 (ExpandedURI q<dis:FileName>,
                  $opt{source_resource}->local_name);
  $section->resource_file_path_stem ($path);

  $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section,
                      has_label => 1);

  ## -- Member modules

  for my $rres (@{$opt{source_resource}->get_property_module_list
                    (ExpandedURI q<DISCore:module>)}) {
    $Opt{module_uri}->{$rres->name_uri}->{$rres->for_uri} = 1;
    my $mod_el = $section->append_child
                    ($section->owner_document
                     ->create_element_ns (ExpandedURI q<dump:>, 'module'));
    $mod_el->ref ($rres->uri);
  }

  ## -- Member resources

  for my $rres (@{$opt{source_resource}->get_property_resource_list
                    (ExpandedURI q<DISCore:resource>)}) {
    progress_inc;
    if ($rres->is_type_uri (ExpandedURI q<doc:Document>)) {
      append_document_documentation (source_resource => $rres,
                                     result_parent => $section);
    } else {
      # 
    }
  }
  status_msg "";
} # append_module_group_documentation

sub append_document_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}
    ->append_child ($opt{result_parent}->owner_document
                    ->create_element_ns (ExpandedURI q<dump:>, 'document'));
  my $od = $section->owner_document;
  
  add_uri ($opt{source_resource} => $section);

  my $path = $opt{source_resource}->get_property_text
                (ExpandedURI q<dis:FileName>,
                 lcfirst $opt{source_resource}->local_name);
  $section->resource_file_path_stem ($path);

  $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));

  if ($opt{source_resource}->is_type_uri (ExpandedURI q<doc:Document>)) {
    $section->append_child ($od->create_element_ns (ExpandedURI q<doc:>, 'rel'))
      ->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', 
                          ExpandedURI q<doc:Document>);
  }
  
  ## TODO: Conneg
  for my $con (@{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<doc:content>)}) {
    my $cond = $con->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
    my $tree = $cond->get_disdoc_tree
      ($od, ExpandedURI q<lang:disdoc>,
       $opt{source_resource}->database,
       default_name_uri => $opt{source_resource}->source_node_id,
       default_for_uri => $opt{source_resource}->for_uri);
    $section
      ->append_child ($od->create_element_ns (ExpandedURI q<doc:>, 'content'))
      ->append_child (transform_disdoc_tree ($tree));
  }

  append_document_properties
    (source_resource => $opt{source_resource},
     result_parent => $section);

  for my $v (@{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<doc:part>)}) {
    my $res = $v->get_resource ($opt{source_resource}->database);
    $ReferredResource{$res->uri} ||= 2;
    $ReferredResource{$res->uri} = 2
      if $ReferredResource{$res->uri} == 1;
    my $doc = $section->append_child
      ($od->create_element_ns (ExpandedURI q<dump:>, 'document'));
    $doc->ref ($res->uri);
    for my $vv (@{$v->get_property (ExpandedURI q<doc:rel>)||[]}) {
      $doc->append_child ($od->create_element_ns (ExpandedURI q<doc:>, 'rel'))
        ->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $vv->uri);
    }
    for my $vv (@{$v->get_property (ExpandedURI q<doc:as>)||[]}) {
      $doc->append_child ($od->create_element_ns (ExpandedURI q<doc:>, 'as'))
        ->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $vv->uri);
    }
  }
} # append_document_documentation

sub append_module_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_module ($opt{source_resource}->uri);
  my $od = $opt{result_parent}->owner_document;
  
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

  for my $con (@{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<DISCore:AnyAppName>)}) {
    my $ns = $con->name;
    my $ln = $1 if ($ns =~ s/(\w+)$//);
    if ($con->isa ('Message::Util::IF::DVURIValue')) {
      $section->append_child ($od->create_element_ns ($ns, $ln))
        ->set_attribute_ns (ExpandedURI q<dump:>, 'dump:ref',
                            $con->string_value);
      $ReferredResource{$con->uri} ||= 1;
    } else {
      $section->append_child ($od->create_element_ns ($ns, $ln))
        ->text_content ($con->string_value);
    }
    if ($con->isa ('Message::Util::IF::DVURIValue')) {
      $ReferredResource{$con->uri} ||= 1;
    }
  }

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
    return;
  }

  for my $rres (@{$opt{source_resource}->get_resource_list}) {
    if ($rres->owner_module eq $opt{source_resource} and## Defined in this module
        not ($ReferredResource{$rres->uri} < 0)) {
                          ## TODO: Modification required to support modplans
      progress_inc;
      if ($rres->is_type_uri (ExpandedURI q<DISLang:Class>)) {
        append_class_documentation
          (result_parent => $section,
           source_resource => $rres);
      } elsif ($rres->is_type_uri (ExpandedURI q<DISLang:Interface>)) {
        append_interface_documentation
          (result_parent => $section,
           source_resource => $rres);
      } elsif ($rres->is_type_uri (ExpandedURI q<DISCore:AnyType>)) {
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
  my $od = $opt{result_parent}->owner_document;
  my $section = $opt{result_parent}->can ('create_data_type')
    ? $opt{result_parent}->create_data_type
                                        ($opt{source_resource}->uri)
    : $opt{result_parent}->append_child
      ($od->create_element_ns
       (ExpandedURI q<dump:>, 'dataType'));
  
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

  for my $con (@{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<dis:AppName>)},
               @{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<dis:Def>)}) {
    my $ns = $con->name;
    my $ln = $1 if ($ns =~ s/(\w+)$//);
    if ($con->isa ('Message::Util::IF::DVURIValue')) {
      $section->append_child ($od->create_element_ns ($ns, $ln))
        ->set_attribute_ns (ExpandedURI q<dump:>, 'dump:ref',
                            $con->string_value);
      $ReferredResource{$con->uri} ||= 1;
    } else {
      $section->append_child ($od->create_element_ns ($ns, $ln))
        ->text_content ($con->string_value);
    }
  }

  append_document_properties
    (source_resource => $opt{source_resource},
     result_parent => $section);
                                 
  append_description (source_resource => $opt{source_resource},
                      result_parent => $section,
                      has_label => 1);

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
  my $path;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);

    $path = $opt{source_resource}->get_property_text
                   (ExpandedURI q<dis:FileName>, $pl_full_name);
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->perl_name ($pl_full_name);
  } else {
    $path = $opt{source_resource}->get_property_text
      (ExpandedURI q<dis:FileName>, $opt{source_resource}->local_name);
    $section->resource_file_path_stem ($path);
  }
  $section->set_attribute_ns
    (ExpandedURI q<ddoct:>, 'ddoct:basePath',
     join '', '../' x ($path =~ tr#/#/#));
  $pl_full_name =~ s/.*:://g;

  $section->is_exception_interface (1)
    if $opt{source_resource}->is_type_uri (ExpandedURI q<DISLang:Exception>);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  if ($opt{is_partial}) {
    $section->resource_is_partial (1);
  }

  for my $memres (@{$opt{source_resource}->get_child_resource_list}) {
    if ($memres->is_type_uri (ExpandedURI q<DISLang:Method>)) {
      append_method_documentation (source_resource => $memres,
                                   result_parent => $section,
                                   class_uri => $class_uri,
                                   is_partial => $opt{is_partial});
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
      append_attr_documentation (source_resource => $memres,
                                 result_parent => $section,
                                 class_uri => $class_uri,
                                 is_partial => $opt{is_partial});
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:ConstGroup>)) {
      append_constgroup_documentation (source_resource => $memres,
                                       result_parent => $section,
                                       class_uri => $class_uri,
                                       is_partial => $opt{is_partial});
    }
  }

  return if $opt{is_partial};

  ## Inheritance
  append_inheritance (source_resource => $opt{source_resource},
                      result_parent => $section,
                      class_uri => $class_uri);

  if ($opt{source_resource}->is_type_uri (ExpandedURI q<idl:AnyInterface>)) {
    $ReferredResource{ExpandedURI q<idl:void>} ||= 1;
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
  }

  my $has_const = 0;
  for my $memres (@{$opt{source_resource}->get_child_resource_list}) {
    if ($memres->is_type_uri (ExpandedURI q<DISLang:Method>)) {
      append_method_documentation (source_resource => $memres,
                                   result_parent => $section,
                                   class_uri => $class_uri,
                                   is_partial => $opt{is_partial});
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:Attribute>)) {
      append_attr_documentation (source_resource => $memres,
                                 result_parent => $section,
                                 class_uri => $class_uri,
                                 is_partial => $opt{is_partial});
    } elsif ($memres->is_type_uri (ExpandedURI q<DISLang:ConstGroup>)) {
      $has_const = 1;
      append_constgroup_documentation
        (source_resource => $memres,
         result_parent => $section,
         class_uri => $class_uri,
         is_partial => $opt{is_partial});
    }
  }

  return if $opt{is_partial};

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
  my $od = $opt{result_parent}->owner_document;
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

  for my $con (@{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<DISCore:AnyAppName>)}) {
    my $ns = $con->name;
    my $ln = $1 if ($ns =~ s/(\w+)$//);
    if ($con->isa ('Message::Util::IF::DVURIValue')) {
      $m->append_child ($od->create_element_ns ($ns, $ln))
        ->set_attribute_ns (ExpandedURI q<dump:>, 'dump:ref',
                            $con->string_value);
      $ReferredResource{$con->uri} ||= 1;
    } else {
      $m->append_child ($od->create_element_ns ($ns, $ln))
        ->text_content ($con->string_value);
    }
  }
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m,
                      method_resource => $opt{source_resource});

  $m->resource_access ('private')
    if $opt{source_resource}->get_property_boolean
      (ExpandedURI q<ManakaiDOM:isForInternal>, 0);

  if ($opt{is_partial}) {
    $m->resource_is_partial (1);
    return;
  }

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

  for my $cr (@{$opt{source_resource}->get_child_resource_list}) {
    if ($cr->is_type_uri (ExpandedURI q<DISLang:MethodParameter>)) {
      append_param_documentation (source_resource => $cr,
                                  result_parent => $m,
                                  method_resource => $opt{source_resource});
    }
  }
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

  $m->resource_access ('private')
    if $opt{source_resource}->get_property_boolean
      (ExpandedURI q<ManakaiDOM:isForInternal>, 0);

  if ($opt{is_partial}) {
    $m->resource_is_partial (1);
    $m->is_read_only_attribute (1)
      if $opt{source_resource}->get_child_resource_by_type
        (ExpandedURI q<DISLang:AttributeSet>);
    return;
  }
  
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

  if ($opt{is_partial}) {
    $m->resource_is_partial (1);
    return;
  }
  
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

  for my $cr (@{$opt{source_resource}->get_child_resource_list}) {
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
  
  for my $cr (@{$opt{source_resource}->get_child_resource_list}) {
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
                         parent_value_arg => $opt{source_value}),
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

  if ($opt{has_label}) {
    my $label = $resd->get_label ($od);
    if ($label) {
      if ($opt{result_parent}->can ('create_label')) {
        $opt{result_parent}->create_label
          ->append_child (transform_disdoc_tree ($label));
      } else {
        $opt{result_parent}->append_child
          ($od->create_element_ns (ExpandedURI q<dump:>, 'label'))
            ->append_child (transform_disdoc_tree ($label));;
      }
    }
  }

  if ($opt{has_case}) {
    for my $caser (@{$opt{source_resource}->get_child_resource_list}) {
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

sub append_document_properties (%) {
  my %opt = @_;
  my $od = $opt{result_parent}->owner_document;

  for my $con (@{$opt{source_resource}->get_property_value_list
                   (ExpandedURI q<dis:Label>)}) {
    my $cond = $con->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
    my $tree = $cond->get_disdoc_tree
      ($od, ExpandedURI q<lang:disdocInline>,
       $opt{source_resource}->database,
       default_name_uri => $opt{source_resource}->source_node_id,
       default_for_uri => $opt{source_resource}->for_uri);
    my $ns = $con->name;
    my $ln = $1 if ($ns =~ s/(\w+)$//);
    $opt{result_parent}->append_child ($od->create_element_ns ($ns, $ln))
      ->append_child (transform_disdoc_tree ($tree));
  }
} # append_document_properties

sub transform_disdoc_tree ($;%) {
  my ($el, %opt) = @_;
  my @el = ($el);
  EL: while (defined (my $el = shift @el)) {
    if ($el->node_type == $el->ELEMENT_NODE and
        defined $el->namespace_uri) {
      my $mmParsed = $el->get_attribute_ns (ExpandedURI q<ddel:>, 'mmParsed');
      if ($mmParsed) {
        my $lextype = $el->get_attribute_ns (ExpandedURI q<ddel:>, 'lexType');
        if ($lextype eq ExpandedURI q<DISCore:TFQNames>) {
          my $uri = dd_get_tfqnames_uri ($el);
          if (defined $uri) {
            $ReferredResource{$uri} ||= 1;
            next EL;
          }
        } elsif ($lextype eq ExpandedURI q<DISCore:QName> or
                 $lextype eq ExpandedURI q<DISCore:NCNameOrQName>) {
          my $uri = dd_get_qname_uri ($el);
          if (defined $uri) {
            $ReferredResource{$uri} ||= 1;
            next EL;
          }
        } elsif ($lextype eq ExpandedURI q<DISLang:MemberRef> or
                 $lextype eq ExpandedURI q<dx:XCRef>) {
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
              if ($lextype eq ExpandedURI q<dx:XCRef> or
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
  my $r;
  if ($lnel) {
    $r = $nsuri . $lnel->text_content;
  } else {
    $r = $el->get_attribute_ns (ExpandedURI q<ddel:>, 'defaultURI');
  }
  $el->set_attribute_ns (ExpandedURI q<dump:>, 'dump:uri', $r);
  $r;
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
      $__uri =~ s{([^0-9A-Za-z!\$'()*,:;=?\@_./~-])}{sprintf '%%%02X', ord $1}ge;
    }
    $uri = qq<tag:suika.fam.cx,2005-09:$__turi+$__furi>;
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
                    default_media_type => ExpandedURI q<DISCore:TFQNames>)}) {
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
                       default_media_type => ExpandedURI q<DISCore:TFQNames>,
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

  for my $el (@{$opt{source_resource}->get_property_value_list
                  (ExpandedURI q<dx:raises>)}) {
    next unless $el->isa ('Message::Util::IF::DVURIValue');
    my $e = $el->get_resource ($db);
    my ($a, $b, $c);           ## NOTE: $db
    if ($e->is_type_uri (ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>)) {
      $c = $e;
      $b = $c->parent_resource;
      $a = $b->parent_resource->parent_resource;
    } elsif ($e->is_type_uri (ExpandedURI q<DISLang:Const>)) {
      $b = $e;
      $a = $b->parent_resource->parent_resource;
    } else {
      $a = $e;
    }
    my $rel = $opt{result_parent}->create_raises
                           ($a->uri, $b ? $b->uri : undef, $c ? $c->uri : undef);
      
    append_description (source_resource => $opt{source_resource},
                        source_value => $el,
                        result_parent => $rel,
                        method_resource => $opt{method_resource});
  }
} # append_raises


my $doc = $impl->create_disdump_document;

my $body = $doc->document_element;

## -- Outputs requested modules

for my $res_nuri (keys %{$Opt{resource_uri}}) {
  for my $res_furi (keys %{$Opt{resource_uri}->{$res_nuri}}) {
    $res_furi = ExpandedURI q<ManakaiDOM:all> unless length $res_furi;
    my $res = $db->get_resource ($res_nuri, for_arg => $res_furi);
    unless ($res->is_defined) {
      die qq{$0: Resource <$res_nuri> for <$res_furi> is not defined};
    }

    if ($res->is_type_uri (ExpandedURI q<doc:Documentation>)) {
      status_msg_ qq<Document <$res_nuri> for <$res_furi>...>;
      
      append_document_documentation
        (result_parent => $body,
         source_resource => $res);

      status_msg qq<done>;
    } elsif ($res->is_type_uri (ExpandedURI q<dis:ModuleGroup>)) {
      status_msg qq<Module group <$res_nuri> for <$res_furi>...>;
      
      append_module_group_documentation
        (result_parent => $body,
         source_resource => $res);
      
      status_msg qq<done>;
    } else {
      die qq{$0: --resource-uri: Resource <$res_nuri> for <$res_furi>}.
          qq{ is not a resource set};
    }
  } # res_furi
} # res_nuri

for my $mod_uri (keys %{$Opt{module_uri}}) {
  for my $mod_for (keys %{$Opt{module_uri}->{$mod_uri}}) {
    $mod_for = $Opt{For} unless length $mod_for;
    my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
    unless (defined $mod_for) {
      $mod_for = $mod->get_property_text (ExpandedURI q<dis:DefaultFor>);
      if (defined $mod_for) {
        $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
      }
    }
    unless ($mod->is_defined) {
      die qq<$0: Module <$mod_uri> for <$mod_for> is not defined>;
    }
    
    status_msg qq<Module <$mod_uri> for <$mod_for>...>;
    progress_reset;
    
    append_module_documentation
      (result_parent => $body,
       source_resource => $mod);
    
    status_msg qq<done>;
  } # mod_for
} # mod_uri

## -- Outputs referenced resources in external modules

status_msg q<Other modules...>;
progress_reset;

my %debug_res_list;
while (my @ruri = grep {$ReferredResource{$_} > 0} keys %ReferredResource) {
  U: while (defined (my $uri = shift @ruri)) {
    next U if $ReferredResource{$uri} < 0;  ## Already done
    if ($Opt{debug}) {
      warn "Resource <$uri>: $debug_res_list{$uri} times\n"
        if ++$debug_res_list{$uri} > 10;
    }
    progress_inc;
    my $res = $db->get_resource ($uri);
    unless ($res->is_defined) {
      $res = $db->get_module ($uri);
      unless ($res->is_defined) {
        $ReferredResource{$uri} = -1;
        next U;
      }
      progress_reset;
      status_msg qq<Module <$uri>...>;
      append_module_documentation
        (result_parent => $body,
         source_resource => $res,
         is_partial => ($ReferredResource{$uri} == 1));
      status_msg qq<done>;
      progress_reset;
    } elsif ($res->is_type_uri (ExpandedURI q<DISLang:Class>)) {
      my $mod = $res->owner_module;
      my $mod_uri = $mod->uri;
      unless ($ReferredResource{$mod_uri} < 0) {
        $ReferredResource{$mod_uri} = $ReferredResource{$uri}
          if $ReferredResource{$mod_uri} < $ReferredResource{$uri};
        unshift @ruri, $uri;
        unshift @ruri, $mod_uri;
        next U;
      }
      append_class_documentation
        (result_parent => $body->create_module ($mod_uri),
         source_resource => $res,
         is_partial => ($ReferredResource{$uri} == 1));
    } elsif ($res->is_type_uri (ExpandedURI q<DISLang:Interface>)) {
      my $mod = $res->owner_module;
      my $mod_uri = $mod->uri;
      unless ($ReferredResource{$mod_uri} < 0) {
        $ReferredResource{$mod_uri} = $ReferredResource{$uri}
          if $ReferredResource{$mod_uri} < $ReferredResource{$uri};
        unshift @ruri, $uri;
        unshift @ruri, $mod_uri;
        next U;
      }
      append_interface_documentation
        (result_parent => $body->create_module ($mod->uri),
         source_resource => $res,
         is_partial => ($ReferredResource{$uri} == 1));
    } elsif ($res->is_type_uri (ExpandedURI q<DISCore:AnyType>)) {
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
             $res->is_type_uri (ExpandedURI q<DISLang:ConstGroup>)) {
      my $cls = $res->parent_resource;
      unless ($cls) {
        $ReferredResource{$res->uri} = -1;
        next U;
      }
      if (not ($ReferredResource{$cls->uri} < 0) and
          ($cls->is_type_uri (ExpandedURI q<DISLang:Class>) or
           $cls->is_type_uri (ExpandedURI q<DISLang:Interface>))) {
        unshift @ruri, $uri;
        unshift @ruri, $cls->uri;
        next U;
      }
      my $model = $body->create_module ($cls->owner_module->uri);
      my $clsel = $cls->is_type_uri (ExpandedURI q<DISLang:Class>)
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
      } elsif ($res->is_type_uri (ExpandedURI q<DISLang:ConstGroup>)) {
        append_constgroup_documentation
          (result_parent => $clsel,
           source_resource => $res);
      } else {
        $ReferredResource{$res->uri} = -1;
      }
    } elsif ($res->is_type_uri (ExpandedURI q<DISLang:MethodParameter>)) {
      my $m = $res->parent_resource;
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<DISLang:Method>)) {
        unshift @ruri, $m->uri;
        $ReferredResource{$res->uri} = -1;
        next U;
      } else {
        $ReferredResource{$res->uri} = -1;
      }
    } elsif ($res->is_type_uri (ExpandedURI q<DISLang:Const>)) {
      my $m = $res->parent_resource;
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<DISLang:ConstGroup>)) {
        unshift @ruri, $m->uri;
        $ReferredResource{$res->uri} = -1;
        next U;
      } else {
        $ReferredResource{$res->uri} = -1;
        next U;
      }
    } elsif ($res->is_type_uri
               (ExpandedURI q<ManakaiDOM:ExceptionOrWarningSubType>)) {
      my $m = $res->parent_resource;
      if (not ($ReferredResource{$m->uri} < 0) and
          $m->is_type_uri (ExpandedURI q<DISLang:Const>)) {
        unshift @ruri, $m->uri;
        $ReferredResource{$res->uri} = -1;
        next U;
      } else {
        $ReferredResource{$res->uri} = -1;
        next U;
      }
    } elsif ($res->is_type_uri (ExpandedURI q<doc:Documentation>)) {
      append_document_documentation (source_resource => $res,
                                     result_parent => $body);
    } else {  ## Unsupported type
      $ReferredResource{$uri} = -1;
    }
  } # U
}

status_msg '';
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

  verbose_msg_ q<...>;

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

  verbose_msg_ q<...>;

  for my $class_uri (keys %ClassMembers) {
    my $cls_res = $db->get_resource ($class_uri);
    next unless $cls_res->is_defined;
    verbose_msg_ q<.>;
    my $cls_el = $body->create_module ($cls_res->owner_module->uri);
    if ($cls_res->is_type_uri (ExpandedURI q<DISLang:Interface>)) {
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
  my $lsimpl = $impl->get_feature (ExpandedURI q<DOMLS:Generic> => '3.0');
  my $serializer = $lsimpl->create_gls_serializer
                        ({ExpandedURI q<DOMLS:SerializeDocumentInstance> => ''});
  print STDOUT Encode::encode ('utf8', $serializer->write_to_string ($doc));
  close STDOUT;
  status_msg qq<done>;
  $doc->free;
}

verbose_msg_ qq<Checking undefined resources...>;
$db->check_undefined_resource;
verbose_msg qq<done>;

verbose_msg_ qq<Closing database...>;
$db->free;
undef $db;
verbose_msg qq<done>;

{
  use integer;
  my $time = time - $start_time;
  status_msg sprintf qq<%d'%02d''>, $time / 60, $time % 60;
}

exit;

END {
  $db->free if $db;
}

sub dac_search_file_path_stem ($$$) {
  my ($ns, $ln, $suffix) = @_;
  require Cwd;
  require File::Spec;
  for my $dir ('.', @{$Opt{input_search_path}->{$ns}||[]}) {
    my $name = Cwd::abs_path
        (File::Spec->canonpath
         (File::Spec->catfile ($dir, $ln)));
    if (-f $name.$suffix) {
      return $name;
    }
  }
  return undef;
} # dac_search_file_path_stem;

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

1; # $Date: 2005/11/15 14:18:23 $
