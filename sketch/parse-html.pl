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

$doc->inner_html ($input);

use Whatpm::HTML::Dumper qw/dumptree/;
print dumptree $doc;
