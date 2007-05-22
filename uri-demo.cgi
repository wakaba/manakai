#!/usr/bin/perl
use strict;
use lib qw[/home/wakaba/work/manakai/lib
           /home/wakaba/public_html/-temp/wiki/lib];
use CGI::Carp qw/fatalsToBrowser/;

use SuikaWiki::Input::HTTP; ## TODO: Use some better CGI module
my $http = SuikaWiki::Input::HTTP->new;

use Message::URI::URIReference;
use Encode;
use encoding 'utf8', STDOUT => 'utf8';

my $uri = Message::DOM::DOMImplementation->create_uri_reference
  (decode 'utf8', scalar $http->parameter ('uri'));
my $baseuri = Message::DOM::DOMImplementation->create_uri_reference
  (decode 'utf8', scalar $http->parameter ('baseuri'));

print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

for (
  [Original => 'uri_reference'],
  ['URI reference' => 'get_uri_reference'],
  ['URI reference [RFC 3986]' => 'get_uri_reference_3986'],
  ['IRI reference' => 'get_iri_reference'],
  ['IRI reference [RFC 3987]' => 'get_iri_reference_3987'],
  [Scheme => 'uri_scheme'],
  [Authority => 'uri_authority'],
  [userinfo => 'uri_userinfo'],
  [host => 'uri_host'],
  [port => 'uri_port'],
  [Path => 'uri_path'],
  [Query => 'uri_query'],
  [Fragment => 'uri_fragment'],
  ['URI?' => 'is_uri'],
  ['URI [RFC 3986]?' => 'is_uri_3986'],
  ['IRI?' => 'is_iri'],
  ['IRI [RFC 3987]?' => 'is_iri_3987'],
  ['Relative reference?' => 'is_relative_reference'],
  ['Relative reference [RFC 3986]?' => 'is_relative_reference_3986'],
  ['Relative IRI reference?' => 'is_relative_iri_reference'],
  ['Relative IRI reference [RFC 3987]?' => 'is_relative_iri_reference_3987'],
  ['URI reference?' => 'is_uri_reference'],
  ['URI reference [RFC 3986]?' => 'is_uri_reference_3986'],
  ['IRI reference?' => 'is_iri_reference'],
  ['IRI reference [RFC 3987]?' => 'is_iri_reference_3987'],
  ['Absolute URI?' => 'is_absolute_uri'],
  ['Absolute URI [RFC 3986]?' => 'is_absolute_uri_3986'],
  ['Absolute IRI?' => 'is_absolute_iri'],
  ['Absolute IRI [RFC 3987]?' => 'is_absolute_iri_3987'],
  ['Empty?' => 'is_empty_reference'],
) {
  my $method_name = $_->[1];
  my $value = $uri->$method_name;
  print STDOUT $_->[0] . ': ' . (defined $value ? '"' . $value . '"' : '(undef)') . "\n";
}

for (
  ['Absolute' => 'get_absolute_reference'],
  ['Absolute [RFC 3986]' => 'get_absolute_reference_3986'],
  ['Absolute [RFC 3987]' => 'get_absolute_reference_3987'],
  ['Relative' => 'get_relative_reference'],
  ['Same document reference?' => 'is_same_document_reference'],
  ['Same document reference [RFC 3986]?' => 'is_same_document_reference_3986'],
) {
  my $method_name = $_->[1];
  my $value = $uri->$method_name ($baseuri);
  print STDOUT $_->[0] . ': ' . (defined $value ? '"' . $value . '"' : '(undef)') . "\n";
}
