#!/usr/bin/perl -w
use strict;
require Test::Simple;
use Message::Markup::XML::Node qw(SGML_NCR SGML_HEX_CHAR_REF
                                  SGML_ATTLIST SGML_ELEMENT
                                  SGML_GENERAL_ENTITY SGML_PARAM_ENTITY
                                  SGML_NOTATION SGML_DOCTYPE
                                  XML_ATTLIST);
use Message::Markup::XML::QName qw:DEFAULT_PFX NS_xml_URI NULL_URI:;
my $NODEMOD = 'Message::Markup::XML::Node';

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

## Simple serialization
my @s = (
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            OK $n->outer_xml, q<<foo xmlns=""></foo>>,
               'Simple default-null-ns element';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   local_name => 'foo');
            OK $n->outer_xml, q<<foo xmlns=""></foo>>,
               'Simple default-null-ns element';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://uri.example/>,
                                   local_name => 'foo');
            OK $n->outer_xml,
               [q<<foo xmlns="http://uri.example/"></foo>>,
                q<<uri.example:foo xmlns:uri.example="http://uri.example/"></uri.example:foo>>],
               'Simple default-or-non-default-non-null-ns element';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://uri.example/>,
                                   local_name => 'foo');
            $n->define_new_namespace ((DEFAULT_PFX) => q<http://uri.example/>);
            OK $n->outer_xml,
               q<<foo xmlns="http://uri.example/"></foo>>,
               'Simple default-non-null-ns element';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://uri.example/>,
                                   local_name => 'foo');
            $n->define_new_namespace (a => q<http://uri.example/>);
            OK $n->outer_xml,
               q<<a:foo xmlns:a="http://uri.example/"></a:foo>>,
               'Simple non-default-non-null-ns element';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://uri.example/>,
                                   qname => 'bar:foo');
            OK $n->outer_xml, q<<bar:foo xmlns:bar="http://uri.example/"></bar:foo>>,
               'Simple non-null-ns element';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   qname => 'bar:foo');
            OK $n->outer_xml, q<<foo xmlns=""></foo>>,
               'Simple null-ns element its QName is given as coloned name';
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => NULL_URI,
                                 local_name => 'bar');
            OK $n->outer_xml, q<<foo xmlns=""><bar></bar></foo>>;
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => q<http://nonnull.example/b>,
                                 local_name => 'bar');
            OK $n->outer_xml,
               [q<<foo xmlns=""><b:bar xmlns:b="http://nonnull.example/b"></b:bar></foo>>,
                q<<foo xmlns="" xmlns:b="http://nonnull.example/b"><b:bar></b:bar></foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => q<http://nonnull.example/b>,
                                 local_name => 'bar')
              ->define_new_namespace (c => q<http://nonnull.example/b>);
            OK $n->outer_xml,
               q<<foo xmlns=""><c:bar xmlns:c="http://nonnull.example/b"></c:bar></foo>>;
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => q<http://nonnull.example/b>,
                                 local_name => 'bar');
            $n->define_new_namespace (c => q<http://nonnull.example/b>);
            OK $n->outer_xml,
               q<<foo xmlns="" xmlns:c="http://nonnull.example/b"><c:bar></c:bar></foo>>;
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => q<http://nonnull.example/b>,
                                 local_name => 'bar');
            $n->define_new_namespace ((DEFAULT_PFX) => q<http://nonnull.example/b>);
            OK $n->outer_xml,
               [q<<foo xmlns=""><b:bar xmlns:b="http://nonnull.example/b"></b:bar></foo>>,
                q<<foo xmlns="" xmlns:b="http://nonnull.example/b"><b:bar></b:bar></foo>>],
               'Explicit attempt to associate to default prefix should be overwriten by NULL_URI';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://nonnull.example/b>,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => NULL_URI,
                                 local_name => 'bar');
            OK $n->outer_xml,
               [q<<b:foo xmlns:b="http://nonnull.example/b"><bar xmlns=""></bar></b:foo>>,
                q<<b:foo xmlns="" xmlns:b="http://nonnull.example/b"><bar></bar></b:foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://nonnull.example/b>,
                                   local_name => 'foo');
            $n->define_new_namespace ((DEFAULT_PFX) => q<http://nonnull.example/b>);
            $n->append_new_node (type => '#element',
                                 namespace_uri => NULL_URI,
                                 local_name => 'bar');
            OK $n->outer_xml,
               q<<foo xmlns="http://nonnull.example/b"><bar xmlns=""></bar></foo>>;
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://nonnull.example/b>,
                                   local_name => 'foo');
            $n->append_new_node (type => '#element',
                                 namespace_uri => q<http://nonnull.example/b>,
                                 local_name => 'bar');
            OK $n->outer_xml, q<<b:foo xmlns:b="http://nonnull.example/b"><b:bar></b:bar></b:foo>>;
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->define_new_namespace ((DEFAULT_PFX) => q<http://s.example/>);
            OK $n->outer_xml,
              [
               q<<foo xmlns=""></foo>>, # current implementation
               q<<foo xmlns="" xmlns:s.example="http://s.example/"></foo>>,
              ],
               '';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://nonnull.example/n>,
                                   local_name => 'foo');
            $n->define_new_namespace ((DEFAULT_PFX) => q<http://s.example/>);
            OK $n->outer_xml,
              [
               q<<n:foo xmlns="http://s.example/" xmlns:n="http://nonnull.example/n"></n:foo>>,
              ],
               '';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->define_new_namespace (s => q<http://s.example/>);
            OK $n->outer_xml,
              [
               q<<foo xmlns="" xmlns:s="http://s.example/"></foo>>,
              ],
               'Non-used namespace declaration should also be preserved';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://nonnull.example/n>,
                                   local_name => 'foo');
            $n->define_new_namespace (s => q<http://s.example/>);
            OK $n->outer_xml,
              [
               q<<n:foo xmlns:n="http://nonnull.example/n" xmlns:s="http://s.example/"></n:foo>>,
              ],
               'Non-used namespace declaration should also be preserved';
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => 'foo');
            $n->set_attribute (foo => 'bar');
            OK $n->outer_xml,
               [q<<foo xmlns="" foo="bar"></foo>>,
                q<<foo foo="bar" xmlns=""></foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   namespace_uri => q<http://nonnull.example/b>,
                                   local_name => 'foo');
            $n->set_attribute (foo => 'bar');
            OK $n->outer_xml,
               [q<<b:foo xmlns:b="http://nonnull.example/b" foo="bar"></b:foo>>,
                q<<b:foo foo="bar" xmlns:b="http://nonnull.example/b"></b:foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->set_attribute (foo => 'bar', namespace_uri => q<about:blank#n>);
            OK $n->outer_xml,
               [q<<foo xmlns="" xmlns:n="about:blank#n" n:foo="bar"></foo>>,
                q<<foo n:foo="bar" xmlns="" xmlns:n="about:blank#n"></foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => q<about:blank#n>);
            $n->set_attribute (foo => 'bar', namespace_uri => q<about:blank#n>);
            OK $n->outer_xml,
               [q<<n:foo xmlns:n="about:blank#n" n:foo="bar"></n:foo>>,
                q<<n:foo n:foo="bar" xmlns:n="about:blank#n"></n:foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => q<about:blank#n>);
            $n->set_attribute (foo => 'bar', namespace_uri => q<about:blank#n>);
            $n->define_new_namespace ((DEFAULT_PFX) => q<about:blank#n>);
            OK $n->outer_xml,
               [q<<foo xmlns="about:blank#n" xmlns:n="about:blank#n" n:foo="bar"></foo>>,
                q<<foo n:foo="bar" xmlns="about:blank#n" xmlns:n="about:blank#n"></foo>>,
                q<<n:foo xmlns="about:blank#n" xmlns:n="about:blank#n" n:foo="bar"></n:foo>>,
                q<<n:foo n:foo="bar" xmlns="about:blank#n" xmlns:n="about:blank#n"></n:foo>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => q<about:blank#n>);
            $n->set_attribute (foo => 'bar', namespace_uri => q<about:blank#n>);
            $n->define_new_namespace (p => q<about:blank#n>);
            OK $n->outer_xml,
               [q<<p:foo xmlns:p="about:blank#n" p:foo="bar"></p:foo>>,
                q<<p:foo p:foo="bar" xmlns:p="about:blank#n"></p:foo>>];
          },
         },         

         {                          
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->set_attribute (foo => '<bar&foo>');
            OK $n->outer_xml,
               [q<<foo foo="&lt;bar&amp;foo&gt;" xmlns=""></foo>>],
               'Attribute value should be escaped';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->set_attribute (foo => 'foo"and"bar');
            OK $n->outer_xml,
               [q<<foo foo="foo&quot;and&quot;bar" xmlns=""></foo>>,
                q<<foo foo='foo"and"bar' xmlns=""></foo>>,],
               'Attribute value should be escaped';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->set_attribute (foo => "foo'and'bar");
            OK $n->outer_xml,
               [q<<foo foo="foo'and'bar" xmlns=""></foo>>,
                q<<foo foo='foo&apos;and&apos;bar' xmlns=""></foo>>,],
               'Attribute value should be escaped';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->set_attribute (foo => q(foo"and'bar));
            OK $n->outer_xml,
               [q<<foo foo="foo&quot;and'bar" xmlns=""></foo>>,
                q<<foo foo='foo"and&apos;bar' xmlns=""></foo>>,],
               'Attribute value should be escaped';
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->append_text ('text');
            OK $n->outer_xml,
               [q<<foo xmlns="">text</foo>>],
               'text node';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->append_text ('<te&xt>');
            OK $n->outer_xml,
               [q<<foo xmlns="">&lt;te&amp;xt&gt;</foo>>],
               'text should be escaped';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element', local_name => 'foo',
                                   namespace_uri => NULL_URI);
            $n->append_text (q(ab"cd'ef));
            OK $n->outer_xml,
               [q<<foo xmlns="">ab"cd'ef</foo>>,
                q<<foo xmlns="">ab&quot;cd'ef</foo>>,
                q<<foo xmlns="">ab&quot;cd&apos;ef</foo>>],
               'text can be escaped';
          },
         },
          
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#comment', value => 'Something');
            OK $n->outer_xml,
               [q<<!--Something-->>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#comment', value => 'Some--thing');
            OK $n->outer_xml,
               [q<<!--Some- -thing-->>,
                q<<!--Some-&#x2D;thing-->>,
                q<<!--Some-&#45;thing-->>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#comment', value => 'Some---thing');
            OK $n->outer_xml,
               [q<<!--Some- - -thing-->>,
                q<<!--Some-&#x2D;-thing-->>,
                q<<!--Some-&#45;-thing-->>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#comment', value => 'Some----thing');
            OK $n->outer_xml,
               [q<<!--Some- - - -thing-->>,
                q<<!--Some-&#x2D;-&#x2D;thing-->>,
                q<<!--Some-&#45;-&#45;thing-->>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#comment', value => 'Something-');
            OK $n->outer_xml,
               [q<<!--Something- -->>,
                q<<!--Something&#x2D;-->>,
                q<<!--Something&#45;-->>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#comment', value => 'Something--');
            OK $n->outer_xml,
               [q<<!--Something- - -->>,
                q<<!--Something-&#x2D;-->>,
                q<<!--Something-&#45;-->>];
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#pi', local_name => 'target');
            OK $n->outer_xml,
               [q<<?target?>>],
               'Only target-name PI';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#pi', local_name => 'target',
                                   value => 'DO SOMETHING');
            OK $n->outer_xml,
               [q<<?target DO SOMETHING?>>],
               'PI with target data';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#pi', local_name => 'target',
                                   value => 'DO?>SOMETHING');
            OK $n->outer_xml,
               [q{<?target DO? >SOMETHING?>},
                q<<?target DO?&gt;SOMETHING?>>],
               'PI with target data including pic';
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#pi', local_name => 'target');
            $n->set_attribute (name => 'value');
            OK $n->outer_xml,
               [q<<?target name="value"?>>],
               'PI with pseudo attribute';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#pi', local_name => 'target');
            $n->set_attribute (name => 'value');
            $n->set_attribute (name2 => 'value');
            OK $n->outer_xml,
               [q<<?target name="value" name2="value"?>>],
               'PI with pseudo attributes';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#pi', local_name => 'target');
            $n->set_attribute (name => 'val?>ue');
            OK $n->outer_xml,
               [q{<?target name="val? >ue"?>},
                q<<?target name="val?&gt;ue"?>>],
               'PI with pseudo attribute including pic';
          },
         },
          
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section',
                                   value => 'character data');
            $n->set_attribute (status => 'CDATA');
            OK $n->outer_xml,
               [q<<![CDATA[character data]]>>],
               'CDATA section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section',
                                   value => q("character"'s & <data>));
            $n->set_attribute (status => 'CDATA');
            OK $n->outer_xml,
               [q<<![CDATA["character"'s & <data>]]>>],
               'CDATA section with delimiters';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section',
                                   value => q(<[[character ]]> data));
            $n->set_attribute (status => 'CDATA');
            OK $n->outer_xml,
               [q<<![CDATA[<[[character ]]]]><![CDATA[> data]]>>,
                q<<![CDATA[<[[character ]]>]]<![CDATA[> data]]>>],
               'CDATA section with mse';
          },
         },
          
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'INCLUDE');
            $n->append_new_node (type => '#comment');
            OK $n->outer_xml,
               [q<<![INCLUDE[<!---->]]>>],
               'INCLUDE section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'INCLUDE');
            $n->append_new_node (type => '#comment', value => ']]>');
            OK $n->outer_xml,
               [q{<![INCLUDE[<!--]]>-->]]>}],
               'INCLUDE section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'INCLUDE');
            $n->append_new_node (type => '#section')
              ->set_attribute (status => 'INCLUDE');
            OK $n->outer_xml,
               [q<<![INCLUDE[<![INCLUDE[]]>]]>>],
               'nested INCLUDE section';
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'IGNORE');
            $n->append_new_node (type => '#comment');
            OK $n->outer_xml,
               [q<<![IGNORE[<!---->]]>>],
               'IGNORE section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'IGNORE');
            $n->append_new_node (type => '#comment', value => '<![[]]>');
            OK $n->outer_xml,
               [q<<![IGNORE[<!--<![[]]>-->]]>>],
               'IGNORE section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'IGNORE');
            $n->append_new_node (type => '#section')
              ->set_attribute (status => 'IGNORE');
            OK $n->outer_xml,
               [q<<![IGNORE[<![IGNORE[]]>]]>>],
               'nested IGNORE section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'IGNORE');
            $n->append_new_node (type => '#section');
            OK $n->outer_xml,
               [q<<![IGNORE[<![[]]>]]>>],
               'Anomymous section in IGNORE section';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#section');
            $n->set_attribute (status => 'IGNORE');
            $n->append_new_node (type => '#xml', value => '<![freetext]]>');
            OK $n->outer_xml,
               [q<<![IGNORE[<![freetext]]>]]>>],
               'Freetext in IGNORE section';
          },
         },
          
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#reference',
                                   namespace_uri => SGML_GENERAL_ENTITY,
                                   local_name => 'ent');
            OK $n->outer_xml,
               [q<&ent;>],
               'A general entity reference';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#reference',
                                   namespace_uri => SGML_PARAM_ENTITY,
                                   local_name => 'ent');
            OK $n->outer_xml,
               [q<%ent;>],
               'A parameter entity reference';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#reference',
                                   namespace_uri => SGML_NCR,
                                   value => 0x0020);
            OK $n->outer_xml,
               [q<&#32;>],
               'A numeric character reference';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#reference',
                                   namespace_uri => SGML_NCR,
                                   value => 0x0000);
            OK $n->outer_xml,
               [q<&#0;>, q<&#00;>],
               'A numeric character reference (invalid in XML)';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#reference',
                                   namespace_uri => SGML_HEX_CHAR_REF,
                                   value => 0x0020);
            OK $n->outer_xml,
               [q<&#x20;>, q<&#x0020;>, q<&#x000020;>, q<&#x00000020;>],
               'A hex character reference';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#reference',
                                   namespace_uri => SGML_HEX_CHAR_REF,
                                   value => 0x0000);
            OK $n->outer_xml,
               [q<&#x0;>, q<&#x00;>, q<&#x0000;>, q<&#x000000;>,
                q<&#x00000000;>],
               'A hex character reference (invalid in XML)';
          },
         },
         
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_GENERAL_ENTITY,
                                   local_name => 'foo');
            OK $n->outer_xml,
               [q<<!ENTITY foo "">>],
               'ENTITY declaration';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_GENERAL_ENTITY,
                                   local_name => 'foo');
            $n->set_attribute (value => '<Entity&Value>');
            OK $n->outer_xml,
               [q<<!ENTITY foo "<Entity&#x26;Value>">>],
               'ENTITY declaration with EntityValue';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_GENERAL_ENTITY,
                                   local_name => 'foo');
            $n->append_new_node (type => '#reference',
                                 namespace_uri => SGML_PARAM_ENTITY,
                                 local_name => 'foo.val');
            OK $n->outer_xml,
               [q<<!ENTITY foo %foo.val;>>],
               'ENTITY declaration with parameter ref';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_GENERAL_ENTITY);
            $n->append_new_node (type => '#reference',
                                 namespace_uri => SGML_PARAM_ENTITY,
                                 local_name => 'foo.val');
            OK $n->outer_xml,
               [q<<!ENTITY %foo.val;>>],
               'ENTITY declaration with parameter ref';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_PARAM_ENTITY);
            $n->append_new_node (type => '#reference',
                                 namespace_uri => SGML_PARAM_ENTITY,
                                 local_name => 'foo.val');
            OK $n->outer_xml,
               [q<<!ENTITY % %foo.val;>>],
               'ENTITY declaration with parameter ref';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_GENERAL_ENTITY,
                                   local_name => 'foo');
            $n->set_attribute (SYSTEM => q<http://foo.example/xml>);
            OK $n->outer_xml,
               [q<<!ENTITY foo SYSTEM "http://foo.example/xml">>],
               'ENTITY declaration with SYSTEM';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_GENERAL_ENTITY,
                                   local_name => 'foo');
            $n->set_attribute (PUBLIC => q"+//IDN foo.example//DTD foo//EN");
            $n->set_attribute (SYSTEM => q<http://foo.example/xml>);
            OK $n->outer_xml,
               [q<<!ENTITY foo PUBLIC "+//IDN foo.example//DTD foo//EN" "http://foo.example/xml">>],
               'ENTITY declaration with PUBLIC';
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_NOTATION,
                                   local_name => 'f');
            $n->set_attribute (PUBLIC => q"+//IDN f.example//NOTATION f//EN");
            OK $n->outer_xml,
               [q<<!NOTATION f PUBLIC "+//IDN f.example//NOTATION f//EN">>],
               'NOTATION declaration with PUBLIC';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_NOTATION,
                                   local_name => 'f');
            $n->set_attribute (SYSTEM => q<http://f.example/>);
            OK $n->outer_xml,
               [q<<!NOTATION f SYSTEM "http://f.example/">>],
               'NOTATION declaration with SYSTEM';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_NOTATION,
                                   local_name => 'f');
            $n->set_attribute (PUBLIC => q"+//IDN f.example//NOTATION f//EN");
            $n->set_attribute (SYSTEM => q<http://f.example/>);
            OK $n->outer_xml,
               [q<<!NOTATION f PUBLIC "+//IDN f.example//NOTATION f//EN" "http://f.example/">>],
               'NOTATION declaration with PUBLIC and SYSTEM';
          },
         },
          
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->set_attribute (qname => 'foo');
            OK $n->outer_xml,
               [q<<!ATTLIST foo>>, q<<!ATTLIST foo >>],
               'An empty ATTLIST';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->set_attribute (qname => 'foo:bar');
            OK $n->outer_xml,
               [q<<!ATTLIST foo:bar>>, q<<!ATTLIST foo:bar >>],
               'An empty ATTLIST with prefixed name';
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->set_attribute (qname => 'foo');
            my $attr = $n->append_new_node (type => '#element',
                                            namespace_uri => XML_ATTLIST,
                                            local_name => 'AttDef');
            $attr->set_attribute (qname => 'bar');
            $attr->set_attribute (type => 'CDATA');
            $attr->set_attribute (default_type => 'REQUIRED');
            OK $n->outer_xml,
               [qq<<!ATTLIST foo\n\tbar\tCDATA\t#REQUIRED>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->set_attribute (qname => 'foo');
            my $attr = $n->append_new_node (type => '#element',
                                            namespace_uri => XML_ATTLIST,
                                            local_name => 'AttDef');
            $attr->set_attribute (qname => 'bar');
            my $att2 = $n->append_new_node (type => '#element',
                                            namespace_uri => XML_ATTLIST,
                                            local_name => 'AttDef');
            $att2->set_attribute (qname => 'ba2');
            OK $n->outer_xml,
               [qq<<!ATTLIST foo\n\tbar\tCDATA\t""\n\tba2\tCDATA\t"">>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->set_attribute (qname => 'foo');
            my $attr = $n->append_new_node (type => '#element',
                                            namespace_uri => XML_ATTLIST,
                                            local_name => 'AttDef');
            $attr->set_attribute (qname => 'bar');
            $attr->set_attribute (type => 'enum');
            $attr->append_new_node (type => '#element',
                                    namespace_uri => XML_ATTLIST,
                                    local_name => 'enum')
                 ->append_text ('enum1');
            $attr->append_new_node (type => '#element',
                                    namespace_uri => XML_ATTLIST,
                                    local_name => 'enum')
                 ->append_text ('enum2');
            $attr->set_attribute (default_value => 'enum2');
            OK $n->outer_xml,
               [qq<<!ATTLIST foo\n\tbar\t(enum1|enum2)\t"enum2">>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->set_attribute (qname => 'foo');
            my $attr = $n->append_new_node (type => '#element',
                                            namespace_uri => XML_ATTLIST,
                                            local_name => 'AttDef');
            $attr->set_attribute (qname => 'bar');
            $attr->set_attribute (type => 'NOTATION');
            $attr->append_new_node (type => '#element',
                                    namespace_uri => XML_ATTLIST,
                                    local_name => 'enum')
                 ->append_text ('enum1');
            $attr->set_attribute (default_type => 'FIXED');
            $attr->set_attribute (default_value => 'enum1');
            OK $n->outer_xml,
               [qq<<!ATTLIST foo\n\tbar\tNOTATION\t(enum1)\t#FIXED\t"enum1">>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ATTLIST);
            $n->append_new_node (type => '#reference',
                                 namespace_uri => SGML_PARAM_ENTITY,
                                 local_name => 'bar');
            OK $n->outer_xml,
              [qq<<!ATTLIST %bar;>>];
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->set_attribute (qname => 'foo');
            OK $n->outer_xml,
              [qq<<!ELEMENT foo EMPTY>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->set_attribute (qname => 'foo:bar');
            OK $n->outer_xml,
              [qq<<!ELEMENT foo:bar EMPTY>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->append_new_node (type => '#reference',
                                 namespace_uri => SGML_PARAM_ENTITY,
                                 local_name => 'bar');
            OK $n->outer_xml,
              [qq<<!ELEMENT %bar;>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (content => 'element');
            my $g = $n->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'group');
            $g->append_new_node (type => '#element',
                                 namespace_uri => SGML_ELEMENT,
                                 local_name => 'element')
              ->set_attribute (qname => 'e');
            OK $n->outer_xml,
              [qq<<!ELEMENT foo (e)>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (content => 'element');
            my $g = $n->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'group');
            my $e = $g->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'element');
            $e->set_attribute (qname => 'e');
            $e->set_attribute (occurence => '?');
            $g->set_attribute (occurence => '+');
            OK $n->outer_xml,
              [qq<<!ELEMENT foo (e?)+>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (content => 'element');
            my $g = $n->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'group');
            my $e = $g->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'element');
            $e->set_attribute (qname => 'e');
            my $f = $g->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'element');
            $f->set_attribute (qname => 'f');
            $g->set_attribute (connector => ',');
            OK $n->outer_xml,
              [qq<<!ELEMENT foo (e,f)>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_ELEMENT);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (content => 'mixed');
            my $g = $n->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'group');
            my $e = $g->append_new_node (type => '#element',
                                         namespace_uri => SGML_ELEMENT,
                                         local_name => 'element');
            $e->set_attribute (qname => 'e');
            $g->set_attribute (occurence => '+'); # Oops!
            OK $n->outer_xml,
              [qq<<!ELEMENT foo (#PCDATA|e)*>>];
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_DOCTYPE);
            $n->set_attribute (qname => 'foo');
            OK $n->outer_xml,
              [q<<!DOCTYPE foo>>, q<<!DOCTYPE foo []>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_DOCTYPE);
            $n->set_attribute (qname => 'foo:bar');
            OK $n->outer_xml,
              [q<<!DOCTYPE foo:bar>>, q<<!DOCTYPE foo:bar []>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_DOCTYPE);
            $n->set_attribute (qname => 'foo');
            $n->append_new_node (type => '#comment');
            OK $n->outer_xml,
              [qq<<!DOCTYPE foo [<!---->]>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_DOCTYPE);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (SYSTEM => q<http://dtd.example/>);
            OK $n->outer_xml,
              [qq<<!DOCTYPE foo SYSTEM "http://dtd.example/">>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_DOCTYPE);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (PUBLIC => q<+//IDN dtd.example//DTD ex//EN>);
            $n->set_attribute (SYSTEM => q<http://dtd.example/>);
            OK $n->outer_xml,
              [qq<<!DOCTYPE foo PUBLIC "+//IDN dtd.example//DTD ex//EN" "http://dtd.example/">>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#declaration',
                                   namespace_uri => SGML_DOCTYPE);
            $n->set_attribute (qname => 'foo');
            $n->set_attribute (SYSTEM => q<http://dtd.example/>);
            $n->append_new_node (type => '#comment');
            OK $n->outer_xml,
              [qq<<!DOCTYPE foo SYSTEM "http://dtd.example/" [<!---->]>>];
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#document');
            OK $n->outer_xml,
              [qq<>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#fragment');
            OK $n->outer_xml,
              [qq<>];
          },
         },
           
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#document');
            my $d = $n->append_new_node (type => '#declaration',
                                         namespace_uri => SGML_DOCTYPE);
            $d->set_attribute (qname => 'foo');
            $d->append_new_node (type => '#comment');
            OK $n->outer_xml,
              [qq<<!DOCTYPE foo [<!---->]>>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#document');
            my $d = $n->append_new_node (type => '#declaration',
                                         namespace_uri => SGML_DOCTYPE);
            $d->append_new_node (type => '#comment');
            $n->append_new_node (type => '#element',
                                 namespace_uri => NULL_URI,
                                 local_name => 'root');
            OK $n->outer_xml,
              [qq<<!DOCTYPE root [<!---->]><root xmlns=""></root>>];
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#document');
            my $p = $n->append_new_node (type => '#pi', local_name => 'xml');
            $p->set_attribute (version => '1.0');
            OK $n->outer_xml,
              [qq<<?xml version="1.0"?>>];
          },
         },
           
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#text', value => "\x00\x01\x02\x03");
            OK $n->outer_xml,
              [qq<&amp;#0;&amp;#1;&amp;#2;&amp;#3;>]; # XML 1.0
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#text', value => "\x09\x0A\x0D\x20");
            OK $n->outer_xml,
              [qq<\x09\x0A\x0D\x20>];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#text', value => "\x7F\x80\x81\x85");
            OK $n->outer_xml,
              [qq<\x7F\x80\x81\x85>]; # XML 1.0
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#attribute',
                                   local_name => 'a',
                                   value => "\x20abc\x20def\x20");
            OK $n->outer_xml,
              [qq<a="\x20abc\x20def\x20">];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#attribute',
                                   local_name => 'a',
                                   value => "\x20\x20abc\x20def\x20\x20");
            OK $n->outer_xml,
              [qq<a="\x20\x20abc\x20def\x20\x20">];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#attribute',
                                   local_name => 'a',
                                   value => "\x09abc\x09def\x09");
            OK $n->outer_xml,
              [qq<a="&#9;abc&#9;def&#9;">];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#attribute',
                                   local_name => 'a',
                                   value => "\x0Aabc\x0Adef\x0A");
            OK $n->outer_xml,
              [qq<a="&#10;abc&#10;def&#10;">];
          },
         },
         {
          main => sub {
            my $n = $NODEMOD->new (type => '#attribute',
                                   local_name => 'a',
                                   value => "\x0Dabc\x0Ddef\x0D");
            OK $n->outer_xml,
              [qq<a="&#13;abc&#13;def&#13;">];
          },
         },

         {
          main => sub {
            my $n = $NODEMOD->new (type => '#element',
                                   local_name => 'ex',
                                   namespace_uri => NS_xml_URI);
            $n->append_new_node (type => '#attribute',
                                   local_name => 'lang',
                                   namespace_uri => NS_xml_URI,
                                   value => 'ja');
            OK $n->outer_xml,
              [qq<<xml:ex xml:lang="ja"></xml:ex>>];
          },
         },
);
$tests += @s;

Test::Simple->import (tests => $tests);

for (@s) {
  $_->{main}->() if ref $_;
}
