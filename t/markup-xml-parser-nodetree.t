#!/usr/bin/perl -w
use strict;

use Message::Markup::XML::Node qw/SGML_DOCTYPE/;
use Message::Markup::XML::Parser::NodeTree;
use Message::Markup::XML::QName qw/:prefix :special-uri/;
use Message::Util::ResourceResolver::XML;
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG (),
   tree => Message::Markup::XML::Parser::NodeTree::URI_CONFIG (),
   test => q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/test/>,
   rr => Message::Util::ResourceResolver::Base::URI_CONFIG (),
   rrx => Message::Util::ResourceResolver::XML::URI_CONFIG (),
   Content => q<urn:x-suika-fam-cx:msgpm:header:mail:rfc822:content>,
   infoset => q<http://www.w3.org/2001/04/infoset#>,
  };
use Test;
use URI;

push @mytest::resresolver::ISA, 'Message::Util::ResourceResolver::XML';

sub mytest::resresolver::get_resource ($;%) {
  my ($self, %opt) = @_;
  my $res = $self->{ExpandedURI q<test:resource>};
  my $uri = URI->new ($opt{ExpandedURI q<infoset:systemIdentifier>});
  $uri = $uri->abs ($opt{ExpandedURI q<infoset:declarationBaseURI>})
    if $opt{ExpandedURI q<infoset:declarationBaseURI>};
  my $r;
  if ($res->{$uri}) {
    $r = {%{$res->{$uri}},
          ExpandedURI q<rr:success> => 1};
  } else {
    $r = {ExpandedURI q<rr:success> => 0};
    warn qq<Resource <$uri> not defined>
      unless exists $res->{$uri};
  }
  $r->{ExpandedURI q<original-uri>} = $uri;
  $r->{ExpandedURI q<uri>} ||= $uri;
  $r->{ExpandedURI q<base-uri>} ||= $uri;
  $r;
}

package main;

my @a = (
         {
          method => q(parse_element),
          t => q(<a></a>),
          result => [q(<a></a>), q(<a xmlns=""></a>)],
         },
         {
          method => q(parse_element),
          t => q(<a/>),
          result => [q(<a/>), q(<a xmlns=""/>),
                     q(<a />), q(<a xmlns="" />)],
         },
         {
          method => q(parse_element),
          t => q(<a />),
          result => [q(<a/>), q(<a xmlns=""/>),
                     q(<a />), q(<a xmlns="" />)],
         },
         {
          method => q(parse_element),
          t => q(<a></b>),
          error => q(0:5:WFC_ELEMENT_TYPE_MATCH),
          result => [q(<a></a>), q(<a xmlns=""></a>)],
         },
         {
          method => q(parse_element),
          t => q(</b>),
          error => q(0:2:SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED),
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc),
          error => q(0:10:SYNTAX_END_TAG_REQUIRED),
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a></a>aa</r>),
          result => [q(bb<a></a>aa), q(bb<a xmlns=""></a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a />aa</r>),
          result => [q(bb<a />aa), q(bb<a xmlns="" />aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc</a>aa</r>),
          result => [q(bb<a>cc</a>aa), q(bb<a xmlns="">cc</a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc<b>dd</b>ee</a>aa</r>),
          result => [q(bb<a>cc<b>dd</b>ee</a>aa),
                     q(bb<a xmlns="">cc<b>dd</b>ee</a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc<b>dd</b>e<c />e</a>aa</r>),
          result => [q(bb<a>cc<b>dd</b>e<c />e</a>aa),
                     q(bb<a xmlns="">cc<b>dd</b>e<c />e</a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc<b>dd</b>e<f>g</f>e</a>aa</r>),
          result => [q(bb<a>cc<b>dd</b>e<f>g</f>e</a>aa),
                     q(bb<a xmlns="">cc<b>dd</b>e<f>g</f>e</a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc<b>dd</b>e<f>ge</a>aa</r>),
          error => q(0:27:WFC_ELEMENT_TYPE_MATCH),
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a>cc<b>dd</b>e<f>ge),
          error => q(0:25:SYNTAX_END_TAG_REQUIRED),
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a b="c">cc</a>aa</r>),
          result => [q(bb<a b="c">cc</a>aa),
                     q(bb<a b="c" xmlns="">cc</a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a b="c">cc<d gg="gg">ff</d>ee</a>aa</r>),
          result => [q(bb<a b="c">cc<d gg="gg">ff</d>ee</a>aa),
                     q(bb<a b="c" xmlns="">cc<d gg="gg">ff</d>ee</a>aa)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<a b="c">cc<d gg="gg" />ee</a>aa</r>),
          result => [q(bb<a b="c">cc<d gg="gg" />ee</a>aa),
                     q(bb<a b="c" xmlns="">cc<d gg="gg" />ee</a>aa)],
         },

         {
          method => q(parse_attribute_specification),
          t => q(<r href="http://uri.example/"></r>),
          result => [q(href="http://uri.example/")],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href='http://uri.example/'></r>),
          result => [q(href="http://uri.example/"),
                     q(href='http://uri.example/')],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href  =    "http://uri.example/"></r>),
          result => [q(href="http://uri.example/"),
                     q(href  =    "http://uri.example/")],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href="http://test&#x2F;"></r>),
          result => [q(href="http://test&#x2F;")],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href="&#x2F;"></r>),
          result => [q(href="&#x2F;")],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href="http://test&#47;"></r>),
          result => [q(href="http://test&#47;")],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href="%uri;"></r>),
          result => [q(href="%uri;")],
         },

         {
          method => q(parse_in_con_mode),
          t => q(<r>bbaa;c&#x70;d&#120;c</r>),
          result => [q(bbaa;c&#x70;d&#120;c)],
         },

         {
          method => q(parse_comment_declaration),
          t => q(<!-- aa -->),
          result => [q(<!-- aa -->)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r><!-- aa --></r>),
          result => [q(<!-- aa -->)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<!-- aa -->cc</r>),
          result => [q(bb<!-- aa -->cc)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb<!-- aa -->cc<!--d--></r>),
          result => [q(bb<!-- aa -->cc<!--d-->)],
         },

 {
  t => q{<?xml-something system-data ?>},
  method => 'parse_processing_instruction',
  result => [q(<?xml-something system-data ?>)],
 },
 {
  t => q{<?xml version="1.0"?>},
  method => 'parse_xml_declaration',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  result => [q(<?xml version="1.0"?>)],
 }, 
         {
          t => q{<?xml version="1.1"?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          result => [q(<?xml version="1.1"?>)],
         },
         {
          t => q{<?xml  encoding = 'iso-2022-jp'?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml encoding="iso-2022-jp"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'iso-2022-jp'?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="iso-2022-jp"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'iso-2022-jp'?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="iso-2022-jp"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'iso-2022-jp'?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="iso-2022-jp"?>)],
         },
         
         {
          t => q{<?xml version="1.0" encoding = 'UTF-8' standalone="yes" ?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'UTF-8' standalone="no" ?>},
          method => 'parse_xml_declaration',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="UTF-8" standalone="no"?>)],
         },

         {
          t => q{<!DOCTYPE root><root />},
          method => q(parse_document_entity),
          result => [q{<!DOCTYPE root><root xmlns="" />},
                     q{<!DOCTYPE root []><root xmlns="" />}],
         },
         {
          t => q{<!DOCTYPE root[]><root />},
          method => q(parse_document_entity),
          result => [q{<!DOCTYPE root><root xmlns="" />},
                     q{<!DOCTYPE root []><root xmlns="" />}],
         },

 {
  t => q{<!DOCTYPE root SYSTEM "sys">},
  method => q(parse_doctype_declaration),
  error => q(0:27:EXTERNAL_SUBSET_NOT_READ),
  flag => {ExpandedURI q<base-uri> => URI->new (q<http://foo.example/>)},
  resource => {q<http://foo.example/sys>=>undef},
 },
 {
  t => q{<!DOCTYPE root PUBLIC "pbu" "sys">},
  method => q(parse_doctype_declaration),
  error => q(0:33:EXTERNAL_SUBSET_NOT_READ),
  flag => {ExpandedURI q<base-uri> => URI->new (q<http://foo.example/>)},
  resource => {q<http://foo.example/sys>=>undef},
 },
 {
  t => q{<!DOCTYPE root SYSTEM "sys">},
  method => q(parse_doctype_declaration),
  result => [q{<!DOCTYPE root SYSTEM "sys">}],
  flag => {ExpandedURI q<base-uri> => URI->new (q<http://foo.example/>)},
  resource => {q<http://foo.example/sys>
                 =>{ExpandedURI q<rrx:literal-entity-value>=>q<>}},
 },
 {
  t => q{<!DOCTYPE root PUBLIC "pub" "sys">},
  method => q(parse_doctype_declaration),
  result => [q{<!DOCTYPE root PUBLIC "pub" "sys">}],
  flag => {ExpandedURI q<base-uri> => URI->new (q<http://foo.example/>)},
  resource => {q<http://foo.example/sys>
                 =>{ExpandedURI q<rrx:literal-entity-value>=>q<>}},
 },
 {
  t => q{<!DOCTYPE root PUBLIC "pub  " "sys"[<!---->]>},
  method => q(parse_doctype_declaration),
  result => [q{<!DOCTYPE root PUBLIC "pub" "sys" [<!---->]>}],
  flag => {ExpandedURI q<base-uri> => URI->new (q<http://foo.example/>)},
  resource => {q<http://foo.example/sys>
                 =>{ExpandedURI q<rrx:literal-entity-value>=>q<>}},
 },

 {
  t => q{<!ENTITY foo "bar">},
  method => q(parse_doctype_subset),
  result => [q{<!ENTITY foo "bar">},
             q{<!ENTITY  foo "bar">}],
 },
 {
  t => q{<!ENTITY % foo "bar">},
  method => q(parse_doctype_subset),
  result => [q{<!ENTITY % foo "bar">},
             q{<!ENTITY  % foo "bar">}],
 },
 {
  t => q{<!ENTITY foo PUBLIC "bar" "baz">},
  method => q(parse_doctype_subset),
  result => [q{<!ENTITY foo PUBLIC "bar" "baz">},
             q{<!ENTITY  foo PUBLIC "bar" "baz">}],
 },
 {
  t => q{<!ENTITY % foo SYSTEM "bar">},
  method => q(parse_doctype_subset),
  result => [q{<!ENTITY % foo SYSTEM "bar">},
             q{<!ENTITY  % foo SYSTEM "bar">}],
 },
 {
  t => q{<!ENTITY foo PUBLIC "bar" "baz" NDATA notation>},
  method => q(parse_doctype_subset),
  result => [q{<!ENTITY foo PUBLIC "bar" "baz" NDATA notation>},
             q{<!ENTITY  foo PUBLIC "bar" "baz" NDATA notation>}],
 },
 
 {
  t => q{<!ENTITY bar %foo;>},
  method => q(parse_doctype_external_subset),
  error => q<0:14:VC_ENTITY_DECLARED__PARAM>,
 },
 {
  t => q{<!ENTITY % foo " 'bar' ">
         <!ENTITY % bar %foo;>},
  method => q(parse_doctype_external_subset),
  result =>
      [q{<!ENTITY % foo " 'bar' ">
         <!ENTITY % bar %foo;>},
       q{<!ENTITY  % foo " 'bar' ">
         <!ENTITY  % bar %foo;>},
       q{<!ENTITY % foo " 'bar' ">
         <!ENTITY % bar "bar">},
       q{<!ENTITY  % foo " 'bar' ">
         <!ENTITY  % bar   'bar'  >}],
 },
 {
  t => q{<!ENTITY % foo "-- foo --">
         <!ENTITY % bar "-- %foo; --">},
  method => q(parse_doctype_subset),
  result =>
      [q{<!ENTITY % foo "-- foo --">
         <!ENTITY % bar "-- %foo; --">},
       q{<!ENTITY  % foo "-- foo --">
         <!ENTITY  % bar "-- %foo; --">},
       q{<!ENTITY % foo "-- foo --">
         <!ENTITY % bar "-- -- foo -- --">},
       q{<!ENTITY  % foo "-- foo --">
         <!ENTITY  % bar "-- -- foo -- --">}],
 },

 {
  t => q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar %foo; >},
  method => q(parse_doctype_external_subset),
  error => q<1:25:EXTERNAL_PARAM_ENTITY_NOT_READ>,
  resource => {q<about:ent1>=>undef},
 },
 {
  t => q{<!NOTATION n1 SYSTEM "n1">
         <!ENTITY % foo SYSTEM "about:ent1" NDATA n1>
         <!ENTITY % bar %foo; >},
  method => q(parse_doctype_external_subset),
  error => q<2:25:WFC_PARSED_ENTITY>,
 },
 {
  t => q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar %foo; >},
  method => q(parse_doctype_external_subset),
  result
   => [q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar %foo; >},
       q{<!ENTITY  % foo SYSTEM "about:ent1">
         <!ENTITY  % bar %foo; >},
       q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar " text ">}],
  resource => {q<about:ent1>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<?xml version="1.0" encoding="us-ascii"?>
                            " text "},
                    },
              },
 },
 {
  t => q{<!ENTITY % foo SYSTEM "http://www.example.com/test/1">
         <!ENTITY % foo2 "SYSTEM 'http://www.example.com/test/2'">
         <!ENTITY % bar %foo; >},
  method => q(parse_doctype_external_subset),
  result
   => [q{<!ENTITY % foo SYSTEM "http://www.example.com/test/1">
         <!ENTITY % foo2 "SYSTEM 'http://www.example.com/test/2'">
         <!ENTITY % bar %foo; >},
       q{<!ENTITY  % foo SYSTEM "http://www.example.com/test/1">
         <!ENTITY  % foo2 "SYSTEM 'http://www.example.com/test/2'">
         <!ENTITY  % bar %foo; >},
       q{<!ENTITY % foo SYSTEM "http://www.example.com/test/1">
         <!ENTITY % foo2 "SYSTEM 'http://www.example.com/test/2'">
         <!ENTITY % bar SYSTEM 'http://www.example.com/test/2'>},
       q{<!ENTITY % foo SYSTEM "http://www.example.com/test/1">
         <!ENTITY % foo2 "SYSTEM 'http://www.example.com/test/2'">
         <!ENTITY % bar SYSTEM "http://www.example.com/test/2">}],
  resource => {q<http://www.example.com/test/1>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<?xml version="1.0" encoding="us-ascii"?>
                            %foo2;},
                    },
               q<http://www.example.com/test/2>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<?xml version="1.0" encoding="us-ascii"?>
                            " text "},
                    },
              },
 },
 {
  t => q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar "%foo; ">},
  method => q(parse_doctype_external_subset),
  result
   => [q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar "%foo; ">},
       q{<!ENTITY  % foo SYSTEM "about:ent1">
         <!ENTITY  % bar "%foo; ">},
       q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar '" text " '>},
       q{<!ENTITY % foo SYSTEM "about:ent1">
         <!ENTITY % bar "
                            &#x22; text &#x22; ">}],
  resource => {q<about:ent1>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<?xml version="1.0" encoding="us-ascii"?>
                            " text "},
                    },
              },
 },

 {
  t => q{<!ENTITY % foo "<!ENTITY &#x25; baz 'baz.'>">
         %foo;
         <!ENTITY % bar "%baz; ">},
  method => q(parse_doctype_external_subset),
  result
   => [q{<!ENTITY % foo "<!ENTITY &#x25; baz 'baz.'>">
         %foo;
         <!ENTITY % bar "%baz; ">},
       q{<!ENTITY  % foo "<!ENTITY &#x25; baz 'baz.'>">
         %foo;
         <!ENTITY  % bar "%baz; ">},
       q{<!ENTITY % foo "<!ENTITY &#x25; baz 'baz.'>">
         <!ENTITY % baz 'baz.'>
         <!ENTITY % bar "baz. ">},
       q{<!ENTITY % foo "<!ENTITY &#x25; baz 'baz.'>">
         %foo;
         <!ENTITY % bar "baz. ">}],
  resource => {q<about:ent1>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<?xml version="1.0" encoding="us-ascii"?>
                            " text "},
                    },
              },
 },
 {
  t => q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         %foo;
         <!ENTITY % bar "%hoge; ">},
  method => q(parse_doctype_external_subset),
  flag => {
    ExpandedURI q<base-uri> => URI->new (q<http://foo.example/bar.dtd>),
  },
  result
   => [q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         %foo;
         <!ENTITY % bar "%hoge; ">},
       q{<!ENTITY  % foo SYSTEM "foo/foo.ent">
         %foo;
         <!ENTITY  % bar "%hoge; ">},
       q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         %foo;
         <!ENTITY % bar "-- bar -- ">}],
  resource => {q<http://foo.example/foo/foo.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % baz SYSTEM "baz.ent">%baz;},
                    },
               q<http://foo.example/foo/baz.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % hoge "-- bar --">},
                    },
              },
 },
 {
  t => q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         %foo;%baz;
         <!ENTITY % bar "%hoge; ">},
  method => q(parse_doctype_external_subset),
  flag => {
    ExpandedURI q<base-uri> => URI->new (q<http://foo.example/bar.dtd>),
  },
  result
   => [q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         %foo;%baz;
         <!ENTITY % bar "%hoge; ">},
       q{<!ENTITY  % foo SYSTEM "foo/foo.ent">
         %foo;%baz;
         <!ENTITY  % bar "%hoge; ">},
       q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         %foo;%baz;
         <!ENTITY % bar "-- bar -- ">}],
  resource => {q<http://foo.example/foo/foo.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % baz SYSTEM "baz.ent">},
                    },
               q<http://foo.example/foo/baz.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % hoge "-- bar --">},
                    },
              },
 },
 {
  t => q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         <!ENTITY % abaz "%foo;">%abaz;%baz;
         <!ENTITY % bar "%hoge; ">},
  method => q(parse_doctype_external_subset),
  flag => {
    ExpandedURI q<base-uri> => URI->new (q<http://foo.example/bar.dtd>),
  },
  result
   => [q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         <!ENTITY % abaz "%baz;">%abaz;%baz;
         <!ENTITY % bar "%hoge; ">},
       q{<!ENTITY  % foo SYSTEM "foo/foo.ent">
         <!ENTITY % abaz "%baz;">%abaz;%baz;
         <!ENTITY  % bar "%hoge; ">},
       q{<!ENTITY % foo SYSTEM "foo/foo.ent">
         <!ENTITY % abaz "<!ENTITY &#x25; baz SYSTEM &#x22;baz.ent&#x22;>">%abaz;%baz;
         <!ENTITY % bar "-- bar -- ">}],
  resource => {q<http://foo.example/foo/foo.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % baz SYSTEM "baz.ent">},
                    },
               q<http://foo.example/baz.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % hoge "-- bar --">},
                    },
              },
 },
 
 {
  t => q{<!DOCTYPE e [<!ENTITY a ""><!ENTITY % a "">]><e></e>},
  method => q(parse_document_entity),
  result
   => [q{<!DOCTYPE e [<!ENTITY a ""><!ENTITY % a "">]><e xmlns=""></e>}],
 },
 {
  t => q{<!DOCTYPE e [<!ENTITY a ""><!ENTITY a "">]><e></e>},
  method => q(parse_document_entity),
  error => q<0:36:GENERAL_ENTITY_NAME_USED>,
 },
 {
  t => q{<!DOCTYPE e [<!ENTITY % a ""><!ENTITY % a "">]><e></e>},
  method => q(parse_document_entity),
  error => q<0:40:PARAM_ENTITY_NAME_USED>,
 },

 {
  t => q{<!DOCTYPE e SYSTEM "foo/doctype"><e>&hoge;</e>},
  method => q(parse_document_entity),
  flag => {
    ExpandedURI q<uri> => URI->new (q<http://foo.example/bar.dtd>),
  },
  result
   => [q{<!DOCTYPE e SYSTEM "foo/doctype"><e xmlns="">&hoge;</e>},
       q{<!DOCTYPE e [<!ENTITY % baz SYSTEM "baz.ent">
                      <!ENTITY hoge "-- bar --">]><e xmlns="">-- bar --</e>}],
  resource => {q<http://foo.example/foo/doctype>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % baz SYSTEM "baz.ent">
                      %baz;},
                    },
               q<http://foo.example/foo/baz.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY hoge "-- bar --">},
                    },
              },
 },
 {
  t => q{<!DOCTYPE e SYSTEM "foo/doctype"><e>&hoge;</e>},
  method => q(parse_document_entity),
  flag => {
    ExpandedURI q<uri> => URI->new (q<http://foo.example/bar.xml>),
  },
  error => q<0:8:SYNTAX_HASH_OR_NAME_REQUIRED>,
  resource => {q<http://foo.example/foo/doctype>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY % baz SYSTEM "baz.ent">
                      %baz;},
                    },
               q<http://foo.example/foo/baz.ent>
                 => {ExpandedURI q<rrx:literal-entity-value>
                       => q{<!ENTITY hoge "-- bar &#x26; --">},
                    },
              },
 },
 {
  method => q(parse_document_entity),
  t => q(<!DOCTYPE r SYSTEM "a">
         <r href="http://&host;/"></r>),
  result => [q(<!DOCTYPE r SYSTEM "a">
         <r href="http://&host;/" xmlns=""></r>)],
  flag => {
    ExpandedURI q<uri> => URI->new (q<http://foo.example/bar.xml>),
  },
  resource => {
    q<http://foo.example/a>
      => {ExpandedURI q<rrx:literal-entity-value>
            => q{<!ENTITY host "foo.bar.example:8080">},
         },
  },
 },
 {
  method => q(parse_document_entity),
  t => q(<!DOCTYPE r SYSTEM "a">
         <r href="http://&host;/"></r>),
  error => q<0:16:SYNTAX_HASH_OR_NAME_REQUIRED>,
  flag => {
    ExpandedURI q<uri> => URI->new (q<http://foo.example/bar.xml>),
  },
  resource => {
    q<http://foo.example/a>
      => {ExpandedURI q<rrx:literal-entity-value>
            => q{<!ENTITY host "foo.bar.example&#x26; :8080">},
         },
  },
 },

 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!NOTATION a SYSTEM "sys">]><r></r>),
  result => [
    q<<!DOCTYPE r [<!NOTATION a SYSTEM "sys">]><r xmlns=""></r>>,
    q<<!DOCTYPE r [<!NOTATION  a SYSTEM "sys">]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!NOTATION ab PUBLIC "sys">]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!NOTATION ab PUBLIC "sys">]><r xmlns=""></r>>,
    q<<!DOCTYPE r [<!-- --> <!NOTATION  ab PUBLIC "sys">]><r xmlns=""></r>>,
  ],
 },

 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!ELEMENT el EMPTY>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el EMPTY>]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!ELEMENT el ANY>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el ANY>]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA)>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA)>]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA)*>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA)*>]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA | a)*>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA | a)*>]><r xmlns=""></r>>,
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el (#PCDATA|a)*>]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!-- --> <!ELEMENT el (b? | (a*, (c)))+>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el (b? | (a*, (c)))+>]><r xmlns=""></r>>,
    q<<!DOCTYPE r [<!-- --> <!ELEMENT el (b?|(a*,(c)))+>]><r xmlns=""></r>>,
  ],
 },

 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!ATTLIST ab tr CDATA #IMPLIED>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!ATTLIST ab tr CDATA #IMPLIED>]><r xmlns=""></r>>,
    q<<!DOCTYPE r [<!ATTLIST ab tr CDATA #IMPLIED>]><r xmlns=""></r>>,
  ],
 },
 {
  method => q<parse_document_entity>,
  t => q(<!DOCTYPE r [<!ATTLIST ab tr CDATA #IMPLIED
                                   ef ID #REQUIRED>]><r></r>),
  result => [
    q<<!DOCTYPE r [<!ATTLIST ab tr CDATA #IMPLIED
                                   ef ID #REQUIRED>]><r xmlns=""></r>>,
    q<<!DOCTYPE r [<!ATTLIST ab tr CDATA #IMPLIED
                                   ef ID #REQUIRED>]><r xmlns=""></r>>,
  ],
 },

 # LAST TEST
);

plan tests => scalar @a;

my $parser = new Message::Markup::XML::Parser::NodeTree;

my $first_error;
my $first_error_desc;
$parser->{error}->{option}->{report} = sub {
  my $err = shift;
  $err->{-object}->set_position ($err->{source}, diff => $err->{position_diff});
  $first_error ||= join ':', $err->{-object}->get_position ($err->{source}),
                          $err->{-type};
  $first_error_desc ||= $err->stringify;
};



my %current = (
  -default => sub {
    +{
      ExpandedURI q<tree:current>
        => Message::Markup::XML::Node->new (type => '#fragment'),
    };
  },
  parse_attribute_specification => sub {
    +{
      ExpandedURI q<tree:current>
        => Message::Markup::XML::Node->new (type => '#fragment'),
      ExpandedURI q<test:result-prefix>
        => q(<r ),
      ExpandedURI q<test:result-suffix>
        => q( xmlns=""></r>),
      ExpandedURI q<test:method> => 'parse_element',
    };
  },
  parse_doctype_external_subset => sub {
    +{
      ExpandedURI q<tree:current>
        => Message::Markup::XML::Node->new (type => '#fragment'),
      ExpandedURI q<test:method> => 'parse_doctype_subset',
      ExpandedURI q<test:option> => {ExpandedURI q<allow-param-entref> => 1},
    };
  },
  parse_in_con_mode => sub {
    +{
      ExpandedURI q<tree:current>
        => Message::Markup::XML::Node->new (type => '#fragment'),
      ExpandedURI q<test:result-prefix>
        => q(<r xmlns="">),
      ExpandedURI q<test:result-suffix>
        => q(</r>),
      ExpandedURI q<test:method> => 'parse_element',
    };
  },
);

my $rr = new mytest::resresolver;

for (@a) {
  undef $first_error;
  undef $first_error_desc;
  $parser->reset;
  $rr->reset;
  $parser->{ExpandedURI q<tree:resource-resolver>} = $rr;
  $rr->{ExpandedURI q<test:resource>} = $_->{resource};
  my $method = $_->{method};
  pos ($_->{t}) = 0;
  my $current = ($current{$method} || $current{-default})->();
  my $node = $current->{ExpandedURI q<tree:current>};
  my $METHOD = $current->{ExpandedURI q<test:method>} || $method;
  for my $name (keys %{$_->{p}}) {
    $current->{$name} = $_->{p}->{$name};
  }
  for my $name (keys %{$_->{flag}}) {
    $parser->{error}->set_flag (\$_->{t}, $name => $_->{flag}->{$name});
  }
  $parser->$METHOD (
    \$_->{t},
    $current,
    %{$_->{option}||{}},
    %{$current->{ExpandedURI q<test:option>}||{}},
  );
  if ($first_error) {
    ok $first_error, $_->{error}, $first_error_desc;
  } else {
    my $ok = 0;
    my $result = $node->stringify;
    my $prefix = $current->{ExpandedURI q<test:result-prefix>} || '';
    my $suffix = $current->{ExpandedURI q<test:result-suffix>} || '';
    for (@{$_->{result}}) {
      if ($result eq $prefix.$_.$suffix) {
        ok $result, $result;
        $ok = 1;
        last;
      }
    }
    ok $result, join ' / ', @{$_->{result}} unless $ok;
  }
}

