#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dp => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#Perl/>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  swcfg21 => q<http://suika.fam.cx/~wakaba/archive/2005/swcfg21#>,
};

our$VERSION=do{my @r=(q$Revision: 1.23 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Cwd;
use Getopt::Long;
use Pod::Usage;
our %Opt = (create_module => []);
my @target_modules;
GetOptions (
  'create-dtd-driver=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 3];
    $i->[3] = 'dtd-driver';
    push @{$Opt{create_module}}, $i;
  },
  'create-dtd-modules=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 3];
    $i->[3] = 'dtd-modules';
    push @{$Opt{create_module}}, $i;
  },
  'create-perl-module=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 3];
    $i->[3] = 'perl-pm';
    push @{$Opt{create_module}}, $i;
    push @target_modules, $i->[0];
  },
  'create-perl-test=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 3];
    $i->[3] = 'perl-t';
    push @{$Opt{create_module}}, $i;
    push @target_modules, $i->[0];
  },
  'debug' => \$Opt{debug},
  'dis-file-suffix=s' => \$Opt{dis_suffix},
  'daem-file-suffix=s' => \$Opt{daem_suffix},
  'dafs-file-suffix=s' => \$Opt{dafs_suffix},
  'dafx-file-suffix=s' => \$Opt{dafx_suffix},
  'dtd-file-suffix=s' => \$Opt{dtd_suffix},
  'help' => \$Opt{help},
  'load-module=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 2];
    push @target_modules, $i->[0];
  },
  'mod-file-suffix=s' => \$Opt{mod_suffix},
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
  'undef-check!' => \$Opt{no_undef_check},
  'verbose!' => \$Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{no_undef_check} = defined $Opt{no_undef_check}
                         ? $Opt{no_undef_check} ? 0 : 1 : 0;
$Opt{dis_suffix} = '.dis' unless defined $Opt{dis_suffix};
$Opt{daem_suffix} = '.dafm' unless defined $Opt{daem_suffix};
$Opt{dafx_suffix} = '.dafx' unless defined $Opt{dafx_suffix};
$Opt{dafs_suffix} = '.dafs' unless defined $Opt{dafs_suffix};
$Opt{dtd_suffix} = '.dtd' unless defined $Opt{dtd_suffix};
$Opt{mod_suffix} = '.mod' unless defined $Opt{mod_suffix};
require Error;
$Error::Debug = 1 if $Opt{debug};
$Message::Util::Error::VERBOSE = 1 if $Opt{verbose};

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

sub daf_open_source_dis_document ($);
sub daf_open_current_module_index ($$);
sub daf_convert_dis_document_to_dnl_document ();
sub daf_get_referring_module_uri_list ($);
sub dac_search_file_path_stem ($$$);
sub daf_get_module_index_file_name ($);
sub daf_check_undefined ();

## ---- The MAIN Program

my $start_time;
BEGIN { $start_time = time }

use Message::DOM::DOMCore;

for (@{$Opt{create_module}}) {
  my (undef, undef, undef, $out_type) = @$_;

  if ($out_type eq 'perl-pm') {
    require 'manakai/daf-perl-pm.pl';
  } elsif ($out_type eq 'perl-t') {
    require 'manakai/daf-perl-t.pl';
  } elsif ($out_type eq 'dtd-modules') {
    require 'manakai/daf-dtd-modules.pl';
  } elsif ($out_type eq 'dtd-driver') {
    require 'manakai/daf-dtd-modules.pl';
  }
}

our $impl = $Message::DOM::ImplementationRegistry->get_dom_implementation;

## --- Loading and Updating the Database

my $HasError;
our $db = $impl->create_dis_database;
$db->pl_database_module_resolver (\&daf_db_module_resolver);
$db->dom_config->set_parameter ('error-handler' => \&daf_on_error);

my $parser = $impl->create_dis_parser;
my %ModuleSourceDISDocument;
my %ModuleSourceDNLDocument;
my %ModuleNameNamespaceBinding = (
  DISCore => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Core#>,
    ## This builtin binding is required since
    ## some module has |DISCore:author| property before |dis:Require|
    ## property.
);

my $ResourceCount = 0;
$db->pl_update_module (\@target_modules,
get_module_index_file_name => sub {
  shift; # $db
  daf_get_module_index_file_name (shift);
},
get_module_source_document_from_uri => sub {
  my ($db, $module_uri, $module_for) = @_;
  status_msg '';
  status_msg qq<Loading module <$module_uri> for <$module_for>...>;
  $ResourceCount = 0;

  unless (defined $ModuleSourceDNLDocument{$module_uri}) {
    unless (defined $ModuleSourceDISDocument{$module_uri}) {
      daf_open_source_dis_document ($module_uri);
    }
    daf_convert_dis_document_to_dnl_document ();
  }
  return $ModuleSourceDNLDocument{$module_uri};
},
get_module_source_document_from_resource => sub ($$$$$) {
  my ($self, $db, $uri, $ns, $ln) = @_;
  status_msg '';
  status_msg qq<Loading module "$ln"...>;
  $ResourceCount = 0;

  my $module_uri = $ns.$ln;
  unless (defined $ModuleSourceDNLDocument{$module_uri}) {
    unless (defined $ModuleSourceDISDocument{$module_uri}) {
      daf_open_source_dis_document ($module_uri);
    }
    daf_convert_dis_document_to_dnl_document ();
  }
  return $ModuleSourceDNLDocument{$module_uri};
},
get_module_source_revision => sub {
  my ($db, $module_uri) = @_;
  my $ns = $module_uri;
  $ns =~ s/(\w+)\z//;
  my $ln = $1;

  my $name = dac_search_file_path_stem ($ns, $ln, $Opt{dis_suffix});
  if (defined $name) {
    return [stat $name.$Opt{dis_suffix}]->[9];
  } else {
    return 0;
  }
},
get_referring_module_uri_list => sub {
  my ($db, $module_uri) = @_;
  unless (defined $ModuleSourceDNLDocument{$module_uri}) {
    unless (defined $ModuleSourceDISDocument{$module_uri}) {
      daf_open_source_dis_document ($module_uri);
    }
  }
  return daf_get_referring_module_uri_list ($module_uri);
},
on_resource_read => sub ($$) {
  if ((++$ResourceCount % 10) == 0) {
    status_msg_ "*";
    status_msg_ " " if ($ResourceCount % (10 * 10)) == 0;
    status_msg '' if ($ResourceCount % (10 * 50)) == 0;
  }
});


## Removes reference from document to database
our @Document;
for my $dis (@Document) {
  $dis->unlink_from_document;
  $dis->dis_database (undef);
}

status_msg '';

status_msg qq<Reading properties...>;
$ResourceCount = 0;
$db->read_properties (on_resource_read => sub ($$) {
  if ((++$ResourceCount % 10) == 0) {
    status_msg_ "*";
    status_msg_ " " if ($ResourceCount % (10 * 10)) == 0;
    status_msg '' if ($ResourceCount % (10 * 50)) == 0;
  }
}, implementation => $impl);
status_msg '';
status_msg "done";

status_msg_ qq<Writing database files...>;
$db->pl_store ('dummy', sub ($$) {
  my ($db, $mod, $type) = @_;
  my $ns = $mod->namespace_uri;
  my $ln = $mod->local_name;
  my $suffix = $type eq ExpandedURI q<dp:ModuleIndexFile>
                 ? $Opt{dafx_suffix} : $Opt{daem_suffix};
  my $name = dac_search_file_path_stem ($ns, $ln, $suffix);
  if (defined $name) {
    $name .= $suffix;
  } elsif (defined ($name = dac_search_file_path_stem
                              ($ns, $ln, $Opt{dis_suffix}))) {
    $name .= $suffix;
  } else {
    $name = Cwd::abs_path
              (File::Spec->canonpath
                 (File::Spec->catfile
                    (defined $Opt{input_search_path}->{$ns}->[0]
                       ? $Opt{input_search_path}->{$ns}->[0] : '.',
                     $ln.$suffix)));
  }
  verbose_msg qq<Database >.
              ($type eq <Q::dp|ModuleIndexFile> ? 'index' : 'module').
              qq< <$ns$ln> is written to "$name">;
  return $name;
}, no_main_database => 1);
status_msg "done";

daf_check_undefined ();

undef %ModuleSourceDNLDocument;
exit $HasError if $HasError;

## --- Creating Files

for (@{$Opt{create_module}}) {
  my ($mod_uri, $out_file_path, undef, $out_type) = @$_;

  if ($out_type eq 'perl-pm') {
    daf_perl_pm ($mod_uri, $out_file_path);
  } elsif ($out_type eq 'perl-t') {
    daf_perl_t ($mod_uri, $out_file_path);
  } elsif ($out_type eq 'dtd-modules') {
    daf_dtd_modules ($mod_uri, $out_file_path);
  } elsif ($out_type eq 'dtd-driver') {
    daf_dtd_driver ($mod_uri, $out_file_path);
  }
}

daf_check_undefined ();

## --- The END

status_msg_ "Closing the database...";
$db->free;
undef $db;
status_msg "done";

undef $impl;

{
  use integer;
  my $time = time - $start_time;
  status_msg sprintf qq<%d'%02d''>, $time / 60, $time % 60;
}
exit $HasError;

END {
  $db->free if $db;
}

## ---- Subroutines

sub daf_open_source_dis_document ($) {
  my ($module_uri) = @_;

  ## -- Finds |dis| source file
  my $ns = $module_uri;
  $ns =~ s/(\w+)\z//;
  my $ln = $1;
  my $file_name = dac_search_file_path_stem ($ns, $ln, $Opt{dis_suffix});
  unless (defined $file_name) {
    die "$0: Source file for <$ns$ln> is not found";
  }
  $file_name .= $Opt{dis_suffix};

  status_msg_ qq<Opening dis source file "$file_name"...>;

  ## -- Opens |dis| file and construct |DISDocument| tree
  open my $file, '<', $file_name or die "$0: $file_name: $!";
  my $dis = $parser->parse ({character_stream => $file});
  require File::Spec;
  $dis->flag (ExpandedURI q<swcfg21:fileName> =>
                  File::Spec->abs2rel ($file_name));
  $dis->dis_namespace_resolver (\&daf_module_name_namespace_resolver);
  close $file;

  ## -- Registers namespace URI
  my $mod = $dis->module_element;
  if ($mod) {
    my $qn = $mod->get_attribute_ns (ExpandedURI q<dis:>, 'QName');
    if ($qn) {
      my $prefix = $qn->value;
      $prefix =~ s/^[^:|]*[:|]\s*//;
      $prefix =~ s/\s+$//;
      unless (defined $ModuleNameNamespaceBinding{$prefix}) {
        $ModuleNameNamespaceBinding{$prefix} = $mod->defining_namespace_uri;
      }
    }
  }

  $ModuleSourceDISDocument{$module_uri} = $dis;
  status_msg q<done>;

  R: for (@{daf_get_referring_module_uri_list ($module_uri)}) {
    next R if defined $db->{modDef}->{$_};
    next R if defined $ModuleSourceDNLDocument{$_};
    next R if defined $ModuleSourceDISDocument{$_};
    my $idx_file_name = daf_get_module_index_file_name ($_);
    if (-f $idx_file_name) {
      daf_open_current_module_index ($_, $idx_file_name);
    } else {
      daf_open_source_dis_document ($_);
    }
  }
} # daf_open_source_dis_document

sub daf_open_current_module_index ($$) {
  my ($module_uri, $file_name) = @_;
  $db->pl_load_dis_database_index ($file_name);

  R: for (@{$db->get_module ($module_uri)
               ->get_referring_module_uri_list}) {
    next R if defined $db->{modDef}->{$_};
    next R if defined $ModuleSourceDNLDocument{$_};
    next R if defined $ModuleSourceDISDocument{$_};
    my $idx_file_name = daf_get_module_index_file_name ($_);
    if (-f $idx_file_name) {
      daf_open_current_module_index ($_, $idx_file_name);
    } else {
      daf_open_source_dis_document ($_);
    }
  }
} # daf_open_current_module_index

sub daf_convert_dis_document_to_dnl_document () {
  M: for my $module_uri (keys %ModuleSourceDISDocument) {
    my $dis_doc = $ModuleSourceDISDocument{$module_uri};
    next M unless $dis_doc;
    verbose_msg_ qq<Converting <$module_uri>...>;
    my $dnl_doc = $impl->convert_dis_document_to_dnl_document
                          ($dis_doc, database_arg => $db,
                           base_namespace_binding =>
                             {(map {$_->local_name => $_->target_namespace_uri}
                               grep {$_} values %{$db->{modDef}}),
                              %ModuleNameNamespaceBinding});
    push @Document, $dnl_doc;
    $ModuleSourceDNLDocument{$module_uri} = $dnl_doc;
    $dis_doc->free;
    delete $ModuleSourceDISDocument{$module_uri};
    verbose_msg q<done>;
  }
} # daf_convert_dis_document_to_dnl_document

sub daf_get_referring_module_uri_list ($) {
  my $module_uri = shift;
  my $ns = $module_uri;
  $ns =~ s/\w+\z//;
  my $src = $ModuleSourceDNLDocument{$module_uri};
  $src = $ModuleSourceDISDocument{$module_uri} unless defined $src;
  my $mod_el = $src->module_element;
  my $r = [];
  if ($mod_el) {
    my $req_el = $mod_el->require_element;
    if ($req_el) {
      M: for my $m_el (@{$req_el->child_nodes}) {
        next M unless $m_el->node_type eq '#element';
        next M unless $m_el->expanded_uri eq ExpandedURI q<dis:Module>;
        my $qn_el = $m_el->get_attribute_ns (ExpandedURI q<dis:>, 'QName');
        if ($qn_el) {
          push @$r, $qn_el->qname_value_uri;
        } else {
          my $n_el = $m_el->get_attribute_ns (ExpandedURI q<dis:>, 'Name');
          if ($n_el) {
            push @$r, $ns.$n_el->value;
          } else {
            # The module itself
          }
        }
      }
    }
  }
  return $r;
} # daf_get_referring_module_uri_list

sub dac_search_file_path_stem ($$$) {
  my ($ns, $ln, $suffix) = @_;
  require File::Spec;
  for my $dir (@{$Opt{input_search_path}->{$ns}||[]}) {
    my $name = Cwd::abs_path
        (File::Spec->canonpath
         (File::Spec->catfile ($dir, $ln)));
    if (-f $name.$suffix) {
      return $name;
    }
  }
  return undef;
} # dac_search_file_path_stem;

sub daf_get_module_index_file_name ($) {
  my ($module_uri) = @_;
  my $ns = $module_uri;
  $ns =~ s/(\w+)\z//;
  my $ln = $1;

  verbose_msg qq<Database module index <$module_uri> is requested>;
  my $suffix = $Opt{dafx_suffix};
  my $name = dac_search_file_path_stem ($ns, $ln, $suffix);
  if (defined $name) {
    $name .= $suffix;
  } elsif (defined ($name = dac_search_file_path_stem
                              ($ns, $ln, $Opt{dis_suffix}))) {
    $name .= $suffix;
  } else {
    $name = Cwd::abs_path
              (File::Spec->canonpath
                 (File::Spec->catfile
                    (defined $Opt{input_search_path}->{$ns}->[0]
                       ? $Opt{input_search_path}->{$ns}->[0] : '.',
                     $ln.$suffix)));
  }
  return $name;  
} # daf_get_module_index_file_name

sub daf_module_name_namespace_resolver ($) {
  my $prefix = shift;

  ## -- From modules in database
  M: for (values %{$db->{modDef}}) {
    my $mod = $_;
    next M unless defined $mod;
    if ($mod->local_name eq $prefix) {
      return $mod->target_namespace_uri;
    }
  }

  ## -- From not-in-database-yet module list
  if (defined $ModuleNameNamespaceBinding{$prefix}) {
    return $ModuleNameNamespaceBinding{$prefix};
  }
  return undef;
} # daf_module_name_namespace_resolver

sub daf_db_module_resolver ($$$) {
  my ($db, $mod, $type) = @_;
  my $ns = $mod->namespace_uri;
  my $ln = $mod->local_name;
  my $suffix = {
    ExpandedURI q<dp:ModuleIndexFile> => $Opt{dafx_suffix},
    ExpandedURI q<dp:ModuleResourceFile> => $Opt{daem_suffix},
    ExpandedURI q<dp:ModuleNodeStorageFile> => $Opt{dafs_suffix},
  }->{$type} or die "Unsupported type: <$type>";
  verbose_msg qq<Database module <$ns$ln> is requested>;
  my $name = dac_search_file_path_stem ($ns, $ln, $suffix);
  if (defined $name) {
    return $name.$suffix;
  } else {
    return undef;
  }
} # daf_db_module_resolver

sub daf_on_error ($$) {
  my ($self, $err) = @_;
  if ($err->severity == $err->SEVERITY_WARNING) {
    my $info = ExpandedURI q<dp:info>;
    if ($err->type =~ /\Q$info\E/) {
      my $msg = $err->text;
      if ($msg =~ /\.\.\.\z/) {
        verbose_msg_ $msg;
      } else {
        verbose_msg $msg;
      }
    } else {
      my $msg = $err->text;
      if ($msg =~ /\.\.\.\z/) {
        status_msg_ $msg;
      } else {
        status_msg $msg;
      }
    }
  } else {
    warn $err;
    $HasError = 1;
  }
} # daf_on_error

sub daf_check_undefined () {
  unless ($Opt{no_undef_check}) {
    status_msg_ "Checking undefined resources...";
    $db->check_undefined_resource;
    print STDERR "done\n";
  }
} # daf_check_undefined

__END__

=head1 NAME

dac.pl - Creating "dac" Database File from "dis" Source Files

=head1 SYNOPSIS

  perl path/to/dac.pl [--input-db-file-name=input.dac] \
                      --output-file-name=out.dac [options...] \
                      input.dis
  perl path/to/dac.pl --help

=head1 DESCRIPTION

This script, C<dac.pl>, compiles "dis" source files into "dac"
database file.  The generated database file can be used
in turn to generate Perl module file, for example, by another
script C<dac2pm.pl> or can be used to create larger database
by specifying its file name as the C<--input-db-file-name>
argument of another C<dac.pl> execution.

This script is part of manakai.

=head1 OPTIONS

=over 4

=item I<input.dis> (Required)

The unnamed option specifies a file name path of the source "dis" file
from which a database is created.  This option is required.

=item C<--input-db-file-name=I<file-name>> (Default: none)

A file path of the base database.  This option is optional; if this
option is specified, the database file is loaded first
and then I<input.dis> file is loaded in the context of it.
Otherwise, a new database is created.

=back

=head1 SEE ALSO

L<lib/Message/Util/DIS.dis> - The actual implementation
of the "dis" interpretation.

=head1 LICENSE

Copyright 2004-2006 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
