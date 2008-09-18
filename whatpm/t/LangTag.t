#!/usr/bin/perl
use strict;

BEGIN {
  require 't/content-checker.pl';
  plan (tests => 2646);
}

test_files (qw[
  t/langtag-1.dat
]);

## License: Public Domain.
## $Date: 2008/09/18 05:49:13 $
