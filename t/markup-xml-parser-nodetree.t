#!/usr/bin/perl -w
use strict;

use Message::Markup::XML::Node;
use Message::Markup::XML::Parser::NodeTree;
use Message::Markup::XML::QName qw/:prefix :special-uri/;
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG (),
   tree => Message::Markup::XML::Parser::NodeTree::URI_CONFIG (),
   test => q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/test/>,
  };
use Test;

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
          method => q(parse_in_con_mode),
          t => q(<r><a href="1" href="2"></a></r>),
          error => q(0:23:WFC_UNIQUE_ATT_SPEC),
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r><a xmlns="1" xmlns="2"></a></r>),
          error => q(0:25:WFC_UNIQUE_ATT_SPEC),
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
          t => q(<r href="http://&host;/"></r>),
          result => [q(href="http://&host;/")],
         },
         {
          method => q(parse_attribute_specification),
          t => q(<r href="http://test&#x2F;"></r>),
          result => [q(href="http://test&#x2F;")],
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
          t => q(<r>&a;</r>),
          result => [q(&a;)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb&aa;cc</r>),
          result => [q(bb&aa;cc)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r>bb&aa;c&#x70;d&#120;c</r>),
          result => [q(bb&aa;c&#x70;d&#120;c)],
         },
         {
          method => q(parse_in_con_mode),
          t => q(<r><dd>bb&aa;cc</dd>&ee;</r>),
          result => [q(<dd>bb&aa;cc</dd>&ee;),
                     q(<dd xmlns="">bb&aa;cc</dd>&ee;)],
         },
         {
          method => q(parse_element),
          t => q(<b>&a</b>),
          error => q(0:5:SYNTAX_REFC_REQUIRED),
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
          t => q{<?xml?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:2:SYNTAX_PI_TARGET_XML),
         },
         {
          t => q{<?XML?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:2:SYNTAX_PI_TARGET_XML),
         },
         {
          t => q{<?XmL?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:2:SYNTAX_PI_TARGET_XML),
         },
         {
          t => q{<?xml ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:6:SYNTAX_XML_VERSION_REQUIRED),
         },
         {
          t => q{<?xml ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:6:SYNTAX_XML_ENCODING_REQUIRED),
         },
         {
          t => q{<?xml ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:6:SYNTAX_XML_ENCODING_REQUIRED),
         },
 {
  t => q{<?xml system-data ?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<check-xml-declaration> => 1},
  error => q(0:0:SYNTAX_XML_DECLARATION_IN_MIDDLE),
 },
 {
  t => q{<?xMl system-data ?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<check-xml-declaration> => 1},
  error => q(0:2:SYNTAX_PI_TARGET_XML),
 },
 {
  t => q{<?xml-something system-data ?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<check-xml-declaration> => 1},
  result => [q(<?xml-something system-data ?>)],
 },
 {
  t => q{<?xml version="1.0"?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  result => [q(<?xml version="1.0"?>)],
 }, 
 {
  t => q{<?xml version="1.0" ?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  result => [q(<?xml version="1.0"?>)],
 },
 {
  t => qq{<?xml \tversion  =  "1.0"?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  result => [q(<?xml version="1.0"?>)],
 },
 {
  t => q{<?xml version='1.0' ?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  result => [q(<?xml version="1.0"?>)],
 },
 {
  t => q{<?xml version="1.0"encoding="iso-2022-jp"?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  error => q(0:19:SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC),
 },
 {
  t => q{<?xml version="1.0?>},
  method => 'parse_processing_instruction',
  option => {ExpandedURI q<allow-xml-declaration> => 1},
  error => q(0:18:SYNTAX_ALITC_REQUIRED),
 },
         {
          t => q{<?xml version=1.0?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:14:SYNTAX_ALITO_OR_ALITAO_REQUIRED),
         },
         {
          t => q{<?xml version="1.1"?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          result => [q(<?xml version="1.1"?>)],
         },
         {
          t => q{<?xml version="1.2"?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:15:SYNTAX_XML_VERSION_UNSUPPORTED),
         },
         {
          t => q{<?xml version="1+2"?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:15:SYNTAX_XML_VERSION_INVALID),
         },
         {
          t => q{<?xml version=""?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:15:SYNTAX_XML_VERSION_INVALID),
         },
         
         {
          t => q{<?xml  encoding = 'iso-2022-jp'?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml encoding="iso-2022-jp"?>)],
         },
         {
          t => q{<?xml  encoding = 'iso-2022-jp'?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:31:SYNTAX_XML_VERSION_REQUIRED),
         },
         {
          t => q{<?xml  encoding = 'iso+2022+jp'?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:19:SYNTAX_XML_ENCODING_INVALID),
         },
         {
          t => q{<?xml encoding = ""?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:18:SYNTAX_XML_ENCODING_INVALID),
         },
         {
          t => q{<?xml  encoding = 'iso-2022-jp' version="1.0"?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:45:SYNTAX_XML_VERSION_REQUIRED),
         },
         {
          t => q{<?xml version="1.0" encoding = 'iso-2022-jp'?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="iso-2022-jp"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'iso-2022-jp'?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="iso-2022-jp"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'iso-2022-jp'?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="iso-2022-jp"?>)],
         },
         
         {
          t => q{<?xml version="1.0" encoding = 'UTF-8' standalone="yes" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'UTF-8' standalone="no" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1,
                     ExpandedURI q<allow-text-declaration> => 1},
          result => [q(<?xml version="1.0" encoding="UTF-8" standalone="no"?>)],
         },
         {
          t => q{<?xml version="1.0" encoding = 'UTF-8' standalone="no" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:51:SYNTAX_XML_STANDALONE),
         },
         {
          t => q{<?xml version="1.0" encoding = 'UTF-8' standalone="unknown" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:51:SYNTAX_XML_STANDALONE_INVALID),
         },
         {
          t => qq{<?xml version="1.0" encoding = 'UTF-8' \tstandalone="no" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:52:COMPAT_XML_STANDALONE_S),
         },
         {
          t => qq{<?xml version="1.1" encoding = 'UTF-8' \tstandalone="no" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:52:SYNTAX_XML_STANDALONE_S),
         },
         {
          t => qq{<?xml standalone = "yes" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:25:SYNTAX_XML_VERSION_REQUIRED),
         },
         {
          t => qq{<?xml standalone = "yes" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:25:SYNTAX_XML_ENCODING_REQUIRED),
         },
         {
          t => qq{<?xml encoding="iso-2022-jp" standalone = "yes" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-text-declaration> => 1},
          error => q(0:43:SYNTAX_XML_STANDALONE),
         },
         {
          t => qq{<?xml version="1.1" encode="iso-2022-jp" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:28:SYNTAX_XML_UNKNOWN_ATTR),
         },
         {
          t => q{<?xml <#version="1.&#x31;" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:6:SYNTAX_ATTR_SPEC_REQUIRED),
         },
         {
          t => qq{<?xml version="&version;" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:15:SYNTAX_GENERAL_ENTREF),
         },
         {
          t => q{<?xml version="1.&#x31;" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:17:SYNTAX_HEX_CHAR_REF),
         },
         {
          t => qq{<?xml version="-&#31;-" ?>},
          method => 'parse_processing_instruction',
          option => {ExpandedURI q<allow-xml-declaration> => 1},
          error => q(0:16:SYNTAX_NUMERIC_CHAR_REF),
         },

         {
          t => q{<!DOCTYPE root>},
          method => q(parse_markup_declaration),
          result => [q{<!DOCTYPE root>},
                     q{<!DOCTYPE root []>}],
         },
         {
          t => q{<!DOCTYPE root[]>},
          method => q(parse_markup_declaration),
          result => [q{<!DOCTYPE root>},
                     q{<!DOCTYPE root []>}],
         },
);

plan tests => scalar @a;

my $parser = new Message::Markup::XML::Parser::NodeTree;

my $first_error;
$parser->{error}->{option}->{report} = sub {
  my $err = shift;
  $err->{-object}->set_position ($err->{source}, diff => $err->{position_diff});
  $first_error ||= join ':', $err->{-object}->get_position ($err->{source}),
                          $err->{-type};
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
for (@a) {
  undef $first_error;
  my $method = $_->{method};
  pos ($_->{t}) = 0;
  my $current = ($current{$method} || $current{-default})->();
  my $node = $current->{ExpandedURI q<tree:current>};
  my $METHOD = $current->{ExpandedURI q<test:method>} || $method;
  $parser->$METHOD (
    \$_->{t},
    $current,
    %{$_->{option}||{}},
  );
  if ($first_error) {
    ok $first_error, $_->{error};
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
