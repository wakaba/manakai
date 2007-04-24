use strict;
use Test;

BEGIN { plan tests => 780 }

use What::ContentType;

sub x (@) { join '', map { chr hex $_ } @_ }

for my $v (
  # octet stream,
  # Content-Type field-body bytes, has Content-Encoding?,
  # "text or binary" expected, description,
  # "unknown type" expected,
  # "feed or HTML" expected,
  [
    q<>,
    q<text/plain>, 0,
    q<text/plain>, 'empty',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<1245474734737435373474\x0D\x0A4634647647>,
    q<text/plain>, 0,
    q<text/plain>, 'ASCII',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xEF\xBB\xBF1245474734737435373474\x0D\x0A4634647647>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-8 BOM',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x20\xEF\xBB\xBF1245474734737435373474\x0D\x0A4634647647>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-8 ZWNBSP',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xFE\xFF546473474747477444>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-16BE BOM',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xFF\xFE546473474747477444>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-16LE BOM',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<23\xFE\xFF546473474747477444>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-16BE ZWNBSP',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<55\xFF\xFE546473474747477444>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-16LE ZWNBSP',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xFF\xFE\x00\x0054647347474747744334>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-32LE BOM',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x00\x00\xFE\xFF54647347474747744334>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-32BE BOM',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xFE\xFF\x00\x0054647347474747744334>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-32 3412 BOM',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x0054647347474747744334>,
    q<text/plain>, 0,
    q<application/octet-stream>, 'NULL',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x0054647347474747744334>,
    q<text/plain>, 1,
    q<text/plain>, 'NULL with Content-Encoding',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x1B\$B54647347474747744334\x1B(Bs46464>,
    q<text/plain>, 0,
    q<text/plain>, 'ISO-2022-JP',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x81\x40\x81\x41\x81\x42\x81\x43>,
    q<text/plain>, 0,
    q<text/plain>, 'Shift_JIS',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xFE\xFF>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-16BE BOM only',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xFF\xFE>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-16LE BOM only',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x00\x00\xFE\xFF>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-32BE BOM only',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x00\x00\xFF\xFE>,
    q<text/plain>, 0,
    q<application/octet-stream>, 'UTF-32 2143 BOM only',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\xEF\xBB\xBF>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-8 BOM only',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\xEF\xBB\xBF\x1A>,
    q<text/plain>, 0,
    q<text/plain>, 'UTF-8 BOM + 1',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain>, 0,
    q<application/octet-stream>, '0x02',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; charset=US-ASCII>, 0,
    q<text/plain>, '0x02; charset=US-ASCII',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/Plain>, 0,
    q<text/plain>, '0x02; text/Plain',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; charset=iso-8859-1>, 0,
    q<application/octet-stream>, '0x02',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; charset=ISO-8859-1>, 0,
    q<application/octet-stream>, '0x02',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; charset=isO-8859-1>, 0,
    q<text/plain>, '0x02; charset=isO-8859-1',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; Charset=iso-8859-1>, 0,
    q<text/plain>, '0x02; Charset=iso-8859-1',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; charset="iso-8859-1">, 0,
    q<text/plain>, '0x02; charset="iso-8859-1"',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<\x02>,
    q<text/plain; charset=iso-8859-1; format=flowed>, 0,
    q<text/plain>, '0x02; format=flowed',
    q<application/octet-stream>,
    q<text/html>,
  ],
  [
    qq<<!DOCTYPE HTML>\x0A...>,
    q<text/plain>, 0,
    q<text/plain>, '<!DOCTYPE HTML',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<!DOCTYPE html>\x0A...>,
    q<text/plain>, 0,
    q<text/plain>, '<!DOCTYPE html',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<!doctype html>\x0A...>,
    q<text/plain>, 0,
    q<text/plain>, '<!doctype html',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<!DOCtypE htmL>\x0A...>,
    q<text/plain>, 0,
    q<text/plain>, '<!DOCtypE htmL>',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">\x0A...>,
    q<text/plain>, 0,
    q<text/plain>, '<!DOCTYPE html PUBLIC "...">',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<html>\x0A...>,
    q<text/plain>, 0,
    q<text/plain>, '<html>',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<html lang="ja"><title>AA>,
    q<text/plain>, 0,
    q<text/plain>, '<html lang="ja">',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<HTML>>,
    q<text/plain>, 0,
    q<text/plain>, '<HTML>',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<Html>>,
    q<text/plain>, 0,
    q<text/plain>, '<Html>',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<html xmlns="http://www.w3.org/1999/xhtml">>,
    q<text/plain>, 0,
    q<text/plain>, '<html xmlns="...">',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<p><!DOCTYPE html></p>>,
    q<text/plain>, 0,
    q<text/plain>, '<p><!DOCTYPE html></p>',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<<!SGML html PUBLIC "..."><!DOCTYPE html PUBLIC "...">>,
    q<text/plain>, 0,
    q<text/plain>, '<!SGML ...><!DOCTYPE html ...>',
    q<text/plain>,
    q<text/html>,
  ],
  [
    qq<<htmlplus>>,
    q<text/plain>, 0,
    q<text/plain>, '<htmlplus>',
    q<text/html>,
    q<text/html>,
  ],
  [
    qq<<?xml version="1.0"?><html />>,
    q<text/plain>, 0,
    q<text/plain>, '<?xml?><html/>',
    q<text/plain>,
    q<text/html>,
  ],
  [
    x (qw(25 21 50 53 2d 41 64 6f 62 65 2d 32 2e 30 0a 25
          25 43 72 65 61 74 6f 72 3a 20 64 76 69 70 73 20
          35 2e 34 38 35 20 43 6f 70 79 72 69 67 68 74 20
          31 39 38 36 2d 39 32 20 52 61 64 69 63 61 6c 20)),
    q<text/plain>, 0,
    q<text/plain>, 'PS',
    q<application/postscript>,
    q<text/html>,
  ],
  [
    x (qw(25 50 44 46 2d 31 2e 32 0a 25 c7 ec 8f a2 0a 36
          20 30 20 6f 62 6a 0a 3c 3c 2f 4c 65 6e 67 74 68
          20 37 20 30 20 52 2f 46 69 6c 74 65 72 20 2f 46
          6c 61 74 65 44 65 63 6f 64 65 3e 3e 0a 73 74 72)),
    q<text/plain>, 0,
    q<text/plain>, 'PDF',
    q<application/pdf>,
    q<text/html>,
  ],
  [
    x (qw(47 49 46 38 37 61 eb 00 36 00 87 00 00 57 3b 23
          74 34 00 78 38 00 7d 3d 00 7a 55 32 7e 5a 36 7e
          5a 3a 80 40 01 84 44 05 89 49 0a 8c 4c 0d 83 4b)),
    q<text/plain>, 0,
    q<application/octet-stream>, 'GIF87a',
    q<image/gif>,
    q<text/html>,
  ],
  [
    x (qw(47 49 46 38 39 61 eb 00 36 00 87 00 00 57 3b 23
          74 34 00 78 38 00 7d 3d 00 7a 55 32 7e 5a 36 7e
          5a 3a 80 40 01 84 44 05 89 49 0a 8c 4c 0d 83 4b)),
    q<text/plain>, 0,
    q<application/octet-stream>, 'GIF89a',
    q<image/gif>,
    q<text/html>,
  ],
  [
    x (qw(89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52
          00 00 00 61 00 00 00 2a 08 03 00 00 00 94 47 c5
          3e 00 00 03 00 50 4c 54 45 ff ff ff fc 12 3c 1c)),
    q<text/plain>, 0,
    q<application/octet-stream>, 'PNG',
    q<image/png>,
    q<text/html>,
  ],
  [
    x (qw(ff d8 ff e0 00 10 4a 46 49 46 00 01 01 00 00 01
          00 01 00 00 ff db 00 43 00 14 0e 0f 12 0f 0d 14
          12 10 12 17 15 14 18 1e 32 21 1e 1c 1c 1e 3d 2c)),
    q<text/plain>, 0,
    q<application/octet-stream>, 'JPEG JFIF',
    q<image/jpeg>,
    q<text/html>,
  ],
  [
    q<<rss><title>RSS feed</title></rss>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS unversioned',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<rss version="2.0"><title>RSS feed</title></rss>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS 2.0',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<?xml version="1.0"?><rss><title>RSS feed</title></rss>>,
    q<text/plain>, 0,
    q<text/plain>, '<?xml?>RSS',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    qq<<!-- RSS 2.0 --> \x0A<rss version="2.0"><title>RSS feed</title></rss>>,
    q<text/plain>, 0,
    q<text/plain>, 'Comment S RSS',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<!-- RSS 2.0 --><!DOCTYPE rss []><rss version="2.0"><title>RSS feed</title></rss>>,
    q<text/plain>, 0,
    q<text/plain>, 'Comment DOCTYPE RSS',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<rdf:RDF><channel></channel></rdf:RDF>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS 1.0 no namespace',
    q<text/plain>,
    q<text/html>,
  ],
  [
    q<<rdf:RDF xmlns="http://purl.org/rss/1.0/"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
           <channel></channel></rdf:RDF>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS 1.0 namespaced 1',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<rdf:RDF
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns="http://purl.org/rss/1.0/">
           <channel></channel></rdf:RDF>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS 1.0 namespaced 2',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:dc=".."
         xmlns="http://purl.org/rss/1.0/">
           <channel></channel></rdf:RDF>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS 1.0 namespaced 3',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:dc=".."
         xmlns:rss="http://purl.org/rss/1.0/">
           <rss:channel></rss:channel></rdf:RDF>>,
    q<text/plain>, 0,
    q<text/plain>, 'RSS 1.0 namespaced 4',
    q<text/plain>,
    q<application/rss+xml>,
  ],
  [
    q<<feed xmlns="http://www.w3.org/2005/Atom"><id>...</id></feed>>,
    q<text/plain>, 0,
    q<text/plain>, 'Atom feed',
    q<text/plain>,
    q<application/atom+xml>,
  ],
  [
    q<<feed><id>...</id></feed>>,
    q<text/plain>, 0,
    q<text/plain>, 'unnamespaced Atom feed',
    q<text/plain>,
    q<application/atom+xml>,
  ],
  [
    q<<entry xmlns="http://www.w3.org/2005/Atom"><id>...</id></entry>>,
    q<text/plain>, 0,
    q<text/plain>, 'Atom entry',
    q<text/plain>,
    q<text/html>,
  ],
  [
    q<<html xmlns="http://www.w3.org/1999/xhtml"><head><feed xmlns="http://www.w3.org/2005/Atom"><id>...</id></feed></head>>,
    q<text/plain>, 0,
    q<text/plain>, 'Atom in HTML',
    q<text/html>,
    q<text/html>,
  ],
  [
    q<<Atom:feed xmlns="http://www.w3.org/2005/Atom"><Atom:id>...</Atom:id></Atom:feed>>,
    q<text/plain>, 0,
    q<text/plain>, 'prefixed Atom entry',
    q<text/plain>,
    q<text/html>,
  ],
) {
  ## Text or binary
  my $st = What::ContentType->get_sniffed_type (get_file_head => sub {
    return $v->[0]; 
  }, http_content_type_byte => $v->[1],
  has_http_content_encoding => $v->[2],
  supported_image_types => {'image/jpeg' => 1});
  ok $st, $v->[3], 'Text or binary: ' . $v->[4];

  ## Unknown type
  $st = What::ContentType->get_sniffed_type (get_file_head => sub {
    return $v->[0]; 
  },
  supported_image_types => {'image/jpeg' => 1});
  ok $st, $v->[5], 'Unknown type: ' . $v->[4];

  ## Image
  for my $img_type (qw(image/png image/gif image/jpeg)) {
    ## If it is the only supported type
    my $st = What::ContentType->get_sniffed_type (get_file_head => sub {
      return $v->[0];
    },
    http_content_type_byte => $img_type,
    supported_image_types => {$img_type => 1});
    ok $st, $img_type, 'Image (only): ' . $v->[4];

    ## If there is no supported type
    $st = What::ContentType->get_sniffed_type (get_file_head => sub {
      return $v->[0];
    },
    http_content_type_byte => $img_type,
    supported_image_types => {});
    ok $st, $img_type, 'Image (no): ' . $v->[4];

    ## If all types are supported
    $st = What::ContentType->get_sniffed_type (get_file_head => sub {
      return $v->[0];
    },
    http_content_type_byte => $img_type,
    supported_image_types => {qw(image/png 1 image/jpeg 1 image/gif 1)});
    ok $st, $v->[5] =~ m#^image/# ? $v->[5] : $img_type,
        'Image (all): ' . $v->[4];
  }

  ## Feed or HTML
  $st = What::ContentType->get_sniffed_type (get_file_head => sub {
    return $v->[0]; 
  },
  http_content_type_byte => 'text/html',
  supported_image_types => {'image/jpeg' => 1});
  ok $st, $v->[6], 'Feed or HTML: ' . $v->[4];
}

## License: Public Domain.
## $Date: 2007/04/24 14:24:33 $
1;
