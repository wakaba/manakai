#!/usr/bin/perl
use strict;
require Message::Markup::SuikaWikiConfig20::Parser;

my $cfg = Message::Markup::SuikaWikiConfig20::Parser->new;

require Test::Simple;
my $t = q(foo:  aiueo
#comment
#(multiple lines)

#comment
#(multiple lines)
foo:  val
foo:
  value
  with multiple
  \         lines
multiple lines:  val
foo:
  value
  with multiple
  \@         lines
  \\\\ escaped
  \      
name:
  @@:  val
  @foo:  bar
  @foo:  0
  @\@:  \@ foo
  @foo:
     something multi
     \
     \ line
  @foo:
     @@@:
     something\
     \ multi
     \
     \ line
     @@foo:  bar
     @@foo:  0
     @@\@:  \@ foo
     @@foo:
        something\
        \ multi
        \
        \ line
     @@foolist[list]:
        foo
        bar
        \#baz
        bar
###COMMENT##
);

my $parsed = $cfg->parse_text ($t);

my @s = split /\n/, $parsed->stringify;
my @t = split /\n/, $t;

Test::Simple->import (tests => scalar @t);
for (0..($#t > $#s ? $#t : $#s)) {
  ok ($s[$_] eq $t[$_], "Line $_ : '$s[$_]' '$t[$_]'");
}
