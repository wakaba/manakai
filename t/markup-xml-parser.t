#!/usr/bin/perl -w
use strict;
use Test;
use Message::Markup::XML::QName qw/NULL_URI DEFAULT_PFX/;
use Message::Markup::XML::Node;
use Message::Markup::XML::Parser;
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::URI_CONFIG,
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
  option => {ExpandedURI q<match_or_error> => 1},
  result => q(1),
 },
 {
  t => q{'foo'},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match_or_error> => 1},
  result => q(1),
 },
 {
  t => q{"foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match_or_error> => 1},
  result => q(0:4:SYNTAX_ALITC_REQUIRED),
 },
 {
  t => q{'foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match_or_error> => 1},
  result => q(0:4:SYNTAX_ALITAC_REQUIRED),
 },
 {
  t => q{foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match_or_error> => 1},
  result => q(0:0:SYNTAX_ALITO_OR_ALITAO_REQUIRED),
 },
 {
  t => q{foo},
  method => 'parse_attribute_value_specification',
  option => {ExpandedURI q<match_or_error> => 0},
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
  result => q(1),
 },
 {
  t => q{'foo&amp;bar'},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{"foo&#1234;bar"},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{'foo&#1234;bar'},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{"foo&#xE234;bar"},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{'foo&#xE234;bar'},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{"foo&#SPACE;bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:6:SYNTAX_NAMED_CHARACTER_REFERENCE),
 },
 {
  t => q{"foo&#XE234;bar"},
  method => 'parse_attribute_value_specification',
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
  result => q(0:11:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{"foo&#0120 bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:10:SYNTAX_REFC_REQUIRED),
 },
 {
  t => q{"foo&amp bar"},
  method => 'parse_attribute_value_specification',
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
  option => {ExpandedURI q<match_or_error> => 1},
  result => q(0:0:SYNTAX_ATTR_NAME_REQUIRED),
 },
 {
  t => q{"bar"},
  method => 'parse_attribute_specification',
  option => {ExpandedURI q<match_or_error> => 0},
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
  t => q{<foo="bar">},
  method => 'parse_start_tag',
  result => q(0:4:SYNTAX_STAGC_OR_NESTC_REQUIRED),
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
  result => q(0:16:SYNTAX_S_IN_COMMENT_DECLARATION),
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

);

plan tests => scalar @a;

my $first_error;
my $parser = Message::Markup::XML::Parser->new;
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
