#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;

BEGIN {
  require 't/content-checker.pl';
  plan (tests => 2646);
}

test_files (qw[
  t/content-model-atom-1.dat
  t/content-model-atom-2.dat
  t/content-model-atom-threading-1.dat
]);

## License: Public Domain.
## $Date: 2008/09/18 05:49:13 $
