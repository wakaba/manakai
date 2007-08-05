package Whatpm::URIChecker;
use strict;

require Encode;

our $DefaultPort = {
  http => 80,
};

sub check_iri ($$$) {
  require Message::URI::URIReference;
  my $dom = Message::DOM::DOMImplementation->new;
  my $uri_o = $dom->create_uri_reference ($_[1]);
  my $uri_s = $uri_o->uri_reference;

  local $Error::Depth = $Error::Depth + 1;

  unless ($uri_o->is_iri_3987) {
    $_[2]->(type => 'syntax error:iri3987', level => 'm');
    ## MUST
  }

  Whatpm::URIChecker->check_iri_reference ($_[1], $_[2]);
} # check_iri

sub check_iri_reference ($$$) {
  my $onerror = $_[2];

  require Message::URI::URIReference;
  my $dom = Message::DOM::DOMImplementation->new;
  my $uri_o = $dom->create_uri_reference ($_[1]);
  my $uri_s = $uri_o->uri_reference;

  local $Error::Depth = $Error::Depth + 1;

  ## RFC 3987 4.1.
  unless ($uri_o->is_iri_reference_3987) {
    $onerror->(type => 'syntax error:iriref3987', level => 'm');
    ## MUST
  }
  
  ## RFC 3986 2.1., 6.2.2.1., RFC 3987 5.3.2.1.
  pos ($uri_s) = 0;
  while ($uri_s =~ /%([a-f][0-9A-Fa-f]|[0-9A-F][a-f])/g) {
    $onerror->(type => 'lowercase hexadecimal digit',
               position => $-[0] + 1, level => 's');
    ## shoult not
  }

  ## RFC 3986 2.2.
  ## URI producing applications should percent-encode ... reserved ...
  ## unless ... allowed by the URI scheme .... --- This is not testable.

  ## RFC 3986 2.3., 6.2.2.2., RFC 3987 5.3.2.3.
  pos ($uri_s) = 0;
  while ($uri_s =~ /%(2[DdEe]|4[1-9A-Fa-f]|5[AaFf]|6[1-9A-Fa-f]|7[AaEe])/g) {
    $onerror->(type => 'percent-encoded unreserved',
               position => $-[0] + 1, level => 's');
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
      $onerror->(type => 'uppercase scheme name', level => 's');
      ## should
    }
  }

  ## Note that nothing prevent a conforming URI (if there is one)
  ## using an unregistered URI scheme...

  ## RFC 3986 3.2.1., 7.5.
  my $ui = $uri_o->uri_userinfo;
  if (defined $ui and $ui =~ /:/) {
    $onerror->(type => 'password', level => 's');
    ## deprecated
  }

  ## RFC 3986 3.2.2., 6.2.2.1., RFC 3987 5.3.2.1.
  my $host = $uri_o->uri_host;
  if (defined $host) {
    if ($host =~ /^\[([vV][0-9A-Fa-f]+)\./) {
      $onerror->(type => 'address format:'.$1, level => 'unsupported');
    }
    my $hostnp = $host;
    $hostnp =~ s/%([0-9A-Fa-f][0-9A-Fa-f])//g;
    if ($hostnp =~ /[A-Z]/) {
      $onerror->(type => 'uppercase host',
                 level => 's');
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
        $onerror->(type => 'non-DNS host', level => 's');
        ## should
        ## should be IDNA encoding if wish to maximize interoperability
      } elsif (length $host > 255) {
        ## NOTE: This length might be incorrect if there were percent-encoded
        ## UTF-8 bytes; however, the above condition catches all non-ASCII.
        $onerror->(type => 'long host', level => 's');
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
        $onerror->(type => 'non UTF-8 host', level => 'm');
        # must
      }
    }
  }

  ## RFC 3986 3.2., 3.2.3., 6.2.3., RFC 3987 5.3.3.
  my $port = $uri_o->uri_port;
  if (defined $port) {
    if ($port =~ /\A([0-9]+)\z/) {
      if ($DefaultPort->{$scheme_canon} == $1) {
        $onerror->(type => 'default port', level => 's');
        ## should
      }
    } elsif ($port eq '') {
      $onerror->(type => 'empty port', level => 's');
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
      $onerror->(type => 'dot-segment', level => 's');
      ## should
    }
  }

  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  my $authority = $uri_o->uri_authority;
  if (defined $authority) {
    if ($path eq '') {
      $onerror->(type => 'empty path', level => 's');
      ## should
    }
  }

  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  ## Scheme dependent default authority should be omitted
  
  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  if (defined $host and $host eq '' and
      (defined $ui or defined $port)) {
    $onerror->(type => 'empty host', level => 's');
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

1;
## $Date: 2007/08/05 07:12:45 $
