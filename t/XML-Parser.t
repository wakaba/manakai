package test::Whatpm::XML::Parser;
use strict;
use warnings;
no warnings 'utf8';
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->parent->subdir ('modules', 'testdataparser', 'lib')->stringify;
use Test::More;
use Test::Differences;
use Test::HTCT::Parser;
use Encode;
sub bytes ($) { encode 'utf8', $_[0] }
my $DEBUG = $ENV{DEBUG};

my $test_dir_name = 't/xml/';

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

use Whatpm::XML::Parser;
use Whatpm::NanoDOM;
use Whatpm::Charset::UnicodeChecker;
use Whatpm::HTML::Dumper qw/dumptree/;

my $dom;
if ($ENV{USE_REAL_DOM}) {
  require Message::DOM::DOMImplementation;
  $dom = Message::DOM::DOMImplementation->new;
}

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

  my $doc = $dom ? $dom->create_document : Whatpm::NanoDOM::Document->new;
  my @errors;
  
  $SIG{INT} = sub {
    print scalar dumptree ($doc);
    exit;
  };

  my $onerror = sub {
    my %opt = @_;
    push @errors, join ';',
        $opt{token}->{line} || $opt{line},
        $opt{token}->{column} || $opt{column},
        $opt{type},
        defined $opt{text} ? $opt{text} : '',
        defined $opt{value} ? $opt{value} : '',
        $opt{level};
  };

  my $chk = sub {
    return $_[0];
    #return Whatpm::Charset::UnicodeChecker->new_handle ($_[0], 'html5');
  }; # $chk

  my $p = Whatpm::XML::Parser->new;
  my $result;
  unless (defined $test->{element}) {
    $p->parse_char_string ($test->{data}->[0] => $doc, $onerror, $chk);
    $result = dumptree ($doc);
  } else {
    ## TODO: ...
    my $el = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, $test->{element}]);
    Whatpm::HTML->set_inner_html ($el, $test->{data}->[0], $onerror, $chk);
    $result = dumptree ($el);
  }
  
  warn "No #errors section ($test->{data}->[0])" unless $test->{errors};

  @errors = sort {$a cmp $b} @errors;
  @{$test->{errors}->[0]} = sort {$a cmp $b} @{$test->{errors}->[0] ||= []};
  
  eq_or_diff join ("\n", @errors), join ("\n", @{$test->{errors}->[0] or []}),
      bytes 'Parse error: ' . Data::Dumper::qquote ($test->{data}->[0]);

  if ($test->{'xml-version'}) {
    is $doc->xml_version, $test->{'xml-version'}->[0],
        bytes 'XML version: ' . Data::Dumper::qquote ($test->{data}->[0]);
  }

  if ($test->{'xml-encoding'}) {
    if (($test->{'xml-encoding'}->[1]->[0] || '') eq 'null') {
      is $doc->xml_encoding, undef, 
          bytes 'XML encoding: ' . Data::Dumper::qquote ($test->{data}->[0]);
    } else {
      is $doc->xml_encoding, $test->{'xml-encoding'}->[0],
          bytes 'XML encoding: ' . Data::Dumper::qquote ($test->{data}->[0]);
    }
  }

  if ($test->{'xml-standalone'}) {
    is $doc->xml_standalone ? 1 : 0,
        $test->{'xml-standalone'}->[1]->[0] eq 'true' ? 1 : 0,
        bytes 'XML standalone: ' . Data::Dumper::qquote ($test->{data}->[0]);
  }

  if ($test->{entities}) {
    my @e;
    for (keys %{$p->{ge}}) {
      my $ent = $p->{ge}->{$_};
      my $v = '<!ENTITY ' . $ent->{name} . ' "'; 
      $v .= $ent->{value} if defined $ent->{value};
      $v .= '" "';
      $v .= $ent->{pubid} if defined $ent->{pubid};
      $v .= '" "';
      $v .= $ent->{sysid} if defined $ent->{sysid};
      $v .= '" ';
      $v .= $ent->{notation} if defined $ent->{notation};
      $v .= '>';
      push @e, $v;
    }
    for (keys %{$p->{pe}}) {
      my $ent = $p->{pe}->{$_};
      my $v = '<!ENTITY % ' . $ent->{name} . ' "'; 
      $v .= $ent->{value} if defined $ent->{value};
      $v .= '" "';
      $v .= $ent->{pubid} if defined $ent->{pubid};
      $v .= '" "';
      $v .= $ent->{sysid} if defined $ent->{sysid};
      $v .= '" ';
      $v .= $ent->{notation} if defined $ent->{notation};
      $v .= '>';
      push @e, $v;
    }
    eq_or_diff join ("\x0A", @e), $test->{entities}->[0],
        bytes 'Entities: ' . Data::Dumper::qquote ($test->{data}->[0]);
  }
  
  $test->{document}->[0] .= "\x0A" if length $test->{document}->[0];
  eq_or_diff $result, $test->{document}->[0],
      bytes 'Document tree: ' . Data::Dumper::qquote ($test->{data}->[0]);
} # test

my @FILES = grep {$_} split /\s+/, qq[
  ${test_dir_name}elements-1.dat
  ${test_dir_name}attrs-1.dat
  ${test_dir_name}attrs-2.dat
  ${test_dir_name}texts-1.dat
  ${test_dir_name}cdata-1.dat
  ${test_dir_name}charref-1.dat
  ${test_dir_name}comments-1.dat
  ${test_dir_name}comments-2.dat
  ${test_dir_name}pis-1.dat
  ${test_dir_name}pis-2.dat
  ${test_dir_name}xmldecls-1.dat
  ${test_dir_name}tree-1.dat
  ${test_dir_name}ns-elements-1.dat
  ${test_dir_name}ns-attrs-1.dat
  ${test_dir_name}doctypes-1.dat
  ${test_dir_name}doctypes-2.dat
  ${test_dir_name}eldecls-1.dat
  ${test_dir_name}attlists-1.dat
  ${test_dir_name}entities-1.dat
  ${test_dir_name}entities-2.dat
  ${test_dir_name}notations-1.dat
  ${test_dir_name}entrefs-1.dat
  ${test_dir_name}entrefs-2.dat
];

for_each_test ($_, {
  errors => {is_list => 1},
  document => {is_prefixed => 1},
  'document-fragment' => {is_prefixed => 1},
  entities => {is_prefixed => 1},
}, \&test) for @FILES;

done_testing;
## License: Public Domain.
