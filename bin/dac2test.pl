#!/usr/bin/perl -w 
use strict;

=head1 NAME

dac2pm - Generating Perl Module from "dac" File

=head1 SYNOPSIS

  perl path/to/dac2pm.pl input.dac \
            --module-uri=module-uri [--for=for-uri] [options] > ModuleName.pm
  perl path/to/dac2pm.pl input.dac \
            --module-uri=module-uri [--for=for-uri] [options] \
            --output-file-path=ModuleName.pm
  perl path/to/dac2pm.pl input.dac \
            --create-perl-module="module-uri ModuleName.pm [for-uri]" \
            [--create-perl-module="..." ...]
  perl path/to/dac2pm.pl --help

=head1 DESCRIPTION

The C<dac2pm.pl> script generates Perl modules from a "dac" database file
created by C<dac.pl>.

This script is part of manakai. 

=cut

use strict;
use Message::Util::QName::Filter {
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  DOMLS => q<http://suika.fam.cx/~wakaba/archive/2004/dom/ls#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Markup => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup#>,
  pc => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/PerlCode#>,
  test => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Test#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

=head1 OPTIONS

=over 4

=item --enable-assertion / --noenable-assertion (default)

Whether assertion codes should be outputed or not. 

=item --create-perl-module="I<module-uri> I<ModuleName.pm> [I<for-uri>]" (Zero or more)

The C<--create-perl-module> option can be used to specify
I<--module-uri>, I<--output-file-path>, and I<--for> options
once.  Its value is a space-separated triplet of "dis" module name URI,
Perl module file path (environment dependent), and optional
"dis" module "for" URI.

This option can be specified more than once; it would
make multiple Perl module files to be created.  If 
both I<--module-uri> and this options are specified,
I<--module-uri>, I<--output-file-path>, and I<--for>
options are treated as if there is another I<--create-perl-module>
option specified.

=item --for=I<for-uri> (Optional)

Specifies the "For" URI reference for which the outputed module is. 
If this parameter is ommitted, the default "For" URI reference 
for the module specified by the C<dis:DefaultFor> attribute
of the C<dis:Module> element, if any, or C<ManakaiDOM:all> is assumed. 

=item --help

Shows the help message. 

=item --module-uri=I<module-uri>

A URI reference that identifies a module from which a Perl
module file is generated.  This argument is I<required>.

=item --output-file-path=I<perl-module-file-path> (default: the standard output)

A platform-dependent file path to which the Perl module
is written down.

=item C<--output-line> / C<--nooutput-line> (default: C<--nooutput-line>)

Whether C<#line> directives should be included to the generated
Perl module files.

=item --verbose / --noverbose (default)

Whether a verbose message mode should be selected or not. 

=back

=cut

use Getopt::Long;
use Pod::Usage;
my %Opt = (
  create_module => [],
);
GetOptions (
  'source-module=s' => sub {
    shift;
    push @{$Opt{create_module}}, [split /\s+/, shift, 3];
  },
  'dis-file-suffix=s' => \$Opt{dis_suffix},
  'daem-file-suffix=s' => \$Opt{daem_suffix},
  'debug' => \$Opt{debug},
  'enable-assertion!' => \$Opt{outputAssertion},
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-uri=s' => \$Opt{module_uri},
  'output-file-path=s' => \$Opt{output_file_name},
  'output-line' => \$Opt{output_line},
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
  'verbose!' => \$Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};

require Error;
$Error::Debug = 1 if $Opt{debug};
$Message::Util::Error::VERBOSE = 1 if $Opt{verbose};

$Opt{daem_suffix} = '.daem' unless defined $Opt{daem_suffix};
$Opt{dis_suffix} = '.dis' unless defined $Opt{dis_suffix};

if ($Opt{module_uri}) {
  push @{$Opt{create_module}},
       [$Opt{module_uri}, $Opt{output_file_name}, $Opt{For}];
}

pod2usage (2) unless @{$Opt{create_module}};

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

use Message::Util::DIS::DNLite;
use Message::Util::DIS::Test;
use Message::DOM::GenericLS;

my $start_time;
BEGIN { $start_time = time }

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
               ({
                 ExpandedURI q<DOMLS:Generic> => '3.0',
                 '+' . ExpandedURI q<DIS:Core> => '1.0',
                 '+' . ExpandedURI q<Util:PerlCode> => '1.0',
                 '+' . ExpandedURI q<DIS:TDT> => '1.0',
                });
my $pc = $impl->get_feature (ExpandedURI q<Util:PerlCode> => '1.0');
my $di = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0');
my $tdt_parser;

  status_msg_ qq<Loading the database "$Opt{file_name}"...>;
  my $db = $di->pl_load_dis_database ($Opt{file_name}, sub ($$) {
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
  status_msg q<done>;

for (@{$Opt{create_module}}) {
  my ($mod_uri, $out_file_path, $mod_for) = @$_;
  
  my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
  unless ($mod_for) {
    $mod_for = $mod->get_property_text (ExpandedURI q<dis:DefaultFor>, undef);
    if (defined $mod_for) {
      $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
    }
  }
  unless ($mod->is_defined) {
    die qq<$0: Module <$mod_uri> for <$mod_for> is not defined>;
  }

  status_msg_ qq<Generating Perl test from <$mod_uri> for <$mod_for>...>;

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
        };');

      } elsif ($res->is_type_uri (ExpandedURI q<test:ParserTestSet>)) {
        my $block = $pack->append_new_pc_block;
        my @test;
        
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
          my $tree_t = $tres->get_property_text (ExpandedURI q<test:domTree>); 
          if (defined $tree_t) {
            unless ($tdt_parser) {
              $tdt_parser = $impl->create_gls_parser
                                     ({
                                       ExpandedURI q<DIS:TDT> => '1.0',
                                      });
            }
            $ttest->{dom_tree} = $tdt_parser->parse_string ($tree_t);
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
  
  status_msg qq<done>;
  
  my $output;
  defined $out_file_path
      ? (open $output, '>', $out_file_path or die "$0: $out_file_path: $!")
      : ($output = \*STDOUT);

  if ($Opt{output_line}) {
    $pl->owner_document->dom_config->set_parameter (ExpandedURI q<pc:line> => 1);
  }
  
  status_msg_ sprintf qq<Writing Perl test script %s...>,
                      defined $out_file_path
                        ? q<">.$out_file_path.q<">
                        : 'to stdout';
  print $output $pl->stringify;
  close $output;
  status_msg q<done>;
} # create_module

status_msg_ "Checking undefined resources...";
$db->check_undefined_resource;
status_msg q<done>;

status_msg_ "Closing the database...";
$db->free;
undef $db;
status_msg q<done>;

END {
  use integer;
  my $time = time - $start_time;
  status_msg sprintf qq<%d'%02d''>, $time / 60, $time % 60;
}
exit;

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

L<lib/Message/Util/DIS.dis> - The <QUOTE::dis> object implementation.

L<lib/Message/Util/DIS/Perl.dis> - The <QUOTE::dis> object implementation,
submodule for Perl modules.

L<lib/Message/Util/PerlCode.dis> - The Perl code generator.

L<lib/manakai/DISCore.dis> - The definition for the "dis" format. 

L<lib/manakai/DISPerl.dis> - The definition for the "dis" Perl-specific 
vocabulary. 

L<bin/dac.pl> - The "dac" database generator.

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2006/01/21 16:28:13 $
