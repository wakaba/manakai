package Whatpm::ContentChecker;
use strict;
require Whatpm::ContentChecker;

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;

sub FEATURE_HTML5_ROLE () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD
      ## TODO: svg:*/@role
}

sub FEATURE_HTML5_LC () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_AT_RISK () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_WD () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_FD () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_DEFAULT () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_DROPPED () {
  ## NOTE: Was part of HTML5, but was dropped.
  Whatpm::ContentChecker::FEATURE_STATUS_WD
}
sub FEATURE_WF2 () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_WF2_DEPRECATED () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
  ## NOTE: MUST NOT be used.
}

## NOTE: Metainformation Attributes Module by W3C XHTML2 WG.
sub FEATURE_RDFA_LC () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

## NOTE: XHTML Role LCWD has almost no information on how the |role|
## attribute can be used- the only requirements for that matter is:
## "the attribute MUST be referenced using its namespace-qualified form" (and
## this is a host language conformance!).

sub FEATURE_XHTMLBASIC11_CR () {
  ## NOTE: Only additions to M12N10_REC are marked.
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}
sub FEATURE_XHTMLBASIC11_CR_DEPRECATED () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR |
  Whatpm::ContentChecker::FEATURE_DEPRECATED_INFO
}

## NOTE: M12N10 status is based on its abstract module definition.
## It contains a number of problems.  (However, again, it's a REC!)
sub FEATURE_M12N10_REC () {
  ## NOTE: Oh, XHTML m12n 1.0 passed the CR phase!  W3C Process suck!
  Whatpm::ContentChecker::FEATURE_STATUS_REC
}
sub FEATURE_M12N10_REC_DEPRECATED () {
  Whatpm::ContentChecker::FEATURE_STATUS_REC |
  Whatpm::ContentChecker::FEATURE_DEPRECATED_INFO
}
## NOTE: XHTML M12N 1.1 is a LC at the time of writing and no
## addition from 1.0.

## NOTE: XHTML10 status is based on its transitional and frameset DTDs
## (second edition).  Only missing attributes from M12N10 abstract
## definition are added.
sub FEATURE_XHTML10_REC () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

## NOTE: Diff from HTML4.
sub FEATURE_ISOHTML_PREPARATION () { ## Informative documentation
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

## NOTE: HTML4 status is based on its transitional and frameset DTDs (HTML
## 4.01).  Only missing attributes from XHTML10 are added.
sub FEATURE_HTML4_REC_RESERVED () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD
}

## TODO: According to HTML4 definition, authors SHOULD use style sheets
## rather than presentational attributes (deprecated or not deprecated).

## NOTE: Diff from HTML4.
sub FEATURE_HTML32_REC_OBSOLETE () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR |
  Whatpm::ContentChecker::FEATURE_DEPRECATED_SHOULD
      ## NOTE: Lowercase normative "should".
}

sub FEATURE_RFC2659 () { ## Experimental RFC
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

## NOTE: HTML 2.x - diff from HTML 2.0 and not in newer versions.
sub FEATURE_HTML2X_RFC () { ## Proposed Standard, obsolete
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

## NOTE: Diff from HTML 2.0.
sub FEATURE_RFC1942 () { ## Experimental RFC, obsolete
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

## NOTE: Diff from HTML 3.2.
sub FEATURE_HTML20_RFC () { ## Proposed Standard, obsolete
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

## December 2007 HTML5 Classification

my $HTMLMetadataContent = {
  $HTML_NS => {
    title => 1, base => 1, link => 1, style => 1, script => 1, noscript => 1,
    'event-source' => 1, command => 1, datatemplate => 1,
    ## NOTE: A |meta| with no |name| element is not allowed as
    ## a metadata content other than |head| element.
    meta => 1,
    ## NOTE: Only when empty [WF2]
    form => 1,
  },
  ## NOTE: RDF is mentioned in the HTML5 spec.
  ## TODO: Other RDF elements?
  q<http://www.w3.org/1999/02/22-rdf-syntax-ns#> => {RDF => 1},
};

my $HTMLFlowContent = {
  $HTML_NS => {
    section => 1, nav => 1, article => 1, blockquote => 1, aside => 1,
    h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1, header => 1,
    footer => 1, address => 1, p => 1, hr => 1, dialog => 1, pre => 1,
    ol => 1, ul => 1, dl => 1, figure => 1, map => 1, table => 1,
    details => 1, ## ISSUE: "Flow element" in spec.
    datagrid => 1, ## ISSUE: "Flow element" in spec.
    datatemplate => 1,
    div => 1, ## ISSUE: No category in spec.
    ## NOTE: |style| is only allowed if |scoped| attribute is specified.
    ## Additionally, it must be before any other element or
    ## non-inter-element-whitespace text node.
    style => 1,  

    br => 1, q => 1, cite => 1, em => 1, strong => 1, small => 1, mark => 1,
    dfn => 1, abbr => 1, time => 1, progress => 1, meter => 1, code => 1,
    var => 1, samp => 1, kbd => 1, sub => 1, sup => 1, span => 1, i => 1,
    b => 1, bdo => 1, script => 1, noscript => 1, 'event-source' => 1,
    command => 1, font => 1,
    a => 1,
    datagrid => 1, ## ISSUE: "Interactive element" in the spec.
    ## NOTE: |area| is allowed only as a descendant of |map|.
    area => 1,
    
    ins => 1, del => 1,

    ## NOTE: If there is a |menu| ancestor, phrasing.  Otherwise, flow.
    menu => 1,

    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,
  },

  ## NOTE: Embedded
  q<http://www.w3.org/1998/Math/MathML> => {math => 1},
  q<http://www.w3.org/2000/svg> => {svg => 1},
};

my $HTMLSectioningContent = {
  $HTML_NS => {
    section => 1, nav => 1, article => 1, aside => 1,
    ## NOTE: |body| is only allowed in |html| element.
    body => 1,
  },
};

my $HTMLSectioningRoot = {
  $HTML_NS => {
    blockquote => 1, datagrid => 1, figure => 1, td => 1,
  },
};

my $HTMLHeadingContent = {
  $HTML_NS => {
    h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1, header => 1,
  },
};

my $HTMLPhrasingContent = {
  ## NOTE: All phrasing content is also flow content.
  $HTML_NS => {
    br => 1, q => 1, cite => 1, em => 1, strong => 1, small => 1, mark => 1,
    dfn => 1, abbr => 1, time => 1, progress => 1, meter => 1, code => 1,
    var => 1, samp => 1, kbd => 1, sub => 1, sup => 1, span => 1, i => 1,
    b => 1, bdo => 1, script => 1, noscript => 1, 'event-source' => 1,
    command => 1, font => 1,
    a => 1,
    datagrid => 1, ## ISSUE: "Interactive element" in the spec.
    ## NOTE: |area| is allowed only as a descendant of |map|.
    area => 1,

    ## NOTE: Transparent.    
    ins => 1, del => 1,

    ## NOTE: If there is a |menu| ancestor, phrasing.  Otherwise, flow.
    menu => 1,

    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,

    ## NOTE: WF2
    input => 1, ## NOTE: type=hidden
    datalist => 1, ## NOTE: block | where |select| allowed
  },

  ## NOTE: Embedded
  q<http://www.w3.org/1998/Math/MathML> => {math => 1},
  q<http://www.w3.org/2000/svg> => {svg => 1},

  ## NOTE: And non-inter-element-whitespace text nodes.
};

## $HTMLEmbeddedContent: See Whatpm::ContentChecker.

my $HTMLInteractiveContent = {
  $HTML_NS => {
    a => 1,
    datagrid => 1, ## ISSUE: Categorized as "Inetractive element"
  },
};

## NOTE: $HTMLTransparentElements: See Whatpm::ContentChecker.
## NOTE: Semi-transparent elements: See Whatpm::ContentChecker.

## -- Common attribute syntacx checkers

our $AttrChecker;

my $GetHTMLEnumeratedAttrChecker = sub {
  my $states = shift; # {value => conforming ? 1 : -1}
  return sub {
    my ($self, $attr) = @_;
    my $value = lc $attr->value; ## TODO: ASCII case insensitibility?
    if ($states->{$value} > 0) {
      #
    } elsif ($states->{$value}) {
      $self->{onerror}->(node => $attr, type => 'enumerated:non-conforming');
    } else {
      $self->{onerror}->(node => $attr, type => 'enumerated:invalid');
    }
  };
}; # $GetHTMLEnumeratedAttrChecker

my $GetHTMLBooleanAttrChecker = sub {
  my $local_name = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    unless ($value eq $local_name or $value eq '') {
      $self->{onerror}->(node => $attr, type => 'boolean:invalid');
    }
  };
}; # $GetHTMLBooleanAttrChecker

## Unordered set of space-separated tokens
my $HTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker = sub {
  my ($self, $attr) = @_;
  my %word;
  for my $word (grep {length $_} split /[\x09-\x0D\x20]/, $attr->value) {
    unless ($word{$word}) {
      $word{$word} = 1;
    } else {
      $self->{onerror}->(node => $attr, type => 'duplicate token:'.$word);
    }
  }
}; # $HTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker

## |rel| attribute (unordered set of space separated tokens,
## whose allowed values are defined by the section on link types)
my $HTMLLinkTypesAttrChecker = sub {
  my ($a_or_area, $todo, $self, $attr, $item, $element_state) = @_;
  my %word;
  for my $word (grep {length $_} split /[\x09-\x0D\x20]/, $attr->value) {
    unless ($word{$word}) {
      $word{$word} = 1;
    } elsif ($word eq 'up') {
      #
    } else {
      $self->{onerror}->(node => $attr, type => 'duplicate token:'.$word);
    }
  }
  ## NOTE: Case sensitive match (since HTML5 spec does not say link
  ## types are case-insensitive and it says "The value should not 
  ## be confusingly similar to any other defined value (e.g.
  ## differing only in case).").
  ## NOTE: Though there is no explicit "MUST NOT" for undefined values,
  ## "MAY"s and "only ... MAY" restrict non-standard non-registered
  ## values to be used conformingly.

  my $is_hyperlink;
  my $is_resource;
  require Whatpm::_LinkTypeList;
  our $LinkType;
  for my $word (keys %word) {
    my $def = $LinkType->{$word};
    if (defined $def) {
      if ($def->{status} eq 'accepted') {
        if (defined $def->{effect}->[$a_or_area]) {
          #
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'link type:bad context:'.$word);
        }
      } elsif ($def->{status} eq 'proposal') {
        $self->{onerror}->(node => $attr, level => 's',
                           type => 'link type:proposed:'.$word);
        if (defined $def->{effect}->[$a_or_area]) {
          #
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'link type:bad context:'.$word);
        }
      } else { # rejected or synonym
        $self->{onerror}->(node => $attr,
                           type => 'link type:non-conforming:'.$word);
      }
      if (defined $def->{effect}->[$a_or_area]) {
        if ($word eq 'alternate') {
          #
        } elsif ($def->{effect}->[$a_or_area] eq 'hyperlink') {
          $is_hyperlink = 1;
        }
      }
      if ($def->{unique}) {
        unless ($self->{has_link_type}->{$word}) {
          $self->{has_link_type}->{$word} = 1;
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'link type:duplicate:'.$word);
        }
      }

      if (defined $def->{effect}->[$a_or_area] and $word ne 'alternate') {
        $is_hyperlink = 1 if $def->{effect}->[$a_or_area] eq 'hyperlink';
        $is_resource = 1 if $def->{effect}->[$a_or_area] eq 'external resource';
      }
    } else {
      $self->{onerror}->(node => $attr, level => 'unsupported',
                         type => 'link type:'.$word);
    }
  }
  $is_hyperlink = 1 if $word{alternate} and not $word{stylesheet};
  ## TODO: The Pingback 1.0 specification, which is referenced by HTML5,
  ## says that using both X-Pingback: header field and HTML
  ## <link rel=pingback> is deprecated and if both appears they
  ## SHOULD contain exactly the same value.
  ## ISSUE: Pingback 1.0 specification defines the exact representation
  ## of its link element, which cannot be tested by the current arch.
  ## ISSUE: Pingback 1.0 specification says that the document MUST NOT
  ## include any string that matches to the pattern for the rel=pingback link,
  ## which again inpossible to test.
  ## ISSUE: rel=pingback href MUST NOT include entities other than predefined 4.

  ## NOTE: <link rel="up index"><link rel="up up index"> is not an error.
  ## NOTE: We can't check "If the page is part of multiple hierarchies,
  ## then they SHOULD be described in different paragraphs.".

  $todo->{has_hyperlink_link_type} = 1 if $is_hyperlink;
  if ($is_hyperlink or $a_or_area) {
    $element_state->{uri_info}->{href}->{type}->{hyperlink} = 1;
  }
  if ($is_resource and not $a_or_area) {
    $element_state->{uri_info}->{href}->{type}->{resource} = 1;
  }
}; # $HTMLLinkTypesAttrChecker

## TODO: "When an author uses a new type not defined by either this specification or the Wiki page, conformance checkers should offer to add the value to the Wiki, with the details described above, with the "proposal" status."

## URI (or IRI)
my $HTMLURIAttrChecker = sub {
  my ($self, $attr, $item, $element_state) = @_;
  ## ISSUE: Relative references are allowed? (RFC 3987 "IRI" is an absolute reference with optional fragment identifier.)
  my $value = $attr->value;
  Whatpm::URIChecker->check_iri_reference ($value, sub {
    my %opt = @_;
    $self->{onerror}->(node => $attr, level => $opt{level},
                       type => 'URI::'.$opt{type}.
                       (defined $opt{position} ? ':'.$opt{position} : ''));
  });
  $self->{has_uri_attr} = 1; ## TODO: <html manifest>

  my $attr_name = $attr->name;
  $element_state->{uri_info}->{$attr_name}->{node} = $attr;
  ## TODO: absolute
  push @{$self->{return}->{uri}->{$value} ||= []},
      $element_state->{uri_info}->{$attr_name};
}; # $HTMLURIAttrChecker

## A space separated list of one or more URIs (or IRIs)
my $HTMLSpaceURIsAttrChecker = sub {
  my ($self, $attr) = @_;

  my $type = {ping => 'action',
              profile => 'namespace',
              archive => 'resource'}->{$attr->name};

  my $i = 0;
  for my $value (split /[\x09-\x0D\x20]+/, $attr->value) {
    Whatpm::URIChecker->check_iri_reference ($value, sub {
      my %opt = @_;
      $self->{onerror}->(node => $attr, level => $opt{level},
                         type => 'URIs:'.':'.
                         $opt{type}.':'.$i.
                         (defined $opt{position} ? ':'.$opt{position} : ''));
    });

    ## TODO: absolute
    push @{$self->{return}->{uri}->{$value} ||= []},
        {node => $attr, type => {$type => 1}};

    $i++;
  }
  ## ISSUE: Relative references? (especially, in profile="")
  ## ISSUE: Leading or trailing white spaces are conformant?
  ## ISSUE: A sequence of white space characters are conformant?
  ## ISSUE: A zero-length string is conformant? (It does contain a relative reference, i.e. same as base URI.)
  ## NOTE: Duplication seems not an error.
  $self->{has_uri_attr} = 1;
}; # $HTMLSpaceURIsAttrChecker

my $HTMLDatetimeAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  ## ISSUE: "space", not "space character" (in parsing algorihtm, "space character")
  if ($value =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})(?>[\x09-\x0D\x20]+(?>T[\x09-\x0D\x20]*)?|T[\x09-\x0D\x20]*)([0-9]{2}):([0-9]{2})(?>:([0-9]{2}))?(?>\.([0-9]+))?[\x09-\x0D\x20]*(?>Z|[+-]([0-9]{2}):([0-9]{2}))\z/) {
    my ($y, $M, $d, $h, $m, $s, $f, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    if (0 < $M and $M < 13) { ## ISSUE: This is not explicitly specified (though in parsing algorithm)
      $self->{onerror}->(node => $attr, type => 'datetime:bad day')
          if $d < 1 or
              $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->{onerror}->(node => $attr, type => 'datetime:bad day')
          if $M == 2 and $d == 29 and
              not ($y % 400 == 0 or ($y % 4 == 0 and $y % 100 != 0));
    } else {
      $self->{onerror}->(node => $attr, type => 'datetime:bad month');
    }
    $self->{onerror}->(node => $attr, type => 'datetime:bad hour') if $h > 23;
    $self->{onerror}->(node => $attr, type => 'datetime:bad minute') if $m > 59;
    $self->{onerror}->(node => $attr, type => 'datetime:bad second')
        if defined $s and $s > 59;
    $self->{onerror}->(node => $attr, type => 'datetime:bad timezone hour')
        if $zh > 23;
    $self->{onerror}->(node => $attr, type => 'datetime:bad timezone minute')
        if $zm > 59;
    ## ISSUE: Maybe timezone -00:00 should have same semantics as in RFC 3339.
  } else {
    $self->{onerror}->(node => $attr, type => 'datetime:syntax error');
  }
}; # $HTMLDatetimeAttrChecker

my $HTMLIntegerAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  unless ($value =~ /\A-?[0-9]+\z/) {
    $self->{onerror}->(node => $attr, type => 'integer:syntax error');
  }
}; # $HTMLIntegerAttrChecker

my $GetHTMLNonNegativeIntegerAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A[0-9]+\z/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'nninteger:out of range');
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'nninteger:syntax error');
    }
  };
}; # $GetHTMLNonNegativeIntegerAttrChecker

my $GetHTMLFloatingPointNumberAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A-?[0-9.]+\z/ and $value =~ /[0-9]/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'float:out of range');
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'float:syntax error');
    }
  };
}; # $GetHTMLFloatingPointNumberAttrChecker

## "A valid MIME type, optionally with parameters. [RFC 2046]"
## ISSUE: RFC 2046 does not define syntax of media types.
## ISSUE: The definition of "a valid MIME type" is unknown.
## Syntactical correctness?
my $HTMLIMTAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  ## ISSUE: RFC 2045 Content-Type header field allows insertion
  ## of LWS/comments between tokens.  Is it allowed in HTML?  Maybe no.
  ## ISSUE: RFC 2231 extension?  Maybe no.
  my $lws0 = qr/(?>(?>\x0D\x0A)?[\x09\x20])*/;
  my $token = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
  my $qs = qr/"(?>[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\x7E]|\x0D\x0A[\x09\x20]|\x5C[\x00-\x7F])*"/;
  if ($value =~ m#\A$lws0($token)$lws0/$lws0($token)$lws0((?>;$lws0$token$lws0=$lws0(?>$token|$qs)$lws0)*)\z#) {
    my @type = ($1, $2);
    my $param = $3;
    while ($param =~ s/^;$lws0($token)$lws0=$lws0(?>($token)|($qs))$lws0//) {
      if (defined $2) {
        push @type, $1 => $2;
      } else {
        my $n = $1;
        my $v = $2;
        $v =~ s/\\(.)/$1/gs;
        push @type, $n => $v;
      }
    }
    require Whatpm::IMTChecker;
    Whatpm::IMTChecker->check_imt (sub {
      my %opt = @_;
      $self->{onerror}->(node => $attr, level => $opt{level},
                         type => 'IMT:'.$opt{type});
    }, @type);
  } else {
    $self->{onerror}->(node => $attr, type => 'IMT:syntax error');
  }
}; # $HTMLIMTAttrChecker

my $HTMLLanguageTagAttrChecker = sub {
  ## NOTE: See also $AtomLanguageTagAttrChecker in Atom.pm.

  my ($self, $attr) = @_;
  my $value = $attr->value;
  require Whatpm::LangTag;
  Whatpm::LangTag->check_rfc3066_language_tag ($value, sub {
    my %opt = @_;
    my $type = 'LangTag:'.$opt{type};
    $type .= ':' . $opt{subtag} if defined $opt{subtag};
    $self->{onerror}->(node => $attr, type => $type, value => $opt{value},
                       level => $opt{level});
  });
  ## ISSUE: RFC 4646 (3066bis)?

  ## TODO: testdata
}; # $HTMLLanguageTagAttrChecker

## "A valid media query [MQ]"
my $HTMLMQAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr, level => 'unsupported',
                     type => 'media query');
  ## ISSUE: What is "a valid media query"?
}; # $HTMLMQAttrChecker

my $HTMLEventHandlerAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr, level => 'unsupported',
                     type => 'event handler');
  ## TODO: MUST contain valid ECMAScript code matching the
  ## ECMAScript |FunctionBody| production. [ECMA262]
  ## ISSUE: MUST be ES3? E4X? ES4? JS1.x?
  ## ISSUE: Automatic semicolon insertion does not apply?
  ## ISSUE: Other script languages?
}; # $HTMLEventHandlerAttrChecker

my $HTMLUsemapAttrChecker = sub {
  my ($self, $attr) = @_;
  ## MUST be a valid hashed ID reference to a |map| element
  my $value = $attr->value;
  if ($value =~ s/^#//) {
    ## ISSUE: Is |usemap="#"| conformant? (c.f. |id=""| is non-conformant.)
    push @{$self->{usemap}}, [$value => $attr];
  } else {
    $self->{onerror}->(node => $attr, type => '#idref:syntax error');
  }
  ## NOTE: Space characters in hashed ID references are conforming.
  ## ISSUE: UA algorithm for matching is case-insensitive; IDs only different in cases should be reported
}; # $HTMLUsemapAttrChecker

my $HTMLTargetAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  if ($value =~ /^_/) {
    $value = lc $value; ## ISSUE: ASCII case-insentitive?
    unless ({
             _self => 1, _parent => 1, _top => 1,
            }->{$value}) {
      $self->{onerror}->(node => $attr,
                         type => 'reserved browsing context name');
    }
  } else {
    ## NOTE: An empty string is a valid browsing context name (same as _self).
  }
}; # $HTMLTargetAttrChecker

my $HTMLSelectorsAttrChecker = sub {
  my ($self, $attr) = @_;

  ## ISSUE: Namespace resolution?
  
  my $value = $attr->value;
  
  require Whatpm::CSS::SelectorsParser;
  my $p = Whatpm::CSS::SelectorsParser->new;
  $p->{pseudo_class}->{$_} = 1 for qw/
    active checked disabled empty enabled first-child first-of-type
    focus hover indeterminate last-child last-of-type link only-child
    only-of-type root target visited
    lang nth-child nth-last-child nth-of-type nth-last-of-type not
    -manakai-contains -manakai-current
  /;

  $p->{pseudo_element}->{$_} = 1 for qw/
    after before first-letter first-line
  /;

  $p->{must_level} = $self->{must_level};
  $p->{onerror} = sub {
    my %opt = @_;
    $opt{type} = 'selectors:'.$opt{type};
    $self->{onerror}->(%opt, node => $attr);
  };
  $p->parse_string ($value);
}; # $HTMLSelectorsAttrChecker

my $HTMLAccesskeyAttrChecker = sub {
  my ($self, $attr) = @_;

  ## NOTE: "character" or |%Character;| in HTML4.

  my $value = $attr->value;
  if (length $value != 1) {
    $self->{onerror}->(node => $attr, type => 'char:syntax error',
                       level => $self->{fact_level}); ## TODO: type
  }

  ## NOTE: "Note. Authors should consider the input method of the expected
  ## reader when specifying an accesskey." [HTML4]  This is hard to implement,
  ## since it depends on keyboard and so on.
  ## NOTE: "We recommend that authors include the access key in label text
  ## or wherever the access key is to apply." [HTML4] (informative)
}; # $HTMLAccesskeyAttrChecker

my $HTMLColorAttrChecker = sub {
  my ($self, $attr) = @_;
  
  ## NOTE: HTML4 "color" or |%Color;|

  my $value = $attr->value;

  if ($value !~ /\A(?>#[0-9A-F]+|black|silver|gray|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua)\z/i) {
    $self->{onerror}->(node => $attr, type => 'color:syntax error', ## TODO: type
                       level => $self->{fact_level});
  }

  ## TODO: HTML4 has some guideline on usage of color.
}; # $HTMLColorAttrChecker

my $HTMLAttrChecker = {
  ## TODO: aria-* ## TODO: svg:*/@aria-* [HTML5ROLE] -> [STATES]
  id => sub {
    ## NOTE: |map| has its own variant of |id=""| checker
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if (length $value > 0) {
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'duplicate ID');
        push @{$self->{id}->{$value}}, $attr;
      } else {
        $self->{id}->{$value} = [$attr];
      }
      if ($value =~ /[\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $attr, type => 'space in ID');
      }
    } else {
      ## NOTE: MUST contain at least one character
      $self->{onerror}->(node => $attr, type => 'empty attribute value');
    }
  },
  title => sub {}, ## NOTE: No conformance creteria
  lang => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value eq '') {
      #
    } else {
      require Whatpm::LangTag;
      Whatpm::LangTag->check_rfc3066_language_tag ($value, sub {
        my %opt = @_;
        my $type = 'LangTag:'.$opt{type};
        $type .= ':' . $opt{subtag} if defined $opt{subtag};
        $self->{onerror}->(node => $attr, type => $type, value => $opt{value},
                           level => $opt{level});
      });
    }
    ## ISSUE: RFC 4646 (3066bis)?
    unless ($attr->owner_document->manakai_is_html) {
      $self->{onerror}->(node => $attr, type => 'in XML:lang');
    }

    ## TODO: test data
  },
  dir => $GetHTMLEnumeratedAttrChecker->({ltr => 1, rtl => 1}),
  class => sub {
    my ($self, $attr) = @_;
    my %word;
    for my $word (grep {length $_} split /[\x09-\x0D\x20]/, $attr->value) {
      unless ($word{$word}) {
        $word{$word} = 1;
        push @{$self->{return}->{class}->{$word}||=[]}, $attr;
      } else {
        $self->{onerror}->(node => $attr, type => 'duplicate token:'.$word);
      }
    }
  },
  contenteditable => $GetHTMLEnumeratedAttrChecker->({
    true => 1, false => 1, '' => 1,
  }),
  contextmenu => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    push @{$self->{contextmenu}}, [$value => $attr];
    ## ISSUE: "The value must be the ID of a menu element in the DOM."
    ## What is "in the DOM"?  A menu Element node that is not part
    ## of the Document tree is in the DOM?  A menu Element node that
    ## belong to another Document tree is in the DOM?
  },
  irrelevant => $GetHTMLBooleanAttrChecker->('irrelevant'),
  ## TODO: repeat, repeat-start, repeat-min, repeat-max, repeat-template ## TODO: global
  ## TODO: role [HTML5ROLE] ## TODO: global @role [XHTML1ROLE]
  tabindex => $HTMLIntegerAttrChecker
## TODO: ref, template, registrationmark
};

my %HTMLAttrStatus = (
  class => FEATURE_HTML5_DEFAULT,
  contenteditable => FEATURE_HTML5_DEFAULT,
  contextmenu => FEATURE_HTML5_WD,
  dir => FEATURE_HTML5_DEFAULT,
  draggable => FEATURE_HTML5_LC,
  id => FEATURE_HTML5_DEFAULT,
  irrelevant => FEATURE_HTML5_WD,
  lang => FEATURE_HTML5_DEFAULT,
  ref => FEATURE_HTML5_AT_RISK,
  registrationmark => FEATURE_HTML5_AT_RISK,
  repeat => FEATURE_WF2,
  'repeat-max' => FEATURE_WF2,
  'repeat-min' => FEATURE_WF2,
  'repeat-start' => FEATURE_WF2,
  'repeat-template' => FEATURE_WF2,
  role => FEATURE_HTML5_ROLE,
  tabindex => FEATURE_HTML5_DEFAULT,
  template => FEATURE_HTML5_AT_RISK,
  title => FEATURE_HTML5_DEFAULT,  
);

my %HTMLM12NCommonAttrStatus = (
  about => FEATURE_RDFA_LC,
  class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  content => FEATURE_RDFA_LC,
  datatype => FEATURE_RDFA_LC,
  dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  instanceof => FEATURE_RDFA_LC,
  onclick => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  ondblclick => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onmousedown => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onmouseup => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onmouseover => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onmousemove => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onmouseout => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onkeypress => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onkeydown => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  onkeyup => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  property => FEATURE_RDFA_LC,
  rel => FEATURE_RDFA_LC,
  resource => FEATURE_RDFA_LC,
  rev => FEATURE_RDFA_LC,
  style => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR_DEPRECATED |
      FEATURE_M12N10_REC,
  title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
);

for (qw/
         onabort onbeforeunload onblur onchange onclick oncontextmenu
         ondblclick ondrag ondragend ondragenter ondragleave ondragover
         ondragstart ondrop onerror onfocus onkeydown onkeypress
         onkeyup onload onmessage onmousedown onmousemove onmouseout
         onmouseover onmouseup onmousewheel onresize onscroll onselect
         onsubmit onunload 
     /) {
  $HTMLAttrChecker->{$_} = $HTMLEventHandlerAttrChecker;
  $HTMLAttrStatus{$_} = FEATURE_HTML5_DEFAULT;
}

my $GetHTMLAttrsChecker = sub {
  my $element_specific_checker = shift;
  my $element_specific_status = shift;
  return sub {
    my ($self, $item, $element_state) = @_;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = $element_specific_checker->{$attr_ln}
            || $HTMLAttrChecker->{$attr_ln};
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr, $item, $element_state);
      } elsif ($attr_ns eq '' and not $element_specific_status->{$attr_ln}) {
        #
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No conformance createria for unknown attributes in the spec
      }
      if ($attr_ns eq '') {
        $self->_attr_status_info ($attr, $element_specific_status->{$attr_ln});
      }
      ## TODO: global attribute
    }
  };
}; # $GetHTMLAttrsChecker

my %HTMLChecker = (
  %Whatpm::ContentChecker::AnyChecker,
  check_attrs => $GetHTMLAttrsChecker->({}, \%HTMLAttrStatus),
);

my %HTMLEmptyChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:empty',
                         level => $self->{must_level});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed:empty',
                         level => $self->{must_level});
    }
  },
);

my %HTMLTextChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
);

my %HTMLFlowContentChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'style') {
      if ($element_state->{has_non_style} or
          not $child_el->has_attribute_ns (undef, 'scoped')) {
        $self->{onerror}->(node => $child_el, ## TODO: type
                           type => 'element not allowed:flow style',
                           level => $self->{must_level});
      }
    } elsif ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
      $element_state->{has_non_style} = 1 unless $child_is_transparent;
    } else {
      $element_state->{has_non_style} = 1;
      $self->{onerror}->(node => $child_el, ## TODO: type
                         type => 'element not allowed:flow',
                         level => $self->{must_level})
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{has_non_style} = 1;
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{has_significant}) {
      $item->{real_parent_state}->{has_significant} = 1;
    } elsif ($item->{transparent}) {
      #
    } else {
      $self->{onerror}->(node => $item->{node},
                         level => $self->{should_level},
                         type => 'no significant content');
    }
  },
);

my %HTMLPhrasingContentChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:phrasing',
                         level => $self->{must_level});
    }
  },
  check_end => $HTMLFlowContentChecker{check_end},
  ## NOTE: The definition for |li| assumes that the only differences
  ## between flow and phrasing content checkers are |check_child_element|
  ## and |check_child_text|.
);

my %HTMLTransparentChecker = %HTMLFlowContentChecker;
## ISSUE: Significant content rule should be applied to transparent element
## with parent?

our $Element;
our $ElementDefault;

$Element->{$HTML_NS}->{''} = {
  %HTMLChecker,
};

$Element->{$HTML_NS}->{html} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  is_root => 1,
  check_attrs => $GetHTMLAttrsChecker->({
    manifest => $HTMLURIAttrChecker,
    xmlns => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ($value eq $HTML_NS) {
        $self->{onerror}->(node => $attr, type => 'invalid attribute value');
      }
      unless ($attr->owner_document->manakai_is_html) {
        $self->{onerror}->(node => $attr, type => 'in XML:xmlns');
  ## TODO: Test
      }

      ## TODO: Should be resolved?
      push @{$self->{return}->{uri}->{$value} ||= []},
          {node => $attr, type => {namespace => 1}};
    },
    version => sub {
      ## NOTE: According to HTML4 prose, this is a "cdata" attribute.
      ## Though DTDs of various versions of HTML define the attribute
      ## as |#FIXED|, this conformance checker does no check for
      ## the attribute value, since what kind of check should be done
      ## is unknown.
    },
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    manifest => FEATURE_HTML5_DEFAULT,
    sdaform => FEATURE_HTML20_RFC,
    version => FEATURE_M12N10_REC,
    xmlns => FEATURE_HTML5_DEFAULT,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before head';
    $element_state->{uri_info}->{manifest}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'before head') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'head') {
        $element_state->{phase} = 'after head';            
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'body') {
        $self->{onerror}->(node => $child_el,
                           type => 'ps element missing:head');
        $element_state->{phase} = 'after body';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed');      
      }
    } elsif ($element_state->{phase} eq 'after head') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'body') {
        $element_state->{phase} = 'after body';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed');      
      }
    } elsif ($element_state->{phase} eq 'after body') {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed');      
    } else {
      die "check_child_element: Bad |html| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'after body') {
      #
    } elsif ($element_state->{phase} eq 'before head') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:head');
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:body');
    } elsif ($element_state->{phase} eq 'after head') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:body');
    } else {
      die "check_end: Bad |html| phase: $element_state->{phase}";
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{head} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    profile => $HTMLSpaceURIsAttrChecker, ## NOTE: MUST be profile URIs.
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    profile => FEATURE_HTML5_DROPPED | FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'title') {
      unless ($element_state->{has_title}) {
        $element_state->{has_title} = 1;
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:head title',
                           level => $self->{must_level});
      }
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'style') {
      if ($child_el->has_attribute_ns (undef, 'scoped')) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:head style',
                           level => $self->{must_level});
      }
    } elsif ($HTMLMetadataContent->{$child_nsuri}->{$child_ln}) {
      #
      
      ## NOTE: |meta| is a metadata content.  However, strictly speaking,
      ## a |meta| element with none of |charset|, |name|,
      ## or |http-equiv| attribute is not allowed.  It is non-conforming
      ## anyway.

      ## TODO: |form| MUST be empty and in XML [WF2].
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:metadata',
                         level => $self->{must_level});
    }
    $element_state->{in_head_original} = $self->{flag}->{in_head};
    $self->{flag}->{in_head} = 1;
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{has_title}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:title');
    }
    $self->{flag}->{in_head} = $element_state->{in_head_original};

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{title} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{base} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  %HTMLEmptyChecker,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;

    if ($self->{has_base}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element not allowed:base');
    } else {
      $self->{has_base} = 1;
    }

    my $has_href = $item->{node}->has_attribute_ns (undef, 'href');
    my $has_target = $item->{node}->has_attribute_ns (undef, 'target');

    if ($self->{has_uri_attr} and $has_href) {
      ## ISSUE: Are these examples conforming?
      ## <head profile="a b c"><base href> (except for |profile|'s 
      ## non-conformance)
      ## <title xml:base="relative"/><base href/> (maybe it should be)
      ## <unknown xmlns="relative"/><base href/> (assuming that
      ## |{relative}:unknown| is allowed before XHTML |base| (unlikely, though))
      ## <style>@import 'relative';</style><base href>
      ## <script>location.href = 'relative';</script><base href>
      ## NOTE: <html manifest=".."><head><base href=""/> is conforming as
      ## an exception.
      $self->{onerror}->(node => $item->{node},
                         type => 'basehref after URI attribute');
    }
    if ($self->{has_hyperlink_element} and $has_target) {
      ## ISSUE: Are these examples conforming?
      ## <head><title xlink:href=""/><base target="name"/></head>
      ## <xbl:xbl>...<svg:a href=""/>...</xbl:xbl><base target="name"/>
      ## (assuming that |xbl:xbl| is allowed before |base|)
      ## NOTE: These are non-conformant anyway because of |head|'s content model:
      ## <link href=""/><base target="name"/>
      ## <link rel=unknown href=""><base target=name>
      $self->{onerror}->(node => $item->{node},
                         type => 'basetarget after hyperlink');
    }

    if (not $has_href and not $has_target) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:href|target');
    }

    $element_state->{uri_info}->{href}->{type}->{base} = 1;

    return $GetHTMLAttrsChecker->({
      href => $HTMLURIAttrChecker,
      target => $HTMLTargetAttrChecker,
    }, {
      %HTMLAttrStatus,
      href => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      target => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    })->($self, $item, $element_state);
  },
};

$Element->{$HTML_NS}->{link} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  %HTMLEmptyChecker,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      ## TODO: HTML4 |charset|
      href => $HTMLURIAttrChecker,
      rel => sub { $HTMLLinkTypesAttrChecker->(0, $item, @_) },
      rev => $HTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker,
      media => $HTMLMQAttrChecker,
      hreflang => $HTMLLanguageTagAttrChecker,
      target => $HTMLTargetAttrChecker,
      type => $HTMLIMTAttrChecker,
      ## NOTE: Though |title| has special semantics,
      ## syntactically same as the |title| as global attribute.
    }, {
      %HTMLAttrStatus,
      %HTMLM12NCommonAttrStatus,
      charset => FEATURE_M12N10_REC,
      href => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      hreflang => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      media => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      methods => FEATURE_HTML20_RFC,
      rel => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      rev => FEATURE_M12N10_REC,
      sdapref => FEATURE_HTML20_RFC,
      target => FEATURE_M12N10_REC,
      type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      urn => FEATURE_HTML20_RFC,
    })->($self, $item, $element_state);
    if ($item->{node}->has_attribute_ns (undef, 'href')) {
      $self->{has_hyperlink_element} = 1 if $item->{has_hyperlink_link_type};
    } else {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:href');
    }
    unless ($item->{node}->has_attribute_ns (undef, 'rel')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:rel');
    }
  },
};

$Element->{$HTML_NS}->{meta} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  %HTMLEmptyChecker,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $name_attr;
    my $http_equiv_attr;
    my $charset_attr;
    my $content_attr;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        if ($attr_ln eq 'content') {
          $content_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'name') {
          $name_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'http-equiv') {
          $http_equiv_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'charset') {
          $charset_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'scheme') {
          ## NOTE: <http://suika.fam.cx/2007/html/standards#html-meta-scheme>
          $checker = sub {};
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln}
              || $AttrChecker->{$attr_ns}->{$attr_ln}
              || $AttrChecker->{$attr_ns}->{''};
        }
      } else {
        $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      }

      my $status = {
        %HTMLAttrStatus,
        charset => FEATURE_HTML5_DEFAULT,
        content => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        'http-equiv' => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
        lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
        name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        scheme => FEATURE_M12N10_REC,
      }->{$attr_ln};

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No conformance createria for unknown attributes in the spec
      }

      if ($attr_ns eq '') {
        $self->_attr_status_info ($attr, $status);
      }
    }
    
    if (defined $name_attr) {
      if (defined $http_equiv_attr) {
        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'attribute not allowed');
      } elsif (defined $charset_attr) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'attribute not allowed');
      }
      my $metadata_name = $name_attr->value;
      my $metadata_value;
      if (defined $content_attr) {
        $metadata_value = $content_attr->value;
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:content');
        $metadata_value = '';
      }
    } elsif (defined $http_equiv_attr) {
      if (defined $charset_attr) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'attribute not allowed');
      }
      unless (defined $content_attr) {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:content');
      }
    } elsif (defined $charset_attr) {
      if (defined $content_attr) {
        $self->{onerror}->(node => $content_attr,
                           type => 'attribute not allowed');
      }
    } else {
      if (defined $content_attr) {
        $self->{onerror}->(node => $content_attr,
                           type => 'attribute not allowed');
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:name|http-equiv');
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:name|http-equiv|charset');
      }
    }

    my $check_charset_decl = sub () {
      my $parent = $item->{node}->manakai_parent_element;
      if ($parent and $parent eq $parent->owner_document->manakai_head) {
        for my $el (@{$parent->child_nodes}) {
          next unless $el->node_type == 1; # ELEMENT_NODE
          unless ($el eq $item->{node}) {
            ## NOTE: Not the first child element.
            $self->{onerror}->(node => $item->{node},
                               type => 'element not allowed:meta charset',
                               level => $self->{must_level});
          }
          last;
          ## NOTE: Entity references are not supported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'element not allowed:meta charset',
                           level => $self->{must_level});
      }

      unless ($item->{node}->owner_document->manakai_is_html) {
        $self->{onerror}->(node => $item->{node},
                           type => 'in XML:charset',
                           level => $self->{must_level});
      }
    }; # $check_charset_decl

    my $check_charset = sub ($$) {
      my ($attr, $charset_value) = @_;
      ## NOTE: Though the case-sensitivility of |charset| attribute value
      ## is not explicitly spelled in the HTML5 spec, the Character Set
      ## registry of IANA, which is referenced from HTML5 spec, says that
      ## charset name is case-insensitive.
      $charset_value =~ tr/A-Z/a-z/; ## NOTE: ASCII Case-insensitive.

      require Message::Charset::Info;
      my $charset = $Message::Charset::Info::IANACharset->{$charset_value};
      my $ic = $item->{node}->owner_document->input_encoding;
      if (defined $ic) {
        ## TODO: Test for this case
        my $ic_charset = $Message::Charset::Info::IANACharset->{$ic};
        if ($charset ne $ic_charset) {
          $self->{onerror}->(node => $attr,
                             type => 'mismatched charset name:'.$ic.
                                 ':'.$charset_value, ## TODO: This should be a |value| value.
                             level => $self->{must_level});
        }
      } else {
        ## NOTE: MUST, but not checkable, since the document is not originally
        ## in serialized form (or the parser does not preserve the input
        ## encoding information).
        $self->{onerror}->(node => $attr,
                           type => 'mismatched charset name::'.$charset_value, ## TODO: |value|
                           level => 'unsupported');
      }
      
      ## ISSUE: What is "valid character encoding name"?  Syntactically valid?
      ## Syntactically valid and registered?  What about x-charset names?
      unless (Message::Charset::Info::is_syntactically_valid_iana_charset_name
                  ($charset_value)) {
        $self->{onerror}->(node => $attr,
                           type => 'charset:syntax error:'.$charset_value, ## TODO
                           level => $self->{must_level});
      }

      if ($charset) {
        ## ISSUE: What is "the preferred name for that encoding" (for a charset
        ## with no "preferred MIME name" label)?
        my $charset_status = $charset->{iana_names}->{$charset_value} || 0;
        if (($charset_status &
             Message::Charset::Info::PREFERRED_CHARSET_NAME ())
                != Message::Charset::Info::PREFERRED_CHARSET_NAME ()) {
          $self->{onerror}->(node => $attr,
                             type => 'charset:not preferred:'.
                                 $charset_value, ## TODO
                             level => $self->{must_level});
        }
        if (($charset_status &
             Message::Charset::Info::REGISTERED_CHARSET_NAME ())
                != Message::Charset::Info::REGISTERED_CHARSET_NAME ()) {
          if ($charset_value =~ /^x-/) {
            $self->{onerror}->(node => $attr,
                               type => 'charset:private:'.$charset_value, ## TODO
                               level => $self->{good_level});
          } else {
            $self->{onerror}->(node => $attr,
                               type => 'charset:not registered:'.
                                   $charset_value, ## TODO
                               level => $self->{good_level});
          }
        }
      } elsif ($charset_value =~ /^x-/) {
        $self->{onerror}->(node => $attr,
                             type => 'charset:private:'.$charset_value, ## TODO
                             level => $self->{good_level});
      } else {
        $self->{onerror}->(node => $attr,
                             type => 'charset:not registered:'.$charset_value, ## TODO
                             level => $self->{good_level});
      }

      if ($attr->get_user_data ('manakai_has_reference')) {
        $self->{onerror}->(node => $attr,
                             type => 'character reference in charset',
                             level => $self->{must_level});
      }
    }; # $check_charset

    ## TODO: metadata conformance

    ## TODO: pragma conformance
    if (defined $http_equiv_attr) { ## An enumerated attribute
      my $keyword = lc $http_equiv_attr->value; ## TODO: ascii case?
      if ({
           'refresh' => 1,
           'default-style' => 1,
          }->{$keyword}) {
        #

        ## TODO: More than one occurence is a MUST-level error (revision 1180).
      } elsif ($keyword eq 'content-type') {
        ## TODO: refs in "text/html; charset=" are not disallowed since rev.1275.

        $check_charset_decl->();
        if ($content_attr) {
          my $content = $content_attr->value;
          if ($content =~ m!^[Tt][Ee][Xx][Tt]/[Hh][Tt][Mm][Ll];
                            [\x09-\x0D\x20]*[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                            =(.+)\z!sx) {
            $check_charset->($content_attr, $1);
          } else {
            $self->{onerror}->(node => $content_attr,
                               type => 'meta content-type syntax error',
                               level => $self->{must_level});
          }
        }
      } else {
        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'enumerated:invalid');
      }
    }

    if (defined $charset_attr) {
      $check_charset_decl->();
      $check_charset->($charset_attr, $charset_attr->value);
    }
  },
};

$Element->{$HTML_NS}->{style} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  %HTMLChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    type => $HTMLIMTAttrChecker, ## TODO: MUST be a styling language
    media => $HTMLMQAttrChecker,
    scoped => $GetHTMLBooleanAttrChecker->('scoped'),
    ## NOTE: |title| has special semantics for |style|s, but is syntactically
    ## not different
  }, {
    %HTMLAttrStatus,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    media => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    scoped => FEATURE_HTML5_DEFAULT,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    ## NOTE: |html:style| itself has no conformance creteria on content model.
    my $type = $item->{node}->get_attribute_ns (undef, 'type');
    if (not defined $type or
        $type =~ m[\A(?>(?>\x0D\x0A)?[\x09\x20])*[Tt][Ee][Xx][Tt](?>(?>\x0D\x0A)?[\x09\x20])*/(?>(?>\x0D\x0A)?[\x09\x20])*[Cc][Ss][Ss](?>(?>\x0D\x0A)?[\x09\x20])*\z]) {
      $element_state->{allow_element} = 0;
      $element_state->{style_type} = 'text/css';
    } else {
      $element_state->{allow_element} = 1; # unknown
      $element_state->{style_type} = $type; ## TODO: $type normalization
    }
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{allow_element}) {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{text} .= $child_node->text_content;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{style_type} eq 'text/css') {
      $self->{onsubdoc}->({s => $element_state->{text},
                           container_node => $item->{node},
                           media_type => 'text/css', is_char_string => 1});
    } else {
      $self->{onerror}->(node => $item->{node}, level => 'unsupported',
                         type => 'style:'.$element_state->{style_type});
    }

    $HTMLChecker{check_end}->(@_);
  },
};
## ISSUE: Relationship to significant content check?

$Element->{$HTML_NS}->{body} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    alink => $HTMLColorAttrChecker,
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    link => $HTMLColorAttrChecker,
    text => $HTMLColorAttrChecker,
    vlink => $HTMLColorAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    alink => FEATURE_M12N10_REC_DEPRECATED,
    background => FEATURE_M12N10_REC_DEPRECATED,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    link => FEATURE_M12N10_REC_DEPRECATED,
    onload => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onunload => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    text => FEATURE_M12N10_REC_DEPRECATED,
    vlink => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
  },
};

$Element->{$HTML_NS}->{section} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{nav} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{article} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{blockquote} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  %HTMLFlowContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
  
    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
  },
};

$Element->{$HTML_NS}->{aside} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{h1} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->{flag}->{has_hn} = 1;
  },
};

$Element->{$HTML_NS}->{h2} = {%{$Element->{$HTML_NS}->{h1}}};

$Element->{$HTML_NS}->{h3} = {%{$Element->{$HTML_NS}->{h1}}};

$Element->{$HTML_NS}->{h4} = {%{$Element->{$HTML_NS}->{h1}}};

$Element->{$HTML_NS}->{h5} = {%{$Element->{$HTML_NS}->{h1}}};

$Element->{$HTML_NS}->{h6} = {%{$Element->{$HTML_NS}->{h1}}};

## TODO: Explicit sectioning is "encouraged".

$Element->{$HTML_NS}->{header} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state,
                                {$HTML_NS => {qw/header 1 footer 1/}},
                                $HTMLSectioningContent);
    $element_state->{has_hn_original} = $self->{flag}->{has_hn};
    $self->{flag}->{has_hn} = 0;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    unless ($self->{flag}->{has_hn}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:hn');
    }
    $self->{flag}->{has_hn} ||= $element_state->{has_hn_original};

    $HTMLFlowContentChecker{check_end}->(@_);
  },
  ## ISSUE: <header><del><h1>...</h1></del></header> is conforming?
};

$Element->{$HTML_NS}->{footer} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state,
                                {$HTML_NS => {footer => 1}},
                                $HTMLSectioningContent,
                                $HTMLHeadingContent);
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{address} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state,
                                {$HTML_NS => {footer => 1, address => 1}},
                                $HTMLSectioningContent, $HTMLHeadingContent);
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{p} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{hr} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: HTML4 |align|, |noshade|, |size|, |width|
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    noshade => FEATURE_M12N10_REC_DEPRECATED,
    sdapref => FEATURE_HTML20_RFC,
    size => FEATURE_M12N10_REC_DEPRECATED,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

$Element->{$HTML_NS}->{br} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    clear => $GetHTMLEnumeratedAttrChecker->({
      left => 1, all => 1, right => 1, none => 1,
    }),
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    clear => FEATURE_M12N10_REC_DEPRECATED,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    sdapref => FEATURE_HTML20_RFC,
    style => FEATURE_XHTML10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  ## NOTE: Blank line MUST NOT be used for presentation purpose.
  ## (This requirement is semantic so that we cannot check.)
};

$Element->{$HTML_NS}->{dialog} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before dt';
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'before dt') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $element_state->{phase} = 'before dd';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $self->{onerror}
            ->(node => $child_el, type => 'ps element missing:dt');
        $element_state->{phase} = 'before dt';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'before dd') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $element_state->{phase} = 'before dt';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $self->{onerror}
            ->(node => $child_el, type => 'ps element missing:dd');
        $element_state->{phase} = 'before dd';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } else {
      die "check_child_element: Bad |dialog| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'before dd') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:dd');
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{pre} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

$Element->{$HTML_NS}->{ol} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    reversed => $GetHTMLBooleanAttrChecker->('reversed'),
    start => $HTMLIntegerAttrChecker,
    ## TODO: HTML4 |type|
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    compact => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    reversed => FEATURE_HTML5_DEFAULT,
    sdaform => FEATURE_HTML20_RFC,
    #start => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC_DEPRECATED,
    start => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    type => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'li') {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
};

$Element->{$HTML_NS}->{ul} = {
  %{$Element->{$HTML_NS}->{ol}},
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    ## TODO: HTML4 |type|
    ## TODO: sdaform, align
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    compact => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    type => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

$Element->{$HTML_NS}->{dir} = {
## TODO: %block; is not allowed [HTML4] ## TODO: Empty list allowed?
  %{$Element->{$HTML_NS}->{ul}},
  status => FEATURE_M12N10_REC_DEPRECATED,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    compact => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{li} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: HTML4 |type|
    value => sub {
      my ($self, $attr) = @_;
      my $parent = $attr->owner_element->manakai_parent_element;
      if (defined $parent) {
        my $parent_ns = $parent->namespace_uri;
        $parent_ns = '' unless defined $parent_ns;
        my $parent_ln = $parent->manakai_local_name;
        unless ($parent_ns eq $HTML_NS and $parent_ln eq 'ol') {
          $self->{onerror}->(node => $attr, level => 'unsupported',
                             type => 'attribute');
        }
      }
      $HTMLIntegerAttrChecker->($self, $attr);
    }, ## TODO: test
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    type => FEATURE_M12N10_REC_DEPRECATED,
    #value => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR | 
    #    FEATURE_M12N10_REC_DEPRECATED,
    value => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR |
        FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{flag}->{in_menu}) {
      $HTMLPhrasingContentChecker{check_child_element}->(@_);
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($self->{flag}->{in_menu}) {
      $HTMLPhrasingContentChecker{check_child_text}->(@_);
    } else {
      $HTMLFlowContentChecker{check_child_text}->(@_);
    }
  },
};

$Element->{$HTML_NS}->{dl} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    compact => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    type => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before dt';
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'in dds') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        #$element_state->{phase} = 'in dds';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $element_state->{phase} = 'in dts';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'in dts') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        #$element_state->{phase} = 'in dts';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $element_state->{phase} = 'in dds';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'before dt') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $element_state->{phase} = 'in dts';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $self->{onerror}
             ->(node => $child_el, type => 'ps element missing:dt');
        $element_state->{phase} = 'in dds';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } else {
      die "check_child_element: Bad |dl| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'in dts') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:dd');
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{dt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{dd} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{a} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my %attr;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = {
          accesskey => $HTMLAccesskeyAttrChecker,
          ## TODO: HTML4 |charset|
          ## TODO: HTML4 |coords|
                     target => $HTMLTargetAttrChecker,
                     href => $HTMLURIAttrChecker,
                     ping => $HTMLSpaceURIsAttrChecker,
                     rel => sub { $HTMLLinkTypesAttrChecker->(1, $item, @_) },
          rev => $HTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker,
          ## TODO: HTML4 |shape|
                     media => $HTMLMQAttrChecker,
          ## TODO: HTML4/XHTML1 |name|
                     hreflang => $HTMLLanguageTagAttrChecker,
                     type => $HTMLIMTAttrChecker,
                   }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};

      my $status = {
        %HTMLAttrStatus,
        %HTMLM12NCommonAttrStatus,
        accesskey => FEATURE_M12N10_REC,
        charset => FEATURE_M12N10_REC,
        coords => FEATURE_M12N10_REC,
        cryptopts => FEATURE_RFC2659,
        dn => FEATURE_RFC2659,
        href => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        hreflang => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
        media => FEATURE_HTML5_DEFAULT,
        methods => FEATURE_HTML20_RFC,
        name => FEATURE_M12N10_REC_DEPRECATED,
        nonce => FEATURE_RFC2659,
        onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        ping => FEATURE_HTML5_DEFAULT,
        rel => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        rev => FEATURE_M12N10_REC,
        sdapref => FEATURE_HTML20_RFC,
        shape => FEATURE_M12N10_REC,
        tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        target => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        urn => FEATURE_HTML20_RFC,
      }->{$attr_ln};

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No conformance createria for unknown attributes in the spec
      }

      if ($attr_ns eq '') {
        $self->_attr_status_info ($attr, $status);
      }
    }

    $element_state->{in_a_href_original} = $self->{flag}->{in_a_href};
    if (defined $attr{href}) {
      $self->{has_hyperlink_element} = 1;
      $self->{flag}->{in_a_href} = 1;
    } else {
      for (qw/target ping rel media hreflang type/) {
        if (defined $attr{$_}) {
          $self->{onerror}->(node => $attr{$_},
                             type => 'attribute not allowed');
        }
      }
    }

    $element_state->{uri_info}->{href}->{type}->{hyperlink} = 1;
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, $HTMLInteractiveContent);
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    delete $self->{flag}->{in_a_href}
        unless $element_state->{in_a_href_original};

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{q} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdapref => FEATURE_HTML2X_RFC,
    sdasuff => FEATURE_HTML2X_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
  },
};

$Element->{$HTML_NS}->{cite} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{em} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{strong} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{small} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{big} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{mark} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLPhrasingContentChecker,
};

$Element->{$HTML_NS}->{dfn} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {dfn => 1}});

    my $node = $item->{node};
    my $term = $node->get_attribute_ns (undef, 'title');
    unless (defined $term) {
      for my $child (@{$node->child_nodes}) {
        if ($child->node_type == 1) { # ELEMENT_NODE
          if (defined $term) {
            undef $term;
            last;
          } elsif ($child->manakai_local_name eq 'abbr') {
            my $nsuri = $child->namespace_uri;
            if (defined $nsuri and $nsuri eq $HTML_NS) {
              my $attr = $child->get_attribute_node_ns (undef, 'title');
              if ($attr) {
                $term = $attr->value;
              }
            }
          }
        } elsif ($child->node_type == 3 or $child->node_type == 4) {
          ## TEXT_NODE or CDATA_SECTION_NODE
          if ($child->data =~ /\A[\x09-\x0D\x20]+\z/) { # Inter-element whitespace
            next;
          }
          undef $term;
          last;
        }
      }
      unless (defined $term) {
        $term = $node->text_content;
      }
    }
    if ($self->{term}->{$term}) {
      $self->{onerror}->(node => $node, type => 'duplicate term');
      push @{$self->{term}->{$term}}, $node;
    } else {
      $self->{term}->{$term} = [$node];
    }
## ISSUE: The HTML5 algorithm does not work with |ruby| unless |dfn|
## has |title|.
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{abbr} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{acronym} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{time} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    datetime => sub { 1 }, # checked in |checker|
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    datetime => FEATURE_HTML5_FD,
  }),
  ## TODO: Write tests
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    my $attr = $item->{node}->get_attribute_node_ns (undef, 'datetime');
    my $input;
    my $reg_sp;
    my $input_node;
    if ($attr) {
      $input = $attr->value;
      $reg_sp = qr/[\x09-\x0D\x20]*/;
      $input_node = $attr;
    } else {
      $input = $item->{node}->text_content;
      $reg_sp = qr/\p{Zs}*/;
      $input_node = $item->{node};

      ## ISSUE: What is the definition for "successfully extracts a date
      ## or time"?  If the algorithm says the string is invalid but
      ## return some date or time, is it "successfully"?
    }

    my $hour;
    my $minute;
    my $second;
    if ($input =~ /
      \A
      [\x09-\x0D\x20]*
      ([0-9]+) # 1
      (?>
        -([0-9]+) # 2
        -([0-9]+) # 3
        [\x09-\x0D\x20]*
        (?>
          T
          [\x09-\x0D\x20]*
        )?
        ([0-9]+) # 4
        :([0-9]+) # 5
        (?>
          :([0-9]+(?>\.[0-9]*)?|\.[0-9]*) # 6
        )?
        [\x09-\x0D\x20]*
        (?>
          Z
          [\x09-\x0D\x20]*
        |
          [+-]([0-9]+):([0-9]+) # 7, 8
          [\x09-\x0D\x20]*
        )?
        \z
      |
        :([0-9]+) # 9
        (?>
          :([0-9]+(?>\.[0-9]*)?|\.[0-9]*) # 10
        )?
        [\x09-\x0D\x20]*\z
      )
    /x) {
      if (defined $2) { ## YYYY-MM-DD T? hh:mm
        if (length $1 != 4 or length $2 != 2 or length $3 != 2 or
            length $4 != 2 or length $5 != 2) {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error');
        }

        if (1 <= $2 and $2 <= 12) {
          $self->{onerror}->(node => $input_node, type => 'datetime:bad day')
              if $3 < 1 or
                  $3 > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$2];
          $self->{onerror}->(node => $input_node, type => 'datetime:bad day')
              if $2 == 2 and $3 == 29 and
                  not ($1 % 400 == 0 or ($1 % 4 == 0 and $1 % 100 != 0));
        } else {
          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad month');
        }

        ($hour, $minute, $second) = ($4, $5, $6);
          
        if (defined $7) { ## [+-]hh:mm
          if (length $7 != 2 or length $8 != 2) {
            $self->{onerror}->(node => $input_node,
                               type => 'dateortime:syntax error');
          }

          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad timezone hour')
              if $7 > 23;
          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad timezone minute')
              if $8 > 59;
        }
      } else { ## hh:mm
        if (length $1 != 2 or length $9 != 2) {
          $self->{onerror}->(node => $input_node,
                             type => qq'dateortime:syntax error');
        }

        ($hour, $minute, $second) = ($1, $9, $10);
      }

      $self->{onerror}->(node => $input_node, type => 'datetime:bad hour')
          if $hour > 23;
      $self->{onerror}->(node => $input_node, type => 'datetime:bad minute')
          if $minute > 59;

      if (defined $second) { ## s
        ## NOTE: Integer part of second don't have to have length of two.
          
        if (substr ($second, 0, 1) eq '.') {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error');
        }
          
        $self->{onerror}->(node => $input_node, type => 'datetime:bad second')
            if $second >= 60;
      }        
    } else {
      $self->{onerror}->(node => $input_node,
                         type => 'dateortime:syntax error');
    }

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{meter} = { ## TODO: "The recommended way of giving the value is to include it as contents of the element"
  status => FEATURE_HTML5_DEFAULT,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    value => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    min => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    low => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    high => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    max => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    optimum => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    high => FEATURE_HTML5_DEFAULT,
    low => FEATURE_HTML5_DEFAULT,
    max => FEATURE_HTML5_DEFAULT,
    min => FEATURE_HTML5_DEFAULT,
    optimum => FEATURE_HTML5_DEFAULT,
    value => FEATURE_HTML5_DEFAULT,
  }),
};

$Element->{$HTML_NS}->{progress} = { ## TODO: recommended to use content
  status => FEATURE_HTML5_DEFAULT,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    value => $GetHTMLFloatingPointNumberAttrChecker->(sub { shift >= 0 }),
    max => $GetHTMLFloatingPointNumberAttrChecker->(sub { shift > 0 }),
  }, {
    %HTMLAttrStatus,
    max => FEATURE_HTML5_DEFAULT,
    value => FEATURE_HTML5_DEFAULT,
  }),
};

$Element->{$HTML_NS}->{code} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{var} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{samp} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{kbd} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{sub} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdapref => FEATURE_HTML2X_RFC,
  }),
};

$Element->{$HTML_NS}->{sup} = $Element->{$HTML_NS}->{sub};

$Element->{$HTML_NS}->{span} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML2X_RFC,
  }),
};

$Element->{$HTML_NS}->{i} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{b} = $Element->{$HTML_NS}->{i};

$Element->{$HTML_NS}->{tt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{s} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_M12N10_REC_DEPRECATED,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{strike} = $Element->{$HTML_NS}->{s};

$Element->{$HTML_NS}->{u} = $Element->{$HTML_NS}->{s};

$Element->{$HTML_NS}->{bdo} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({}, {
      %HTMLAttrStatus,
      class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      style => FEATURE_XHTML10_REC,
      title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      sdapref => FEATURE_HTML2X_RFC,
      sdasuff => FEATURE_HTML2X_RFC,
    })->($self, $item, $element_state);
    unless ($item->{node}->has_attribute_ns (undef, 'dir')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:dir');
    }
  },
  ## ISSUE: The spec does not directly say that |dir| is a enumerated attr.
};

=pod

## TODO: 

+
+  <p>Partly because of the confusion described above, authors are
+  strongly recommended to always mark up all paragraphs with the
+  <code>p</code> element, and to not have any <code>ins</code> or
+  <code>del</code> elements that cross across any <span
+  title="paragraph">implied paragraphs</span>.</p>
+
(An informative note)

<p><code>ins</code> elements should not cross <span
+  title="paragraph">implied paragraph</span> boundaries.</p>
(normative)

+  <p><code>del</code> elements should not cross <span
+  title="paragraph">implied paragraph</span> boundaries.</p>
(normative)

=cut

$Element->{$HTML_NS}->{ins} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    datetime => $HTMLDatetimeAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    datetime => FEATURE_HTML5_FD | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
  },
};

$Element->{$HTML_NS}->{del} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    datetime => $HTMLDatetimeAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    datetime => FEATURE_HTML5_FD | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{has_significant}) {
      ## NOTE: Significantness flag does not propagate.
    } elsif ($item->{transparent}) {
      #
    } else {
      $self->{onerror}->(node => $item->{node},
                         level => $self->{should_level},
                         type => 'no significant content');
    }
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
  },
};

$Element->{$HTML_NS}->{figure} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_FD,
  ## NOTE: legend, Flow | Flow, legend?
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
      $element_state->{has_non_legend} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'legend') {
      if ($element_state->{has_legend_at_first}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:figure legend',
                           level => $self->{must_level});
      } elsif ($element_state->{has_legend}) {
        $self->{onerror}->(node => $element_state->{has_legend},
                           type => 'element not allowed:figure legend',
                           level => $self->{must_level});
        $element_state->{has_legend} = $child_el;
      } elsif ($element_state->{has_non_legend}) {
        $element_state->{has_legend} = $child_el;
      } else {
        $element_state->{has_legend_at_first} = 1;
      }
      delete $element_state->{has_non_legend};
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
      $element_state->{has_non_legend} = 1 unless $child_is_transparent;
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{has_non_legend} = 1;
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    if ($element_state->{has_legend_at_first}) {
      #
    } elsif ($element_state->{has_legend}) {
      if ($element_state->{has_non_legend}) {
        $self->{onerror}->(node => $element_state->{has_legend},
                           type => 'element not allowed:figure legend',
                           level => $self->{must_level});
      }
    }

    $HTMLFlowContentChecker{check_end}->(@_);
## ISSUE: |<figure><legend>aa</legend></figure>| should be an error?
  },
};
## TODO: Test for <nest/> in <figure/>

$Element->{$HTML_NS}->{img} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      align => $GetHTMLEnumeratedAttrChecker->({
        bottom => 1, middle => 1, top => 1, left => 1, right => 1,
      }),
      alt => sub { }, ## NOTE: No syntactical requirement
      border => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      src => $HTMLURIAttrChecker,
      usemap => $HTMLUsemapAttrChecker,
      hspace => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      ismap => sub {
        my ($self, $attr, $parent_item) = @_;
        if (not $self->{flag}->{in_a_href}) {
          $self->{onerror}->(node => $attr,
                             type => 'attribute not allowed:ismap',
                             level => $self->{must_level});
        }
        $GetHTMLBooleanAttrChecker->('ismap')->($self, $attr, $parent_item);
      },
      longdesc => $HTMLURIAttrChecker,
      ## TODO: HTML4 |name|
      ## TODO: height
      vspace => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      ## TODO: width
    }, {
      %HTMLAttrStatus,
      %HTMLM12NCommonAttrStatus,
      align => FEATURE_M12N10_REC_DEPRECATED,
      alt => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      border => FEATURE_M12N10_REC_DEPRECATED,
      height => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      hspace => FEATURE_M12N10_REC_DEPRECATED,
      ismap => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      longdesc => FEATURE_M12N10_REC,
      name => FEATURE_M12N10_REC_DEPRECATED,
      sdapref => FEATURE_HTML20_RFC,
      src => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      usemap => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      vspace => FEATURE_M12N10_REC_DEPRECATED,
      width => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    })->($self, $item, $element_state);
    unless ($item->{node}->has_attribute_ns (undef, 'alt')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:alt',
                         level => $self->{should_level});
    }
    unless ($item->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:src');
    }

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{lowsrc}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{dynsrc}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{longdesc}->{type}->{cite} = 1;
  },
};

$Element->{$HTML_NS}->{iframe} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      ## NOTE: Not part of M12N10 Strict
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_XHTML10_REC,
    class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    frameborder => FEATURE_M12N10_REC,
    height => FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    longdesc => FEATURE_M12N10_REC,
    marginheight => FEATURE_M12N10_REC,
    marginwidth => FEATURE_M12N10_REC,
    name => FEATURE_M12N10_REC_DEPRECATED,
    scrolling => FEATURE_M12N10_REC,
    src => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

$Element->{$HTML_NS}->{embed} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $has_src;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        if ($attr_ln eq 'src') {
          $checker = $HTMLURIAttrChecker;
          $has_src = 1;
        } elsif ($attr_ln eq 'type') {
          $checker = $HTMLIMTAttrChecker;
        } else {
          ## TODO: height
          ## TODO: width
          $checker = $HTMLAttrChecker->{$attr_ln}
            || sub { }; ## NOTE: Any local attribute is ok.
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};

      my $status = {
        %HTMLAttrStatus,
        height => FEATURE_HTML5_DEFAULT,
        src => FEATURE_HTML5_DEFAULT,
        type => FEATURE_HTML5_DEFAULT,
        width => FEATURE_HTML5_DEFAULT,
      }->{$attr_ln};

      if ($checker) {
        $checker->($self, $attr, $item, $element_state);
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No conformance createria for global attributes in the spec
      }

      if ($attr_ns eq '') {
        $self->_attr_status_info ($attr, $status) if $status;
      }
    }

    unless ($has_src) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:src');
    }

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

## TODO:
## {applet} FEATURE_M12N10_REC_DEPRECATED
## class, id, title, alt, archive, code, codebase, height, object, width name style,hspace,vspace(xhtml10)

$Element->{$HTML_NS}->{object} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      align => $GetHTMLEnumeratedAttrChecker->({
        bottom => 1, middle => 1, top => 1, left => 1, right => 1,
      }),
      archive => $HTMLSpaceURIsAttrChecker,
          ## TODO: Relative to @codebase
      border => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      classid => $HTMLURIAttrChecker,
      codebase => $HTMLURIAttrChecker,
      codetype => $HTMLIMTAttrChecker,
          ## TODO: "RECOMMENDED when |classid| is specified" [HTML4]
      data => $HTMLURIAttrChecker,
      declare => $GetHTMLBooleanAttrChecker->('declare'),
          ## NOTE: "The object MUST be instantiated by a subsequent OBJECT ..."
          ## [HTML4] but we don't know how to test this.
      hspace => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      ## TODO: HTML4 |name|
      standby => sub {}, ## NOTE: %Text; in HTML4
      type => $HTMLIMTAttrChecker,
      usemap => $HTMLUsemapAttrChecker,
      vspace => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      ## TODO: width
      ## TODO: height
    }, {
      %HTMLAttrStatus,
      %HTMLM12NCommonAttrStatus,
      align => FEATURE_XHTML10_REC,
      archive => FEATURE_M12N10_REC,
      border => FEATURE_XHTML10_REC,
      classid => FEATURE_M12N10_REC,
      codebase => FEATURE_M12N10_REC,
      codetype => FEATURE_M12N10_REC,
      data => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      datafld => FEATURE_HTML4_REC_RESERVED,
      dataformatas => FEATURE_HTML4_REC_RESERVED,
      datasrc => FEATURE_HTML4_REC_RESERVED,
      declare => FEATURE_M12N10_REC,
      height => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      hspace => FEATURE_XHTML10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      name => FEATURE_M12N10_REC,
      standby => FEATURE_M12N10_REC,
      tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      usemap => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      vspace => FEATURE_XHTML10_REC,
      width => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    })->($self, $item, $element_state);
    unless ($item->{node}->has_attribute_ns (undef, 'data')) {
      unless ($item->{node}->has_attribute_ns (undef, 'type')) {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:data|type');
      }
    }

    $element_state->{uri_info}->{data}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{classid}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{codebase}->{type}->{base} = 1;
    ## TODO: archive
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  },
  ## NOTE: param*, transparent (Flow)
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
      $element_state->{has_non_legend} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'param') {
      if ($element_state->{has_non_param}) {
        $self->{onerror}->(node => $child_el, ## TODO: type
                           type => 'element not allowed:flow',
                           level => $self->{must_level});
      }
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
      $element_state->{has_non_param} = 1;
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{has_non_param} = 1;
    }
  },   
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{has_significant}) {
      $item->{real_parent_state}->{has_significant} = 1;
    } elsif ($item->{node}->manakai_parent_element) {
      ## NOTE: Transparent.
    } else {
      $self->{onerror}->(node => $item->{node},
                         level => $self->{should_level},
                         type => 'no significant content');
    }
  },
## TODO: Tests for <nest/> in <object/>
};
## ISSUE: Is |<menu><object data><li>aa</li></object></menu>| conforming?
## What about |<section><object data><style scoped></style>x</object></section>|?
## |<section><ins></ins><object data><style scoped></style>x</object></section>|?

$Element->{$HTML_NS}->{param} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      name => sub { },
      type => $HTMLIMTAttrChecker,
      value => sub { },
      valuetype => $GetHTMLEnumeratedAttrChecker->({
        data => 1, ref => 1, object => 1,
      }),
    }, {
      %HTMLAttrStatus,
      id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      type => FEATURE_M12N10_REC,
      value => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      valuetype => FEATURE_M12N10_REC,
    })->(@_);
    unless ($item->{node}->has_attribute_ns (undef, 'name')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:name');
    }
    unless ($item->{node}->has_attribute_ns (undef, 'value')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:value');
    }
  },
};

$Element->{$HTML_NS}->{video} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
    ## TODO: start, loopstart, loopend, end
    ## ISSUE: they MUST be "value time offset"s.  Value?
    ## ISSUE: playcount has no conformance creteria
    autoplay => $GetHTMLBooleanAttrChecker->('autoplay'),
    controls => $GetHTMLBooleanAttrChecker->('controls'),
    poster => $HTMLURIAttrChecker,
    ## TODO: width, height
  }, {
    %HTMLAttrStatus,
    autoplay => FEATURE_HTML5_LC,
    controls => FEATURE_HTML5_LC,
    end => FEATURE_HTML5_LC,
    height => FEATURE_HTML5_LC,
    loopend => FEATURE_HTML5_LC,
    loopstart => FEATURE_HTML5_LC,
    playcount => FEATURE_HTML5_LC,
    poster => FEATURE_HTML5_LC,
    src => FEATURE_HTML5_LC,
    start => FEATURE_HTML5_LC,
    width => FEATURE_HTML5_LC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{allow_source}
        = not $item->{node}->has_attribute_ns (undef, 'src');
    $element_state->{has_source} ||= $element_state->{allow_source} * -1;
      ## NOTE: It might be set true by |check_element|.

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{poster}->{type}->{embedded} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
      delete $element_state->{allow_source};
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'source') {
      unless ($element_state->{allow_source}) {
        $self->{onerror}->(node => $child_el, ## TODO: type
                         type => 'element not allowed:flow',
                         level => $self->{must_level});
      }
      $element_state->{has_source} = 1;
    } else {
      delete $element_state->{allow_source};
      $HTMLFlowContentChecker{check_child_element}->(@_);
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      delete $element_state->{allow_source};
    }
    $HTMLFlowContentChecker{check_child_text}->(@_);
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{has_source} == -1) { 
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:source',
                         level => $self->{must_level});
    }

    $Element->{$HTML_NS}->{object}->{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{audio} = {
  %{$Element->{$HTML_NS}->{video}},
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
    ## TODO: start, loopstart, loopend, end
    ## ISSUE: they MUST be "value time offset"s.  Value?
    ## ISSUE: playcount has no conformance creteria
    autoplay => $GetHTMLBooleanAttrChecker->('autoplay'),
    controls => $GetHTMLBooleanAttrChecker->('controls'),
  }, {
    %HTMLAttrStatus,
    autoplay => FEATURE_HTML5_LC,
    controls => FEATURE_HTML5_LC,
    end => FEATURE_HTML5_LC,
    loopend => FEATURE_HTML5_LC,
    loopstart => FEATURE_HTML5_LC,
    playcount => FEATURE_HTML5_LC,
    src => FEATURE_HTML5_LC,
    start => FEATURE_HTML5_LC,
  }),
};

$Element->{$HTML_NS}->{source} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      src => $HTMLURIAttrChecker,
      type => $HTMLIMTAttrChecker,
      media => $HTMLMQAttrChecker,
    }, {
      %HTMLAttrStatus,
      media => FEATURE_HTML5_DEFAULT,
      src => FEATURE_HTML5_DEFAULT,
      type => FEATURE_HTML5_DEFAULT,
    })->(@_);
    unless ($item->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:src');
    }

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

$Element->{$HTML_NS}->{canvas} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    height => FEATURE_HTML5_LC,
    width => FEATURE_HTML5_LC,
  }),
};

$Element->{$HTML_NS}->{map} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $has_id;
    $GetHTMLAttrsChecker->({
      id => sub {
        ## NOTE: same as global |id=""|, with |$self->{map}| registeration
        my ($self, $attr) = @_;
        my $value = $attr->value;
        if (length $value > 0) {
          if ($self->{id}->{$value}) {
            $self->{onerror}->(node => $attr, type => 'duplicate ID');
            push @{$self->{id}->{$value}}, $attr;
          } else {
            $self->{id}->{$value} = [$attr];
          }
        } else {
          ## NOTE: MUST contain at least one character
          $self->{onerror}->(node => $attr, type => 'empty attribute value');
        }
        if ($value =~ /[\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $attr, type => 'space in ID');
        }
        $self->{map}->{$value} ||= $attr;
        $has_id = 1;
      },
      ## TODO: HTML4 |name|
    }, {
      %HTMLAttrStatus,
      class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      name => FEATURE_M12N10_REC_DEPRECATED,
      onclick => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      ondblclick => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onmousedown => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onmouseup => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onmouseover => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onmousemove => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onmouseout => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onkeypress => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onkeydown => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      onkeyup => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    })->(@_);
    $self->{onerror}->(node => $item->{node}, type => 'attribute missing:id')
        unless $has_id;
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{in_map_original} = $self->{flag}->{in_map};
    $self->{flag}->{in_map} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    delete $self->{flag}->{in_map} unless $element_state->{in_map_original};
    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{area} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my %attr;
    my $coords;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = {
          accesskey => $HTMLAccesskeyAttrChecker,
                     alt => sub { },
                         ## NOTE: |alt| value has no conformance creteria.
                     shape => $GetHTMLEnumeratedAttrChecker->({
                       circ => -1, circle => 1,
                       default => 1,
                       poly => 1, polygon => -1,
                       rect => 1, rectangle => -1,
                     }),
                     coords => sub {
                       my ($self, $attr) = @_;
                       my $value = $attr->value;
                       if ($value =~ /\A-?[0-9]+(?>,-?[0-9]+)*\z/) {
                         $coords = [split /,/, $value];
                       } else {
                         $self->{onerror}->(node => $attr,
                                            type => 'coords:syntax error');
                       }
                     },
          nohref => $GetHTMLBooleanAttrChecker->('nohref'),
          target => $HTMLTargetAttrChecker,
                     href => $HTMLURIAttrChecker,
                     ping => $HTMLSpaceURIsAttrChecker,
                     rel => sub { $HTMLLinkTypesAttrChecker->(1, $item, @_) },
                     media => $HTMLMQAttrChecker,
                     hreflang => $HTMLLanguageTagAttrChecker,
                     type => $HTMLIMTAttrChecker,
                   }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};

      my $status = {
        %HTMLAttrStatus,
        %HTMLM12NCommonAttrStatus,
        accesskey => FEATURE_M12N10_REC,
        alt => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        coords => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        href => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        hreflang => FEATURE_HTML5_DEFAULT,
        lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
        media => FEATURE_HTML5_DEFAULT,
        nohref => FEATURE_M12N10_REC,
        onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        ping => FEATURE_HTML5_DEFAULT,
        rel => FEATURE_HTML5_DEFAULT,
        shape => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        target => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        type => FEATURE_HTML5_DEFAULT,
      }->{$attr_ln};

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }

      if ($attr_ns eq '') {
        $self->_attr_status_info ($attr, $status);
      }
    }

    if (defined $attr{href}) {
      $self->{has_hyperlink_element} = 1;
      unless (defined $attr{alt}) {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:alt');
      }
    } else {
      for (qw/target ping rel media hreflang type alt/) {
        if (defined $attr{$_}) {
          $self->{onerror}->(node => $attr{$_},
                             type => 'attribute not allowed');
        }
      }
    }

    my $shape = 'rectangle';
    if (defined $attr{shape}) {
      $shape = {
                circ => 'circle', circle => 'circle',
                default => 'default',
                poly => 'polygon', polygon => 'polygon',
                rect => 'rectangle', rectangle => 'rectangle',
               }->{lc $attr{shape}->value} || 'rectangle';
      ## TODO: ASCII lowercase?
    }

    if ($shape eq 'circle') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords == 3) {
            if ($coords->[2] < 0) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range:2');
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number:3:'.@$coords);
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:coords');
      }
    } elsif ($shape eq 'default') {
      if (defined $attr{coords}) {
        $self->{onerror}->(node => $attr{coords},
                           type => 'attribute not allowed');
      }
    } elsif ($shape eq 'polygon') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords >= 6) {
            unless (@$coords % 2 == 0) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:number:even:'.@$coords);
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number:>=6:'.@$coords);
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:coords');
      }
    } elsif ($shape eq 'rectangle') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords == 4) {
            unless ($coords->[0] < $coords->[2]) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range:0');
            }
            unless ($coords->[1] < $coords->[3]) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range:1');
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number:4:'.@$coords);
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:coords');
      }
    }

    $element_state->{uri_info}->{href}->{type}->{hyperlink} = 1;
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    unless ($self->{flag}->{in_map} or
            not $item->{node}->manakai_parent_element) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element not allowed:area',
                         level => $self->{must_level});
    }
  },
};

$Element->{$HTML_NS}->{table} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: HTML4 |cellspacing|, |cellpadding|
    frame => $GetHTMLEnumeratedAttrChecker->({
      void => 1, above => 1, below => 1, hsides => 1, vsides => 1,
      lhs => 1, rhs => 1, box => 1, border => 1,
    }),
    rules => $GetHTMLEnumeratedAttrChecker->({
      none => 1, groups => 1, rows => 1, cols => 1, all => 1,
    }),
    summary => sub {}, ## NOTE: %Text; in HTML4.
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }), ## %Pixels;
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    border => FEATURE_M12N10_REC,
    cellpadding => FEATURE_M12N10_REC,
    cellspacing => FEATURE_M12N10_REC,
    cols => FEATURE_RFC1942,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datapagesize => FEATURE_M12N10_REC,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    frame => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    rules => FEATURE_M12N10_REC,
    summary => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before caption';

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'in tbodys') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'tbody') {
        #$element_state->{phase} = 'in tbodys';
      } elsif (not $element_state->{has_tfoot} and
               $child_nsuri eq $HTML_NS and $child_ln eq 'tfoot') {
        $element_state->{phase} = 'after tfoot';
        $element_state->{has_tfoot} = 1;
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'in trs') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
        #$element_state->{phase} = 'in trs';
      } elsif (not $element_state->{has_tfoot} and
               $child_nsuri eq $HTML_NS and $child_ln eq 'tfoot') {
        $element_state->{phase} = 'after tfoot';
        $element_state->{has_tfoot} = 1;
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'after thead') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'tbody') {
        $element_state->{phase} = 'in tbodys';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
        $element_state->{phase} = 'in trs';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tfoot') {
        $element_state->{phase} = 'in tbodys';
        $element_state->{has_tfoot} = 1;
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'in colgroup') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'colgroup') {
        $element_state->{phase} = 'in colgroup';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'thead') {
        $element_state->{phase} = 'after thead';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tbody') {
        $element_state->{phase} = 'in tbodys';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
        $element_state->{phase} = 'in trs';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tfoot') {
        $element_state->{phase} = 'in tbodys';
        $element_state->{has_tfoot} = 1;
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'before caption') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'caption') {
        $element_state->{phase} = 'in colgroup';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'colgroup') {
        $element_state->{phase} = 'in colgroup';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'thead') {
        $element_state->{phase} = 'after thead';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tbody') {
        $element_state->{phase} = 'in tbodys';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
        $element_state->{phase} = 'in trs';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tfoot') {
        $element_state->{phase} = 'in tbodys';
        $element_state->{has_tfoot} = 1;
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($element_state->{phase} eq 'after tfoot') {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    } else {
      die "check_child_element: Bad |table| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## Table model errors
    require Whatpm::HTMLTable;
    Whatpm::HTMLTable->form_table ($item->{node}, sub {
      my %opt = @_;
      $self->{onerror}->(type => 'table:'.$opt{type}, node => $opt{node});
    });
    push @{$self->{return}->{table}}, $item->{node};

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{caption} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      top => 1, bottom => 1, left => 1, right => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

my %cellalign = (
  ## HTML4 %cellhalign;
  align => $GetHTMLEnumeratedAttrChecker->({
    left => 1, center => 1, right => 1, justify => 1, char => 1,
  }),
  char => sub {
    my ($self, $attr) = @_;

    ## NOTE: "character" or |%Character;| in HTML4.
    
    my $value = $attr->value;
    if (length $value != 1) {
      $self->{onerror}->(node => $attr, type => 'char:syntax error',
                         level => $self->{fact_level}); ## TODO: type
    }
  },
  ## TODO: HTML4 |charoff|  
  ## HTML4 %cellvalign;
  valign => $GetHTMLEnumeratedAttrChecker->({
    top => 1, middle => 1, bottom => 1, baseline => 1,
  }),
);

$Element->{$HTML_NS}->{colgroup} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
      ## NOTE: Defined only if "the |colgroup| element contains no |col| elements"
      ## TODO: "attribute not supported" if |col|.
      ## ISSUE: MUST NOT if any |col|?
      ## ISSUE: MUST NOT for |<colgroup span="1"><any><col/></any></colgroup>| (though non-conforming)?
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    span => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'col') {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
};

$Element->{$HTML_NS}->{col} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    span => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC,
  }),
};

$Element->{$HTML_NS}->{tbody} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    valign => FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
      $element_state->{has_tr} = 1;
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{has_tr}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:tr');
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{thead} = {
  %{$Element->{$HTML_NS}->{tbody}},
};

$Element->{$HTML_NS}->{tfoot} = {
  %{$Element->{$HTML_NS}->{tbody}},
};

$Element->{$HTML_NS}->{tr} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    bgcolor => $HTMLColorAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    valign => FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and
             ($child_ln eq 'td' or $child_ln eq 'th')) {
      $element_state->{has_cell} = 1;
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{has_cell}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:td|th');
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{td} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    abbr => sub {}, ## NOTE: HTML4 %Text; and SHOULD be short.
    axis => sub {}, ## NOTE: HTML4 "cdata", comma-separated
    bgcolor => $HTMLColorAttrChecker,
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    ## TODO: HTML5 |headers|
    nowrap => $GetHTMLBooleanAttrChecker->('nowrap'),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    abbr => FEATURE_M12N10_REC,
    align => FEATURE_M12N10_REC,
    axis => FEATURE_M12N10_REC,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    colspan => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    headers => FEATURE_M12N10_REC,
    height => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    nowrap => FEATURE_M12N10_REC_DEPRECATED,
    rowspan => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    scope => FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

$Element->{$HTML_NS}->{th} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    abbr => sub {}, ## NOTE: HTML4 %Text; and SHOULD be short.
    axis => sub {}, ## NOTE: HTML4 "cdata", comma-separated
    bgcolor => $HTMLColorAttrChecker,
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    ## TODO: HTML5 |headers|
    nowrap => $GetHTMLBooleanAttrChecker->('nowrap'),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    abbr => FEATURE_M12N10_REC,
    align => FEATURE_M12N10_REC,
    axis => FEATURE_M12N10_REC,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    colspan => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    headers => FEATURE_M12N10_REC,
    height => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    nowrap => FEATURE_M12N10_REC_DEPRECATED,
    rowspan => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    scope => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

my $AttrCheckerNotImplemented = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr, level => 'unsupported',
                     type => 'attribute');
};

$Element->{$HTML_NS}->{form} = {
  %HTMLFlowContentChecker, ## NOTE: Flow* [WF2]
    ## TODO: form in form is allowed in XML [WF2]
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => $AttrCheckerNotImplemented, ## TODO: ContentTypes [WF2]
    'accept-charset' => $AttrCheckerNotImplemented, ## TODO: Charsets
    action => $HTMLURIAttrChecker, ## TODO: "User agent behavior for a value other than HTTP URI is undefined" [HTML4]
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
    enctype => $HTMLIMTAttrChecker, ## TODO: "multipart/form-data" should be used when type=file is used [HTML4] ## TODO: MUST NOT parameter [WF2]
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
        ## NOTE: "get" SHOULD be used for idempotent submittion,
        ## "post" SHOULD be used otherwise [HTML4].  This cannot be tested.
    name => sub { }, # CDATA in HTML4 ## TODO: must be same as |id| (informative!) [XHTML10]
    onreceived => $HTMLEventHandlerAttrChecker,
    replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
    target => $HTMLTargetAttrChecker,
    ## TODO: Warn for combination whose behavior is not defined.
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_WF2 | FEATURE_M12N10_REC,
    'accept-charset' => FEATURE_M12N10_REC,
    action => FEATURE_WF2 | FEATURE_M12N10_REC,
    data => FEATURE_WF2,
    enctype => FEATURE_WF2 | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    method => FEATURE_WF2 | FEATURE_M12N10_REC,
    name => FEATURE_M12N10_REC_DEPRECATED,
    onreceived => FEATURE_WF2,
    onreset => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onsubmit => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    replace => FEATURE_WF2,
    sdapref => FEATURE_HTML20_RFC,
    sdasuff => FEATURE_HTML20_RFC,
    target => FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <form>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{fieldset} = {
  %HTMLFlowContentChecker, ## NOTE: legend, %Flow; ## TODO: legend
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    ## TODO: form [WF2]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_WF2,
    form => FEATURE_WF2,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <fieldset>
};

$Element->{$HTML_NS}->{input} = {
  %HTMLEmptyChecker, ## MUST [WF2]
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => $AttrCheckerNotImplemented, ## TODO: ContentTypes [WF2]
    accesskey => $HTMLAccesskeyAttrChecker,
    action => $HTMLURIAttrChecker,
    align => $GetHTMLEnumeratedAttrChecker->({
      top => 1, middle => 1, bottom => 1, left => 1, right => 1,
    }),
    alt => sub {}, ## NOTE: Text [M12N] ## TODO: |alt| should be provided for |type=image| [HTML4]
        ## NOTE: HTML4 has a "should" for accessibility, which cannot be tested
        ## here.
    autocomplete => $GetHTMLEnumeratedAttrChecker->({on => 1, off => 1}),
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    checked => $GetHTMLBooleanAttrChecker->('checked'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    enctype => $HTMLIMTAttrChecker,
    ## TODO: form [WF2]
    ## TODO: inputmode [WF2]
    ismap => $GetHTMLBooleanAttrChecker->('ismap'),
    ## TODO: list [WF2]
    ## TODO: max [WF2]
    maxlength => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
    ## TODO: min [WF2]
    name => sub {}, ## NOTE: CDATA [M12N]
    readonly => $GetHTMLBooleanAttrChecker->('readonly'),
    replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
    required => $GetHTMLBooleanAttrChecker->('required'),
    size => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    src => $HTMLURIAttrChecker,
    ## TODO: step [WF2]
    target => $HTMLTargetAttrChecker,
    ## TODO: template
    type => $GetHTMLEnumeratedAttrChecker->({
      text => 1, password => 1, checkbox => 1, radio => 1, submit => 1,
      reset => 1, file => 1, hidden => 1, image => 1, button => 1,
      ## [WF2]
      datatime => 1, 'datetime-local' => 1, date => 1, month => 1, week => 1,
      time => 1, number => 1, range => 1, email => 1, url => 1,
      add => 1, remove => 1, 'move-up' => 1, 'move-down' => 1,
    }),
    usemap => $HTMLUsemapAttrChecker,
    value => sub {}, ## NOTE: CDATA [M12N] ## TODO: "optional except when the type attribute has the value "radio" or "checkbox"" [HTML4] ## TODO: constraints [WF2]
    ## TODO: "authors should ensure that in each set of radio buttons that one is initially "on"." [HTML4] [WF2]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_WF2 | FEATURE_M12N10_REC,
    'accept-charset' => FEATURE_HTML2X_RFC,
    accesskey => FEATURE_M12N10_REC,
    action => FEATURE_WF2,
    align => FEATURE_M12N10_REC_DEPRECATED,
    alt => FEATURE_M12N10_REC,
    autocomplete => FEATURE_WF2,
    autofocus => FEATURE_WF2,
    checked => FEATURE_M12N10_REC,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_WF2 | FEATURE_M12N10_REC,
    enctype => FEATURE_WF2,
    form => FEATURE_WF2,
    inputmode => FEATURE_WF2 | FEATURE_XHTMLBASIC11_CR,
    ismap => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    list => FEATURE_WF2,
    max => FEATURE_WF2,
    maxlength => FEATURE_WF2 | FEATURE_M12N10_REC,
    method => FEATURE_WF2,
    min => FEATURE_WF2,
    name => FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onselect => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    readonly => FEATURE_WF2 | FEATURE_M12N10_REC,
    replace => FEATURE_WF2,
    required => FEATURE_WF2,
    sdapref => FEATURE_HTML20_RFC,
    size => FEATURE_WF2_DEPRECATED | FEATURE_M12N10_REC,
    src => FEATURE_M12N10_REC,
    step => FEATURE_WF2,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    target => FEATURE_WF2,
    template => FEATURE_WF2,
    type => FEATURE_M12N10_REC,
    usemap => FEATURE_HTML5_DROPPED | FEATURE_M12N10_REC,
    value => FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <input>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

## TODO: Form |name| attributes: MUST NOT conflict with RFC 3106 [WF2]

$Element->{$HTML_NS}->{button} = {
  %HTMLFlowContentChecker, ## NOTE: %Flow; - something [XHTML10]
    ## TODO: -A|%formctrl;|form|fieldset [HTML4]
    ## TODO: image map (img) in |button| is "illegal" [HTML4].
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
    action => $HTMLURIAttrChecker,
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    ## TODO: form [WF2]
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
    name => sub {}, ## NOTE: CDATA [M12N]
    oninvalid => $HTMLEventHandlerAttrChecker,
    replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
    target => $HTMLTargetAttrChecker,
    ## TODO: template [WF2]
    type => $GetHTMLEnumeratedAttrChecker->({
      button => 1, submit => 1, reset => 1,
    }),
    value => sub {}, ## NOTE: CDATA [M12N]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_M12N10_REC,
    action => FEATURE_WF2,
    autofocus => FEATURE_WF2,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_WF2 | FEATURE_M12N10_REC,
    enctype => FEATURE_WF2,
    form => FEATURE_WF2,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    method => FEATURE_WF2,
    name => FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    oninvalid => FEATURE_WF2,
    replace => FEATURE_WF2,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    target => FEATURE_WF2,
    template => FEATURE_WF2,
    type => FEATURE_M12N10_REC,
    value => FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <button>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{label} = {
  %HTMLPhrasingContentChecker, ## NOTE: %Inline - label [XHTML10] ## TODO: -label
    ## TODO: At most one form control [WF2]
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
    for => $AttrCheckerNotImplemented, ## TODO: IDREF ## TODO: Must be |id| of control [HTML4] ## TODO: Or, "may only contain one control element"
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_WF2 | FEATURE_M12N10_REC,
    for => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <label>
};

$Element->{$HTML_NS}->{select} = {
  %HTMLFlowContentChecker, ## TODO: (optgroup|option)* [HTML4] + [WF2] ## TODO: SHOULD avoid empty and visible [WF2]
    ## TODO: author should SELECTED at least one OPTION in non-MULTIPLE case [HTML4].
    ## TODO: more than one OPTION with SELECTED in non-MULTIPLE case is "error" [HTML4]
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  is_root => 1, ## TODO: SHOULD NOT in application/xhtml+xml [WF2]
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
    ## TODO: form [WF2]
    multiple => $GetHTMLBooleanAttrChecker->('multiple'),
    name => sub {}, ## NOTE: CDATA [M12N]
    oninvalid => $HTMLEventHandlerAttrChecker,
    ## TODO: pattern [WF2] ## TODO: |title| semantics
    size => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_WF2,
    autofocus => FEATURE_WF2,
    data => FEATURE_WF2,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_WF2 | FEATURE_M12N10_REC,
    form => FEATURE_WF2,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    multiple => FEATURE_M12N10_REC,
    name => FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    oninvalid => FEATURE_WF2,
    pattern => FEATURE_WF2,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    size => FEATURE_M12N10_REC,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <select>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{datalist} = {
  %HTMLFlowContentChecker, ## TODO: (transparent | option)*
    ## TODO: |option| child MUST be empty [WF2]
  status => FEATURE_WF2,
  check_attrs => $GetHTMLAttrsChecker->({
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
  }, {
    %HTMLAttrStatus,
    data => FEATURE_WF2,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <datalist>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{optgroup} = {
  %HTMLFlowContentChecker, ## TODO: (option|optgroup)* [HTML4] + [WF2] SHOULD avoid empty and visible [WF2]
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    label => sub {}, ## NOTE: Text [M12N] ## TODO: required
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_WF2 | FEATURE_M12N10_REC,
    label => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <optgroup>
};

$Element->{$HTML_NS}->{option} = {
  %HTMLTextChecker,
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    label => sub {}, ## NOTE: Text [M12N]
    selected => $GetHTMLBooleanAttrChecker->('selected'),
    value => sub {}, ## NOTE: CDATA [M12N]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_WF2, FEATURE_M12N10_REC,
    label => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    selected => FEATURE_M12N10_REC,
    value => FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <option>
};

$Element->{$HTML_NS}->{textarea} = {
  %HTMLTextChecker,
  status => FEATURE_WF2 | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => $HTMLIMTAttrChecker, ## TODO: MUST be a text-based type
    accesskey => $HTMLAccesskeyAttrChecker,
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    cols => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }), ## TODO: SHOULD if wrap=hard [WF2]
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    ## TODO: form [WF2]
    ## TODO: inputmode [WF2]
    maxlength => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    name => sub {}, ## NOTE: CDATA [M12N]
    ## TODO: pattern [WF2] ## TODO: |title| special semantics
    readonly => $GetHTMLBooleanAttrChecker->('readonly'),
    required => $GetHTMLBooleanAttrChecker->('required'),
    rows => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    oninvalid => $HTMLEventHandlerAttrChecker,
    wrap => $GetHTMLEnumeratedAttrChecker->({soft => 1, hard => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_WF2,
    'accept-charset' => FEATURE_HTML2X_RFC,
    accesskey => FEATURE_M12N10_REC,
    autofocus => FEATURE_WF2,
    cols => FEATURE_M12N10_REC,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_WF2 | FEATURE_M12N10_REC,
    form => FEATURE_WF2,
    inputmode => FEATURE_WF2 | FEATURE_XHTMLBASIC11_CR,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    maxlength => FEATURE_WF2,
    name => FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    oninvalid => FEATURE_WF2,
    onselect => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    pattern => FEATURE_WF2,
    readonly => FEATURE_WF2 | FEATURE_M12N10_REC,
    required => FEATURE_WF2,
    rows => FEATURE_M12N10_REC, 
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    wrap => FEATURE_WF2,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <textarea>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{output} = {
  %HTMLPhrasingContentChecker, ## Inline [WF2]
  status => FEATURE_WF2,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: for [WF2]
    ## TODO: form [WF2]
    ## TODO: name [WF2]
    ## onformchange[WF2]
    ## onforminput[WF2]
  }, {
    %HTMLAttrStatus,
    for => FEATURE_WF2,
    form => FEATURE_WF2,
    name => FEATURE_WF2,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_WF2,
    onformchange => FEATURE_WF2,
    onforminput => FEATURE_WF2,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <output>
  ## NOTE: "The output  element should be used when ..." [WF2]
};

## TODO: repetition template

$Element->{$HTML_NS}->{isindex} = {
  %HTMLEmptyChecker,
  status => FEATURE_M12N10_REC_DEPRECATED |
      Whatpm::ContentChecker::FEATURE_DEPRECATED_SHOULD, ## [HTML4]
  check_attrs => $GetHTMLAttrsChecker->({
    prompt => sub {}, ## NOTE: Text [M12N]
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    prompt => FEATURE_M12N10_REC_DEPRECATED,
    sdapref => FEATURE_HTML20_RFC,
    style => FEATURE_XHTML10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <isindex>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
  },
};

$Element->{$HTML_NS}->{script} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: HTML4 |charset|
    ## TODO: HTML4 |language|
      src => $HTMLURIAttrChecker,
      defer => $GetHTMLBooleanAttrChecker->('defer'),
      async => $GetHTMLBooleanAttrChecker->('async'),
      type => $HTMLIMTAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    async => FEATURE_HTML5_DEFAULT,
    charset => FEATURE_M12N10_REC,
    defer => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    event => FEATURE_HTML4_REC_RESERVED,
    for => FEATURE_HTML4_REC_RESERVED,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    language => FEATURE_M12N10_REC_DEPRECATED,
    src => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    if ($item->{node}->has_attribute_ns (undef, 'src')) {
      $element_state->{must_be_empty} = 1;
    } else {
      ## NOTE: No content model conformance in HTML5 spec.
      my $type = $item->{node}->get_attribute_ns (undef, 'type');
      my $language = $item->{node}->get_attribute_ns (undef, 'language');
      if ((defined $type and $type eq '') or
          (defined $language and $language eq '')) {
        $type = 'text/javascript';
      } elsif (defined $type) {
        #
      } elsif (defined $language) {
        $type = 'text/' . $language;
      } else {
        $type = 'text/javascript';
      }
      $element_state->{script_type} = $type; ## TODO: $type normalization
    }

    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      if ($element_state->{must_be_empty}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed');
      }
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant and
        $element_state->{must_be_empty}) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed');
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{must_be_empty}) {
      $self->{onerror}->(node => $item->{node}, level => 'unsupported',
                         type => 'script:'.$element_state->{script_type});
      ## TODO: text/javascript support
      
      $HTMLChecker{check_end}->(@_);
    }
  },
};
## ISSUE: Significant check and text child node

## NOTE: When script is disabled.
$Element->{$HTML_NS}->{noscript} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    unless ($item->{node}->owner_document->manakai_is_html) {
      $self->{onerror}->(node => $item->{node}, type => 'in XML:noscript');
    }

    unless ($self->{flag}->{in_head}) {
      $self->_add_minus_elements ($element_state,
                                  {$HTML_NS => {noscript => 1}});
    }
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{flag}->{in_head}) {
      if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:minus',
                           level => $self->{must_level});
      } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
        #
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'link') {
        #
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'style') {
        if ($child_el->has_attribute_ns (undef, 'scoped')) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:head noscript',
                             level => $self->{must_level});
        }
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'meta') {
        my $http_equiv_attr
            = $child_el->get_attribute_node_ns (undef, 'http-equiv');
        if ($http_equiv_attr) {
          ## TODO: case
          if (lc $http_equiv_attr->value eq 'content-type') {
            $self->{onerror}->(node => $child_el,
                               type => 'element not allowed:head noscript',
                               level => $self->{must_level});
          } else {
            #
          }
        } else {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:head noscript',
                             level => $self->{must_level});
        }
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:head noscript',
                           level => $self->{must_level});
      }
    } else {
      $HTMLTransparentChecker{check_child_element}->(@_);
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($self->{flag}->{in_head}) {
      if ($has_significant) {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed');
      }
    } else {
      $HTMLTransparentChecker{check_child_text}->(@_);
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    if ($self->{flag}->{in_head}) {
      $HTMLChecker{check_end}->(@_);
    } else {
      $HTMLPhrasingContentChecker{check_end}->(@_);
    }
  },
};
## ISSUE: Scripting is disabled: <head><noscript><html a></noscript></head>

$Element->{$HTML_NS}->{'event-source'} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    src => FEATURE_HTML5_LC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{details} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_WD,
  check_attrs => $GetHTMLAttrsChecker->({
    open => $GetHTMLBooleanAttrChecker->('open'),
  }, {
    %HTMLAttrStatus,
    open => FEATURE_HTML5_WD,
  }),
  ## NOTE: legend, Flow
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
      $element_state->{has_non_legend} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'legend') {
      if ($element_state->{has_non_legend}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:details legend',
                           level => $self->{must_level});
      }
      $element_state->{has_legend} = 1;
      $element_state->{has_non_legend} = 1;
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
      $element_state->{has_non_legend} = 1 unless $child_is_transparent;
      ## ISSUE: |<details><object><legend>xx</legend></object>..</details>|
      ## is conforming?
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{has_non_legend} = 1;
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    unless ($element_state->{has_legend}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:legend',
                         level => $self->{must_level});
    }

    $HTMLFlowContentChecker{check_end}->(@_);
    ## ISSUE: |<details><legend>aa</legend></details>| error?
  },
};

$Element->{$HTML_NS}->{datagrid} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_WD,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    multiple => $GetHTMLBooleanAttrChecker->('multiple'),
  }, {
    %HTMLAttrStatus,
    disabled => FEATURE_HTML5_WD,
    multiple => FEATURE_HTML5_WD,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $self->_add_minus_elements ($element_state,
                                {$HTML_NS => {a => 1, datagrid => 1}});
    $element_state->{phase} = 'any';
  },
  ## Flow -(text* table Flow*) | table | select | datalist | Empty
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'flow') {
      if ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        if (not $element_state->{has_element} and 
            $child_nsuri eq $HTML_NS and
            $child_ln eq 'table') {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed');
        } else {
          #
        }
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed');
      }
      $element_state->{has_element} = 1;
    } elsif ($element_state->{phase} eq 'any') {
      if ($child_nsuri eq $HTML_NS and
          {table => 1, select => 1, datalist => 1}->{$child_ln}) {
        $element_state->{phase} = 'none';
      } elsif ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        $element_state->{has_element} = 1;
        $element_state->{phase} = 'flow';
        ## TODO: transparent?
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed');        
      }
    } elsif ($element_state->{phase} eq 'none') {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed');
    } else {
      die "check_child_element: Bad |datagrid| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      if ($element_state->{phase} eq 'flow') {
        #
      } elsif ($element_state->{phase} eq 'any') {
        $element_state->{phase} = 'flow';
      } else {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed');
      }
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    if ($element_state->{phase} eq 'none') {
      $HTMLChecker{check_end}->(@_);
    } else {
      $HTMLPhrasingContentChecker{check_end}->(@_);
    }
  },
    ## ISSUE: "xxx<table/>" is disallowed; "<select/>aaa" and "<datalist/>aa"
    ## are not disallowed (assuming that form control contents are also
    ## flow content).
};

$Element->{$HTML_NS}->{command} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_WD,
  check_attrs => $GetHTMLAttrsChecker->({
    checked => $GetHTMLBooleanAttrChecker->('checked'),
    default => $GetHTMLBooleanAttrChecker->('default'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    hidden => $GetHTMLBooleanAttrChecker->('hidden'),
    icon => $HTMLURIAttrChecker,
    label => sub { }, ## NOTE: No conformance creteria
    radiogroup => sub { }, ## NOTE: No conformance creteria
    type => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ({command => 1, checkbox => 1, radio => 1}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'attribute value not allowed');
      }
    },
  }, {
    %HTMLAttrStatus,
    checked => FEATURE_HTML5_WD,
    default => FEATURE_HTML5_WD,
    disabled => FEATURE_HTML5_WD,
    hidden => FEATURE_HTML5_WD,
    icon => FEATURE_HTML5_WD,
    label => FEATURE_HTML5_WD,
    radiogroup => FEATURE_HTML5_WD,
    type => FEATURE_HTML5_WD,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{icon}->{type}->{embedded} = 1;
  },
};

$Element->{$HTML_NS}->{menu} = {
  %HTMLPhrasingContentChecker,
  #status => FEATURE_M12N10_REC_DEPRECATED | FEATURE_HTML5_WD,
  status => FEATURE_M12N10_REC | FEATURE_HTML5_WD,
      ## NOTE: We don't want any |menu| element warned as deprecated.
  check_attrs => $GetHTMLAttrsChecker->({
    autosubmit => $GetHTMLBooleanAttrChecker->('autosubmit'),
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    id => sub {
      ## NOTE: same as global |id=""|, with |$self->{menu}| registeration
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if (length $value > 0) {
        if ($self->{id}->{$value}) {
          $self->{onerror}->(node => $attr, type => 'duplicate ID');
          push @{$self->{id}->{$value}}, $attr;
        } else {
          $self->{id}->{$value} = [$attr];
        }
      } else {
        ## NOTE: MUST contain at least one character
        $self->{onerror}->(node => $attr, type => 'empty attribute value');
      }
      if ($value =~ /[\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $attr, type => 'space in ID');
      }
      $self->{menu}->{$value} ||= $attr;
      ## ISSUE: <menu id=""><p contextmenu=""> match?
    },
    label => sub { }, ## NOTE: No conformance creteria
    type => $GetHTMLEnumeratedAttrChecker->({context => 1, toolbar => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    autosubmit => FEATURE_HTML5_WD,
    compat => FEATURE_M12N10_REC_DEPRECATED,
    label => FEATURE_HTML5_WD,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    type => FEATURE_HTML5_WD,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'li or phrasing';
    $element_state->{in_menu_original} = $self->{flag}->{in_menu};
    $self->{flag}->{in_menu} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'li') {
      if ($element_state->{phase} eq 'li') {
        #
      } elsif ($element_state->{phase} eq 'li or phrasing') {
        $element_state->{phase} = 'li';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } elsif ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
      if ($element_state->{phase} eq 'phrasing') {
        #
      } elsif ($element_state->{phase} eq 'li or phrasing') {
        $element_state->{phase} = 'phrasing';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed');
      }
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      if ($element_state->{phase} eq 'phrasing') {
        #
      } elsif ($element_state->{phase} eq 'li or phrasing') {
        $element_state->{phase} = 'phrasing';
      } else {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed');
      }
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    delete $self->{flag}->{in_menu} unless $element_state->{in_menu_original};
    
    if ($element_state->{phase} eq 'li') {
      $HTMLChecker{check_end}->(@_);
    } else { # 'phrasing' or 'li or phrasing'
      $HTMLPhrasingContentChecker{check_end}->(@_);
    }
  },
};

$Element->{$HTML_NS}->{datatemplate} = {
  %HTMLChecker,
  status => FEATURE_HTML5_AT_RISK,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'rule') {
      #
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:datatemplate');
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed');
    }
  },
  is_xml_root => 1,
};

$Element->{$HTML_NS}->{rule} = {
  %HTMLChecker,
  status => FEATURE_HTML5_AT_RISK,
  check_attrs => $GetHTMLAttrsChecker->({
    condition => $HTMLSelectorsAttrChecker,
    mode => $HTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker,
  }, {
    %HTMLAttrStatus,
    condition => FEATURE_HTML5_AT_RISK,
    mode => FEATURE_HTML5_AT_RISK,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_plus_elements ($element_state, {$HTML_NS => {nest => 1}});
  },
  check_child_element => sub { },
  check_child_text => sub { },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_plus_elements ($element_state);
    $HTMLChecker{check_end}->(@_);
  },
  ## NOTE: "MAY be anything that, when the parent |datatemplate|
  ## is applied to some conforming data, results in a conforming DOM tree.":
  ## We don't check against this.
};

$Element->{$HTML_NS}->{nest} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_AT_RISK,
  check_attrs => $GetHTMLAttrsChecker->({
    filter => $HTMLSelectorsAttrChecker,
    mode => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value !~ /\A[^\x09-\x0D\x20]+\z/) {
        $self->{onerror}->(node => $attr, type => 'mode:syntax error');
      }
    },
  }, {
    %HTMLAttrStatus,
    filter => FEATURE_HTML5_AT_RISK,
    mode => FEATURE_HTML5_AT_RISK,
  }),
};

$Element->{$HTML_NS}->{legend} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
#    align => $GetHTMLEnumeratedAttrChecker->({
#      top => 1, bottom => 1, left => 1, right => 1,
#    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_M12N10_REC,
    align => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{div} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{center} = {
  %HTMLFlowContentChecker,
  status => FEATURE_M12N10_REC_DEPRECATED,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
};

$Element->{$HTML_NS}->{font} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_AT_RISK | FEATURE_M12N10_REC_DEPRECATED,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: HTML4 |size|, |color|, |face|
    ## TODO: HTML5 |style|
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    color => FEATURE_M12N10_REC_DEPRECATED,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    face => FEATURE_M12N10_REC_DEPRECATED,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    size => FEATURE_M12N10_REC_DEPRECATED,
    style => FEATURE_HTML5_AT_RISK | FEATURE_XHTML10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
};

$Element->{$HTML_NS}->{basefont} = {
  %HTMLEmptyChecker,
  status => FEATURE_M12N10_REC_DEPRECATED,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: color, face, size
  }, {
    %HTMLAttrStatus,
    color => FEATURE_M12N10_REC_DEPRECATED,
    face => FEATURE_M12N10_REC_DEPRECATED,
    #id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC_DEPRECATED,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    size => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

## TODO: frameset FEATURE_M12N10_REC
## class title id cols rows onload onunload style(x10)
## frame frameborder longdesc marginheight marginwidth noresize scrolling src name(deprecated) class,id,title,style(x10)
## noframes Common, lang(xhtml10)

## TODO: CR: ruby rb rt rp rbc rtc @rbspan

## TODO: xmp, listing, plaintext FEATURE_HTML32_REC_OBSOLETE
## TODO: ^^^ lang, dir, id, class [HTML 2.x] sdaform [HTML 2.0]
## xmp, listing sdapref[HTML2,0]

=pod

WF2: Documents MUST comply to [CHARMOD].
                     WF2: Vencor extensions MUST NOT be used.

HTML 2.0 nextid @n

RFC 2659: CERTS CRYPTOPTS 

ISO-HTML: pre-html, divN

=cut

## NOTE: Where RFC 2659 allows additional attributes is unclear.
## We added them only to |a|.  |link| and |form| might also allow them
## in theory.

$Whatpm::ContentChecker::Namespace->{$HTML_NS}->{loaded} = 1;

1;
