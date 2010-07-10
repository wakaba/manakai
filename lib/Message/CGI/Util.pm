package Message::CGI::Util;
use strict;
use warnings;
use Exporter::Lite;

our @EXPORT_OK = qw/
  htescape
  percent_encode percent_encode_na
  percent_decode
  get_absolute_url
  datetime_in_content
  datetime_for_http
/;

sub htescape ($) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
} # htescape

sub percent_encode ($) {
  require Encode;
  my $s = Encode::encode ('utf8', $_[0]);
  $s =~ s/([^A-Za-z0-9_~-])/sprintf '%%%02X', ord $1/ges;
  return $s;
} # percent_encode

sub percent_encode_na ($) {
  require Encode;
  my $s = Encode::encode ('utf8', $_[0]);
  $s =~ s/([^\x00-\x7F])/sprintf '%%%02X', ord $1/ges;
  return $s;
} # percent_encode_na

sub percent_decode ($) { # input should be a byte string.
  require Encode;
  my $s = shift;
  $s =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
  return Encode::decode ('utf-8', $s); # non-UTF-8 octet converted to \xHH
} # percent_decode

sub get_absolute_url ($$) {
  require Message::DOM::DOMImplementation;
  return Message::DOM::DOMImplementation->create_uri_reference ($_[0])
      ->get_absolute_reference ($_[1])
      ->get_uri_reference 
      ->uri_reference;
} # get_absolute_url

## Returns the specified time in the "date or time strings in content" format.
sub datetime_in_content ($) {
  my @time = gmtime shift;
  return sprintf '%04d-%02d-%02d %02d:%02d:%02d+00:00',
      $time[5] + 1900, $time[4] + 1, $time[3], $time[2], $time[1], $time[0];
} # datetime_in_content

my @MonthName = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub datetime_for_http ($) {
  my @time = gmtime shift;
  return sprintf '%02d %s %04d %02d:%02d:%02d +0000',
      $time[3], $MonthName[$time[4]], $time[5] + 1900,
      $time[2], $time[1], $time[0];
} # datetime_for_http

1;

=head1 LICENSE

Copyright 2008-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
