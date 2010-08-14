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

print STDERR "Parsing...";
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
    $err{node} = $err{node}->local_name || $err{node}->node_name;
  }
  printf STDOUT "%s[%d.%d]: %s, %s\n",
      $level, $line, $column, $type,
      join ' ', %err;
});
