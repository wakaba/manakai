#!/usr/bin/perl -w 
use strict;

=head1 NAME

domtest.pl - Perl DOM Testing Library

=head1 DESCRIPTION

This library provides functions commonly used in DOM testing scripts. 
Most of them are named after the official ECMAScript test code. 

This library is part of manakai. 

=head1 FUNCTIONS

=cut

use Message::DOM::DOMLS qw/MODE_SYNCHRONOUS/;
use Message::DOM::ManakaiDOMLS2003;
use Getopt::Long;

our $REPORT = *STDOUT;
our $MSG = *STDOUT;

=item Global Variable $builder = {}

=cut

our $builder = {};
  $builder->{impl_attr} = {
    validating => "false",
    expandEntityReferences => "false",
    coalescing => "false",
    signed => "true",
    hasNullString => "true",
    ignoringElementContentWhitespace => "false",
    namespaceAware => "true",
    ignoringComments => "false",
    schemaValidating => "false",
  };

=item Global Variable $Info = {}

=cut

our $Info;

=item Global Variable @TestFileDir = []

Relative of absolute directory pathes to files loaded during the test. 
If there is an environmental variable C<MANAKAI_DOMTEST_FILE_DIR> 
defined, its value is psuhed into this array, split by character ":" or ";". 

=cut

our @TestFileDir = qw[
  files/
];
push @TestFileDir, split /[:;]/, $ENV{MANAKAI_DOMTEST_FILE_DIR}
  if defined $ENV{MANAKAI_DOMTEST_FILE_DIR};
my $Status = {Count => 0};

=item Command-line Option C<--test-file-directory=I<path-to-test>> (zero or more)

Adds a directory path to the array C<@TestFileDir>.

=cut

GetOptions (
  'test-file-directory=s' => \@TestFileDir,
);

=item $result = test_comment $msg

Formats a string for the user message output.  

=cut

sub test_comment ($) {
  my $s = shift;
  $s =~ s/\n/\n## /g;
  $s =~ s/\n## $/\n/s;
  $s .= "\n" unless $s =~ /\n$/;
  $s = q<## > . $s;
  $s;
}

=item $result = test_value $value

Formats a value for the output.  If the C<$value> is an array reference and 
its length is one, then its item is returned.  If the C<$value> is an 
C<undef> value, the string C<(undef)> is returned.  If defined but 
length is zero, the string C<(empty)> is returned.  Otherwise, 
quoted value is returned. 

ISSUE: Should value escaped in some way if the value has a quote character? 

=cut

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

=item is_ok

Outputs a success message. 

=cut

sub is_ok () {
  print $REPORT "ok ".++($Status->{Count})."\n";
}

=item is_not_ok id => I<identifier>, value => I<received value>, expected => I<expected value>

Outputs a failure message and exits the test. 

=cut

sub is_not_ok (%) {
  my %opt = @_;
  local $Error::Depth = $Error::Depth + 1;
  print $REPORT "not ok ".++($Status->{Count})." - $opt{id}\n";
  print $MSG test_comment 
      "Got ".test_value ($opt{value})." (expected: ".
      test_value ($opt{expected}) .")";
  $Status->{Failed}->{$opt{id}} = 1;
  skip_rest (not_ok => 1, msg => q<Untestable after failure>);
  exit;
}

=item skip_n ($n, %opt)

Skips I<n> tests. 

=cut

sub skip_n ($%) {
  my ($n, %opt) = @_;
  $opt{msg} = '' unless defined $opt{msg};
  for (1..$n) {
    print $REPORT qq<ok >.++($Status->{Count})." # Skip ".test_comment $opt{msg};
  }
} # skip_n

=item skip_rest (%opt)

Skips the rest of tests. 

Options:

=over 4

=item msg => I<text>

Briefly describes why test are skipped, if necessary.

=item not_ok => 1/0

Whether skipped because of failure of a test (C<1>) or of other reason (C<0>). 

=back

=cut

sub skip_rest (%) {
  my %opt = @_;
  my $n = $Status->{Number} - $Status->{Count};
  $opt{msg} = '' unless defined $opt{msg};
  if ($n > 0) {
    my $s = $opt{not_ok} ? 'not ok' : 'ok';
    for (my $i = $Status->{Count} + 1; $i <= $Status->{Number}; $i++) {
      print $REPORT "$s $i # Skip ".test_comment $opt{msg};
    }
    $Status->{Count} = $Status->{Number};
  } elsif (not $opt{not_ok}) {
    print $MSG test_comment "Skip: planned - count = $n\n";
    print $MSG test_comment $opt{msg};
  }
} # skip_rest

=item plan $n

Plans a test with the number of C<$n>.  Any more tests might be 
added later.

Note: This function must be called at the top of the test script.  
Once this is called, the script cannot call C<plan_local>. 

=cut

sub plan ($) {
  $Status->{Number} = shift;
  print $REPORT "1..".$Status->{Number}."\n";
}

=item plan_local ($n)

Plans C<$n> tests.  More number of tests might be added later. 

Note: This function can be called from anywhere in the test script 
as far as C<plan> is not called. 

=cut

sub plan_local ($) {
  my $n = shift;
  $Status->{Number} += $n;
  $Status->{Number_local} = 1;
} # plan_local

=item end_of_test

Declares that the test has exited. 

=cut

sub end_of_test () {
  if ($Status->{Number_local}) {
    print $REPORT "1..".$Status->{Number}."\n";
    $Status->{Number_local} = 0;
  }
  delete $Info->{__impl};
} # end_of_test

=item Special Function C<END>

Reports the result of the test for Perl's test manager and user
(developer). 

=cut

END {
  if ($Status->{Number_local}) {
    print $MSG test_comment "Looks like tests has stopped before the end";
    print $REPORT "1..".($Status->{Count}+1)."\n";
  }
  if ($Status->{Count} < $Status->{Number}) {
    print $MSG test_comment
                   sprintf "Looks like you planned %d tests but only ran %d.",
                           $Status->{Number}, $Status->{Count};
  } elsif ($Status->{Number} < $Status->{Count}) {
    print $MSG test_comment
                   sprintf "Looks like you planned %d tests but ran %d extra.",
                           $Status->{Number},
                           $Status->{Number} - $Status->{Count};
  }
  if (keys %{$Status->{Failed}}) {
    print $MSG test_comment $Info->{Name};
    print $MSG test_comment $Info->{Description};
    print $MSG test_comment sprintf "Looks like you failed %d tests of %d.",
                                      0 + keys %{$Status->{Failed}},
                                      $Status->{Number};
  } else {
    if ($Status->{Count} < $Status->{Number}) {
      print $MSG test_comment $Info->{Name};
      print $MSG test_comment $Info->{Description};
    }
    print $MSG test_comment 
                   sprintf "Looks like you passed %d tests.",
                           $Status->{Count};
  }
}

=item $doc = load ($name)

Loads a document and returns it. 

=cut

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

  ## TODO: select an implementation to test by argument
  my $dom = $Message::DOM::DOMImplementationRegistry
              ->get_dom_implementation
                  ({q<http://suika.fam.cx/~wakaba/archive/2004/9/27/mdom-old-ls#LS> => undef});
  $dom or die "$0: load: DOM implementation with LS not found";

  $Info->{__impl} = $dom;
  
  my $parser = $dom->create_ls_parser (MODE_SYNCHRONOUS);
  my $input = $dom->create_ls_input;
  {
    open my $f, '<', $file or die "$0: load: $file: $!";
    local $/ = undef;
    $input->string_data (<$f>);
    close $f;
  }
  return $parser->parse ($input);
}

=item impl_attr ($name, $value)

Ensures the DOM implementation has an implementation attribute 
with a value; otherwise, this test script is skipped. 

=cut

sub impl_attr ($$) {
  my ($name, $val) = @_;
  unless ($builder->{impl_attr}->{$name} eq $val) {
    skip_rest
      (msg => qq<implementation attribute "$name"="$val" does not match>);
  }
} # impl_attr

=item hasFeature ($feature, $version)

Ensures the DOM implementation has a feature; otherwise, 
this test script is skipped. 

=cut

sub hasFeature ($;$) {
  my ($name, $ver) = @_;
  unless ($Info->{__impl}->has_feature ($name, $ver)) {
    no warnings 'uninitialized';
    skip_rest (msg => qq<feature "$name"/"$ver" is not supported>);
  }
} # hasFeature

=item assertNull ($id, $value)

Asserts that the C<$value> is an C<undef> value. 

=cut

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

=item assertNotNull ($id, $value)

Asserts that the C<$value> is a non-C<undef> value. 

=cut

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

=item assertSize ($id, $size, $collection)

Asserts that the size of C<$collection> is equal to C<$size>. 

=cut

sub assertSize ($$$) {
  my ($id, $size, $coll) = @_;
  if (not defined $coll) {
    is_not_ok (id => $id,
               value => $coll,
               expected => ['non-null']);
  } elsif ($size == size ($coll)) {
    is_ok;
  } else {
    is_not_ok (id => $id,
               value => size ($coll),
               expected => $size);
  }
}

=item $size = size $collection

Returns the length of the collection. 

=cut

sub size ($) {
  my $coll = shift;
  $coll->length;
}

=item assertEquals ($id, $expected, $actual)

Asserts that the C<$actual> value is equal to the C<$expected> value. 

=cut

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

=item assertEqualsList ($id, $expected, $actual)

Asserts that the C<$expected> list is equal to the C<$actual> list. 

=cut

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
} # assertEqualsList

sub assertEqualsCollection ($$$) {
  my ($id, $ex, $ac) = @_;
  unless (ref $ex eq 'ARRAY') {
    die qq["@{[ref $ex]}": Unsupported expected collection type];
  }
  my $exl = @$ex;
  my $acl = $ac->length;
  if ($exl != $acl) {
    is_not_ok (id => $id,
               value => 'length = '.$acl,
               expected => 'length = '.$exl);
  }
  for my $exi (@$ex) {
    my $n = 0;
    for (my $i = 0; $i < $acl; $i++) {
      my $aci = $ac->item ($i);
      $n++ if $aci eq $exi;
    }
    if ($n != 1) {
      is_not_ok (id => $id,
                 value => 'n ('.$exi.') = '.$n,
                 expected => 'n = 1');
    }
  }
  is_ok;
} # assertEqualsCollection

=item assertTrue $id, $condition

Asserts that the C<$condition> is true. 

=cut

sub assertTrue ($$) {
  my ($id, $cond) = @_;
  if ($cond) {
    is_ok;
  } else {
    is_not_ok (id => $id, value => $cond, expected => 1);
  }
}

=item assertFalse $id, $condition

Asserts that the C<$condition> is false. 

=cut

sub assertFalse ($$) {
  my ($id, $cond) = @_;
  if ($cond) {
    is_not_ok (id => $id, value => $cond, expected => 0);
  } else {
    is_ok;
  }
}

=back

=head1 SEE ALSO

I<Document Object Model (DOM) Conformance Test Suites>,
<http://www.w3.org/DOM/Test/>.

F<bin/domtest2perl.pl>. 

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/10/06 10:53:39 $
