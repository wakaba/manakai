package Whatpm::CacheManifest;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::URI::URIReference;

sub parse_byte_string ($$$$$) {
  require Encode;
  my $s = Encode::decode ('utf-8', $_[1]);
  return $_[0]->_parse (\$s, $_[2], $_[3], $_[4] || sub {
    my %err = @_;
    warn $err{type}, "\n";
  });
} # parse_byte_string

sub parse_char_string ($$$$$) {
  return $_[0]->_parse (\($_[1]), $_[2], $_[3], $_[4] || sub {
    my %err = @_;
    warn $err{type}, "\n";
  });
} # parse_char_string

sub _parse ($$$$$) {
  #my (undef, $input, $manifest_uri, $base_uri, $onerror) = @_;

  ## NOTE: A manifest MUST be labeled as text/cache-manifest.  (This should
  ## be checked in upper-level).
  ## NOTE: No "MUST" for being UTF-8.
  ## NOTE: A |text/cache-manifest| MUST be a cache manifest.
  ## NOTE: Newlines MUST be CR/CRLF/LF.  (We don't and can't check this.)

  ## ISSUE: In RFC 2046: "The specification for any future subtypes of "text" must specify whether or not they will also utilize a "charset" parameter"

  my $m_uri = Message::DOM::DOMImplementation->create_uri_reference ($_[2]);
  my $m_scheme = $m_uri->uri_scheme;

  my $onerror = $_[4];
  my $must_level = 'm';
  my $warn_level = 'w';
  my $line_number = 1;

  ## Same scheme/host/port
  my $same_shp = sub {
    ## TODO: implement this algorithm correctly!

    my $u1 = shift;
    
    unless (lc $u1->uri_scheme eq lc $m_scheme) {
      return 0;
    }

    return 0 unless defined $u1->uri_authority;
    return 0 unless defined $m_uri->uri_authority;

    return 0 unless $u1->uri_host eq $m_uri->uri_host;
    return 0 unless $u1->uri_port eq $m_uri->uri_port;

    return 1;
  }; # $same_shp

  ## Step 5
  my $input = $_[1];
  
  ## Step 1: MUST bytes --UTF-8--> characters.
  ## NOTE: illegal(s) -> U+FFFD, U+0000 -> U+FFFD
  $$input =~ tr/\x00/\x{FFFD}/;

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
    $onerror->(type => 'not manifest', level => $must_level,
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
    $line_number++ for $v =~ /\x0D\x0A?|\x0D/g;

    ## Step 14
    $$input =~ /([^\x0A\x0D]*)/gc;
    my $line = $1;

    ## Step 15
    next START_OF_LINE if $line =~ /^#/;

    ## Step 16
    $line =~ s/[\x20\x09]+\z//;

    if ($line eq 'CACHE:') {
      ## Step 17
      $mode = 'explicit';
      next START_OF_LINE;
    } elsif ($line eq 'FALLBACK:') {
      ## Step 18
      $mode = 'fallback';
      next START_OF_LINE;
    } elsif ($line eq 'NETWORK:') {
      ## Step 19
      $mode = 'online whitelist';
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

    ## Step 20
    if ($mode eq 'explicit') {
      my $uri = Message::DOM::DOMImplementation->create_uri_reference ($line);

      unless ($uri->is_iri_reference_3987) {
        $onerror->(type => 'URI::syntax error:iriref3987',
                   level => $must_level, line => $line_number, column => 1,
                   value => $line);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      $uri = $uri->get_absolute_reference ($_[3]);

      if (defined $uri->uri_fragment) {
        $uri->uri_fragment (undef);
        $onerror->(type => 'URI fragment not allowed',
                   level => $must_level, line => $line_number, column => 1,
                   value => $line);
        ## NOTE: MUST in writing section.
      }

      my $scheme = $uri->uri_scheme;
      unless (defined $scheme and $scheme eq $m_scheme) {
        $onerror->(type => 'different scheme from manifest',
                   level => $warn_level, line => $line_number, column => 1,
                   value => $uri->uri_reference);
        next START_OF_LINE;
      }
      ## ISSUE: case-insensitive?

      push @$explicit_uris, $uri->uri_reference;
    } elsif ($mode eq 'fallback') {
      my ($p1, $p2) = split /[\x20\x09]+/, $line, 2;

      unless (defined $p2) {
        $onerror->(type => 'no fallback entry URI',
                   level => $must_level, line => $line_number, column => 1,
                   value => $line);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      my $u1 = Message::DOM::DOMImplementation->create_uri_reference ($p1);

      unless ($u1->is_iri_reference_3987) {
        $onerror->(type => 'URI::syntax error:iriref3987',
                   level => $must_level, line => $line_number, column => 1,
                   index => 0, value => $p1);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      my $u2 = Message::DOM::DOMImplementation->create_uri_reference ($p2);

      unless ($u2->is_iri_reference_3987) {
        $onerror->(type => 'URI::syntax error:iriref3987',
                   level => $must_level, line => $line_number, column => 1,
                   index => 1, value => $p2);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      if (defined $u1->uri_fragment) {
        $onerror->(type => 'URI fragment not allowed',
                   level => $must_level, line => $line_number, column => 1,
                   index => 0, value => $p1);
        ## NOTE: MUST in writing section.
        ## ISSUE: Not dropped
      }

      if (defined $u2->uri_fragment) {
        $onerror->(type => 'URI fragment not allowed',
                   level => $must_level, line => $line_number, column => 1,
                   index => 1, value => $p2);
        ## NOTE: MUST in writing section.
        ## ISSUE: Not dropped
      }

      $u1 = $u1->get_absolute_reference ($_[3]);
      $u2 = $u2->get_absolute_reference ($_[3]);

      if (exists $fallback_uris->{$u1->uri_reference}) {
        $onerror->(type => 'duplicate oc namespace',
                   level => $must_level, line => $line_number, column => 1,
                   index => 0, value => $u1->uri_reference);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }
      
      unless ($same_shp->($u1)) {
        $onerror->(type => 'different shp from manifest',
                   level => $must_level, line => $line_number, column => 1,
                   index => 0, value => $u1->uri_reference);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      my $u2_scheme = $u2->uri_scheme;
      unless (defined $u2_scheme and $u2_scheme eq $m_scheme) {
        $onerror->(type => 'different scheme from manifest',
                   level => $warn_level, line => $line_number, column => 1,
                   index => 1, value => $u2->uri_reference);
        next START_OF_LINE;
      }

      $fallback_uris->{$u1->uri_reference} = $u2->uri_reference;
    } elsif ($mode eq 'online whitelist') {
      my $uri = Message::DOM::DOMImplementation->create_uri_reference ($line);

      unless ($uri->is_iri_reference_3987) {
        $onerror->(type => 'URI::syntax error:iriref3987',
                   level => $must_level, line => $line_number, column => 1,
                   value => $line);
        next START_OF_LINE; ## NOTE: MUST in syntax.
      }

      $uri = $uri->get_absolute_reference ($_[3]);

      if (defined $uri->uri_fragment) {
        $uri->uri_fragment (undef);
        $onerror->(type => 'URI fragment not allowed',
                   level => $must_level, line => $line_number, column => 1,
                   value => $line);
        ## NOTE: MUST in writing section.
      }

      my $scheme = $uri->uri_scheme;
      unless (defined $scheme and $scheme eq $m_scheme) {
        $onerror->(type => 'different scheme from manifest',
                   level => $warn_level, line => $line_number, column => 1,
                   value => $uri->uri_reference);
        next START_OF_LINE;
      }

      push @$online_whitelist_uris, $uri->uri_reference;      
    }

    ## Step 21
    #next START_OF_LINE;
  } # START_OF_LINE

  ## Step 22
  return [$explicit_uris, $fallback_uris, $online_whitelist_uris];
} # _parse

sub check_manifest ($$$) {
  my (undef, $manifest, $onerror) = @_;

  my $listed = {};
  my $must_level = 'm';

  require Whatpm::URIChecker;

  for my $uri (@{$manifest->[0]}) {
    $listed->{$uri} = 1;

    Whatpm::URIChecker->check_iri_reference ($uri, sub {
      my %opt = @_;
      $onerror->(level => $opt{level}, value => $uri,
                 type => 'URI::'.$opt{type}.
                 (defined $opt{position} ? ':'.$opt{position} : ''));
    });
  }

  for my $uri (values %{$manifest->[1]}) {
    $listed->{$uri} = 1;

    Whatpm::URIChecker->check_iri_reference ($uri, sub {
      my %opt = @_;
      $onerror->(level => $opt{level}, index => 1, value => $uri,
                 type => 'URI::'.$opt{type}.
                 (defined $opt{position} ? ':'.$opt{position} : ''));
    });
  }

  for my $uri (keys %{$manifest->[1]}) { 
    Whatpm::URIChecker->check_iri_reference ($uri, sub {
      my %opt = @_;
      $onerror->(level => $opt{level}, index => 0, value => $uri,
                 type => 'URI::'.$opt{type}.
                 (defined $opt{position} ? ':'.$opt{position} : ''));
    });
  }

  for my $uri (@{$manifest->[2]}) {
    if ($listed->{$uri}) {
      $onerror->(type => 'both in entries and whitelist',
                 level => $must_level, value => $uri);
      ## NOTE: MUST in writing section.
    }

    Whatpm::URIChecker->check_iri_reference ($uri, sub {
      my %opt = @_;
      $onerror->(level => $opt{level}, value => $uri,
                 type => 'URI::'.$opt{type}.
                 (defined $opt{position} ? ':'.$opt{position} : ''));
    });
  }
} # check_manifest


=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2007/11/23 14:47:49 $
