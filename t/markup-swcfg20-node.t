#!/usr/bin/perl
use strict;
require Message::Markup::SuikaWikiConfig20::Node;

my $cfg = Message::Markup::SuikaWikiConfig20::Node->new (type => '#document');

$cfg->append_new_node (type => '#element', local_name => 'foo')
    ->inner_text (new_value => 'aiueo');
$cfg->append_new_node (type => '#comment', value => 'comment
(multiple lines)');
$cfg->append_new_node (type => '#comment', value => 'comment
(multiple lines)');
$cfg->append_new_node (type => '#element', local_name => 'foo', value => 'val');
$cfg->append_new_node (type => '#element', local_name => 'foo', value => 'value
with multiple
         lines');
$cfg->append_new_node (type => '#element', local_name => 'name with
multiple lines', value => 'val');
$cfg->append_new_node (type => '#element', local_name => 'foo', value => 'value
with multiple
@         lines
\ escaped
      ');

my $t = $cfg->append_new_node (type => '#element', local_name => 'name', value => 'val');
$t->append_new_node (type => '#element', local_name => 'foo', value => 'bar');
$t->append_new_node (type => '#element', local_name => 'foo', value => '0');
$t->append_new_node (type => '#element', local_name => '@', value => '@ foo');
$t->append_new_node (type => '#element', local_name => 'foo', value => 'something multi

 line');
$t->append_new_node (type => '#comment', value => 'comment');
my $tt = $t->append_new_node (type => '#element', local_name => 'foo', value => 'something\
 multi

 line');
$tt->append_new_node (type => '#element', local_name => 'foo', value => 'bar');
$tt->append_new_node (type => '#element', local_name => 'foo', value => '0');
$tt->append_new_node (type => '#element', local_name => '@', value => '@ foo');
$tt->append_new_node (type => '#element', local_name => 'foo', value => 'something\
 multi

 line');
$cfg->append_new_node (type => '#comment', value => '##COMMENT##');
$tt->append_new_node (type => '#element', local_name => 'foolist', value => [qw/foo bar #baz bar/]);

require Test::Simple;
my @s = split /\n/, $cfg->stringify;
my @t = split /\n/, q(foo:  aiueo
#comment
#(multiple lines)

#comment
#(multiple lines)
foo:  val
foo:
  value
  with multiple
  \         lines
name with
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

Test::Simple->import (tests => scalar @t);
for (0..($#t > $#s ? $#t : $#s)) {
  ok ($s[$_] eq $t[$_], "Line $_ : '$s[$_]' '$t[$_]'");
}
