#!/usr/bin/perl -w
## -*- euc-japan -*-
use strict;

use Test;
require Message::Util;

my (%test);

%test =  (
  "(180)(193)(187)(250)(161)(162)(165)(171)(165)(191)(165)(171)(165)(202)(161)(162)(164)(210)(164)(233)(164)(172)(164)(202)"
  	=> ['decoding 8bit printable-string' => sub { Message::Util::encode_printable_string (
  	  "漢字、カタカナ、ひらがな"
  	) }],
  "'a demo.'"
  	=> ['decoding no-encoded printable-string' => sub { Message::Util::decode_printable_string (
  	  "'a demo.'"
  	) }],
  "a demo."
  	=> ['encoding printable-string' => sub { Message::Util::encode_printable_string (
  	  "a demo."
  	) }],
  q{foo(a)bar.example}
  	=> ['encoding printable-string' => sub { Message::Util::encode_printable_string (
  	  q{foo@bar.example}
  	) }],
  q{foo@bar.example}
  	=> ['decoding printable-string' => sub { Message::Util::decode_printable_string (
  	  q{foo(A)bar.example}
  	) }],
  q{(q)(u)(p)(q)(126)}
  	=> ['encoding printable-string' => sub { Message::Util::encode_printable_string (
  	  q{"_%"~}
  	) }],
  q{"_%"(}
  	=> ['decoding printable-string' => sub { Message::Util::decode_printable_string (
  	  q{(q)(u)(p)(q)(}
  	) }],
  q{aou(vvv)v{dfda}ddd}
  	=> ['decoding T.61String' => sub { Message::Util::decode_t61_string (
  	  q{aou{040}vvv{041}v{123}dfda{125}ddd}
  	) }],
  q{Aidfo{064}bar.example}
  	=> ['encoding T.61String' => sub { Message::Util::encode_t61_string (
  	  q{Aidfo@bar.example}
  	) }],
  q{dd(d)v)(%)aaieu}
  	=> ['decoding T.61String' => sub { Message::Util::decode_t61_string (
  	  q{dd{040}d{041}v{041040037041}aaieu}
  	) }],
  q{argle#~}
  	=> ['decoding restricted RFC 822' => sub { Message::Util::decode_restricted_rfc822 (
  	  q{argle#h##126#}
  	) }],
  q{Steve_Kille}
  	=> ['encoding restricted RFC 822' => sub { Message::Util::encode_restricted_rfc822 (
  	  q{Steve Kille}
  	) }],
);
plan tests => 0 + keys (%test);

for (keys %test) {
  ok (&{ $test{$_}->[1] }, $_, $test{$_}->[0].' is broken');
}
