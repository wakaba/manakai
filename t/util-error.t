#!/usr/bin/perl
use strict;
use Message::Util::Error;
use Test;
plan tests => 25;

try {
  throw Message::Util::Error -type => 'SOMETHING_UNKNOWN';
} catch Message::Util::Error with {
  my $err = shift;
  warn $err->stringify if $^W;
  ok $err->text, qq("SOMETHING_UNKNOWN": Unknown error);
} except {
  ok 1, 0;
} otherwise {
  ok 1, 0;
} finally {
  ok 1, 1;
};
ok 1, 1;

try {
  throw test_error -type => 'ERR1', param1 => 'VAL1', param2 => 'VAL2';
} catch test_error with {
  my $err = shift;
  ok $err->text, qq(Param1 "VAL1"; Param2 "VAL2");
};

try {
  throw test_error -type => 'error_with_code';
} catch test_error with {
  my $err = shift;
  ok $err->code, 128, "error_with_code->code";
  ok $err->value, 128, "error_with_code->value";
  ok 0+$err->value, 128, "0+error_with_code";
  ok $err->text, "error", "error_with_code->text";
  ok $err->type, "error_with_code", "error_with_code->type";
  ok $err->subtype, undef, "error_with_code->subtype";
  ok $err->type_def->{-description}, "error", "error_with_code->type_def";
};

try {
  throw test_error -type => 'error_with_code', -subtype => 'suberror';
} catch test_error with {
  my $err = shift;
  ok $err->code, 128, "error_with_code->code";
  ok $err->value, 128, "error_with_code->value";
  ok 0+$err->value, 128, "0+error_with_code";
  ok $err->text, "suberror", "error_with_code->text";
  ok $err->type, "error_with_code", "error_with_code->type";
  ok $err->subtype, "suberror", "error_with_code->subtype";
  ok $err->type_def->{-description}, "error", "error_with_code->type_def";
};

package test_error;
BEGIN {
our @ISA = 'Message::Util::Error';
}
sub ___error_def () {+{
  ERR1 => {
    -description => q(Param1 "%t(name=>param1);"; Param2 "%t(name=>param2);"),
  },
  fatal => {
    -description => q(fatal error),
  },
  warn => {
    -description => q(warn msg),
  },
  error_with_code => {
    -code => 128,
    -description => q(error),
    -subtype => {
      suberror => {
        -description => q(suberror),
        -code => 100,
      },
    },
  },
}}

package test_report;
BEGIN {
our @ISA = 'test_error';
}

package test_pack1;
#line 1 "pack1"

sub t {
  throw test_error -type => 'ERR1', param1 => 1, param2 => 2;
}
sub r {
  report test_error -type => 'ERR1', param1 => 1, param2 => 2;
}

sub rw {
  report test_error -type => 'warn', -object => bless {};
}
sub rf {
  report test_error -type => 'fatal', -object => bless {};
}

sub ___report_error ($$;%) {
  my ($pack1, $err, %opt) = @_;
#  if ($err->{-type} eq 'fatal') {
    $err->throw;
#  } else {
#    
#  }
}

package test_pack2;
#line 1 "pack2"

sub t {
  local $Error::Depth = $Error::Depth + 1;
  throw test_error -type => 'ERR1', param1 => 1, param2 => 2;
}
sub r {
  local $Error::Depth = $Error::Depth + 1;
  report test_error -type => 'ERR1', param1 => 1, param2 => 2;
}

package test_pack3;
#line 1 "pack3"
push our @ISA, 'test_pack1';

sub t {
  local $Error::Depth = $Error::Depth + 1;
  shift->SUPER::t (@_);
}
sub r {
  local $Error::Depth = $Error::Depth + 1;
  shift->SUPER::r (@_);
}

sub rf {
  local $Error::Depth = $Error::Depth + 1;
  shift->SUPER::rf (@_);
}

package main;
#line 1 "main"

try {
  test_pack1->t;
} catch test_error with {
  my $err = shift;
  ok $err->file, "pack1";
};

try {
  test_pack1->r;
} catch test_error with {
  my $err = shift;
  ok $err->file, "main";
};

try {
  test_pack2->t;
} catch test_error with {
  my $err = shift;
  ok $err->file, "main";
};

try {
  test_pack3->t;
} catch test_error with {
  my $err = shift;
  ok $err->file, "pack3";
};

try {
  test_pack3->r;
} catch test_error with {
  my $err = shift;
  ok $err->file, "main";
};


try {
  test_pack1->rf;
} catch test_error with {
  my $err = shift;
  ok $err->file, "main";
};

try {
  test_pack3->rf;
} catch test_error with {
  my $err = shift;
  ok $err->file, "main";
};

=head1 LICENSE

Copyright 2003-2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2007/06/16 05:30:37 $
