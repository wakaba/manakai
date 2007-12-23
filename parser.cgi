#!/usr/bin/perl
use strict;

use lib qw[/home/httpd/html/www/markup/html/whatpm
           /home/wakaba/work/manakai2/lib];
use CGI::Carp qw[fatalsToBrowser];

use Message::CGI::HTTP;
my $http = Message::CGI::HTTP->new;

## TODO: _charset_

my $mode = $http->get_meta_variable ('PATH_INFO');
## TODO: decode unreserved characters

if ($mode eq '/csstext') {
  require Encode;
  require Whatpm::CSS::Parser;

  my $s = $http->get_parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  print STDOUT "#errors\n";

  my $parser = Whatpm::CSS::Parser->new;
  $parser->{onerror} = sub {
    my (%opt) = @_;
    print STDOUT "$opt{line},$opt{column},$opt{level},$opt{type}\n";
  };
  
  my $ss = $parser->parse_char_string ($s);

  print "#csstext\n";
  my $out = $ss->css_text;
  print STDOUT Encode::encode ('utf-8', $out);
} elsif ($mode eq '/tokens') {
  require Encode;
  require Whatpm::CSS::Tokenizer;

  my $s = $http->get_parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  print STDOUT "#errors\n";

  my $onerror = sub {
    my (%opt) = @_;
    print STDOUT "$opt{line},$opt{column},$opt{level},$opt{type}\n";
  };

  my $pos = 0;
  my $length = length $s;
  my $t = Whatpm::CSS::Tokenizer->new;
  $t->{get_char} = sub {
    if ($pos < $length) {
      return ord substr $s, $pos++, 1;
    } else {
      return -1;
    }
  };
  $t->init;
  my @token;
  while (1) {
    my $token = $t->get_next_token;
    push @token, $token;
    last if $token->{type} == Whatpm::CSS::Tokenizer::EOF_TOKEN ();
  }

  print "#tokens\n";

  my $out = '';
  for my $token (@token) {
    $out .= ($Whatpm::CSS::Tokenizer::TokenName[$token->{type}] or
             $token->{type}) . qq[\t"] . $token->{value} . qq["\t"] .
        $token->{number} . qq["\n];
  }
  print STDOUT Encode::encode ('utf-8', $out);
  print STDOUT "\n";
} elsif ($mode eq '/selectors') {
  require Encode;
  require Whatpm::CSS::SelectorsParser;

  my $s = $http->get_parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  my $p = Whatpm::CSS::SelectorsParser->new;

  print STDOUT "#errors\n";

  $p->{onerror} = sub {
    my (%opt) = @_;
    print STDOUT "$opt{line},$opt{column},$opt{level},$opt{type}\n";
  };

  $p->{pseudo_class}->{$_} = 1 for qw/
    active checked disabled empty enabled first-child first-of-type
    focus hover indeterminate last-child last-of-type link only-child
    only-of-type root target visited
    lang nth-child nth-last-child nth-of-type nth-last-of-type not
    -manakai-contains -manakai-current
  /;
  $p->{pseudo_element}->{$_} = 1 for qw/
    after before first-letter first-line
  /;

  my $selectors = $p->parse_string ($s);
  
  require Whatpm::CSS::SelectorsSerializer;
  my ($sel, $ns) = Whatpm::CSS::SelectorsSerializer->serialize_test
      ($selectors);
  my $out = "\n#namespaces\n" . $ns . "\n#selectors\n" . $sel;

  print STDOUT Encode::encode ('utf-8', $out);
  print STDOUT "\n";
} else {
  print STDOUT "Status: 404 Not Found\nContent-Type: text/plain; charset=us-ascii\n\n404";
}

exit;

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

## $Date: 2007/12/23 08:19:43 $
