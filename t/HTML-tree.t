package test::Whatpm::HTML::Parser::tree;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;
use Test::Differences;
use Encode;
sub bytes ($) { encode 'utf8', $_[0] }
my $DEBUG = $ENV{DEBUG};

my $test_dir_name = 't/';
my $dir_name = 't/tree-construction/';

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  eval {
    ## Perl 5.8.8/5.10.1 in some environment does not handle utf8
    ## string with surrogate code points well (it breaks the string
    ## when it is passed to another subroutine even when it can be
    ## accessible only via traversing reference chain, very
    ## strange...), so |eval| this statement.  It would not change the
    ## test result as long as our parser implementation passes the
    ## tests.
    $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
    1;
  } or warn $@;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

if ($DEBUG) {
  my $not_found = {%{$Whatpm::HTML::Debug::cp or {}}};
  $Whatpm::HTML::Debug::cp_pass = sub {
    my $id = shift;
    delete $not_found->{$id};
  };

  END {
    for my $id (sort {$a <=> $b || $a cmp $b} keys %$not_found) {
      print "# checkpoint $id is not reached\n";
    }
  }
}

use Whatpm::HTML;
use Whatpm::NanoDOM;
use Whatpm::Charset::UnicodeChecker;
use Whatpm::HTML::Dumper qw/dumptree/;

sub test ($) {
  my $test = shift;
  my $data = $test->{data}->[0];

  if ($test->{skip}->[1]->[0]) {
#line 1 "HTML-tree.t test () skip"
    SKIP: {
      skip "", 1;
    }
    return;
  }

  if ($test->{'document-fragment'}) {
    if (@{$test->{'document-fragment'}->[1]}) {
      ## NOTE: Old format.
      $test->{element} = $test->{'document-fragment'}->[1]->[0];
      $test->{document} ||= $test->{'document-fragment'};
    } else {
      ## NOTE: New format.
      $test->{element} = $test->{'document-fragment'}->[0];
    }
  }

  my $doc = Whatpm::NanoDOM::Document->new;
  my @errors;
  my @shoulds;
  
  $SIG{INT} = sub {
    print scalar dumptree ($doc);
    exit;
  };

  if ($test->{issrcdoc}->[1]) {
    $doc->manakai_is_srcdoc (1);
  }

  my $onerror = sub {
    my %opt = @_;
    if ($opt{level} eq 's') {
      push @shoulds, join ':', $opt{line}, $opt{column}, $opt{type};
    } else {
      push @errors, join ':', $opt{line}, $opt{column}, $opt{type};
    }
  };

  my $chk = sub {
    return Whatpm::Charset::UnicodeChecker->new_handle ($_[0], 'html5');
  }; # $chk

  my $result;
  unless (defined $test->{element}) {
    Whatpm::HTML->parse_char_string
        ($test->{data}->[0] => $doc, $onerror, $chk);
    $result = dumptree ($doc);
  } else {
    my $el;
    if ($test->{element} =~ s/^svg\s*//) {
      $el = $doc->create_element_ns
          (q<http://www.w3.org/2000/svg>, [undef, $test->{element}]);
    } elsif ($test->{element} =~ s/^math\s*//) {
      $el = $doc->create_element_ns
          (q<http://www.w3.org/1998/Math/MathML>, [undef, $test->{element}]);
    } elsif ($test->{element} =~ s/^\{([^{}]*)\}\s*//) {
      $el = $doc->create_element_ns ($1, [undef, $test->{element}]);
    } else {
      $el = $doc->create_element_ns
          (q<http://www.w3.org/1999/xhtml>, [undef, $test->{element}]);
    }
    Whatpm::HTML->set_inner_html ($el, $test->{data}->[0], $onerror, $chk);
    $result = dumptree ($el);
  }
  
  warn "No #errors section ($test->{data}->[0])" unless $test->{errors};
    
#line 1 "HTML-tree.t test () ok"
  is scalar @errors, scalar @{$test->{errors}->[0] or []}, bytes
    'Parse error: ' . Data::Dumper::qquote ($test->{data}->[0]) . '; ' . 
    join (', ', @errors) . ';' . join (', ', @{$test->{errors}->[0] or []});
  is scalar @shoulds, scalar @{$test->{shoulds}->[0] or []}, bytes
    'SHOULD-level error: ' . Data::Dumper::qquote ($test->{data}->[0]) . '; ' .
    join (', ', @shoulds) . ';' . join (', ', @{$test->{shoulds}->[0] or []});

  $test->{document}->[0] .= "\x0A" if length $test->{document}->[0];
  eq_or_diff $result, $test->{document}->[0], bytes
      'Document tree: ' . Data::Dumper::qquote ($test->{data}->[0]);
} # test

my @FILES = grep {$_} split /\s+/, qq[
                      ${test_dir_name}tokenizer-test-chars.dat
                      ${test_dir_name}tokenizer-test-2.dat
                      ${test_dir_name}tokenizer-test-3.dat
                      ${test_dir_name}tokenizer-test-cdata.dat
                      ${dir_name}tests1.dat
                      ${dir_name}tests2.dat
                      ${dir_name}tests3.dat
                      ${dir_name}tests4.dat
                      ${dir_name}tests5.dat
                      ${dir_name}tests6.dat
                      ${dir_name}tests7.dat
                      ${dir_name}tests8.dat
                      ${dir_name}tests9.dat
                      ${dir_name}tests10.dat
                      ${dir_name}tests11.dat
                      ${dir_name}tests12.dat
                      ${test_dir_name}tree-test-1.dat
                      ${test_dir_name}tree-test-2.dat
                      ${test_dir_name}tree-test-3.dat
                      ${test_dir_name}tree-test-struct.dat
                      ${test_dir_name}tree-test-void.dat
                      ${test_dir_name}tree-test-flow.dat
                      ${test_dir_name}tree-test-tables.dat
                      ${test_dir_name}tree-test-phrasing.dat
                      ${test_dir_name}tree-test-form.dat
                      ${test_dir_name}tree-test-frames.dat
                      ${test_dir_name}tree-test-foreign.dat
                     ];

require 't/testfiles.pl';
execute_test ($_, {
  errors => {is_list => 1},
  shoulds => {is_list => 1},
  document => {is_prefixed => 1},
  'document-fragment' => {is_prefixed => 1},
}, \&test) for @FILES;

done_testing;
## License: Public Domain.
