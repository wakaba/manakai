package Whatpm::IMTChecker;
use strict;

## ISSUE: RFC 2046 is so poorly written specification that
## what we should do is unclear...  It's even worse than
## RFC 1521, which contains BNF rules for parameter values.

our $Type;

my $application_xml_charset = { ## TODO: ...
  syntax => 'token',
};

$Type->{application}->{registered} = 1;

$Type->{application}->{subtype}->{'rdf+xml'} = { # RFC 3870
  parameter => {
    charset => $application_xml_charset,
  },
  registered => 1,

  ## RECOMMENDED that an RDF document follows new RDF/XML spec
  ## rather than 1999 spec - this is not testable in this layer.
};

$Type->{application}->{subtype}->{'rss+xml'} = {
  parameter => {
  },
  ## NOTE: Not registered
};

$Type->{audio}->{registered} = 1;

$Type->{image}->{registered} = 1;

$Type->{message}->{registered} = 1;

$Type->{model}->{registered} = 1;

$Type->{multipart}->{registered} = 1;

$Type->{text}->{registered} = 1;

$Type->{text}->{subtype}->{plain} = {
  parameter => {
    charset => {syntax => 'token'}, # RFC 2046 ## TODO: registered?
    'charset-edition' => {}, # RFC 1922
    'charset-extension' => {syntax => 'token'}, # RFC 1922 ## TODO: registered?
  },
  registered => 1,
};
$Type->{text}->{subtype}->{html} = { # RFC 2854
  parameter => {
    charset => {}, ## TODO: UTF-8 is preferred ## TODO: strongly recommended that it always be present ## NOTE: Syntax and range are not defined.
    level => {obsolete =>1}, # RFC 1866
    version => {obsolete => 1}, # HTML 3.0
  },
  registered => 1,
};
$Type->{text}->{subtype}->{css} = { # RFC 2318
  parameter => {
    charset => {}, ## TODO: US-ASCII, iso-8859-X, utf-8 are recommended ## TODO: Any charset that is a superset of US-ASCII may be used ## NOTE: Syntax and range are not defined.
  },
  registered => 1,
};
$Type->{text}->{subtype}->{javascript} = { # RFC 4329
  parameter => {
    charset => {syntax => 'mime-charset'}, ## TODO: SHOULD be registered
    e4x => {checker => sub { # HTML5 (but informative?)
      my ($value, $onerror) = @_;
      unless ($value eq '1') {
        $onerror->(type => 'value syntax error:e4x', level => 'm');
        ## NOTE: Whether values other than "1" is non-conformant
        ## or not is not defined actually...
      }
    }},
  },
  obsolete => 1,
  registered => 1,
};
$Type->{text}->{subtype}->{ecmascript} = { # RFC 4329
  parameter => {
    charset => $Type->{text}->{subtype}->{javascript}->{parameter}->{charset},
  },
  registered => 1,
};
$Type->{audio}->{subtype}->{mpeg} = { # RFC 3003
  registered => 1,
};
my $CodecsParameter = { # RFC 4281
  ## TODO: syntax and value check
};
$Type->{audio}->{subtype}->{'3gpp'} = {
  parameter => {
    codecs => $CodecsParameter, # RFC 4281
  },
  registered => 1,
};

$Type->{video}->{registered} = 1;

$Type->{video}->{subtype}->{'3gpp'} = {
  parameter => {
    codecs => $CodecsParameter, # RFC 4281
  },
  registered => 1,
};
$Type->{audio}->{subtype}->{'3gpp2'} = { # RFC 4393
  parameter => {
    codecs => $CodecsParameter, # RFC 4393 -> RFC 4281
  },
  registered => 1,
};
$Type->{video}->{subtype}->{'3gpp2'} = { # RFC 4393
  parameter => {
    codecs => $CodecsParameter, # RFC 4393 -> RFC 4281
  },
  registered => 1,
};
$Type->{application}->{subtype}->{'octet-stream'} = {
  parameter => {
    conversions => {obsolete => 1}, # RFC 1341 ## TODO: syntax
    name => {obsolete => 1}, # RFC 1341
    padding => {}, # RFC 2046
    type => {}, # RFC 2046
  },
  registered => 1,
};
$Type->{application}->{subtype}->{javascript} = { # RFC 4329
  parameter => {
    charset => $Type->{text}->{subtype}->{javascript}->{parameter}->{charset},
  },
  registered => 1,
};
$Type->{application}->{subtype}->{ecmascript} = { # RFC 4329
  parameter => {
    charset => $Type->{text}->{subtype}->{ecmascript}->{parameter}->{charset},
  },
  registered => 1,
};
$Type->{multipart}->{parameter}->{boundary} = {
  checker => sub {
    my ($value, $onerror) = @_;
    if ($value !~ /\A[0-9A-Za-z'()+_,.\x2F:=?-]{0,69}[0-9A-Za-z'()+_,.\x2F:=?\x20-]\z/) {
      $onerror->(type => 'value syntax error:boundary', level => 'm');
    }
  },
  required => 1,
};
$Type->{message}->{subtype}->{partial} = {
  parameter => {
    id => {required => 1}, # RFC 2046
    number => {required => 1}, # RFC 2046
    total => {}, # RFC 2046 # required for the last fragment
  },
  registered => 1,
};
$Type->{message}->{subtype}->{'external-body'} = {
  parameter => {
    'access-type' => {
      required => 1,
      syntax => 'token', ## TODO: registry?
    }, # RFC 2046
    expiration => {syntax => 'MIME date-time'}, # RFC 2046
    permission => {}, # RFC 2046
    size => {}, # RFC 2046
    ## TODO: access-type dependent parameters
  },
  registered => 1,
};

sub check_imt ($$$$@) {
  my (undef, $onerror, $type, $subtype, @parameter) = @_;

  require Message::IMT::InternetMediaType; ## From manakai
  my $dom = 'Message::DOM::DOMImplementation'; ## ISSUE: This is not a formal way to instantiate it.

  local $Error::Depth = $Error::Depth + 1;

  my $imt = $dom->create_internet_media_type ($type, $subtype);
  while (@parameter) {
    $imt->add_parameter (shift @parameter => shift @parameter);
    ## NOTE: Attribute duplication are not error, though its semantics
    ## is not defined.
    ## See <http://suika.fam.cx/gate/2005/sw/%E5%AA%92%E4%BD%93%E5%9E%8B/%E5%BC%95%E6%95%B0>.
  }

  my $type = $imt->top_level_type;
  my $subtype = $imt->subtype;

  my $type_def = $Type->{$type};
  my $has_param;

  if ($type =~ /^x[-\.]/) { ## TODO: Is there x. tree?
    $onerror->(type => 'private type', level => 's'); ## TODO: What level?
  } elsif ($type_def and not $type_def->{registered}) {
    $onerror->(type => 'unregistered type', level => 's'); ## TODO: What level?
  }

  if ($type_def) {
    my $subtype_def = $type_def->{subtype}->{$subtype};

    if ($subtype =~ /^x[-\.]/) {
      $onerror->(type => 'private subtype', level => 's'); ## TODO: What level?
    } elsif ($subtype_def and not $subtype_def->{registered}) {
      $onerror->(type => 'unregistered subtype', level => 's'); ## TODO: What level?
    }
    if ($subtype_def->{obsolete}) {
      $onerror->(type => 'obsolete subtype', level => 's');
    }
    
    if ($subtype_def) {
      for (0..$imt->parameter_length-1) {
        my $attr = $imt->get_attribute ($_);
        my $value = $imt->get_value ($_);
        $has_param->{$attr} = 1;
        my $param_def = $subtype_def->{parameter}->{$attr}
          || $type_def->{parameter}->{$attr};
        if ($param_def) {
          if (defined $param_def->{syntax}) {
            if ($param_def->{syntax} eq 'mime-charset') { # RFC 2978
              if ($value =~ /[^A-Za-z0-9!#\x23%&'+^_`{}~-]/) {
                $onerror->(type => 'value syntax error:'.$attr, level => 'm');
              }
            } elsif ($param_def->{syntax} eq 'token') { # RFC 2046
              if ($value =~ /[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/) {
                $onerror->(type => 'value syntax error:'.$attr, level => 'm');
              }
            }
            ## TODO: syntax |MIME date-time|
            if ($param_def->{checker}) {
              $param_def->{checker}->($value, $onerror);
            }
            if ($param_def->{obsolete}) {
              $onerror->(type => 'obsolete parameter:'.$attr, level => 'm');
            }
          }
        } else {
          $onerror->(type => 'parameter:'.$attr, level => 'unsupported');
        }
      }

      for (keys %{$subtype_def->{parameter} or {}}) {
        if ($subtype_def->{parameter}->{$_}->{required} and
            not $has_param->{$_}) {
          $onerror->(type => 'parameter missing:'.$_, level => 'm');
        }
      }
    } else {
      $onerror->(type => 'subtype', level => 'unsupported');
    }

    for (keys %{$type_def->{parameter} or {}}) {
      if ($type_def->{parameter}->{$_}->{required} and
          not $has_param->{$_}) {
        $onerror->(type => 'parameter missing:'.$_, level => 'm');
      }
    }
  } else {
    $onerror->(type => 'type', level => 'unsupported');
  }
} # check_imt

1;
## $Date: 2007/06/30 13:12:33 $
