=head1 NAME

What::ContentType - What Sniffed Type the Entity is?

=head1 SYNOPSIS

  require What::ContentType;
  my $sniffed_type = What::ContentType->get_sniffed_type (
    get_file_head => sub {
      my $n = shift;
      return $first_n_bytes_of_the_entity;
    },
    http_content_type_byte => $content_type_field_body_of_the_entity_in_bytes,
    has_http_content_encoding => $is_there_cotntent_encoding_field ? 1 : 0,
    supported_image_types => {
      'image/jpeg' => 1, 'image/png' => 1, 'image/gif' => 1, # for example
    },
  );

=head1 DESCRIPTION

The C<What::ContentType> module can be used when you want to
know I<what> the media type, or I<content type>, of an entity is in fact.
It implements the algorithm for sniffing a file used when
a Web browser determine how to handle it, as defined
in Web Applications 1.0 (aka HTML5) specification.

=cut

package What::ContentType;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

## Table in <http://www.whatwg.org/specs/web-apps/current-work/#content-type1>.
##
## "User agents MAY support further types if desired, by implicitly adding
## to the above table. However, user agents SHOULD NOT use any other patterns
## for types already mentioned in the table above, as this could then be used
## for privilege escalation (where, e.g., a server uses the above table to 
## determine that content is not HTML and thus safe from XSS attacks, but
## then a user agent detects it as HTML anyway and allows script to execute)."
our @UnknownSniffingTable = (
  ## Mask, Pattern, Sniffed Type
  [
    "\xFF\xFF\xDF\xDF\xDF\xDF\xDF\xDF\xDF\xFF\xDF\xDF\xDF\xDF",
    "\x3C\x21\x44\x4F\x43\x54\x59\x50\x45\x20\x48\x54\x4D\x4C",
         ## ISSUE: Second byte of pattern is incorrect in spec
    "text/html",
  ],
  [
    "\xFF\xDF\xDF\xDF\xDF",
    "\x3C\x48\x54\x4D\x4C",
    "text/html",
  ],
  [
    "\xFF\xFF\xFF\xFF\xFF",
    "\x25\x50\x44\x46\x2D",
    "application/pdf",
  ],
  [
    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF",
    "\x25\x21\x50\x53\x2D\x41\x64\x6F\x62\x65\x2D",
    "application/postscript",
  ],
  [
    "\xFF\xFF\xFF\xFF\xFF\xFF",
    "\x47\x49\x46\x38\x37\x61",
    "image/gif",
  ],
  [
    "\xFF\xFF\xFF\xFF\xFF\xFF",
    "\x47\x49\x46\x38\x39\x61",
    "image/gif",
  ],
  [
    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF",
    "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
    "image/png",
  ],
  [
    "\xFF\xFF\xFF",
    "\xFF\xD8\xFF",
    "image/jpeg",
  ],
);

## Table in <http://www.whatwg.org/specs/web-apps/current-work/#content-type2>.
## 
## User agents are not (at least explicitly) allowed to add rows to this table.
my @ImageSniffingTable = (
  ## Pattern, Sniffed Type
  [
    "\x47\x49\x46\x38\x37\x61",
    "image/gif",
  ],
  [
    "\x47\x49\x46\x38\x39\x61",
    "image/gif",
  ],
  [
    "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
    "image/png",
  ],
  [
    "\xFF\xD8\xFF",
    "image/jpeg",
  ],
);
## NOTE: Ensure |$bytes| to be longer than pattern when a new image type
## is added to the table.

=head1 METHOD

=over 4

=item I<$sniffed_type> = What::ContentType->get_sniffed_type (I<named-parameters>)

Returns the sniffed type of an entity.

Named parameters:

=over 4

=item content_type_metadata

The Content-Type metadata as defined in Web Applications 1.0.
The value of this parameter MUST be an Internet Media Type (with
any parameters), that match to the C<media-type> rule
defined in RFC 2616.

If the C<http_content_type_byte> parameter is specified,
then this parameter has no effect.  Otherwise,
this parameter MUST be specified if and only if any Content-Type metadata
is available.

=item get_file_head

The code reference used to obtain first I<$n> bytes of the 
entity sniffed.  The value of this parameter MUST be a
reference to a subroutine that returns a string.

This parameter MUST be specified.  If missing, an empty
(zero-length) entity is assumed.

When invoked, the code receives a parameter I<$n> that 
represents the number of bytes expected.  The code SHOULD
return I<$n> bytes at the beginning of the entity.
If more than I<$n> bytes are returned, then I<$n> + 1
byte and later are discarded.  The code MAY return
a string whose length is less than I<$n> bytes
if no more bytes is available.

=item has_http_content_encoding

Whether the entity has HTTP C<Content-Encoding> header field specified.

This parameter MUST be set to a true value
if and only if the entity is transfered over HTTP
and the HTTP response entity contains the C<Content-Encoding>
header field.

=item http_content_type_byte

The byte sequence of the C<field-body> part of the HTTP
C<Content-Type> header field of the entity.

This parameter MUST be set to the byte sequence of
the C<Content-Type> header field's C<field-body> of
the entity if and only if it is transfered over HTTP
and the HTTP response entity contains the C<Content-Type>
header field.

=item supported_image_types

A reference to the hash that contains the list of supported
image types.

This parameter MUST be set to a reference to the hash
whose keys are Internet Media Types (without any parameter)
and whose values are whether image formats with those Internet Media Types
are supported or not.  A value MUST be true if and only
if the Internet Media Type is supported.

If this parameter is missing, then no image types are 
considered as supported.

=back

=cut

sub get_sniffed_type ($%) {
  shift;
  my %opt = @_;
  $opt{get_file_head} ||= sub () { return '' };

  ## <http://www.whatwg.org/specs/web-apps/current-work/#content-type-sniffing>
  
  ## Step 1
  if (not $opt{has_http_content_encoding} and
      defined $opt{http_content_type_byte}) {
    ## ISSUE: Is leading LWS ignored?
    if ($opt{http_content_type_byte} eq 'text/plain' or
        $opt{http_content_type_byte} eq 'text/plain; charset=ISO-8859-1' or
        $opt{http_content_type_byte} eq 'text/plain; charset=iso-8859-1') {
      ## Content-Type sniffing: text or binary
      ## <http://www.whatwg.org/specs/web-apps/current-work/#content-type4>

      ## Step 1
      my $bytes = substr $opt{get_file_head}->(512), 0, 512;

      ## Step 2
      ## Step 3
      if (length $bytes >= 4) {
        my $by = substr $bytes, 0, 4;
        return 'text/plain'
            if $by =~ /^\xFE\xFF/ or
                $by =~ /^\xFF\xFE/ or
                $by =~ /^\x00\x00\xFE\xFF/ or
                $by =~ /^\xEF\xBB\xBF/;
      }

      ## Step 4
      return 'application/octet-stream'
          if $bytes =~ /[\x00-\x08\x0E-\x1A\x1C-\x1F]/;

      ## Step 5
      return 'text/plain';
    }
  }

  ## Step 2
  my $official_type = $opt{content_type_metadata};
  $official_type = $opt{http_content_type_byte} unless defined $official_type;
  ## ISSUE: RFC 2616 defines no error handling rules
  if (defined $official_type and
      $official_type =~ m#^[\x09\x0A\x0D\x20]*([^/;,\s]+/[^/;,\s]+)#) {
    $official_type = lc $1;
  } else {
    ## ISSUE: If there is Content-Type but it has an error, then unknown type?
    ## ISSUE: Use of extension (of filename?) is disallowed (WA1 4.7.5)
    ## even if there is no Content-Type header field (RFC 2616 7.2.1)?

    ## Content-Type sniffing: unknown type
    ## <http://www.whatwg.org/specs/web-apps/current-work/#content-type5>

    ## Step 1
    my $bytes = substr $opt{get_file_head}->(512), 0, 512;
    
    ## Step 2
    my $stream_length = length $bytes;

    ## Step 3
    ROW: for my $row (@UnknownSniffingTable) { # Mask, Pattern, Sniffed Type
      my $pattern_length = length $row->[1];
      next ROW if $pattern_length > $stream_length;
      my $data = substr ($bytes, 0, $pattern_length) & $row->[0];
      return $row->[2] if $data eq $row->[1];
    }

    ## Step 4
    ## Text or binary; $n=$stream_length
   
    ## Step 3
    if ($stream_length >= 4) {
      my $by = substr $bytes, 0, 4;
      return 'text/plain'
          if $by =~ /^\xFE\xFF/ or
              $by =~ /^\xFF\xFE/ or
              $by =~ /^\x00\x00\xFE\xFF/ or
              $by =~ /^\xEF\xBB\xBF/;
    }

    ## Step 4
    return 'application/octet-stream'
        if $bytes =~ /[\x00-\x08\x0E-\x1A\x1C-\x1F]/;

    ## Step 5
    return 'text/plain';
  }

  ## Step 3
  if ($official_type =~ /\+xml$/ or 
      $official_type eq 'text/xml' or
      $official_type eq 'application/xml') {
    return $official_type;
  }

  ## Step 4
  if ($opt{supported_image_types}->{$official_type}) {
    ## Content-Type sniffing: image
    ## <http://www.whatwg.org/specs/web-apps/current-work/#content-type6>

    my $bytes = substr $opt{get_file_head}->(8), 0, 8;

    ## Table
    for my $row (@ImageSniffingTable) { # Pattern, Sniffed Type
      return $row->[1]
          if substr ($bytes, 0, length $row->[0]) eq $row->[0] and
              $opt{supported_image_types}->{$row->[1]};
    }

    ## Otherwise
    return $official_type;
  }

  ## Step 5
  if ($official_type eq 'text/html') {
    ## Content-Type sniffing: feed or HTML
    ## <http://www.whatwg.org/specs/web-apps/current-work/#content-type7>

    ## Step 1
    ## Step 2
    my $bytes = substr $opt{get_file_head}->(512), 0, 512;

    ## Step 3

    ## Step 4
    pos ($bytes) = 0;

    ## Step 5-8
    1 while $bytes =~ /\G(?:[\x09\x20\x0A\x0D]+|<!--.*?-->|<![^>]*>|<\?.*?\?>)/gcs;
    return 'text/html' unless $bytes =~ /\G</gc;

    ## Step 9
    if ($bytes =~ /\Grss/gc) {
      return 'application/rss+xml';
    } elsif ($bytes =~ /\Gfeed/gc) {
      return 'application/atom+xml';
    } elsif ($bytes and $bytes =~ /\Grdf:RDF/gc) {
      # 
    } else {
      return 'text/html';
    }

    ## Step 10
    ## ISSUE: Step 10 is not defined yet in the spec
    if ($bytes =~ /\G([^>]+)/gc) {
      my $by = $1;
      if ($by =~ m!xmlns[^>=]*=[\x20\x0A\x0D\x09]*["']http://www\.w3\.org/1999/02/22-rdf-syntax-ns#["']! and
          $by =~ m!xmlns[^>=]*=[\x20\x0A\x0D\x09]*["']http://purl\.org/rss/1\.0/["']!) {
        return 'application/rss+xml';
      }
    }

    ## Step 11
    return 'text/html';
  }

  return $official_type;
} # get_sniffed_type

=back

=head1 SEE ALSO

Web Applications 1.0 Working Draft - 
Determining the type of a new resource in a browsing context
<http://www.whatwg.org/specs/web-apps/current-work/#content-type-sniffing>

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2007/04/25 11:19:22 $
