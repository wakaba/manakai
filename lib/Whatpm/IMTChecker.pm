package Whatpm::IMTChecker;
use strict;

## NOTE: RFC 2046 sucks, it is a poorly written specification such that
## what we should do is not entirely clear and it does define almost nothing
## from the today's viewpoint...  Suprisingly, it's even worse than
## RFC 1521, the previous version of that specification, which does
## contain BNF rules for parameter values at least.

my $default_error_levels = {
  must => 'm',
  warn => 'w',
  info => 'i',
  uncertain => 'u',

  mime_must => 'm', # lowercase "must"
  mime_fact => 'm',
  mime_strongly_discouraged => 'w',
  mime_discouraged => 'w',
};

our $Type;

my $application_xml_charset = { ## TODO: ...
  syntax => 'token',
  registered => 1,
};

$Type->{application}->{registered} = 1;

$Type->{application}->{subtype}->{'atom+xml'} = { ## NOTE: RFC 4287
  parameter => {
    type => { ## NOTE: RFC 5023
      ## TODO: "entry"|"feed" (case-insensitive)
      registered => 1,
      ## NOTE: SHOULD for Atom Entry Document.
    },
  },
  registered => 1,
};

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

$Type->{application}->{subtype}->{xml} = { ## TODO: check IANAREG
  registered => 1,
};

$Type->{audio}->{registered} = 1;

$Type->{audio}->{subtype}->{basic} = { ## TODO: check IANAREG
  registered => 1,
};

$Type->{audio}->{subtype}->{mpeg} = { ## TODO: check IANAREG
  registered => 1,
};

$Type->{image}->{registered} = 1;

$Type->{image}->{subtype}->{jpeg} = { ## TODO: check IANAREG
  registered => 1,
};

$Type->{image}->{subtype}->{png} = { ## TODO: check IANAREG
  registered => 1,
};

$Type->{image}->{subtype}->{'svg+xml'} = { ## TODO: check IANAREG
  registered => 1,
};

$Type->{message}->{registered} = 1;

$Type->{model}->{registered} = 1;

$Type->{multipart}->{registered} = 1;

$Type->{text}->{registered} = 1;

$Type->{text}->{subtype}->{plain} = {
  parameter => {
    charset => {syntax => 'token', registered => 1}, # RFC 2046 ## TODO: registered?
    'charset-edition' => {registered => 1}, # RFC 1922
    'charset-extension' => {syntax => 'token', registered => 1}, # RFC 1922 ## TODO: registered?
  },
  registered => 1,
};
$Type->{text}->{subtype}->{html} = { # RFC 2854
  parameter => {
    charset => {registered => 1}, ## TODO: UTF-8 is preferred ## TODO: strongly recommended that it always be present ## NOTE: Syntax and range are not defined.
    level => {obsolete => 'mime_fact'}, # RFC 1866
    version => {obsolete => 'mime_fact'}, # HTML 3.0
  },
  registered => 1,
};
$Type->{text}->{subtype}->{css} = { # RFC 2318
  parameter => {
    charset => {registered => 1}, ## TODO: US-ASCII, iso-8859-X, utf-8 are recommended ## TODO: Any charset that is a superset of US-ASCII may be used ## NOTE: Syntax and range are not defined.
  },
  registered => 1,
};
$Type->{text}->{subtype}->{javascript} = { # RFC 4329
  parameter => {
    charset => {syntax => 'mime-charset', registered => 1}, ## TODO: SHOULD be registered
    e4x => {checker => sub { # HTML5 (but informative?)
      my ($self, $value, $onerror) = @_;
      unless ($value eq '1') {
        $onerror->(type => 'e4x:syntax error',
                   level => $self->{level}->{info},
                   value => $value);
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
  registered => 1,
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
    conversions => {obsolete => 'mime_fact',
                    registered => 1}, # RFC 1341 ## TODO: syntax
    name => {obsolete => 'mime_fact', registered => 1}, # RFC 1341
    padding => {registered => 1}, # RFC 2046
    type => {registered => 1}, # RFC 2046
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
    my ($self, $value, $onerror) = @_;
    if ($value !~ /\A[0-9A-Za-z'()+_,.\x2F:=?-]{0,69}[0-9A-Za-z'()+_,.\x2F:=?\x20-]\z/) {
      $onerror->(type => 'boundary:syntax error',
                 level => $self->{level}->{mime_fact}, # TODO: correct?
                 value => $value);
    }
  },
  required => 1,
  registered => 1,
};
$Type->{message}->{subtype}->{partial} = {
  parameter => {
    id => {required => 1, registered => 1}, # RFC 2046
    number => {required => 1, registered => 1}, # RFC 2046
    total => {registered => 1}, # RFC 2046 # required for the last fragment
  },
  registered => 1,
};
$Type->{message}->{subtype}->{'external-body'} = {
  parameter => {
    'access-type' => {
      required => 1,
      syntax => 'token', ## TODO: registry?
      registered => 1,
    }, # RFC 2046
    expiration => {syntax => 'MIME date-time', registered => 1}, # RFC 2046
    permission => {registered => 1}, # RFC 2046
    size => {registered => 1}, # RFC 2046
    ## TODO: access-type dependent parameters
  },
  registered => 1,
};

sub new ($) {
  my $self = bless {}, shift;

  $self->{level} = $default_error_levels;

  return $self;
} # new

sub check_imt ($$$$@) {
  my $self = ref $_[0] ? shift : shift->new;
  my ($onerror, $type, $subtype, @parameter) = @_;

  require Message::IMT::InternetMediaType;
  my $dom = Message::DOM::DOMImplementation->new;

  my $imt = $dom->create_internet_media_type ($type, $subtype);
  while (@parameter) {
    $imt->add_parameter (shift @parameter => shift @parameter);
    ## NOTE: Attribute duplication are not error, though its semantics
    ## is not defined.
    ## See <http://suika.fam.cx/gate/2005/sw/%E5%AA%92%E4%BD%93%E5%9E%8B/%E5%BC%95%E6%95%B0>.
  }

  my $type = $imt->top_level_type;
  my $subtype = $imt->subtype;

  ## NOTE: RFC 2045 (MIME), RFC 2616 (HTTP/1.1), and RFC 4288 (IMT
  ## registration) have different requirements on type and subtype names.
  if ($type !~ /\A[A-Za-z0-9!#\$&.+^_-]{1,127}\z/) {
    $onerror->(type => 'IMT:type syntax error',
               level => $self->{level}->{must}, # RFC 4288 4.2.
               value => $type);
  }
  if ($subtype !~ /\A[A-Za-z0-9!#\$&.+^_-]{1,127}\z/) {
    $onerror->(type => 'IMT:subtype syntax error',
               level => $self->{level}->{must}, # RFC 4288 4.2.
               value => $subtype);
  }

  my $type_def = $Type->{$type};
  my $has_param;

  if ($type =~ /^x-/) {
    $onerror->(type => 'IMT:private type',
               level => $self->{level}->{mime_strongly_discouraged},
               value => $type); # RFC 2046 6.
    ## NOTE: "discouraged" in RFC 4288 3.4.
  } elsif (not $type_def or not $type_def->{registered}) {
  #} elsif ($type_def and not $type_def->{registered}) {
    ## NOTE: Top-level type is seldom added.
    
    ## NOTE: RFC 2046 6. "Any format without a rigorous and public
    ## definition must be named with an "X-" prefix" (strictly, this
    ## is not an author requirement, but a requirement for media
    ## type specfication author and it does not restrict use of 
    ## unregistered value).
    $onerror->(type => 'IMT:unregistered type',
               level => $self->{level}->{mime_must},
               value => $type);
  }

  if ($type_def) {
    my $subtype_def = $type_def->{subtype}->{$subtype};

    if ($subtype =~ /^x[-\.]/) {
      $onerror->(type => 'IMT:private subtype',
                 level => $self->{level}->{mime_discouraged},
                 value => $type . '/' . $subtype);
      ## NOTE: "x." and "x-" are discouraged in RFC 4288 3.4.
    } elsif ($subtype_def and not $subtype_def->{registered}) {
      ## NOTE: RFC 2046 6. "Any format without a rigorous and public
      ## definition must be named with an "X-" prefix" (strictly, this
      ## is not an author requirement, but a requirement for media
      ## type specfication author and it does not restrict use of
      ## unregistered value).
      $onerror->(type => 'IMT:unregistered subtype',
                 level => $self->{level}->{mime_must},
                 value => $type . '/' . $subtype);
    }
    
    if ($subtype_def) {
      ## NOTE: Semantics (including its relationship between conformance)
      ## is not defined for the "intended usage" keywords of the IMT
      ## registration template.
      if ($subtype_def->{obsolete}) {
        $onerror->(type => 'IMT:obsolete subtype',
                   level => $self->{level}->{warn},
                   value => $type . '/' . $subtype);
      } elsif ($subtype_def->{limited_use}) {
        $onerror->(type => 'IMT:limited use subtype',
                   level => $self->{level}->{warn},
                   value => $type . '/' . $subtype);        
      }

      for (0..$imt->parameter_length-1) {
        my $attr = $imt->get_attribute ($_);
        my $value = $imt->get_value ($_);

        if ($attr !~ /\A[A-Za-z0-9!#\$&.+^_-]{1,127}\z/) {
          $onerror->(type => 'IMT:attribute syntax error',
                     level => $self->{level}->{mime_fact}, # RFC 4288 4.3.
                     value => $attr);
        }

        $has_param->{$attr} = 1;
        my $param_def = $subtype_def->{parameter}->{$attr}
          || $type_def->{parameter}->{$attr};
        if ($param_def) {
          if (defined $param_def->{syntax}) {
            if ($param_def->{syntax} eq 'mime-charset') { # RFC 2978
              ## TODO: ...
              if ($value =~ /[^A-Za-z0-9!#\x23%&'+^_`{}~-]/) {
                $onerror->(type => 'value syntax error:'.$attr, level => 'm');
              }
            } elsif ($param_def->{syntax} eq 'token') { # RFC 2046
              ## TODO: ...
              if ($value =~ /[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/) {
                $onerror->(type => 'value syntax error:'.$attr, level => 'm');
              }
            }
            ## TODO: syntax |MIME date-time|
          } elsif ($param_def->{checker}) {
            $param_def->{checker}->($self, $value, $onerror);
          }
           
          if ($param_def->{obsolete}) {
            $onerror->(type => 'IMT:obsolete parameter',
                       level => $self->{level}->{$param_def->{obsolete}},
                       value => $attr);
            ## NOTE: The value of |$param_def->{obsolete}|, if it has a
            ## true value, must be "mime_fact", which represents that
            ## the parameter is defined in a previous version of the MIME
            ## specification (or a related specification) and then
            ## removed or marked as obsolete such that it seems that use of
            ## that parameter is made non-conforming without using any
            ## explicit statement on that fact.
          }
        }
        if (not $param_def or not $param_def->{registered}) {
          if ($subtype =~ /\./ or $subtype =~ /^x-/ or $type =~ /^x-/) {
            ## NOTE: The parameter names SHOULD be fully specified for
            ## personal or vendor tree subtype [RFC 4288].  Therefore, there
            ## might be unknown parameters and still conforming.
            $onerror->(type => 'IMT:unknown parameter',
                       level => $self->{level}->{uncertain},
                       value => $attr);
          } else {
            ## NOTE: The parameter names MUST be fully specified for
            ## standard tree.  Therefore, unknown parameter is non-conforming,
            ## unless it is standardized later.
            $onerror->(type => 'IMT:parameter not allowed',
                       level => $self->{level}->{mime_fact},
                       value => $attr);
          }
        }
      }

      for (keys %{$subtype_def->{parameter} or {}}) {
        if ($subtype_def->{parameter}->{$_}->{required} and
            not $has_param->{$_}) {
          $onerror->(type => 'IMT:parameter missing',
                     level => $self->{level}->{mime_fact},
                     text => $_,
                     value => $type . '/' . $subtype);
        }
      }
    } else {
      ## NOTE: Since subtypes are frequently added to the IANAREG and such
      ## that our database might be out-of-date, we don't raise an error
      ## for an unknown subtype, instead we report an "uncertain" status.
      $onerror->(type => 'IMT:unknown subtype',
                 level => $self->{level}->{uncertain},
                 value => $type . '/' . $subtype);
    }

    for (keys %{$type_def->{parameter} or {}}) {
      if ($type_def->{parameter}->{$_}->{required} and
          not $has_param->{$_}) {
        $onerror->(type => 'IMT:parameter missing',
                   level => $self->{level}->{mime_fact},
                   text => $_,
                   value => $type . '/' . $subtype);
      }
    }
  }
} # check_imt

1;
## $Date: 2008/12/12 05:05:20 $
