use strict;
use Message::Util::QName::Filter {
  c => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  pc => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/PerlCode#>,
  test => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Test#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
  xp => q<http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#>,
};

use Message::Util::PerlCode;
use Message::Util::DIS::Test;
use Message::DOM::GenericLS;

our $impl; # Assigned in the main script
our $db;
my $tdt_parser;

sub daf_perl_t ($$$) {
  my ($mod_uri, $out_file_path, $mod_for) = @_;

  unless (defined $mod_for) {
    $mod_for = $db->get_module ($mod_uri)
                  ->get_property_text (ExpandedURI q<dis:DefaultFor>,
                                       ExpandedURI q<ManakaiDOM:all>);
  }
  my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);

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
} # daf_perl_t

sub daf_generate_perl_test_file ($) {
  my $mod = shift;
  local $Message::Util::DIS::Perl::Implementation = $impl;
  my $pl = $impl->create_pc_file;
  my $factory = $pl->owner_document;
  my $pack = $pl->get_last_package ("Manakai::Test", make_new_package => 1);
  $pack->add_use_perl_module_name ("Message::Util::DIS::Test");
  $pack->add_use_perl_module_name ("Message::Util::Error");
  $pack->add_require_perl_module_name ($mod->pl_fully_qualified_name);

  $pl->source_file ($mod->get_property_text (ExpandedURI q<DIS:sourceFile>, ""));
  $pl->source_module ($mod->name_uri);
  $pl->source_for ($mod->for_uri);
  $pl->license_uri ($mod->get_property_resource (ExpandedURI q<dis:License>)
                        ->uri);

  $pack->append_code ('
    use Getopt::Long;
    my %Skip;
    GetOptions (
      "Skip=s" => sub {
        shift;
        for (split /\s+/, shift) {
          if (/^(\d+)-(\d+)$/) {
            $Skip{$_} = 1 for $1..$2;
          } else {
            $Skip{$_} = 1;
          }
        }
      },
    );
  ');

  $pack->append_child ($factory->create_pc_statement)
       ->append_code
           ('my $impl = $Message::DOM::ImplementationRegistry
                            ->get_implementation ({
                "http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#Test"
                    => "1.0",
            })');

  my $num_statement = $pack->append_child ($factory->create_pc_statement);
  $num_statement->append_code ('my $test = $impl->create_test_manager');

  my $total_tests = 0;
  my %processed;
  for my $res (@{$mod->get_resource_list}) {
    next if $res->owner_module ne $mod or $processed{$res->uri};
    $processed{$res->uri} = 1;

    if ($res->is_type_uri (ExpandedURI q<test:Test>)) {
      if ($res->is_type_uri (ExpandedURI q<test:StandaloneTest>)) {
        my $test_num = ++$total_tests;
        my $test_uri = $res->name_uri || $res->uri;

        $pack->append_code ('$test->start_new_test (');
        $pack->append_new_pc_literal ($test_uri);
        $pack->append_code (');');

        $pack->append_code ('if (not $Skip{'.$test_num.'} and not $Skip{');
        $pack->append_new_pc_literal ($test_uri);
        $pack->append_code ('}) {');
        
        $pack->append_code ('try {');
        
        my $test_pc = $res->pl_code_fragment ($factory);
        if (not defined $test_pc) {
          die "Perl test code not defined for <".$res->uri.">";
        }
        
        $pack->append_child ($test_pc);
        
        $pack->append_code ('$test->ok;');
        
        $pack->append_code ('} catch Message::Util::IF::DTException with {
          ##
        } otherwise {
          my $err = shift;
          warn $err;
          $test->not_ok;
        };');

        $pack->append_code ('} else { warn "'.$test_num.' skipped\n" }');

      } elsif ($res->is_type_uri (ExpandedURI q<test:ParserTestSet>)) {
        my $block = $pack->append_new_pc_block;
        my @test;
        
        $tdt_parser ||= $impl->create_gls_parser
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
                 ExpandedURI q<test:value>, ExpandedURI q<xp:encoding>) {
              my $v = $eres->get_property_text ($_);
              $tent->{$_} = $v if defined $v;
            }
            $ttest->{root_uri} = $eres->uri
              if $eres->is_type_uri (ExpandedURI q<test:RootEntity>) or
                 not defined $ttest->{root_uri};
          }

          ## DOM configuration parameters
          for my $v (@{$tres->get_property_value_list
                              (ExpandedURI q<c:anyDOMConfigurationParameter>)}) {
            my $cpuri = $v->name;
            my $cp = $db->get_resource ($cpuri, for_arg => $tres->for_uri);
            $ttest->{dom_config}->{$cp->get_dom_configuration_parameter_name}
              = $v->get_perl_code ($block->owner_document, $tres);
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
        
        my $plc = $res->pl_code_fragment ($factory);
        unless ($plc) {
          die "Resource <".$res->uri."> does not have Perl test code";
        }

        $block->append_child ($plc);
        
      } # test resource type
    } # test:Test
  }
  
  $num_statement->append_code (' (' . $total_tests . ')');

  return $pl;
} # daf_generate_perl_test_file

1;

__END__

=head1 NAME

daf-perl-t.pl - A daf module to generate Perl test scripts

=head1 DESCRIPTION

This script, C<daf-perl-t.pl>, is dynamically loaded by
C<daf.pl> to create Perl test scripts.

=head1 SEE ALSO

L<bin/daf.pl> - daf main script

=head1 LICENSE

Copyright 2004-2006 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
