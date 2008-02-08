#!/usr/bin/perl
use strict;

## Test for Whatpm::CSS::MediaQueryParser and Whatpm::CSS::MediaQuerySerializer

use Test;

BEGIN { plan tests => 28 }

require Whatpm::CSS::MediaQueryParser;
require Whatpm::CSS::MediaQuerySerializer;

for my $file_name (map {"t/$_"} qw(
  mq-1.dat
)) {
  print "# $file_name\n";
  open my $file, '<:utf8', $file_name or die "$0: $file_name: $!";

  my $all_test = {test => []};
  my $test;
  my $mode = 'data';
  my $doc_id;
  my $selectors;
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      push @{$all_test->{test}}, $test;
      $mode = 'data';
    } elsif (/#mediatext$/) {
      $test->{mediatext} = '';
      $mode = 'mediatext';
    } elsif (/^#errors$/) {
      $test->{errors} = [];
      $mode = 'errors';
      $test->{data} =~ s/\x0D?\x0A\z//;
    } elsif (defined $test->{data} and /^$/) {
      undef $test;
    } else {
      if ({data => 1, mediatext => 1}->{$mode}) {
        $test->{$mode} .= $_;
      } elsif ($mode eq 'errors') {
        tr/\x0D\x0A//d;
        push @{$test->{errors}}, $_;
      } else {
        die "Line $.: $_";
      }
    }
  }

  my $p = Whatpm::CSS::MediaQueryParser->new;
  for my $test (@{$all_test->{test}}) {
    my @actual_error;
    $p->{onerror} = sub {
      my (%opt) = @_;
      my $uri = ${$opt{uri}};
      $uri =~ s[^thismessage:/][];
      push @actual_error, join ';',
          $uri, $opt{token}->{line}, $opt{token}->{column},
          $opt{level},
          $opt{type} . (defined $opt{value} ? ';'.$opt{value} : '');
    };

    my $mq = $p->parse_char_string ($test->{data});

    ok ((join "\n", @actual_error), (join "\n", @{$test->{errors} or []}),
        "#result ($test->{data})");

    if (defined $test->{mediatext}) {
      my $mt = Whatpm::CSS::MediaQuerySerializer->serialize_media_query ($mq);
      ok $mt."\n", $test->{mediatext}, "#mediatext ($test->{data})";
    }
  }
}
