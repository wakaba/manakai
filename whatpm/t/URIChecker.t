#!/usr/bin/perl
use strict;

use lib qw[/home/wakaba/work/manakai/lib];
## ISSUE: Message::URI::URIReference module.

use Test;
BEGIN { plan tests => 49 }

my $Cases = [
  {
    data => q<http://localhost/%40/>,
    errors => [],
  },
  {
    data => q<>,
    errors => [],
  },
  {
    data => q<abcdef>,
    errors => [],
  },
  {
    data => q<%7Fabc:efg>,
    errors => ['m::syntax error'],
  },
  {
    data => q<http://test/[53::0]>,
    errors => ['m::syntax error'],
  },
  {
    data => q<100%!>,
    errors => ['m::syntax error'],
  },
  {
    data => q<%a2>,
    errors => ['s:1:lowercase hexadecimal digit'],
  },
  {
    data => q<%a2?>,
    errors => ['s:1:lowercase hexadecimal digit'],
  },
  {
    data => q<?%a2>,
    errors => ['s:2:lowercase hexadecimal digit'],
  },
  {
    data => q<%a2%1b>,
    errors => ['s:1:lowercase hexadecimal digit',
               's:4:lowercase hexadecimal digit'],
  },
  {
    data => q<http://%5b/>,
    errors => ['s:8:lowercase hexadecimal digit',
               's::non-DNS host'],
  },
  {
    data => q<http://%5b/%25a/bv/%cc>,
    errors => ['s:8:lowercase hexadecimal digit',
               's:20:lowercase hexadecimal digit',
               's::non-DNS host'],
  },
  {
    data => q<%41>,
    errors => ['s:1:percent-encoded unreserved'],
  },
  {
    data => q<%41%7E>,
    errors => ['s:1:percent-encoded unreserved',
               's:4:percent-encoded unreserved'],
  },
  {
    data => q</%41>,
    errors => ['s:2:percent-encoded unreserved'],
  },
  {
    data => q<http://%5a/>,
    errors => ['s:8:lowercase hexadecimal digit',
               's:8:percent-encoded unreserved'],
  },
  {
    data => q<./%2E%2E>,
    errors => ['s:3:percent-encoded unreserved',
               's:6:percent-encoded unreserved'],
  },
  {
    data => q<http://www.example.com/%7Euser/>,
    errors => ['s:24:percent-encoded unreserved'],
  },
  {
    data => q<HTTP://example/>,
    errors => ['s:1:uppercase scheme name'],
  },
  {
    data => q<Http://example/>,
    errors => ['s:1:uppercase scheme name'],
  },
  {
    data => q<datA:,>,
    errors => ['s:1:uppercase scheme name'],
  },
  {
    data => q<dat%41:,>,
    errors => ['m::syntax error',
               's:4:percent-encoded unreserved'],
  },
  {
    data => q<g%5A:,>,
    errors => ['m::syntax error',
               's:2:percent-encoded unreserved'],
  },
  {
    data => q<g%7A:,>,
    errors => ['m::syntax error',
               's:2:percent-encoded unreserved'],
  },
  {
    data => q<http://www.test:2222/>,
    errors => [],
  },
  {
    data => q<http://www.example:0/>,
    errors => [],
  },
  {
    data => q<http://www@example:/>,
    errors => ['s::empty port'],
  },
  {
    data => q<http://www.test:/>,
    errors => ['s::empty port'],
  },
  {
    data => q<http://user:password@example/>,
    errors => ['s::password'],
  },
  {
    data => q<http://EXAMPLE/>,
    errors => ['s::uppercase host'],
  },
  {
    data => q<http://USER@example/>,
    errors => [],
  },
  {
    data => q<http://[v0.aaa]/>,
    errors => ['w::address format not supported:v0'],
  },
  {
    data => q<http://user@[v0.aaa]/>,
    errors => ['w::address format not supported:v0'],
  },
  {
    data => q<http://127.0.0.1/>,
    errors => [],
  },
  {
    data => q<http://123456789012345678901234567890123456789012345678901234567890123.test/>,
    errors => [],
  },
  {
    data => q<http://1234567890123456789012345678901234567890123456789012345678901234.test/>,
    errors => ['s::non-DNS host'],
  },
  {
    data => q<http://123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123/>,
    errors => [],
  },
  {
    data => q<http://123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123./>,
    errors => ['s::long host'],
  },
  {
    data => q<http://a_b.test/>,
    errors => ['s::non-DNS host'],
  },
  {
    data => q<http://%61.test/>,
    errors => ['s:8:percent-encoded unreserved'],
  },
  {
    data => q<http://a.test/>,
    errors => [],
  },
  {
    data => q<http://1.test/>,
    errors => [],
  },
  {
    data => q<http://a-1.test/>,
    errors => [],
  },
  {
    data => q<http://1-a.test/>,
    errors => [],
  },
  {
    data => q<http://a-.test/>,
    errors => ['s::non-DNS host'],
  },
  {
    data => q<http://-a.test/>,
    errors => ['s::non-DNS host'],
  },
  {
    data => q<http://a.b.test/>,
    errors => [],
  },
  {
    data => q<http://a.bc.test/>,
    errors => [],
  },
  {
    data => q<http://a.b-c.test/>,
    errors => [],
  },
];

require Whatpm::URIChecker;

for my $test (@$Cases) {
  @{$test->{errors}} = sort {$a cmp $b} @{$test->{errors}};
  my @errors;
  Whatpm::URIChecker->check_iri_reference ($test->{data}, sub {
    my %opt = @_;
    push @errors, $opt{level} . ':' .
        (defined $opt{position} ? $opt{position} : '') . ':' . 
        $opt{type};
  });
  @errors = sort {$a cmp $b} @errors;

  ok join ("\n", @errors), join ("\n", @{$test->{errors}}), $test->{data};
}
