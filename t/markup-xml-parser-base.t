#!/usr/bin/perl -w
use strict;
use Test;
use Message::Markup::XML::QName qw/NULL_URI DEFAULT_PFX/;
use Message::Markup::XML::Node;
use Message::Markup::XML::Parser::Base;
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG,
   tree => q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>,
  };

sub match ($$;%) {
  my ($result, $expect, %opt) = @_;
  my $c = +{
    parse_attribute_specification => sub {
      no warnings 'uninitialized';
      qq<<r $_[0] xmlns=""></r>>;
    },
  }->{$opt{method}} || sub {shift};
  if (ref $expect) {
    for (@$expect) {
      return 1 if $result eq $c->($_);
    }
  } else {
    $result eq $c->($expect);
  }
}

my @a =
(
 {
  t => q{"foo"},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 1},
  result => q(1),
 },
 {
  t => q{'foo'},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 1},
  result => q(1),
 },
 {
  t => q{"foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 1},
  result => q(0:4:SYNTAX_ALITC_REQUIRED),
 },
 {
  t => q{'foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 1},
  result => q(0:4:SYNTAX_ALITAC_REQUIRED),
 },
 {
  t => q{foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 1},
  result => q(0:0:SYNTAX_ATTRIBUTE_VALUE),
 },
 {
  t => q{foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 0},
  result => q(0:0:SYNTAX_ATTRIBUTE_VALUE),
 },
 {
  t => q{>},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match-or-error> => 0},
  result => q(1),
 },
 {
  t => q{"foo<bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:4:WFC_NO_LESS_THAN_IN_ATTR_VAL),
 },
 {
  t => q{'foo<bar'},
  method => 'parse_attribute_value_specification',
  result => q(0:4:WFC_NO_LESS_THAN_IN_ATTR_VAL),
 },
 {
  t => q{"foo&amp;bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(1),
 },
 {
  t => q{'foo&amp;bar'},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(1),
 },
 {
  t => q{"foo&#1234;bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(1),
 },
 {
  t => q{'foo&#1234;bar'},
  method => 'parse_attribute_value_specification',
  result => q(1),
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
 },
 {
  t => q{"foo&#xE234;bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(1),
 },
 {
  t => q{'foo&#xE234;bar'},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(1),
 },
 {
  t => q{"foo&#SPACE;bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(0:6:SYNTAX_NAMED_CHARACTER_REFERENCE),
 },
 {
  t => q{"foo&#XE234;bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(0:6:SYNTAX_HCRO_CASE),
 },
 {
  t => q{"foo& bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:5:SYNTAX_HASH_OR_NAME_REQUIRED),
 },
 {
  t => q{'foo&# bar'},
  method => 'parse_attribute_value_specification',
  result => q(0:6:SYNTAX_X_OR_DIGIT_REQUIRED),
 },
 {
  t => q{"foo&#x bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:7:SYNTAX_HEXDIGIT_REQUIRED),
 },
 {
  t => q{"foo&#x0120 bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(0:11:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{"foo&#0120 bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(0:10:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{"foo&amp bar"},
  method => 'parse_attribute_value_specification',
  option => {
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
            },
  result => q(0:8:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{foo="bar"},
  method => 'parse_attribute_specification',
  result => q(1),
 },
 {
  t => q{"bar"},
  method => 'parse_attribute_specification',
  option => {ExpandedURI q<match-or-error> => 1},
  result => q(0:0:SYNTAX_ATTR_NAME_REQUIRED),
 },
 {
  t => q{"bar"},
  method => 'parse_attribute_specification',
  option => {ExpandedURI q<match-or-error> => 0},
  result => q(1),
  output => q(),
 },
 {
  t => qq{foo \t= \x0D"bar"},
  method => 'parse_attribute_specification',
  result => q(1),
  output => q(foo="bar"),
 },
 {
  t => q{foo"bar"},
  method => 'parse_attribute_specification',
  result => q(0:3:SYNTAX_VI_REQUIRED),
 },
 {
  t => q{foo=},
  method => 'parse_attribute_specification',
  result => q(0:4:SYNTAX_ALITO_OR_ALITAO_REQUIRED),
 },
 {
  t => q{foo:bar='baz'},
  method => 'parse_attribute_specification',
  result => q(1),
  output => [q(foo:bar="baz"), q(foo:bar='baz')],
 },
 {
  t => q{:bar='baz'},
  method => 'parse_attribute_specification',
  result => q(1),
  output => [q(:bar="baz"), q(:bar='baz')],
 },
 {
  t => q{r='baz'},
  method => 'parse_attribute_specification',
  result => q(1),
  output => [q(r="baz"), q(r='baz')],
 },
 {
  t => q{r!='baz'},
  method => 'parse_attribute_specification',
  result => q(0:1:SYNTAX_VI_REQUIRED),
 },
 {
  t => q{<foo>},
  method => 'parse_start_tag',
  result => q(1),
 },
 {
  t => q{<foo   >},
  method => 'parse_start_tag',
  result => q(1),
 },
 {
  t => q{<foo},
  method => 'parse_start_tag',
  result => q(0:4:SYNTAX_STAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{<foo bar="baz">},
  method => 'parse_start_tag',
  result => q(1),
 },
 {
  t => q{<foo bar="baz" baz="bar">},
  method => 'parse_start_tag',
  result => q(1),
 },
 {
  t => q{<foo bar="baz"baz="bar">},
  method => 'parse_start_tag',
  result => q(0:14:SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC),
 },
 {
  t => q{<foo bar="bazbaz="bar">},
  method => 'parse_start_tag',
  result => q(0:18:SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC),
 },
 {
  t => q{<foo "baz"baz="bar">},
  method => 'parse_start_tag',
  result => q(0:5:SYNTAX_STAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{<foo="bar">},
  method => 'parse_start_tag',
  result => q(0:4:SYNTAX_STAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{<foo a=bar>},
  method => 'parse_start_tag',
  result => q(0:7:SYNTAX_ATTRIBUTE_VALUE),
 },
 {
  t => q{<foo/>},
  method => 'parse_start_tag',
  result => q(1),
 },
 {
  t => q{<foo/},
  method => 'parse_start_tag',
  result => q(0:5:SYNTAX_NET_REQUIRED),
 },
 {
  t => q{<foo    />},
  method => 'parse_start_tag',
  result => q(1),
 },
 {
  t => q{</foo>},
  method => 'parse_start_tag',
  result => q(0:1:SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED),
 },
 {
  t => q{<},
  method => 'parse_start_tag',
  result => q(0:1:SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED),
 },
 {
  t => q{<<},
  method => 'parse_start_tag',
  result => q(0:1:SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED),
 },
 
 {
  t => q{<e>text</e>},
  method => 'parse_element',
  option => {},
  result => q(1),
 },
 {
  t => q{<e>text<tag>text</tag>text<tag/>text</e>},
  method => 'parse_element',
  option => {},
  result => q(1),
 },
 {
  t => q{<e>text<tag</e>},
  method => 'parse_element',
  result => q(0:11:SYNTAX_STAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{<e>text&ref;and&#1234;text</e>},
  method => 'parse_element',
  result => q(1),
 },

 {
  t => q{<foo></foo bar="baz">},
  method => 'parse_element',
  result => q(0:11:SYNTAX_ETAGC_REQUIRED),
 },
 {
  t => q{<foo></foo/>},
  method => 'parse_element',
  result => q(0:10:SYNTAX_ETAGC_REQUIRED),
 },
 {
  t => q{<foo></foo},
  method => 'parse_element',
  result => q(0:10:SYNTAX_ETAGC_REQUIRED),
 },
 {
  t => q{<foo></b>},
  method => 'parse_element',
  result => q(0:7:WFC_ELEMENT_TYPE_MATCH),
 },
 {
  t => q{<e></},
  method => 'parse_element',
  option => {ExpandedURI q<allow_end_tag> => 0},
  result => q(0:5:SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_ETAGO_REQUIRED),
 },
 {
  t => q{<foo>aa},
  method => 'parse_element',
  result => q(0:7:SYNTAX_END_TAG_REQUIRED),
 },

 {
  t => q{<!-- comment -->},
  method => 'parse_markup_declaration',
  result => 1,
 },
 {
  t => q{<!-- comment- -->},
  method => 'parse_markup_declaration',
  result => 1,
 },
 {
  t => q{<!-- comment-> -->},
  method => 'parse_markup_declaration',
  result => 1,
 },
 {
  t => q{<!-- comment},
  method => 'parse_markup_declaration',
  result => q(0:12:SYNTAX_COMC_REQUIRED),
 },
 {
  t => q{<!-- comment --},
  method => 'parse_markup_declaration',
  result => q(0:15:SYNTAX_MDC_FOR_COMMENT_REQUIRED),
 },
 {
  t => q{<!-- comment --->},
  method => 'parse_markup_declaration',
  result => q(0:15:SYNTAX_MDC_FOR_COMMENT_REQUIRED),
 },
 {
  t => q{<!--- comment -->},
  method => 'parse_markup_declaration',
  result => 1,
 },
 {
  t => q{<!-- comment ----},
  method => 'parse_markup_declaration',
  result => q(0:15:SYNTAX_MULTIPLE_COMMENT),
 },
 {
  t => q{<!-- comment ----aa-->},
  method => 'parse_markup_declaration',
  result => q(0:15:SYNTAX_MULTIPLE_COMMENT),
 },
 {
  t => q{<!-- comment -- >},
  method => 'parse_markup_declaration',
  result => q(0:15:SYNTAX_S_IN_COMMENT_DECLARATION),
 },

 {
  t => q{<e><!-- comment --></e>},
  method => 'parse_element',
  result => 1,
 },
 {
  t => q{<e>bb<!-- comment -->aa</e>},
  method => 'parse_element',
  result => 1,
 },
 {
  t => q{<e>bb<!-- comment -->aa<!--c--></e>},
  method => 'parse_element',
  result => 1,
 },

 {
  t => q{<?pi?>},
  method => 'parse_processing_instruction',
  result => 1,
 },
 {
  t => q{<?pi target-data?>},
  method => 'parse_processing_instruction',
  result => 1,
 },
 {
  t => q{<?pi target-data ?>},
  method => 'parse_processing_instruction',
  result => 1,
 },
 {
  t => q{<?pi target-data="something"?>},
  method => 'parse_processing_instruction',
  result => 1,
 },
 {
  t => q{<?pi target-data="some?>},
  method => 'parse_processing_instruction',
  result => 1,
 },
 {
  t => q{<? system-data ?>},
  method => 'parse_processing_instruction',
  result => q(0:2:SYNTAX_TARGET_NAME_REQUIRED),
 },
 {
  t => q{<?pi},
  method => 'parse_processing_instruction',
  result => q(0:4:SYNTAX_PIC_REQUIRED),
 },
 {
  t => q{<?pi!?>},
  method => 'parse_processing_instruction',
  result => q(0:4:SYNTAX_PIC_REQUIRED),
 },
 
 {
  t => q{<e><?pi?>foo</e>},
  method => 'parse_element',
  result => q(1),
 },
 {
  t => q{<e>bar<?pi?>foo</e>},
  method => 'parse_element',
  result => q(1),
 },

 {
  t => q{<!foo>},
  method => 'parse_markup_declaration',
  result => q(0:2:SYNTAX_UNKNOWN_MARKUP_DECLARATION),
 },

 {
  t => q{<!DOCTYPE>},
  method => 'parse_markup_declaration',
  result => q(0:9:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE >},
  method => 'parse_markup_declaration',
  result => q(0:10:SYNTAX_DOCTYPE_NAME_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE #IMPLIED>},
  method => 'parse_markup_declaration',
  result => q(0:11:SYNTAX_DOCTYPE_IMPLIED),
 },
 {
  t => q{<!DOCTYPE #keyword>},
  method => 'parse_markup_declaration',
  result => q(0:11:SYNTAX_DOCTYPE_RNI_KEYWORD),
 },
 {
  t => q{<!DOCTYPE#IMPLIED>},
  method => 'parse_markup_declaration',
  result => q(0:9:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC>},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC >},
  method => 'parse_markup_declaration',
  result => q(0:22:SYNTAX_PUBID_LITERAL_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC[]>},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC []>},
  method => 'parse_markup_declaration',
  result => q(0:22:SYNTAX_PUBID_LITERAL_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC"pubid">},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid">},
  method => 'parse_markup_declaration',
  result => q(0:29:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC 'pubid'>},
  method => 'parse_markup_declaration',
  result => q(0:29:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid},
  method => 'parse_markup_declaration',
  result => q(0:28:SYNTAX_PUBLIT_MLITC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC 'pubid},
  method => 'parse_markup_declaration',
  result => q(0:28:SYNTAX_PUBLIT_MLITAC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" >},
  method => 'parse_markup_declaration',
  result => q(0:30:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC 'pubid' >},
  method => 'parse_markup_declaration',
  result => q(0:30:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pub<id" "">},
  method => 'parse_markup_declaration',
  result => q(0:26:SYNTAX_PUBID_LITERAL_INVALID_CHAR),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" "sysid">},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" "sysid" >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" "sys<>id">},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid'>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid' >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" "sysid>},
  method => 'parse_markup_declaration',
  result => q(0:37:SYNTAX_SLITC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid>},
  method => 'parse_markup_declaration',
  result => q(0:37:SYNTAX_SLITAC_REQUIRED),
 },
 
 {
  t => q{<!DOCTYPE name SYSTEM>},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM >},
  method => 'parse_markup_declaration',
  result => q(0:22:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM[]>},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM []>},
  method => 'parse_markup_declaration',
  result => q(0:22:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 { 
  t => q{<!DOCTYPE name SYSTEM"sysid">},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM'sysid'>},
  method => 'parse_markup_declaration',
  result => q(0:21:SYNTAX_DOCTYPE_PS_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM "sysid">},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM "sysid" >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM 'sysid'>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM 'sysid' >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM "sysid},
  method => 'parse_markup_declaration',
  result => q(0:28:SYNTAX_SLITC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM 'sysid},
  method => 'parse_markup_declaration',
  result => q(0:28:SYNTAX_SLITAC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name system},
  method => 'parse_markup_declaration',
  result => q(0:15:SYNTAX_MARKUP_DECLARATION_UNKNOWN_KEYWORD),
 },

 {
  t => q{<!DOCTYPE name[]>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name []>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name[ ]   >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name []    >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" "sysid"[]>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" "sysid" []>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid'[]>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid' []>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid'[] >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pubid" 'sysid' []>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name [] SYSTEM 'sysid'},
  method => 'parse_markup_declaration',
  result => q(0:18:SYNTAX_MDC_REQUIRED),
 },

 {
  t => q{<!DOCTYPE name SYSTEM ""[ <!-- --> ]>},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM ""[ <!-- --> ]   >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM ""[ <!-- --> <!> ]>},
  method => 'parse_markup_declaration',
  result => q(0:35:SYNTAX_EMPTY_COMMENT_DECLARATION),
 },
 {
  t => q{<!DOCTYPE name SYSTEM ""[ <!-- -- -- --> ]>},
  method => 'parse_markup_declaration',
  result => q(0:33:SYNTAX_S_IN_COMMENT_DECLARATION),
 },
 {
  t => q{<!DOCTYPE name SYSTEM ""[ <!-- --> ]  },
  method => 'parse_markup_declaration',
  result => q(0:38:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name []aaa>},
  method => 'parse_markup_declaration',
  result => q(0:17:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name PUBLIC "pub" "sys"aaa>},
  method => 'parse_markup_declaration',
  result => q(0:33:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name SYSTEM "sys"aaa>},
  method => 'parse_markup_declaration',
  result => q(0:27:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!DOCTYPE name []      >},
  method => 'parse_markup_declaration',
  result => q(1),
 },
 {
  t => q{<!DOCTYPE name SYSTEM "sys"    >},
  method => 'parse_markup_declaration',
  result => q(1),
 },

 {
  t => q{abcdefg},
  method => 'parse_rpdata',
  result => q(1),
 },
 {
  t => q{abcd&#125;efg},
  method => 'parse_rpdata',
  result => q(1),
 },
 {
  t => q{abcd&#x125;efg},
  method => 'parse_rpdata',
  result => q(1),
 },
 {
  t => q{abcd&e5;efg},
  method => 'parse_rpdata',
  result => q(1),
 },
 {
  t => q{abcd%e5;efg},
  method => 'parse_rpdata',
  result => q(1),
 },
 {
  t => q{abcd&e5efg},
  method => 'parse_rpdata',
  result => q(0:10:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{abcd&#xe5e a},
  method => 'parse_rpdata',
  result => q(0:10:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{abcd%e5efg},
  method => 'parse_rpdata',
  result => q(0:10:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{abcd% e5efg},
  method => 'parse_rpdata',
  result => q(0:5:SYNTAX_PARAENT_NAME_REQUIRED),
 },

 {
  t => q{<!ENTITY "a">},
  method => 'parse_entity_declaration',
  result => q(0:9:SYNTAX_ENTITY_NAME_REQUIRED),
 },
 {
  t => q{<!ENTITY a "a">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY % "a">},
  method => 'parse_entity_declaration',
  result => q(0:11:SYNTAX_ENTITY_PARAM_NAME_REQUIRED),
 },
 {
  t => q{<!ENTITY % a "a">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY #DEFAULT "a">},
  method => 'parse_entity_declaration',
  result => q(0:10:SYNTAX_ENTITY_DEFAULT),
 },
 {
  t => q{<!ENTITY #ALL "a">},
  method => 'parse_entity_declaration',
  result => q(0:10:SYNTAX_ENTITY_RNI_KEYWORD),
 },
 {
  t => q{<!ENTITY % #DEFAULT "a">},
  method => 'parse_entity_declaration',
  result => q(0:11:SYNTAX_ENTITY_PARAM_NAME_REQUIRED),
 },

 {
  t => q{<!ENTITY a "abcde">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a "ab&a;cde">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a "ab%a;cde">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a "ab<c'de">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a 'ab<c"de'>},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a "abcde>},
  method => 'parse_entity_declaration',
  result => q(0:18:SYNTAX_PLITC_REQUIRED),
 },
 {
  t => q{<!ENTITY a 'abcde>},
  method => 'parse_entity_declaration',
  result => q(0:18:SYNTAX_PLITAC_REQUIRED),
 },
 {
  t => q{<!ENTITY a "abcde"    >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a "abcde"aa>},
  method => 'parse_entity_declaration',
  result => q(0:18:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ENTITY a "abcde" aa>},
  method => 'parse_entity_declaration',
  result => q(0:19:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ENTITY % pa "abcde" >},
  method => 'parse_entity_declaration',
  result => q(1),
 },

 {
  t => q{<!ENTITY a SYSTEM "sys">},
  method => 'parse_entity_declaration',
  result => q(1),
 }, 
 {
  t => q{<!ENTITY a SYSTEM "sys"  >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a PUBLIC "pub" "sys">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a PUBLIC "pub" "sys"  >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY %    a PUBLIC "pub" "sys"  >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a PUBLIC "pub" >},
  method => 'parse_entity_declaration',
  result => q(0:24:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 {
  t => q{<!ENTITY a PUBLIC >},
  method => 'parse_entity_declaration',
  result => q(0:18:SYNTAX_PUBID_LITERAL_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM >},
  method => 'parse_entity_declaration',
  result => q(0:18:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" "what?">},
  method => 'parse_entity_declaration',
  result => q(0:24:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ENTITY a PUBLIC "pub" "sys" "what?">},
  method => 'parse_entity_declaration',
  result => q(0:30:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ENTITY a PUBLIC "pub""sys">},
  method => 'parse_entity_declaration',
  result => q(0:23:SYNTAX_ENTITY_PS_REQUIRED),
 },
 {
  t => q{<!ENTITY a PUBLIC"pub" "sys">},
  method => 'parse_entity_declaration',
  result => q(0:17:SYNTAX_ENTITY_PS_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM"sys">},
  method => 'parse_entity_declaration',
  result => q(0:17:SYNTAX_ENTITY_PS_REQUIRED),
 },
 {
  t => q{<!ENTITY a KEYWORD>},
  method => 'parse_entity_declaration',
  result => q(0:11:SYNTAX_ENTITY_TEXT_KEYWORD),
 },
 {
  t => q{<!ENTITY a CDATA "cdata">},
  method => 'parse_entity_declaration',
  result => q(0:11:SYNTAX_ENTITY_TEXT_PRE_KEYWORD),
 },
 {
  t => q{<!ENTITY a "cdata" CDATA>},
  method => 'parse_entity_declaration',
  result => q(0:19:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATA notation>},
  method => 'parse_entity_declaration',
  result => q(1),
 },
);

plan tests => scalar @a;

my $first_error;
my $parser = Message::Markup::XML::Parser::Base->new;
$parser->{error}->{option}->{report} = sub {
  my $err = shift;
  $err->{-object}->set_position ($err->{source}, diff => $err->{position_diff});
  $first_error ||= join ':', $err->{-object}->get_position ($err->{source}),
                          $err->{-type};
};
for (@a) {
  $first_error = '';
  my $method = $_->{method};
  pos ($_->{t}) = 0;
  $parser->$method (
    \$_->{t}, {},
    %{$_->{option}||{}},
  );
  ok $first_error || 1, $_->{result};
}
