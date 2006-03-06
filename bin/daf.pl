#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  c => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  DOMLS => q<http://suika.fam.cx/~wakaba/archive/2004/dom/ls#>,
  dp => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#Perl/>,
  fe => q<http://suika.fam.cx/www/2006/feature/>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  pc => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/PerlCode#>,
  swcfg21 => q<http://suika.fam.cx/~wakaba/archive/2005/swcfg21#>,
  test => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Test#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

use Cwd;
use Getopt::Long;
use Pod::Usage;
my %Opt = (create_module => []);
GetOptions (
  'create-perl-module=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 3];
    $i->[3] = 'perl-pm';
    push @{$Opt{create_module}}, $i;
  },
  'create-perl-test=s' => sub {
    shift;
    my $i = [split /\s+/, shift, 3];
    $i->[3] = 'perl-t';
    push @{$Opt{create_module}}, $i;
  },
  'debug' => \$Opt{debug},
  'dis-file-suffix=s' => \$Opt{dis_suffix},
  'daem-file-suffix=s' => \$Opt{daem_suffix},
  'dafx-file-suffix=s' => \$Opt{dafx_suffix},
  'help' => \$Opt{help},
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
$Message::DOM::DOMFeature::DEBUG = 1 if $Opt{debug};
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

## ---- The MAIN Program

my $start_time;
BEGIN { $start_time = time }

use Message::Util::DIS::DNLite;
use Message::Util::PerlCode;
use Message::Util::DIS::Test;
use Message::DOM::GenericLS;

my $limpl = $Message::DOM::ImplementationRegistry->get_implementation
                           ({ExpandedURI q<fe:Min> => '3.0',
                             ExpandedURI q<fe:GenericLS> => '3.0',
                             '+' . ExpandedURI q<DIS:DNLite> => '1.0',
                             '+' . ExpandedURI q<DIS:Core> => '1.0',
                             '+' . ExpandedURI q<Util:PerlCode> => '1.0',
                             '+' . ExpandedURI q<DIS:TDT> => '1.0',
                           });
my $impl = $limpl->get_feature (ExpandedURI q<DIS:Core> => '1.0');
my $pc = $impl->get_feature (ExpandedURI q<Util:PerlCode> => '1.0');
my $di = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0');
my $tdt_parser;

## --- Loading and Updating the Database

my $HasError;
my $db = $impl->create_dis_database;
$db->pl_database_module_resolver (\&daf_db_module_resolver);
$db->dom_config->set_parameter ('error-handler' => \&daf_on_error);

my $parser = $impl->create_dis_parser;
my $DNi = $impl->get_feature (ExpandedURI q<DIS:DNLite> => '1.0');
my %ModuleSourceDISDocument;
my %ModuleSourceDNLDocument;
my %ModuleNameNamespaceBinding = (
  DISCore => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Core#>,
    ## This builtin binding is required since
    ## some module has |DISCore:author| property before |dis:Require|
    ## property.
);

my @target_modules;
for (@{$Opt{create_module}}) {
  my ($mod_uri, $out_path, $mod_for, $out_type) = @$_;
  push @target_modules, [$mod_uri, $mod_for];
}

my $ResourceCount = 0;
$db->pl_update_module (\@target_modules,
get_module_index_file_name => sub {
  shift; # $db
  daf_get_module_index_file_name (@_);
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
get_module_source_document_from_resource => sub ($$$$$$) {
  my ($self, $db, $uri, $ns, $ln, $for) = @_;
  status_msg '';
  status_msg qq<Loading module "$ln" for <$for>...>;
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
});
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

undef $DNi;
undef %ModuleSourceDNLDocument;
exit $HasError if $HasError;

## --- Creating Files

for (@{$Opt{create_module}}) {
  my ($mod_uri, $out_file_path, $mod_for, $out_type) = @$_;
  unless (defined $mod_for) {
    $mod_for = $db->get_module ($mod_uri)
                  ->get_property_text (ExpandedURI q<dis:DefaultFor>,
                                       ExpandedURI q<ManakaiDOM:all>);
  }
  my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);

  if ($out_type eq 'perl-pm') {
    status_msg_ qq<Generating Perl module from <$mod_uri> for <$mod_for>...>;
    my $pl = $mod->pl_generate_perl_module_file;
    status_msg qq<done>;

    my $output;
    defined $out_file_path
        ? (open $output, '>', $out_file_path or die "$0: $out_file_path: $!")
        : ($output = \*STDOUT);

    status_msg_ sprintf qq<Writing Perl module %s...>,
                          defined $out_file_path
                            ? q<">.$out_file_path.q<">
                            : 'to stdout';
    print $output $pl->stringify;
    close $output;
    status_msg q<done>;
  } elsif ($out_type eq 'perl-t') {
    status_msg_ qq<Generating Perl test from <$mod_uri> for <$mod_for>...>;
    my $pl = daf_generate_perl_test_file ($mod);
    status_msg qq<done>;

    my $cfg = $pl->owner_document->dom_config;
    $cfg->set_parameter (ExpandedURI q<pc:preserve-line-break> => 1);

    my $output;
    defined $out_file_path
        ? (open $output, '>', $out_file_path or die "$0: $out_file_path: $!")
          : ($output = \*STDOUT);

    status_msg_ sprintf qq<Writing Perl test %s...>,
                          defined $out_file_path
                            ? q<">.$out_file_path.q<">
                            : 'to stdout';
    print $output $pl->stringify;
    close $output;
    status_msg q<done>;
  }
}

daf_check_undefined ();

## --- The END

status_msg_ "Closing the database...";
$db->free;
undef $db;
status_msg "done";

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
    my $dnl_doc = $DNi->convert_dis_document_to_dnl_document
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

sub daf_get_module_index_file_name ($$) {
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
  my $suffix = $type eq ExpandedURI q<dp:ModuleIndexFile>
                 ? $Opt{dafx_suffix} : $Opt{daem_suffix};
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

sub daf_generate_perl_test_file ($) {
  my $mod = shift;
  my $pl = $pc->create_perl_file;
  my $pack = $pl->get_last_package ("Manakai::Test", make_new_package => 1);
  $pack->add_use_perl_module_name ("Message::Util::DIS::Test");
  $pack->add_use_perl_module_name ("Message::Util::Error");
  $pack->add_require_perl_module_name ($mod->pl_fully_qualified_name);

  $pl->source_file ($mod->get_property_text (ExpandedURI q<DIS:sourceFile>, ""));
  $pl->source_module ($mod->name_uri);
  $pl->source_for ($mod->for_uri);
  $pl->license_uri ($mod->get_property_resource (ExpandedURI q<dis:License>)
                        ->uri);

  $pack->append_code
    ($pc->create_perl_statement
       ('my $impl = $Message::DOM::ImplementationRegistry->get_implementation ({
           "http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#Test"
             => "1.0",
         })'));

  $pack->append_code
      (my $num_statement = $pc->create_perl_statement 
                                  ('my $test = $impl->create_test_manager'));

  my $total_tests = 0;
  my %processed;
  for my $res (@{$mod->get_resource_list}) {
    next if $res->owner_module ne $mod or $processed{$res->uri};
    $processed{$res->uri} = 1;

    if ($res->is_type_uri (ExpandedURI q<test:Test>)) {
      if ($res->is_type_uri (ExpandedURI q<test:StandaloneTest>)) {
        $total_tests++;
        $pack->append_code ('$test->start_new_test (');
        $pack->append_new_pc_literal ($res->name_uri || $res->uri);
        $pack->append_code (');');
        
        $pack->append_code ('try {');
        
        my $test_pc = $res->pl_code_fragment;
        if (not defined $test_pc) {
          die "Perl test code not defined for <".$res->uri.">";
        }
        
        $pack->append_code_fragment ($test_pc);
        
        $pack->append_code ('$test->ok;');
        
        $pack->append_code ('} catch Message::Util::IF::DTException with {
          ##
        } otherwise {
          my $err = shift;
          warn $err;
          $test->not_ok;
        };');

      } elsif ($res->is_type_uri (ExpandedURI q<test:ParserTestSet>)) {
        my $block = $pack->append_new_pc_block;
        my @test;
        
        $tdt_parser ||= $limpl->create_gls_parser
                                 ({
                                   ExpandedURI q<DIS:TDT> => '1.0',
                                  });
        for my $tres (@{$res->get_child_resource_list_by_type
                                (ExpandedURI q<test:ParserTest>)}) {
          $total_tests++;
          push @test, my $ttest = {entity => {}};
          $ttest->{uri} = $tres->uri;
          for my $eres (@{$tres->get_child_resource_list_by_type
                                   (ExpandedURI q<test:Entity>)}) {
            my $tent = $ttest->{entity}->{$eres->uri} = {};
            for (ExpandedURI q<test:uri>, ExpandedURI q<test:baseURI>,
                 ExpandedURI q<test:value>) {
              my $v = $eres->get_property_text ($_);
              $tent->{$_} = $v if defined $v;
            }
            $ttest->{root_uri} = $eres->uri
              if $eres->is_type_uri (ExpandedURI q<test:RootEntity>) or
                 not defined $ttest->{root_uri};
          }

          ## Result DOM tree
          my $tree_t = $tres->get_property_text (ExpandedURI q<test:domTree>); 
          if (defined $tree_t) {
            $ttest->{dom_tree} = $tdt_parser->parse_string ($tree_t);
          }

          ## Expected |DOMError|s
          for (@{$tres->get_property_value_list (ExpandedURI q<c:erred>)}) {
            my $err = $tdt_parser->parse_tdt_error_string
                                     ($_->string_value, $db, $_,
                                      undef, $tres->for_uri);
            push @{$ttest->{dom_error}->{$err->{type}->{value}} ||= []}, $err;
          }
        }

        for ($block->append_statement
                   ->append_new_pc_expression ('=')) {
          $_->append_new_pc_variable ('$', undef, 'TestData')
            ->variable_scope ('my');
          $_->append_new_pc_literal (\@test);
        }
        
        my $plc = $res->pl_code_fragment;
        unless ($plc) {
          die "Resource <".$res->uri."> does not have Perl test code";
        }

        $block->append_code_fragment ($plc);
        
      } # test resource type
    } # test:Test
  }
  
  $num_statement->append_code (' (' . $total_tests . ')');

  return $pl;
} # daf_generate_perl_test_file

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

=item C<--output-file-name=I<file-name>> (Required)

The 

=back

=head1 SEE ALSO

L<bin/dac2pm.pl> - Generating Perl module from "dac" file.

L<lib/Message/Util/DIS.dis> - The actual implementation
of the "dis" interpretation.

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
