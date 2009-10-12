package Whatpm::CacheManifest;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::URI::URIReference;

sub parse_byte_string ($$$$;$$) {
  require Encode;
  my $s = Encode::decode ('utf-8', $_[1]);
  return $_[0]->_parse (\$s, $_[2], $_[3], $_[4] || sub {
    my %err = @_;
    warn $err{type}, "\n";
  }, $_[5]);
} # parse_byte_string

sub parse_char_string ($$$$;$$) {
  return $_[0]->_parse (\($_[1]), $_[2], $_[3], $_[4] || sub {
    my %err = @_;
    warn $err{type}, "\n";
  }, $_[5]);
} # parse_char_string

my $default_error_levels = {
  must => 'm',
  info => 'i',
};

sub _parse ($$$$$$) {
  #my (undef, $input, $manifest_uri, $base_uri, $onerror, $levels) = @_;

  ## NOTE: A manifest MUST be labeled as text/cache-manifest.  (This should
  ## be checked in upper-level).
  ## NOTE: No "MUST" for being UTF-8.
  ## NOTE: A |text/cache-manifest| MUST be a cache manifest.
  ## NOTE: Newlines MUST be CR/CRLF/LF.  (We don't and can't check this.)

  ## ISSUE: In RFC 2046: "The specification for any future subtypes of "text" must specify whether or not they will also utilize a "charset" parameter"

  my $m_uri = Message::DOM::DOMImplementation->create_uri_reference ($_[2]);
  my $m_scheme = $m_uri->uri_scheme;

  my $onerror = $_[4];
  my $levels = $_[5] || $default_error_levels;

  my $line_number = 1;

  ## Same origin with the manifest's URI
  my $same_origin = sub {
    ## NOTE: Step numbers in this function corresponds to those in the
    ## algorithm for determining the origin of a URI specified in HTML5.

    ## 1. and 2.
    my $u1 = shift;
    #my $m_uri = $m_uri;


    ## 3.
    return 0 unless defined $u1->uri_authority;
    return 0 unless defined $m_uri->uri_authority;
    ## TODO: In addition, in the case of URIs with non-server-based authority
    ## it must also return 0.
    
    ## 4.
    unless (lc $u1->uri_scheme eq lc $m_scheme) { ## TODO: case
      return 0;
    }
    ## TODO: Return if $u1->uri_scheme is not a supported scheme.
    ## NOTE: $m_scheme is always a supported URI scheme, otherwise
    ## the manifest itself cannot be retrieved.

    ## 5., 6., and 7.
    return 0 unless $u1->uri_host eq $m_uri->uri_host;
    ## TODO: IDNA ToASCII
 
    ## 8.
    return 0 unless $u1->uri_port eq $m_uri->uri_port;
    ## TODO: default port

    ## 9.
    return 1;
  }; # $same_origin

  ## Step 5
  my $input = $_[1];
  
  ## Step 1: MUST bytes --UTF-8--> characters.
  ## NOTE: illegal(s) -> U+FFFD, #U+0000 -> U+FFFD (commented out in r1553).
  #$$input =~ tr/\x00/\x{FFFD}/;

  ## Step 2
  my $explicit_uris = [];

  ## Step 3
  my $fallback_uris = {};

  ## Step 4
  my $online_whitelist_uris = [];

  ## Step 6
  pos ($$input) = 0;

  ## Step 7
  ## Skip BOM ## NOTE: MAY in syntax.

  ## Step 8-10
  unless ($$input =~ /^CACHE MANIFEST[\x20\x09]*(?![^\x0D\x0A])/gc) {
    $onerror->(type => 'not manifest', level => $levels->{must},
               line => $line_number, column => 1); ## NOTE: MUST in syntax.
    return; ## Not a manifest.
  }

  ## Step 11
  ## This is a cache manifest.

  ## Step 12
  my $mode = 'explicit';

  ## NOTE: MUST be (blank line|comment|section head|data for the current
  ## section)*.

  ## Step 13
  START_OF_LINE: while (pos $$input < length $$input) {
    $$input =~ /([\x0A\x0D\x20\x09]+)/gc;
    my $v = $1;
    $line_number++ for $v =~ /\x0D\x0A?|\x0A/g;

    ## Step 14
    $$input =~ /([^\x0A\x0D]*)/gc;
    my $line = $1;

    ## Step 15
    $line =~ s/[\x20\x09]+\z//;

    ## Step 16-17
    if ($line eq '' or $line =~ /^#/) {
      next START_OF_LINE;
    }

    if ($line eq 'CACHE:') {
      ## Step 18
      $mode = 'explicit';
      next START_OF_LINE;
    } elsif ($line eq 'FALLBACK:') {
      ## Step 19
      $mode = 'fallback';
      next START_OF_LINE;
    } elsif ($line eq 'NETWORK:') {
      ## Step 20
      $mode = 'online whitelist';
      next START_OF_LINE;
    } elsif ($line =~ /:\z/) {
      ## Step 21
      $mode = 'unknown';

      $onerror->(type => 'manifest:unknown section',
                 level => $levels->{must},
                 line => $line_number, column => 1,
                 value => $line);

      next START_OF_LINE;
    }

    ## NOTE: "URIs that are to be fallback pages associated with
    ## opportunistic caching namespaces, and those namespaces themselves,
    ## MUST be given in fallback sections, with the namespace being the
    ## first URI of the data line, and the corresponding fallback page
    ## being the second URI. All the other pages to be cached MUST be
    ## listed in explicit sections." in writing section can't be tested.
    ## NOTE: "URIs that the user agent is to put into the online whitelist
    ## MUST all be specified in online whitelist sections." in writing
    ## section can't be tested.

    ## NOTE: "Relative URIs MUST be given relative to the manifest's own URI."
    ## requirement in writing section can't be tested.

    ## Step 22
    ## "This is either a data line or it is syntactically incorrect."

    ## Step 23-26
    my $tokens = [split /[\x09\x20]+/, $line];
    shift @$tokens if $tokens->[0] eq ''; # leading white space
    ## NOTE: Now, @$tokens contains at least one non-empty string.

    ## Step 27
    if ($mode eq 'explicit') {
      if (@$tokens > 1) {
        $onerror->(type => 'manifest:too many tokens',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $tokens->[1]);
      }

      my $uri = Message::DOM::DOMImplementation->create_uri_reference
          ($tokens->[0]);

      unless ($uri->is_iri_reference_3987) {
        $onerror->(type => 'syntax error:iriref3987',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $line);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      $uri = $uri->get_absolute_reference ($_[3]);

      if (defined $uri->uri_fragment) {
        $uri->uri_fragment (undef);
        $onerror->(type => 'URL fragment not allowed',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $line);
        ## NOTE: MUST in writing section.
      }

      my $scheme = $uri->uri_scheme;
      unless (defined $scheme and $scheme eq $m_scheme) {
        $onerror->(type => 'different scheme from manifest',
                   level => $levels->{info},
                   line => $line_number, column => 1,
                   value => $uri->uri_reference);
        next START_OF_LINE;
      }

      push @$explicit_uris, $uri->uri_reference;
    } elsif ($mode eq 'fallback') {
      if (@$tokens > 2) {
        $onerror->(type => 'manifest:too many tokens',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $tokens->[2]);
      }

      my ($p1, $p2) = (@$tokens);

      unless (defined $p2) {
        $onerror->(type => 'no fallback entry URL',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $line);

        ## ISSUE: The following is dropped in r2051 (error?)
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      my $u1 = Message::DOM::DOMImplementation->create_uri_reference ($p1);

      unless ($u1->is_iri_reference_3987) {
        $onerror->(type => 'syntax error:iriref3987',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   index => 0, value => $p1);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      my $u2 = Message::DOM::DOMImplementation->create_uri_reference ($p2);

      unless ($u2->is_iri_reference_3987) {
        $onerror->(type => 'syntax error:iriref3987',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   index => 1, value => $p2);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      if (defined $u1->uri_fragment) {
        $u1->uri_fragment (undef);
        $onerror->(type => 'URL fragment not allowed',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   index => 0, value => $p1);
        ## NOTE: MUST in writing section.
      }

      if (defined $u2->uri_fragment) {
        $u2->uri_fragment (undef);
        $onerror->(type => 'URL fragment not allowed',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   index => 1, value => $p2);
        ## NOTE: MUST in writing section.
      }

      $u1 = $u1->get_absolute_reference ($_[3]);
      $u2 = $u2->get_absolute_reference ($_[3]);

      if (exists $fallback_uris->{$u1->uri_reference}) {
        $onerror->(type => 'duplicate oc namespace',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   index => 0, value => $u1->uri_reference);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }
      
      unless ($same_origin->($u1)) {
        $onerror->(type => 'different origin from manifest',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   index => 0, value => $u1->uri_reference);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      my $u2_scheme = $u2->uri_scheme;
      unless (defined $u2_scheme and $u2_scheme eq $m_scheme) {
        $onerror->(type => 'different scheme from manifest',
                   level => $levels->{info},
                   line => $line_number, column => 1,
                   index => 1, value => $u2->uri_reference);
        next START_OF_LINE;
      }

      $fallback_uris->{$u1->uri_reference} = $u2->uri_reference;
    } elsif ($mode eq 'online whitelist') {
      if (@$tokens > 1) {
        $onerror->(type => 'manifest:too many tokens',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $tokens->[1]);
      }

      my $uri = Message::DOM::DOMImplementation->create_uri_reference
          ($tokens->[0]);

      unless ($uri->is_iri_reference_3987) {
        $onerror->(type => 'syntax error:iriref3987',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $line);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      $uri = $uri->get_absolute_reference ($_[3]);

      if (defined $uri->uri_fragment) {
        $uri->uri_fragment (undef);
        $onerror->(type => 'URL fragment not allowed',
                   level => $levels->{must},
                   line => $line_number, column => 1,
                   value => $line);
        ## NOTE: MUST in writing section.
      }

      my $scheme = $uri->uri_scheme;
      unless (defined $scheme and $scheme eq $m_scheme) {
        $onerror->(type => 'different scheme from manifest',
                   level => $levels->{info},
                   line => $line_number, column => 1,
                   value => $uri->uri_reference);
        next START_OF_LINE;
      }

      push @$online_whitelist_uris, $uri->uri_reference;      
    } elsif ($mode eq 'unknown') {
      ## NOTE: Do nothing.
      ## NOTE: No informational message is thrown, since when the mode
      ## is switched to the "unknown" state an error is raised.
    }

    ## Step 28
    #next START_OF_LINE;
  } # START_OF_LINE

  ## Step 29
  return [$explicit_uris, $fallback_uris, $online_whitelist_uris,
          $m_uri->uri_reference];
} # _parse

sub check_manifest ($$$;$) {
  my (undef, $manifest, $onerror, $levels) = @_;

  my $listed = {};

  $levels ||= $default_error_levels;

  require Whatpm::URIChecker;

  my $i = 0;
  for my $uri (@{$manifest->[0]}) {
    $listed->{$uri} = 1;

    Whatpm::URIChecker->check_iri_reference ($uri, sub {
      $onerror->(value => $uri, @_, index => $i);
    });

    ## ISSUE: Literal equivalence, right?
    if ($uri eq $manifest->[3]) {
      $onerror->(level => $levels->{must}, value => $uri,
                 index => $i,
                 type => 'same as manifest URL');
    }

    $i++;
  }

  for my $uri1 (sort {$a cmp $b} keys %{$manifest->[1]}) {
    Whatpm::URIChecker->check_iri_reference ($uri1, sub {
      $onerror->(value => $uri1, @_, index => 0);
    });

    if ($uri1 eq $manifest->[3]) {
      $onerror->(level => $levels->{must}, value => $uri1,
                 index => $i,
                 type => 'same as manifest URL');
    }

    $i++;

    my $uri2 = $manifest->[1]->{$uri1};
    $listed->{$uri2} = 1;

    Whatpm::URIChecker->check_iri_reference ($uri2, sub {
      $onerror->(value => $uri2, @_, index => 1);
    });

    if ($uri2 eq $manifest->[3]) {
      $onerror->(level => $levels->{must}, value => $uri2,
                 index => $i,
                 type => 'same as manifest URL');
    }

    $i++;
  }

  for my $uri (@{$manifest->[2]}) {
    if ($listed->{$uri}) {
      $onerror->(type => 'both in entries and whitelist',
                 index => $i,
                 level => $levels->{must}, value => $uri);
      ## NOTE: MUST in writing section.
    }

    Whatpm::URIChecker->check_iri_reference ($uri, sub {
      $onerror->(value => $uri, @_, index => $i);
    });

    if ($uri eq $manifest->[3]) {
      $onerror->(level => $levels->{must}, value => $uri,
                 index => $i,
                 type => 'same as manifest URL');
    }

    $i++;
  }
} # check_manifest


=head1 LICENSE

Copyright 2007-2008 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2008/08/31 13:27:33 $
