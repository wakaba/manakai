#!/usr/bin/perl -w
use strict;
use Carp q(verbose);
require Test::Simple;
sub OK ($$) {
  my ($result, $expect) = @_;
  if ($result eq $expect) {
    ok (1);
  } else {
    ok (0, qq("$result" : "$expect" expected));
  }
}

my @s = (
         {
          rule => 'BARE-TEXT ONLY RULE',
          result => 'BARE-TEXT ONLY RULE',
         },
         {
          rule => 'BARE-TEXT%undefined;BARE-TEXT',
          result => 'BARE-TEXT[undef: undefined]BARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%percent;BARE-TEXT',
          result => 'BARE-TEXT%BARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%foo;BARE-TEXT',
          result => 'BARE-TEXT[foo:][:foo]BARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%bar(param=>{value});BARE-TEXT',
          result => 'BARE-TEXTvalueBARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%bar(param=>{%foo;}p);BARE-TEXT',
          result => 'BARE-TEXT[foo:][:foo]BARE-TEXT',
         },
         {
          rule => '%i;BARE-TEXT%i;BARE-TEXT%i;',
          result => '1BARE-TEXT2BARE-TEXT3',
         },
         {
          rule => 'BARE-TEXT%baz(param=>{%foo;}p);BARE-TEXT',
          result => 'BARE-TEXT[foo:][:foo]BARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%hoge (param=>{%foo;}p);BARE-TEXT',
          result => 'BARE-TEXT[foo:][:foo]BARE-TEXT',
         },
         {
          rule => '%l (bare);,%l;,%l (bare => 0);,%l (bare => foo);',
          result => '1,,0,foo',
         },
        );
Test::Simple->import (tests => scalar @s);
                             
my $f = node_formatter->new ();
my $o = {}; 
for (@s) {
  my $result = $f->replace ($_->{rule}, param => $o);
  OK $result, $_->{result};
}


package node_formatter;
BEGIN {
require Message::Util::Formatter::Node;
our @ISA = q(Message::Util::Formatter::Node);
require Message::Markup::XML::Node;
}
sub replace_option () {
  return {
    -class => 'Message::Markup::XML::Node',
  };
}

sub rule_def {+{
  foo => {
    main => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-parent}->append_text (qq([$name:]));
      $p->{-parent}->append_text (qq([:$name]));
    },
  },
  bar => {
    main => sub {
      my ($f, $name, $p, $o, %opt) = @_;
      $f->parse_attr ($p, 'param', $o, -parent => $p->{-parent}, 
                      -non_parsed_to_node => 1, %opt);
    },
  },
  baz => {
    main => sub {
      my ($f, $name, $p, $o, %opt) = @_;
      $f->parse_attr ($p, 'param', $o,
                      -non_parsed_to_node => 1, %opt);
      $p->{-parent}->append_node ($p->{param});
    },
  },
  hoge => {
    main => sub {
      my ($f, $name, $p, $o, %opt) = @_;
      $f->parse_attr ($p, 'param', $o, %opt);
      $p->{-parent}->append_node ($p->{param}, node_or_text => 1);
    },
  },
  i => {
    main => sub {
      my ($f, $name, $p, $o, %opt) = @_;
      $p->{-parent}->append_text (++$o->{i});
    },
  },
  l => {
    main => sub {
      my ($f, $name, $p, $o, %opt) = @_;
      $p->{-parent}->append_text ($p->{bare});
    },
  },
}}
