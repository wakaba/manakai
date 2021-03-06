#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->stringify;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;

BEGIN {
  require 'content-checker.pl';
}

test_files (map { file (__FILE__)->dir->parent->file($_)->stringify } qw[
  t/dom-conformance/xml-1.dat
  t/dom-conformance/xml-global.dat
]);

done_testing;

## License: Public Domain.
