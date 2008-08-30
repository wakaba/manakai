#!/usr/bin/perl
use strict;

use lib qw[/home/wakaba/work/manakai/lib];
## ISSUE: Message::URI::URIReference module.

use Test;
BEGIN { plan tests => 81 }

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
    errors => ['m::syntax error:iriref3987'],
  },
  {
    data => q<http://test/[53::0]>,
    errors => ['m::syntax error:iriref3987'],
  },
  {
    data => q<100%!>,
    errors => ['m::syntax error:iriref3987'],
  },
  {
    data => q<%a2>,
    errors => ['w:0.2:URL:lowercase hexadecimal digit'],
  },
  {
    data => q<%a2?>,
    errors => ['w:0.2:URL:lowercase hexadecimal digit'],
  },
  {
    data => q<?%a2>,
    errors => ['w:1.3:URL:lowercase hexadecimal digit'],
  },
  {
    data => q<%a2%1b>,
    errors => ['w:0.2:URL:lowercase hexadecimal digit',
               'w:3.5:URL:lowercase hexadecimal digit'],
  },
  {
    data => q<http://%5b/>,
    errors => ['w:7.9:URL:lowercase hexadecimal digit',
               'w::URL:non-DNS host'],
  },
  {
    data => q<http://%5b/%25a/bv/%cc>,
    errors => ['w:7.9:URL:lowercase hexadecimal digit',
               'w:19.21:URL:lowercase hexadecimal digit',
               'w::URL:non-DNS host'],
  },
  {
    data => q<%41>,
    errors => ['w:0.2:URL:percent-encoded unreserved'],
  },
  {
    data => q<%41%7E>,
    errors => ['w:0.2:URL:percent-encoded unreserved',
               'w:3.5:URL:percent-encoded unreserved'],
  },
  {
    data => q</%41>,
    errors => ['w:1.3:URL:percent-encoded unreserved'],
  },
  {
    data => q<http://%5a/>,
    errors => ['w:7.9:URL:lowercase hexadecimal digit',
               'w:7.9:URL:percent-encoded unreserved'],
  },
  {
    data => q<./%2E%2E>,
    errors => ['w:2.4:URL:percent-encoded unreserved',
               'w:5.7:URL:percent-encoded unreserved'],
  },
  {
    data => q<http://www.example.com/%7Euser/>,
    errors => ['w:23.25:URL:percent-encoded unreserved'],
  },
  {
    data => q<HTTP://example/>,
    errors => ['w::URL:uppercase scheme name'],
  },
  {
    data => q<Http://example/>,
    errors => ['w::URL:uppercase scheme name'],
  },
  {
    data => q<datA:,>,
    errors => ['w::URL:uppercase scheme name'],
  },
  {
    data => q<dat%41:,>,
    errors => ['m::syntax error:iriref3987',
               'w::URL:uppercase scheme name',
               'w:3.5:URL:percent-encoded unreserved'],
  },
  {
    data => q<g%5A:,>,
    errors => ['m::syntax error:iriref3987',
               'w::URL:uppercase scheme name',
               'w:1.3:URL:percent-encoded unreserved'],
  },
  {
    data => q<g%7A:,>,
    errors => ['m::syntax error:iriref3987',
               'w:1.3:URL:percent-encoded unreserved'],
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
    errors => ['w::URL:empty port'],
  },
  {
    data => q<http://www.test:/>,
    errors => ['w::URL:empty port'],
  },
  {
    data => q<http://user:password@example/>,
    errors => ['w::URL:password'],
  },
  {
    data => q<http://EXAMPLE/>,
    errors => ['w::URL:uppercase host'],
  },
  {
    data => q<http://USER@example/>,
    errors => [],
  },
  {
    data => q<http://[v0.aaa]/>,
    errors => ['w:1.2:URL:address format:v0'],
  },
  {
    data => q<http://user@[v0.aaa]/>,
    errors => ['w:1.2:URL:address format:v0'],
  },
  {
    data => q<http://user@[V0A.aaa]/>,
    errors => ['w:1.3:URL:address format:V0A',
               'w::URL:uppercase host'],
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
    errors => ['w::URL:non-DNS host'],
  },
  {
    data => q<http://123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123/>,
    errors => [],
  },
  {
    data => q<http://123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123./>,
    errors => ['w:256.256:URL:long host'],
  },
  {
    data => q<http://123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.456789/>,
    errors => ['w:256.262:URL:long host'],
  },
  {
    data => q<http://a_b.test/>,
    errors => ['w::URL:non-DNS host'],
  },
  {
    data => q<http://%61.test/>,
    errors => ['w:7.9:URL:percent-encoded unreserved'],
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
    errors => ['w::URL:non-DNS host'],
  },
  {
    data => q<http://-a.test/>,
    errors => ['w::URL:non-DNS host'],
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
  {
    data => qq<http://\x{123}\x{456}.test/>,
    errors => ['w::URL:non-DNS host'],
  },
  {
    data => qq<http://\x{4E00}%80.test/>,
    errors => ['w::URL:non-DNS host',
               'm::URL:non UTF-8 host'],
  },
  {
    data => q<http://a.%E3%81%82%E3%81%84.test/>,
    errors => ['w::URL:non-DNS host'],
  },
  {
    data => q<example://a/b/c/%7Bfoo%7D>,
    errors => [],
  },
  {
    data => q<eXAMPLE://a/./b/../b/%63/%7bfoo%7d>,
    errors => ['w::URL:uppercase scheme name',
               'w:21.23:URL:percent-encoded unreserved',
               'w:25.27:URL:lowercase hexadecimal digit',
               'w:31.33:URL:lowercase hexadecimal digit',
               'w::URL:dot-segment'],
  },
  {
    data => q<example://a/.htaccess>,
    errors => [],
  },
  {
    data => q<example://a/.>,
    errors => ['w::URL:dot-segment'],
  },
  {
    data => q<http://example.com>,
    errors => ['w::URL:empty path'],
  },
  {
    data => q<http://example.com/>,
    errors => [],
  },
  {
    data => q<http://example.com:/>,
    errors => ['w::URL:empty port'],
  },
  {
    data => q<http://example.com:80/>,
    errors => ['w::URL:default port'],
  },
  {
    data => q<hTTP://example.com:80/>,
    errors => ['w::URL:uppercase scheme name',
               'w::URL:default port'],
  },
  {
    data => q<%68ttp://example.com:80/>,
    errors => ['m::syntax error:iriref3987',
               'w:0.2:URL:percent-encoded unreserved',
               'w::URL:default port'],
  },
  {
    data => q<file://user@/>,
    errors => ['w::URL:empty host'],
  },
  {
    data => q<http://example.com/?>,
    errors => [],
  },
  {
    data => q<mailto:Joe@Example.COM>,
    errors => [],
  },
  {
    data => q<mailto:Joe@example.com>,
    errors => [],
  },
  {
    data => q<http://example.com/data>,
    errors => [],
  },
  {
    data => q<ftp://cnn.example.com&story=breaking_news@10.0.0.1/top_story.htm>,
    errors => [],
  },
  {
    data => qq<http://r\xE9sum\xE9.example.org>,
    errors => ['w::URL:non-DNS host',
               'w::URL:empty path'],
  },
  {
    data => qq<http://validator.w3.org/check?uri=http%3A%2F%2Fr\xE9;sum\xE9.example.com>,
    errors => [],
  },
  {
    data => q<http://validator.w3.org/check?uri=http%3A%2F%2Fr%C3%A9sum%C3%A9.example.com>,
    errors => [],
  },
  {
    data => qq<http://example.com/\x{10300}\x{10301}\x{10302}>,
    errors => [],
  },
  {
    data => q<http://example.com/%F0%90%8C%80%F0%90%8C%81%F0%90%8C%82>,
    errors => [],
  },
  {
    data => q<http://www.example.org/r%E9sum%E9.html>,
    errors => [],
  },
  {
    data => q<http://xn--99zt52a.example.org/%e2%80%ae>,
    errors => ['w:31.33:URL:lowercase hexadecimal digit',
               'w:37.39:URL:lowercase hexadecimal digit'],
  },
  {
    data => qq<example://a/b/c/%7Bfoo%7D/ros\xE9>,
    errors => [],
  },
  {
    data => qq<eXAMPLE://a/./b/../b/%63/%7bfoo%7d/ros%C3%A9>,
    errors => ['w::URL:uppercase scheme name',
               'w:21.23:URL:percent-encoded unreserved',
               'w:25.27:URL:lowercase hexadecimal digit',
               'w:31.33:URL:lowercase hexadecimal digit',
               'w::URL:dot-segment'],
  },
  {
    data => qq<http://www.example.org/..abc/>,
    errors => [],
  },
  {
    data => qq<http://www.example.org/../abc/>,
    errors => ['w::URL:dot-segment'],
  },
  {
    data => qq<http://www.example.org/r\xE9sum\xE9.html>,
    errors => [],
  },
  {
    data => qq<http://www.example.org/re\x{301}sume\x{301}.html>,
    errors => [], ## TODO: not in NFC
  },
  {
    data => q<http://www.example.org/r%E9sum%E9.xml#r%C3%A9sum%C3%A9>,
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
        (defined $opt{pos_start} ? $opt{pos_start} . '.' . $opt{pos_end} : '') . ':' . 
        $opt{type} .
        (defined $opt{text} ? ':' . $opt{text} : '');
  });
  @errors = sort {$a cmp $b} @errors;

  ok join ("\n", @errors), join ("\n", @{$test->{errors}}), $test->{data};
}
