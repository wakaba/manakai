#!/usr/bin/perl -w 
use strict;

use Getopt::Long;
use Pod::Usage;
my %Opt;
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
) or pod2usage (2);
if ($Opt{help}) {
  pod2usage (0);
  exit;
}

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}
our $State;
our $ClassDefElementTypes;

my $ManakaiDOMModulePrefix = 'Message::DOM::';
sub perl_package_name (%) {
  my %opt = @_;
  my $r;
  if ($opt{if}) {
    $r = $ManakaiDOMModulePrefix . q<::IF::> . perl_name $opt{if};
  } elsif ($opt{iif}) {
    $r = $ManakaiDOMModulePrefix . q<::IIF::> . perl_name $opt{iif};
  } elsif ($opt{name} or $opt{name_with_condition}) {
    if ($opt{name_with_condition}) {
      if ($opt{name_with_condition} =~ /^([^:]+)::([^:]+)$/) {
        $opt{name} = $1;
        $opt{condition} = $2;
      } else {
        $opt{name} = $opt{name_with_condition};
      }
    } 
    $opt{name} = perl_name $opt{name};
    $opt{name} = $opt{prefix} . '::' . $opt{name} if $opt{prefix};
    $r = $ManakaiDOMModulePrefix . q<::> . $opt{name};
  } elsif ($opt{qname} or $opt{qname_with_condition}) {
    if ($opt{qname_with_condition}) {
      if ($opt{qname_with_condition} =~ /^(.+)::([^:]*)$/) {
        $opt{qname} = $1;
        $opt{condition} = $2;
      } else {
        $opt{qname} = $opt{qname_with_condition};
      }
    }
    if ($opt{qname} =~ /^([^:]*):(.*)$/) {
      $opt{ns_prefix} = $1;
      $opt{name} = $2;
    } else {
      $opt{ns_prefix} = '#default';
      $opt{name} = $opt{qname};
    }
    ## ISSUE: Prefix to ...
    #$r = ns_uri_to_perl_package_name (ns_prefix_to_uri ($opt{ns_prefix})) .
    #     '::' . $opt{name};
    $r = $ManakaiDOMModulePrefix . '::' . $opt{name};
  } elsif ($opt{if_qname} or $opt{if_qname_with_condition}) {
    if ($opt{if_qname_with_condition}) {
      if ($opt{if_qname_with_condition} =~ /^(.+)::([^:]*)$/) {
        $opt{if_qname} = $1;
        $opt{condition} = $2;
      } else {
        $opt{if_qname} = $opt{if_qname_with_condition};
      }
    }
    if ($opt{if_qname} =~ /^([^:]*):(.*)$/) {
      $opt{ns_prefix} = $1;
      $opt{name} = $2;
    } else {
      $opt{ns_prefix} = '#default';
      $opt{name} = $opt{if_qname};
    }
    ## ISSUE: Prefix to ...
    #$r = ns_uri_to_perl_package_name (ns_prefix_to_uri ($opt{ns_prefix})) .
    #     '::' . $opt{name};
    $r = $ManakaiDOMModulePrefix . '::IF::' . $opt{name};
  } elsif ($opt{full_name}) {
    $r = $opt{full_name};
  } else {
    valid_err q<$opt{name} is false>;
  }
  if ($opt{condition}) {
    $r = $r . '::' . perl_name $opt{condition};
  }
  if ($opt{is_internal}) {
    $r .= '::_internal';
    $r .= '_inherit' if $opt{is_for_inheriting};
  }
  $r;
} # perl_package_name

sub perl_change_package (%) {
  my $fn = perl_package_name @_;
  unless ($fn eq $State->{perl_current_package}) {
    $State->{perl_current_package} = $fn;
    return perl_statement qq<package $fn>;
  } else {
    return '';
  }
} # perl_change_package

sub dispm_root_node ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  for (@{$node->child_nodes}) {
    next unless $_->node_type eq '#element';
    next unless dis_node_for_match $_, $opt{For}, %opt;
    my $ln = $_->local_name;
    if ($ClassDefElementTypes->{$ln}) {
      $r .= dispm_classdefs_element ($_, %opt);
    } elsif ({qw/Const 1/}->{$ln}) {
      ## TODO: 
    } elsif ({qw/Module 1 Namespace 1/}->{$ln}) {
      # 
    } else {
      valid_err q<Unknown element type>, node => $_;
    }
  }
  $r;
} # dispm_root_node

sub dispm_classdefs_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  my $ln = $node->local_name;
  for ([ExpandedURI q<ManakaiDOM:Class>, \&dispm_classdef_element],
       [ExpandedURI q<ManakaiDOM:IF>, \&dispm_ifdef_element],
       [ExpandedURI q<ManakaiDOM:Exception>, \&dispm_exceptiondef_element],
       [ExpandedURI q<ManakaiDOM:Warning>, \&dispm_warningdef_element],
       [ExpandedURI q<ManakaiDOM:DataType>, \&dispm_datatypedef_element],
       [ExpandedURI q<ManakaiDOM:ConstGroup>, \&dispm_constgroup_element]) {
    my $type = dis_get_attr_node (%opt, parent => $node,
                                  name => 'Type');
    if (defined $type) {
      ## Matched explicitly or implicitly
      if ($type ? dis_uri_ctype_match ($type->value, $_->[0], %opt) : 1) {
        $r .= $_->[1]->($node, %opt);
      }
    }
  } 
  return $r;
} # dispm_classdefs_element

sub dispm_classdef_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  return $r;
} # dispm_classdef_element

sub dispm_ifdef_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  return $r;
} # dispm_ifdef_element

sub dispm_exceptiondef_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  return $r;
} # dispm_exceptiondef_element

sub dispm_warningdef_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  return $r;
} # dispm_warningdef_element

sub dispm_datatypedef_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  return $r;
} # dispm_datatypedef_element

sub dispm_constgroupdef_element ($;%) {
  my ($node, %opt) = @_;
  my $r = '';
  return $r;
} # dispm_constgroupdef_element


$Opt{file_name} = shift;

$State->{DefaultFor} = $Opt{For};
my $source = dis_load_module_file (module_file_name => $Opt{file_name},
                                   for => $Opt{For},
                                   use_default_for => 1);
$State->{for_def_required}->{$State->{DefaultFor}} ||= 1;

dis_check_undef_type_and_for ();
$State->{perl_primary_module} = $State->{Module}->{$State->{module}};

my $result = '';
$State->{perl_current_package} = 'main';
$result .= perl_comment q<This file is automatically generated from> . "\n" .
                        q<"> . $Opt{file_name} . q<" at > .
                        rfc3339_date (time) . qq<.\n> .
                        q<Don't edit by hand!>;

$result .= perl_statement q<use strict>;
$State->{perl_defined_package}
      ->{$State->{perl_primary_module}->{perl_package_name}} = 1;
$result .= dispm_root_node ($source);

## Export
if (keys %{$State->{perl_primary_module}->{perl_export_ok}||{}}) {
  $result .= perl_change_package
               full_name => $State->{perl_primary_module}->{perl_package_name};
  $result .= perl_statement 'require Exporter';
  $result .= perl_inherit ['Exporter'];
  $result .= perl_statement
               perl_assign
                    perl_var (type => '@', scope => 'our',
                              local_name => 'EXPORT_OK')
                 => '(' . perl_list (keys %{$State->{perl_primary_module}
                                                  ->{perl_export_ok}}) . ')';
  if (keys %{$State->{perl_primary_module}->{perl_export_tags}||{}}) {
    $result .= perl_statement
                 perl_assign
                       perl_var (type => '%', scope => 'our',
                                 local_name => 'EXPORT_TAGS')
                   => '(' . perl_list (map {
                         $_ => [keys %{$State->{perl_primary_module}
                                             ->{perl_export_tags}->{$_}}]
                      } keys %{$State->{perl_primary_module}
                                     ->{perl_export_tags}}) . ')';
  }
}

## Packages
{
  my $list = join ', ', map {'$'.$_.'::VERSION'}
                        sort keys %{$State->{perl_defined_package}};
  my $date = perl_literal version_date time;
  $result .= qq{
               for ($list) {
                 \$_ = $date;
               }
  };
}
$result .= perl_statement 1;

output_result $result;

1;
