#!/usr/bin/perl
use strict;
use lib qw[/home/httpd/html/www/markup/html/whatpm
           /home/wakaba/work/manakai2/lib];
use CGI::Carp qw/fatalsToBrowser/;

use Message::CGI::HTTP;
my $http = Message::CGI::HTTP->new;

print STDOUT "Status: 404 Not Found\nContent-Type: text/plain; charset=us-ascii\n\n404" and exit
  unless $http->get_meta_variable ('PATH_INFO') eq '/';

use Whatpm::LangTag;
use Encode;
use encoding 'utf8', STDOUT => 'utf8';

print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

print "* RFC 4646\n\n";
print "#errors\n";

my $tag = $http->get_parameter ('t');
my $wf = 1;

my $parsed = Whatpm::LangTag->parse_rfc4646_langtag ($tag, sub {
  print join "\t", @_;
  print "\n";
  $wf = 0;
});

print "\n";
print "#parsed\n";

for my $n (keys %$parsed) {
  my $v = $parsed->{$n};
  if (defined $v) {
    if ($n eq 'extension') {
      if (@$v) {
        print qq[extension\n];
        for (@$v) {
          print qq[\t"];
          print join qq["\t"], @$_;
          print qq["\n];
        }
      }
    } elsif (ref $v) {
      if (@$v) {
        print qq[$n\n];
        for (@$v) {
          print qq[\t"$_"\n];
        }
      }
    } else {
      print qq[$n\t"$v"\n];
    }
  } else {
    print "$n\t(undef)\n";
  }
}

print "\n";

print "#validity\n";
my $validity = 1;

Whatpm::LangTag->check_rfc4646_langtag ($parsed, sub {
  my %opt = @_;
  print join "\t", %opt;
  print "\n";
  $validity = 0 unless {w => 1, i => 1}->{$opt{level}};
});

print "\n";

print "#result\n";
print "well-formed\t$wf\n";
print "valid\t$validity\n";

print "\n* RFC 3066\n\n";
my $rfc3066conforming = 1;

print "#errors\n";
Whatpm::LangTag->check_rfc3066_language_tag ($tag, sub {
  my %opt = @_;
  print join "\t", %opt;
  print "\n";
  if ($opt{level} eq 'f' or $opt{level} eq 'm') {
    $rfc3066conforming = 0;
  }
});

print "\n#result\n";
print "conforming\t$rfc3066conforming\n";

## License: Public Domain.
# $Date: 2008/09/18 14:33:35 $
