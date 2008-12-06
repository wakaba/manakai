package Message::URL;
use strict;
use warnings;

require Message::URI::URIReference;

sub new ($$) {
  shift;
  return Message::DOM::DOMImplementation->create_uri_reference ($_[0]);
} # new

sub new_abs ($$$) {
  shift;
  return Message::DOM::DOMImplementation->create_uri_reference ($_[0])
      ->get_absolute_reference ($_[1]);
} # new_abs

1;
