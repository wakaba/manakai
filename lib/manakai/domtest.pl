#!/usr/bin/perl -w 
use strict;

use Message::DOM::DOMCore;
use Message::DOM::DOMXML;
use Message::DOM::ManakaiDOMLS2003;
use Getopt::Long;

our $builder = {};
our $Info;

our @TestFileDir = qw[
  files/
];
push @TestFileDir, split /[:;]/, $ENV{MANAKAI_DOMTEST_FILE_DIR}
  if defined $ENV{MANAKAI_DOMTEST_FILE_DIR};
my $Status = {Count => 0};

GetOptions (
  'test-file-directory=s' => \@TestFileDir,
);

sub test_comment ($) {
  my $s = shift;
  $s =~ s/\n/\n## /g;
  $s =~ s/\n## $/\n/s;
  $s .= "\n" unless $s =~ /\n$/;
  $s = q<## > . $s;
  $s;
}

sub test_value ($) {
  my $s = shift;
  if (defined $s) {
    if (ref $s eq 'ARRAY' and @$s == 1) {
      $s->[0];
    } elsif (length $s) {
      qq<"$s">;
    } else {
      qq<(empty)>;
    }
  } else {
    qq<(undef)>;
  }
}

sub is_ok () {
  print STDOUT "ok ".++($Status->{Count})."\n";
}

sub is_not_ok (%) {
  my %opt = @_;
  local $Error::Depth = $Error::Depth + 1;
  print STDOUT "not ok ".++($Status->{Count})." - $opt{id}\n";
  print STDERR test_comment 
      "Got ".test_value ($opt{value})." (expected: ".
      test_value ($opt{expected}) .")";
  $Status->{Failed}->{$opt{id}} = 1;
  exit;
}

sub plan ($) {
  $Status->{Number} = shift;
  print STDOUT "1..".$Status->{Number}."\n";
}

END {
  if ($Status->{Count} < $Status->{Number}) {
    print STDERR test_comment
                   sprintf "Looks like you planned %d tests but only ran %d.",
                           $Status->{Number}, $Status->{Count};
  } elsif ($Status->{Number} < $Status->{Count}) {
    print STDERR test_comment
                   sprintf "Looks like you planned %d tests but ran %d extra.",
                           $Status->{Number},
                           $Status->{Number} - $Status->{Count};
  }
  if (keys %{$Status->{Failed}}) {
    print STDERR test_comment $Info->{Name};
    print STDERR test_comment $Info->{Description};
    print STDERR test_comment sprintf "Looks like you failed %d tests of %d.",
                                      0 + keys %{$Status->{Failed}},
                                      $Status->{Number};
  } else {
    if ($Status->{Count} < $Status->{Number}) {
      print STDERR test_comment $Info->{Name};
      print STDERR test_comment $Info->{Description};
    }
    print STDERR test_comment 
                   sprintf "Looks like you passed %d tests.",
                           $Status->{Count};
  }
}



sub load ($) {
  my $name = shift;
  my $file;
  for (@TestFileDir) {
    if (-e $_ . $name . '.xml') {
      $file = $_ . $name . '.xml';
      $builder->{contentType} = 'application/xml';
      last;
    }
  }
  $file or die "$0: load: $name: File not found";
  my $dom = Message::DOM::DOMImplementationRegistry
              ->getDOMImplementation
                  ({q<http://suika.fam.cx/~wakaba/archive/2004/9/27/mdom-old-ls#LS> => undef});
  $dom or die "$0: load: DOM implementation with LS not found";
  my $parser = $dom->createLSParser
                      (Message::DOM::DOMImplementationLS->MODE_SYNCHRONOUS);
  my $input = $dom->createLSInput;
  {
    open my $f, '<', $file or die "$0: load: $file: $!";
    local $/ = undef;
    $input->stringData (<$f>);
    close $f;
  }
  return $parser->parse ($input);
}

sub assertNull ($$) {
  my ($id, $val) = @_;
  if (defined $val) {
    is_not_ok (id => $id,
               value => $val,
               expected => undef);
  } else {
    is_ok;
  }
}

sub assertNotNull ($$) {
  my ($id, $val) = @_;
  if (defined $val) {
    is_ok;
  } else {
    is_not_ok (id => $id,
               value => $val,
               expected => ['non-null']);
  }
}

sub assertSize ($$$) {
  my ($id, $size, $coll) = @_;
  if ($size == size ($coll)) {
    is_ok;
  } else {
    is_not_ok (id => $id,
               value => size ($coll),
               expected => $size);
  }
}

sub size ($) {
  my $coll = shift;
  $coll->length;
}

sub assertEquals ($$$) {
  my ($id, $expected, $actual) = @_;
  if (defined $expected and
      defined $actual and
      $expected eq $actual) {
    is_ok;
  } elsif (not defined $expected and
           not defined $actual) {
    is_ok;
  } else {
    is_not_ok (id => $id,
               value => $actual,
               expected => $expected);
  }
}

sub assertEqualsList ($$$) {
  my ($id, $expected, $actual) = @_;
  if (@$expected == @$actual) {
    for (0..$#$expected) {
      if (defined $expected->[$_] and
          defined $actual->[$_] and
          $expected->[$_] eq $actual->[$_]) {
        #
      } elsif (not defined $expected->[$_] and
               not defined $actual->[$_]) {
        #
      } else {
        is_not_ok (id => $id,
                   value => $actual->[$_],
                   expected => $expected->[$_]);
        return;
      }
    }
    is_ok;
  } else {
    is_not_ok (id => $id, value => 'length = '.@$actual,
               expected => 'length = '.@$expected);
  }
}

sub assertTrue ($$) {
  my ($id, $cond) = @_;
  if ($cond) {
    is_ok;
  } else {
    is_not_ok (id => $id, value => $cond, expected => 1);
  }
}

sub assertFalse ($$) {
  my ($id, $cond) = @_;
  if ($cond) {
    is_not_ok (id => $id, value => $cond, expected => 0);
  } else {
    is_ok;
  }
}

1;
