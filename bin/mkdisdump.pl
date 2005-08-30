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

sub append_module_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_module ($opt{source_resource}->uri);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);
    my $path = $pl_full_name;
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));
  }

  $section->resource_file_name_stem ($opt{source_resource}->pl_file_name_stem);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

  for my $rres (@{$opt{source_resource}->get_property_resource_list
                           (ExpandedURI q<DIS:resource>)}) {
    if ($rres->owner_module eq $opt{source_resource}) { ## Defined in this module
                          ## TODO: Modification required to support modplans
      print STDERR "*";
      if ($rres->is_type_uri (ExpandedURI q<ManakaiDOM:Class>)) {
        append_class_documentation
          (result_parent => $section,
           source_resource => $rres);
      } elsif ($rres->is_type_uri (ExpandedURI q<ManakaiDOM:IF>)) {
        append_interface_documentation
          (result_parent => $section,
           source_resource => $rres);
      }
    } else {  ## Aliases
      # 
    }
  }
  print STDERR "\n";
} # append_module_documentation

sub append_interface_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_interface
                                        ($opt{source_resource}->uri);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);
    my $path = $pl_full_name;
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath',
       join '', '../' x ($path =~ tr#/#/#));
  }

  $section->resource_file_name_stem ($opt{source_resource}->pl_file_name_stem);

  $section->is_exception_interface (1)
    if $opt{source_resource}->is_type_uri
                                 (ExpandedURI q<ManakaiDOM:ExceptionIF>);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

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

    }
  }
} # append_interface_documentation

sub append_class_documentation (%) {
  my %opt = @_;
  my $section = $opt{result_parent}->create_class ($opt{source_resource}->uri);

  my $pl_full_name = $opt{source_resource}->pl_fully_qualified_name;
  if (defined $pl_full_name) {
    $section->perl_package_name ($pl_full_name);
    my $path = $pl_full_name;
    $path =~ s#::#/#g;
    $section->resource_file_path_stem ($path);
    $section->set_attribute_ns
      (ExpandedURI q<ddoct:>, 'ddoct:basePath', '../' x ($path =~ tr#/#/#));
  }

  $section->resource_file_name_stem ($opt{source_resource}->pl_file_name_stem);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $section);

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
    } elsif ($memres->is_type_uri (ExpandedURI q<ManakaiDOM:Const>)) {

    } elsif ($memres->is_type_uri (ExpandedURI q<ManakaiDOM:ConstGroup>)) {

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

  $m->add_uri ($opt{source_resource}->uri);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m);

  my $ret = $opt{source_resource}->get_child_resource_by_type
    (ExpandedURI q<DISLang:MethodReturn>);
  if ($ret) {
    my $r = $m->dis_return;

    try {
      $r->resource_data_type ($ret->dis_data_type_resource->uri);
      $r->resource_actual_data_type ($ret->dis_actual_data_type_resource->uri);
      
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

  $m->add_uri ($opt{source_resource}->uri);
  
  append_description (source_resource => $opt{source_resource},
                      result_parent => $m,
                      has_case => 1);

  my $ret = $opt{source_resource}->get_child_resource_by_type
    (ExpandedURI q<DISLang:AttributeGet>);
  if ($ret) {
    my $r = $m->dis_get;

    $r->resource_data_type ($ret->dis_data_type_resource->uri);
    $r->resource_actual_data_type ($ret->dis_actual_data_type_resource->uri);
    
    append_description (source_resource => $ret,
                        result_parent => $r,
                        has_case => 1);

    ## TODO: Exceptions
  }

  my $set = $opt{source_resource}->get_child_resource_by_type
    (ExpandedURI q<DISLang:AttributeSet>);
  if ($set) {
    my $r = $m->dis_set;

    $r->resource_data_type ($set->dis_data_type_resource->uri);
    $r->resource_actual_data_type ($set->dis_actual_data_type_resource->uri);
    
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

sub append_param_documentation (%) {
  my %opt = @_;
  
  my $is_named_param = $opt{source_resource}->get_property_boolean
    (ExpandedURI q<DISPerl:isNamedParameter>, 0);

  my $perl_name = $is_named_param
    ? $opt{source_resource}->pl_name
    : $opt{source_resource}->pl_variable_name;
  
  my $p = $opt{result_parent}->create_parameter ($perl_name, $is_named_param);
  
  $p->is_nullable_parameter ($opt{source_resource}->pl_is_nullable);
  $p->resource_data_type ($opt{source_resource}->dis_data_type_resource->uri);
  $p->resource_actual_data_type
    ($opt{source_resource}->dis_actual_data_type_resource->uri);

  append_description (source_resource => $opt{source_resource},
                      result_parent => $p,
                      has_case => 1);
} # append_param_documentation

sub append_description (%) {
  my %opt = @_;
  my $od = $opt{result_parent}->owner_document;
  my $resd = $opt{source_resource}->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
  my $doc = $resd->get_description ($od);
  $opt{result_parent}->create_description->append_child ($doc);
  ## TODO: Negotiation

  if ($opt{has_case}) {
    for my $caser (@{$opt{source_resource}->get_property_resource_list
                      (ExpandedURI q<DIS:childResource>)}) {
      if ($caser->is_type_uri (ExpandedURI q<ManakaiDOM:InCase>)) {
        my $case = $opt{result_parent}->append_case;
        my $cased = $caser->get_feature (ExpandedURI q<DIS:Doc>, '2.0');
        my $label = $cased->get_label ($od);
        if ($label) {
          $case->create_label->append_child ($label);
        }
        my $value = $caser->pl_code_fragment;
        if ($value) {
          $case->create_value->text_content ($value->stringify);
        }
        append_description (source_resource => $caser,
                            result_parent => $case);
      }
    }
  }
} # append_description

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
    }
  }
} # append_inheritance

my $doc = $impl->create_disdump_document;

my $body = $doc->document_element;

append_module_documentation
  (result_parent => $body,
   source_resource => $mod);

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

1; # $Date: 2005/08/30 12:30:45 $
