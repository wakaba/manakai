#!/usr/bin/perl
use strict;
use Message::Util::Error;
use Test::Simple tests => 4;
sub OK ($$) {
  my ($result, $expect) = @_;
  if ($result eq $expect) {
    ok 1;
  } else {
    ok 0, qq("$result" : "$expect" expected);
  }
}

try {
  throw Message::Util::Error -type => 'SOMETHING_UNKNOWN';
} catch Message::Util::Error with {
  my $err = shift;
  warn $err->stringify if $^W;
  OK $err->text, qq("SOMETHING_UNKNOWN": Unknown error);
} except {
  OK 1, 0;
} otherwise {
  OK 1, 0;
} finally {
  OK 1, 1;
};
OK 1, 1;

try {
  throw test_error -type => 'ERR1', param1 => 'VAL1', param2 => 'VAL2';
} catch test_error with {
  my $err = shift;
  OK $err->text, qq(Param1 "VAL1"; Param2 "VAL2");
};

package test_error;
BEGIN {
our @ISA = 'Message::Util::Error';
}
sub ___error_def () {+{
  ERR1 => {
    description => q(Param1 "%t(name=>param1);"; Param2 "%t(name=>param2);"),
  },
}}


