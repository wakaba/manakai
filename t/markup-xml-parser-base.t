#!/usr/bin/perl -w
use strict;
use Test;
use Message::Markup::XML::QName qw/NULL_URI DEFAULT_PFX/;
use Message::Markup::XML::Node;
use Message::Markup::XML::Parser::Base;
BEGIN {
  our $NS =
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG,
   tree => q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>,
   test => q<mid:t.markup-xml-parser-base.t+2004.5.20@manakai.suika.fam.cx#>,
  };
}
use Message::Util::QName::General [qw/ExpandedURI/], our $NS;

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
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATA notation     >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys"NDATA notation>},
  method => 'parse_entity_declaration',
  result => q(0:23:SYNTAX_ENTITY_PS_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATAnotation>},
  method => 'parse_entity_declaration',
  result => q(0:24:SYNTAX_ENTITY_DATA_TYPE_UNKNOWN_KEYWORD),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATA notation  aa   >},
  method => 'parse_entity_declaration',
  result => q(0:40:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATA >},
  method => 'parse_entity_declaration',
  result => q(0:30:SYNTAX_ENTITY_DATA_TYPE_NOTATION_NAME_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATA #>},
  method => 'parse_entity_declaration',
  result => q(0:30:SYNTAX_ENTITY_DATA_TYPE_NOTATION_NAME_REQUIRED),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" CDATA a>},
  method => 'parse_entity_declaration',
  result => q(0:24:SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" SDATA a>},
  method => 'parse_entity_declaration',
  result => q(0:24:SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" SUBDOC a>},
  method => 'parse_entity_declaration',
  result => q(0:24:SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD),
 },
 {
  t => q{<!ENTITY a SYSTEM "sys" NDATA b [ attr=val ]>},
  method => 'parse_entity_declaration',
  result => q(0:32:SYNTAX_MDC_REQUIRED),
 },

 {
  entity => {b => ''},
  t => q{<!ENTITY a "%b;">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => ''},
  t => q{<!ENTITY a %b; "aa">},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => '"aa"'},
  t => q{<!ENTITY a %b;>},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => q<SYSTEM "foo">},
  t => q{<!ENTITY a %b;>},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => q<  PUBLIC "pub" 'sys'  >},
  t => q{<!ENTITY a %b;>},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => 'SYSTEM'},
  t => q{<!ENTITY a %b;>},
  method => 'parse_entity_declaration',
  result => q(0:14:SYNTAX_ENTITY_PS_REQUIRED),
 },
 {
  entity => {b => "SYSTEM"},
  t => q{<!ENTITY a %b; >},
  method => 'parse_entity_declaration',
  result => q(0:15:SYNTAX_SYSTEM_LITERAL_REQUIRED),
 },
 {
  entity => {b => q<  SYSTEM "foo" >},
  t => q{<!ENTITY a %b; >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => q<  SYSTEM %c; >,
             c => q< "sys" >},
  t => q{<!ENTITY a %b; >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => q<SYSTEM %c; >,
             c => q< "sys" >},
  t => q{<!ENTITY%b; >},
  method => 'parse_entity_declaration',
  result => q(1),
 },
 {
  entity => {b => q[SYSTEM %c; > ],
             c => q< "sys" >},
  t => q{<!ENTITY%b; >},
  method => 'parse_entity_declaration',
  result => q(0:11:SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM),
 },

 {
  t => q{<!ENTITY --comment-->},
  method => 'parse_entity_declaration',
  result => q(0:9:SYNTAX_PS_COMMENT),
 },
 {
  t => q{<!ENTITY a --comment-->},
  method => 'parse_entity_declaration',
  result => q(0:11:SYNTAX_PS_COMMENT),
 },
 {
  t => q{<!ENTITY a "a" --comment-->},
  method => 'parse_entity_declaration',
  result => q(0:15:SYNTAX_PS_COMMENT),
 },

 {
  t => q{<!ELEMENT el ANY>},
  method => 'parse_element_declaration',
  result => q(1),
 },
 {
  t => q{<!ELEMENT el EMPTY   >},
  method => 'parse_element_declaration',
  result => q(1),
 },
 {
  t => q{<!ELEMENT el CDATA>},
  method => 'parse_element_declaration',
  result => q(0:13:SYNTAX_ELEMENT_SGML_CONTENT_KEYWORD),
 },
 {
  t => q{<!ELEMENT el RCDATA>},
  method => 'parse_element_declaration',
  result => q(0:13:SYNTAX_ELEMENT_SGML_CONTENT_KEYWORD),
 },
 {
  t => q{<!ELEMENT el foo>},
  method => 'parse_element_declaration',
  result => q(0:13:SYNTAX_ELEMENT_UNKNOWN_CONTENT_KEYWORD),
 },
 {
  t => q{<!ELEMENT el ANY foo>},
  method => 'parse_element_declaration',
  result => q(0:17:SYNTAX_MDC_REQUIRED),
 },
 {
  t => q{<!ELEMENT el - - ANY>},
  method => 'parse_element_declaration',
  result => q(0:13:SYNTAX_ELEMENT_TAG_MIN),
 },
 {
  t => q{<!ELEMENT el o - ANY>},
  method => 'parse_element_declaration',
  result => q(0:13:SYNTAX_ELEMENT_TAG_MIN),
 },
 {
  t => q{<!ELEMENT (el) o - ANY>},
  method => 'parse_element_declaration',
  result => q(0:10:SYNTAX_ELEMENT_DECLARATION_TYPE_NAME_GROUP),
 },
 {
  t => q{<!ELEMENT el 1 o - ANY>},
  method => 'parse_element_declaration',
  result => q(0:13:SYNTAX_ELEMENT_RANK_SUFFIX),
 },
 {
  t => q{<!ELEMENT>},
  method => 'parse_element_declaration',
  result => q(0:9:SYNTAX_ELEMENT_PS_REQUIRED),
 },
 {
  t => q{<!ELEMENT >},
  method => 'parse_element_declaration',
  result => q(0:10:SYNTAX_ELEMENT_DECLARATION_TYPE_NAME_REQUIRED),
 },
 {
  t => q{<!ELEMENT e>},
  method => 'parse_element_declaration',
  result => q(0:11:SYNTAX_ELEMENT_PS_REQUIRED),
 },
 {
  t => q{<!ELEMENT e >},
  method => 'parse_element_declaration',
  result => q(0:12:SYNTAX_ELEMENT_MODEL_OR_MIN_OR_RANK_REQUIRED),
 },
 {
  t => q{<!ELEMENT e ANY},
  method => 'parse_element_declaration',
  result => q(0:15:SYNTAX_MDC_REQUIRED),
 },

 {
  t => q<(a)>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<(a,b)>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<(a,b,c)>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<(   a , b  )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<(   a , b  >,
  method => 'parse_model_group',
  result => '0:11:SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
 },
  {
  t => q<(   a ,   >,
  method => 'parse_model_group',
  result => '0:10:SYNTAX_MODEL_GROUP_ITEM_REQUIRED',
 },

 {
  t => q<( a+ )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a* )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a? )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a?, b )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a?, b, c+ )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a?, b*, c+ )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a?>,
  method => 'parse_model_group',
  result => '0:4:SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
 },
 {
  t => q<( a ?>,
  method => 'parse_model_group',
  result => '0:4:SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
 },

 {
  t => q<( a | b )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a & b )>,
  method => 'parse_model_group',
  result => '0:4:SYNTAX_CONNECTOR',
 },

 {
  t => q<( a , b )*>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a , b )+>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a , b )?>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a , (b)* )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a , (b, c)* )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a , (b, (c, d)+)* )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( a , ([b, %ry; ], (c, d)+)* )>,
  method => 'parse_model_group',
  result => '0:7:SYNTAX_DATA_TAG_GROUP',
 },

 {
  t => q<( a -- , b -- )>,
  method => 'parse_model_group',
  result => '0:4:SYNTAX_PS_COMMENT',
 },
 {
  entity => {
    b => q<, b>,
  },
  t => q<( a %b; )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  entity => {
    b => q<, >,
  },
  t => q<( a %b; )>,
  method => 'parse_model_group',
  result => '0:8:SYNTAX_MODEL_GROUP_ITEM_REQUIRED',
 },
 {
  entity => {
    b => q<, (b) >,
  },
  t => q<( a %b; )>,
  method => 'parse_model_group',
  result => 1,
 },
 {
  entity => {
    b => q<, (b >,
  },
  t => q<( a %b; ))>,
  method => 'parse_model_group',
  result => '0:5:SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
 },
 {
  entity => {
    b => q<, b) >,
  },
  t => q<( a %b; >,
  method => 'parse_model_group',
  result => '0:3:SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
 },

 {
  t => q<( #PCDATA )* >,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( #PCDATA ) >,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( #PCDATA | a )* >,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( #PCDATA | a | b)* >,
  method => 'parse_model_group',
  result => 1,
 },
 {
  t => q<( #PCDATA )+ >,
  method => 'parse_model_group',
  result => '0:11:SYNTAX_MODEL_GROUP_PCDATA_OCCUR',
 },
 {
  t => q<( #PCDATA | a )+ >,
  method => 'parse_model_group',
  result => '0:15:SYNTAX_MODEL_GROUP_MIXED_OCCUR',
 },
 {
  t => q<( #PCDATA , a )* >,
  method => 'parse_model_group',
  result => '0:10:SYNTAX_MODEL_GROUP_MIXED_CONNECTOR',
 },
 {
  t => q<( #PCDATA | (a) )* >,
  method => 'parse_model_group',
  result => '0:12:SYNTAX_MODEL_GROUP_MIXED_NESTED',
 },
 {
  t => q<( b | #PCDATA )* >,
  method => 'parse_model_group',
  result => '0:7:SYNTAX_MODEL_GROUP_PCDATA_POSITION',
 },
 {
  t => q<( b | #foo )* >,
  method => 'parse_model_group',
  result => '0:7:SYNTAX_MODEL_GROUP_UNKNOWN_KEYWORD',
 },
 {
  t => q<( #PCDATA | a , b ) >,
  method => 'parse_model_group',
  result => '0:14:SYNTAX_MODEL_GROUP_CONNECTOR_MATCH',
 },
 {
  t => q<( a , b | a) >,
  method => 'parse_model_group',
  result => '0:8:SYNTAX_MODEL_GROUP_CONNECTOR_MATCH',
 },

 {
  t => q<<!ELEMENT e ( a , b , a) >>,
  method => 'parse_element_declaration',
  result => '1',
 },
 {
  t => q<<!ELEMENT e ( a , b  >>,
  method => 'parse_element_declaration',
  result => '0:21:SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
 },
 {
  entity => {b => q<(a, b>},
  t => q<<!ELEMENT e %b; ) >>,
  method => 'parse_element_declaration',
  result => '0:5:SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
 },
 {
  entity => {b => q[(a, b )>]},
  t => q[<!ELEMENT e %b; ],
  method => 'parse_element_declaration',
  result => '0:7:SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
 },
);

plan tests => scalar @a;

my $first_error;
my $first_error_detail;
my $parser = new test_parser;
$parser->{error}->{option}->{report} = sub {
  my $err = shift;
  $err->{-object}->set_position ($err->{source}, diff => $err->{position_diff});
  unless ($first_error) {
    $first_error = join ':', $err->{-object}->get_position ($err->{source}),
                          $err->{-type};
    $first_error_detail = $err->stringify;
  }
};
for (@a) {
  $first_error = '';
  $first_error_detail = '';
  my $method = $_->{method};
  pos ($_->{t}) = 0;
  $parser->{ExpandedURI q<test:entity>} = $_->{entity} || {};
  $parser->$method (
    \$_->{t}, {},
    %{$_->{option}||{}},
  );
  ok $first_error || 1, $_->{result}, $first_error_detail;
}

package test_parser;
BEGIN {
  push our @ISA, 'Message::Markup::XML::Parser::Base';
  use Message::Util::QName::General [qw/ExpandedURI/], $main::NS;
}

sub parameter_entity_reference_in_parameter_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  for my $reptxt ($self->{ExpandedURI q<test:entity>}
                       ->{$pp->{ExpandedURI q<entity-name>}}) {
    push @{$opt{ExpandedURI q<source>}}, \$reptxt if $reptxt;
  }
}

