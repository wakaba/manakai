#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->subdir ('modules/*/lib');

my $input = shift;

use Message::DOM::DOMImplementation;
my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;
$doc->manakai_is_html (1);

print STDERR "Parsing...\n";
$doc->inner_html ($input);
print STDERR "\n";

use Whatpm::ContentChecker;
print STDERR "Checking...\n";
Whatpm::ContentChecker->check_document ($doc, sub {
  my %err = @_;
  my $line = delete $err{line} || 0;
  my $column = delete $err{column} || 0;
  my $level = delete $err{level} || '?';
  my $type = delete $err{type} || '';
  if ($err{node}) {
    $line ||= $err{node}->get_user_data ('manakai_source_line');
    $column ||= $err{node}->get_user_data ('manakai_source_column');
    $err{node} = $err{node}->local_name || $err{node}->node_name;
  }
  printf STDOUT "Line %d Column %d (%s): %s, %s\n",
      $line, $column, $level, $type,
      join ', ', map { $_ . '=' . $err{$_} } keys %err;
});
