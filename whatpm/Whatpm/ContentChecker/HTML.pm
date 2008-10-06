package Whatpm::ContentChecker;
use strict;
require Whatpm::ContentChecker;

use Char::Class::XML qw/InXML_NCNameStartChar10 InXMLNCNameChar10/;

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;

sub FEATURE_HTML5_ROLE () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD
      ## TODO: svg:*/@role
}

sub FEATURE_HTML5_COMPLETE () {
  Whatpm::ContentChecker::FEATURE_STATUS_REC |
  Whatpm::ContentChecker::FEATURE_ALLOWED
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
sub FEATURE_HTML5_LC_DROPPED () {
  ## NOTE: Was part of HTML5, but was dropped.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}
sub FEATURE_WF2X () {
  ## NOTE: Defined in WF2 and then incorporated into the HTML5 spec.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}
sub FEATURE_WF2 () {
  ## NOTE: Part of WF2, still not added to the HTML5 spec.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}
sub FEATURE_WF2_INFORMATIVE () {
  ## NOTE: Part of WF2 Appendix A, still not added to the HTML5 spec.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}
sub FEATURE_WF2X_DEPRECATED () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
  ## NOTE: MUST NOT be used according to WF2.
}

## NOTE: Metainformation Attributes Module by W3C XHTML2 WG.
sub FEATURE_RDFA_PR () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR
  ## NOTE: Diff from FEATURE_RDFA_CR
}
sub FEATURE_RDFA_CR () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}
sub FEATURE_RDFA_LC () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

sub FEATURE_RDFA_ED () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD
}

## NOTE: XHTML Role LCWD has almost no information on how the |role|
## attribute can be used- the only requirements for that matter is:
## "the attribute MUST be referenced using its namespace-qualified form" (and
## this is a host language conformance!).
sub FEATURE_ROLE_LC () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

sub FEATURE_XHTML2_ED () {
  Whatpm::ContentChecker::FEATURE_STATUS_WD
}

sub FEATURE_XHTMLBASIC11_CR () {
  ## NOTE: Only additions to M12N10_REC are marked.
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}
sub FEATURE_XHTMLBASIC11_CR_DEPRECATED () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR |
  Whatpm::ContentChecker::FEATURE_DEPRECATED_INFO
}

sub FEATURE_M12N11_LC () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

sub FEATURE_RUBY_REC () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR
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
## NOTE: XHTML M12N 1.1 is in the PR status at the time of writing and no
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
    'event-source' => 1, eventsource => 1,
    command => 1, datatemplate => 1,
    ## NOTE: A |meta| with no |name| element is not allowed as
    ## a metadata content other than |head| element.
    meta => 1,
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
    form => 1, fieldset => 1,
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
    b => 1, bdo => 1, ruby => 1,
    script => 1, noscript => 1, 'event-source' => 1, eventsource => 1,
    command => 1, bb => 1,
    input => 1, button => 1, label => 1, select => 1, datalist => 1,
    textarea => 1, output => 1,
    datagrid => 1, ## ISSUE: "Interactive element" in the spec.
    ## NOTE: |area| is allowed only as a descendant of |map|.
    area => 1,
    
    ## NOTE: Transparent.
    a => 1, ins => 1, del => 1, font => 1,

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
    b => 1, bdo => 1, ruby => 1,
    script => 1, noscript => 1, 'event-source' => 1, eventsource => 1,
    command => 1, bb => 1,
    input => 1, button => 1, label => 1, select => 1, datalist => 1,
    textarea => 1, output => 1,
    datagrid => 1, ## ISSUE: "Interactive element" in the spec.
    ## NOTE: |area| is allowed only as a descendant of |map|.
    area => 1,

    ## NOTE: Transparent.    
    a => 1, ins => 1, del => 1, font => 1,

    ## NOTE: If there is a |menu| ancestor, phrasing.  Otherwise, flow.
    menu => 1,

    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,
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
    label => 1, input => 1, button => 1, select => 1, textarea => 1,
    details => 1, datagrid => 1, bb => 1,

    ## NOTE: When "controls" attribute is specified.
    video => 1, audio => 1,

    ## NOTE: When "type=toolbar" attribute is specified.
    menu => 1,
  },
};

## NOTE: Labelable form-associated element.
my $LabelableFAE = {
  $HTML_NS => {
    input => 1, button => 1, select => 1, textarea => 1, 
  },
};

our $IsInHTMLInteractiveContent; # See Whatpm::ContentChecker.

## NOTE: $HTMLTransparentElements: See Whatpm::ContentChecker.
## NOTE: Semi-transparent elements: See Whatpm::ContentChecker.

## -- Common attribute syntacx checkers

our $AttrChecker;
our $AttrStatus;

my $GetHTMLEnumeratedAttrChecker = sub {
  my $states = shift; # {value => conforming ? 1 : -1}
  return sub {
    my ($self, $attr) = @_;
    my $value = lc $attr->value; ## TODO: ASCII case insensitibility?
    if ($states->{$value} > 0) {
      #
    } elsif ($states->{$value}) {
      $self->{onerror}->(node => $attr, type => 'enumerated:non-conforming',
                         level => $self->{level}->{must});
    } else {
      $self->{onerror}->(node => $attr, type => 'enumerated:invalid',
                         level => $self->{level}->{must});
    }
  };
}; # $GetHTMLEnumeratedAttrChecker

my $GetHTMLBooleanAttrChecker = sub {
  my $local_name = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = lc $attr->value; ## TODO: case
    unless ($value eq $local_name or $value eq '') {
      $self->{onerror}->(node => $attr, type => 'boolean:invalid',
                         level => $self->{level}->{must});
    }
  };
}; # $GetHTMLBooleanAttrChecker

## Unordered set of space-separated tokens
my $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker = sub {
  my $allowed_words = shift;
  return sub {
    my ($self, $attr) = @_;
    my %word;
    for my $word (grep {length $_}
                  split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
      unless ($word{$word}) {
        $word{$word} = 1;
        if (not defined $allowed_words or
            $allowed_words->{$word}) {
          #
        } else {
          $self->{onerror}->(node => $attr, type => 'word not allowed',
                             value => $word,
                             level => $self->{level}->{must});
        }
      } else {
        $self->{onerror}->(node => $attr, type => 'duplicate token',
                           value => $word,
                           level => $self->{level}->{must});
      }
    }
  };
}; # $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker

## |rel| attribute (set of space separated tokens,
## whose allowed values are defined by the section on link types)
my $HTMLLinkTypesAttrChecker = sub {
  my ($a_or_area, $todo, $self, $attr, $item, $element_state) = @_;
  my %word;
  for my $word (grep {length $_}
                split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
    unless ($word{$word}) {
      $word{$word} = 1;
    } elsif ($word eq 'up') {
      #
    } else {
      $self->{onerror}->(node => $attr, type => 'duplicate token',
                         value => $word,
                         level => $self->{level}->{must});
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
                             type => 'link type:bad context',
                             value => $word,
                             level => $self->{level}->{must});
        }
      } elsif ($def->{status} eq 'proposal') {
        $self->{onerror}->(node => $attr,
                           type => 'link type:proposed',
                           value => $word,
                           level => $self->{level}->{should});
        if (defined $def->{effect}->[$a_or_area]) {
          #
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'link type:bad context',
                             value => $word,
                             level => $self->{level}->{must});
        }
      } else { # rejected or synonym
        $self->{onerror}->(node => $attr,
                           type => 'link type:non-conforming',
                           value => $word,
                           level => $self->{level}->{must});
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
                             type => 'link type:duplicate',
                             value => $word,
                             level => $self->{level}->{must});
        }
      }

      if (defined $def->{effect}->[$a_or_area] and $word ne 'alternate') {
        $is_hyperlink = 1 if $def->{effect}->[$a_or_area] eq 'hyperlink';
        $is_resource = 1 if $def->{effect}->[$a_or_area] eq 'external resource';
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'unknown link type',
                         value => $word,
                         level => $self->{level}->{uncertain});
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

  $element_state->{link_rel} = \%word;
}; # $HTMLLinkTypesAttrChecker

## TODO: "When an author uses a new type not defined by either this specification or the Wiki page, conformance checkers should offer to add the value to the Wiki, with the details described above, with the "proposal" status."

## URI (or IRI)
my $HTMLURIAttrChecker = sub {
  my ($self, $attr, $item, $element_state) = @_;
  ## ISSUE: Relative references are allowed? (RFC 3987 "IRI" is an absolute reference with optional fragment identifier.)
  my $value = $attr->value;
  Whatpm::URIChecker->check_iri_reference ($value, sub {
    $self->{onerror}->(@_, node => $attr);
  }), $self->{level};
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
  for my $value (split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
    Whatpm::URIChecker->check_iri_reference ($value, sub {
      $self->{onerror}->(value => $value, @_, node => $attr, index => $i);
    }, $self->{level});

    ## TODO: absolute
    push @{$self->{return}->{uri}->{$value} ||= []},
        {node => $attr, type => {$type => 1}};

    $i++;
  }
  ## ISSUE: Relative references? (especially, in profile="")
  ## ISSUE: Leading or trailing white spaces are conformant?
  ## ISSUE: A sequence of white space characters are conformant?
  ## ISSUE: A zero-length string is conformant? (It does contain a relative reference, i.e. same as base URI.)
  ## ISSUE: What is "space"?
  ## NOTE: Duplication seems not an error.
  $self->{has_uri_attr} = 1;
}; # $HTMLSpaceURIsAttrChecker

## NOTE: "Valid datetime".
my $HTMLDatetimeAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  ## ISSUE: "space", not "space character" (in parsing algorihtm, "space character")
  if ($value =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})
                 (?>[\x09\x0A\x0C\x0D\x20]+
                 (?>T[\x09\x0A\x0C\x0D\x20]*)?|T[\x09\x0A\x0C\x0D\x20]*)
                 ([0-9]{2}):([0-9]{2})(?>:([0-9]{2}))?(?>\.([0-9]+))?
                 [\x09\x0A\x0C\x0D\x20]*
                 (?>Z|[+-]([0-9]{2}):([0-9]{2}))\z/x) {
    my ($y, $M, $d, $h, $m, $s, $f, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    if (0 < $M and $M < 13) { ## ISSUE: This is not explicitly specified (though in parsing algorithm)
      $self->{onerror}->(node => $attr, type => 'datetime:bad day',
                         level => $self->{level}->{must})
          if $d < 1 or
              $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->{onerror}->(node => $attr, type => 'datetime:bad day',
                         level => $self->{level}->{must})
          if $M == 2 and $d == 29 and
              not ($y % 400 == 0 or ($y % 4 == 0 and $y % 100 != 0));
    } else {
      $self->{onerror}->(node => $attr, type => 'datetime:bad month',
                         level => $self->{level}->{must});
    }
    $self->{onerror}->(node => $attr, type => 'datetime:bad hour',
                       level => $self->{level}->{must}) if $h > 23;
    $self->{onerror}->(node => $attr, type => 'datetime:bad minute',
                       level => $self->{level}->{must}) if $m > 59;
    $self->{onerror}->(node => $attr, type => 'datetime:bad second',
                       level => $self->{level}->{must})
        if defined $s and $s > 59;
    $self->{onerror}->(node => $attr, type => 'datetime:bad timezone hour',
                       level => $self->{level}->{must}) if $zh > 23;
    $self->{onerror}->(node => $attr, type => 'datetime:bad timezone minute',
                       level => $self->{level}->{must}) if $zm > 59;
    ## ISSUE: Maybe timezone -00:00 should have same semantics as in RFC 3339.
  } else {
    $self->{onerror}->(node => $attr, type => 'datetime:syntax error',
                       level => $self->{level}->{must});
  }
}; # $HTMLDatetimeAttrChecker

my $HTMLIntegerAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  unless ($value =~ /\A-?[0-9]+\z/) {
    $self->{onerror}->(node => $attr, type => 'integer:syntax error',
                       level => $self->{level}->{must});
  }
}; # $HTMLIntegerAttrChecker

my $GetHTMLNonNegativeIntegerAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A[0-9]+\z/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'nninteger:out of range',
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'nninteger:syntax error',
                         level => $self->{level}->{must});
    }
  };
}; # $GetHTMLNonNegativeIntegerAttrChecker

my $GetHTMLFloatingPointNumberAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A-?[0-9]+(?>\.[0-9]*)?\z/ or
        $value =~ /\A-?\.[0-9]+\z/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'float:out of range',
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'float:syntax error',
                         level => $self->{level}->{must});
    }
  };

  ## TODO: scientific notation
}; # $GetHTMLFloatingPointNumberAttrChecker

my $StepAttrChecker = sub {
  ## NOTE: A valid floating point number (> 0), or ASCII
  ## case-insensitive "any".
  
  my ($self, $attr) = @_;
  my $value = $attr->value;
  if ($value =~ /\A-?[0-9]+(?>\.[0-9]*)?\z/ or
      $value =~ /\A-?\.[0-9]+\z/) {
    unless ($value > 0) {
      $self->{onerror}->(node => $attr, type => 'float:out of range',
                         level => $self->{level}->{must});
    }
  } elsif ($value =~ /\A[Aa][Nn][Yy]\z/) {
    #
  } else {
    $self->{onerror}->(node => $attr,
                       type => 'float:syntax error',
                       level => $self->{level}->{must});
  }
  
  ## TODO: scientific
}; # $StepAttrChecker

## HTML4 %Length;
my $HTMLLengthAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  unless ($value =~ /\A[0-9]+%?\z/) {
    $self->{onerror}->(node => $attr, type => 'length:syntax error',
                       level => $self->{level}->{must});
  }

  ## NOTE: HTML4 definition is too vague - it does not define the syntax
  ## of percentage value at all (!).
}; # $HTMLLengthAttrChecker

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
    my $ic = Whatpm::IMTChecker->new;
    $ic->{level} = $self->{level};
    $ic->check_imt (sub {
      $self->{onerror}->(@_, node => $attr);
    }, @type);
  } else {
    $self->{onerror}->(node => $attr, type => 'IMT:syntax error',
                       level => $self->{level}->{must});
  }
}; # $HTMLIMTAttrChecker

my $HTMLLanguageTagAttrChecker = sub {
  ## NOTE: See also $AtomLanguageTagAttrChecker in Atom.pm.

  my ($self, $attr) = @_;
  my $value = $attr->value;
  require Whatpm::LangTag;
  Whatpm::LangTag->check_rfc3066_language_tag ($value, sub {
    $self->{onerror}->(@_, node => $attr);
  }, $self->{level});
  ## ISSUE: RFC 4646 (3066bis)?

  ## TODO: testdata
}; # $HTMLLanguageTagAttrChecker

## "A valid media query [MQ]"
my $HTMLMQAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr,
                     type => 'media query',
                     level => $self->{level}->{uncertain});
  ## ISSUE: What is "a valid media query"?
}; # $HTMLMQAttrChecker

my $HTMLEventHandlerAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr,
                     type => 'event handler',
                     level => $self->{level}->{uncertain});
  ## TODO: MUST contain valid ECMAScript code matching the
  ## ECMAScript |FunctionBody| production. [ECMA262]
  ## ISSUE: MUST be ES3? E4X? ES4? JS1.x?
  ## ISSUE: Automatic semicolon insertion does not apply?
  ## ISSUE: Other script languages?
}; # $HTMLEventHandlerAttrChecker

my $HTMLFormAttrChecker = sub {
  my ($self, $attr) = @_;

  ## NOTE: MUST be the ID of a |form| element.

  my $value = $attr->value;
  push @{$self->{idref}}, ['form', $value => $attr];

  ## ISSUE: <form id=""><input form=""> (empty ID)?
}; # $HTMLFormAttrChecker

my $HTMLUsemapAttrChecker = sub {
  my ($self, $attr) = @_;
  ## MUST be a valid hash-name reference to a |map| element.
  my $value = $attr->value;
  if ($value =~ s/^#//) {
    ## NOTE: |usemap="#"| is conforming, though it identifies no |map| element
    ## according to the "rules for parsing a hash-name reference" algorithm.
    ## The document is non-conforming anyway, since |<map name="">| (empty
    ## name) is non-conforming.
    push @{$self->{usemap}}, [$value => $attr];
  } else {
    $self->{onerror}->(node => $attr, type => 'hashref:syntax error',
                       level => $self->{level}->{must});
  }
  ## NOTE: Space characters in hash-name references are conforming.
  ## ISSUE: UA algorithm for matching is case-insensitive; IDs only different in cases should be reported
}; # $HTMLUsemapAttrChecker

## Valid browsing context name
my $HTMLBrowsingContextNameAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  if ($value =~ /^_/) {
    $self->{onerror}->(node => $attr, type => 'window name:reserved',
                       level => $self->{level}->{must},
                       value => $value);
  } elsif (length $value) {
    #
  } else {
    $self->{onerror}->(node => $attr, type => 'window name:empty',
                       level => $self->{level}->{must});
  }
}; # $HTMLBrowsingContextNameAttrChecker

## Valid browsing context name or keyword
my $HTMLTargetAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  if ($value =~ /^_/) {
    $value = lc $value; ## ISSUE: ASCII case-insentitive?
    unless ({
             _blank => 1,_self => 1, _parent => 1, _top => 1,
            }->{$value}) {
      $self->{onerror}->(node => $attr,
                         type => 'window name:reserved',
                         level => $self->{level}->{must},
                         value => $value);
    }
  } elsif (length $value) {
    #
  } else {
    $self->{onerror}->(node => $attr, type => 'window name:empty',
                       level => $self->{level}->{must});
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

  $p->{level} = $self->{level};
  $p->{onerror} = sub {
    $self->{onerror}->(@_, node => $attr);
  };
  $p->parse_string ($value);
}; # $HTMLSelectorsAttrChecker

my $HTMLAccesskeyAttrChecker = sub {
  my ($self, $attr) = @_;

  ## NOTE: "character" or |%Character;| in HTML4.

  my $value = $attr->value;
  if (length $value != 1) {
    $self->{onerror}->(node => $attr, type => 'char:syntax error',
                       level => $self->{level}->{html4_fact});
  }

  ## NOTE: "Note. Authors should consider the input method of the expected
  ## reader when specifying an accesskey." [HTML4]  This is hard to implement,
  ## since it depends on keyboard and so on.
  ## NOTE: "We recommend that authors include the access key in label text
  ## or wherever the access key is to apply." [HTML4] (informative)
}; # $HTMLAccesskeyAttrChecker

my $HTMLCharsetChecker = sub ($$$;$) {
  my ($charset_value, $self, $attr, $ascii_compat) = @_;

  ## NOTE: This code is used for |charset=""| attributes, |charset=|
  ## portion of the |content=""| attributes, and |accept-charset=""|
  ## attributes.

  ## NOTE: Though the case-sensitivility of |charset| attribute value
  ## is not explicitly spelled in the HTML5 spec, the Character Set
  ## registry of IANA, which is referenced from HTML5 spec, says that
  ## charset name is case-insensitive.
  $charset_value =~ tr/A-Z/a-z/; ## NOTE: ASCII Case-insensitive.
  
  require Message::Charset::Info;
  my $charset = $Message::Charset::Info::IANACharset->{$charset_value};
      
  ## ISSUE: What is "valid character encoding name"?  Syntactically valid?
  ## Syntactically valid and registered?  What about x-charset names?
  unless (Message::Charset::Info::is_syntactically_valid_iana_charset_name
              ($charset_value)) {
    $self->{onerror}->(node => $attr,
                       type => 'charset:syntax error',
                       value => $charset_value,
                       level => $self->{level}->{must});
  }
  
  if ($charset) {
    ## ISSUE: What is "the preferred name for that encoding" (for a charset
    ## with no "preferred MIME name" label)?
    my $charset_status = $charset->{iana_names}->{$charset_value} || 0;
    if (($charset_status &
         Message::Charset::Info::PREFERRED_CHARSET_NAME ())
            != Message::Charset::Info::PREFERRED_CHARSET_NAME ()) {
      $self->{onerror}->(node => $attr,
                         type => 'charset:not preferred',
                         value => $charset_value,
                         level => $self->{level}->{must});
    }

    if (($charset_status &
         Message::Charset::Info::REGISTERED_CHARSET_NAME ())
            != Message::Charset::Info::REGISTERED_CHARSET_NAME ()) {
      if ($charset_value =~ /^x-/) {
        $self->{onerror}->(node => $attr,
                           type => 'charset:private',
                           value => $charset_value,
                           level => $self->{level}->{good});
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'charset:not registered',
                           value => $charset_value,
                           level => $self->{level}->{good});
      }
    }
    
    if ($ascii_compat) {
      if ($charset->{category} &
              Message::Charset::Info::CHARSET_CATEGORY_ASCII_COMPAT ()) {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'charset:not ascii compat',
                           value => $charset_value,
                           level => $self->{level}->{must});
      }
    }

## TODO: non-preferred-name error for following cases:
  } elsif ($charset_value =~ /^x-/) {
    $self->{onerror}->(node => $attr,
                       type => 'charset:private',
                       value => $charset_value,
                       level => $self->{level}->{good});

    ## NOTE: Whether this is an ASCII-compatible character encoding or
    ## not is unknown.
  } else {
    $self->{onerror}->(node => $attr,
                       type => 'charset:not registered',
                       value => $charset_value,
                       level => $self->{level}->{good});

    ## NOTE: Whether this is an ASCII-compatible character encoding or
    ## not is unknown.
  }
  
  return ($charset, $charset_value);
}; # $HTMLCharsetChecker

## NOTE: "An ordered set of space-separated tokens" where "each token
## MUST be the preferred name of an ASCII-compatible character
## encoding".
my $HTMLCharsetsAttrChecker = sub {
  my ($self, $attr) = @_;

  ## ISSUE: "ordered set of space-separated tokens" is not defined.

  my @value = grep {length $_} split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value;
  
  ## ISSUE: Uniqueness is not enforced.

  for my $charset (@value) {
    $HTMLCharsetChecker->($charset, $self, $attr, 1);
  }

  ## ISSUE: Shift_JIS is ASCII-compatible?  What about ISO-2022-JP?
}; # $HTMLCharsetsAttrChecker

my $HTMLColorAttrChecker = sub {
  my ($self, $attr) = @_;
  
  ## NOTE: HTML4 "color" or |%Color;|

  my $value = $attr->value;

  if ($value !~ /\A(?>#[0-9A-F]+|black|silver|gray|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua)\z/i) {
    $self->{onerror}->(node => $attr, type => 'color:syntax error',
                       level => $self->{level}->{html4_fact});
  }

  ## TODO: HTML4 has some guideline on usage of color.
}; # $HTMLColorAttrChecker

my $HTMLRefOrTemplateAttrChecker = sub {
  my ($self, $attr) = @_;
  $HTMLURIAttrChecker->(@_);

  my $attr_name = $attr->name;

  if ($attr_name eq 'ref') {
    unless ($attr->owner_element->has_attribute_ns (undef, 'template')) {
      $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                         level => $self->{level}->{must});
    }
  }
  
  my $doc = $attr->owner_document;
  my $doc_uri = $doc->document_uri;
  my $uri = $doc->implementation
      ->create_uri_reference ($attr->value)
      ->get_absolute_reference ($doc_uri);
  my $no_frag_uri = $uri->clone;
  $no_frag_uri->uri_fragment (undef);
  if ((defined $doc_uri and $doc_uri eq $no_frag_uri) or
      (not defined $doc_uri and $no_frag_uri eq '')) {
    my $fragid = $uri->uri_fragment;
    if (defined $fragid) {
      push @{$self->{$attr_name}}, [$fragid => $attr];
    } else {
      DOCEL: {
        last DOCEL unless $attr_name eq 'template';

        my $docel = $doc->document_element;
        if ($docel) {
          my $nsuri = $docel->namespace_uri;
          if (defined $nsuri and $nsuri eq $HTML_NS) {
            if ($docel->manakai_local_name eq 'datatemplate') {
              last DOCEL;
            }
          }
        }
        
        $self->{onerror}->(node => $attr, type => 'template:not template',
                           level => $self->{level}->{must});
      } # DOCEL
    }
  } else {
    ## TODO: An external document is referenced.
    ## The document MUST be an HTML or XML document.
    ## If there is a fragment identifier, it MUST point a part of the doc.
    ## If the attribute is |template|, the pointed part MUST be a
    ## |datatemplat| element.
    ## If no fragment identifier is specified, the root element MUST be
    ## a |datatemplate| element when the attribute is |template|.
  }
}; # $HTMLRefOrTemplateAttrChecker

my $HTMLRepeatIndexAttrChecker = sub {
  my ($self, $attr) = @_;

  if (defined $attr->namespace_uri) {
    my $oe = $attr->owner_element;
    my $oe_nsuri = $oe->namespace_uri;
    if (defined $oe_nsuri or $oe_nsuri eq $HTML_NS) { ## TODO: wrong?
      $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                         level => $self->{level}->{must});
    }
  }
  
  $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 })->(@_);
}; # $HTMLRepeatIndexAttrChecker

my $HTMLAttrChecker = {
  ## TODO: aria-* ## TODO: svg:*/@aria-* [HTML5ROLE] -> [STATES]
  id => sub {
    my ($self, $attr, $item, $element_state) = @_;
    my $value = $attr->value;
    if (length $value > 0) {
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'duplicate ID',
                           level => $self->{level}->{must});
        push @{$self->{id}->{$value}}, $attr;
      } else {
        $self->{id}->{$value} = [$attr];
        $self->{id_type}->{$value} = $element_state->{id_type} || '';
      }
      if ($value =~ /[\x09\x0A\x0C\x0D\x20]/) {
        $self->{onerror}->(node => $attr, type => 'space in ID',
                           level => $self->{level}->{must});
      }
    } else {
      ## NOTE: MUST contain at least one character
      $self->{onerror}->(node => $attr, type => 'empty attribute value',
                         level => $self->{level}->{must});
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
        $self->{onerror}->(@_, node => $attr);
      }, $self->{level});
    }
    ## ISSUE: RFC 4646 (3066bis)?

    ## TODO: test data

    ## NOTE: Inconsistency between |lang| and |xml:lang| attributes are
    ## non-conforming.  Such errors are detected by the checkers of
    ## |{}xml:lang| and |{xml}:lang| attributes.
  },
  dir => $GetHTMLEnumeratedAttrChecker->({ltr => 1, rtl => 1}),
  class => sub {
    my ($self, $attr) = @_;
    
    ## NOTE: "Unordered set of unique space-separated tokens".

    my %word;
    for my $word (grep {length $_}
                  split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
      unless ($word{$word}) {
        $word{$word} = 1;
        push @{$self->{return}->{class}->{$word}||=[]}, $attr;
      } else {
        $self->{onerror}->(node => $attr, type => 'duplicate token',
                           value => $word,
                           level => $self->{level}->{must});
      }
    }
  },
  contenteditable => $GetHTMLEnumeratedAttrChecker->({
    true => 1, false => 1, '' => 1,
  }),
  contextmenu => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    push @{$self->{idref}}, ['menu', $value => $attr];
    ## ISSUE: "The value must be the ID of a menu element in the DOM."
    ## What is "in the DOM"?  A menu Element node that is not part
    ## of the Document tree is in the DOM?  A menu Element node that
    ## belong to another Document tree is in the DOM?
  },
  hidden => $GetHTMLBooleanAttrChecker->('hidden'),
  irrelevant => $GetHTMLBooleanAttrChecker->('irrelevant'),
  ref => $HTMLRefOrTemplateAttrChecker,
  registrationmark => sub {
    my ($self, $attr, $item, $element_state) = @_;

    ## NOTE: Any value is conforming.

    if ($self->{flag}->{in_rule}) {
      my $el = $attr->owner_element;
      my $ln = $el->manakai_local_name;
      if ($ln eq 'nest' or
          ($ln eq 'rule' and not $element_state->{in_rule_original})) {
        my $nsuri = $el->namespace_uri;
        if (defined $nsuri and $nsuri eq $HTML_NS) {
          $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                             level => $self->{level}->{must});
        }
      }
    } else {
      $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                         level => $self->{level}->{must});
    }
  },
  repeat => sub {
    my ($self, $attr) = @_;

    if (defined $attr->namespace_uri) {
      my $oe = $attr->owner_element;
      my $oe_nsuri = $oe->namespace_uri;
      if (defined $oe_nsuri or $oe_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    }

    my $value = $attr->value;
    if ($value eq 'template') {
      #
    } elsif ($value =~ /\A-?[0-9]+\z/) {
      #
    } else {
      $self->{onerror}->(node => $attr, type => 'repeat:syntax error',
                         level => $self->{level}->{must});
    }

    ## ISSUE: "Repetition templates may occur anywhere."  Does that mean
    ## that the attribute MAY be specified to any element, or that the
    ## element with that attribute (i.e. a repetition template) can be
    ## inserted anywhere in a document tree?
  },
  'repeat-min' => $HTMLRepeatIndexAttrChecker,
  'repeat-max' => $HTMLRepeatIndexAttrChecker,
  'repeat-start' => $HTMLRepeatIndexAttrChecker,
  'repeat-template' => sub {
    my ($self, $attr) = @_;

    if (defined $attr->namespace_uri) {
      my $oe = $attr->owner_element;
      my $oe_nsuri = $oe->namespace_uri;
      if (defined $oe_nsuri or $oe_nsuri eq $HTML_NS) { ## TODO: This condition is wrong?
        $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    }

    ## ISSUE: This attribute has no conformance requirement.
    ## ISSUE: Repetition blocks MAY have this attribute.  Then, is the
    ## attribute allowed on an element that is not a repetition block?
  },
  ## TODO: role [HTML5ROLE] ## TODO: global @role [XHTML1ROLE]
  style => sub {
    my ($self, $attr) = @_;

    $self->{onsubdoc}->({s => $attr->value,
                         container_node => $attr,
                         media_type => 'text/x-css-inline',
                         is_char_string => 1});

    ## NOTE: "... MUST still be comprehensible and usable if those
    ## attributes were removed" is a semantic requirement, it cannot
    ## be tested.
  },
  tabindex => $HTMLIntegerAttrChecker,
  template => $HTMLRefOrTemplateAttrChecker,
  'xml:lang' => sub {
    my ($self, $attr) = @_;
    
    if ($attr->owner_document->manakai_is_html) {
      $self->{onerror}->(type => 'in HTML:xml:lang',
                         level => $self->{level}->{info},
                         node => $attr);
      ## NOTE: This is not an error, but the attribute will be ignored.
    } else {
      $self->{onerror}->(type => 'in XML:xml:lang',
                         level => $self->{level}->{html5_no_may},
                         node => $attr);
      ## TODO: We need to add test for this error.
    }
    
    my $lang_attr = $attr->owner_element->get_attribute_node_ns
        (undef, 'lang');
    if ($lang_attr) {
      my $lang_attr_value = $lang_attr->value;
      $lang_attr_value =~ tr/A-Z/a-z/; ## ASCII case-insensitive
      my $value = $attr->value;
      $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive
      if ($lang_attr_value ne $value) {
        $self->{onerror}->(type => 'xml:lang ne lang',
                           level => $self->{level}->{must},
                           node => $attr);
      }
    } else {
      $self->{onerror}->(type => 'xml:lang not allowed',
                         level => $self->{level}->{must},
                         node => $attr);
      ## TODO: We need to add test for <x {xml}:lang {}xml:lang>.
    }
  },
  xmlns => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    unless ($value eq $HTML_NS) {
      $self->{onerror}->(node => $attr, type => 'invalid attribute value',
                         level => $self->{level}->{must});
      ## TODO: Should be new "bad namespace" error?
    }
    unless ($attr->owner_document->manakai_is_html) {
      $self->{onerror}->(node => $attr, type => 'in XML:xmlns',
                         level => $self->{level}->{must});
      ## TODO: Test
    }
    
    ## TODO: Should be resolved?
    push @{$self->{return}->{uri}->{$value} ||= []},
        {node => $attr, type => {namespace => 1}};
  },
};

## ISSUE: Shouldn't the same-origin policy applied to the datatemplate feature?

my %HTMLAttrStatus = (
  class => FEATURE_HTML5_DEFAULT,
  contenteditable => FEATURE_HTML5_DEFAULT,
  contextmenu => FEATURE_HTML5_WD,
  dir => FEATURE_HTML5_DEFAULT,
  draggable => FEATURE_HTML5_LC,
  hidden => FEATURE_HTML5_DEFAULT,
  id => FEATURE_HTML5_DEFAULT,
  irrelevant => FEATURE_HTML5_DROPPED,
  lang => FEATURE_HTML5_DEFAULT,
  ref => FEATURE_HTML5_AT_RISK,
  registrationmark => FEATURE_HTML5_AT_RISK,
  repeat => FEATURE_WF2,
  'repeat-max' => FEATURE_WF2,
  'repeat-min' => FEATURE_WF2,
  'repeat-start' => FEATURE_WF2,
  'repeat-template' => FEATURE_WF2,
  role => FEATURE_HTML5_ROLE,
  style => FEATURE_HTML5_DEFAULT,
  tabindex => FEATURE_HTML5_DEFAULT,
  template => FEATURE_HTML5_AT_RISK,
  title => FEATURE_HTML5_DEFAULT,  
  xmlns => FEATURE_HTML5_DEFAULT,
);

my %HTMLM12NCommonAttrStatus = (
  about => FEATURE_RDFA_CR,
  class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  content => FEATURE_RDFA_CR,
  datatype => FEATURE_RDFA_CR,
  dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  href => FEATURE_RDFA_CR,
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
  property => FEATURE_RDFA_CR,
  rel => FEATURE_RDFA_CR,
  resource => FEATURE_RDFA_CR,
  rev => FEATURE_RDFA_CR,
  #style => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR_DEPRECATED |
  #    FEATURE_M12N10_REC,
  style => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR |
      FEATURE_M12N10_REC,
  title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  typeof => FEATURE_RDFA_CR,
);

my %XHTML2CommonAttrStatus = (
  ## Core
  class => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED,
  id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED,
  #xml:id
  layout => FEATURE_XHTML2_ED,
  title => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED,

  ## Hypertext
  cite => FEATURE_XHTML2_ED,
  href => FEATURE_XHTML2_ED,
  hreflang => FEATURE_XHTML2_ED,
  hrefmedia => FEATURE_XHTML2_ED,
  hreftype => FEATURE_XHTML2_ED,
  nextfocus => FEATURE_XHTML2_ED,
  prevfocus => FEATURE_XHTML2_ED,
  target => FEATURE_XHTML2_ED,
  #xml:base

  ## I18N
  #xml:lang

  ## Bi-directional
  dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED,

  ## Edit
  edit => FEATURE_XHTML2_ED,
  datetime => FEATURE_XHTML2_ED,

  ## Embedding
  encoding => FEATURE_XHTML2_ED,
  src => FEATURE_XHTML2_ED,
  srctype => FEATURE_XHTML2_ED,

  ## Image Map
  usemap => FEATURE_XHTML2_ED,
  ismap => FEATURE_XHTML2_ED,
  shape => FEATURE_XHTML2_ED,
  coords => FEATURE_XHTML2_ED,

  ## Media
  media => FEATURE_XHTML2_ED,

  ## Metadata
  about => FEATURE_XHTML2_ED,
  content => FEATURE_XHTML2_ED,
  datatype => FEATURE_XHTML2_ED,
  instanceof => FEATURE_XHTML2_ED,
  property => FEATURE_XHTML2_ED,
  rel => FEATURE_XHTML2_ED,
  resource => FEATURE_XHTML2_ED,
  rev => FEATURE_XHTML2_ED,

  ## Role
  role => FEATURE_HTML5_ROLE | FEATURE_XHTML2_ED,

  ## Style
  style => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED, # "strongly discouraged"
);

my %HTMLM12NXHTML2CommonAttrStatus = (
  %HTMLM12NCommonAttrStatus,
  %XHTML2CommonAttrStatus,

  about => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  class => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  content => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  datatype => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  href => FEATURE_RDFA_CR,
  id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  instanceof => FEATURE_RDFA_LC | FEATURE_XHTML2_ED,
  property => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  rel => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  resource => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  rev => FEATURE_RDFA_CR | FEATURE_XHTML2_ED,
  #style => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR_DEPRECATED |
  #    FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  style => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR |
      FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  title => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  typeof => FEATURE_RDFA_CR,
);

for (qw/
         onabort onbeforeunload onblur onchange onclick oncontextmenu
         ondblclick ondrag ondragend ondragenter ondragleave ondragover
         ondragstart ondrop onerror onfocus onkeydown onkeypress
         onkeyup onload onmessage onmousedown onmousemove onmouseout
         onmouseover onmouseup onmousewheel onresize onscroll onselect
         onstorage onsubmit onunload 
     /) {
  $HTMLAttrChecker->{$_} = $HTMLEventHandlerAttrChecker;
  $HTMLAttrStatus{$_} = FEATURE_HTML5_DEFAULT;
}

## NOTE: Non-standard global attributes in the HTML namespace.
$AttrChecker->{$HTML_NS}->{''} = sub {}; # no syntactical checks
$AttrStatus->{$HTML_NS}->{''} = 0; # disallowed and not part of any standard

$AttrStatus->{$HTML_NS}->{active} = FEATURE_HTML5_DROPPED;
for (qw/repeat repeat-max repeat-min repeat-start repeat-template/) {
  $AttrChecker->{$HTML_NS}->{$_} = $HTMLAttrChecker->{$_};
  $AttrStatus->{$HTML_NS}->{$_} = FEATURE_WF2;
}

for (qw/about content datatype property rel resource rev/) {
  $AttrStatus->{$HTML_NS}->{$_} = FEATURE_RDFA_CR | FEATURE_XHTML2_ED;
}
$AttrStatus->{$HTML_NS}->{instanceof} = FEATURE_RDFA_LC | FEATURE_XHTML2_ED;
$AttrStatus->{$HTML_NS}->{typeof} = FEATURE_RDFA_CR;
$AttrStatus->{$HTML_NS}->{role} = FEATURE_ROLE_LC;
for (qw/cite coords datetime edit encoding href hreflang hrefmedia hreftype
        ismap layout media nextfocus prevfocus shape src srctype style
        target usemap/) {
  $AttrStatus->{$HTML_NS}->{$_} = FEATURE_XHTML2_ED;
}
for (qw/class dir id title/) {
  $AttrStatus->{$HTML_NS}->{$_} = FEATURE_M12N11_LC | FEATURE_XHTML2_ED;
}
for (qw/onclick ondblclick onmousedown onmouseup onmouseover onmousemove
        onmouseout onkeypress onkeydown onkeyup/) {
  $AttrStatus->{$HTML_NS}->{$_} = FEATURE_M12N11_LC;
}

my $HTMLDatasetAttrChecker = sub {
  ## NOTE: "Authors should ... when the attributes are ignored and
  ## any associated CSS dropped, the page is still usable." (semantic
  ## constraint.)
}; # $HTMLDatasetAttrChecker

my $HTMLDatasetAttrStatus = FEATURE_HTML5_DEFAULT;

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
      my $status;
      if ($attr_ns eq '') {
        if ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
            $attr_ln !~ /[A-Z]/) {
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } else {
          $checker = $element_specific_checker->{$attr_ln}
              || $HTMLAttrChecker->{$attr_ln};
          $status = $element_specific_status->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      $status ||= $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''};
      $status = FEATURE_ALLOWED if not defined $status and length $attr_ns;
      if ($checker) {
        $checker->($self, $attr, $item, $element_state);
      } elsif ($attr_ns eq '' and not $element_specific_status->{$attr_ln}) {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
        ## ISSUE: No conformance createria for unknown attributes in the spec
      }
      $self->_attr_status_info ($attr, $status);
    }
  };
}; # $GetHTMLAttrsChecker

my %HTMLChecker = (
  %Whatpm::ContentChecker::AnyChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_attrs => $GetHTMLAttrsChecker->({}, \%HTMLAttrStatus),
);

my %HTMLEmptyChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:empty',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed:empty',
                         level => $self->{level}->{must});
    }
  },
);

my %HTMLTextChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed:text',
                         level => $self->{level}->{must});
    }
  },
);

my %HTMLFlowContentChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'style') {
      if ($element_state->{has_non_style} or
          not $child_el->has_attribute_ns (undef, 'scoped')) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:flow style',
                           level => $self->{level}->{must});
      }
    } elsif ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
      $element_state->{has_non_style} = 1 unless $child_is_transparent;
    } else {
      $element_state->{has_non_style} = 1;
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:flow',
                         level => $self->{level}->{must})
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
    ## NOTE: A modified copy of the code below is in |datagrid| checker.
    if ($element_state->{has_significant}) {
      $item->{real_parent_state}->{has_significant} = 1;
    } elsif ($item->{transparent}) {
      #
    } else {
      $self->{onerror}->(node => $item->{node},
                         level => $self->{level}->{should},
                         type => 'no significant content');
    }
  },
);

my %HTMLPhrasingContentChecker = (
  %HTMLChecker,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:phrasing',
                         level => $self->{level}->{must});
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  is_root => 1,
  check_attrs => $GetHTMLAttrsChecker->({
    manifest => $HTMLURIAttrChecker,
    version => sub {
      ## NOTE: According to HTML4 prose, this is a "cdata" attribute.
      ## Though DTDs of various versions of HTML define the attribute
      ## as |#FIXED|, this conformance checker does no check for
      ## the attribute value, since what kind of check should be done
      ## is unknown.
    },
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    manifest => FEATURE_HTML5_DEFAULT,
    sdaform => FEATURE_HTML20_RFC,
    version => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before head';

    $element_state->{uri_info}->{manifest}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'before head') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'head') {
        $element_state->{phase} = 'after head';            
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'body') {
        $self->{onerror}->(node => $child_el,
                           type => 'ps element missing',
                           text => 'head',
                           level => $self->{level}->{must});
        $element_state->{phase} = 'after body';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed',
                           level => $self->{level}->{must});      
      }
    } elsif ($element_state->{phase} eq 'after head') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'body') {
        $element_state->{phase} = 'after body';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed',
                           level => $self->{level}->{must});      
      }
    } elsif ($element_state->{phase} eq 'after body') {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed',
                         level => $self->{level}->{must});      
    } else {
      die "check_child_element: Bad |html| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'after body') {
      #
    } elsif ($element_state->{phase} eq 'before head') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'head',
                         level => $self->{level}->{must});
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'body',
                         level => $self->{level}->{must});
    } elsif ($element_state->{phase} eq 'after head') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'body',
                         level => $self->{level}->{must});
    } else {
      die "check_end: Bad |html| phase: $element_state->{phase}";
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{head} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    profile => $HTMLSpaceURIsAttrChecker, ## NOTE: MUST be profile URIs.
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    profile => FEATURE_HTML5_DROPPED | FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'title') {
      unless ($element_state->{has_title}) {
        $element_state->{has_title} = 1;
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:head title',
                           level => $self->{level}->{must});
      }
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'style') {
      if ($child_el->has_attribute_ns (undef, 'scoped')) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:head style',
                           level => $self->{level}->{must});
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
                         level => $self->{level}->{must});
    }
    $element_state->{in_head_original} = $self->{flag}->{in_head};
    $self->{flag}->{in_head} = 1;
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{has_title}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'title',
                         level => $self->{level}->{must});
    }
    $self->{flag}->{in_head} = $element_state->{in_head_original};

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{title} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_XHTML10_REC,
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
                         type => 'element not allowed:base',
                         level => $self->{level}->{must});
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
                         type => 'basehref after URL attribute',
                         level => $self->{level}->{must});
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
                         type => 'basetarget after hyperlink',
                         level => $self->{level}->{must});
    }

    if (not $has_href and not $has_target) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing:href|target',
                         level => $self->{level}->{must});
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLEmptyChecker,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $sizes_attr;
    $GetHTMLAttrsChecker->({
      charset => sub {
        my ($self, $attr) = @_;
        $HTMLCharsetChecker->($attr->value, @_);
      },
      href => $HTMLURIAttrChecker,
      rel => sub { $HTMLLinkTypesAttrChecker->(0, $item, @_) },
      rev => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->(),
      media => $HTMLMQAttrChecker,
      hreflang => $HTMLLanguageTagAttrChecker,
      sizes => sub {
        my ($self, $attr) = @_;
        $sizes_attr = $attr;
        my %word;
        for my $word (grep {length $_}
                      split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
          unless ($word{$word}) {
            $word{$word} = 1;
            if ($word eq 'any' or $word =~ /\A[1-9][0-9]*x[1-9][0-9]*\z/) {
              #
            } else {
              $self->{onerror}->(node => $attr, 
                                 type => 'sizes:syntax error',
                                 value => $word,
                                 level => $self->{level}->{must});
            }
          } else {
            $self->{onerror}->(node => $attr, type => 'duplicate token',
                               value => $word,
                               level => $self->{level}->{must});
          }
        }
      },
      target => $HTMLTargetAttrChecker,
      type => $HTMLIMTAttrChecker,
      ## NOTE: Though |title| has special semantics,
      ## syntactically same as the |title| as global attribute.
    }, {
      %HTMLAttrStatus,
      %HTMLM12NXHTML2CommonAttrStatus,
      charset => FEATURE_HTML5_DROPPED | FEATURE_M12N10_REC,
          ## NOTE: |charset| attribute had been part of HTML5 spec though
          ## it had been commented out.
      href => FEATURE_HTML5_DEFAULT | FEATURE_RDFA_CR | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      hreflang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED |
          FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      media => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      methods => FEATURE_HTML20_RFC,
      rel => FEATURE_HTML5_DEFAULT | FEATURE_RDFA_CR | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      rev => FEATURE_RDFA_CR | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      sdapref => FEATURE_HTML20_RFC,
      sizes => FEATURE_HTML5_DEFAULT,
      target => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      urn => FEATURE_HTML20_RFC,
    })->($self, $item, $element_state);

    if ($item->{node}->has_attribute_ns (undef, 'href')) {
      $self->{has_hyperlink_element} = 1 if $item->{has_hyperlink_link_type};
    } else {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'href',
                         level => $self->{level}->{must});
    }

    unless ($item->{node}->has_attribute_ns (undef, 'rel')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'rel',
                         level => $self->{level}->{must});
    }
    
    if ($sizes_attr and not $element_state->{link_rel}->{icon}) {
      $self->{onerror}->(node => $sizes_attr,
                         type => 'attribute not allowed',
                         level => $self->{level}->{must});
    }

    if ($element_state->{link_rel}->{alternate} and
        $element_state->{link_rel}->{stylesheet}) {
      my $title_attr = $item->{node}->get_attribute_node_ns (undef, 'title');
      unless ($title_attr) {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'title',
                           level => $self->{level}->{must});
      } elsif ($title_attr->value eq '') {
        $self->{onerror}->(node => $title_attr,
                           type => 'empty style sheet title',
                           level => $self->{level}->{must});
      }
    }
  },
};

$Element->{$HTML_NS}->{meta} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
      my $status;
      if ($attr_ns eq '') {
        $status = {
          %HTMLAttrStatus,
          %XHTML2CommonAttrStatus,
          charset => FEATURE_HTML5_DEFAULT,
          content => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED |
                     FEATURE_M12N10_REC,
          dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED |
                 FEATURE_M12N10_REC,
          'http-equiv' => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED |
                FEATURE_XHTML10_REC,
          lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
          name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          scheme => FEATURE_M12N10_REC,
        }->{$attr_ln};

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
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln}
              || $AttrChecker->{$attr_ns}->{$attr_ln}
              || $AttrChecker->{$attr_ns}->{''};
        }
      } else {
        $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
            || $AttrChecker->{$attr_ns}->{''};
        $status ||= $AttrStatus->{$attr_ns}->{$attr_ln}
            || $AttrStatus->{$attr_ns}->{''};
        $status = FEATURE_ALLOWED if not defined $status;
      }

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
        ## ISSUE: No conformance createria for unknown attributes in the spec
      }

      $self->_attr_status_info ($attr, $status);
    }
    
    if (defined $name_attr) {
      if (defined $http_equiv_attr) {
        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
      } elsif (defined $charset_attr) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
      my $metadata_name = $name_attr->value;
      my $metadata_value;
      if (defined $content_attr) {
        $metadata_value = $content_attr->value;
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'content',
                           level => $self->{level}->{must});
        $metadata_value = '';
      }
    } elsif (defined $http_equiv_attr) {
      if (defined $charset_attr) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
      unless (defined $content_attr) {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'content',
                           level => $self->{level}->{must});
      }
    } elsif (defined $charset_attr) {
      if (defined $content_attr) {
        $self->{onerror}->(node => $content_attr,
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    } else {
      if (defined $content_attr) {
        $self->{onerror}->(node => $content_attr,
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:name|http-equiv',
                           level => $self->{level}->{must});
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing:name|http-equiv|charset',
                           level => $self->{level}->{must});
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
                               level => $self->{level}->{must});
          }
          last;
          ## NOTE: Entity references are not supported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'element not allowed:meta charset',
                           level => $self->{level}->{must});
      }

      unless ($item->{node}->owner_document->manakai_is_html) {
        $self->{onerror}->(node => $item->{node},
                           type => 'in XML:charset',
                           level => $self->{level}->{must});
      }
    }; # $check_charset_decl

    my $check_charset = sub ($$) {
      my ($attr, $charset_value) = @_;

      my $charset;
      ($charset, $charset_value)
          = $HTMLCharsetChecker->($charset_value, $self, $attr);

      my $ic = $item->{node}->owner_document->input_encoding;
      if (defined $ic) {
        ## TODO: Test for this case
        my $ic_charset = $Message::Charset::Info::IANACharset->{$ic};
        if ($charset ne $ic_charset) {
          $self->{onerror}->(node => $attr,
                             type => 'mismatched charset name',
                             text => $ic,
                             value => $charset_value,
                             level => $self->{level}->{must});
        }
      } else {
        ## NOTE: MUST, but not checkable, since the document is not originally
        ## in serialized form (or the parser does not preserve the input
        ## encoding information).
        $self->{onerror}->(node => $attr,
                           type => 'mismatched charset name not checked',
                           value => $charset_value,
                           level => $self->{level}->{uncertain});
      }

      if ($attr->get_user_data ('manakai_has_reference')) {
        $self->{onerror}->(node => $attr,
                           type => 'charref in charset',
                           level => $self->{level}->{must},
                           layer => 'syntax');
      }
    }; # $check_charset

    ## TODO: metadata conformance

    ## TODO: pragma conformance
    if (defined $http_equiv_attr) { ## An enumerated attribute
      my $keyword = lc $http_equiv_attr->value; ## TODO: ascii case?

      if ($self->{has_http_equiv}->{$keyword}) {
        $self->{onerror}->(type => 'duplicate http-equiv', value => $keyword,
                           node => $http_equiv_attr,
                           level => $self->{level}->{must});
      } else {
        $self->{has_http_equiv}->{$keyword} = 1;
      }

      if ($keyword eq 'content-type') {
        ## TODO: refs in "text/html; charset=" are not disallowed since rev.1275.

        $check_charset_decl->();
        if ($content_attr) {
          my $content = $content_attr->value;
          if ($content =~ m!^[Tt][Ee][Xx][Tt]/[Hh][Tt][Mm][Ll];
                            [\x09\x0A\x0C\x0D\x20]*[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                            =(.+)\z!sx) {
            $check_charset->($content_attr, $1);
          } else {
            $self->{onerror}->(node => $content_attr,
                               type => 'meta content-type syntax error',
                               level => $self->{level}->{must});
          }
        }
      } elsif ($keyword eq 'default-style') {
        ## ISSUE: Not defined yet in the spec.
      } elsif ($keyword eq 'refresh') {
        if ($content_attr) {
          my $content = $content_attr->value;
          if ($content =~ /\A[0-9]+\z/) {
            ## NOTE: Valid non-negative integer.
            #
          } elsif ($content =~ s/\A[0-9]+;[\x09\x0A\x0C\x0D\x20]+[Uu][Rr][Ll]=//) {
            ## ISSUE: Relative references are allowed? (RFC 3987 "IRI" is an absolute reference with optional fragment identifier.)
            Whatpm::URIChecker->check_iri_reference ($content, sub {
              $self->{onerror}->(value => $content, @_, node => $content_attr);
            }, $self->{level});
            $self->{has_uri_attr} = 1; ## NOTE: One of "attributes with URIs".

            $element_state->{uri_info}->{content}->{node} = $content_attr;
            $element_state->{uri_info}->{content}->{type}->{hyperlink} = 1;
            ## TODO: absolute
            push @{$self->{return}->{uri}->{$content} ||= []},
                $element_state->{uri_info}->{content};
          } else {
            $self->{onerror}->(node => $content_attr,
                               type => 'refresh:syntax error',
                               level => $self->{level}->{must});
          }
        }
      } else {
        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'enumerated:invalid',
                           level => $self->{level}->{must});
      }
    }

    if (defined $charset_attr) {
      $check_charset_decl->();
      $check_charset->($charset_attr, $charset_attr->value);
    }
  },
};

$Element->{$HTML_NS}->{style} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    type => $HTMLIMTAttrChecker, ## TODO: MUST be a styling language
    media => $HTMLMQAttrChecker,
    scoped => $GetHTMLBooleanAttrChecker->('scoped'),
    ## NOTE: |title| has special semantics for |style|s, but is syntactically
    ## not different
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    disabled => FEATURE_XHTML2_ED,
    href => FEATURE_RDFA_PR | FEATURE_XHTML2_ED,
    id => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_XHTML10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    media => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    scoped => FEATURE_HTML5_DEFAULT,
    title => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    ## NOTE: |html:style| itself has no conformance creteria on content model.
    my $type = $item->{node}->get_attribute_ns (undef, 'type');
    $type = 'text/css' unless defined $type;
    if ($type =~ m[\A(?>(?>\x0D\x0A)?[\x09\x20])*([\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+)(?>(?>\x0D\x0A)?[\x09\x20])*/(?>(?>\x0D\x0A)?[\x09\x20])*([\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+)(?>(?>\x0D\x0A)?[\x09\x20])*\z]) {
      $type = "$1/$2";
      $type =~ tr/A-Z/a-z/; ## NOTE: ASCII case-insensitive
    } else {
      ## NOTE: We don't know how parameters are handled by UAs.  According to
      ## HTML5 specification, <style> with unknown parameters in |type=""| 
      ## must be ignored.
      undef $type;
    }
    if (not defined $type) {
      $element_state->{allow_element} = 1; # invalid type=""
    } elsif ($type eq 'text/css') {
      $element_state->{allow_element} = 0;
    #} elsif ($type =~ m![/+][Xx][Mm][Ll]\z!) {
    #  ## NOTE: There is no definition for "XML-based styling language" in HTML5
    #  $element_state->{allow_element} = 1;
    } else {
      $element_state->{allow_element} = 1; # unknown
    }
    $element_state->{style_type} = $type;

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{text} = '';
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{allow_element}) {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{text} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if (not defined $element_state->{style_type}) {
      ## NOTE: Invalid type=""
      #
    } elsif ($element_state->{style_type} eq 'text/css') {
      $self->{onsubdoc}->({s => $element_state->{text},
                           container_node => $item->{node},
                           media_type => 'text/css', is_char_string => 1});
    } elsif ($element_state->{style_type} =~ m![+/][Xx][Mm][Ll]\z!) {
      ## NOTE: XML content should be checked by THIS instance of checker
      ## as part of normal tree validation.  However, we don't know of any
      ## XML-based styling language that can be used in HTML <style> element,
      ## such that we throw a "style language not supported" error.
      $self->{onerror}->(node => $item->{node},
                         type => 'XML style lang',
                         text => $element_state->{style_type},
                         level => $self->{level}->{uncertain});
    } else {
      ## NOTE: Should we raise some kind of error for,
      ## say, <style type="text/plaion">?
      $self->{onsubdoc}->({s => $element_state->{text},
                           container_node => $item->{node},
                           media_type => $element_state->{style_type},
                           is_char_string => 1});
    }

    $HTMLChecker{check_end}->(@_);
  },
};
## ISSUE: Relationship to significant content check?

$Element->{$HTML_NS}->{body} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    alink => $HTMLColorAttrChecker,
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    link => $HTMLColorAttrChecker,
    text => $HTMLColorAttrChecker,
    vlink => $HTMLColorAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{section} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED,
  check_attrs => $GetHTMLAttrsChecker->({
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
  }),
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLFlowContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
  
    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{aside} = {
  status => FEATURE_HTML5_DEFAULT,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{h1} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->{flag}->{has_hn} = 1;

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
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

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    unless ($self->{flag}->{has_hn}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:hn',
                         level => $self->{level}->{must});
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

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{address} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: add test
    #align => $GetHTMLEnumeratedAttrChecker->({
    #  left => 1, center => 1, right => 1, justify => 1,
    #}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{p} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
    style => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
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

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'before dt') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $element_state->{phase} = 'before dd';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $self->{onerror}
            ->(node => $child_el, type => 'ps element missing',
               text => 'dt',
               level => $self->{level}->{must});
        $element_state->{phase} = 'before dt';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'before dd') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $element_state->{phase} = 'before dt';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $self->{onerror}
            ->(node => $child_el, type => 'ps element missing',
               text => 'dd',
               level => $self->{level}->{must});
        $element_state->{phase} = 'before dd';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } else {
      die "check_child_element: Bad |dialog| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'before dd') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'dd',
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{pre} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_end => sub {
    my ($self, $item, $element_state) = @_;
  
    ## TODO: Flag to enable/disable IDL checking?
    my $class = $item->{node}->get_attribute_ns (undef, 'class');
    if ($class =~ /\bidl(?>-code)?\b/) { ## TODO: use classList.has
      ## NOTE: pre.idl: WHATWG, XHR, Selectors API, CSSOM specs
      ## NOTE: pre.code > code.idl-code: WebIDL spec
      ## NOTE: pre.idl-code: DOM1 spec
      ## NOTE: div.idl-code > pre: DOM, ProgressEvent specs
      ## NOTE: pre.schema: ReSpec-generated specs
      $self->{onsubdoc}->({s => $item->{node}->text_content,
                           container_node => $item->{node},
                           media_type => 'text/x-webidl',
                           is_char_string => 1});
    }

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{ol} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    reversed => $GetHTMLBooleanAttrChecker->('reversed'),
    start => $HTMLIntegerAttrChecker,
    ## TODO: HTML4 |type|
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'li') {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
};

$Element->{$HTML_NS}->{ul} = {
  %{$Element->{$HTML_NS}->{ol}},
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    ## TODO: HTML4 |type|
    ## TODO: sdaform, align
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
          ## ISSUE: ...
          $self->{onerror}->(node => $attr,
                             type => 'unknown attribute',
                             level => $self->{level}->{uncertain});
        }
      }
      $HTMLIntegerAttrChecker->($self, $attr);
    },
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    type => FEATURE_M12N10_REC_DEPRECATED,
    #value => FEATURE_HTML5_DEFAULT | FEATURE_XHTMLBASIC11_CR | 
    #    FEATURE_M12N10_REC_DEPRECATED,
    value => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED |
        FEATURE_XHTMLBASIC11_CR | FEATURE_M12N10_REC,
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    compact => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    type => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before dt';

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'in dds') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        #$element_state->{phase} = 'in dds';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $element_state->{phase} = 'in dts';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'in dts') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        #$element_state->{phase} = 'in dts';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $element_state->{phase} = 'in dds';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'before dt') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'dt') {
        $element_state->{phase} = 'in dts';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'dd') {
        $self->{onerror}
             ->(node => $child_el, type => 'ps element missing',
                text => 'dt',
                level => $self->{level}->{must});
        $element_state->{phase} = 'in dds';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } else {
      die "check_child_element: Bad |dl| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'in dts') {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'dd',
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{dt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{dd} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{a} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my %attr;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      my $status;
      if ($attr_ns eq '') {
        $status = {
          %HTMLAttrStatus,
          %HTMLM12NXHTML2CommonAttrStatus,
          accesskey => FEATURE_M12N10_REC,
          charset => FEATURE_M12N10_REC,
          coords => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          cryptopts => FEATURE_RFC2659,
          dn => FEATURE_RFC2659,
          href => FEATURE_HTML5_DEFAULT | FEATURE_RDFA_CR | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          hreflang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
          media => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED,
          methods => FEATURE_HTML20_RFC,
          name => FEATURE_M12N10_REC_DEPRECATED,
          nonce => FEATURE_RFC2659,
          onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          ping => FEATURE_HTML5_DEFAULT,
          rel => FEATURE_HTML5_DEFAULT | FEATURE_RDFA_CR | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          rev => FEATURE_RDFA_CR | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          sdapref => FEATURE_HTML20_RFC,
          shape => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          target => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          urn => FEATURE_HTML20_RFC,
        }->{$attr_ln};

        $checker = {
          accesskey => $HTMLAccesskeyAttrChecker,
          charset => sub {
            my ($self, $attr) = @_;
            $HTMLCharsetChecker->($attr->value, @_);
          },
          ## TODO: HTML4 |coords|
                     target => $HTMLTargetAttrChecker,
                     href => $HTMLURIAttrChecker,
                     ping => $HTMLSpaceURIsAttrChecker,
                     rel => sub { $HTMLLinkTypesAttrChecker->(1, $item, @_) },
          rev => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->(),
          ## TODO: HTML4 |shape|
                     media => $HTMLMQAttrChecker,
          ## TODO: HTML4/XHTML1 |name|
                     hreflang => $HTMLLanguageTagAttrChecker,
                     type => $HTMLIMTAttrChecker,
                   }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      $status ||= $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''};
      $status = FEATURE_ALLOWED if not defined $status and length $attr_ns;

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
        ## ISSUE: No conformance createria for unknown attributes in the spec
      }

      $self->_attr_status_info ($attr, $status);
    }

    $element_state->{in_a_href_original} = $self->{flag}->{in_a_href};
    if (defined $attr{href}) {
      $self->{has_hyperlink_element} = 1;
      $self->{flag}->{in_a_href} = 1;
    } else {
      for (qw/target ping rel media hreflang type/) {
        if (defined $attr{$_}) {
          $self->{onerror}->(node => $attr{$_},
                             type => 'attribute not allowed',
                             level => $self->{level}->{must});
        }
      }
    }

    $element_state->{uri_info}->{href}->{type}->{hyperlink} = 1;
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, $HTMLInteractiveContent);

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    delete $self->{flag}->{in_a_href}
        unless $element_state->{in_a_href_original};

    $HTMLTransparentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{q} = {
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdapref => FEATURE_HTML2X_RFC,
    sdasuff => FEATURE_HTML2X_RFC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};
## TODO: "Quotation punctuation (such as quotation marks), if any, must be
## placed inside the <code>q</code> element."  Though we cannot test the
## element against this requirement since it incluides a semantic bit,
## it might be possible to inform of the existence of quotation marks OUTSIDE
## the |q| element.

$Element->{$HTML_NS}->{cite} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{em} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{strong} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
          if ($child->data =~ /\A[\x09\x0A\x0C\x0D\x20]+\z/) { # Inter-element whitespace
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
      push @{$self->{term}->{$term}}, $node;
    } else {
      $self->{term}->{$term} = [$node];
    }
    ## ISSUE: The HTML5 definition for the defined term does not work with
    ## |ruby| unless |dfn| has |title|.

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{abbr} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    full => FEATURE_XHTML2_ED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  ## NOTE: "If an abbreviation is pluralised, the expansion's grammatical
  ## number (plural vs singular) must match the grammatical number of the
  ## contents of the element."  Though this can be checked by machine,
  ## it requires language-specific knowledge and dictionary, such that
  ## we don't support the check of the requirement.
  ## ISSUE: Is <abbr title="Cascading Style Sheets">CSS</abbr> conforming?
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
      $reg_sp = qr/[\x09\x0A\x0C\x0D\x20]*/;
      $input_node = $attr;
    } else {
      $input = $item->{node}->text_content;
      $reg_sp = qr/\p{WhiteSpace}*/;
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
      $reg_sp
      ([0-9]+) # 1
      (?>
        -([0-9]+) # 2
        -((?>[0-9]+)) # 3 # Use (?>) such that yyyy-mm-ddhh:mm does not match
        $reg_sp
        (?>
          T
          $reg_sp
        )?
        ([0-9]+) # 4
        :([0-9]+) # 5
        (?>
          :([0-9]+(?>\.[0-9]*)?|\.[0-9]*) # 6
        )?
        $reg_sp
        (?>
          Z
          $reg_sp
        |
          [+-]([0-9]+):([0-9]+) # 7, 8
          $reg_sp
        )?
        \z
      |
        :([0-9]+) # 9
        (?>
          :([0-9]+(?>\.[0-9]*)?|\.[0-9]*) # 10
        )?
        $reg_sp
        \z
      )
    /x) {
      if (defined $2) { ## YYYY-MM-DD T? hh:mm
        if (length $1 != 4 or length $2 != 2 or length $3 != 2 or
            length $4 != 2 or length $5 != 2) {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error',
                             level => $self->{level}->{must});
        }

        if (1 <= $2 and $2 <= 12) {
          $self->{onerror}->(node => $input_node, type => 'datetime:bad day',
                             level => $self->{level}->{must})
              if $3 < 1 or
                  $3 > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$2];
          $self->{onerror}->(node => $input_node, type => 'datetime:bad day',
                             level => $self->{level}->{must})
              if $2 == 2 and $3 == 29 and
                  not ($1 % 400 == 0 or ($1 % 4 == 0 and $1 % 100 != 0));
        } else {
          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad month',
                             level => $self->{level}->{must});
        }

        ($hour, $minute, $second) = ($4, $5, $6);
          
        if (defined $7) { ## [+-]hh:mm
          if (length $7 != 2 or length $8 != 2) {
            $self->{onerror}->(node => $input_node,
                               type => 'dateortime:syntax error',
                               level => $self->{level}->{must});
          }

          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad timezone hour',
                             level => $self->{level}->{must})
              if $7 > 23;
          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad timezone minute',
                             level => $self->{level}->{must})
              if $8 > 59;
        }
      } else { ## hh:mm
        if (length $1 != 2 or length $9 != 2) {
          $self->{onerror}->(node => $input_node,
                             type => qq'dateortime:syntax error',
                             level => $self->{level}->{must});
        }

        ($hour, $minute, $second) = ($1, $9, $10);
      }

      $self->{onerror}->(node => $input_node, type => 'datetime:bad hour',
                         level => $self->{level}->{must}) if $hour > 23;
      $self->{onerror}->(node => $input_node, type => 'datetime:bad minute',
                         level => $self->{level}->{must}) if $minute > 59;

      if (defined $second) { ## s
        ## NOTE: Integer part of second don't have to have length of two.
          
        if (substr ($second, 0, 1) eq '.') {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error',
                             level => $self->{level}->{must});
        }
          
        $self->{onerror}->(node => $input_node, type => 'datetime:bad second',
                           level => $self->{level}->{must}) if $second >= 60;
      }        
    } else {
      $self->{onerror}->(node => $input_node,
                         type => 'dateortime:syntax error',
                         level => $self->{level}->{must});
    }

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{meter} = { ## TODO: "The recommended way of giving the value is to include it as contents of the element"
## TODO: value inequalities (HTML5 revision 1463)
## TODO: content checking
## TODO: content or value must contain number (rev 2053)
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{var} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{samp} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{kbd} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
  }),
};

$Element->{$HTML_NS}->{sub} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdapref => FEATURE_HTML2X_RFC,
  }),
};

$Element->{$HTML_NS}->{sup} = $Element->{$HTML_NS}->{sub};

$Element->{$HTML_NS}->{span} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
      style => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      sdapref => FEATURE_HTML2X_RFC,
      sdasuff => FEATURE_HTML2X_RFC,
    })->($self, $item, $element_state);
    unless ($item->{node}->has_attribute_ns (undef, 'dir')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'dir',
                         level => $self->{level}->{must});
    }
  },
  ## ISSUE: The spec does not directly say that |dir| is a enumerated attr.
};

$Element->{$HTML_NS}->{ruby} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus, # XHTML 1.1 & XHTML 2.0 & XHTML+RDFa 1.0
    lang => FEATURE_HTML5_DEFAULT,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{phase} = 'before-rb';
    #$element_state->{has_sig}

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  ## NOTE: (phrasing, (rt | (rp, rt, rp)))+
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'before-rb') {
      if ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
        $element_state->{phase} = 'in-rb';
      } elsif ($child_ln eq 'rt' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        $element_state->{phase} = 'after-rt';
      } elsif ($child_ln eq 'rp' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        $element_state->{phase} = 'after-rp1';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:ruby base',
                           level => $self->{level}->{must});
        $element_state->{phase} = 'in-rb';
      }
    } elsif ($element_state->{phase} eq 'in-rb') {
      if ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
        #$element_state->{phase} = 'in-rb';
      } elsif ($child_ln eq 'rt' and $child_nsuri eq $HTML_NS) {
        unless ($element_state->{has_significant}) {
          $self->{onerror}->(node => $child_el,
                             level => $self->{level}->{should},
                             type => 'no significant content before');
        }
        $element_state->{phase} = 'after-rt';
      } elsif ($child_ln eq 'rp' and $child_nsuri eq $HTML_NS) {
        unless ($element_state->{has_significant}) {
          $self->{onerror}->(node => $child_el,
                             level => $self->{level}->{should},
                             type => 'no significant content before');
        }
        $element_state->{phase} = 'after-rp1';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:ruby base',
                           level => $self->{level}->{must});
        #$element_state->{phase} = 'in-rb';
      }
    } elsif ($element_state->{phase} eq 'after-rt') {
      if ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
        if ($element_state->{has_significant}) {
          $element_state->{has_sig} = 1;
          delete $element_state->{has_significant};
        }
        $element_state->{phase} = 'in-rb';
      } elsif ($child_ln eq 'rp' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        $element_state->{phase} = 'after-rp1';
      } elsif ($child_ln eq 'rt' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        #$element_state->{phase} = 'after-rt';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:ruby base',
                           level => $self->{level}->{must});
        if ($element_state->{has_significant}) {
          $element_state->{has_sig} = 1;
          delete $element_state->{has_significant};
        }
        $element_state->{phase} = 'in-rb';
      }
    } elsif ($element_state->{phase} eq 'after-rp1') {
      if ($child_ln eq 'rt' and $child_nsuri eq $HTML_NS) {
        $element_state->{phase} = 'after-rp-rt';
      } elsif ($child_ln eq 'rp' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el, 
                           type => 'ps element missing',
                           text => 'rt',
                           level => $self->{level}->{must});
        $element_state->{phase} = 'after-rp2';
      } else {
        $self->{onerror}->(node => $child_el, 
                           type => 'ps element missing',
                           text => 'rt',
                           level => $self->{level}->{must});
        $self->{onerror}->(node => $child_el, 
                           type => 'ps element missing',
                           text => 'rp',
                           level => $self->{level}->{must});
        unless ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:ruby base',
                             level => $self->{level}->{must});
        }
        if ($element_state->{has_significant}) {
          $element_state->{has_sig} = 1;
          delete $element_state->{has_significant};
        }
        $element_state->{phase} = 'in-rb';
      }
    } elsif ($element_state->{phase} eq 'after-rp-rt') {
      if ($child_ln eq 'rp' and $child_nsuri eq $HTML_NS) {
        $element_state->{phase} = 'after-rp2';
      } elsif ($child_ln eq 'rt' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el, 
                           type => 'ps element missing',
                           text => 'rp',
                           level => $self->{level}->{must});
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        $element_state->{phase} = 'after-rt';
      } else {
        $self->{onerror}->(node => $child_el, 
                           type => 'ps element missing',
                           text => 'rp',
                           level => $self->{level}->{must});
        unless ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:ruby base',
                             level => $self->{level}->{must});
        }
        if ($element_state->{has_significant}) {
          $element_state->{has_sig} = 1;
          delete $element_state->{has_significant};
        }
        $element_state->{phase} = 'in-rb';
      }
    } elsif ($element_state->{phase} eq 'after-rp2') {
      if ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
        if ($element_state->{has_significant}) {
          $element_state->{has_sig} = 1;
          delete $element_state->{has_significant};
        }
        $element_state->{phase} = 'in-rb';
      } elsif ($child_ln eq 'rt' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        $element_state->{phase} = 'after-rt';
      } elsif ($child_ln eq 'rp' and $child_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $child_el,
                           level => $self->{level}->{should},
                           type => 'no significant content before');
        $element_state->{phase} = 'after-rp1';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:ruby base',
                           level => $self->{level}->{must});
        if ($element_state->{has_significant}) {
          $element_state->{has_sig} = 1;
          delete $element_state->{has_significant};
        }
        $element_state->{phase} = 'in-rb';
      }
    } else {
      die "check_child_element: Bad |ruby| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      if ($element_state->{phase} eq 'before-rb') {
        $element_state->{phase} = 'in-rb';
      } elsif ($element_state->{phase} eq 'in-rb') {
        #
      } elsif ($element_state->{phase} eq 'after-rt' or
               $element_state->{phase} eq 'after-rp2') {
        $element_state->{phase} = 'in-rb';
      } elsif ($element_state->{phase} eq 'after-rp1') {
        $self->{onerror}->(node => $child_node, 
                           type => 'ps element missing',
                           text => 'rt',
                           level => $self->{level}->{must});
        $self->{onerror}->(node => $child_node, 
                           type => 'ps element missing',
                           text => 'rp',
                           level => $self->{level}->{must});
        $element_state->{phase} = 'in-rb';
      } elsif ($element_state->{phase} eq 'after-rp-rt') {
        $self->{onerror}->(node => $child_node, 
                           type => 'ps element missing',
                           text => 'rp',
                           level => $self->{level}->{must});
        $element_state->{phase} = 'in-rb';
      } else {
        die "check_child_text: Bad |ruby| phase: $element_state->{phase}";
      }
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    if ($element_state->{phase} eq 'before-rb') {
      $self->{onerror}->(node => $item->{node},
                         level => $self->{level}->{should},
                         type => 'no significant content');
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing',
                         text => 'rt',
                         level => $self->{level}->{must});
    } elsif ($element_state->{phase} eq 'in-rb') {
      unless ($element_state->{has_significant}) {
        $self->{onerror}->(node => $item->{node},
                           level => $self->{level}->{should},
                           type => 'no significant content at the end');
      }
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing',
                         text => 'rt',
                         level => $self->{level}->{must});
    } elsif ($element_state->{phase} eq 'after-rt' or
             $element_state->{phase} eq 'after-rp2') {
      #
    } elsif ($element_state->{phase} eq 'after-rp1') {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing',
                         text => 'rt',
                         level => $self->{level}->{must});
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing',
                         text => 'rp',
                         level => $self->{level}->{must});
    } elsif ($element_state->{phase} eq 'after-rp-rt') {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing',
                         text => 'rp',
                         level => $self->{level}->{must});
    } else {
      die "check_child_text: Bad |ruby| phase: $element_state->{phase}";
    }

    ## NOTE: A modified version of |check_end| of %AnyChecker.
    if ($element_state->{has_significant} or $element_state->{has_sig}) {
      $item->{real_parent_state}->{has_significant} = 1;
    }    
  },
};

$Element->{$HTML_NS}->{rt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT,
  }),
};

$Element->{$HTML_NS}->{rp} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_DEFAULT,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{text} = '';

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{text} .= $child_node->data;
      ## NOTE: |<rp> <!---->(</rp>| is allowed.
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    my $p_class = ($item->{parent_state} and
                   $item->{parent_state}->{phase} and
                   $item->{parent_state}->{phase} eq 'after-rp2')
        ? qr/\p{Pe}/ : qr/\p{Ps}/;
    if ($element_state->{text} =~ /\A$p_class\z/) {
        #=~ /\A[\x09\x0A\x0C\x0D\x20]*${p_class}[\x09\x0A\x0C\x0D\x20]*\z/) {
      #
    } else {
      $self->{onerror}->(node => $item->{node},
                         type => 'rp:syntax error',
                         level => $self->{level}->{must});
    }

    $HTMLTextChecker{check_end}->(@_);
  },  
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
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
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
                         level => $self->{level}->{should},
                         type => 'no significant content');
    }
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{figure} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_FD,
  ## NOTE: legend, Flow | Flow, legend?
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
      $element_state->{has_non_legend} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'legend') {
      if ($element_state->{has_legend_at_first}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:figure legend',
                           level => $self->{level}->{must});
      } elsif ($element_state->{has_legend}) {
        $self->{onerror}->(node => $element_state->{has_legend},
                           type => 'element not allowed:figure legend',
                           level => $self->{level}->{must});
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
                           level => $self->{level}->{must});
      }
    }

    $HTMLFlowContentChecker{check_end}->(@_);
## ISSUE: |<figure><legend>aa</legend></figure>| should be an error?
  },
};
## TODO: Test for <nest/> in <figure/>

my $AttrCheckerNotImplemented = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr,
                     type => 'unknown attribute',
                     level => $self->{level}->{uncertain});
};

$Element->{$HTML_NS}->{img} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
                             level => $self->{level}->{must});
        }
        $GetHTMLBooleanAttrChecker->('ismap')->($self, $attr, $parent_item);
      },
      longdesc => $HTMLURIAttrChecker,
      ## TODO: HTML4 |name|
      height => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
      vspace => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      width => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
    }, {
      %HTMLAttrStatus,
      %HTMLM12NXHTML2CommonAttrStatus,
      align => FEATURE_M12N10_REC_DEPRECATED,
      alt => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
      border => FEATURE_M12N10_REC_DEPRECATED,
      height => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
      hspace => FEATURE_M12N10_REC_DEPRECATED,
      ismap => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      longdesc => FEATURE_M12N10_REC,
      name => FEATURE_M12N10_REC_DEPRECATED,
      sdapref => FEATURE_HTML20_RFC,
      src => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      usemap => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      vspace => FEATURE_M12N10_REC_DEPRECATED,
      width => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    })->($self, $item, $element_state);
    unless ($item->{node}->has_attribute_ns (undef, 'alt')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'alt',
                         level => $self->{level}->{should});
      ## TODO: ...
    }
    unless ($item->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'src',
                         level => $self->{level}->{must});
    }

    ## TODO: external resource check

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{lowsrc}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{dynsrc}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{longdesc}->{type}->{cite} = 1;
  },
};

$Element->{$HTML_NS}->{iframe} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
      ## NOTE: Not part of M12N10 Strict
  check_attrs => $GetHTMLAttrsChecker->({
    height => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
    name => $HTMLBrowsingContextNameAttrChecker,
    sandbox => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->({
      'allow-same-origin' => 1, 'allow-forms' => 1, 'allow-scripts' => 1,
    }),
    seemless => $GetHTMLBooleanAttrChecker->('seemless'),
    src => $HTMLURIAttrChecker,
    width => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_XHTML10_REC,
    class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    frameborder => FEATURE_M12N10_REC,
    height => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    longdesc => FEATURE_M12N10_REC,
    marginheight => FEATURE_M12N10_REC,
    marginwidth => FEATURE_M12N10_REC,
    #name => FEATURE_HTML5_WD | FEATURE_M12N10_REC_DEPRECATED,
    name => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    sandbox => FEATURE_HTML5_WD,
    scrolling => FEATURE_M12N10_REC,
    seemless => FEATURE_HTML5_WD,
    src => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    width => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{embed} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_WD,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $has_src;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;

      my $status = {
        %HTMLAttrStatus,
        height => FEATURE_HTML5_DEFAULT,
        src => FEATURE_HTML5_WD,
        type => FEATURE_HTML5_WD,
        width => FEATURE_HTML5_DEFAULT,
      }->{$attr_ln};

      if ($attr_ns eq '') {
        if ($attr_ln eq 'src') {
          $checker = $HTMLURIAttrChecker;
          $has_src = 1;
        } elsif ($attr_ln eq 'type') {
          $checker = $HTMLIMTAttrChecker;
        } elsif ($attr_ln eq 'width' or $attr_ln eq 'height') {
          $checker = $AttrCheckerNotImplemented; ## TODO: because spec does not define them yet.
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } elsif ($attr_ln !~ /^[Xx][Mm][Ll]/ and
                 $attr_ln !~ /[A-Z]/ and
                 $attr_ln =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
          $checker = $HTMLAttrChecker->{$attr_ln}
            || sub { }; ## NOTE: Any local attribute is ok.
          $status = FEATURE_HTML5_WD | FEATURE_ALLOWED;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      $status ||= $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''};
      $status = FEATURE_ALLOWED if not defined $status and length $attr_ns;

      if ($checker) {
        $checker->($self, $attr, $item, $element_state);
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr, 
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
        ## ISSUE: No conformance createria for global attributes in the spec
      }

      $self->_attr_status_info ($attr, $status);
    }

    unless ($has_src) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'src',
                         level => $self->{level}->{info});
      ## NOTE: <embed> without src="" is allowed since revision 1929.
      ## We issues an informational message since <embed> w/o src=""
      ## is likely an authoring error.
    }

    ## TODO: external resource check

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

## TODO:
## {applet} FEATURE_M12N10_REC_DEPRECATED
## class, id, title, alt, archive, code, codebase, height, object, width name style,hspace,vspace(xhtml10)

$Element->{$HTML_NS}->{object} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
      name => $HTMLBrowsingContextNameAttrChecker,
      standby => sub {}, ## NOTE: %Text; in HTML4
      type => $HTMLIMTAttrChecker,
      usemap => $HTMLUsemapAttrChecker,
      height => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
      vspace => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      width => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
    }, {
      %HTMLAttrStatus,
      %HTMLM12NXHTML2CommonAttrStatus,
      align => FEATURE_XHTML10_REC,
      archive => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      border => FEATURE_XHTML10_REC,
      classid => FEATURE_M12N10_REC,
      codebase => FEATURE_M12N10_REC,
      codetype => FEATURE_M12N10_REC,
      'content-length' => FEATURE_XHTML2_ED,
      data => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      datafld => FEATURE_HTML4_REC_RESERVED,
      dataformatas => FEATURE_HTML4_REC_RESERVED,
      datasrc => FEATURE_HTML4_REC_RESERVED,
      declare => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      height => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      hspace => FEATURE_XHTML10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
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
                           type => 'attribute missing:data|type',
                           level => $self->{level}->{must});
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
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
      $element_state->{has_non_legend} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'param') {
      if ($element_state->{has_non_param}) {
        $self->{onerror}->(node => $child_el, 
                           type => 'element not allowed:flow',
                           level => $self->{level}->{must});
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
                         level => $self->{level}->{should},
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
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
      href => FEATURE_RDFA_PR,
      id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      name => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      type => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      value => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      valuetype => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    })->(@_);
    unless ($item->{node}->has_attribute_ns (undef, 'name')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'name',
                         level => $self->{level}->{must});
    }
    unless ($item->{node}->has_attribute_ns (undef, 'value')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'value',
                         level => $self->{level}->{must});
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
    height => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
    width => $AttrCheckerNotImplemented, ## TODO: spec does not define yet
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
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
      delete $element_state->{allow_source};
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'source') {
      unless ($element_state->{allow_source}) {
        $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:flow',
                           level => $self->{level}->{must});
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
                         type => 'child element missing',
                         text => 'source',
                         level => $self->{level}->{must});
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
      media => $HTMLMQAttrChecker,
      pixelratio => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
      src => $HTMLURIAttrChecker, ## ISSUE: Negative or zero pixelratio=""
      type => $HTMLIMTAttrChecker,
    }, {
      %HTMLAttrStatus,
      media => FEATURE_HTML5_DEFAULT,
      pixelratio => FEATURE_HTML5_DEFAULT,
      src => FEATURE_HTML5_DEFAULT,
      type => FEATURE_HTML5_DEFAULT,
    })->(@_);
    unless ($item->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'src',
                         level => $self->{level}->{must});
    }

    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

$Element->{$HTML_NS}->{canvas} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_COMPLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    height => FEATURE_HTML5_COMPLETE,
    width => FEATURE_HTML5_COMPLETE,
  }),
};

$Element->{$HTML_NS}->{map} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $has_name;
    $GetHTMLAttrsChecker->({
      name => sub {
        my ($self, $attr) = @_;
        my $value = $attr->value;
        if (length $value) {
          ## NOTE: Duplication is not non-conforming.
          ## NOTE: Space characters are not non-conforming.
          #
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'empty attribute value',
                             level => $self->{level}->{must});
        }
        $self->{map}->{$value} ||= $attr;
        $has_name = [$value, $attr];
      },
    }, {
      %HTMLAttrStatus,
      class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
      #name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC_DEPRECATED,
      name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
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

    if ($has_name) {
      my $id = $item->{node}->get_attribute_ns (undef, 'id');
      if (defined $id and $has_name->[0] ne $id) {
        $self->{onerror}->(node => $item->{node}->get_attribute_node ('id'),
                           type => 'id ne name',
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'name',
                         level => $self->{level}->{must});
    }
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{in_map_original} = $self->{flag}->{in_map};
    $self->{flag}->{in_map} = [@{$self->{flag}->{in_map} or []}, {}];
        ## NOTE: |{in_map}| is a reference to the array which contains
        ## hash references.  Hashes are corresponding to the opening
        ## |map| elements and each of them contains the key-value
        ## pairs corresponding to the absolute URLs for the processed
        ## |area| elements in the |map| element corresponding to the
        ## hash.  The key represents the resource (## TODO: use
        ## absolute URL), while the value represents whether there is
        ## an |area| element whose |alt| attribute is specified to a
        ## non-empty value.  If there IS such an |area| element for
        ## the resource specified by the key, then the value is set to
        ## zero (|0|).  Otherwise, if there is no such an |area|
        ## element but there is any |area| element with the empty
        ## |alt=""| attribute, then the value contains an array
        ## reference that contains all of such |area| elements.

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    
    for (keys %{$self->{flag}->{in_map}->[-1]}) {
      my $nodes = $self->{flag}->{in_map}->[-1]->{$_};
      next unless $nodes;
      for (@$nodes) {
        $self->{onerror}->(type => 'empty area alt',
                           node => $_,
                           level => $self->{level}->{html5_no_may});
      }
    }
    
    $self->{flag}->{in_map} = $element_state->{in_map_original};
    
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
      my $status;
      if ($attr_ns eq '') {
        $status = {
          %HTMLAttrStatus,
          %HTMLM12NCommonAttrStatus,
          accesskey => FEATURE_M12N10_REC,
          alt => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          coords => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          href => FEATURE_HTML5_DEFAULT | FEATURE_RDFA_CR | FEATURE_M12N10_REC,
          hreflang => FEATURE_HTML5_DEFAULT,
          lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
          media => FEATURE_HTML5_DEFAULT,
          nohref => FEATURE_M12N10_REC,
          onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          ping => FEATURE_HTML5_DEFAULT,
          rel => FEATURE_HTML5_DEFAULT | FEATURE_RDFA_CR,
          shape => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          target => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          type => FEATURE_HTML5_DEFAULT,
        }->{$attr_ln};

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
                                            type => 'coords:syntax error',
                                            level => $self->{level}->{must});
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
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      $status ||= $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''};
      $status = FEATURE_ALLOWED if not defined $status and length $attr_ns;

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                             level => $self->{level}->{uncertain});
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }

      $self->_attr_status_info ($attr, $status);
    }

    if (defined $attr{href}) {
      $self->{has_hyperlink_element} = 1;
      if (defined $attr{alt}) {
        my $url = $attr{href}->value; ## TODO: resolve
        if (length $attr{alt}->value) {
          for (@{$self->{flag}->{in_map} or []}) {
            $_->{$url} = 0;
          }
        } else {
          ## NOTE: Empty |alt=""|.  If there is another |area| element
          ## with the same |href=""| and that |area| elemnet's
          ## |alt=""| attribute is not an empty string, then this
          ## is conforming.
          for (@{$self->{flag}->{in_map} or []}) {
            push @{$_->{$url} ||= []}, $attr{alt}
                unless exists $_->{$url} and not $_->{$url};
          }
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'alt',
                           level => $self->{level}->{must});
      }
    } else {
      for (qw/target ping rel media hreflang type alt/) {
        if (defined $attr{$_}) {
          $self->{onerror}->(node => $attr{$_},
                             type => 'attribute not allowed',
                             level => $self->{level}->{must});
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
                                 type => 'coords:out of range',
                                 index => 2,
                                 value => $coords->[2],
                                 level => $self->{level}->{must});
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number not 3',
                               text => 0+@$coords,
                               level => $self->{level}->{must});
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'coords',
                           level => $self->{level}->{must});
      }
    } elsif ($shape eq 'default') {
      if (defined $attr{coords}) {
        $self->{onerror}->(node => $attr{coords},
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($shape eq 'polygon') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords >= 6) {
            unless (@$coords % 2 == 0) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:number not even',
                                 text => 0+@$coords,
                                 level => $self->{level}->{must});
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number lt 6',
                               text => 0+@$coords,
                               level => $self->{level}->{must});
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'coords',
                           level => $self->{level}->{must});
      }
    } elsif ($shape eq 'rectangle') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords == 4) {
            unless ($coords->[0] < $coords->[2]) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range',
                                 index => 0,
                                 value => $coords->[0],
                                 level => $self->{level}->{must});
            }
            unless ($coords->[1] < $coords->[3]) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range',
                                 index => 1,
                                 value => $coords->[1],
                                 level => $self->{level}->{must});
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number not 4',
                               text => 0+@$coords,
                               level => $self->{level}->{must});
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'coords',
                           level => $self->{level}->{must});
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
                         level => $self->{level}->{must});
    }

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{table} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    cellpadding => $HTMLLengthAttrChecker,
    cellspacing => $HTMLLengthAttrChecker,
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
    %HTMLM12NXHTML2CommonAttrStatus,
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
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
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
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'in trs') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
        #$element_state->{phase} = 'in trs';
      } elsif (not $element_state->{has_tfoot} and
               $child_nsuri eq $HTML_NS and $child_ln eq 'tfoot') {
        $element_state->{phase} = 'after tfoot';
        $element_state->{has_tfoot} = 1;
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
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
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
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
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
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
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'after tfoot') {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    } else {
      die "check_child_element: Bad |table| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## Table model errors
    require Whatpm::HTMLTable;
    my $table = Whatpm::HTMLTable->form_table ($item->{node}, sub {
      $self->{onerror}->(@_);
    }, $self->{level});
    Whatpm::HTMLTable->assign_header
        ($table, $self->{onerror}, $self->{level});
    push @{$self->{return}->{table}}, $table;

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{caption} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      top => 1, bottom => 1, left => 1, right => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
                         level => $self->{level}->{html4_fact});
    }
  },
  charoff => $HTMLLengthAttrChecker,

  ## HTML4 %cellvalign;
  valign => $GetHTMLEnumeratedAttrChecker->({
    top => 1, middle => 1, bottom => 1, baseline => 1,
  }),
);

$Element->{$HTML_NS}->{colgroup} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
      ## NOTE: Defined only if "the |colgroup| element contains no |col| elements"
      ## TODO: "attribute not supported" if |col|.
      ## ISSUE: MUST NOT if any |col|?
      ## ISSUE: MUST NOT for |<colgroup span="1"><any><col/></any></colgroup>| (though non-conforming)?
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    span => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'col') {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
};

$Element->{$HTML_NS}->{col} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    span => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC,
  }),
};

$Element->{$HTML_NS}->{tbody} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    valign => FEATURE_M12N10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'tr') {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    bgcolor => $HTMLColorAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
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
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and
             ($child_ln eq 'td' or $child_ln eq 'th')) {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
};

$Element->{$HTML_NS}->{td} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    abbr => sub {}, ## NOTE: HTML4 %Text; and SHOULD be short.
    axis => sub {}, ## NOTE: HTML4 "cdata", comma-separated
    bgcolor => $HTMLColorAttrChecker,
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    headers => sub {
      ## NOTE: Will be checked by Whatpm::HTMLTable->assign_header.
      ## Though that method does not check the |headers| attribute of a
      ## |td| element if the element does not form a table, in that case
      ## the |td| element is non-conforming anyway.
    },
    nowrap => $GetHTMLBooleanAttrChecker->('nowrap'),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    abbr => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    align => FEATURE_M12N10_REC,
    axis => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    colspan => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    headers => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    height => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    nowrap => FEATURE_M12N10_REC_DEPRECATED,
    rowspan => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    scope => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

$Element->{$HTML_NS}->{th} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    abbr => sub {}, ## NOTE: HTML4 %Text; and SHOULD be short.
    axis => sub {}, ## NOTE: HTML4 "cdata", comma-separated
    bgcolor => $HTMLColorAttrChecker,
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    ## TODO: HTML4(?) |headers|
    nowrap => $GetHTMLBooleanAttrChecker->('nowrap'),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    abbr => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    align => FEATURE_M12N10_REC,
    axis => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    bgcolor => FEATURE_M12N10_REC_DEPRECATED,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    colspan => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    headers => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    height => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    nowrap => FEATURE_M12N10_REC_DEPRECATED,
    rowspan => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    scope => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valign => FEATURE_M12N10_REC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
};

$Element->{$HTML_NS}->{form} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => $AttrCheckerNotImplemented, ## TODO: ContentTypes [WF2]
    'accept-charset' => $HTMLCharsetsAttrChecker,
    action => $HTMLURIAttrChecker, ## TODO: "User agent behavior for a value other than HTTP URI is undefined" [HTML4]
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
    enctype => $HTMLIMTAttrChecker, ## TODO: "multipart/form-data" should be used when type=file is used [HTML4] ## TODO: MUST NOT parameter [WF2]
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
        ## NOTE: "get" SHOULD be used for idempotent submittion,
        ## "post" SHOULD be used otherwise [HTML4].  This cannot be tested.
    name => sub {
      my ($self, $attr) = @_;
      
      my $value = $attr->value;
      if ($value eq '') {
        $self->{onerror}->(type => 'empty form name',
                           node => $attr,
                           level => $self->{level}->{must});
      } else {
        if ($self->{form}->{$value}) {
          $self->{onerror}->(type => 'duplicate form name',
                             node => $attr,
                             value => $value,
                             level => $self->{level}->{must});
        } else {
          $self->{form}->{$value} = 1;
        }
      }
    },
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
    onreceived => $HTMLEventHandlerAttrChecker,
    replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
    target => $HTMLTargetAttrChecker,
    ## TODO: Warn for combination whose behavior is not defined in HTML4/WF2.
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_WF2X | FEATURE_M12N10_REC,
    'accept-charset' => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    action => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    data => FEATURE_WF2,
    enctype => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    method => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    #name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC_DEPRECATED,
    name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onformchange => FEATURE_WF2_INFORMATIVE,
    onforminput => FEATURE_WF2_INFORMATIVE,
    onreceived => FEATURE_WF2,
    onreset => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onsubmit => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    replace => FEATURE_WF2,
    sdapref => FEATURE_HTML20_RFC,
    sdasuff => FEATURE_HTML20_RFC,
    target => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {form => 1}});

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
    $element_state->{id_type} = 'form';
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{fieldset} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    form => $HTMLFormAttrChecker,
    ## TODO: name [HTML5]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    form => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    name => FEATURE_HTML5_DEFAULT,
  }),
  ## NOTE: legend, Flow
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
      $element_state->{has_non_legend} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'legend') {
      if ($element_state->{has_non_legend}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:details legend',
                           level => $self->{level}->{must});
      }
      $element_state->{has_legend} = 1;
      $element_state->{has_non_legend} = 1;
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
      $element_state->{has_non_legend} = 1 unless $child_is_transparent;
      ## TODO:
      ## |<details><object><legend>xx</legend></object>..</details>|
      ## should be an error, since |object| is allowed as flow,
      ## therefore |details| part of the content model does not match.
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
                         type => 'child element missing',
                         text => 'legend',
                         level => $self->{level}->{must});
    }

    $HTMLFlowContentChecker{check_end}->(@_);
    ## ISSUE: |<details><legend>aa</legend></details>| error?
  },
  ## NOTE: This definition is partially reused by |details| element's
  ## checker.
  ## TODO: Tests for <nest/> in <fieldset>
};

$Element->{$HTML_NS}->{input} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
        
    my $state = $item->{node}->get_attribute_ns (undef, 'type');
    $state = 'text' unless defined $state;
    $state =~ tr/A-Z/a-z/; ## ASCII case-insensitive

    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      my $status;
      if ($attr_ns eq '') {
        $status =
        {
         %HTMLAttrStatus,
         %HTMLM12NCommonAttrStatus,
         accept => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
         'accept-charset' => FEATURE_HTML2X_RFC,
         accesskey => FEATURE_M12N10_REC,
         action => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         align => FEATURE_M12N10_REC_DEPRECATED,
         alt => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         autocomplete => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         autofocus => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         checked => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         datafld => FEATURE_HTML4_REC_RESERVED,
         dataformatas => FEATURE_HTML4_REC_RESERVED,
         datasrc => FEATURE_HTML4_REC_RESERVED,
         disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
         enctype => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         form => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         inputmode => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_XHTMLBASIC11_CR,
         ismap => FEATURE_M12N10_REC,
         lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
         list => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         max => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         maxlength => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
         method => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         min => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onformchange => FEATURE_WF2_INFORMATIVE,
         onforminput => FEATURE_WF2_INFORMATIVE,
         oninput => FEATURE_WF2,
         oninvalid => FEATURE_WF2,
         onselect => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         pattern => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         readonly => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
         replace => FEATURE_WF2,
         required => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         sdapref => FEATURE_HTML20_RFC,
         size => FEATURE_HTML5_DEFAULT | FEATURE_WF2X_DEPRECATED | FEATURE_M12N10_REC,
         src => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         step => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         target => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
         template => FEATURE_HTML5_AT_RISK | FEATURE_WF2,
         type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         usemap => FEATURE_HTML5_DROPPED | FEATURE_M12N10_REC,
         value => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
        }->{$attr_ln};

        $checker =
        {
         ## NOTE: Value of an empty string means that the attribute is only
         ## applicable for a specific set of states.
         accept => '',
         action => '',
         alt => '',
         autocomplete => '',
         autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
             ## ISSUE: No HTML5 definition yet.  ## TODO: Tests
         checked => '',
         disabled => $GetHTMLBooleanAttrChecker->('disabled'),
             ## ISSUE: No HTML5 definition yet.  ## TODO: Tests
         enctype => '',
         form => $HTMLFormAttrChecker,
         list => '',
         max => '',
         maxlength => '',
         method => '',
         min => '',
         name => sub {
           ## ISSUE: No HTML5 definition yet.
           ## TODO: tests
         },
         pattern => '',
         readonly => '',
         required => '',
         size => '',
         src => '',
         step => '',
         target => '',
         type => $GetHTMLEnumeratedAttrChecker->({
           hidden => 1, text => 1, email => 1, url => 1, password => 1,
           datetime => 1, date => 1, month => 1, week => 1, time => 1,
           'datetime-local' => 1, number => 1, range => 1, checkbox => 1,
           radio => 1, file => 1, submit => 1, image => 1, reset => 1,
           button => 1,
         }),
         value => '',
        }->{$attr_ln};

        ## State-dependent checkers
        unless ($checker) {
          if ($state eq 'hidden') {
            $checker =
            {
             value => sub {
               my ($self, $attr, $item, $element_state) = @_;
               my $name = $item->{node}->get_attribute_ns (undef, 'name');
               if (defined $name and $name eq '_charset_') { ## case-sensitive
                 $self->{onerror}->(node => $attr,
                                    type => '_charset_ value',
                                    level => $self->{level}->{must});
               }
             },
            }->{$attr_ln} || $checker;
            ## TODO: Warn if no name attribute?
            ## TODO: Warn if name!=_charset_ and no value attribute?
          } elsif ($state eq 'datetime') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             ## TODO: max
             ## TODO: min
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid UTC date and time string.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'date') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             ## TODO: max
             ## TODO: min
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid date string.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'month') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             ## TODO: max
             ## TODO: min
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid month string.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'week') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             ## TODO: max
             ## TODO: min
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid week string.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'time') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             ## TODO: max
             ## TODO: min
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid time string.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'datetime-local') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             ## TODO: max
             ## TODO: min
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid local date and time string.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'number') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             max => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
             min => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
               ## TODO: min & max tests
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid floating point number.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'range') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             max => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
             min => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
               ## TODO: min & max tests
             step => $StepAttrChecker,
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if not a valid floating point number.
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'checkbox' or $state eq 'radio') {
            $checker = 
            {
             ## TDDO: checked
             required => $GetHTMLBooleanAttrChecker->('required'),
             value => sub { }, ## NOTE: No restriction.
            }->{$attr_ln} || $checker;
            ## TODO: There MUST be another input type=radio with same
            ## name (Radio state).
            ## ISSUE: There should be exactly one type=radio with checked?
          } elsif ($state eq 'file') {
            $checker =
            {
             ## TODO: accept
             required => $GetHTMLBooleanAttrChecker->('required'),
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'submit') {
            $checker =
            {
             ## TODO: action
             ## TODO: enctype
             ## TODO: method
             ## TODO: target
             value => sub { }, ## NOTE: No restriction.
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'image') {
            $checker =
            {
             ## TODO: action
             alt => sub {
               my ($self, $attr) = @_;
               my $value = $attr->value;
               unless (length $value) {
                 $self->{onerror}->(node => $attr,
                                    type => 'empty anchor image alt',
                                    level => $self->{level}->{must});
               }
             },
             ## TODO: enctype
             ## TODO: method
             src => $HTMLURIAttrChecker,
               ## TODO: There is requirements on the referenced resource.
               ## TODO: tests
             ## TODO: target
            }->{$attr_ln} || $checker;
            ## TODO: alt & src are required.
          } elsif ({
                    reset => 1, button => 1,
                    ## NOTE: From Web Forms 2.0:
                    remove => 1, 'move-up' => 1, 'move-down' => 1,
                    add => 1,
                   }->{$state}) {
            $checker = 
            {
             ## NOTE: According to Web Forms 2.0, |input| attribute
             ## has |template| attribute to support the |add| button
             ## type (as part of the repetition template feature).  It
             ## conflicts with the |template| global attribute
             ## introduced as part of the data template feature.
             ## NOTE: |template| attribute as defined in Web Forms 2.0
             ## has no author requirement.
               ## TODO: template tests
             value => sub { }, ## NOTE: No restriction.
            }->{$attr_ln} || $checker;
          } else { # Text, E-mail, URL, Password
            $checker =
            {
             accept => $AttrCheckerNotImplemented, ## TODO: ContentTypes [WF2]
             'accept-charset' => $HTMLCharsetsAttrChecker,
             accesskey => $HTMLAccesskeyAttrChecker,
             action => $HTMLURIAttrChecker,
             align => $GetHTMLEnumeratedAttrChecker->({
               top => 1, middle => 1, bottom => 1, left => 1, right => 1,
             }),
             checked => $GetHTMLBooleanAttrChecker->('checked'),
             enctype => $HTMLIMTAttrChecker,
             ## TODO: inputmode [WF2]
             ismap => $GetHTMLBooleanAttrChecker->('ismap'),
             maxlength => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
             method => $GetHTMLEnumeratedAttrChecker->({
               get => 1, post => 1, put => 1, delete => 1,
             }),
             onformchange => $HTMLEventHandlerAttrChecker,
             onforminput => $HTMLEventHandlerAttrChecker,
             oninput => $HTMLEventHandlerAttrChecker,
             oninvalid => $HTMLEventHandlerAttrChecker,
             replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
             target => $HTMLTargetAttrChecker,
             usemap => $HTMLUsemapAttrChecker,


             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: list
             maxlength => sub {
               my ($self, $attr, $item, $element_state) = @_;

               $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 })->(@_);

               if ($attr->value =~ /^[\x09\x0A\x0D\x20]*([0-9]+)/) {
                 ## NOTE: Applying the rules for parsing non-negative
                 ## integers results in a number.
                 my $max_allowed_value_length = 0+$1;

                 my $value = $item->{node}->get_attribute_ns (undef, 'value');
                 if (defined $value) {
                   my $codepoint_length = length $value;
                   $codepoint_length++
                       while $value =~ /[\x{10000}-\x{10FFFF}]/g;

                   if ($codepoint_length > $max_allowed_value_length) {
                     $self->{onerror}
                         ->(node => $item->{node}
                              ->get_attribute_node_ns (undef, 'value'),
                            type => 'value too long',
                            level => $self->{level}->{must});
                   }
                 }
               }
             },
             ## TODO: pattern
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             size => $GetHTMLNonNegativeIntegerAttrChecker->(sub {shift > 0}),
             value => sub {
               ## NOTE: No restriction.
               ## TODO: Warn if it contains CR or LF?
               ## TODO: Warn if not addr-spec (E-Mail state)?
               ## TODO: Warn if not a URL (URL state)?
             },
            }->{$attr_ln} || $checker;
            $checker = '' if $state eq 'password' and $attr_ln eq 'list';
            $state = 'text';
          }
        }

        if (defined $checker) {
          if ($checker eq '') {
            $checker = sub {
              my ($self, $attr) = @_;
              $self->{onerror}->(node => $attr,
                                 type => 'input attr not applicable',
                                 text => $state,
                                 level => $self->{level}->{must});
            };
          }
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      $status ||= $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''};
      $status = FEATURE_ALLOWED if not defined $status and length $attr_ns;

      if ($checker) {
        $checker->($self, $attr, $item, $element_state) if ref $checker;
      } elsif ($attr_ns eq '' and not $status) {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }

      $self->_attr_status_info ($attr, $status);
    }
  },
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <input>
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    if ($self->{flag}->{has_label} and $self->{flag}->{has_labelable}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'multiple labelable fae',
                         level => $self->{level}->{must});
    } else {
      $self->{flag}->{has_labelable} = 2;
    }
    
    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{id_type} = 'labelable';
  },
};

## TODO: Form |name| attributes: MUST NOT conflict with RFC 3106 [WF2]

## NOTE: "authors who are nesting repetition blocks should position such
## [repetition-block-related] buttons carefully to make clear which block a
## button applies to.": I have no idea how this can be tested.

$Element->{$HTML_NS}->{button} = {
  %HTMLPhrasingContentChecker, ## ISSUE: -interactive?
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
    action => $HTMLURIAttrChecker,
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    form => $HTMLFormAttrChecker,
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
    name => sub {}, ## NOTE: CDATA [M12N]
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
    replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
    target => $HTMLTargetAttrChecker,
    ## NOTE: According to Web Forms 2.0, |button| attribute has |template|
    ## attribute to support the |add| button type (as part of repetition
    ## template feature).  It conflicts with the |template| global attribute
    ## introduced as part of the data template feature.
    ## NOTE: |template| attribute as defined in Web Forms 2.0 has no
    ## author requirement.
    type => $GetHTMLEnumeratedAttrChecker->({
      button => 1, submit => 1, reset => 1,
      ## [WF2]
      add => 1, remove => 1, 'move-up' => 1, 'move-down' => 1,
    }),
    value => sub {}, ## NOTE: CDATA [M12N]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_M12N10_REC,
    action => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    autofocus => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    enctype => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    form => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    method => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onformchange => FEATURE_WF2_INFORMATIVE,
    onforminput => FEATURE_WF2_INFORMATIVE,
    replace => FEATURE_WF2,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    target => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    template => FEATURE_WF2,
    type => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    value => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    if ($self->{flag}->{has_label} and $self->{flag}->{has_labelable}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'multiple labelable fae',
                         level => $self->{level}->{must});
    } else {
      $self->{flag}->{has_labelable} = 2;
    }
    
    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{id_type} = 'labelable';
  },
};

$Element->{$HTML_NS}->{label} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC
      | FEATURE_XHTML2_ED, 
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
    for => sub {
      my ($self, $attr) = @_;
      
      ## NOTE: MUST be an ID of a labelable element.
      
      push @{$self->{idref}}, ['labelable', $attr->value, $attr];
    },
    form => $HTMLFormAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    accesskey => FEATURE_WF2 | FEATURE_M12N10_REC,
    for => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    form => FEATURE_HTML5_DEFAULT,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {label => 1}});

    $element_state->{has_label_original} = $self->{flag}->{has_label};
    $self->{flag}->{has_label} = 1;
    $element_state->{has_labelable_original} = $self->{flag}->{has_labelable};
    $self->{flag}->{has_labelable} = $item->{node}->has_attribute ('for')?1:0;

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    
    if ($self->{flag}->{has_labelable} == 1) { # has for="" but no labelable
      $self->{flag}->{has_labelable}
          = $element_state->{has_labelable_original};
    }
    delete $self->{flag}->{has_label}
        unless $element_state->{has_label_original};
    ## TODO: Warn if no labelable descendant?  <input type=hidden>?

    ## NOTE: |<label for=a><input id=a></label>| is non-conforming.

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
  ## TODO: Tests for <nest/> in <label>
};

$Element->{$HTML_NS}->{select} = {
  %HTMLChecker,
    ## TODO: author should SELECTED at least one OPTION in non-MULTIPLE case [HTML4].
    ## TODO: more than one OPTION with SELECTED in non-MULTIPLE case is "error" [HTML4]
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  is_root => 1, ## TODO: SHOULD NOT in application/xhtml+xml [WF2]
  check_attrs => $GetHTMLAttrsChecker->({
    accesskey => $HTMLAccesskeyAttrChecker,
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
    form => $HTMLFormAttrChecker,
    multiple => $GetHTMLBooleanAttrChecker->('multiple'),
    name => sub {}, ## NOTE: CDATA [M12N]
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
    oninput => $HTMLEventHandlerAttrChecker,
    oninvalid => $HTMLEventHandlerAttrChecker,
    size => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_WF2,
    autofocus => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    data => FEATURE_WF2,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    form => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    multiple => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onformchange => FEATURE_WF2_INFORMATIVE,
    onforminput => FEATURE_WF2_INFORMATIVE,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    oninput => FEATURE_WF2,
    oninvalid => FEATURE_WF2,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    size => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    if ($self->{flag}->{has_label} and $self->{flag}->{has_labelable}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'multiple labelable fae',
                         level => $self->{level}->{must});
    } else {
      $self->{flag}->{has_labelable} = 2;
    }

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{id_type} = 'labelable';
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and
             {
               option => 1, optgroup => 1,
             }->{$child_ln}) {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
};

$Element->{$HTML_NS}->{datalist} = {
  %HTMLPhrasingContentChecker,
    ## TODO: |option| child MUST be empty [WF2]
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
  check_attrs => $GetHTMLAttrsChecker->({
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
  }, {
    %HTMLAttrStatus,
    data => FEATURE_WF2,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{phase} = 'any'; # any | phrasing | option

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  ## NOTE: phrasing | option*
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'phrasing') {
      if ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
        #
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:phrasing',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'option') {
      if ($child_nsuri eq $HTML_NS and $child_ln eq 'option') {
        #
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'any') {
      if ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
        $element_state->{phase} = 'phrasing';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'option') {
        $element_state->{phase} = 'option';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed',
                           level => $self->{level}->{must});        
      }
    } else {
      die "check_child_element: Bad |datalist| phase: $element_state->{phase}";
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      if ($element_state->{phase} eq 'phrasing') {
        #
      } elsif ($element_state->{phase} eq 'any') {
        $element_state->{phase} = 'phrasing';
      } else {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed',
                           level => $self->{level}->{must});
      }
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'phrasing') {
      if ($element_state->{has_significant}) {
        $item->{real_parent_state}->{has_significant} = 1;
      } elsif ($item->{transparent}) {
        #
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'no significant content',
                           level => $self->{level}->{should});
      }
    } else {
      ## NOTE: Since the content model explicitly allows a |datalist| element
      ## being empty, we don't raise "no significant content" error for this
      ## element when there is no element.  (We should raise an error for
      ## |<datalist><br></datalist>|, however.)
      ## NOTE: As a side-effect, when the |datalist| element only contains
      ## non-conforming content, then the |phase| flag has not changed from
      ## |any|, no "no significant content" error is raised neither.
      $HTMLChecker{check_end}->(@_);
    }
  },
};

$Element->{$HTML_NS}->{optgroup} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    label => sub {}, ## NOTE: Text [M12N] ## TODO: required
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    label => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'option') {
      #
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
};

$Element->{$HTML_NS}->{option} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    label => sub {}, ## NOTE: Text [M12N]
    selected => $GetHTMLBooleanAttrChecker->('selected'),
    value => sub {}, ## NOTE: CDATA [M12N]
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X |  FEATURE_M12N10_REC,
    label => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    selected => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    value => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
};

$Element->{$HTML_NS}->{textarea} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => $HTMLIMTAttrChecker, ## TODO: MUST be a text-based type
    accesskey => $HTMLAccesskeyAttrChecker,
    autofocus => $GetHTMLBooleanAttrChecker->('autofocus'),
    cols => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }), ## TODO: SHOULD if wrap=hard [WF2]
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    form => $HTMLFormAttrChecker,
    ## TODO: inputmode [WF2]
    maxlength => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    name => sub {}, ## NOTE: CDATA [M12N]
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
    oninput => $HTMLEventHandlerAttrChecker,
    ## TODO: pattern [WF2] ## TODO: |title| special semantics
    readonly => $GetHTMLBooleanAttrChecker->('readonly'),
    required => $GetHTMLBooleanAttrChecker->('required'),
    rows => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    oninput => $HTMLEventHandlerAttrChecker,
    oninvalid => $HTMLEventHandlerAttrChecker,
    wrap => $GetHTMLEnumeratedAttrChecker->({soft => 1, hard => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    'accept-charset' => FEATURE_HTML2X_RFC,
    accesskey => FEATURE_M12N10_REC,
    autofocus => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    cols => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    disabled => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    form => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    inputmode => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_XHTMLBASIC11_CR,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    maxlength => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onformchange => FEATURE_WF2_INFORMATIVE,
    onforminput => FEATURE_WF2_INFORMATIVE,
    oninput => FEATURE_WF2,
    oninvalid => FEATURE_WF2,
    onselect => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    pattern => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    readonly => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    required => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    rows => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC, 
    sdaform => FEATURE_HTML20_RFC,
    sdapref => FEATURE_HTML20_RFC,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    wrap => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    if ($self->{flag}->{has_label} and $self->{flag}->{has_labelable}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'multiple labelable fae',
                         level => $self->{level}->{must});
    } else {
      $self->{flag}->{has_labelable} = 2;
    }

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{id_type} = 'labelable';
  },
};

$Element->{$HTML_NS}->{output} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: for [WF2]
    form => $HTMLFormAttrChecker,
    ## TODO: name [WF2]
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
  }, {
    %HTMLAttrStatus,
    for => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    form => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    name => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_WF2,
    onformchange => FEATURE_WF2,
    onforminput => FEATURE_WF2,
  }),
  ## NOTE: "The output  element should be used when ..." [WF2]
};

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
    style => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  ## TODO: Tests
  ## TODO: Tests for <nest/> in <isindex>
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{script} = {
  %HTMLChecker,
  status => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    charset => sub {
      my ($self, $attr) = @_;

      unless ($attr->owner_element->has_attribute_ns (undef, 'src')) {
        $self->{onerror}->(type => 'attribute not allowed',
                           node => $attr,
                           level => $self->{level}->{must});
      }

      $HTMLCharsetChecker->($attr->value, @_);
    },
    language => sub {}, ## NOTE: No syntax constraint according to HTML4.
      src => $HTMLURIAttrChecker, ## TODO: pointed resource MUST be in type of type="" (resource error)
      defer => $GetHTMLBooleanAttrChecker->('defer'),
      async => $GetHTMLBooleanAttrChecker->('async'),
      type => $HTMLIMTAttrChecker, ## TODO: MUST NOT: |charset=""| parameter
  }, {
    %HTMLAttrStatus,
    async => FEATURE_HTML5_DEFAULT,
    charset => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    defer => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    event => FEATURE_HTML4_REC_RESERVED,
    for => FEATURE_HTML4_REC_RESERVED,
    href => FEATURE_RDFA_PR,
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

      if ($type =~ m[\A(?>(?>\x0D\x0A)?[\x09\x20])*([\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+)(?>(?>\x0D\x0A)?[\x09\x20])*/(?>(?>\x0D\x0A)?[\x09\x20])*([\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+)(?>(?>\x0D\x0A)?[\x09\x20])*(?>;|\z)]) {
        $type = "$1/$2";
        $type =~ tr/A-Z/a-z/; ## NOTE: ASCII case-insensitive
        ## TODO: Though we strip prameter here, it should not be ignored for the purpose of conformance checking...
      }
      $element_state->{script_type} = $type;
    }

    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{text} = '';
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      if ($element_state->{must_be_empty}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:empty',
                           level => $self->{level}->{must});
      }
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant and
        $element_state->{must_be_empty}) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed:empty',
                         level => $self->{level}->{must});
    }
    $element_state->{text} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{must_be_empty}) {
      if ($element_state->{script_type} =~ m![+/][Xx][Mm][Ll]\z!) {
        ## NOTE: XML content should be checked by THIS instance of checker
        ## as part of normal tree validation.
        $self->{onerror}->(node => $item->{node},
                           type => 'XML script lang',
                           text => $element_state->{script_type},
                           level => $self->{level}->{uncertain});
        ## ISSUE: Should we raise some kind of error for
        ## <script type="text/xml">aaaaa</script>?
        ## NOTE: ^^^ This is why we throw an "uncertain" error.
      } else {
        $self->{onsubdoc}->({s => $element_state->{text},
                             container_node => $item->{node},
                             media_type => $element_state->{script_type},
                             is_char_string => 1});
      }
      
      $HTMLChecker{check_end}->(@_);
    }
  },
  ## TODO: There MUST be |type| unless the script type is JavaScript. (resource error)
  ## NOTE: "When used to include script data, the script data must be embedded
  ## inline, the format of the data must be given using the type attribute,
  ## and the src attribute must not be specified." - not testable.
      ## TODO: It would be possible to err <script type=text/plain src=...>
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
      $self->{onerror}->(node => $item->{node}, type => 'in XML:noscript',
                         level => $self->{level}->{must});
    }

    unless ($self->{flag}->{in_head}) {
      $self->_add_minus_elements ($element_state,
                                  {$HTML_NS => {noscript => 1}});
    }

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{flag}->{in_head}) {
      if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:minus',
                           level => $self->{level}->{must});
      } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
        #
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'link') {
        #
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'style') {
        if ($child_el->has_attribute_ns (undef, 'scoped')) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:head noscript',
                             level => $self->{level}->{must});
        }
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'meta') {
        my $http_equiv_attr
            = $child_el->get_attribute_node_ns (undef, 'http-equiv');
        if ($http_equiv_attr) {
          ## TODO: case
          if (lc $http_equiv_attr->value eq 'content-type') {
            $self->{onerror}->(node => $child_el,
                               type => 'element not allowed:head noscript',
                               level => $self->{level}->{must});
          } else {
            #
          }
        } else {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:head noscript',
                             level => $self->{level}->{must});
        }
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:head noscript',
                           level => $self->{level}->{must});
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
                           type => 'character not allowed',
                           level => $self->{level}->{must});
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
  status => FEATURE_HTML5_LC_DROPPED,
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    src => FEATURE_HTML5_LC_DROPPED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{eventsource} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DEFAULT,
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    src => FEATURE_HTML5_DEFAULT,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{details} = {
  %{$Element->{$HTML_NS}->{fieldset}},
  status => FEATURE_HTML5_WD,
  check_attrs => $GetHTMLAttrsChecker->({
    open => $GetHTMLBooleanAttrChecker->('open'),
  }, {
    %HTMLAttrStatus,
    open => FEATURE_HTML5_WD,
  }),
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
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  ## NOTE: Flow -(text* (table|select|datalist) Flow*) | table | select |
  ## datalist | Empty
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($element_state->{phase} eq 'flow') {
      if ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        if (not $element_state->{has_element} and 
            $child_nsuri eq $HTML_NS and
            {
              table => 1, select => 1, datalist => 1,
            }->{$child_ln}) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed',
                             level => $self->{level}->{must});
        } else {
          #
        }
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed', ## TODO: :flow
                           level => $self->{level}->{must});
      }
      $element_state->{has_element} = 1;
    } elsif ($element_state->{phase} eq 'any') {
      if ($child_nsuri eq $HTML_NS and
          {table => 1, select => 1, datalist => 1}->{$child_ln}) {
        $element_state->{phase} = 'none';
      } elsif ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        $element_state->{has_element} = 1;
        $element_state->{phase} = 'flow';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed',
                           level => $self->{level}->{must});        
      }
    } elsif ($element_state->{phase} eq 'none') {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed',
                         level => $self->{level}->{must});
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
                           type => 'character not allowed',
                           level => $self->{level}->{must});
      }
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    if ($element_state->{phase} eq 'flow') {
      if ($element_state->{has_significant}) {
        $item->{real_parent_state}->{has_significant} = 1;
      } elsif ($item->{transparent}) {
        #
      } else {
        $self->{onerror}->(node => $item->{node},
                           type => 'no significant content',
                           level => $self->{level}->{should});
      }
    } else {
      ## NOTE: Since the content model explicitly allows a |datagird| element
      ## being empty, we don't raise "no significant content" error for this
      ## element when there is no element.  (We should raise an error for
      ## |<datagrid><br></datagrid>|, however.)
      ## NOTE: As a side-effect, when the |datagrid| element only contains
      ## non-conforming content, then the |phase| flag has not changed from
      ## |any|, no "no significant content" error is raised neither.
      ## NOTE: Another side-effect of the current implementation:
      ## |<daragrid><datagrid/></datagrid>| has no "no significant content"
      ## error at all.
      $HTMLChecker{check_end}->(@_);
    }
  },
};

$Element->{$HTML_NS}->{command} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_WD,
  check_attrs => $GetHTMLAttrsChecker->({
    checked => $GetHTMLBooleanAttrChecker->('checked'),
    default => $GetHTMLBooleanAttrChecker->('default'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    icon => $HTMLURIAttrChecker,
    label => sub { }, ## NOTE: No conformance creteria
    radiogroup => sub { }, ## NOTE: No conformance creteria
    type => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ({command => 1, checkbox => 1, radio => 1}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'invalid attribute value',
                           level => $self->{level}->{must});
      }
    },
  }, {
    %HTMLAttrStatus,
    checked => FEATURE_HTML5_WD,
    default => FEATURE_HTML5_WD,
    disabled => FEATURE_HTML5_WD,
    icon => FEATURE_HTML5_WD,
    label => FEATURE_HTML5_WD,
    radiogroup => FEATURE_HTML5_WD,
    type => FEATURE_HTML5_WD,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{icon}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{bb} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT,
  check_attrs => $GetHTMLAttrsChecker->({
    type => $GetHTMLEnumeratedAttrChecker->({makeapp => 1}),
  }, {
    %HTMLAttrStatus,
    type => FEATURE_HTML5_DEFAULT,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, $HTMLInteractiveContent);

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLTransparentChecker{check_end}->(@_);
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
    ## ISSUE: <menu id=""><p contextmenu=""> match?  (In the current
    ## implementation, it does not match.)
    label => sub { }, ## NOTE: No conformance creteria
    type => $GetHTMLEnumeratedAttrChecker->({context => 1, toolbar => 1}),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    autosubmit => FEATURE_HTML5_DROPPED,
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

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
    $element_state->{id_type} = 'menu';
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'li') {
      if ($element_state->{phase} eq 'li') {
        #
      } elsif ($element_state->{phase} eq 'li or phrasing') {
        $element_state->{phase} = 'li';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($HTMLPhrasingContent->{$child_nsuri}->{$child_ln}) {
      if ($element_state->{phase} eq 'phrasing') {
        #
      } elsif ($element_state->{phase} eq 'li or phrasing') {
        $element_state->{phase} = 'phrasing';
      } else {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
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
                           type => 'character not allowed',
                           level => $self->{level}->{must});
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
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'rule') {
      #
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:datatemplate',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  },
  is_xml_root => 1,
};

$Element->{$HTML_NS}->{rule} = {
  %HTMLChecker,
  status => FEATURE_HTML5_AT_RISK,
  check_attrs => $GetHTMLAttrsChecker->({
    condition => $HTMLSelectorsAttrChecker,
    mode => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->(),
  }, {
    %HTMLAttrStatus,
    condition => FEATURE_HTML5_AT_RISK,
    mode => FEATURE_HTML5_AT_RISK,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $self->_add_plus_elements ($element_state, {$HTML_NS => {nest => 1}});
    $element_state->{in_rule_original} = $self->{flag}->{in_rule};
    $self->{flag}->{in_rule} = 1;

    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_child_element => sub { },
  check_child_text => sub { },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    $self->_remove_plus_elements ($element_state);
    delete $self->{flag}->{in_rule} unless $element_state->{in_rule_original};

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
      if ($value !~ /\A[^\x09\x0A\x0C\x0D\x20]+\z/) {
        $self->{onerror}->(node => $attr, type => 'mode:syntax error',
                           level => $self->{level}->{must});
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
  status => FEATURE_HTML5_DEFAULT | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_M12N10_REC_DEPRECATED,
    datafld => FEATURE_HTML4_REC_RESERVED,
    dataformatas => FEATURE_HTML4_REC_RESERVED,
    datasrc => FEATURE_HTML4_REC_RESERVED,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
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
  status => FEATURE_HTML5_DROPPED | FEATURE_M12N10_REC_DEPRECATED,
  check_attrs => $GetHTMLAttrsChecker->({
    ## TODO: HTML4 |size|, |color|, |face|
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    color => FEATURE_M12N10_REC_DEPRECATED,
    dir => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    face => FEATURE_M12N10_REC_DEPRECATED,
    id => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    size => FEATURE_M12N10_REC_DEPRECATED,
    style => FEATURE_HTML5_DEFAULT | FEATURE_XHTML10_REC,
    title => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  ## NOTE: When the |font| element was defined in the HTML5 specification,
  ## it is allowed only in a document with the WYSIWYG signature.  The
  ## checker does not check whether there is the signature, since the
  ## signature is dropped, too, and has never been implemented.  (In addition,
  ## for any |font| element an "element not defined" error is raised anyway,
  ## such that we don't have to raise an additional error.)
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

## TODO: CR: rbc rtc @rbspan (M12NXHTML2Common)

## TODO: xmp, listing, plaintext FEATURE_HTML32_REC_OBSOLETE
## TODO: ^^^ lang, dir, id, class [HTML 2.x] sdaform [HTML 2.0]
## xmp, listing sdapref[HTML2,0]

=pod

WF2: Documents MUST comply to [CHARMOD].
                     WF2: Vencor extensions MUST NOT be used.

HTML 2.0 nextid @n

RFC 2659: CERTS CRYPTOPTS 

ISO-HTML: pre-html, divN

XHTML2: blockcode (Common), h (Common), separator (Common), l (Common),
di (Common), nl (Common), handler (Common, type), standby (Common),
summary (Common)

Access & XHTML2: access (LC)

XML Events & XForms (for XHTML2 support; very, very low priority)

=cut

## NOTE: Where RFC 2659 allows additional attributes is unclear.
## We added them only to |a|.  |link| and |form| might also allow them
## in theory.

$Whatpm::ContentChecker::Namespace->{$HTML_NS}->{loaded} = 1;

1;
