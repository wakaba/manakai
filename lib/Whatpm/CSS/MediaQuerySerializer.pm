package Whatpm::CSS::MediaQuerySerializer;
use strict;

sub serialize_media_query ($$) {
  my (undef, $mq) = @_;

  return join ', ', map {
    do {
      if (@$_ and $_->[0]->[0] eq '#type') {
        $_->[0]->[1];
      } else {
        'unknown';
      }
    }
  } @$mq;
} # serialize_media_query

1;
