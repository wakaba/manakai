#!/usr/bin/perl -w
use strict;

use Test;
require Message::Entity;
require Message::MIME::Charset;

  Message::MIME::Charset::make_charset ('*default' =>
    encoder	=> sub { $_[1] },
    decoder	=> sub { $_[1] },
    mime_text	=> 1,
  );

my (%test);
my %utf16;

BEGIN {
%test =  (
  "foo bar"
  	=> "us-ascii",
  "\x1B\x24B!y\x1B(B"
  	=> 'iso-2022-jp',
  "\x1B\x24(O&=\x1B\x24B!y\x1B(B"
  	=> 'x-iso-2022-7bit',
  "\x1B\x24(O&=\x1B(B"
  	=> 'iso-2022-jp-3-plane1',
  "\x1B\x24(O&=\x1B\x24(P!!\x1B(B"
  	=> 'iso-2022-jp-3',
  "\x1B\x24)G\x0El]N)k#\x0F"
  	=> "iso-2022-cn",	## From Hello
  "\x1b\x24\x29\x41\x0e\x3d\x3b\x3b\x3b\x1b\x24\x29\x47\x47\x28\x5f\x50\x0f"
  	=> "iso-2022-cn",	## From RFC 1922
  "\x1B\x24)C\x0EGQ1[\x0F"
  	=> 'iso-2022-kr',	## From Hello
  "Fran\x1B\x2E\x41\x1B\x4Egais"
  	=> 'iso-2022-jp-2',	## From Hello
  "\xA1\xA2\xA3\xA4"
  	=> 'iso-8859-1',
  "\x1B\x2DA\xA1\xA2\xA3\xA4"
  	=> 'x-iso-2022',
  "\xC1\x81\xC2\x82\xC3\x83\xC4\x84"
  	=> 'utf-8',
);
%utf16 = (
	"\x00A\x00S\x00C\x00I\x00I\x00!"	=> 'iso-10646-ucs-basic',
	"\x00L\x00a\x00t\x00i\x00n\x001\x00\xA1"	=> 'iso-10646-unicode-latin1',
	"\x01\x00\x4E\x00"	=> 'iso-10646-ucs-2',
	"\x30\x41\x30\x43"	=> 'iso-10646-j-1',
	"\x01\x00\x4E\x00\xD8\x00\xDC\x00"	=> 'utf-16be',
);
plan tests => 2 * keys (%test) + keys (%utf16) }

## Charset name auto-minimumization test
for (keys %test) {
  ok (Message::MIME::Charset::name_minimumize ('iso-2022-int-1', 
    $_), $test{$_}, 'name_minimumize is broken');
  my $b = Message::Entity->new;
  $b->body ($_);
  $b->stringify (-fill_ct => 1, -force_mime_entity => 1,
    -fill_date => 0, -add_ua => 0,
  );
  ok (scalar $b->header->field ('content-type')->parameter ('charset'), $test{$_}, 'name_minimumize with Message::Entity suite is broken');
}
for (keys %utf16) {
  ok (Message::MIME::Charset::name_minimumize ('utf-16be', 
    $_), $utf16{$_}, 'name_minimumize is broken');
}
