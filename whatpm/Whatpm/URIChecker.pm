package Whatpm::URIChecker;
use strict;

require Encode;

our $DefaultPort = {
  http => 80,
};

my $default_error_levels = {
  uri_fact => 'm',
  uri_lc_must => 'm', ## Non-RFC 2119 "must" (or fact)
  uri_lc_should => 'w', ## Non-RFC 2119 "should"
  uri_syntax => 'm',

  rdf_fact => 'm',

  uncertain => 'u',
};

sub check_iri ($$$;$) {
  require Message::URI::URIReference;
  my $dom = Message::DOM::DOMImplementation->new;
  my $uri_o = $dom->create_uri_reference ($_[1]);
  my $uri_s = $uri_o->uri_reference;

  local $Error::Depth = $Error::Depth + 1;

  unless ($uri_o->is_iri_3987) {
    $_[2]->(type => 'syntax error:iri3987',
            level => ($_[3] or $default_error_levels)->{uri_syntax});
  }

  Whatpm::URIChecker->check_iri_reference ($_[1], $_[2], $_[3]);
} # check_iri

sub check_iri_reference ($$$;$) {
  my $onerror = $_[2];
  my $levels = $_[3] || $default_error_levels;

  require Message::DOM::DOMImplementation;
  my $dom = Message::DOM::DOMImplementation->new;
  my $uri_o = $dom->create_uri_reference ($_[1]);
  my $uri_s = $uri_o->uri_reference;

  ## RFC 3987 4.1.
  unless ($uri_o->is_iri_reference_3987) {
    $onerror->(type => 'syntax error:iriref3987',
               level => $levels->{uri_syntax});
    ## MUST (NOTE: A requirement for bidi IRIs.)
  }
  
  ## RFC 3986 2.1., 6.2.2.1., RFC 3987 5.3.2.1.
  pos ($uri_s) = 0;
  while ($uri_s =~ /%([a-f][0-9A-Fa-f]|[0-9A-F][a-f])/g) {
    $onerror->(type => 'URL:lowercase hexadecimal digit',
               position => $-[0] + 1, level => $levels->{uri_lc_should});
    ## shoult not
  }

  ## RFC 3986 2.2.
  ## URI producing applications should percent-encode ... reserved ...
  ## unless ... allowed by the URI scheme .... --- This is not testable.

  ## RFC 3986 2.3., 6.2.2.2., RFC 3987 5.3.2.3.
  pos ($uri_s) = 0;
  while ($uri_s =~ /%(2[DdEe]|4[1-9A-Fa-f]|5[AaFf]|6[1-9A-Fa-f]|7[AaEe])/g) {
    $onerror->(type => 'URL:percent-encoded unreserved',
               position => $-[0] + 1, level => $levels->{uri_lc_should});
    ## should
    ## should
  }

  ## RFC 3986 2.4.
  ## ... "%" ... must be percent-encoded as "%25" ...
  ## --- Either syntax error or undetectable if followed by two hexadecimals

  ## RFC 3986 3.1., 6.2.2.1., RFC 3987 5.3.2.1.
  my $scheme = $uri_o->uri_scheme;
  my $scheme_canon;
  if (defined $scheme) {
    $scheme_canon = Encode::encode ('utf8', $scheme);
    $scheme_canon =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack 'C', hex $1/ge;
    if ($scheme_canon =~ tr/A-Z/a-z/) {
      $onerror->(type => 'URL:uppercase scheme name',
                 level => $levels->{uri_lc_should});
      ## should
    }
  }

  ## Note that nothing prevent a conforming URI (if there is one)
  ## using an unregistered URI scheme...

  ## RFC 3986 3.2.1., 7.5.
  my $ui = $uri_o->uri_userinfo;
  if (defined $ui and $ui =~ /:/) {
    $onerror->(type => 'URL:password', level => $levels->{uri_lc_should});
    ## deprecated
  }

  ## RFC 3986 3.2.2., 6.2.2.1., RFC 3987 5.3.2.1.
  my $host = $uri_o->uri_host;
  if (defined $host) {
    if ($host =~ /^\[([vV][0-9A-Fa-f]+)\./) {
      $onerror->(type => 'URL:address format',
                 value => $1, level => $levels->{uncertain});
    }
    my $hostnp = $host;
    $hostnp =~ s/%([0-9A-Fa-f][0-9A-Fa-f])//g;
    if ($hostnp =~ /[A-Z]/) {
      $onerror->(type => 'URL:uppercase host',
                 level => $levels->{uri_lc_should},
                 value => $host);
      ## should
    }
      
    if ($host =~ /^\[/) {
      #
    } else {
      $host = Encode::encode ('utf8', $host);
      $host =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack 'C', hex $1/ge;

      if ($host eq '') {
        ## NOTE: Although not explicitly mentioned, an empty host
        ## should be considered as an exception for the recommendation
        ## that a host "should" be a DNS name.
      } elsif ($host !~ /\A(?>[A-Za-z0-9](?>[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(?>\.(?>[A-Za-z0-9](?>[A-Za-z0-9-]{0,61}[A-Za-z0-9])?))*\.?\z/) {
        $onerror->(type => 'URL:non-DNS host',
                   level => $levels->{uri_lc_should});
        ## should
        ## should be IDNA encoding if wish to maximize interoperability
      } elsif (length $host > 255) {
        ## NOTE: This length might be incorrect if there were percent-encoded
        ## UTF-8 bytes; however, the above condition catches all non-ASCII.
        $onerror->(type => 'URL:long host',
                   level => $levels->{uri_lc_should});
        ## should
      }
      
      ## FQDN should be followed by "." if necessary --- untestable
      
      ## must be UTF-8
      unless ($host =~ /\A(?>
          [\x00-\x7F] |
          [\xC2-\xDF][\x80-\xBF] |                          # UTF8-2
          [\xE0][\xA0-\xBF][\x80-\xBF] |
          [\xE1-\xEC][\x80-\xBF][\x80-\xBF] |
          [\xED][\x80-\x9F][\x80-\xBF] |
          [\xEE\xEF][\x80-\xBF][\x80-\xBF] |                # UTF8-3
          [\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
          [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
          [\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]           # UTF8-4
      )*\z/x) {
        $onerror->(type => 'URL:non UTF-8 host',
                   level => $levels->{uri_lc_must});
        # must
      }
    }
  }

  ## RFC 3986 3.2., 3.2.3., 6.2.3., RFC 3987 5.3.3.
  my $port = $uri_o->uri_port;
  if (defined $port) {
    if ($port =~ /\A([0-9]+)\z/) {
      if ($DefaultPort->{$scheme_canon} == $1) {
        $onerror->(type => 'URL:default port',
                   level => $levels->{uri_lc_should});
        ## should
      }
    } elsif ($port eq '') {
      $onerror->(type => 'URL:empty port',
                 level => $levels->{uri_lc_should});
      ## should
    }
  }

  ## RFC 3986 3.4.
  ## ... says that "/" or "?" in query might be problematic for
  ## old implementations, but also suggest that for readability percent-encoding
  ## might not be good idea.  It provides no recommendation on this issue.
  ## Therefore, we do no check for this matter.

  ## RFC 3986 3.5.
  ## ... says again that "/" or "?" in fragment might be problematic,
  ## without any recommendation. 
  ## We again left this unchecked.

  ## RFC 3986 4.4.
  ## Authors should not assume ... different, though equivalent, 
  ## URI will (or will not) be interpreted as a same-document reference ...
  ## This is not testable.

  ## RFC 3986 5.4.2.
  ## "scheme:relative" should be avoided
  ## This is not testable without scheme specific information.

  ## RFC 3986 6.2.2.3., RFC 3987 5.3.2.4.
  my $path = $uri_o->uri_path;
  if (defined $scheme) {
    if (
        $path =~ m!/\.\.! or
        $path =~ m!/\./! or
        $path =~ m!/\.\.\z! or
        $path =~ m!/\.\z! or
        $path =~ m!\A\.\./! or
        $path =~ m!\A\./! or
        $path eq '.,' or
        $path eq '.'
       ) {
      $onerror->(type => 'URL:dot-segment',
                 level => $levels->{uri_lc_should});
      ## should
    }
  }

  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  my $authority = $uri_o->uri_authority;
  if (defined $authority) {
    if ($path eq '') {
      $onerror->(type => 'URL:empty path', 
                 level => $levels->{uri_lc_should});
      ## should
    }
  }

  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  ## Scheme dependent default authority should be omitted
  
  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  if (defined $host and $host eq '' and
      (defined $ui or defined $port)) {
    $onerror->(type => 'URL:empty host',
               level => $levels->{uri_lc_should});
    ## should # when empty authority is allowed
  }

  ## RFC 3986 7.5.
  ## should not ... username or password that is intended to be secret
  ## This is not testable.

  ## RFC 3987 4.1.
  ## MUST be in full logical order
  ## This is not testable.

  ## RFC 3987 4.1., 6.4.
  ## URI scheme dependent syntax
  ## MUST
  ## TODO

  ## RFC 3987 4.2.
  ## iuserinfo, ireg-name, isegment, isegment-nz, isegment-nz-nc, iquery, ifragment
  ## SHOULD NOT use both rtl and ltr characters
  ## SHOULD start with rtl if using rtl characters
  ## TODO

  ## RFC 3987 5.3.2.2. 
  ## SHOULD be NFC
  ## NFKC may avoid even more problems
  ## TODO

  ## RFC 3987 5.3.3.
  ## IDN (ireg-name or elsewhere) SHOULD be validated by ToASCII(UseSTD3ASCIIRules, AllowUnassigned)
  ## SHOULD be normalized by Nameprep
  ## TODO

  ## TODO: If it is a relative reference, then resolve and then check against scheme dependent requirements
} # check_iri_reference

sub check_rdf_uri_reference ($$$;$) {
  require Message::URI::URIReference;
  my $dom = Message::DOM::DOMImplementation->new;
  my $uri_o = $dom->create_uri_reference ($_[1]);
  my $uri_s = $uri_o->uri_reference;

  my $levels = $_[3] || $default_error_levels;

  if ($uri_s =~ /[\x00-\x1F\x7F-\x9F]/) {
    $_[2]->(type => 'syntax error:rdfuriref',
            level => $levels->{rdf_fact},
            position => $-[0]);
  }

  my $ascii_uri_o = $uri_o->get_uri_reference_3986; # same as RDF spec's one

  unless ($ascii_uri_o->is_uri) { ## TODO: is_uri_2396 should be used.
    $_[2]->(#type => 'syntax error:uri2396',
            type => 'syntax error:uri3986',
            level => $levels->{uri_fact},
            value => $ascii_uri_o->uri_reference);
  }

  ## TODO: Check against RFC 2396.
  #Whatpm::URIChecker->check_iri_reference ($_[1], $_[2], $_[3]);
} # check_rdf_uri_reference

1;
## $Date: 2008/08/30 04:31:57 $
