#!/usr/bin/perl -w
use strict;
use Test;
use Message::Markup::XML::QName qw/NULL_URI/;
use Message::Markup::XML::Node;
use Message::Markup::XML::Parser;

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
  option => {match_or_error => 1},
  result => q(1),
 },
 {
  t => q{"foo},
  method => 'parse_attribute_value_specification',
  option => {match_or_error => 1},
  result => q(0:4:SYNTAX_CLOSE_LIT_REQUIRED),
 },
 {
  t => q{'foo},
  method => 'parse_attribute_value_specification',
  option => {match_or_error => 1},
  result => q(0:4:SYNTAX_CLOSE_LITA_REQUIRED),
 },
 {
  t => q{foo},
  method => 'parse_attribute_value_specification',
  option => {match_or_error => 1},
  result => q(0:0:SYNTAX_OPEN_LIT_OR_LITA_REQUIRED),
 },
 {
  t => q{foo},
  method => 'parse_attribute_value_specification',
  option => {match_or_error => 0},
  result => q(1),
 },
 {
  t => q{"foo<bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:4:WFC_NO_LESS_THAN_IN_ATTR_VAL),
 },
 {
  t => q{"foo&amp;bar"},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{"foo&#1234;bar"},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{"foo&#xE234;bar"},
  method => 'parse_attribute_value_specification',
  result => q(1),
 },
 {
  t => q{"foo& bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:5:SYNTAX_HASH_OR_NAME_REQUIRED),
 },
 {
  t => q{"foo&# bar"},
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
  result => q(0:11:SYNTAX_REFERENCE_END_REQUIRED),
 },
 {
  t => q{"foo&#0120 bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:10:SYNTAX_REFERENCE_END_REQUIRED),
 },
 {
  t => q{"foo&amp bar"},
  method => 'parse_attribute_value_specification',
  result => q(0:8:SYNTAX_REFERENCE_END_REQUIRED),
 },
 {
  t => q{foo="bar"},
  method => 'parse_attribute_specification',
  result => q(1),
 },
 {
  t => q{"bar"},
  method => 'parse_attribute_specification',
  option => {match_or_error => 1},
  result => q(0:0:SYNTAX_ATTR_NAME_REQUIRED),
 },
 {
  t => q{"bar"},
  method => 'parse_attribute_specification',
  option => {match_or_error => 0},
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
  result => q(0:4:SYNTAX_OPEN_LIT_OR_LITA_REQUIRED),
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
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(1),
 },
 {
  t => q{<foo   >},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(1),
 },
 {
  t => q{<foo>},
  method => 'parse_tag',
  option => {allow_start_tag => 0},
  result => q(0:0:SYNTAX_START_TAG_NOT_ALLOWED),
 },
 {
  t => q{<foo},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(0:4:SYNTAX_START_TAG_TAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{<foo bar="baz">},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(1),
 },
 {
  t => q{<foo bar="baz" baz="bar">},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(1),
 },
 {
  t => q{<foo bar="baz"baz="bar">},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(0:14:SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC),
 },
 {
  t => q{<foo="bar">},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(0:4:SYNTAX_START_TAG_TAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{<foo/>},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(1),
 },
 {
  t => q{<foo/},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(0:5:SYNTAX_NET_REQUIRED),
 },
 {
  t => q{<foo    />},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(1),
 },
 {
  t => q{</foo>},
  method => 'parse_tag',
  option => {allow_end_tag => 1},
  result => q(1),
 },
 {
  t => q{</foo    >},
  method => 'parse_tag',
  option => {allow_end_tag => 1},
  result => q(1),
 },
 {
  t => q{</foo>},
  method => 'parse_tag',
  option => {allow_end_tag => 0},
  result => q(0:0:SYNTAX_END_TAG_NOT_ALLOWED),
 },
 {
  t => q{</foo bar="baz">},
  method => 'parse_tag',
  option => {allow_end_tag => 1},
  result => q(0:6:SYNTAX_END_TAG_TAGC_REQUIRED),
 },
 {
  t => q{</foo/>},
  method => 'parse_tag',
  option => {allow_end_tag => 1},
  result => q(0:5:SYNTAX_END_TAG_TAGC_REQUIRED),
 },
 {
  t => q{</foo},
  method => 'parse_tag',
  option => {allow_end_tag => 1},
  result => q(0:5:SYNTAX_END_TAG_TAGC_REQUIRED),
 },
 {
  t => q{</},
  method => 'parse_tag',
  option => {allow_end_tag => 1},
  result => q(0:2:SYNTAX_ELEMENT_TYPE_NAME_REQUIRED),
 },
 {
  t => q{</},
  method => 'parse_tag',
  option => {allow_end_tag => 0},
  result => q(0:0:SYNTAX_END_TAG_NOT_ALLOWED),
 },
 {
  t => q{<},
  method => 'parse_tag',
  option => {allow_start_tag => 1},
  result => q(0:1:SYNTAX_ELEMENT_TYPE_NAME_REQUIRED),
 },
 {
  t => q{<},
  method => 'parse_tag',
  option => {allow_start_tag => 1, allow_end_tag => 1},
  result => q(0:1:SYNTAX_SLASH_OR_ELEMENT_TYPE_NAME_REQUIRED),
 },
 {
  t => q{},
  method => 'parse_tag',
  option => {allow_end_tag => 1, allow_start_tag => 1, match_or_error => 1},
  result => q(0:0:SYNTAX_TAG_REQUIRED),
 },
 {
  t => q{text},
  method => 'parse_con_mode',
  option => {},
  result => q(1),
 },
 {
  t => q{text<tag>text</tag>text<tag/>text},
  method => 'parse_con_mode',
  option => {},
  result => q(1),
 },
 {
  t => q{text<tag},
  method => 'parse_con_mode',
  result => q(0:8:SYNTAX_START_TAG_TAGC_OR_NESTC_REQUIRED),
 },
 {
  t => q{text&ref;and&#1234;text},
  method => 'parse_con_mode',
  result => q(1),
 }
);
plan tests => scalar @a;

my $last_error;
my $err = Message::Markup::XML::Parser->error;
$err->{option}->{report} = sub {
  my $err = shift;
  $err->{-object}->set_position ($err->{source}, diff => $err->{position_diff});
  $last_error = join ':', $err->{-object}->get_position ($err->{source}),
                          $err->{-type};
};
my %parent = (
  -default => sub {
    new Message::Markup::XML::Node type => '#fragment';
  },
  parse_attribute_specification => sub {
    new Message::Markup::XML::Node type => '#element',
                                   namespace_uri => NULL_URI,
                                   local_name => q(r);
  },
);
for (@a) {
  $last_error = '1';
  my $method = $_->{method};
  pos ($_->{t}) = 0;
  my $parent = ($parent{$method} or $parent{-default})->();
  Message::Markup::XML::Parser->$method (
    \$_->{t}, parent => $parent, -error => $err, %{$_->{option}||{}},
  );
  ok $last_error, $_->{result};
#  skip (not ($_->{result} eq '1' and $last_error eq $_->{result}),
#        match ($parent->stringify => $_->{output}, method => $method));
}
