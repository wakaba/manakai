#!/usr/bin/perl
use strict;
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
          rule => 'BARE-TEXT%percent (prefix => {>},
                                      suffix => {<} );BARE-TEXT',
          result => 'BARE-TEXT>%<BARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%foo;BARE-TEXT',
          result => 'BARE-TEXT[foo:][:foo]BARE-TEXT',
         },
         {
          rule => 'BARE-TEXT%bar(param=>"value");BARE-TEXT',
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
          rule => '%j;%j(content=>{%j;}p);%j;',
          result => '[1[]2][5[[3[]4]]6][7[]8]',
         },
         {
          rule => '%k;%k(content=>{%k;}p);%k;',
          result => '[1[]2][3[[5[]6]]4][7[]8]',
         },
         {
          rule => '%l (bare);,%l;,%l (bare => 0);,%l (bare => foo);',
          result => '1,,0,foo',
         },
        );
Test::Simple->import (tests => scalar @s);
                             
my $f = test_formatter->new ();
my $o = {}; 
for (@s) {
  my $result = $f->replace ($_->{rule}, param => $o);
  OK $result, $_->{result};
}


package test_formatter;
BEGIN {
require Message::Util::Formatter::Text;
our @ISA = q(Message::Util::Formatter::Text);
}
sub ___rule_def {+{
  foo => {
    before => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} .= "[$name:]";
    },
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} .= "[:$name]";
    },
  },
  bar => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} .= $p->{param};
    },
  },
  i => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} .= ++$o->{param};
    },
  },
  j => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} .= '['.++$o->{param1}.'['
                      . ($p->{content} || '')
                      .']'.++$o->{param1}.']';
    },
  },
  k => {
    before => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} .= '['.++$o->{param2}.'[%%%%'
                      .']'.++$o->{param2}.']';
    },
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} =~ s/%%%%/$p->{content}||''/ge;
    },
  },
  l => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} = $p->{bare};
    },
  },
}}
