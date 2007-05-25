package Whatpm::URIChecker;
use strict;

sub check_iri_reference ($$$) {
  my $onerror = $_[2];

  require Message::URI::URIReference; ## From manakai
  my $dom = 'Message::DOM::DOMImplementation'; ## ISSUE: This is not a formal way to instantiate it.

  my $uri_o = $dom->create_uri_reference ($_[1]);
  my $uri_s = $uri_o->uri_reference;

  local $Error::Depth = $Error::Depth + 1;

  unless ($uri_o->is_iri_reference_3987) {
    $onerror->(type => 'syntax error', level => 'm');
  }
  
  ## RFC 3986 2.1.
  while ($uri_s =~ /%([a-f][0-9A-Fa-f]|[0-9A-F][a-f])/g) {
    $onerror->(type => 'lowercase hexadecimal digit',
               position => $-[0] + 1, level => 's');
    ## shoult not
  }

  ## RFC 3986 2.2.
  ## URI producing applications should percent-encode ... reserved ...
  ## unless ... allowed by the URI scheme .... --- This is not testable.

  ## RFC 3986 2.3.
  while ($uri_s =~ /%(2[DdEe]|4[1-9A-Fa-f]|5[AaFf]|6[1-9A-Fa-f]|7[AaEe])/g) {
    $onerror->(type => 'percent-encoded unreserved',
               position => $-[0] + 1, level => 's');
    ## should not
  }

  ## RFC 3986 2.4.
  ## ... "%" ... must be percent-encoded as "%25" ...
  ## --- Either syntax error or undetectable if followed by two hexadecimals

  ## RFC 3986 3.1.
  my $scheme = $uri_o->uri_scheme;
  if (defined $scheme) {
    $scheme =~ s/%([0-9A-Fa-f][0-9A-Fa-f])//g;
    if ($scheme =~ /[A-Z]/) {
      $onerror->(type => 'uppercase scheme name',
                 position => 1, level => 's');
      ## lowercase is the canonical form
    }
  }

  ## Note that nothing prevent a conforming URI (if there is one)
  ## using an unregistered URI scheme...

  ## RFC 3986 3.2.
  my $port = $uri_o->uri_port;
  if (defined $port and $port eq '') {
    $onerror->(type => 'empty port', level => 's');
    ## should not
  }

  ## RFC 3986 3.2.1.
  my $ui = $uri_o->uri_userinfo;
  if (defined $ui and $ui =~ /:/) {
    $onerror->(type => 'password', level => 's');
    ## deprecated
  }

  ## RFC 3986 3.2.2.
  my $host = $uri_o->uri_host;
  if (defined $host) {
    if ($host =~ /^\[([vV][0-9A-Fa-f]+)\./) {
      $onerror->(type => 'address format not supported:'.$1,
                 level => 'w');
      ## NOTE: The canonical form of |"v" 1*HEXDIG| is not defined.
    } else {
      my $hostnp = $host;
      $hostnp =~ s/%([0-9A-Fa-f][0-9A-Fa-f])//g;
      if ($hostnp =~ /[A-Z]/) {
        $onerror->(type => 'uppercase host',
                   level => 's');
        ## should (reg-name and hexadecimal address)
      }
      
      if ($host =~ /^\[/) {
        #
      } else {
        $host =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack 'C', hex $1/ge;
      
        if ($host !~ /\A(?>[A-Za-z0-9](?>[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(?>\.(?>[A-Za-z0-9](?>[A-Za-z0-9-]{0,61}[A-Za-z0-9])?))*\.?\z/) {
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
        if (1) {

=pod

 TODO:

[\xC2-\xDF][\x80-\xBF] |                          # UTF8-2
    [\xE0][\xA0-\xBF][\x80-\xBF] |
    [\xE1-\xEC][\x80-\xBF][\x80-\xBF] |
    [\xED][\x80-\x9F][\x80-\xBF] |
    [\xEE\xEF][\x80-\xBF][\x80-\xBF] |                # UTF8-3
    [\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |           # UTF8-4
    [\x80-\xFF]          


=cut

        }
      }
    }
  }


  

} # check_iri_reference

1;
## $Date: 2007/05/25 12:13:55 $
