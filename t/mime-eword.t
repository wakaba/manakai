#!/usr/bin/perl -w
## -*- euc-japan -*-

use strict;

use Test;
require Message::MIME::EncodedWord;
require Message::MIME::Charset;

my $encoder;
  eval q{
    use Message::MIME::Charset::Jcode 'Encode';
    warn "# Using Encode';
    $encoder = 'Encode';
    1;
  } or eval q{
    use Message::MIME::Charset::Jcode 'Jcode';
    warn "# Using Jcode.pm";
    $encoder = 'Jcode';
    1;
  } or eval q{
    use Message::MIME::Charset::Jcode 'jcode.pl';
    warn "# Using jcode.pl";
    $encoder = 'jcode.pl';
    1;
  } or do {
    warn "# You do not have Jcode.pm nor jcode.pl, so encoded-word test with Japanese string is skipped";
  };


my (%eword, %eword2, %ewordC);

BEGIN {
%eword =  (
  "=?ISO-2022-JP?B?GyRCNEE7eiEiJSslPyUrJUohIiRSJGkkLCRKGyhC?="
  	=> "漢字、カタカナ、ひらがな",
  "foo bar"
  	=> "foo bar",
  "=?ISO-2022-JP?B?GyRCNEE7eiEiJSslPyUrJUohIiRSJGkkLCRKJE46LiQ4JEMkPxsoQlN1?=\n =?ISO-2022-JP?B?YmplY3Q=?= Header."
  	=> "漢字、カタカナ、ひらがなの混じったSubject Header.",
  '=?iso-2022-jp?B?GyRCR3BMWjA0GyhC?='
  	=> '柏木梓',
  '=?us-ascii?q?MIME_Header=20(Defined_by_RFC=202047)?='
  	=> 'MIME Header (Defined by RFC 2047)',
  '=?ISO-2022-JP?B?GyRCJGokcyQ0GyhC?= =?ISO-2022-JP?B?MRskQjhEGyhC?= '.
  '=?iso-8859-2?q?=A5105?= !'
  	=> 'りんご1個 =?iso-8859-2?q?=A5105?= !',
  'An=?us-ascii?Q?invalid_quoted-word?='
  	=> 'An=?us-ascii?Q?invalid_quoted-word?=',
  '=?iso-2022-jp?B?GyRCJDMkTkZ8S1w4bCQsRkkkYSRsJFAbKEI=?= OK =?iso-2022-jp?B?GyRCJEckOSEjGyhC?='
  	=> 'この日本語が読めれば OK です。',
  'test of =?iso-8859-8?q?=FA=E9=F8=E1=F2?= in mail headers'
  	=> 'test of =?iso-8859-8?q?=FA=E9=F8=E1=F2?= in mail headers',
  '=?ISO-2022-jp?B?GyRCNEE7eiRkJSslSiRkISIbKEJTUCAbJEIkZBsoQg==?= latin letter =?us-ascii?q?_?= 	=?ISO-2022-JP?B?GyRCJHI0XiRgISJEOSRhJE5KODt6TnMhIxsoQg==?='
  	=> '漢字やカナや、SP や latin letter  を含む、長めの文字列。',
  '=?iso-2022-jp?q?=1B$B$=22$$$&$($=2A?= (Broken iso-2022-jp fragment)'
  	=> 'あいうえお (Broken iso-2022-jp fragment)',
);
%eword2 = (
  '=?iso-8859-1?Q?T=EBsting=20r=EBlatively?= long =?iso-8859-1?Q?fil=EBnames=2Etxt?='
  	=> "T\xEBsting r\xEBlatively long fil\xEBnames.txt",
  '=?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?= =?ISO-8859-1?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?='
  	=> 'If you can read this you understand the example.',
  '=?ISO-8859-1?x-unknown?unknown_encoded_characters?='
  	=> '=?ISO-8859-1?x-unknown?unknown_encoded_characters?=',
  '=?us-ascii?q?ABC?==?us-ascii?q?DEF?='	=> '=?us-ascii?q?ABC?==?us-ascii?q?DEF?=',
  '=?us-ascii?q?ABC DEF?='	=> '=?us-ascii?q?ABC DEF?=',
);
%ewordC = (
  '(=?ISO-8859-1?Q?a?=)'	=> '(a)',
  '(=?ISO-8859-1?Q?a?= b)'	=> '(a b)',
  '(=?ISO-8859-1?Q?a?= =?ISO-8859-1?Q?b?=)'	=> '(ab)',
  '(=?ISO-8859-1?Q?a?=  =?ISO-8859-1?Q?b?=)'	=> '(ab)',
  '(=?ISO-8859-1?Q?a?=	=?ISO-8859-1?Q?b?=)'	=> '(ab)',
  '(=?ISO-8859-1?Q?a_b?=)'	=> '(a b)',
  '(=?ISO-8859-1?Q?a?= =?ISO-8859-2?Q?_b?=)'	=> '(a b)',
  '(=?ISO-8859-1?Q?a?=b)'	=> '(=?ISO-8859-1?Q?a?=b)',
  '(=\?ISO-8859-1?Q?a?=)'	=> '(=?ISO-8859-1?Q?a?=)',
);
plan tests => 0 + keys (%eword) + keys (%eword2) + keys (%ewordC) }

$Message::MIME::EncodedWord::OPTION{forcedecode} = 0;
for (keys %eword) {
  skip (!$encoder, Message::MIME::EncodedWord::decode ($_), $eword{$_}, 'decoding eword is broken');
  #ok (Jcode->new ($_)->mime_decode, $eword{$_}, 'decoding eword with Jcode.pm failed');
}

Message::MIME::Charset::make_charset ('iso-8859-1' => decoder => sub { $_[1] });
$Message::MIME::EncodedWord::OPTION{forcedecode} = 1;
for (keys %eword2) {
  ok (Message::MIME::EncodedWord::decode ($_), $eword2{$_}, 'decoding eword is broken');
}

## Comment decode test from RFC 2047, etc.
Message::MIME::Charset::make_charset ('iso-8859-2' => decoder => sub { $_[1] });
$Message::MIME::EncodedWord::OPTION{forcedecode} = 0;
my $self = {option => {hook_decode_string => sub { value => $_[1] }}};
for (keys %ewordC) {
  ok (Message::MIME::EncodedWord::decode_ccontent ($self, $_), $ewordC{$_}, 'decoding eword in comment is broken');
}
