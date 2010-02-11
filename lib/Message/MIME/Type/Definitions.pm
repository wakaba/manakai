package Message::MIME::Type::Definitions;
use strict;
use warnings;
our $VERSION = '1.0';

our $Type;

my $application_xml_charset = { ## TODO: ...
  syntax => 'token',
  registered => 1,
};

## ------ |application| Media Types ------

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

$Type->{application}->{subtype}->{smil} = {
  registered => 1, # XXX?
};

$Type->{application}->{subtype}->{'smil+xml'} = {
  registered => 1, # XXX?
};

$Type->{application}->{subtype}->{'xhtml+xml'} = {
  registered => 1, # XXX?
};

$Type->{application}->{subtype}->{xml} = { ## TODO: check IANAREG
  registered => 1,
  is_text_based => 1,
};

$Type->{application}->{subtype}->{'xslt+xml'} = {
  is_styling_lang => 1,
};

## ------ |audio| Media Types ------

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

## ------ |text| Media Types ------

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
  is_styling_lang => 1,
};
$Type->{text}->{subtype}->{javascript} = { # RFC 4329
  parameter => {
    charset => {syntax => 'mime-charset', registered => 1}, ## TODO: SHOULD be registered
    e4x => {checker => sub {
      my ($self, $value, $onerror) = @_;
      unless ($value eq '1') {
        $onerror->(type => 'e4x:syntax error',
                   level => $self->{level}->{info},
                   value => $value);
        ## In fact no spec defines this parameter, except Web
        ## Applications 1.0 specification defines the UA requirement.
      }
    }},
  },
  ## Though RFC 4329 obsoletes this MIME type, it does not reflect the
  ## real world.  As Web Applications 1.0 specification states, we
  ## willfully violates that bogus spec here.
  #obsolete => 1,
  registered => 1,
};
$Type->{text}->{subtype}->{ecmascript} = { # RFC 4329
  parameter => {
    charset => $Type->{text}->{subtype}->{javascript}->{parameter}->{charset},
  },
  registered => 1,
};

$Type->{text}->{subtype}->{xsl} = {
  is_styling_lang => 1,
};

## ------ |audio| Media Types ------

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

## ------ |multipart| Media Types ------

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

$Type->{multipart}->{subtype}->{mixed} = {
  registered => 1,
}; # multipart/mixed

## ------ |message| Media Types ------

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

1;

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
