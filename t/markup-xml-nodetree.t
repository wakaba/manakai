#!/usr/bin/perl -w
use strict;
require Test::Simple;
use Message::Markup::XML::NodeTree qw/construct_xml_tree/;
use Message::Markup::XML::Node qw(SGML_GENERAL_ENTITY SGML_PARAM_ENTITY
                                  SGML_DOCTYPE
                                  SGML_NCR SGML_HEX_CHAR_REF);
use Message::Markup::XML::QName qw/:prefix :special-uri/;
my $NODEMOD = 'Message::Markup::XML';
sub OK ($$;$) {
  my ($result, $expect, $testname) = @_;
  my @expect = ref $expect ?@ $expect : ($expect);
  for (@expect) {
    if ($_ eq $result) {
      ok (1);
      return;
    }
  }
  my $e = sub {
    my $s = shift;
    $s =~ s/\t/\\t/g;
    $s;
  };
  ok (0, sprintf '%s: "%s" ("%s" expected)', ($testname || 'Node'),
                 $e->($result), join '" or "', map {$e->($_)} @expect);
}

my $tests = 0;

my @s = (
         {
          main => sub {
            my $n = $NODEMOD->new
              (type => '#element', local_name => 'foo');
            $n->append_text ('text');
            my $ref = $n->append_new_node
              (type => '#reference', namespace_uri => SGML_GENERAL_ENTITY,
               local_name => 'ent');
            $ref->append_text ('other_text');
            OK $n->outer_xml,
               q<<foo xmlns="">text&ent;</foo>>,
               'First, serialization of reference-containing-tree work as expected?';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new
              (type => '#element', local_name => 'foo');
            $n->append_text ('text');
            my $ref = $n->append_new_node
              (type => '#reference', namespace_uri => SGML_GENERAL_ENTITY,
               local_name => 'ent');
            $ref->append_text ('other_text');
            $ref->flag (smxp__ref_expanded => 1);
            $n->remove_references;
            OK $n->outer_xml,
               q<<foo xmlns="">textother_text</foo>>,
               'Simple removing of #reference';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new
              (type => '#element', local_name => 'foo');
            $n->append_text ('text');
            my $ref = $n->append_new_node
              (type => '#reference', namespace_uri => SGML_GENERAL_ENTITY,
               local_name => 'ent');
            $ref->append_text ('other_text');
            $ref->flag (smxp__ref_expanded => 0);
            $n->remove_references;
            OK $n->outer_xml,
               q<<foo xmlns="">text&ent;</foo>>,
               q(Don't remove unexpanded #reference);
          },
         },
         {
          main => sub {
            my $e = new $NODEMOD (type => '#fragment');
            my $ent = $e->append_new_node (type => '#reference', 
                                           namespace_uri => SGML_PARAM_ENTITY,
                                           local_name => 'ent');
            $ent->append_new_node (type => '#comment');
            $ent->flag (smxp__ref_expanded => 1);
            $e->remove_references;
            OK $e->outer_xml,
               q<<!---->>,
               'Derefering parameter entity reference in declaration subset';
          },
         },
         {
          main => sub {
            my $e = new $NODEMOD (type => '#declaration',
                                  namespace_uri => SGML_PARAM_ENTITY);
            $e->flag (smxp__defined_with_param_ref => 1);
            my $ent = $e->append_new_node (type => '#reference',
                                           namespace_uri => SGML_PARAM_ENTITY,
                                           local_name => 'ent');
            $ent->append_new_node (type => '#xml',
                                   value => '% name SYSTEM "somewhere"');
            $ent->flag (smxp__ref_expanded => 1);
            $e->remove_references;
            OK $e->outer_xml,
               q<<!ENTITY % name SYSTEM "somewhere">>,
               'Derefering parameter entity reference in ps';
          },
         },
         {
          main => sub {
            my $e = new $NODEMOD (type => '#declaration',
                                  namespace_uri => SGML_PARAM_ENTITY);
            $e->flag (smxp__defined_with_param_ref => 1);
            my $ent = $e->append_new_node (type => '#reference',
                                           namespace_uri => SGML_PARAM_ENTITY,
                                           local_name => 'ent');
            $ent->append_new_node (type => '#xml',
                                   value => '% name SYSTEM "somewhere"');
            $ent->flag (smxp__ref_expanded => 1);
            $ent->flag (smxp__non_processed_declaration => 1);
            $e->remove_references;
            OK $e->outer_xml,
               [q<<!ENTITY %ent;>>,
                q<<!ENTITY % name SYSTEM "somewhere">>],
               'Derefering parameter entity reference in ps : ENTITY declaration is not processed';
          },
         },  
         {
          main => sub {
            my $e = new $NODEMOD (type => '#fragment');
            $e->append_text ('text1');
            $e->append_new_node (type => '#reference', 
                                 namespace_uri => SGML_NCR,
                                 value => 0x00004E00);
            $e->append_text ('text2');
            $e->remove_references;
            OK $e->outer_xml,
               qq<text1\x{4E00}text2>,
               'Derefering NCR';
          },
         },
         {
          main => sub {
            my $e = new $NODEMOD (type => '#fragment');
            $e->append_text ('text1');
            $e->append_new_node (type => '#reference',
                                 namespace_uri => SGML_HEX_CHAR_REF,
                                 value => 0x00004E00);
            $e->append_text ('text2');
            $e->remove_references;
            OK $e->outer_xml,
               qq<text1\x{4E00}text2>,
               'Derefering HCR';
          },
         },
);
$tests += @s + 1;

Test::Simple->import (tests => $tests);

for (@s) {
  $_->{main}->() if ref $_;
}

sub NS_XHTML1 { q<http://www.w3.org/1999/xhtml> }
sub NS_XHTML2 { q<http://www.w3.org/2002/06/xhtml2> }
my $tree = construct_xml_tree
  type => '#element',
  local_name => 'html',
  namespace_uri => NS_XHTML1,
  -child =>
  [
   {
    type => '#element',
    local_name => 'head',
    namespace_uri => NS_XHTML1,
    -child =>
    [
     {
      type => '#element',
      local_name => 'title',
      namespace_uri => NS_XHTML1,
      -child =>
      [
       {
        type => '#text',
        value => 'An Example Document',
       },
      ],
     },
    ],
   },
   {
    type => '#element',
    local_name => 'body',
    namespace_uri => NS_XHTML1,
    -attr =>
    {
     class => 'example',
    },
    -child => 
    [
     {
      type => '#comment',
      value => '===== main =====',
     },
     {
      type => '#element',
      local_name => 'p',
      namespace_uri => q<http://www.w3.org/2002/06/xhtml2>,
      -attr => 
      {
        class => 'introduction',
      },
      -child =>
      [
       {
        type => '#text',
        value => 'foo',
       },
      ],
      -ns =>
      {
       h2 => q<http://www.w3.org/2002/06/xhtml2>,
      },
     },
    ],
   },
  ],
  -ns => 
  {
   (DEFAULT_PFX) => q<http://www.w3.org/1999/xhtml>,
  };

OK $tree->stringify, q<<html xmlns="http://www.w3.org/1999/xhtml"><head><title>An Example Document</title></head><body class="example"><!--===== main =====--><h2:p class="introduction" xmlns:h2="http://www.w3.org/2002/06/xhtml2">foo</h2:p></body></html>>;
