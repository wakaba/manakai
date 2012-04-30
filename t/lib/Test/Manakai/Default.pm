package Test::Manakai::Default;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->parent->parent->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->parent->parent->parent->subdir ('modules', '*', 'lib')->stringify;
use Test::Manakai::Exceptions;
use Exporter::Lite;

push our @EXPORT, qw(dom_exception_ok);

1;
