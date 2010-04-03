package Whatpm::ContentChecker::HTML;
use strict;
use warnings;
our $VERSION = '3.0';

package Whatpm::ContentChecker;
require Whatpm::ContentChecker;

use Char::Class::XML qw/InXML_NCNameStartChar10 InXMLNCNameChar10/;

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;

## --- Feature Status ---

sub FEATURE_HTML5_REC () {
  ## NOTE: Part of HTML5, the implemented status.
  Whatpm::ContentChecker::FEATURE_STATUS_REC |
  Whatpm::ContentChecker::FEATURE_ALLOWED

      ## Strictly speaking, HTML5's "implemented and widely deployed"
      ## status does not necessarily satisfy the condition for
      ## FEATURE_STATUS_REC, since there is no test cases for most of
      ## features marked as "implemented" in HTML5.  Nevertheless, we
      ## special-case HTML5's this status as if that had passed the CR
      ## phase, considering HTML's history.
}

sub FEATURE_HTML5_CR () {
  ## NOTE: Part of HTML5, the awaiting implementation feedback status.
  Whatpm::ContentChecker::FEATURE_STATUS_CR |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_LC () {
  ## NOTE: Part of HTML5, the last call of comments status.
  Whatpm::ContentChecker::FEATURE_STATUS_LC |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_WD () {
  ## NOTE: Part of HTML5, the working draft status.
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_FD () {
  ## NOTE: Part of HTML5, the first draft status.
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_DEFAULT () {
  ## NOTE: Part of HTML5, but not annotated.
  Whatpm::ContentChecker::FEATURE_STATUS_WD |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}
sub FEATURE_HTML5_DROPPED () {
  ## NOTE: Was part of HTML5, in a status before the last call of
  ## comments, but then dropped.
  Whatpm::ContentChecker::FEATURE_STATUS_WD
}
sub FEATURE_HTML5_LC_DROPPED () {
  ## NOTE: Was part of HTML5, in the last call of comments status, but
  ## then dropped.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

## NOTE: Features that are listed in the "non-conforming features"
## section.
use constant FEATURE_HTML5_OBSOLETE => 0;

## -- Obsolete specifications --

## The manakai specification for conformance checking of obsolete HTML
## vocabulary,
## <http://suika.fam.cx/www/markup/html/exts/manakai-obsvocab>.  The
## document defines conformance checking requirements for numbers of
## obsolete HTML elements and attributes historically specified or
## implemented but no longer considered part of the HTML language
## proper.
sub FEATURE_OBSVOCAB () { "0 but true" }

## Following historical specifications are obsolete; though some of
## them are still "live" specifications according to corresponding
## standardization bodies, they are not "applicable specification"s
## [WA1] and therefore cannot form parts of the HTML langauge anymore.

sub FEATURE_WF2X () {
  ## NOTE: Defined in WF2 (whether deprecated or not) and then
  ## incorporated into the HTML5 spec.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}
sub FEATURE_WF2 () {
  ## NOTE: Features introduced or modified in WF2, which were not
  ## merged into HTML5.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

sub FEATURE_RDFA_REC () {
  Whatpm::ContentChecker::FEATURE_STATUS_REC
}
sub FEATURE_RDFA_LC_DROPPED () {
  ## NOTE: The feature that was defined in a RDFa last call working
  ## draft, but then dropped.
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

## NOTE: XHTML Role LCWD has almost no information on how the |role|
## attribute can be used- the only requirements for that matter is:
## "the attribute MUST be referenced using its namespace-qualified form" (and
## this is a host language conformance!).
sub FEATURE_ROLE_LC () {
  Whatpm::ContentChecker::FEATURE_STATUS_LC
}

sub FEATURE_XHTML2_ED () {
  ## NOTE: XHTML 2.0 Editor's Draft, in which the namespace URI is
  ## defined as "http://www.w3.org/1999/xhtml".
  Whatpm::ContentChecker::FEATURE_STATUS_WD
}

sub FEATURE_XHTMLBASIC11_CR () {
  ## NOTE: XHTML Basic 1.1 Recommendation, new features (not in XHTML
  ## M12N).
  Whatpm::ContentChecker::FEATURE_STATUS_REC
}

sub FEATURE_RUBY_REC () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR
}

sub FEATURE_M12N11_LC () {
  ## NOTE: XHTML M12N 1.1 Recommendation, new features (not in 1.0).
  Whatpm::ContentChecker::FEATURE_STATUS_REC;
}

## NOTE: M12N10 status is based on its abstract module definition.
## It contains a number of problems.  (However, again, it's a REC!)
sub FEATURE_M12N10_REC () {
  ## NOTE: Oh, XHTML m12n 1.0 passed the CR phase!  W3C Process sucks!
  Whatpm::ContentChecker::FEATURE_STATUS_REC
}
sub FEATURE_M12N10_REC_DEPRECATED () {
  Whatpm::ContentChecker::FEATURE_STATUS_REC |
  Whatpm::ContentChecker::FEATURE_DEPRECATED_INFO
}

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

## We don't support RFC 2659 (Experimental RFC) - it's too vague to
## implement, and it has never affected the real world at all.

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

## --- Content Model ---

## December 2007 HTML5 Classification

my $HTMLMetadataContent = {
  $HTML_NS => {
    title => 1, base => 1, link => 1, style => 1, script => 1, noscript => 1,
    command => 1,
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
    h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1, hgroup => 1,
    header => 1,
    footer => 1, address => 1, p => 1, hr => 1, dialog => 1, pre => 1,
    ol => 1, ul => 1, dl => 1, menu => 1, figure => 1, table => 1,
    form => 1, fieldset => 1,
    details => 1,
    div => 1,
    ## NOTE: |style| is only allowed if |scoped| attribute is specified.
    ## Additionally, it must be before any other element or
    ## non-inter-element-whitespace text node.
    style => 1,  

    ## These phrasing content are also categorized as flow content.
    br => 1, q => 1, cite => 1, em => 1, strong => 1, small => 1, mark => 1,
    dfn => 1, abbr => 1, time => 1, progress => 1, meter => 1, code => 1,
    var => 1, samp => 1, kbd => 1, sub => 1, sup => 1, span => 1, i => 1,
    b => 1, bdo => 1, ruby => 1,
    script => 1, noscript => 1,
    command => 1,
    input => 1, button => 1, label => 1, select => 1, datalist => 1,
    textarea => 1, keygen => 1, output => 1,
    ## NOTE: |area| is allowed only as a descendant of |map|.
    area => 1,

    ## Flow/phrasing content whose content model is transparent.
    a => 1, ins => 1, del => 1, font => 1, map => 1,

    ## These embeded content are also categorized as flow content.
    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,
  },

  ## These embedded content are also categorized as flow content.
  q<http://www.w3.org/1998/Math/MathML> => {math => 1},
  q<http://www.w3.org/2000/svg> => {svg => 1},

  ## And, non-inter-element-whitespace text nodes.
}; # $HTMLFlowContent

my $HTMLSectioningContent = {
  $HTML_NS => {
    section => 1, nav => 1, article => 1, aside => 1,
  },
}; # $HTMLSectioningContent

my $HTMLSectioningRoot = {
  $HTML_NS => {
    blockquote => 1, figure => 1, td => 1,
  },
};

my $HTMLHeadingContent = {
  $HTML_NS => {
    h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1, hgroup => 1,
  },
};

my $HTMLPhrasingContent = {
  ## NOTE: All phrasing content is also flow content.
  $HTML_NS => {
    br => 1, q => 1, cite => 1, em => 1, strong => 1, small => 1, mark => 1,
    dfn => 1, abbr => 1, time => 1, progress => 1, meter => 1, code => 1,
    var => 1, samp => 1, kbd => 1, sub => 1, sup => 1, span => 1, i => 1,
    b => 1, bdo => 1, ruby => 1,
    script => 1, noscript => 1,
    command => 1,
    input => 1, button => 1, label => 1, select => 1, datalist => 1,
    textarea => 1, keygen => 1, output => 1,
    ## NOTE: |area| is allowed only as a descendant of |map|.
    area => 1,

    ## NOTE: Transparent.    
    a => 1, ins => 1, del => 1, font => 1, map => 1,

    ## These embedded content is also categorized as phrasing content.
    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,
  },

  ## These embedded content is also categorized as phrasing content.
  q<http://www.w3.org/1998/Math/MathML> => {math => 1},
  q<http://www.w3.org/2000/svg> => {svg => 1},

  ## And, non-inter-element-whitespace text nodes.
}; # $HTMLPhrasingContent

## $HTMLEmbeddedContent: See Whatpm::ContentChecker.

my $HTMLInteractiveContent = {
  $HTML_NS => {
    a => 1,
    label => 1, button => 1, select => 1, textarea => 1,
    keygen => 1, details => 1,
    iframe => 1, embed => 1,

    ## NOTE: When the |usemap| attribute is specified.
    img => 1, object => 1,

    ## NOTE: When "type=hidden" attribute is not specified.
    input => 1,

    ## NOTE: When "controls" attribute is specified.
    video => 1, audio => 1,

    ## NOTE: When "type=toolbar" attribute is specified.
    menu => 1,
  },
}; # $HTMLInteractiveContent

## NOTE: Labelable form-associated element.
my $LabelableFAE = {
  $HTML_NS => {
    input => 1, button => 1, select => 1, textarea => 1, keygen => 1,
  },
};

## Check whether the labelable form-associated element is allowed to
## place there or not and mark the element ID, if any, might be used
## in the |for| attribute of a |label| element.
my $FAECheckStart = sub {
  my ($self, $item, $element_state) = @_;

  $element_state->{id_type} = 'labelable';
}; # $FAECheckStart
my $FAECheckAttrs2 = sub {
  my ($self, $item, $element_state) = @_;

  ## This must be done in "check_attrs2" phase since it requires the
  ## |id| attribute of the element, if any, reflected to the
  ## |$self->{id}| hash.

  CHK: {
    if ($self->{flag}->{has_label} and $self->{flag}->{has_labelable}) {
      my $for = $self->{flag}->{label_for};
      if (defined $for) {
        my $id_attrs = $self->{id}->{$for};
        if ($id_attrs and $id_attrs->[0]) {
          my $el = $id_attrs->[0]->owner_element;
          if ($el and $el eq $item->{node}) {
            ## Even if there is an ancestor |label| element with its
            ## |for| attribute specified, the attribute value
            ## identifies THIS element, then there is no problem.
            last CHK;
          }
        }
      }
      
      $self->{onerror}->(node => $item->{node},
                         type => 'multiple labelable fae',
                         level => $self->{level}->{must});
    } else {
      $self->{flag}->{has_labelable} = 2;
    }
  } # CHK
}; # $FAECheckAttrs2

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
    my $value = $attr->value;
    $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
    if ($states->{$value} and $states->{$value} > 0) {
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
    my $value = $attr->value;
    $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
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
    $word =~ tr/A-Z/a-z/ unless $word =~ /:/; ## ASCII case-insensitive.

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

    if ($word =~ /:/) {
      ## XXX MUST be an absolute URL (HTML5 revision 4533)
      Whatpm::URIChecker->check_iri_reference ($word, sub {
        $self->{onerror}->(value => $word, @_, node => $attr);
      }, $self->{level});
      
      ## TODO: absolute
      push @{$self->{return}->{uri}->{$word} ||= []},
          {node => $attr, type => {'linktype' => 1}};
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

# XXX URL
## URI (or IRI)
my $HTMLURIAttrChecker = sub {
  my ($self, $attr, $item, $element_state) = @_;
  ## ISSUE: Relative references are allowed? (RFC 3987 "IRI" is an absolute reference with optional fragment identifier.)
  my $value = $attr->value;
  Whatpm::URIChecker->check_iri_reference ($value, sub {
    $self->{onerror}->(@_, node => $attr);
  }, $self->{level});
  $self->{has_uri_attr} = 1; ## TODO: <html manifest>

  my $attr_name = $attr->name;
  $element_state->{uri_info}->{$attr_name}->{node} = $attr;
  ## TODO: absolute
  push @{$self->{return}->{uri}->{$value} ||= []},
      $element_state->{uri_info}->{$attr_name};
}; # $HTMLURIAttrChecker

my $NonEmptyURLChecker = sub {
  my ($self, $attr) = @_;
  if ($attr->value eq '') {
    $self->{onerror}->(type => 'url:empty', # XXX documentation
                       node => $attr,
                       level => $self->{level}->{must});
  } else {
    $HTMLURIAttrChecker->(@_);
  }
}; # $NonEmptyURLChecker

## "A set of space-separated tokens, each of which MUST be a valid
## URL".
my $HTMLSpaceURIsAttrChecker = sub {
  my ($self, $attr) = @_;

  my %word;
  for my $word (grep {length $_}
                split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
    $word =~ tr/A-Z/a-z/; ## ASCII case-insensitive.

    unless ($word{$word}) {
      $word{$word} = 1;
    } else {
      $self->{onerror}->(node => $attr, type => 'duplicate token',
                         value => $word,
                         level => $self->{level}->{must});
    }
  }

  my $type = {ping => 'action',
              profile => 'namespace',
              archive => 'resource'}->{$attr->name};

  for my $value (keys %word) {
    Whatpm::URIChecker->check_iri_reference ($value, sub {
      $self->{onerror}->(value => $value, @_, node => $attr);
    }, $self->{level});

    ## TODO: absolute
    push @{$self->{return}->{uri}->{$value} ||= []},
        {node => $attr, type => {$type => 1}};
  }

  $self->{has_uri_attr} = 1;
}; # $HTMLSpaceURIsAttrChecker

my $ValidEmailAddress;
{
  my $atext_dot = qr[[A-Za-z0-9!#\$%&'*+/=?^_`{|}~.-]];
  my $ldh_str = qr[[A-Za-z0-9-]+];
  $ValidEmailAddress = qr/$atext_dot+\@$ldh_str(?>\.$ldh_str)+/o;
}

## Valid global date and time.
my $GetDateTimeAttrChecker = sub ($) {
  my $type = shift;
  return sub {
    my ($self, $attr, $item, $element_state) = @_;
    
    my $range_error;
    
    require Message::Date;
    my $dp = Message::Date->new;
    $dp->{level} = $self->{level};
    $dp->{onerror} = sub {
      my %opt = @_;
      unless ($opt{type} eq 'date value not supported') {
        $self->{onerror}->(%opt, node => $attr);
        $range_error = '';
      }
    };
    
    my $method = 'parse_' . $type;
    my $d = $dp->$method ($attr->value);
    $element_state->{date_value}->{$attr->name} = $d || $range_error;
  };
}; # $GetDateTimeAttrChecker

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
      if ($range_check->($value + 0)) {
        return 1;
      } else {
        $self->{onerror}->(node => $attr, type => 'nninteger:out of range',
                           level => $self->{level}->{must});
        return 0;
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'nninteger:syntax error',
                         level => $self->{level}->{must});
      return 0;
    }
  };
}; # $GetHTMLNonNegativeIntegerAttrChecker

## "Valid floating point number".
my $GetHTMLFloatingPointNumberAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr, $item, $element_state) = @_;
    my $value = $attr->value;
    if ($value =~ /
        \A
        (-?) # $1
        ([0-9]+) # $2
        (?>(\.[0-9]+))? # $3
        (?>[Ee] ([+-]?[0-9]+) )? # $4
        \z
    /x) {
      my $num = (defined $3 ? $2 . $3 : $2) + 0;
      $num = -$num if $1;
      $num *= 10 ** ($4 + 0) if $4; # $4 can be "-0", but no problem.
      if ($range_check->($num)) {
        $element_state->{number_value}->{$attr->name} = $num;
      } else {
        $self->{onerror}->(node => $attr, type => 'float:out of range',
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'float:syntax error',
                         level => $self->{level}->{must});
    }
  };
}; # $GetHTMLFloatingPointNumberAttrChecker

my $PositiveFloatingPointNumberAttrChecker
  = $GetHTMLFloatingPointNumberAttrChecker->(sub { $_[0] > 0 });

my $StepAttrChecker = sub {
  ## NOTE: A valid floating point number (> 0), or ASCII
  ## case-insensitive "any".
  
  my ($self, $attr) = @_;
  my $value = $attr->value;
  if ($value =~ /\A[Aa][Nn][Yy]\z/) {
    #
  } else {
    $PositiveFloatingPointNumberAttrChecker->(@_);
  }
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

## HTML4 %MultiLength;
my $MultiLengthChecker = sub {
  my ($self, $attr) = @_;
  unless ($attr->value =~ /\A(?>[0-9]+[%*]?|\*)\z/) {
    $self->{onerror}->(node => $attr,
                       type => 'multilength:syntax error', # XXXdocumentation
                       level => $self->{level}->{html4_fact});
  }
}; # $MultiLengthChecker

## HTML4 multilength-list (set of comma-separated tokens [HTML5] where
## each token is %MultiLength; [HTML4])
my $MultiLengthListChecker = sub {
  my ($self, $attr) = @_;
  for my $ml (split /,/, $attr->value, -1) {
    $ml =~ s/\A[\x09\x0A\x0C\x0D\x20]+//;
    $ml =~ s/[\x09\x0A\x0C\x0D\x20]+\z//;
    
    unless ($ml =~ /\A(?>[0-9]+[%*]?|\*)\z/) {
      $self->{onerror}->(node => $attr,
                         value => $ml,
                         type => 'multilength:syntax error', # XXXdocumentation
                         level => $self->{level}->{html4_fact});
    }
  }
}; # $MultiLengthListChecker

our $MIMETypeChecker; ## See |Whatpm::ContentChecker|.

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

my $ListAttrChecker = sub {
  my ($self, $attr) = @_;
  
  ## NOTE: MUST be the ID of a |datalist| element.
  
  push @{$self->{idref}}, ['datalist', $attr->value, $attr];

  ## TODO: Warn violation to control-dependent restrictions.  For
  ## example, |<input type=url maxlength=10 list=a> <datalist
  ## id=a><option value=nonurlandtoolong></datalist>| should be
  ## warned.
}; # $ListAttrChecker

my $PatternAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onsubdoc}->({s => $attr->value,
                       container_node => $attr,
                       media_type => 'text/x-regexp-js',
                       is_char_string => 1});

  ## ISSUE: "value must match the Pattern production of ECMA 262's
  ## grammar" - no additional constraints (e.g. {n,m} then n>=m).

  ## TODO: Warn if @value does not match @pattern.
}; # $PatternAttrChecker

my $AcceptAttrChecker = sub {
  my ($self, $attr) = @_;
  
  my $value = $attr->value;
  $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive

  ## A set of comma-separated tokens.
  my @value = length $value ? split /,/, $value, -1 : ();

  my %has_value;
  for my $v (@value) {
    $v =~ s/^[\x09\x0A\x0C\x0D\x20]+//;
    $v =~ s/[\x09\x0A\x0C\x0D\x20]+\z//;

    if ($has_value{$v}) {
      $self->{onerror}->(node => $attr,
                         type => 'duplicate token',
                         value => $v,
                         level => $self->{level}->{must});
      next;
    } 
    $has_value{$v} = 1;
    
    if ($v eq 'audio/*' or $v eq 'video/*' or $v eq 'image/*') {
      #
    } else {
      require Message::MIME::Type;
      my $onerror = sub {
        $self->{onerror}->(value => $v, @_, node => $attr);
      };
      
      ## Syntax-level validation
      my $type = Message::MIME::Type->parse_web_mime_type
          ($v, $onerror, $self->{level});

      if ($type) {
        if (@{$type->attrs}) {
          $self->{onerror}->(node => $attr,
                             type => 'IMT:no param allowed',
                             level => $self->{level}->{must});
        }
        
        ## Vocabulary-level validation
        $type->validate ($onerror, no_required_param => 1);
      }
    }
  }
}; # $AcceptAttrChecker

my $FormControlNameAttrChecker = sub {
  my ($self, $attr) = @_;
  
  unless (length $attr->value) {
    $self->{onerror}->(node => $attr,
                       type => 'empty control name', ## TODOC: type
                       level => $self->{level}->{must});
  }
  
  ## NOTE: No uniqueness constraint.
}; # $FormControlNameAttrChecker

my $AutofocusAttrChecker = sub {
  my ($self, $attr) = @_;
  
  $GetHTMLBooleanAttrChecker->('autofocus')->(@_);
  
  if ($self->{has_autofocus}) {
    $self->{onerror}->(node => $attr,
                       type => 'duplicate autofocus', ## TODOC: type
                       level => $self->{level}->{must});
  }
  $self->{has_autofocus} = 1;
}; # $AutofocusAttrChekcer

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
    $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
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
  
  ## XXX
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

my $FontSizeChecker = sub {
  my ($self, $attr) = @_;
  unless ($attr->value =~ /\A[+-]?[1-7]\z/) { ## HTML4 definition is vague.
    $self->{onerror}->(node => $attr,
                       type => 'fontsize:syntax error',
                       level => $self->{level}->{html4_fact});
  }
}; # $FontSizeChecker

my $HTMLRepeatIndexAttrChecker = sub {
  my ($self, $attr) = @_;

  # XXX
  if (defined $attr->namespace_uri) {
    my $oe = $attr->owner_element;
    my $oe_nsuri = $oe->namespace_uri;
    if (defined $oe_nsuri and $oe_nsuri eq $HTML_NS) {
      $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                         level => $self->{level}->{must});
    }
  }

  my $oe = $attr->owner_element;
  my $oens = $oe->namespace_uri;
  my $repeat = (defined $oens and $oens eq $HTML_NS)
      ? $oe->get_attribute_ns (undef, 'repeat')
      : $oe->get_attribute_ns ($HTML_NS, 'repeat');
  if (defined $repeat and $repeat eq 'template') {
    #
  } else {
    $self->{onerror}->(node => $attr,
                       type => 'attribute not allowed:repeat-*', # XXXdocumentation
                       level => $self->{level}->{must});
  }
  
  $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 })->(@_);
}; # $HTMLRepeatIndexAttrChecker

my $PlaceholderAttrChecker = sub {
  my ($self, $attr) = @_;
  if ($attr->value =~ /[\x0D\x0A]/) {
    $self->{onerror}->(node => $attr,
                       type => 'newline in value', ## TODOC: type
                       level => $self->{level}->{must});
  }
}; # $PlaceholderAttrChecker

my $HTMLAttrChecker = {
  about => $HTMLURIAttrChecker,
  accesskey => sub {
    my ($self, $attr) = @_;
    
    ## "Ordered set of unique space-separated tokens"
    
    my %keys;
    my @keys = grep {length} split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value;
    
    for my $key (@keys) {
      unless ($keys{$key}) {
        $keys{$key} = 1;
        if (length $key != 1) {
          $self->{onerror}->(node => $attr, type => 'char:syntax error',
                             value => $key,
                             level => $self->{level}->{must});
        }
      } else {
        $self->{onerror}->(node => $attr, type => 'duplicate token',
                           value => $key,
                           level => $self->{level}->{must});
      }
    }
  }, # accesskey
  atomicselection => $GetHTMLEnumeratedAttrChecker->({true => 1, false => 1}),
  datasrc => $NonEmptyURLChecker,
  datafld => sub { },
  dataformatas => $GetHTMLEnumeratedAttrChecker->({
    text => 1, html => 1, 'localized-text' => 1,
    ## See <http://suika.fam.cx/~wakaba/wiki/sw/n/dataformatas>.
  }),

  ## TODO: aria-* ## TODO: svg:*/@aria-* [HTML5ROLE] -> [STATES]
  id => sub {
    my ($self, $attr, $item, $element_state) = @_;
    my $value = $attr->value;
    if (length $value > 0) {
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'duplicate ID',
                           level => $self->{level}->{must});
        push @{$self->{id}->{$value}}, $attr;
      } elsif ($self->{name}->{$value} and
               $self->{name}->{$value}->[-1]->owner_element ne $item->{node}) {
       $self->{onerror}->(node => $attr,
                           type => 'id name confliction', # XXXdocumentation
                           value => $value,
                           level => $self->{level}->{must});
        $self->{id}->{$value} = [$attr];
        $self->{id_type}->{$value} = $element_state->{id_type} || '';
      } else {
        $self->{id}->{$value} = [$attr];
        $self->{id_type}->{$value} = $element_state->{id_type} || '';
      }
      push @{$element_state->{element_ids} ||= []}, $value;

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
    
    ## NOTE: "set of unique space-separated tokens".

    my %word;
    for my $word (grep {length $_}
                  split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
      unless ($word{$word}) {
        $word{$word} = 1;
        push @{$self->{return}->{class}->{$word}||=[]}, $attr;
      }
    }
  },
  content => sub { },
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
  datatype => sub { },
  disabled => $GetHTMLBooleanAttrChecker->('disabled'),
  hidden => $GetHTMLBooleanAttrChecker->('hidden'),
  hidefocus => $GetHTMLBooleanAttrChecker->('hidefocus'),
  irrelevant => $GetHTMLBooleanAttrChecker->('irrelevant'),
  language => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
    unless ($value eq 'javascript') {
      $self->{onerror}->(type => 'script language', # XXXdocumentation
                         node => $attr,
                         level => $self->{level}->{must});
    }
  }, # language
  property => sub { },
  rel => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->(),
  repeat => sub {
    my ($self, $attr) = @_;

    if (defined $attr->namespace_uri) {
      my $oe = $attr->owner_element;
      my $oe_nsuri = $oe->namespace_uri;
      if (defined $oe_nsuri and $oe_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    }

    my $value = $attr->value;
    if ($value eq 'template') {
      #
    } elsif ($value =~ /\A-?[0-9]+\z/) { ## A valid integer.
      #
    } else {
      $self->{onerror}->(node => $attr, type => 'repeat:syntax error',
                         level => $self->{level}->{must});
    }
  },
  'repeat-min' => $HTMLRepeatIndexAttrChecker,
  'repeat-max' => $HTMLRepeatIndexAttrChecker,
  'repeat-start' => $HTMLRepeatIndexAttrChecker,
  'repeat-template' => sub {
    my ($self, $attr) = @_;

    if (defined $attr->namespace_uri) {
      my $oe = $attr->owner_element;
      my $oe_nsuri = $oe->namespace_uri;
      if (defined $oe_nsuri and $oe_nsuri eq $HTML_NS) {
        $self->{onerror}->(node => $attr, type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    }
    
    push @{$self->{idref}}, ['repeat-template', $attr->value, $attr];
  },
  resource => $HTMLURIAttrChecker,
  rev => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->(),
  ## TODO: role [HTML5ROLE] ## TODO: global @role [XHTML1ROLE]
  spellcheck => $GetHTMLEnumeratedAttrChecker->({
    true => 1, false => 1, '' => 1,
  }),
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
  typeof => sub { },
  unselectable => $GetHTMLEnumeratedAttrChecker->({on => 1, off => 1}),
  ## The |xml:lang| attribute in the null namespace, which is
  ## different from the |lang| attribute in the XML's namespace.
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

  ## The |xmlns| attribute in the null namespace, which is different
  ## from the |xmlns| attribute in the XMLNS namespace.
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

  ## The |xml:space| attribute in no namespace, which is different
  ## from the |space| attribute in the XML namespace.
  'xml:space' => $GetHTMLEnumeratedAttrChecker->({default => 1, preserve => 1}),
}; # $HTMLAttrChecker

my %HTMLAttrStatus = (
  about => FEATURE_OBSVOCAB,
  accesskey => FEATURE_HTML5_FD,
  atomicselection => FEATURE_OBSVOCAB,
  class => FEATURE_HTML5_LC,
  content => FEATURE_OBSVOCAB,
  contenteditable => FEATURE_HTML5_REC,
  contextmenu => FEATURE_HTML5_WD,
  datafld => FEATURE_HTML5_OBSOLETE | FEATURE_OBSVOCAB,
  dataformatas => FEATURE_HTML5_OBSOLETE | FEATURE_OBSVOCAB,
  datasrc => FEATURE_HTML5_OBSOLETE | FEATURE_OBSVOCAB,
  datatype => FEATURE_OBSVOCAB,
  dir => FEATURE_HTML5_REC,
  disabled => FEATURE_OBSVOCAB,
  draggable => FEATURE_HTML5_LC,
  hidden => FEATURE_HTML5_LC,
  hidefocus => FEATURE_OBSVOCAB,
  id => FEATURE_HTML5_REC,
  irrelevant => FEATURE_HTML5_DROPPED,
  lang => FEATURE_HTML5_REC,
  language => FEATURE_OBSVOCAB,
  property => FEATURE_OBSVOCAB,
  rel => FEATURE_OBSVOCAB,
  repeat => FEATURE_OBSVOCAB,
  'repeat-max' => FEATURE_OBSVOCAB,
  'repeat-min' => FEATURE_OBSVOCAB,
  'repeat-start' => FEATURE_OBSVOCAB,
  'repeat-template' => FEATURE_OBSVOCAB,
  resource => FEATURE_OBSVOCAB,
  rev => FEATURE_OBSVOCAB,
  role => 0,
  spellcheck => FEATURE_HTML5_WD,
  style => FEATURE_HTML5_REC,
  tabindex => FEATURE_HTML5_DEFAULT,
  template => FEATURE_HTML5_DROPPED,
  title => FEATURE_HTML5_REC,  
  typeof => FEATURE_OBSVOCAB,
  unselectable => FEATURE_OBSVOCAB,
  xmlns => FEATURE_HTML5_WD,
  'xml:space' => FEATURE_OBSVOCAB,
);

my %HTMLM12NCommonAttrStatus = (
  class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  dir => FEATURE_HTML5_REC,
  href => FEATURE_RDFA_REC,
  id => FEATURE_HTML5_REC,
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
  style => FEATURE_HTML5_REC,
  title => FEATURE_HTML5_REC,
);

my %XHTML2CommonAttrStatus = (
  ## Core
  class => FEATURE_HTML5_LC | FEATURE_XHTML2_ED,
  id => FEATURE_HTML5_REC,
  #xml:id
  layout => FEATURE_XHTML2_ED,
  title => FEATURE_HTML5_REC,

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
  dir => FEATURE_HTML5_REC,

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

  ## Role
  role => FEATURE_XHTML2_ED,

  ## Style
  style => FEATURE_HTML5_REC,
);

my %HTMLM12NXHTML2CommonAttrStatus = (
  %HTMLM12NCommonAttrStatus,
  %XHTML2CommonAttrStatus,

  class => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  dir => FEATURE_HTML5_REC,
  href => FEATURE_RDFA_REC,
  id => FEATURE_HTML5_REC,
  style => FEATURE_HTML5_REC,
  title => FEATURE_HTML5_REC,
);

for (qw(
  onabort oncanplay oncanplaythrough onchange onclick oncontextmenu
  ondblclick ondrag ondragend ondragenter ondragleave ondragover
  ondragstart ondrop ondurationchange onemptied onended onformchange
  onforminput oninput oninvalid onkeydown onkeypress onkeyup
  onloadeddata onloadedmetadata onloadstart onmousedown onmousemove
  onmouseout onmouseover onmouseup onmousewheel onpause onplay
  onplaying onprogress onratechange onreadystatechange onscroll
  onseeked onseeking onselect onshow onstalled onsubmit onsuspend
  ontimeupdate onvolumechange onwaiting

  onblur onerror onfocus onload
)) {
  $HTMLAttrChecker->{$_} = $HTMLEventHandlerAttrChecker;
  $HTMLAttrStatus{$_} = FEATURE_HTML5_LC;
}

for (qw(
  onactivate onafterupdate onbeforeactivate onbeforecopy onbeforecut
  onbeforedeactivate onbeforeeditfocus onbeforepaste onbeforeupdate
  oncellchange oncontrolselect oncopy oncut ondataavailable
  ondatasetchanged ondatasetcomplete ondeactivate onerrorupdate
  onfilterchange onfocusin onfocusout ongesturechange ongestureend
  ongesturestart onhelp onlayoutcomplete onlosecapture onmouseenter
  onmouseleave onmove onmoveend onmovestart onorientationchange
  onpaste onpropertychange onresizeend onresizestart onrowenter
  onrowexit onrowsdelete onrowsinserted onselectstart onsearch
  ontouchcancel ontouchend ontouchmove ontouchstart
)) {
  $HTMLAttrChecker->{$_} = $HTMLEventHandlerAttrChecker;
  $HTMLAttrStatus{$_} = FEATURE_OBSVOCAB;
}

## Following attributes are not supported (at least as global
## attributes): onbeforeunload, onhashchange, onresize, onstorage,
## onunload, ondataunavailable, onmessage.

## ------ Attributes in the HTML namespace ------

## Global attributes whoes namespace URL is the HTML namespace,
## i.e. <http://www.w3.org/1999/xhtml>, e.g. |html:class|.  They are
## all non-conforming.

$AttrChecker->{$HTML_NS}->{''} = sub {}; # no syntactical checks
$AttrStatus->{$HTML_NS}->{''} = 0;

for (qw(
  class dir id title
  onclick ondblclick onmousedown onmouseup onmouseover onmousemove
  onmouseout onkeypress onkeydown onkeyup
  repeat repeat-max repeat-min repeat-start repeat-template
  about content datatype property rel resource rev typeof
  role
)) {
  $AttrChecker->{$HTML_NS}->{$_} = $HTMLAttrChecker->{$_};
  $AttrStatus->{$HTML_NS}->{$_} = FEATURE_OBSVOCAB;
}

## Following attributes are not supported: html:active [WA1 draft],
## html:instanceof [RDFa draft], html:cite, html:coords,
## html:datetime, html:edit, html:encoding, html:href, html:hreflang,
## html:hrefmedia, html:hreftype, html:ismap, html:layout, html:media,
## html:nextfocus, html:prevfocus, html:shape, html:src, html:srctype,
## html:style, html:target, html:usemap [XHTML2 ED].

## ------ ------

my $HTMLDatasetAttrChecker = sub {
  ## NOTE: "Authors should ... when the attributes are ignored and
  ## any associated CSS dropped, the page is still usable." (semantic
  ## constraint.)
}; # $HTMLDatasetAttrChecker

my $HTMLDatasetAttrStatus = FEATURE_HTML5_LC;

my $NameAttrChecker = sub {
  my ($self, $attr, $item, $element_state) = @_;
  my $value = $attr->value;
  if ($value eq '') {
    $self->{onerror}->(node => $attr,
                       type => 'anchor name:empty', # XXXdocumentation
                       level => $self->{level}->{must});
  } else {
    if ($self->{name}->{$value}) {
      $self->{onerror}->(node => $attr,
                         type => 'duplicate anchor name', # XXXdocumentation
                         value => $value,
                         level => $self->{level}->{must});
    } elsif ($self->{id}->{$value} and
             $self->{id}->{$value}->[-1]->owner_element ne $item->{node}) {
      $self->{onerror}->(node => $attr,
                         type => 'id name confliction', # XXXdocumentation
                         value => $value,
                         level => $self->{level}->{must});
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'anchor name', # XXX documentation
                         level => $self->{level}->{obsconforming});
    }

    push @{$self->{name}->{$value} ||= []}, $attr;
    $element_state->{element_name} = $value;
  }
}; # $NameAttrChecker

my $NameAttrCheckEnd = sub {
  my ($self, $item, $element_state) = @_;
  if (defined $element_state->{element_name}) {
    my $has_id;
    
    for my $id (@{$element_state->{element_ids} or []}) {
      if ($id eq $element_state->{element_name}) {
        undef $has_id;
        last;
      }
      $has_id = 1;
    }

    if ($has_id) {
      $self->{onerror}->(node => $item->{node}->get_attribute_node_ns (undef, 'name'),
                         type => 'id name mismatch', # XXXdocumentation
                         level => $self->{level}->{must});
    }
  }
}; # $NameAttrCheckEnd

my $ShapeCoordsChecker = sub ($$$$) {
  my ($self, $item, $attrs, $shape) = @_;
  
  my $coords;
  if ($attrs->{coords}) {
    my $coords_value = $attrs->{coords}->value;
    if ($coords_value =~ /\A-?[0-9]+(?>,-?[0-9]+)*\z/) {
      $coords = [split /,/, $coords_value];
    } else {
      $self->{onerror}->(node => $attrs->{coords},
                         type => 'coords:syntax error',
                         level => $self->{level}->{must});
    }
  }

  if (defined $attrs->{shape}) {
    my $sv = $attrs->{shape}->value;
    $sv =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
    $shape = {
        circ => 'circle', circle => 'circle',
        default => 'default',
        poly => 'polygon', polygon => 'polygon',
        rect => 'rectangle', rectangle => 'rectangle',
    }->{$sv} || 'rectangle';
  }
  
  if ($shape eq 'circle') {
    if (defined $attrs->{coords}) {
      if (defined $coords) {
        if (@$coords == 3) {
          if ($coords->[2] < 0) {
            $self->{onerror}->(node => $attrs->{coords},
                               type => 'coords:out of range',
                               index => 2,
                               value => $coords->[2],
                               level => $self->{level}->{must});
          }
        } else {
          $self->{onerror}->(node => $attrs->{coords},
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
    if (defined $attrs->{coords}) {
      $self->{onerror}->(node => $attrs->{coords},
                         type => 'attribute not allowed',
                         level => $self->{level}->{must});
    }
  } elsif ($shape eq 'polygon') {
    if (defined $attrs->{coords}) {
      if (defined $coords) {
        if (@$coords >= 6) {
          unless (@$coords % 2 == 0) {
            $self->{onerror}->(node => $attrs->{coords},
                               type => 'coords:number not even',
                               text => 0+@$coords,
                               level => $self->{level}->{must});
          }
        } else {
          $self->{onerror}->(node => $attrs->{coords},
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
    if (defined $attrs->{coords}) {
      if (defined $coords) {
        if (@$coords == 4) {
          unless ($coords->[0] < $coords->[2]) {
            $self->{onerror}->(node => $attrs->{coords},
                               type => 'coords:out of range',
                               index => 0,
                               value => $coords->[0],
                               level => $self->{level}->{must});
          }
          unless ($coords->[1] < $coords->[3]) {
            $self->{onerror}->(node => $attrs->{coords},
                               type => 'coords:out of range',
                               index => 1,
                               value => $coords->[1],
                               level => $self->{level}->{must});
          }
        } else {
          $self->{onerror}->(node => $attrs->{coords},
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
}; # $ShapeCoordsChecker

my $EmbeddedAlignChecker = $GetHTMLEnumeratedAttrChecker->({
  bottom => 1, middle => 1, top => 1, left => 1, right => 1, center => -1,
  baseline => -1, texttop => -1, abscenter => -1, absmiddle => -1,
});

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
          ## XML-compatible + no uppercase letter
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
      }
      $self->_attr_status_info ($attr, $status);
    }
  };
}; # $GetHTMLAttrsChecker

my %HTMLChecker = (
  %Whatpm::ContentChecker::AnyChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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

# ------ Elements ------

our $Element;
our $ElementDefault;

# ---- Default HTML elements ----

$Element->{$HTML_NS}->{''} = {
  status => 0,
  %HTMLChecker,
};

# ---- The root element ----

$Element->{$HTML_NS}->{html} = {
  status => FEATURE_HTML5_REC,
  is_root => 1,
  check_attrs => $GetHTMLAttrsChecker->({
    manifest => $HTMLURIAttrChecker,
    version => sub {
      ## According to HTML4 prose, the |version| attribute's value is
      ## "cdata".  Various DTDs of versions of HTML and XHTML define
      ## their |version| attribute as |#FIXED| and gives their public
      ## identifiers as the value, but it had not been speced anywhere
      ## at all.  We can't test the attribute value against unexisting
      ## conformance criteria.
    },
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    class => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_REC,
    id => FEATURE_HTML5_REC,
    lang => FEATURE_HTML5_REC,
    manifest => FEATURE_HTML5_WD,
    version => FEATURE_HTML5_OBSOLETE,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before head';

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
}; # html

$Element->{$HTML_NS}->{'pre-html'} = {
  %{$Element->{$HTML_NS}->{html}},
  status => FEATURE_ISOHTML_PREPARATION,
}; # pre-html

# ---- Document metadata ----

$Element->{$HTML_NS}->{head} = {
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    profile => $HTMLSpaceURIsAttrChecker, ## NOTE: MUST be profile URIs.
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    class => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_REC,
    id => FEATURE_HTML5_REC,
    lang => FEATURE_HTML5_REC,
    profile => FEATURE_HTML5_DROPPED | FEATURE_HTML5_OBSOLETE,
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
      my $el = $item->{node};
      my $od = $el->owner_document;
      my $tmd = $od->get_user_data('manakai_title_metadata');
      if ((defined $tmd and length $tmd) or $od->manakai_is_srcdoc) {
        #
      } else {
        $self->{onerror}->(node => $el,
                           type => 'child element missing',
                           text => 'title',
                           level => $self->{level}->{must});
      }
    }
    $self->{flag}->{in_head} = $element_state->{in_head_original};

    $HTMLChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{title} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    class => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_HTML2X_RFC,
    dir => FEATURE_HTML5_REC,
    id => FEATURE_HTML5_REC,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{base} = {
  status => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
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
      href => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
      id => FEATURE_HTML5_REC,
      target => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    })->($self, $item, $element_state);
  },
};

$Element->{$HTML_NS}->{basefont} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    color => $HTMLColorAttrChecker,
    face => sub { }, ## Comma-separated font names (cdata) [HTML4]
    size => $FontSizeChecker,
  }, {
    %HTMLAttrStatus,
    color => FEATURE_M12N10_REC_DEPRECATED,
    face => FEATURE_M12N10_REC_DEPRECATED,
    id => FEATURE_HTML5_REC,
    size => FEATURE_M12N10_REC_DEPRECATED,
  }),
}; # basefont

$Element->{$HTML_NS}->{nextid} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    n => sub { }, ## CDATA [HTML 2.0]
        ## XXX "It should be distinct from all NAME attribute values
        ## on <A> elements." [HTML 2.0]
  }, {
    %HTMLAttrStatus,
    n => FEATURE_HTML20_RFC,
  }), # check_attrs
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    my $el = $item->{node};
    unless ($el->has_attribute_ns (undef, 'n')) {
      $self->{onerror}->(node => $el,
                         type => 'attribute missing',
                         text => 'n',
                         level => $self->{level}->{must});
    }
  }, # check_attrs2
}; # nextid

$Element->{$HTML_NS}->{link} = {
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
      media => $HTMLMQAttrChecker,
      methods => sub { }, ## Space-separated values [HTML 2.0]
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
      type => $MIMETypeChecker,
      urn => $HTMLURIAttrChecker,
    }, {
      %HTMLAttrStatus,
      %HTMLM12NXHTML2CommonAttrStatus,
      charset => FEATURE_HTML5_DROPPED | FEATURE_HTML5_OBSOLETE,
          ## NOTE: |charset| attribute had been part of HTML5 spec though
          ## it had been commented out.
      href => FEATURE_HTML5_LC | FEATURE_RDFA_REC | FEATURE_XHTML2_ED |
          FEATURE_M12N10_REC,
      hreflang => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_REC,
      media => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      methods => FEATURE_HTML20_RFC,
      rel => FEATURE_HTML5_LC | FEATURE_RDFA_REC | FEATURE_XHTML2_ED |
          FEATURE_M12N10_REC,
      sizes => FEATURE_HTML5_LC,
      target => FEATURE_HTML5_OBSOLETE,
      type => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
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
  status => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLEmptyChecker,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $el = $item->{node};

    my $name_attr;
    my $http_equiv_attr;
    my $charset_attr;
    my $content_attr;
    for my $attr (@{$el->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      my $status;
      if ($attr_ns eq '') {
        $status = {
          %HTMLAttrStatus,
          %XHTML2CommonAttrStatus,
          charset => FEATURE_HTML5_WD,
          content => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          dir => FEATURE_HTML5_REC,
          'http-equiv' => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
          id => FEATURE_HTML5_REC,
          lang => FEATURE_HTML5_REC,
          name => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
          scheme => FEATURE_HTML5_OBSOLETE,
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
          ## XML-compatible + no uppercase letter
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
        $self->{onerror}->(node => $el,
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
        $self->{onerror}->(node => $el,
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
        $self->{onerror}->(node => $el,
                           type => 'attribute missing:name|http-equiv',
                           level => $self->{level}->{must});
      } else {
        $self->{onerror}->(node => $el,
                           type => 'attribute missing:name|http-equiv|charset',
                           level => $self->{level}->{must});
      }
    }

    my $check_charset_decl = sub () {
      my $parent = $el->manakai_parent_element;
      my $head = $parent ? $parent->owner_document->manakai_head : undef;
      if ($parent and $head and $parent eq $head) {
        for my $cel (@{$parent->child_nodes}) {
          next unless $cel->node_type == 1; # ELEMENT_NODE
          unless ($cel eq $el) {
            ## NOTE: Not the first child element.
            $self->{onerror}->(node => $el,
                               type => 'element not allowed:meta charset',
                               level => $self->{level}->{must});
          }
          last;
          ## NOTE: Entity references are not supported.
        }
      } else {
        $self->{onerror}->(node => $el,
                           type => 'element not allowed:meta charset',
                           level => $self->{level}->{must});
      }
    }; # $check_charset_decl

    my $check_charset = sub ($$) {
      my ($attr, $charset_value) = @_;

      my $charset;
      ($charset, $charset_value)
          = $HTMLCharsetChecker->($charset_value, $self, $attr);

      my $ic = $el->owner_document->input_encoding;
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

    ## -- The |name| attribute (document metadata)
    if (defined $name_attr) {
      my $name = $name_attr->value;
      $name =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
      
      require Whatpm::ContentChecker::HTML::Metadata;
      Whatpm::ContentChecker::HTML::Metadata->check
          (name => $name,
           name_attr => $name_attr,
           content => $content_attr ? $content_attr->value : '',
           content_attr => $content_attr || $el,
           checker => $self);
    }

    my $doc = $el->owner_document;

    ## -- The |http-equiv| attribute (pragmas)
    if (defined $http_equiv_attr) { ## An enumerated attribute
      my $keyword = $http_equiv_attr->value;
      $keyword =~ tr/A-Z/a-z/; ## ASCII case-insensitive.

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

        if (not $doc->manakai_is_html) {
          $self->{onerror}->(node => $el,
                             type => 'in XML:charset',
                             level => $self->{level}->{must});
        } elsif ($doc->manakai_is_srcdoc) {
          $self->{onerror}->(node => $el,
                             type => 'srcdoc:charset', # XXXdocumentation
                             level => $self->{level}->{must});
        }

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
        ## XXX no author requirement in the spec
        
      } elsif ($keyword eq 'refresh') {
        if ($content_attr) {
          my $content = $content_attr->value;
          if ($content =~ /\A[0-9]+\z/) {
            ## NOTE: Valid non-negative integer.
            #
          } elsif ($content =~ s/\A[0-9]+;[\x09\x0A\x0C\x0D\x20]+[Uu][Rr][Ll]=//) {
            ## XXXURL
            Whatpm::URIChecker->check_iri_reference ($content, sub {
              $self->{onerror}->(value => $content, @_, node => $content_attr);
            }, $self->{level});
            $self->{has_uri_attr} = 1; ## NOTE: One of "attributes with URLs".

            $element_state->{uri_info}->{content}->{node} = $content_attr;
            $element_state->{uri_info}->{content}->{type}->{hyperlink} = 1;
            ## XXXTODO: absolute
            push @{$self->{return}->{uri}->{$content} ||= []},
                $element_state->{uri_info}->{content};
          } else {
            $self->{onerror}->(node => $content_attr,
                               type => 'refresh:syntax error',
                               level => $self->{level}->{must});
          }
        }
      } elsif ($keyword eq 'content-language') {
        if ($content_attr) {
          my $content = $content_attr->value;
          require Whatpm::LangTag;
          ## XXX In fact what the spec requires is "BCP 47 langauge code".
          Whatpm::LangTag->check_rfc3066_language_tag ($content, sub {
            $self->{onerror}->(@_, node => $content_attr);
          }, $self->{level});
        }

        $self->{onerror}->(node => $el,
                           type => 'content-language', # XXX documentation
                           level => $self->{level}->{obsconforming});
      } else {
        ## NOTE: |Content-Style-Type| and |Content-Script-Type|
        ## pragmas are listed in the table of the spec in the
        ## commented-out form, but there is no author requirement
        ## (even commented-out one isn't there).

        ## NOTE: Pragma extensions are listed in
        ## <http://wiki.whatwg.org/wiki/PragmaExtensions>.  At the
        ## time of writing, no extension has been registered yet.

        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'enumerated:invalid',
                           level => $self->{level}->{must});
      }
    }

    if (defined $charset_attr) {
      my $value = $charset_attr->value;

      $check_charset_decl->();
      $check_charset->($charset_attr, $value);

      if (not $doc->manakai_is_html and not $value =~ /\A[Uu][Tt][Ff]-8\z/) {
        $self->{onerror}->(node => $el,
                           type => 'in XML:charset',
                           level => $self->{level}->{must});
      } elsif ($doc->manakai_is_srcdoc) {
        $self->{onerror}->(node => $el,
                           type => 'srcdoc:charset', # XXXdocumentation
                           level => $self->{level}->{must});
      }
    }
  }, # check_attrs
}; # meta

$Element->{$HTML_NS}->{style} = {
  status => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    type => sub {
      my ($self, $attr) = @_;

      my $type = $MIMETypeChecker->(@_);
      if ($type) {
        unless ($type->is_styling_lang) {
          $self->{onerror}->(node => $attr,
                             type => 'IMT:not styling lang', # XXXdocumentation
                             level => $self->{level}->{must});
        }

        if (defined $type->param ('charset')) {
          $self->{onerror}->(node => $attr,
                             type => 'IMT:parameter not allowed',
                             level => $self->{level}->{must});
        }
      }
    },
    media => $HTMLMQAttrChecker,
    scoped => $GetHTMLBooleanAttrChecker->('scoped'),
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    dir => FEATURE_HTML5_REC,
    disabled => FEATURE_XHTML2_ED,
    href => FEATURE_RDFA_REC | FEATURE_XHTML2_ED,
    id => FEATURE_HTML5_REC,
    lang => FEATURE_HTML5_REC,
    media => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    scoped => FEATURE_HTML5_FD,
    title => FEATURE_HTML5_REC,
    type => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    my $type = $item->{node}->get_attribute_ns (undef, 'type');
    $type = 'text/css' unless defined $type;

    ## NOTE: RFC 2616's definition of "type/subtype".  According to
    ## the Web Applications 1.0 specification, types with unsupported
    ## parameters are considered as unknown types.  Since we don't
    ## support any media type with parameters (and the spec requires
    ## the impl to treate |charset| parameter as if it is an unknown
    ## parameter), we can safely ignore any type specification with
    ## explicit parameters entirely.
    if ($type =~ m[\A(?>(?>\x0D\x0A)?[\x09\x20])*([\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]+)/([\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]+)(?>(?>\x0D\x0A)?[\x09\x20])*\z]) {
      $type = "$1/$2";
      $type =~ tr/A-Z/a-z/; ## NOTE: ASCII case-insensitive
    } else {
      undef $type;
    }

    ## Conformance of the content depends on the styling language in
    ## use, which is detected by the |type=""| attribute value
    ## (i.e. $type).
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
      ## NOTE: XML content should be checked by THIS instance of
      ## checker as part of normal tree validation.  However, we don't
      ## know any XML-based styling language that can be used in HTML
      ## <style> element at the moment, so it throws a "style language
      ## not supported" error here.
      $self->{onerror}->(node => $item->{node},
                         type => 'XML style lang',
                         text => $element_state->{style_type},
                         level => $self->{level}->{uncertain});
    } else {
      $self->{onsubdoc}->({s => $element_state->{text},
                           container_node => $item->{node},
                           media_type => $element_state->{style_type},
                           is_char_string => 1});
    }

    ## |style| element content restrictions
    my $tc = $item->{node}->text_content;
    $tc =~ s/.*<!--.*-->//gs;
    if ($tc =~ /<!--/) {
      $self->{onerror}->(node => $item->{node},
                         type => 'style:unclosed cdo', ## XXX documentation
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  },
}; # style
## ISSUE: Relationship to significant content check?

# ---- Scripting ----

$Element->{$HTML_NS}->{script} = {
  %HTMLChecker,
  status => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    async => $GetHTMLBooleanAttrChecker->('async'),
    defer => $GetHTMLBooleanAttrChecker->('defer'),
    charset => sub {
      my ($self, $attr) = @_;

      ## XXXresource: MUST match the charset of the referenced
      ## resource (HTML5 revision 2967).

      $HTMLCharsetChecker->($attr->value, @_);
    },
    event => sub { }, ## Reserved in HTML4 without no restriction.
    for => $HTMLURIAttrChecker, ## Reserved in HTML4
    language => sub {},
    src => $HTMLURIAttrChecker, ## TODO: pointed resource MUST be in type of type="" (resource error)
    type => sub {
      my ($self, $attr) = @_;

      my $type = $MIMETypeChecker->(@_);
      if ($type) {
        if (defined $type->param ('charset')) {
          $self->{onerror}->(node => $attr,
                             type => 'IMT:parameter not allowed',
                             level => $self->{level}->{must});
        }
      }
    }, # type
  }, {
    %HTMLAttrStatus,
    async => FEATURE_HTML5_WD,
    charset => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    defer => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    event => FEATURE_HTML5_OBSOLETE,
    for => FEATURE_HTML5_OBSOLETE,
    href => FEATURE_RDFA_REC,
    id => FEATURE_HTML5_REC,
    #implements [XHTML 1.2]
    language => FEATURE_HTML5_LC,
    src => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    my $el = $item->{node};
    
    unless ($el->has_attribute_ns (undef, 'src')) {
      my $charset_attr = $el->get_attribute_node_ns (undef, 'charset');
      if ($charset_attr) {
        $self->{onerror}->(type => 'attribute not allowed',
                           node => $charset_attr,
                           level => $self->{level}->{must});
      }

      if ($el->has_attribute_ns (undef, 'defer')) {
        $self->{onerror}->(node => $el,
                           type => 'attribute missing',
                           text => 'src',
                           level => $self->{level}->{must});
      }
    }

    my $lang_attr = $el->get_attribute_node_ns (undef, 'language');
    if ($lang_attr) {
      my $lang = $lang_attr->value;
      $lang =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
      if ($lang eq 'javascript') {
        my $type = $el->get_attribute_ns (undef, 'type');
        $type =~ tr/A-Z/a-z/ if defined $type; ## ASCII case-insensitive.
        if (not defined $type or $type eq 'text/javascript') {
          $self->{onerror}->(node => $lang_attr,
                             type => 'script language', # XXXdocumentatoion
                             level => $self->{level}->{obsconforming});
        } else {
          $self->{onerror}->(node => $lang_attr,
                             type => 'script language:ne type', # XXXdocmentation
                             level => $self->{level}->{must});
        }
      } else {
        $self->{onerror}->(node => $lang_attr,
                           type => 'script language:not js', # XXXdocmentation
                           level => $self->{level}->{must});
      }
    }
  }, # check_attrs2
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    if ($item->{node}->has_attribute_ns (undef, 'src')) {
      $element_state->{inline_documentation_only} = 1;
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

      # XXX this is wrong - unknown parameters MUST be ignored.
      $element_state->{script_type} = $type;
    }

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
      if ($element_state->{inline_documentation_only}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:empty',
                           level => $self->{level}->{must});
      }
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{text} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{inline_documentation_only}) {
      if (length $element_state->{text}) {
        $self->{onsubdoc}->({s => $element_state->{text},
                             container_node => $item->{node},
                             media_type => 'text/x-script-inline-documentation',
                             is_char_string => 1});
      }
    } else {
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
    }

    if (length $element_state->{text}) {
      $self->{onsubdoc}->({s => $element_state->{text},
                           container_node => $item->{node},
                           media_type => 'text/x-script-element-text',
                           is_char_string => 1});
    }

    $HTMLChecker{check_end}->(@_);
  },
  ## TODO: There MUST be |type| unless the script type is JavaScript. (resource error)
  ## NOTE: "When used to include script data, the script data must be embedded
  ## inline, the format of the data must be given using the type attribute,
  ## and the src attribute must not be specified." - not testable.
      ## TODO: It would be possible to err <script type=text/plain src=...>
}; # script
## ISSUE: Significant check and text child node

## NOTE: When script is disabled.
$Element->{$HTML_NS}->{noscript} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
          my $value = $http_equiv_attr->value;
          $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
          if ($value eq 'content-type') {
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
}; # event-source

$Element->{$HTML_NS}->{eventsource} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_DROPPED,
  check_attrs => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    src => FEATURE_HTML5_DROPPED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
}; # eventsource

# ---- Sections ----

$Element->{$HTML_NS}->{body} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    alink => $HTMLColorAttrChecker,
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    link => $HTMLColorAttrChecker,
    marginheight => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    marginwidth => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    onafterprint => $HTMLEventHandlerAttrChecker,
    onbeforeprint => $HTMLEventHandlerAttrChecker,
    onbeforeunload => $HTMLEventHandlerAttrChecker,
    onblur => $HTMLEventHandlerAttrChecker,
    onerror => $HTMLEventHandlerAttrChecker,
    onfocus => $HTMLEventHandlerAttrChecker,
    onhashchange => $HTMLEventHandlerAttrChecker,
    onload => $HTMLEventHandlerAttrChecker,
    onmessage => $HTMLEventHandlerAttrChecker,
    onoffline => $HTMLEventHandlerAttrChecker,
    ononline => $HTMLEventHandlerAttrChecker,
    onpagehide => $HTMLEventHandlerAttrChecker,
    onpageshow => $HTMLEventHandlerAttrChecker,
    onpopstate => $HTMLEventHandlerAttrChecker,
    onredo => $HTMLEventHandlerAttrChecker,
    onresize => $HTMLEventHandlerAttrChecker,
    onstorage => $HTMLEventHandlerAttrChecker,
    onundo => $HTMLEventHandlerAttrChecker,
    onunload => $HTMLEventHandlerAttrChecker,
    rightmargin => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    text => $HTMLColorAttrChecker,
    topmargin => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    vlink => $HTMLColorAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    alink => FEATURE_HTML5_OBSOLETE,
    background => FEATURE_HTML5_OBSOLETE,
    bgcolor => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    link => FEATURE_HTML5_OBSOLETE,
    #marginheight WA1 prose
    #marginwidth WA1 prose
    onafterprint => FEATURE_HTML5_LC,
    onbeforeprint => FEATURE_HTML5_LC,
    onbeforeunload => FEATURE_HTML5_LC,
    onblur => FEATURE_HTML5_LC,
    onerror => FEATURE_HTML5_LC,
    onfocus => FEATURE_HTML5_LC,
    onhashchange => FEATURE_HTML5_LC,
    onload => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    onmessage => FEATURE_HTML5_LC,
    onoffline => FEATURE_HTML5_LC,
    ononline => FEATURE_HTML5_LC,
    onpagehide => FEATURE_HTML5_LC,
    onpageshow => FEATURE_HTML5_LC,
    onpopstate => FEATURE_HTML5_LC,
    onredo => FEATURE_HTML5_LC,
    onresize => FEATURE_HTML5_LC,
    onstorage => FEATURE_HTML5_LC,
    onundo => FEATURE_HTML5_LC,
    onunload => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    #rightmargin WA1 prose
    text => FEATURE_HTML5_OBSOLETE,
    #topmargin WA1 prose
    vlink => FEATURE_HTML5_OBSOLETE,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
}; # body

$Element->{$HTML_NS}->{section} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %XHTML2CommonAttrStatus,
    cite => FEATURE_HTML5_DROPPED | FEATURE_XHTML2_ED,
  }),
};

$Element->{$HTML_NS}->{nav} = {
  status => FEATURE_HTML5_LC,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{article} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    pubdate => $GetDateTimeAttrChecker->('global_date_and_time_string'),
  }, {
    %HTMLAttrStatus,
    cite => FEATURE_HTML5_DROPPED,
    pubdate => FEATURE_HTML5_LC_DROPPED,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{has_time_pubdate_original}
        = $self->{flag}->{has_time_pubdate};
    $self->{flag}->{has_time_pubdate} = 0;

    $HTMLFlowContentChecker{check_start}->(@_);
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    
    $self->{flag}->{has_time_pubdate}
        = $element_state->{has_time_pubdate_original};

    $HTMLFlowContentChecker{check_end}->(@_);
  }, # check_end
}; # article

$Element->{$HTML_NS}->{aside} = {
  status => FEATURE_HTML5_LC,
  %HTMLFlowContentChecker,
};

$Element->{$HTML_NS}->{h1} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->{flag}->{has_hn} = 1;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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

$Element->{$HTML_NS}->{hgroup} = {
  %HTMLChecker,
  status => FEATURE_HTML5_LC,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state, $element_state2) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
      if ($child_nsuri eq $HTML_NS and $child_ln =~ /\Ah[1-6]\z/) {
        $element_state2->{has_hn} = 1;
      }
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln =~ /\Ah[1-6]\z/) {
      ## NOTE: Use $element_state2 instead of $element_state here so
      ## that the |h2| element in |<hgroup><ins><h2>| is not counted
      ## as an |h2| of the |hgroup| element.
      $element_state2->{has_hn} = 1;
    } else {
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  }, # check_child_element
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node, type => 'character not allowed',
                         level => $self->{level}->{must});
    }
  }, # check_child_text
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{has_hn}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:hn',
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  }, # check_end
}; # hgroup

$Element->{$HTML_NS}->{header} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_LC,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state,
                                {$HTML_NS => {qw/header 1 footer 1/}});
    $element_state->{has_hn_original} = $self->{flag}->{has_hn};
    $self->{flag}->{has_hn} = 0;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    unless ($self->{flag}->{has_hn}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:hn',
                         level => $self->{level}->{warn});
    }
    $self->{flag}->{has_hn} ||= $element_state->{has_hn_original};

    $HTMLFlowContentChecker{check_end}->(@_);
  }, # check_end
}; # header

$Element->{$HTML_NS}->{footer} = {
  status => FEATURE_HTML5_LC,
  %HTMLFlowContentChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state,
                                {$HTML_NS => {header => 1, footer => 1}});

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  }, # check_end
}; # footer

$Element->{$HTML_NS}->{address} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements
        ($element_state,
         {$HTML_NS => {header => 1, footer => 1, address => 1}},
         $HTMLSectioningContent, $HTMLHeadingContent);

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLFlowContentChecker{check_end}->(@_);
  },
};

# ---- Grouping content ----

$Element->{$HTML_NS}->{p} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{hr} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1,
    }),
    color => $HTMLColorAttrChecker,
    noshade => $GetHTMLBooleanAttrChecker->('noshade'),
    size => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    width => $HTMLLengthAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    color => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    noshade => FEATURE_HTML5_OBSOLETE,
    size => FEATURE_HTML5_OBSOLETE,
    width => FEATURE_HTML5_OBSOLETE,
  }), # check_attrs
}; # hr

$Element->{$HTML_NS}->{spacer} = {
  %HTMLEmptyChecker,
  # XXX attributes
  status => FEATURE_HTML5_OBSOLETE,
}; # wbr

$Element->{$HTML_NS}->{br} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    clear => $GetHTMLEnumeratedAttrChecker->({
      left => 1, all => 1, right => 1, none => 1, both => -1,
    }),
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    clear => FEATURE_HTML5_OBSOLETE,
    id => FEATURE_HTML5_REC,
    style => FEATURE_HTML5_REC,
    title => FEATURE_HTML5_REC,
  }),
}; # br

$Element->{$HTML_NS}->{pre} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    wrap => $GetHTMLBooleanAttrChecker->('wrap'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
    width => FEATURE_HTML5_OBSOLETE,
    #wrap WA1 prose
  }),
  check_end => sub {
    my ($self, $item, $element_state) = @_;
  
    ## TODO: Flag to enable/disable IDL checking?
    my $class = $item->{node}->get_attribute_ns (undef, 'class');
    if (defined $class and
        $class =~ /\bidl(?>-code)?\b/) { ## TODO: use classList.has
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
}; # pre

$Element->{$HTML_NS}->{xmp} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_OBSOLETE,
}; # xmp

$Element->{$HTML_NS}->{listing} = $Element->{$HTML_NS}->{xmp};

$Element->{$HTML_NS}->{plaintext} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_OBSOLETE,
}; # plaintext

$Element->{$HTML_NS}->{blockquote} = {
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLFlowContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    cite => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
  
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{dialog} = {
  status => FEATURE_HTML5_DROPPED,
  %HTMLChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before dt';

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
}; # dialog

$Element->{$HTML_NS}->{ol} = {
  %HTMLChecker,
  status => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    reversed => $GetHTMLBooleanAttrChecker->('reversed'),
    start => $HTMLIntegerAttrChecker,
    type => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ({
          1 => 1, a => 1, A => 1, i => 1, I => 1,
      }->{$value}) {
        $self->{onerror}->(node => $attr,
                           type => 'oltype:invalid', # XXXdocumentation
                           level => $self->{level}->{must});
      }
    }, # type
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    compact => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    reversed => FEATURE_HTML5_WD,
    #start => FEATURE_HTML5_WD | FEATURE_M12N10_REC_DEPRECATED,
    start => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_OBSOLETE,
  }), # check_attrs
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
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
    compact => $GetHTMLBooleanAttrChecker->('compact'),
    type => $GetHTMLEnumeratedAttrChecker->({
      disc => 1, square => 1, circle => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    compact => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    type => FEATURE_HTML5_OBSOLETE,
  }), # check_attrs
}; # ul

$Element->{$HTML_NS}->{dir} = {
  %{$Element->{$HTML_NS}->{ul}},
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
    compact => $GetHTMLBooleanAttrChecker->('compact'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    compact => FEATURE_M12N10_REC_DEPRECATED,
    lang => FEATURE_HTML5_REC,
  }),
}; # dir

$Element->{$HTML_NS}->{li} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
    type => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      ## HTML4's definition of |type| attribute of |li| element is
      ## very vague.  See
      ## <http://suika.fam.cx/%7Ewakaba/wiki/sw/n/type$13186>.
      unless ($value =~ /\A(?:[Cc][Ii][Rr][Cc][Ll][Ee]|[Dd][Ii][Ss][Cc]|[Ss][Qq][Uu][Aa][Rr][Ee]|[1aAiI])\z/) {
        $self->{onerror}->(node => $attr,
                           type => 'litype:invalid', # XXXdocumentation
                           level => $self->{level}->{must});
      }
    }, # type
    value => sub {
      my ($self, $attr) = @_;

      my $parent_is_ol;
      my $parent = $attr->owner_element->manakai_parent_element;
      if (defined $parent) {
        my $parent_ns = $parent->namespace_uri;
        $parent_ns = '' unless defined $parent_ns;
        my $parent_ln = $parent->manakai_local_name;
        $parent_is_ol = ($parent_ns eq $HTML_NS and $parent_ln eq 'ol');
      }

      unless ($parent_is_ol) {
        $self->{onerror}->(node => $attr,
                           type => 'non-ol li value',
                           level => $self->{level}->{must});
      }
      
      $HTMLIntegerAttrChecker->($self, $attr);
    },
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML2X_RFC,
    lang => FEATURE_HTML5_REC,
    type => FEATURE_HTML5_OBSOLETE,
    #value => FEATURE_HTML5_LC | FEATURE_XHTMLBASIC11_CR | 
    #    FEATURE_M12N10_REC_DEPRECATED,
    value => FEATURE_HTML5_LC | FEATURE_XHTML2_ED |
        FEATURE_XHTMLBASIC11_CR | FEATURE_M12N10_REC,
  }), # check_attrs
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if (0) {
      ## XXXTODO: In <dir> element, then ...
      $HTMLPhrasingContentChecker{check_child_element}->(@_);
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
    }
  }, # check_child_element
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if (0) {
      ## XXXTODO: In <dir> element, then ...
      $HTMLPhrasingContentChecker{check_child_text}->(@_);
    } else {
      $HTMLFlowContentChecker{check_child_text}->(@_);
    }
  }, # check_child_text
}; # li

$Element->{$HTML_NS}->{dl} = {
  %HTMLChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    compact => $GetHTMLBooleanAttrChecker->('compact'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    compact => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    type => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before dt';

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
}; # dl
## XXX Within a single <code>dl</code> element, there should not be
## more than one <code>dt</code> element for each name.</p> (HTML5
## revision 3859)

$Element->{$HTML_NS}->{dt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
}; # dt

$Element->{$HTML_NS}->{dd} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{div} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
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
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
}; # center

$Element->{$HTML_NS}->{div1} = {
  %{$Element->{$HTML_NS}->{div}},
  status => FEATURE_ISOHTML_PREPARATION,
}; # div1

$Element->{$HTML_NS}->{div2} = $Element->{$HTML_NS}->{div1};
$Element->{$HTML_NS}->{div3} = $Element->{$HTML_NS}->{div1};
$Element->{$HTML_NS}->{div4} = $Element->{$HTML_NS}->{div1};
$Element->{$HTML_NS}->{div5} = $Element->{$HTML_NS}->{div1};
$Element->{$HTML_NS}->{div6} = $Element->{$HTML_NS}->{div1};

$Element->{$HTML_NS}->{marquee} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    behavior => $GetHTMLEnumeratedAttrChecker->({
      scroll => -1, slide => -1, alternate => -1,
    }),
    bgcolor => $HTMLColorAttrChecker,
    direction => $GetHTMLEnumeratedAttrChecker->({
      left => -1, right => -1, up => -1, down => -1,
    }),
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    hspace => $HTMLLengthAttrChecker,
    loop => $HTMLIntegerAttrChecker,
    onbounce => $HTMLEventHandlerAttrChecker,
    onfinish => $HTMLEventHandlerAttrChecker,
    onstart => $HTMLEventHandlerAttrChecker,
    scrollamount => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    scrolldelay => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    truespeed => $GetHTMLEnumeratedAttrChecker->({
      true => -1, false => -1,
    }),
    vspace => $HTMLLengthAttrChecker,
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    behavior => FEATURE_HTML5_OBSOLETE,
    #bgcolor WA1 prose
    direction => FEATURE_HTML5_OBSOLETE,
    #height WA1 prose
    #hspace WA1 prose
    #loop WA1 prose
    onbounce => FEATURE_HTML5_OBSOLETE,
    onfinish => FEATURE_HTML5_OBSOLETE,
    onstart => FEATURE_HTML5_OBSOLETE,
    #scrollamount WA1 prose
    #scrolldelay WA1 prose
    truespeed => FEATURE_HTML5_OBSOLETE,
    #vspace WA1 prose
    #width WA1 prose
  }), # check_attrs
}; # marquee

$Element->{$HTML_NS}->{multicol} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
  # XXX attributes
}; # multicol

$Element->{$HTML_NS}->{font} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_DROPPED | FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    color => $HTMLColorAttrChecker,
    face => sub { }, ## Comma-separated font names (cdata) [HTML4]
    size => $FontSizeChecker,
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    color => FEATURE_M12N10_REC_DEPRECATED,
    dir => FEATURE_HTML5_REC,
    face => FEATURE_M12N10_REC_DEPRECATED,
    id => FEATURE_HTML5_REC,
    lang => FEATURE_HTML5_REC,
    size => FEATURE_M12N10_REC_DEPRECATED,
    style => FEATURE_HTML5_REC,
    title => FEATURE_HTML5_REC,
  }),
  ## NOTE: When the |font| element was defined in the HTML5 specification,
  ## it is allowed only in a document with the WYSIWYG signature.  The
  ## checker does not check whether there is the signature, since the
  ## signature is dropped, too, and has never been implemented.  (In addition,
  ## for any |font| element an "element not defined" error is raised anyway,
  ## such that we don't have to raise an additional error.)
}; # font

# ---- Text-level semantics ----

$Element->{$HTML_NS}->{a} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
          accesskey => FEATURE_M12N10_REC | FEATURE_HTML5_FD,
          charset => FEATURE_HTML5_OBSOLETE,
          coords => FEATURE_HTML5_OBSOLETE,
          href => FEATURE_HTML5_WD | FEATURE_RDFA_REC | FEATURE_XHTML2_ED |
              FEATURE_M12N10_REC,
          hreflang => FEATURE_HTML5_WD | FEATURE_XHTML2_ED |
              FEATURE_M12N10_REC,
          lang => FEATURE_HTML5_REC,
          media => FEATURE_HTML5_WD | FEATURE_XHTML2_ED,
          methods => FEATURE_HTML5_OBSOLETE,
          name => FEATURE_HTML5_LC,
          onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          ping => FEATURE_HTML5_WD,
          rel => FEATURE_HTML5_WD | FEATURE_RDFA_REC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          shape => FEATURE_HTML5_OBSOLETE,
          tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          target => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
          type => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
          urn => FEATURE_HTML5_OBSOLETE,
        }->{$attr_ln};

        $checker = {
          charset => sub {
            my ($self, $attr) = @_;
            $HTMLCharsetChecker->($attr->value, @_);
          },
          coords => sub { }, ## Checked in $ShapeCoordsChecker.
          href => $HTMLURIAttrChecker,
          hreflang => $HTMLLanguageTagAttrChecker,
          media => $HTMLMQAttrChecker,
          methods => sub { }, ## Space-separated values [HTML 2.0]
          name => $NameAttrChecker,
          ping => $HTMLSpaceURIsAttrChecker,
          rel => sub { $HTMLLinkTypesAttrChecker->(1, $item, @_) },
          shape => $GetHTMLEnumeratedAttrChecker->({
            circ => -1, circle => 1,
            default => 1,
            poly => 1, polygon => -1,
            rect => 1, rectangle => -1,
          }),
          target => $HTMLTargetAttrChecker,
          type => $MIMETypeChecker,
          urn => $HTMLURIAttrChecker,
        }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          ## XML-compatible + no uppercase letter
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

    $ShapeCoordsChecker->($self, $item, \%attr, 'missing');

    $element_state->{uri_info}->{href}->{type}->{hyperlink} = 1;
  },
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, $HTMLInteractiveContent);

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);
    delete $self->{flag}->{in_a_href}
        unless $element_state->{in_a_href_original};

    $NameAttrCheckEnd->(@_);
    $HTMLTransparentChecker{check_end}->(@_);
  },
};

$Element->{$HTML_NS}->{em} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{strong} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{small} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{big} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{cite} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{q} = {
  status => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    cite => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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

$Element->{$HTML_NS}->{dfn} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    full => FEATURE_XHTML2_ED,
    lang => FEATURE_HTML5_REC,
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
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{time} = {
  status => FEATURE_HTML5_WD,
  %HTMLPhrasingContentChecker,
  check_attrs => $GetHTMLAttrsChecker->({
    datetime => sub { 1 }, # checked in |checker|
    pubdate => $GetHTMLBooleanAttrChecker->('pubdate'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    datetime => FEATURE_HTML5_FD,
    pubdate => FEATURE_HTML5_WD,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {time => 1}});

    $HTMLPhrasingContentChecker{check_start}->(@_);
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    ## XXX Maybe we should move this code out somewhere (maybe
    ## Message::Date) such that we can reuse this code in other places
    ## (e.g. HTMLTimeElement implementation).

    my $has_pubdate = $item->{node}->has_attribute_ns (undef, 'pubdate');
    if ($has_pubdate) {
      if ($self->{flag}->{has_time_pubdate}) {
        ## NOTE: "for each Document, there must be no more than one
        ## time element with a pubdate attribute that does not have an
        ## ancestor article element."  Therefore, strictly speaking,
        ## an orphan tree might contain more than two |time| elements
        ## with |pubdate| attribute specified.  We don't always
        ## inteprete the spec text strictly when a node that belongs
        ## to an orphan tree is being processed (unless the spec
        ## explicitly defines handling of such a case).
        
        $self->{onerror}->(node => $item->{node},
                           type => 'element not allowed:pubdate', ## XXX TODOC
                           level => $self->{level}->{must});
      } else {
        $self->{flag}->{has_time_pubdate} = 1;
      }
    }

    my $need_a_date = $has_pubdate;

    ## "Vaguer moments in time" or "valid date or time string".
    my $attr = $item->{node}->get_attribute_node_ns (undef, 'datetime');
    my $input;
    my $reg_sp;
    my $input_node;
    if ($attr) {
      $input = $attr->value;
      $reg_sp = qr/[\x09\x0A\x0C\x0D\x20]/;
      $input_node = $attr;
    } else {
      $input = $item->{node}->text_content;
      $reg_sp = qr/\p{WhiteSpace}/;
      $input_node = $item->{node};
    }

    my $hour;
    my $minute;
    my $second;
    if ($input =~ /
      \A
      $reg_sp*
      ([0-9]+) # 1
      (?>
        -([0-9]+) # 2
        -((?>[0-9]+)) # 3 # Use (?>) such that yyyy-mm-ddhh:mm does not match
        $reg_sp*
        (?>
          (?>
            T
            $reg_sp*
          )?
          ([0-9]+) # 4
          :([0-9]+) # 5
          (?>
            :([0-9]+(?>\.[0-9]+)?) # 6
          )?
          $reg_sp*
          (?>
            Z
            $reg_sp*
          |
            [+-]([0-9]+):([0-9]+) # 7, 8
            $reg_sp*
          )?
        )?
        \z
      |
        :([0-9]+) # 9
        (?:
          :([0-9]+(?>\.[0-9]+)?) # 10
        )?
        $reg_sp*
        \z
      )
    /x) {
      my $has_syntax_error;
      if (defined $2) { ## YYYY-MM-DD T? hh:mm
        if (length $1 != 4 or length $2 != 2 or length $3 != 2 or
            (defined $4 and length $4 != 2) or
            (defined $5 and length $5 != 2)) {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error',
                             level => $self->{level}->{must});
          $has_syntax_error = 1;
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
        $self->{onerror}->(node => $input_node,
                           type => 'datetime:bad year',
                           level => $self->{level}->{must})
          if $1 == 0;

        ($hour, $minute, $second) = ($4, $5, $6);
          
        if (defined $7) { ## [+-]hh:mm
          if (length $7 != 2 or length $8 != 2) {
            $self->{onerror}->(node => $input_node,
                               type => 'dateortime:syntax error',
                               level => $self->{level}->{must});
            $has_syntax_error = 1;
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
          $has_syntax_error = 1;
        }

        ($hour, $minute, $second) = ($1, $9, $10);

        if ($need_a_date) {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:date missing', ## XXX TODOC
                             level => $self->{level}->{must});
        }
      }

      $self->{onerror}->(node => $input_node, type => 'datetime:bad hour',
                         level => $self->{level}->{must})
          if defined $hour and $hour > 23;
      $self->{onerror}->(node => $input_node, type => 'datetime:bad minute',
                         level => $self->{level}->{must})
          if defined $minute and $minute > 59;

      if (defined $second) { ## s
        ## NOTE: Integer part of second don't have to have length of two.
          
        if (substr ($second, 0, 1) eq '.') {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error',
                             level => $self->{level}->{must});
          $has_syntax_error = 1;
        }
          
        $self->{onerror}->(node => $input_node, type => 'datetime:bad second',
                           level => $self->{level}->{must}) if $second >= 60;
      }

      unless ($has_syntax_error) {
        $input =~ s/\A$reg_sp+//;
        $input =~ s/$reg_sp+\z//;
        if ($input =~ /$reg_sp+/) {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error',
                             level => $self->{level}->{must});
        }
      }
    } else {
      $self->{onerror}->(node => $input_node,
                         type => 'dateortime:syntax error',
                         level => $self->{level}->{must});
    }

    $HTMLPhrasingContentChecker{check_end}->(@_);
  }, # check_end
}; # time

$Element->{$HTML_NS}->{code} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{var} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{samp} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{kbd} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{sub} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{sup} = $Element->{$HTML_NS}->{sub};

# XXX Warning for "authors are encouraged to consider whether other
# elements might be more applicable"
$Element->{$HTML_NS}->{i} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

$Element->{$HTML_NS}->{b} = $Element->{$HTML_NS}->{i};

$Element->{$HTML_NS}->{tt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
}; # tt

$Element->{$HTML_NS}->{s} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
}; # s

$Element->{$HTML_NS}->{strike} = $Element->{$HTML_NS}->{s};

$Element->{$HTML_NS}->{u} = $Element->{$HTML_NS}->{s};

$Element->{$HTML_NS}->{blink} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
}; # blink

$Element->{$HTML_NS}->{mark} = {
  status => FEATURE_HTML5_WD,
  %HTMLPhrasingContentChecker,
};

$Element->{$HTML_NS}->{nobr} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
}; # nobr

$Element->{$HTML_NS}->{wbr} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_OBSOLETE,
}; # wbr

$Element->{$HTML_NS}->{ruby} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_WD | FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus, # XHTML 1.1 & XHTML 2.0 & XHTML+RDFa 1.0
    lang => FEATURE_HTML5_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{phase} = 'before-rb';
    #$element_state->{has_sig}

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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

$Element->{$HTML_NS}->{rb} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
}; # rb

$Element->{$HTML_NS}->{rt} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_WD | FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    rbspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
    rbspan => FEATURE_RUBY_REC,
  }),
}; # rt

$Element->{$HTML_NS}->{rp} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_WD | FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
}; # rp

$Element->{$HTML_NS}->{rbc} = {
  %HTMLChecker,
  status => FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
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
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'rb') {
      $element_state->{has_rb} = 1;
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
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    unless ($element_state->{has_rb}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'rb',
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  }, # check_end
}; # rbc

$Element->{$HTML_NS}->{rtc} = {
  %HTMLChecker,
  status => FEATURE_RUBY_REC,
  check_attrs => $GetHTMLAttrsChecker->({}, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
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
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'rt') {
      $element_state->{has_rt} = 1;
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
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    unless ($element_state->{has_rt}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'rt',
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  }, # check_end
}; # rtc

$Element->{$HTML_NS}->{bdo} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      #
    }, {
      %HTMLAttrStatus,
      class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
      dir => FEATURE_HTML5_REC,
      id => FEATURE_HTML5_REC,
      style => FEATURE_HTML5_REC,
      title => FEATURE_HTML5_REC,
      lang => FEATURE_HTML5_REC,
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

$Element->{$HTML_NS}->{span} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }),
};

# ---- Edits ----

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
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    datetime => $GetDateTimeAttrChecker->('global_date_and_time_string'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    datetime => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

$Element->{$HTML_NS}->{del} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    datetime => $GetDateTimeAttrChecker->('global_date_and_time_string'),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    cite => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    datetime => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{cite}->{type}->{cite} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
};

# ---- Embedded content ----

$Element->{$HTML_NS}->{figure} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_WD,
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{in_figure} = 1;
    $element_state->{phase} = 'initial';

    $HTMLFlowContentChecker{check_start}->(@_);
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
    } elsif ($element_state->{phase} eq 'flow') {
      if ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        #
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'figcaption') {
        $element_state->{phase} = 'flow-figcaption';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:figure',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'figcaption-flow') {
      if ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        #
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:figure',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'figcaption') {
      if ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        $element_state->{phase} = 'figcaption-flow';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:figure',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{phase} eq 'initial') {
      if ($HTMLFlowContent->{$child_nsuri}->{$child_ln}) {
        $element_state->{phase} = 'flow';
      } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'figcaption') {
        $element_state->{phase} = 'figcaption';
      } else {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:figure', # XXXdocumentation
                           level => $self->{level}->{must});        
      }
    } elsif ($element_state->{phase} eq 'flow-figcaption') {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:figure', # XXXdocumentation
                         level => $self->{level}->{must});        
    } else {
      die "check_child_element: Bad |figure| phase: $element_state->{phase}";
    }
  }, # check_child_element
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      if ($element_state->{phase} eq 'flow' or
          $element_state->{phase} eq 'figcaption-flow') {
        #
      } elsif ($element_state->{phase} eq 'figcaption') {
        $element_state->{phase} = 'figcaption-flow';
      } elsif ($element_state->{phase} eq 'initial') {
        $element_state->{phase} = 'flow';
      } else {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed:figure', # XXXdocumentation
                           level => $self->{level}->{must});
      }
    }
  }, # check_child_text
}; # figure

$Element->{$HTML_NS}->{figcaption} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT,
}; # figcaption

my $AttrCheckerNotImplemented = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr,
                     type => 'unknown attribute',
                     level => $self->{level}->{uncertain});
};

$Element->{$HTML_NS}->{img} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      align => $EmbeddedAlignChecker,
      alt => sub { }, ## NOTE: No syntactical requirement
      border => sub {
        my ($self, $attr) = @_;

        my $value = $attr->value;
        if ($value eq '0') {
          $self->{onerror}->(node => $attr,
                             type => 'img border:0', # XXXdocumentation
                             level => $self->{level}->{obsconforming});
        } else {
          if ($GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 })->(@_)) {
            ## A non-negative integer.
            $self->{onerror}->(node => $attr,
                               type => 'img border:nninteger', # XXX documentation
                               level => $self->{level}->{must});
          } else {
            ## Not a non-negative integer.
          }
        }
      }, # border
      height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
      hspace => $HTMLLengthAttrChecker,
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
      name => $NameAttrChecker,
      src => $HTMLURIAttrChecker,
      usemap => $HTMLUsemapAttrChecker,
      vspace => $HTMLLengthAttrChecker,
      width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    }, {
      %HTMLAttrStatus,
      %HTMLM12NXHTML2CommonAttrStatus,
      align => FEATURE_HTML5_OBSOLETE,
      alt => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
      border => FEATURE_HTML5_LC,
      height => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
      hspace => FEATURE_HTML5_OBSOLETE,
      ismap => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      lang => FEATURE_HTML5_REC,
      longdesc => FEATURE_HTML5_OBSOLETE,
      name => FEATURE_HTML5_OBSOLETE,
      src => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      usemap => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
      vspace => FEATURE_HTML5_OBSOLETE,
      width => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{lowsrc}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{dynsrc}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{longdesc}->{type}->{cite} = 1;
  }, # check_attrs
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    
    $NameAttrCheckEnd->(@_);
    $HTMLEmptyChecker{check_end}->(@_);
  }, # check_end
}; # img

$Element->{$HTML_NS}->{iframe} = {
  %HTMLTextChecker, # XXX content model restriction
  status => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $EmbeddedAlignChecker,
    frameborder => $GetHTMLEnumeratedAttrChecker->({
      1 => 1, 0 => 1,
      yes => -1, no => -1,
    }),
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    hspace => $HTMLLengthAttrChecker,
    longdesc => $HTMLURIAttrChecker,
    marginheight => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    marginwidth => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    name => $HTMLBrowsingContextNameAttrChecker,
    sandbox => $GetHTMLUnorderedUniqueSetOfSpaceSeparatedTokensAttrChecker->({
      'allow-same-origin' => 1, 'allow-forms' => 1, 'allow-scripts' => 1,
    }),
    scrolling => $GetHTMLEnumeratedAttrChecker->({
      yes => 1, no => 1, auto => 1,
      on => -1, scroll => -1, off => -1, noscroll => -1,
    }),
    seemless => $GetHTMLBooleanAttrChecker->('seemless'),
    src => $HTMLURIAttrChecker,
    srcdoc => sub {
      my ($self, $attr) = @_;
      
      my $type = $attr->owner_document->manakai_is_html
          ? 'text/x-html-srcdoc' : 'text/xml';
      $self->{onsubdoc}->({s => $attr->value,
                           container_node => $attr,
                           media_type => $type,
                           is_char_string => 1});
    }, # srcdoc
    vspace => $HTMLLengthAttrChecker,
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    frameborder => FEATURE_HTML5_OBSOLETE,
    height => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    #hspace WA1 prose
    id => FEATURE_HTML5_REC,
    longdesc => FEATURE_HTML5_OBSOLETE,
    marginheight => FEATURE_HTML5_OBSOLETE,
    marginwidth => FEATURE_HTML5_OBSOLETE,
    #name => FEATURE_HTML5_WD | FEATURE_M12N10_REC_DEPRECATED,
    name => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    sandbox => FEATURE_HTML5_LC,
    scrolling => FEATURE_HTML5_OBSOLETE,
    seemless => FEATURE_HTML5_LC,
    src => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    srcdoc => FEATURE_HTML5_FD,
    title => FEATURE_HTML5_REC,
    #vspace WA1 prose
    width => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
}; # iframe

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
        align => FEATURE_HTML5_OBSOLETE,
        height => FEATURE_HTML5_LC,
        #hspace WA1 prose
        name => FEATURE_HTML5_OBSOLETE,
        src => FEATURE_HTML5_WD,
        type => FEATURE_HTML5_WD,
        width => FEATURE_HTML5_LC,
        #vspace WA1 prose
      }->{$attr_ln};

      if ($attr_ns eq '') {
        if ($attr_ln eq 'src') {
          $checker = $HTMLURIAttrChecker;
          $has_src = 1;
        } elsif ($attr_ln eq 'type') {
          $checker = $MIMETypeChecker;
        } elsif ($attr_ln eq 'width' or $attr_ln eq 'height') {
          $checker = $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 });
        } elsif ($attr_ln eq 'hspace' or $attr_ln eq 'vspace') {
          $checker = $HTMLLengthAttrChecker;
        } elsif ($attr_ln eq 'align') {
          $checker = $EmbeddedAlignChecker;
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          ## XML-compatible + no uppercase letter
          $checker = $HTMLDatasetAttrChecker;
          $status = $HTMLDatasetAttrStatus;
        } elsif ($attr_ln !~ /^xml/ and
                 $attr_ln !~ /[A-Z]/ and
                 $attr_ln =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
          ## XML-compatible + no uppercase letter
          $checker = $HTMLAttrChecker->{$attr_ln}
            || sub { }; ## NOTE: Any local attribute is ok.
          $status = FEATURE_HTML5_WD | FEATURE_ALLOWED;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      $status = $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''}
              unless defined $status;
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
  },
};

$Element->{$HTML_NS}->{noembed} = {
  %HTMLTextChecker, # XXX content model restriction
  status => FEATURE_HTML5_OBSOLETE,
}; # noembed

$Element->{$HTML_NS}->{object} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $EmbeddedAlignChecker,
    archive => $HTMLSpaceURIsAttrChecker,
        ## TODO: Relative to @codebase
    border => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    classid => $HTMLURIAttrChecker,
    codebase => $HTMLURIAttrChecker,
    codetype => $MIMETypeChecker,
        ## TODO: "RECOMMENDED when |classid| is specified" [HTML4]
    data => $HTMLURIAttrChecker,
    declare => $GetHTMLBooleanAttrChecker->('declare'),
        ## NOTE: "The object MUST be instantiated by a subsequent OBJECT ..."
        ## [HTML4] but we don't know how to test this.
    form => $HTMLFormAttrChecker,
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    hspace => $HTMLLengthAttrChecker,
    name => $HTMLBrowsingContextNameAttrChecker,
        ## NOTE: |name| attribute of the |object| element defines
        ## the name of the browsing context created by the element,
        ## if any, but is also used as the form control name of the
        ## form control provided by the plugin, if any.
    standby => sub {}, ## NOTE: %Text; in HTML4
    type => $MIMETypeChecker,
    usemap => $HTMLUsemapAttrChecker,
    vspace => $HTMLLengthAttrChecker,
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    archive => FEATURE_HTML5_OBSOLETE,
    border => FEATURE_HTML5_OBSOLETE,
    classid => FEATURE_HTML5_OBSOLETE,
    code => FEATURE_HTML5_OBSOLETE,
    codebase => FEATURE_HTML5_OBSOLETE,
    codetype => FEATURE_HTML5_OBSOLETE,
    'content-length' => FEATURE_XHTML2_ED,
    data => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    declare => FEATURE_HTML5_OBSOLETE,
    form => FEATURE_HTML5_LC,
    height => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    hspace => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    name => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    standby => FEATURE_HTML5_OBSOLETE,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    usemap => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    vspace => FEATURE_HTML5_OBSOLETE,
    width => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

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
    $element_state->{uri_info}->{archive}->{type}->{resource} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  }, # check_attrs2
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
    
    $NameAttrCheckEnd->(@_); # for <img name>
  },
}; # object
## ISSUE: Is |<menu><object data><li>aa</li></object></menu>| conforming?
## What about |<section><object data><style scoped></style>x</object></section>|?
## |<section><ins></ins><object data><style scoped></style>x</object></section>|?

$Element->{$HTML_NS}->{applet} = {
  %{$Element->{$HTML_NS}->{object}},
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $EmbeddedAlignChecker,
    alt => sub { }, ## CDATA [HTML4]
    archive => $HTMLSpaceURIsAttrChecker, # XXX comma-separated
        ## TODO: Relative to @codebase
    code => sub { }, ## CDATA [HTML4]
    codebase => $HTMLURIAttrChecker,
        ## XXX more restriction [HTML4]
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    hspace => $HTMLLengthAttrChecker,
    name => $NameAttrChecker,
    object => sub {
      my ($self, $attr) = @_;
      ## "Authors should use this feature with extreme caution."
      ## [HTML4]
      $self->{onerror}->(node => $attr,
                         type => 'applet object', # XXX documentation
                         level => $self->{level}->{should});
    },
    vspace => $HTMLLengthAttrChecker,
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    align => FEATURE_XHTML10_REC,
    alt => FEATURE_M12N10_REC_DEPRECATED,
    archive => FEATURE_M12N10_REC_DEPRECATED,
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    code => FEATURE_M12N10_REC_DEPRECATED,
    codebase => FEATURE_M12N10_REC_DEPRECATED,
    height => FEATURE_M12N10_REC_DEPRECATED,
    hspace => FEATURE_XHTML10_REC,
    id => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    name => FEATURE_M12N10_REC_DEPRECATED,
    object => FEATURE_M12N10_REC_DEPRECATED,
    style => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    title => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    vspace => FEATURE_XHTML10_REC,
    width => FEATURE_M12N10_REC_DEPRECATED,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    my $el = $item->{node};

    unless ($el->has_attribute_ns (undef, 'code')) {
      unless ($el->has_attribute_ns (undef, 'object')) {
        $self->{onerror}->(node => $el,
                           type => 'attribute missing:code|object', # XXX documentation
                           level => $self->{level}->{must});
      }
    }
    
    for my $attr_name (qw(width height alt)) {
      ## |width| and |height| are REQUIRED according to HTML4.
      ## |alt| is required according to XHTML m12n.
      unless ($el->has_attribute_ns (undef, $attr_name)) {
        $self->{onerror}->(node => $el,
                           type => 'attribute missing',
                           text => $attr_name,
                           level => $self->{level}->{must});
      }
    }

    $element_state->{uri_info}->{data}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{classid}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{codebase}->{type}->{base} = 1;
    $element_state->{uri_info}->{archive}->{type}->{resource} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
  }, # check_attrs2
}; # applet

$Element->{$HTML_NS}->{param} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    name => sub { },
    type => $MIMETypeChecker,
    value => sub { },
    valuetype => $GetHTMLEnumeratedAttrChecker->({
      data => 1, ref => 1, object => 1,
    }),
  }, {
    %HTMLAttrStatus,
    href => FEATURE_RDFA_REC,
    id => FEATURE_HTML5_REC,
    name => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    type => FEATURE_HTML5_OBSOLETE,
    value => FEATURE_HTML5_WD | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valuetype => FEATURE_HTML5_OBSOLETE,
  }), # check_attrs
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
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
  }, # check_attrs2
}; # param

$Element->{$HTML_NS}->{video} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    autobuffer => $GetHTMLBooleanAttrChecker->('autobuffer'),
    autoplay => sub {
      my ($self, $attr) = @_;

      ## "Authors are also encouraged to consider not using the
      ## automatic playback behavior at all" according to HTML5.
      $self->{onerror}->(node => $attr,
                         type => 'attribute not allowed',
                         level => $self->{level}->{warn});

      ## In addition, the |preload| attribute is ignored if the
      ## |autoplay| attribute is specified.

      $GetHTMLBooleanAttrChecker->('autoplay')->(@_);
    },
    controls => $GetHTMLBooleanAttrChecker->('controls'),
    end => sub { },
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    loop => $GetHTMLBooleanAttrChecker->('loop'),
    loopend => sub { },
    loopstart => sub { },
    playcount => sub { },
    poster => $HTMLURIAttrChecker,
    preload => $GetHTMLEnumeratedAttrChecker->({
      'none' => 1, 'metadata' => 1, 'auto' => 1, '' => 1,
    }),
    src => $HTMLURIAttrChecker,
    start => sub { },
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),

    ## NOTE: |start|, |end|, |loopstart|, |loopend|, and |playcount|
    ## attributes has been deleted from the spec before the exact
    ## author requirement is defined.
  }, {
    %HTMLAttrStatus,
    autobuffer => FEATURE_HTML5_DROPPED,
    autoplay => FEATURE_HTML5_LC,
    controls => FEATURE_HTML5_LC,
    end => FEATURE_HTML5_DROPPED,
    height => FEATURE_HTML5_LC,
    loop => FEATURE_HTML5_LC,
    loopend => FEATURE_HTML5_DROPPED,
    loopstart => FEATURE_HTML5_DROPPED,
    playcount => FEATURE_HTML5_DROPPED,
    poster => FEATURE_HTML5_LC,
    preload => FEATURE_HTML5_LC,
    src => FEATURE_HTML5_LC,
    start => FEATURE_HTML5_DROPPED,
    width => FEATURE_HTML5_LC,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {
      video => 1, audio => 1,
    }});

    $element_state->{allow_source}
        = not $item->{node}->has_attribute_ns (undef, 'src');
    $element_state->{has_source} ||= $element_state->{allow_source} * -1;
      ## NOTE: It might be set true by |check_element|.

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{poster}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
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
    $self->_remove_minus_elements ($element_state);
    
    if ($element_state->{has_source} == -1) { 
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'source',
                         level => $self->{level}->{must});
    }

    $Element->{$HTML_NS}->{object}->{check_end}->(@_);
  },
}; # video

$Element->{$HTML_NS}->{audio} = {
  %{$Element->{$HTML_NS}->{video}},
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    autobuffer => $GetHTMLBooleanAttrChecker->('autobuffer'),
    autoplay => sub {
      my ($self, $attr) = @_;

      ## "Authors are also encouraged to consider not using the
      ## automatic playback behavior at all" according to HTML5.
      $self->{onerror}->(node => $attr,
                         type => 'attribute not allowed',
                         level => $self->{level}->{warn});

      ## In addition, the |preload| attribute is ignored if the
      ## |autoplay| attribute is specified.

      $GetHTMLBooleanAttrChecker->('autoplay')->(@_);
    },
    controls => $GetHTMLBooleanAttrChecker->('controls'),
    end => sub { },
    loop => $GetHTMLBooleanAttrChecker->('loop'),
    loopend => sub { },
    loopstart => sub { },
    playcount => sub { },
    preload => $GetHTMLEnumeratedAttrChecker->({
      'none' => 1, 'metadata' => 1, 'auto' => 1, '' => 1,
    }),
    src => $HTMLURIAttrChecker,
    start => sub { },

    ## NOTE: |start|, |end|, |loopstart|, |loopend|, and |playcount|
    ## attributes has been deleted from the spec before the exact
    ## author requirement is defined.
  }, {
    %HTMLAttrStatus,
    autobuffer => FEATURE_HTML5_DROPPED,
    autoplay => FEATURE_HTML5_LC,
    controls => FEATURE_HTML5_LC,
    end => FEATURE_HTML5_DROPPED,
    loop => FEATURE_HTML5_LC,
    loopend => FEATURE_HTML5_DROPPED,
    loopstart => FEATURE_HTML5_DROPPED,
    playcount => FEATURE_HTML5_DROPPED,
    preload => FEATURE_HTML5_LC,
    src => FEATURE_HTML5_LC,
    start => FEATURE_HTML5_DROPPED,
  }), # check_attrs
}; # audio

$Element->{$HTML_NS}->{source} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    $GetHTMLAttrsChecker->({
      media => $HTMLMQAttrChecker,
      pixelratio => $PositiveFloatingPointNumberAttrChecker,
      src => $HTMLURIAttrChecker,
      type => $MIMETypeChecker,
    }, {
      %HTMLAttrStatus,
      media => FEATURE_HTML5_LC,
      pixelratio => FEATURE_HTML5_DROPPED,
      src => FEATURE_HTML5_LC,
      type => FEATURE_HTML5_LC,
    })->(@_);
    unless ($item->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'src',
                         level => $self->{level}->{must});
    }

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;

    ## NOTE: The |pixelratio| attribute should have been forbidden
    ## when the parent of the |source| element is an |audio| element,
    ## but the attribute itself has been dropped from the spec.
  },
}; # source

$Element->{$HTML_NS}->{bgsound} = {
  %HTMLEmptyChecker,
  # XXX attirbutes
  status => FEATURE_HTML5_OBSOLETE,
}; # bgsound

$Element->{$HTML_NS}->{canvas} = {
  %HTMLTransparentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }, {
    %HTMLAttrStatus,
    height => FEATURE_HTML5_REC,
    width => FEATURE_HTML5_REC,
  }),

  # Authors MUST provide alternative content (HTML5 revision 2868) -
  # This requirement cannot be checked, since the alternative content
  # might be placed outside of the element.
}; # canvas

$Element->{$HTML_NS}->{map} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    my $has_name;
    $GetHTMLAttrsChecker->({
      name => sub {
        my ($self, $attr) = @_;
        my $value = $attr->value;
        my $value_compat = lc $value; ## XXX compatibility caseless match
        if (length $value) {
          if ($value =~ /[\x09\x0A\x0C\x0D\x20]/) {
            $self->{onerror}->(node => $attr, type => 'space in map name',
                               level => $self->{level}->{must}); ## XXX documentation
          }
          
          if ($self->{map_compat}->{$value_compat}) {
            $self->{onerror}->(node => $attr,
                               type => 'duplicate map name', ## XXX TODOC
                               value => $value,
                               level => $self->{level}->{must});
          }
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'empty attribute value',
                             level => $self->{level}->{must});
        }
        $self->{map_exact}->{$value} ||= $attr;
        $self->{map_compat}->{$value_compat} ||= $attr;
        $has_name = [$value, $attr];
      },
    }, {
      %HTMLAttrStatus,
      class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
      dir => FEATURE_HTML5_REC,
      id => FEATURE_HTML5_REC,
      lang => FEATURE_HTML5_REC,
      #name => FEATURE_HTML5_LC | FEATURE_M12N10_REC_DEPRECATED,
      name => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
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
      title => FEATURE_HTML5_REC,
    })->(@_);

    if ($has_name) {
      my $id = $item->{node}->get_attribute_ns (undef, 'id');
      if (defined $id and $has_name->[0] ne $id) {
        $self->{onerror}
            ->(node => $item->{node}->get_attribute_node_ns (undef, 'id'),
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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
  status => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
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
          %HTMLM12NCommonAttrStatus,
          accesskey => FEATURE_M12N10_REC | FEATURE_HTML5_FD,
          alt => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
          coords => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
          href => FEATURE_HTML5_WD | FEATURE_RDFA_REC | FEATURE_M12N10_REC,
          hreflang => FEATURE_HTML5_WD,
          lang => FEATURE_HTML5_REC,
          media => FEATURE_HTML5_WD,
          nohref => FEATURE_HTML5_OBSOLETE,
          onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          ping => FEATURE_HTML5_WD,
          rel => FEATURE_HTML5_WD | FEATURE_RDFA_REC,
          shape => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
          tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
          target => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
          type => FEATURE_HTML5_WD,
        }->{$attr_ln};

        $checker = {
          alt => sub { }, ## Checked later.
          coords => sub { }, ## Checked in $ShapeCoordsChecker
          href => $HTMLURIAttrChecker,
          hreflang => $HTMLLanguageTagAttrChecker,
          media => $HTMLMQAttrChecker,
          nohref => $GetHTMLBooleanAttrChecker->('nohref'),
          ping => $HTMLSpaceURIsAttrChecker,
          rel => sub { $HTMLLinkTypesAttrChecker->(1, $item, @_) },
          shape => $GetHTMLEnumeratedAttrChecker->({
            circ => -1, circle => 1,
            default => 1,
            poly => 1, polygon => -1,
            rect => 1, rectangle => -1,
          }),
          target => $HTMLTargetAttrChecker,
          type => $MIMETypeChecker,
        }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } elsif ($attr_ln =~ /^data-\p{InXMLNCNameChar10}+\z/ and
                 $attr_ln !~ /[A-Z]/) {
          ## XML-compatible + no uppercase letter
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

    $ShapeCoordsChecker->($self, $item, \%attr, 'rectangle');

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

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
}; # area

# ---- Tabular data ----

$Element->{$HTML_NS}->{table} = {
  %HTMLChecker,
  status => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1,
      absmiddle => -1, middle => -1, abscenter => -1,
    }),
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    border => sub {
      my ($self, $attr) = @_;
      ## HTML4 definition: %Pixels; = [0-9]+; with <table border> support.
      unless ($attr->value =~ /\A[0-9]*\z/) {
        $self->{onerror}->(node => $attr,
                           type => 'tableborder:syntax error', # XXXdocumentation
                           level => $self->{level}->{must});
      }
    }, # border
    bordercolor => $HTMLColorAttrChecker,
    cellpadding => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    cellspacing => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    cols => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    datapagesize => sub { }, ## CDATA [HTML4]
    frame => $GetHTMLEnumeratedAttrChecker->({
      void => 1, above => 1, below => 1, hsides => 1, vsides => 1,
      lhs => 1, rhs => 1, box => 1, border => 1,
    }),
    height => $HTMLLengthAttrChecker,
    hspace => $HTMLLengthAttrChecker,
    rules => $GetHTMLEnumeratedAttrChecker->({
      none => 1, groups => 1, rows => 1, cols => 1, all => 1,
    }),
    summary => sub {
      my ($self, $attr) = @_;
      $self->{onerror}->(node => $attr,
                         type => 'table summary', # XXX documentatin
                         level => $self->{level}->{obsconforming});
    },
    vspace => $HTMLLengthAttrChecker,
    width => $HTMLLengthAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    background => FEATURE_HTML5_OBSOLETE,
    bgcolor => FEATURE_HTML5_OBSOLETE,
    border => FEATURE_HTML5_OBSOLETE,
    #bordercolor WA1 prose
    cellpadding => FEATURE_HTML5_OBSOLETE,
    cellspacing => FEATURE_HTML5_OBSOLETE,
    cols => FEATURE_RFC1942,
    datapagesize => FEATURE_M12N10_REC,
    frame => FEATURE_HTML5_OBSOLETE,
    #height WA1 prose
    #hspace WA1 prose
    lang => FEATURE_HTML5_REC,
    rules => FEATURE_HTML5_OBSOLETE,
    summary => FEATURE_HTML5_LC,
    width => FEATURE_HTML5_OBSOLETE,
    #vspace WA1 prose
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'before caption';

    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
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
        $item->{parent_state}->{table_caption_element} = $child_el;
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

    require Whatpm::HTML::Table;
    my $table = Whatpm::HTML::Table->form_table ($item->{node}, sub {
      $self->{onerror}->(@_);
    }, $self->{level});

    my @headers_cell;
    for my $x (0..$#{$table->{cell}}) {
      for my $y (0..$#{$table->{cell}->[$x]}) {
        my $cell = $table->{cell}->[$x]->[$y] or next;
        $cell = $cell->[0];
        next unless $cell->{x} == $x;
        next unless $cell->{y} == $y;

        push @headers_cell, $cell if $cell->{header_ids};
      }
    }

    my @id;
    for my $headers_cell (@headers_cell) {
      my $headers_attr = $headers_cell->{element}->get_attribute_node_ns
          (undef, 'headers');
      my %word;
      for my $word (@{$headers_cell->{header_ids}}) {
        unless ($word{$word}) {
          my $referenced_cell = $table->{id_cell}->{$word};
          if ($referenced_cell) {
            if ($referenced_cell->{element}->manakai_local_name eq 'th') {
              push @id, $word;
            } else {
              $self->{onerror}->(node => $headers_attr,
                                 value => $word,
                                 type => 'not th', # XXXdocumentation
                                 level => $self->{level}->{must});
            }
          } else {
            $self->{onerror}->(node => $headers_attr,
                               value => $word,
                               type => 'no referenced header cell', # XXXdocumentation
                               level => $self->{level}->{must});
          }
          $word{$word} = 1;
        } else {
          $self->{onerror}->(node => $headers_attr,
                             value => $word,
                             type => 'duplicate token',
                             level => $self->{level}->{must});
        }
      }

      my %checked_id;
      while (@id) {
        my $id = shift @id;
        next if $checked_id{$id};
        my $referenced_cell = $table->{id_cell}->{$id};
        if ($referenced_cell->{element} eq $headers_cell->{element}) {
          $self->{onerror}->(node => $headers_attr,
                             type => 'self targeted', # XXXdocumentation
                             level => $self->{level}->{must});
          last;
        }
        push @id, @{$referenced_cell->{header_ids} or []};
        $checked_id{$id} = 1;
      }
    } # $headers_cell

    push @{$self->{return}->{table}}, $table;

    $HTMLChecker{check_end}->(@_);
  }, # check_end
}; # table

$Element->{$HTML_NS}->{caption} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      top => 1, bottom => 1, left => 1, right => 1,
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {table => 1}});

    $HTMLFlowContentChecker{check_start}->(@_);
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    FIGURE: {
      my $caption = $item->{node};
      
      my $table = $caption->parent_node or last FIGURE;
      last FIGURE if $table->node_type != 1;
      my $nsurl = $table->namespace_uri;
      last FIGURE if not defined $nsurl or $nsurl ne $HTML_NS;
      last FIGURE if $table->manakai_local_name ne 'table';

      my $dd = $table->parent_node or last FIGURE;
      last FIGURE if $dd->node_type != 1;
      $nsurl = $dd->namespace_uri;
      last FIGURE if not defined $nsurl or $nsurl ne $HTML_NS;
      last FIGURE if $dd->manakai_local_name ne 'dd';

      my $figure = $dd->parent_node or last FIGURE;
      last FIGURE if $figure->node_type != 1;
      $nsurl = $figure->namespace_uri;
      last FIGURE if not defined $nsurl or $nsurl ne $HTML_NS;
      last FIGURE if $figure->manakai_local_name ne 'figure';

      my @table;
      for my $node (@{$dd->child_nodes}) {
        my $nt = $node->node_type;
        if ($nt == 1) { # Element
          $nsurl = $node->namespace_uri;
          last FIGURE if not defined $nsurl or $nsurl ne $HTML_NS;
          last FIGURE if $node->manakai_local_name ne 'table';

          push @table, $node;
        } elsif ($nt == 3 or $nt == 4) { # Text / CDATASection
          last FIGURE if $node->data =~ /[^\x09\x0A\x0C\x0D\x20]/;
        }
      }

      last FIGURE if @table != 1;

      $self->{onerror}->(node => $caption,
                         type => 'element not allowed:figure table caption', ## XXX documentation
                         level => $self->{level}->{must});
    } # FIGURE

    $HTMLFlowContentChecker{check_end}->(@_);
  },
}; # caption

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
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    width => $MultiLengthChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_M12N10_REC,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
    span => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
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
      if ($item->{node}->has_attribute_ns (undef, 'span')) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:colgroup', # XXXdocumentation
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:colgroup', # XXXdocumentation
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed:colgroup', # XXXdocumentation
                         level => $self->{level}->{must});
    }
  },
}; # colgroup

$Element->{$HTML_NS}->{col} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    width => $HTMLLengthAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    char => FEATURE_HTML5_OBSOLETE,
    charoff => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    span => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valign => FEATURE_HTML5_OBSOLETE,
    width => FEATURE_HTML5_OBSOLETE,
  }),
}; # col

$Element->{$HTML_NS}->{tbody} = {
  %HTMLChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    %cellalign,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    background => FEATURE_HTML5_OBSOLETE,
    #bgcolor WA1 prose
    char => FEATURE_HTML5_OBSOLETE,
    charoff => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    valign => FEATURE_HTML5_OBSOLETE,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
  }, # check_attrs2
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
}; # tbody

$Element->{$HTML_NS}->{thead} = {
  %{$Element->{$HTML_NS}->{tbody}},
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{in_thead} = 1;

    $HTMLChecker{check_start}->(@_);
  }, # check_start
}; # thead

$Element->{$HTML_NS}->{tfoot} = {
  %{$Element->{$HTML_NS}->{tbody}},
};

$Element->{$HTML_NS}->{tr} = {
  %HTMLChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    height => $HTMLLengthAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    align => FEATURE_HTML5_OBSOLETE,
    background => FEATURE_HTML5_OBSOLETE,
    bgcolor => FEATURE_HTML5_OBSOLETE,
    char => FEATURE_HTML5_OBSOLETE,
    charoff => FEATURE_HTML5_OBSOLETE,
    #height WA1 prose
    lang => FEATURE_HTML5_REC,
    valign => FEATURE_HTML5_OBSOLETE,
  }), # check_attrs
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
  }, # check_attrs2
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
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'td') {
      if ($item->{parent_state}->{in_thead}) {
        $self->{onerror}->(node => $child_el, # XXX document the error type
                           type => 'element not allowed:thead td',
                           level => $self->{level}->{must});
      }
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'th') {
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
}; # tr

$Element->{$HTML_NS}->{td} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    abbr => sub {}, ## NOTE: HTML4 %Text; and SHOULD be short.
    axis => sub {}, ## NOTE: HTML4 "cdata", comma-separated
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    headers => sub {
      ## NOTE: Will be checked as part of |table| element checker.
      ## Although the conformance of |headers| attribute is not
      ## checked if the element does not form a part of a table, the
      ## element is non-conforming in that case anyway.
    },
    height => $HTMLLengthAttrChecker,
    nowrap => $GetHTMLBooleanAttrChecker->('nowrap'),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
    width => $HTMLLengthAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    abbr => FEATURE_HTML5_OBSOLETE,
    align => FEATURE_HTML5_OBSOLETE,
    axis => FEATURE_HTML5_OBSOLETE,
    background => FEATURE_HTML5_OBSOLETE,
    bgcolor => FEATURE_HTML5_OBSOLETE,
    char => FEATURE_HTML5_OBSOLETE,
    charoff => FEATURE_HTML5_OBSOLETE,
    colspan => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    headers => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    height => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    nowrap => FEATURE_HTML5_OBSOLETE,
    rowspan => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    scope => FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    valign => FEATURE_HTML5_OBSOLETE,
    width => FEATURE_HTML5_OBSOLETE,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
  }, # check_attrs2
}; # td

$Element->{$HTML_NS}->{th} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    %cellalign,
    abbr => sub {}, ## NOTE: HTML4 %Text; and SHOULD be short.
    axis => sub {}, ## NOTE: HTML4 "cdata", comma-separated
    background => $HTMLURIAttrChecker,
    bgcolor => $HTMLColorAttrChecker,
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    headers => sub {
      ## NOTE: Will be checked as part of |table| element checker.
      ## Although the conformance of |headers| attribute is not
      ## checked if the element does not form a part of a table, the
      ## element is non-conforming in that case anyway.
    },
    height => $HTMLLengthAttrChecker,
    nowrap => $GetHTMLBooleanAttrChecker->('nowrap'),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
    width => $HTMLLengthAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    abbr => FEATURE_HTML5_OBSOLETE,
    align => FEATURE_HTML5_OBSOLETE,
    axis => FEATURE_HTML5_OBSOLETE,
    background => FEATURE_HTML5_OBSOLETE,
    bgcolor => FEATURE_HTML5_OBSOLETE,
    char => FEATURE_M12N10_REC,
    charoff => FEATURE_HTML5_OBSOLETE,
    colspan => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    headers => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    height => FEATURE_HTML5_OBSOLETE,
    lang => FEATURE_HTML5_REC,
    nowrap => FEATURE_HTML5_OBSOLETE,
    rowspan => FEATURE_HTML5_LC | FEATURE_XHTML2_ED | FEATURE_M12N10_REC,
    scope => FEATURE_HTML5_REC,
    valign => FEATURE_HTML5_OBSOLETE,
    width => FEATURE_HTML5_OBSOLETE,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{background}->{type}->{embedded} = 1;
  }, # check_attrs2
}; # th

# ---- Forms ----

$Element->{$HTML_NS}->{form} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_WD | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => $AcceptAttrChecker,
    'accept-charset' => $HTMLCharsetsAttrChecker,
    action => $HTMLURIAttrChecker, ## TODO: Warn if submission is not defined for the scheme
    autocomplete => $GetHTMLEnumeratedAttrChecker->({
      on => 1, off => 1,
    }),
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
    enctype => $GetHTMLEnumeratedAttrChecker->({
      'application/x-www-form-urlencoded' => 1,
      'multipart/form-data' => 1,
      'text/plain' => 1,
    }),
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
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
    novalidate => $GetHTMLBooleanAttrChecker->('novalidate'),
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
    onreceived => $HTMLEventHandlerAttrChecker,
    replace => $GetHTMLEnumeratedAttrChecker->({document => 1, values => 1}),
    target => $HTMLTargetAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_HTML5_DROPPED | FEATURE_WF2X | FEATURE_M12N10_REC,
    'accept-charset' => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    action => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    autocomplete => FEATURE_HTML5_WD,
    data => FEATURE_WF2,
    enctype => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
    method => FEATURE_HTML5_DEFAULT | FEATURE_WF2X | FEATURE_M12N10_REC,
    #name => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC_DEPRECATED,
    name => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
    novalidate => FEATURE_HTML5_LC,
    onreceived => FEATURE_WF2,
    onreset => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onsubmit => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    replace => FEATURE_WF2,
    target => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {form => 1}});

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
}; # form

$Element->{$HTML_NS}->{fieldset} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_WD | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    form => $HTMLFormAttrChecker,
    name => $FormControlNameAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_HTML5_WD | FEATURE_WF2X,
    form => FEATURE_HTML5_LC | FEATURE_WF2X,
    lang => FEATURE_HTML5_REC,
    name => FEATURE_HTML5_LC,
  }),
  ## NOTE: legend?, Flow
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
                           type => 'element not allowed:fieldset legend', # XXXdocumentation
                           level => $self->{level}->{must});
      }
      $element_state->{has_legend} = 1;
      $element_state->{has_non_legend} = 1;
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
      $element_state->{has_non_legend} = 1 unless $child_is_transparent;
      ## TODO:
      ## |<fieldset><object><legend>xx</legend></object>..</fieldset>|
      ## should raise an error.
    }
  }, # check_child_element
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{has_non_legend} = 1;
    }
  }, # check_child_text
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## ISSUE: |<fieldset><legend>aa</legend></fieldset>| error?

    $HTMLFlowContentChecker{check_end}->(@_);
  }, # check_end
}; # fieldset

$Element->{$HTML_NS}->{legend} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1,
    }),
    form => $HTMLFormAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_HTML5_FD | FEATURE_M12N10_REC,
    align => FEATURE_HTML5_OBSOLETE,
    form => FEATURE_HTML5_DROPPED,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
}; # legend

$Element->{$HTML_NS}->{label} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    for => sub {
      my ($self, $attr) = @_;
      
      ## NOTE: MUST be an ID of a labelable element.
      
      push @{$self->{idref}}, ['labelable', $attr->value, $attr];
    },
    form => $HTMLFormAttrChecker,
  }, {
    %HTMLAttrStatus,
    %HTMLM12NXHTML2CommonAttrStatus,
    accesskey => FEATURE_HTML5_FD | FEATURE_WF2 | FEATURE_M12N10_REC,
    for => FEATURE_HTML5_REC,
    form => FEATURE_HTML5_LC,
    lang => FEATURE_HTML5_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {label => 1}});

    ## If $self->{flag}->{has_label} is true, then there is at least
    ## an ancestor |label| element.

    ## If $self->{flag}->{has_labelable} is equal to 1, then there is
    ## an ancestor |label| element with its |for| attribute specified.
    ## If the value is equal to 2, then there is an ancestor |label|
    ## element with its |for| attribute unspecified but there is an
    ## associated form control element.

    $element_state->{has_label_original} = $self->{flag}->{has_label};
    $element_state->{has_labelable_original} = $self->{flag}->{has_labelable};
    $element_state->{label_for_original} = $self->{flag}->{label_for};

    $self->{flag}->{has_label} = 1;
    $self->{flag}->{has_labelable}
        = $item->{node}->has_attribute_ns (undef, 'for') ? 1 : 0;
    $self->{flag}->{label_for}
        = $item->{node}->get_attribute_ns (undef, 'for');

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
    $self->{flag}->{label_for} = $element_state->{label_for_original};

    ## TODO: Warn if no labelable descendant?  <input type=hidden>?

    $HTMLPhrasingContentChecker{check_end}->(@_);
  },
}; # label

$Element->{$HTML_NS}->{input} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_WD | FEATURE_WF2X | FEATURE_M12N10_REC,
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
         accesskey => FEATURE_M12N10_REC | FEATURE_HTML5_FD,
         action => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
         align => FEATURE_HTML5_OBSOLETE,
         alt => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         autocomplete => FEATURE_HTML5_LC | FEATURE_WF2X,
         autofocus => FEATURE_HTML5_LC | FEATURE_WF2X,
         #border WA1 prose
         checked => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
         disabled => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
         enctype => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
         form => FEATURE_HTML5_LC | FEATURE_WF2X,
         formaction => FEATURE_HTML5_LC,
         formenctype => FEATURE_HTML5_LC,
         formmethod => FEATURE_HTML5_LC,
         formnovalidate => FEATURE_HTML5_LC,
         formtarget => FEATURE_HTML5_LC,
         height => FEATURE_HTML5_LC,
         #hspace WA1 prose
         inputmode => FEATURE_HTML5_DROPPED | FEATURE_WF2X |
             FEATURE_XHTMLBASIC11_CR,
         ismap => FEATURE_M12N10_REC,
         lang => FEATURE_HTML5_REC,
         list => FEATURE_HTML5_LC | FEATURE_WF2X,
         max => FEATURE_HTML5_LC | FEATURE_WF2X,
         maxlength => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
         method => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
         min => FEATURE_HTML5_LC | FEATURE_WF2X,
         multiple => FEATURE_HTML5_LC,
         name => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
         novalidate => FEATURE_HTML5_DROPPED,
         onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         onselect => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         pattern => FEATURE_HTML5_LC | FEATURE_WF2X,
         placeholder => FEATURE_HTML5_LC,
         readonly => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
         replace => FEATURE_WF2,
         required => FEATURE_HTML5_LC | FEATURE_WF2X,
         size => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
         src => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         step => FEATURE_HTML5_LC | FEATURE_WF2X,
         tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
         target => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
         template => FEATURE_HTML5_DROPPED | FEATURE_WF2,
         type => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
         usemap => FEATURE_HTML5_DROPPED | FEATURE_HTML5_OBSOLETE,
         value => FEATURE_HTML5_WD | FEATURE_M12N10_REC,
         #vspace WA1 prose
         width => FEATURE_HTML5_LC,
        }->{$attr_ln};

        $checker =
        {
         ## NOTE: Value of an empty string means that the attribute is only
         ## applicable for a specific set of states.
         accept => '',
         'accept-charset' => $HTMLCharsetsAttrChecker,
             ## It is unclear which |type=""| values this attribute is
             ## applied to in RFC 2070.
         action => '',
         align => '',
         alt => '',
         autocomplete => '',
         autofocus => $AutofocusAttrChecker,
             ## NOTE: <input type=hidden disabled> is not disallowed.
         border => '',
         checked => '',
         disabled => $GetHTMLBooleanAttrChecker->('disabled'),
             ## NOTE: <input type=hidden disabled> is not disallowed.
         enctype => '',
         form => $HTMLFormAttrChecker,
         formaction => '',
         formenctype => '',
         formmethod => '',
         formnovalidate => '',
         formtarget => '',
         height => '',
         hspace => '',
         inputmode => '',
         ismap => '', ## NOTE: "MUST" be type=image [HTML4]
         list => '',
         max => '',
         maxlength => '',
         method => '',
         min => '',
         multiple => '',
         name => $FormControlNameAttrChecker,
         novalidate => '',
         pattern => '',
         placeholder => '',
         readonly => '',
         replace => '',
         required => '',
         size => '',
         src => '',
         step => '',
         target => '',
         template => '',
         type => $GetHTMLEnumeratedAttrChecker->({
           hidden => 1, text => 1, search => 1, url => 1,
           tel => 1, email => 1, password => 1,
           datetime => 1, date => 1, month => 1, week => 1, time => 1,
           'datetime-local' => 1, number => 1, range => 1, color => 1,
           checkbox => 1,
           radio => 1, file => 1, submit => 1, image => 1, reset => 1,
           button => 1,
         }),
         usemap => '',
         value => '',
         vspace => '',
         width => '',
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
          } elsif ({
                    datetime => 1, date => 1, month => 1, time => 1,
                    week => 1, 'datetime-local' => 1,
                   }->{$state}) {
            my $v = {
              datetime => ['global_date_and_time_string'],
              date => ['date_string'],
              month => ['month_string'],
              week => ['week_string'],
              time => ['time_string'],
              'datetime-local' => ['local_date_and_time_string'],
            }->{$state};
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             list => $ListAttrChecker,
             min => $GetDateTimeAttrChecker->($v->[0]),
             max => $GetDateTimeAttrChecker->($v->[0]),
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => $GetDateTimeAttrChecker->($v->[0]),
            }->{$attr_ln} || $checker;

            ## XXX Maybe it is better to check min <= value <= max
            ## relation is hold for convinience?
          } elsif ($state eq 'number') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             list => $ListAttrChecker,
             max => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
             min => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             step => $StepAttrChecker,
             value => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'range') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             list => $ListAttrChecker,
             max => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
             min => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
             step => $StepAttrChecker,
             value => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'color') {
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             list => $ListAttrChecker,
             value => sub {
               my ($self, $attr) = @_;
               unless ($attr->value =~ /\A#[0-9A-Fa-f]{6}\z/) {
                 $self->{onerror}->(node => $attr,
                                    type => 'scolor:syntax error', ## TODOC: type
                                    level => $self->{level}->{must});
               }
             },
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'checkbox' or $state eq 'radio') {
            $checker = 
            {
             checked => $GetHTMLBooleanAttrChecker->('checked'),
                 ## TODO: tests
             required => $GetHTMLBooleanAttrChecker->('required'),
             value => sub { }, ## NOTE: No restriction.
            }->{$attr_ln} || $checker;
            ## TODO: There MUST be another input type=radio with same
            ## name (Radio state).
            ## ISSUE: There should be exactly one type=radio with checked?
          } elsif ($state eq 'file') {
            $checker =
            {
             accept => $AcceptAttrChecker,
             ## max (default 1) & min (default 0) [WF2]: Dropped by HTML5.
             multiple => $GetHTMLBooleanAttrChecker->('multiple'),
             required => $GetHTMLBooleanAttrChecker->('required'),
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'submit') {
            $checker =
            {
             action => $HTMLURIAttrChecker,
             enctype => $GetHTMLEnumeratedAttrChecker->({
               'application/x-www-form-urlencoded' => 1,
               'multipart/form-data' => 1,
               'text/plain' => 1,
             }),
             formaction => $HTMLURIAttrChecker,
             formenctype => $GetHTMLEnumeratedAttrChecker->({
               'application/x-www-form-urlencoded' => 1,
               'multipart/form-data' => 1,
               'text/plain' => 1,
             }),
             formmethod => $GetHTMLEnumeratedAttrChecker->({
               get => 1, post => 1, put => 1, delete => 1,
             }),
             formnovalidate => $GetHTMLBooleanAttrChecker->('formnovalidate'),
             formtarget => $HTMLTargetAttrChecker,
             method => $GetHTMLEnumeratedAttrChecker->({
               get => 1, post => 1, put => 1, delete => 1,
             }),
             novalidate => $GetHTMLBooleanAttrChecker->('novalidate'),
             replace => $GetHTMLEnumeratedAttrChecker->({
               document => 1, values => 1,
             }),
             target => $HTMLTargetAttrChecker,
             value => sub { }, ## NOTE: No restriction.
            }->{$attr_ln} || $checker;
          } elsif ($state eq 'image') {
            $checker =
            {
             action => $HTMLURIAttrChecker,
             align => $EmbeddedAlignChecker,
             alt => sub {
               my ($self, $attr) = @_;
               my $value = $attr->value;
               unless (length $value) {
                 $self->{onerror}->(node => $attr,
                                    type => 'empty anchor image alt',
                                    level => $self->{level}->{must});
               }
             },
             border => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
             enctype => $GetHTMLEnumeratedAttrChecker->({
               'application/x-www-form-urlencoded' => 1,
               'multipart/form-data' => 1,
               'text/plain' => 1,
             }),
             formaction => $HTMLURIAttrChecker,
             formenctype => $GetHTMLEnumeratedAttrChecker->({
               'application/x-www-form-urlencoded' => 1,
               'multipart/form-data' => 1,
               'text/plain' => 1,
             }),
             formmethod => $GetHTMLEnumeratedAttrChecker->({
               get => 1, post => 1, put => 1, delete => 1,
             }),
             formnovalidate => $GetHTMLBooleanAttrChecker->('formnovalidate'),
             formtarget => $HTMLTargetAttrChecker,
             height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
             hspace => $HTMLLengthAttrChecker,
             ismap => $GetHTMLBooleanAttrChecker->('ismap'),
             method => $GetHTMLEnumeratedAttrChecker->({
               get => 1, post => 1, put => 1, delete => 1,
             }),
             novalidate => $GetHTMLBooleanAttrChecker->('novalidate'),
             replace => $GetHTMLEnumeratedAttrChecker->({
               document => 1, values => 1,
             }),
             src => $HTMLURIAttrChecker,
               ## TODO: There is requirements on the referenced resource.
             target => $HTMLTargetAttrChecker,
             usemap => $HTMLUsemapAttrChecker,
             vspace => $HTMLLengthAttrChecker,
             width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
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
             template => sub { }, # XXXobsvocab
             value => sub { }, ## NOTE: No restriction.
            }->{$attr_ln} || $checker;
          } else { # Text, Search, E-mail, URL, Telephone, Password
            $checker =
            {
             autocomplete => $GetHTMLEnumeratedAttrChecker->({
               on => 1, off => 1,
             }),
             ## TODO: inputmode [WF2]
             list => $ListAttrChecker,
             maxlength => sub {
               my ($self, $attr, $item, $element_state) = @_;

               $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 })->(@_);

               if ($attr->value =~ /^[\x09\x0A\x0C\x0D\x20]*([0-9]+)/) {
                 ## NOTE: Applying the rules for parsing non-negative
                 ## integers results in a number.
                 my $max_allowed_value_length = 0+$1;

                 my $value = $item->{node}->get_attribute_ns (undef, 'value');
                 if (defined $value) {
                   my $codepoint_length = length $value;
                   
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
             pattern => $PatternAttrChecker,
             placeholder => $PlaceholderAttrChecker,
             readonly => $GetHTMLBooleanAttrChecker->('readonly'),
             required => $GetHTMLBooleanAttrChecker->('required'),
             size => $GetHTMLNonNegativeIntegerAttrChecker->(sub {shift > 0}),
             value => sub {
               my ($self, $attr, $item, $element_state) = @_;
               if ($state eq 'url') {
                 ## XXX MUST be absolute IRI.
                 $HTMLURIAttrChecker->(@_);
               } elsif ($state eq 'email') {
                 if ($item->{node}->has_attribute_ns (undef, 'multiple')) {
                   ## A set of comma-separated tokens.
                   my @addr = split /,/, $attr->value, -1;
                   @addr = ('') unless @addr;
                   for (@addr) {
                     s/\A[\x09\x0A\x0C\x0D\x20]+//;
                     s/[\x09\x0A\x0C\x0D\x20]\z//;

                     unless (/\A$ValidEmailAddress\z/o) {
                       $self->{onerror}->(node => $attr,
                                          type => 'email:syntax error', ## TODO: type
                                          value => $_,
                                          level => $self->{level}->{must});
                     } 
                   }
                 } else {
                   unless ($attr->value =~ /\A$ValidEmailAddress\z/) {
                     $self->{onerror}->(node => $attr,
                                        type => 'email:syntax error', ## TODO: type
                                        level => $self->{level}->{must});
                   }
                 }
               } else {
                 if ($attr->value =~ /[\x0D\x0A]/) {
                   $self->{onerror}->(node => $attr,
                                      type => 'newline in value', ## TODO: type
                                      level => $self->{level}->{must});
                 }
               }
             },
            }->{$attr_ln} || $checker;
            $checker = '' if $state eq 'password' and $attr_ln eq 'list';
            $checker = $GetHTMLBooleanAttrChecker->('multiple')
                if $state eq 'email' and $attr_ln eq 'multiple';

            if ($item->{node}->has_attribute_ns (undef, 'pattern') and
                not $item->{node}->has_attribute_ns (undef, 'title')) {
              $self->{onerror}->(node => $item->{node},
                                 type => 'attribute missing',
                                 text => 'title',
                                 level => $self->{level}->{should});
            }
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
          ## XML-compatible + no uppercase letter
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

    ## ISSUE: -0/+0

    if ($state eq 'range') {
      $element_state->{number_value}->{min} ||= 0;
      $element_state->{number_value}->{max} = 100
          unless defined $element_state->{number_value}->{max};
    }

    if (defined $element_state->{date_value}->{min} or
        defined $element_state->{date_value}->{max}) {
      my $min_value = $element_state->{date_value}->{min};
      my $max_value = $element_state->{date_value}->{max};
      my $value_value = $element_state->{date_value}->{value};

      if (defined $min_value and $min_value eq '' and
          (defined $max_value or defined $value_value)) {
        my $min = $item->{node}->get_attribute_node_ns (undef, 'min');
        $self->{onerror}->(node => $min,
                           type => 'date value not supported', ## TODOC: type
                           value => $min->value,
                           level => $self->{level}->{unsupported});
        undef $min_value;
      }
      if (defined $max_value and $max_value eq '' and
          (defined $max_value or defined $value_value)) {
        my $max = $item->{node}->get_attribute_node_ns (undef, 'max');
        $self->{onerror}->(node => $max,
                           type => 'date value not supported', ## TODOC: type
                           value => $max->value,
                           level => $self->{level}->{unsupported});
        undef $max_value;
      }
      if (defined $value_value and $value_value eq '' and
          (defined $max_value or defined $min_value)) {
        my $value = $item->{node}->get_attribute_node_ns (undef, 'value');
        $self->{onerror}->(node => $value,
                           type => 'date value not supported', ## TODOC: type
                           value => $value->value,
                           level => $self->{level}->{unsupported});
        undef $value_value;
      }

      if (defined $min_value and defined $max_value) {
        if ($min_value->to_html5_number > $max_value->to_html5_number) {
          my $max = $item->{node}->get_attribute_node_ns (undef, 'max');
          $self->{onerror}->(node => $max,
                             type => 'max lt min', ## TODOC: type
                             level => $self->{level}->{must});
        }
      }
      
      if (defined $min_value and defined $value_value) {
        if ($min_value->to_html5_number > $value_value->to_html5_number) {
          my $value = $item->{node}->get_attribute_node_ns (undef, 'value');
          $self->{onerror}->(node => $value,
                             type => 'value lt min', ## TODOC: type
                             level => $self->{level}->{warn});
          ## NOTE: Not an error.
        }
      }
      
      if (defined $max_value and defined $value_value) {
        if ($max_value->to_html5_number < $value_value->to_html5_number) {
          my $value = $item->{node}->get_attribute_node_ns (undef, 'value');
          $self->{onerror}->(node => $value,
                             type => 'value gt max', ## TODOC: type
                             level => $self->{level}->{warn});
          ## NOTE: Not an error.
        }
      }
    } elsif (defined $element_state->{number_value}->{min} or
             defined $element_state->{number_value}->{max}) {
      my $min_value = $element_state->{number_value}->{min};
      my $max_value = $element_state->{number_value}->{max};
      my $value_value = $element_state->{number_value}->{value};

      if (defined $min_value and defined $max_value) {
        if ($min_value > $max_value) {
          my $max = $item->{node}->get_attribute_node_ns (undef, 'max');
          $self->{onerror}->(node => $max,
                             type => 'max lt min', ## TODOC: type
                             level => $self->{level}->{must});
        }
      }
      
      if (defined $min_value and defined $value_value) {
        if ($min_value > $value_value) {
          my $value = $item->{node}->get_attribute_node_ns (undef, 'value');
          $self->{onerror}->(node => $value,
                             type => 'value lt min', ## TODOC: type
                             level => $self->{level}->{warn});
          ## NOTE: Not an error.
        }
      }
      
      if (defined $max_value and defined $value_value) {
        if ($max_value < $value_value) {
          my $value = $item->{node}->get_attribute_node_ns (undef, 'value');
          $self->{onerror}->(node => $value,
                             type => 'value gt max', ## TODOC: type
                             level => $self->{level}->{warn});
          ## NOTE: Not an error.
        }
      }
    }
    
    ## TODO: Warn unless value = min * x where x is an integer.
 
    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{formaction}->{type}->{action} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{src}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckStart->($self, $item, $element_state);
  }, # check_start
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckAttrs2->($self, $item, $element_state);
  }, # check_attrs2
}; # input

## XXXresource: Dimension attributes have requirements on width and
## height of referenced resource.

$Element->{$HTML_NS}->{button} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    action => $HTMLURIAttrChecker,
    autofocus => $AutofocusAttrChecker,
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    enctype => $GetHTMLEnumeratedAttrChecker->({
      'application/x-www-form-urlencoded' => 1,
      'multipart/form-data' => 1,
      'text/plain' => 1,
    }),
    form => $HTMLFormAttrChecker,
    formaction => $HTMLURIAttrChecker,
    formenctype => $GetHTMLEnumeratedAttrChecker->({
      'application/x-www-form-urlencoded' => 1,
      'multipart/form-data' => 1,
      'text/plain' => 1,
    }),
    formmethod => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
    formnovalidate => $GetHTMLBooleanAttrChecker->('formnovalidate'),
    formtarget => $HTMLTargetAttrChecker,
    method => $GetHTMLEnumeratedAttrChecker->({
      get => 1, post => 1, put => 1, delete => 1,
    }),
    name => $FormControlNameAttrChecker,
    novalidate => $GetHTMLBooleanAttrChecker->('novalidate'),
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
    }),
    value => sub {}, ## NOTE: No restriction.
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_M12N10_REC | FEATURE_HTML5_FD,
    action => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
    autofocus => FEATURE_HTML5_LC | FEATURE_WF2X,
    disabled => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
    enctype => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
    form => FEATURE_HTML5_LC | FEATURE_WF2X,
    formaction => FEATURE_HTML5_LC,
    formenctype => FEATURE_HTML5_LC,
    formmethod => FEATURE_HTML5_LC,
    formnovalidate => FEATURE_HTML5_LC,
    formtarget => FEATURE_HTML5_LC,
    lang => FEATURE_HTML5_REC,
    method => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
    name => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    novalidate => FEATURE_HTML5_DROPPED,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    replace => FEATURE_WF2,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    target => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
    template => FEATURE_HTML5_DROPPED | FEATURE_WF2,
    type => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    value => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, $HTMLInteractiveContent);
    $FAECheckStart->($self, $item, $element_state);

    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{formaction}->{type}->{action} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckAttrs2->($self, $item, $element_state);

    my $type = $item->{node}->get_attribute_ns (undef, 'type') || '';
    if ($type eq 'reset' or $type eq 'button') {
      for (
        $item->{node}->get_attribute_node_ns (undef, 'formaction'),
        $item->{node}->get_attribute_node_ns (undef, 'formmethod'),
        $item->{node}->get_attribute_node_ns (undef, 'formnovalidate'),
        $item->{node}->get_attribute_node_ns (undef, 'formenctype'),
        $item->{node}->get_attribute_node_ns (undef, 'formtarget'),
      ) {
        next unless $_;
        $self->{onerror}->(node => $_,
                           type => 'attribute not allowed',
                           level => $self->{level}->{must});
      }
    }
  }, # check_attrs2
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLPhrasingContentChecker{check_end}->(@_);
  }, # check_end
}; # button

$Element->{$HTML_NS}->{select} = {
  %HTMLChecker,
  ## ISSUE: HTML5 has no requirement like these:
    ## TODO: author should SELECTED at least one OPTION in non-MULTIPLE case [HTML4].
    ## TODO: more than one OPTION with SELECTED in non-MULTIPLE case is "error" [HTML4]
  status => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
  is_root => 1, ## TODO: SHOULD NOT in application/xhtml+xml [WF2]
  check_attrs => $GetHTMLAttrsChecker->({
    autofocus => $AutofocusAttrChecker,
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
    form => $HTMLFormAttrChecker,
    multiple => $GetHTMLBooleanAttrChecker->('multiple'),
    name => $FormControlNameAttrChecker,
    ## TODO: tests for on*
    onformchange => $HTMLEventHandlerAttrChecker,
    onforminput => $HTMLEventHandlerAttrChecker,
    oninput => $HTMLEventHandlerAttrChecker,
    oninvalid => $HTMLEventHandlerAttrChecker,
    size => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accesskey => FEATURE_HTML5_FD | FEATURE_WF2,
    autofocus => FEATURE_HTML5_LC | FEATURE_WF2X,
    data => FEATURE_WF2,
    disabled => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
    form => FEATURE_HTML5_LC | FEATURE_WF2X,
    lang => FEATURE_HTML5_REC,
    multiple => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    name => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    size => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckStart->($self, $item, $element_state);

    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckAttrs2->($self, $item, $element_state);
  }, # check_attrs2
  check_child_element => sub {
    ## NOTE: (option | optgroup)*

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
  status => FEATURE_HTML5_LC | FEATURE_WF2X,
  check_attrs => $GetHTMLAttrsChecker->({
    data => $HTMLURIAttrChecker, ## TODO: MUST point ... [WF2]
  }, {
    %HTMLAttrStatus,
    data => FEATURE_WF2,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{phase} = 'any'; # any | phrasing | option

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;

    $element_state->{id_type} = 'datalist';
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
  status => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    label => sub {},
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
    label => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
  }),
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    
    unless ($item->{node}->has_attribute_ns (undef, 'label')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'label',
                         level => $self->{level}->{must});
    }
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
  status => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    label => sub {}, ## NOTE: No restriction.
    selected => $GetHTMLBooleanAttrChecker->('selected'), ## ISSUE: Not a "boolean attribute"
    value => sub {}, ## NOTE: No restriction.
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    disabled => FEATURE_HTML5_LC | FEATURE_WF2X |  FEATURE_M12N10_REC,
    label => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    lang => FEATURE_HTML5_REC,
    selected => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    value => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
  }),
};

$Element->{$HTML_NS}->{textarea} = {
  %HTMLTextChecker,
  status => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
  check_attrs => $GetHTMLAttrsChecker->({
    accept => sub {
      my ($self, $attr) = @_;

      my $type = $MIMETypeChecker->(@_);
      if ($type) {
        unless ($type->is_text_based) {
          $self->{onerror}->(node => $attr,
                             type => 'IMT:not text-based', # XXXdocumentation
                             level => $self->{level}->{must});
        }
      }
    }, # accept
    'accept-charset' => $HTMLCharsetsAttrChecker,
    autofocus => $AutofocusAttrChecker,
    cols => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    form => $HTMLFormAttrChecker,
    ## TODO: inputmode [WF2]
    maxlength => sub {
      my ($self, $attr, $item, $element_state) = @_;
      
      $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 })->(@_);
      
      if ($attr->value =~ /^[\x09\x0A\x0C\x0D\x20]*([0-9]+)/) {
        ## NOTE: Applying the rules for parsing non-negative integers
        ## results in a number.
        my $max_allowed_value_length = 0+$1;

        ## ISSUE: "The the purposes of this requirement," (typo)
        
        ## ISSUE: This constraint is applied w/o CRLF normalization to
        ## |value| attribute, but w/ CRLF normalization to
        ## concept-value.
        my $value = $item->{node}->text_content;
        if (defined $value) {
          my $codepoint_length = length $value;
          
          if ($codepoint_length > $max_allowed_value_length) {
            $self->{onerror}->(node => $item->{node},
                               type => 'value too long',
                               level => $self->{level}->{must});
          }
        }
      }
    },
    name => $FormControlNameAttrChecker,
    pattern => $PatternAttrChecker,
    placeholder => $PlaceholderAttrChecker,
    readonly => $GetHTMLBooleanAttrChecker->('readonly'),
    required => $GetHTMLBooleanAttrChecker->('required'),
    rows => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    wrap => $GetHTMLEnumeratedAttrChecker->({
      soft => 1, hard => 1,
      ## |off| affects rendering, but it is not a keyword according to
      ## Web Applications 1.0.
    }),
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    accept => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
    'accept-charset' => FEATURE_HTML2X_RFC,
    accesskey => FEATURE_HTML5_FD | FEATURE_M12N10_REC,
    autofocus => FEATURE_HTML5_LC | FEATURE_WF2X,
    cols => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    disabled => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
    form => FEATURE_HTML5_LC | FEATURE_WF2X,
    inputmode => FEATURE_HTML5_DROPPED | FEATURE_WF2X | FEATURE_XHTMLBASIC11_CR,
    lang => FEATURE_HTML5_REC,
    maxlength => FEATURE_HTML5_DEFAULT | FEATURE_WF2X,
    name => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    onblur => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onchange => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onfocus => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    onselect => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    pattern => FEATURE_HTML5_DROPPED | FEATURE_WF2X,
    placeholder => FEATURE_HTML5_LC,
    readonly => FEATURE_HTML5_LC | FEATURE_WF2X | FEATURE_M12N10_REC,
    required => FEATURE_HTML5_LC | FEATURE_WF2X,
    rows => FEATURE_HTML5_LC | FEATURE_M12N10_REC, 
    tabindex => FEATURE_HTML5_DEFAULT | FEATURE_M12N10_REC,
    wrap => FEATURE_HTML5_LC | FEATURE_WF2X,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckStart->($self, $item, $element_state);
    
    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{data}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    if ($item->{node}->has_attribute_ns (undef, 'pattern') and
        not $item->{node}->has_attribute_ns (undef, 'title')) {
      ## NOTE: WF2 (dropped by HTML5)
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'title',
                         level => $self->{level}->{should});
    }
    
    unless ($item->{node}->has_attribute_ns (undef, 'cols')) {
      my $wrap = $item->{node}->get_attribute_ns (undef, 'wrap');
      if (defined $wrap) {
        $wrap =~ tr/A-Z/a-z/; ## ASCII case-insensitive
        if ($wrap eq 'hard') {
          $self->{onerror}->(node => $item->{node},
                             type => 'attribute missing',
                             text => 'cols',
                             level => $self->{level}->{must});
        }
      }
    }
    
    $FAECheckAttrs2->($self, $item, $element_state);
  }, # check_attrs2
}; # textarea

$Element->{$HTML_NS}->{keygen} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_FD,
  check_attrs => $GetHTMLAttrsChecker->({
    autofocus => $AutofocusAttrChecker,
    challenge => sub { }, ## No constraints.
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    form => $HTMLFormAttrChecker,
    keytype => $GetHTMLEnumeratedAttrChecker->({rsa => 1}),
    name => $FormControlNameAttrChecker,
  }, {
    %HTMLAttrStatus,
    autofocus => FEATURE_HTML5_LC,
    challenge => FEATURE_HTML5_FD,
    disabled => FEATURE_HTML5_LC,
    form => FEATURE_HTML5_LC,
    keytype => FEATURE_HTML5_FD,
    name => FEATURE_HTML5_LC,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckStart->($self, $item, $element_state);

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;
    $FAECheckAttrs2->($self, $item, $element_state);
  }, # check_attrs2
}; # keygen

$Element->{$HTML_NS}->{output} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC | FEATURE_WF2X,
  check_attrs => $GetHTMLAttrsChecker->({
    for => sub {
      my ($self, $attr) = @_;
      
      ## NOTE: "Unordered set of unique space-separated tokens".
      
      my %word;
      for my $word (grep {length $_}
                    split /[\x09\x0A\x0C\x0D\x20]+/, $attr->value) {
        unless ($word{$word}) {
          $word{$word} = 1;
          push @{$self->{idref}}, ['any', $word, $attr];
        } else {
          $self->{onerror}->(node => $attr, type => 'duplicate token',
                             value => $word,
                             level => $self->{level}->{must});
        }
      }
    },
    form => $HTMLFormAttrChecker,
    name => $FormControlNameAttrChecker,
  }, {
    %HTMLAttrStatus,
    for => FEATURE_HTML5_LC | FEATURE_WF2X,
    form => FEATURE_HTML5_LC | FEATURE_WF2X,
    name => FEATURE_HTML5_LC | FEATURE_WF2X,
  }),
}; # output

# XXX labelable
$Element->{$HTML_NS}->{progress} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    form => $HTMLFormAttrChecker,
    max => sub { }, ## checked in |check_attrs2|
    value => sub { }, ## checked in |check_attrs2|
  }, {
    %HTMLAttrStatus,
    form => FEATURE_HTML5_LC,
    max => FEATURE_HTML5_LC,
    value => FEATURE_HTML5_LC,
  }), # check_attrs
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    my $max = 1;
    my $max_attr = $item->{node}->get_attribute_node_ns (undef, 'max');
    if ($max_attr) {
      $GetHTMLFloatingPointNumberAttrChecker->(sub {
        my $num = $_[0];
        $max = $num;
        return $num > 0; ## >, not >=
      })->($self, $max_attr);
    }

    my $value_attr = $item->{node}->get_attribute_node_ns (undef, 'value');
    if ($value_attr) {
      $GetHTMLFloatingPointNumberAttrChecker->(sub {
        my $num = $_[0];

        unless ($num <= $max) {
          $self->{onerror}->(node => $value_attr,
                             type => 'progress value out of range',
                             value => $max, # XXX document error type
                             level => $self->{level}->{must});
        }
        
        return $num >= 0; ## >=, not >
      })->($self, $value_attr);
    }
  }, # check_attrs2
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {progress => 1}});

    $HTMLPhrasingContentChecker{check_start}->(@_);
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLPhrasingContentChecker{check_end}->(@_);
  }, # check_end

  ## XXX "Authors are encouraged ... text inside the element" - Add a
  ## note in significant text warning's documentation.
}; # progress

## XXX labelable element
$Element->{$HTML_NS}->{meter} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    form => $HTMLFormAttrChecker,
    high => sub { 1 }, ## checked in |check_attrs2|
    low => sub { 1 }, ## checked in |check_attrs2|
    max => sub { 1 }, ## checked in |check_attrs2|
    min => sub { 1 }, ## checked in |check_attrs2|
    optimum => sub { 1 }, ## checked in |check_attrs2|
    value => sub { 1 }, ## checked in |check_attrs2|
  }, {
    %HTMLAttrStatus,
    form => FEATURE_HTML5_LC,
    high => FEATURE_HTML5_LC,
    low => FEATURE_HTML5_LC,
    max => FEATURE_HTML5_LC,
    min => FEATURE_HTML5_LC,
    optimum => FEATURE_HTML5_LC,
    value => FEATURE_HTML5_LC,
  }), # check_attrs
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    my %attr;
    my %value = (
        min => 0,
        max => 1,
        value => 0,
    );
    for my $attr_name (qw(high low max min optimum value)) {
      $attr{$attr_name} = $item->{node}->get_attribute_node_ns
          (undef, $attr_name);
      if ($attr{$attr_name}) {
        $GetHTMLFloatingPointNumberAttrChecker->(sub {
          $value{$attr_name} = $_[0];
          return 1;
        })->($self, $attr{$attr_name});
      }
    }
    
    unless ($attr{value}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'value',
                         level => $self->{level}->{must});
    }

    $value{low} = $value{min} unless defined $value{low};
    $value{high} = $value{max} unless defined $value{high};
    $value{optimum} = ($value{min} + $value{max}) / 2
        unless defined $value{optimum};
    
    for my $attr_name (qw(value low high optimum)) {
      next unless $attr{$attr_name};

      unless ($value{min} <= $value{$attr_name}) {
        $self->{onerror}->(node => $attr{$attr_name},
                           type => 'meter:out of range:min',
                           text => $attr_name,
                           value => $value{min},
                           level => $self->{level}->{must});
      }
      
      unless ($value{$attr_name} <= $value{max}) {
        $self->{onerror}->(node => $attr{$attr_name},
                           type => 'meter:out of range:max',
                           text => $attr_name,
                           value => $value{max},
                           level => $self->{level}->{must});
      }
    }

    if ($attr{low} and $attr{high}) {
      unless ($value{low} <= $value{high}) {
        $self->{onerror}->(node => $attr{low},
                           type => 'meter:out of range:high',
                           value => $value{high},
                           level => $self->{level}->{must});
      }
    }

 }, # check_attrs2
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, {$HTML_NS => {meter => 1}});

    $HTMLPhrasingContentChecker{check_start}->(@_);
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    $self->_remove_minus_elements ($element_state);

    $HTMLPhrasingContentChecker{check_end}->(@_);
  }, # check_end

  ## XXX "Authors are encouraged ... textual representation" - Add a
  ## note in significant text warning's documentation.
}; # meter

$Element->{$HTML_NS}->{isindex} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    prompt => sub {}, ## NOTE: Text [M12N]
  }, {
    %HTMLAttrStatus,
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    dir => FEATURE_HTML5_REC,
    id => FEATURE_HTML5_REC,
    lang => FEATURE_HTML5_REC,
    prompt => FEATURE_M12N10_REC_DEPRECATED,
    style => FEATURE_HTML5_REC,
    title => FEATURE_HTML5_REC,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{action}->{type}->{action} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  },
}; # isindex

# ---- Interactive elements ----

$Element->{$HTML_NS}->{details} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_LC,
  check_attrs => $GetHTMLAttrsChecker->({
    open => $GetHTMLBooleanAttrChecker->('open'),
  }, {
    %HTMLAttrStatus,
    open => FEATURE_HTML5_LC,
  }),
  ## NOTE: summary, Flow
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
      $element_state->{has_non_summary} = 1;
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'summary') {
      if ($element_state->{has_non_summary}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:details summary', ## XXXdocumentation
                           level => $self->{level}->{must});
      }
      $element_state->{has_summary} = 1;
      $element_state->{has_non_summary} = 1;
    } else {
      $HTMLFlowContentChecker{check_child_element}->(@_);
      $element_state->{has_non_summary} = 1 unless $child_is_transparent;
      ## TODO:
      ## |<details><object><summary>xx</summary></object>..</details>|
      ## should raise an error.
    }
  }, # check_child_element
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $element_state->{has_non_summary} = 1;
    }
  }, # check_child_text
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    unless ($element_state->{has_summary}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing',
                         text => 'summary',
                         level => $self->{level}->{must});
    }

    ## XXX |<details><summary>aaa</summary></details> should not raise
    ## a "no significant content" warnings.

    $HTMLFlowContentChecker{check_end}->(@_);
  }, # check_end
}; # details

$Element->{$HTML_NS}->{summary} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DEFAULT,
}; # summary

$Element->{$HTML_NS}->{datagrid} = {
  %HTMLFlowContentChecker,
  status => FEATURE_HTML5_DROPPED,
  check_attrs => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    multiple => $GetHTMLBooleanAttrChecker->('multiple'),
  }, {
    %HTMLAttrStatus,
    disabled => FEATURE_HTML5_DROPPED,
    multiple => FEATURE_HTML5_DROPPED,
  }), # check_attrs
}; # datagrid

$Element->{$HTML_NS}->{command} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_WD,
  check_attrs => $GetHTMLAttrsChecker->({
    checked => $GetHTMLBooleanAttrChecker->('checked'),
    default => $GetHTMLBooleanAttrChecker->('default'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    icon => $HTMLURIAttrChecker,
    label => sub {
      my ($self, $attr, $item, $element_state) = @_;
      unless (length $attr->value) {
        $self->{onerror}->(node => $attr,
                           type => 'empty command label', # XXX documentation
                           level => $self->{level}->{must});
      }
      $element_state->{has_label} = 1;
    },
    radiogroup => sub { }, ## NOTE: No requirement for the value
    type => $GetHTMLEnumeratedAttrChecker->({
      command => 1, checkbox => 1, radio => 1,
    }),
  }, {
    %HTMLAttrStatus,
    checked => FEATURE_HTML5_WD,
    default => FEATURE_HTML5_DROPPED, # HTML5 revision 3067
    disabled => FEATURE_HTML5_WD,
    icon => FEATURE_HTML5_WD,
    label => FEATURE_HTML5_WD,
    radiogroup => FEATURE_HTML5_WD,
    type => FEATURE_HTML5_WD,
  }), # check_attrs
  check_attrs2 => sub {
    my ($self, $item, $element_state) = @_;

    my $type = $item->{node}->get_attribute_ns (undef, 'type') || '';
    $type =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
    $type = 'command' unless $type eq 'radio' or $type eq 'checkbox';

    unless ($type eq 'radio') {
      my $rg_attr = $item->{node}->get_attribute_node_ns (undef, 'radiogroup');
      if ($rg_attr) {
        $self->{onerror}->(node => $rg_attr,
                           type => 'attribute not allowed:radiogroup',
                           level => $self->{level}->{must});
      }
    }

    unless ($type eq 'checkbox' or $type eq 'radio') {
      my $cd_attr = $item->{node}->get_attribute_node_ns (undef, 'checked');
      if ($cd_attr) {
        $self->{onerror}->(node => $cd_attr,
                           type => 'attribute not allowed:checked',
                           level => $self->{level}->{must});
      }
    }

    unless ($type eq 'command') {
      my $def_attr = $item->{node}->get_attribute_node_ns (undef, 'default');
      if ($def_attr) {
        ## HTML5 revision 2415
        $self->{onerror}->(node => $def_attr,
                           type => 'attribute not allowed:default',
                           level => $self->{level}->{must});
      }
    }
  }, # check_attrs2
  check_start => sub {
    my ($self, $item, $element_state) = @_;

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{icon}->{type}->{embedded} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
  }, # check_start
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    
    unless ($element_state->{has_label}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'label',
                         level => $self->{level}->{must});
    }
    
    $HTMLEmptyChecker{check_end}->(@_);
  }, # check_end
}; # command

$Element->{$HTML_NS}->{bb} = {
  %HTMLPhrasingContentChecker,
  status => FEATURE_HTML5_DROPPED,
  check_attrs => $GetHTMLAttrsChecker->({
    type => $GetHTMLEnumeratedAttrChecker->({makeapp => 1}),
  }, {
    %HTMLAttrStatus,
    type => FEATURE_HTML5_DROPPED,
  }),
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->_add_minus_elements ($element_state, $HTMLInteractiveContent);

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
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
    align => $GetHTMLEnumeratedAttrChecker->({
      left => 1, center => 1, right => 1, justify => 1,
    }),
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
    compat => FEATURE_HTML5_OBSOLETE,
    label => FEATURE_HTML5_WD,
    lang => FEATURE_HTML5_REC,
    type => FEATURE_HTML5_WD,
  }), # check_attrs
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{phase} = 'li or phrasing';

    $element_state->{uri_info}->{datasrc}->{type}->{resource} = 1;
    $element_state->{uri_info}->{template}->{type}->{resource} = 1;
    $element_state->{uri_info}->{ref}->{type}->{resource} = 1;
    $element_state->{id_type} = 'menu';
  }, # check_start
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
  }, # check_child_element
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
  }, # check_child_text
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{phase} eq 'li') {
      $HTMLChecker{check_end}->(@_);
    } else { # 'phrasing' or 'li or phrasing'
      $HTMLPhrasingContentChecker{check_end}->(@_);
    }
  }, # check_end
}; # menu

# XXXX device

# ---- Microdata ----

# XXXX

# ---- Frames ----

$Element->{$HTML_NS}->{frameset} = {
  %HTMLChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    bordercolor => $HTMLColorAttrChecker,
    cols => $MultiLengthListChecker,
    onafterprint => $HTMLEventHandlerAttrChecker,
    onbeforeprint => $HTMLEventHandlerAttrChecker,
    onbeforeunload => $HTMLEventHandlerAttrChecker,
    onblur => $HTMLEventHandlerAttrChecker,
    onerror => $HTMLEventHandlerAttrChecker,
    onfocus => $HTMLEventHandlerAttrChecker,
    onhashchange => $HTMLEventHandlerAttrChecker,
    onload => $HTMLEventHandlerAttrChecker,
    onmessage => $HTMLEventHandlerAttrChecker,
    onoffline => $HTMLEventHandlerAttrChecker,
    ononline => $HTMLEventHandlerAttrChecker,
    onpagehide => $HTMLEventHandlerAttrChecker,
    onpageshow => $HTMLEventHandlerAttrChecker,
    onpopstate => $HTMLEventHandlerAttrChecker,
    onredo => $HTMLEventHandlerAttrChecker,
    onresize => $HTMLEventHandlerAttrChecker,
    onstorage => $HTMLEventHandlerAttrChecker,
    onundo => $HTMLEventHandlerAttrChecker,
    onunload => $HTMLEventHandlerAttrChecker,
    rows => $MultiLengthListChecker,
  }, {
    %HTMLAttrStatus,
    #bordercolor WA1 prose
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    cols => FEATURE_M12N10_REC,
    id => FEATURE_HTML5_REC,
    onafterprint => FEATURE_HTML5_OBSOLETE,
    onbeforeprint => FEATURE_HTML5_OBSOLETE,
    onbeforeunload => FEATURE_HTML5_OBSOLETE,
    onblur => FEATURE_HTML5_OBSOLETE,
    onerror => FEATURE_HTML5_OBSOLETE,
    onfocus => FEATURE_HTML5_OBSOLETE,
    onhashchange => FEATURE_HTML5_OBSOLETE,
    onload => FEATURE_HTML5_OBSOLETE,
    onmessage => FEATURE_HTML5_OBSOLETE,
    onoffline => FEATURE_HTML5_OBSOLETE,
    ononline => FEATURE_HTML5_OBSOLETE,
    onpagehide => FEATURE_HTML5_OBSOLETE,
    onpageshow => FEATURE_HTML5_OBSOLETE,
    onpopstate => FEATURE_HTML5_OBSOLETE,
    onredo => FEATURE_HTML5_OBSOLETE,
    onstorage => FEATURE_HTML5_OBSOLETE,
    onundo => FEATURE_HTML5_OBSOLETE,
    onunload => FEATURE_HTML5_OBSOLETE,
    rows => FEATURE_M12N10_REC,
    style => FEATURE_HTML5_REC,
    title => FEATURE_HTML5_REC,
  }), # check_attrs
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
             ($child_ln eq 'frameset' or $child_ln eq 'frame')) {
      $item->{has_frame_or_frameset} = 1;
    } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'noframes') {
      if ($item->{has_noframes}) {
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed',
                           level => $self->{level}->{html4_fact});
      } else {
        $item->{has_noframes} = 1;
      }
    } else {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:frameset', # XXXdocumentation
                         level => $self->{level}->{must});
    }
  }, # check_child_element
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed:frameset', # XXXdocumentation
                         level => $self->{level}->{must});
    }
  }, # check_child_text
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    unless ($item->{has_frame_or_frameset}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:frame|frameset', # XXXdocumentation
                         level => $self->{level}->{must});
    }

    $HTMLChecker{check_end}->(@_);
  }, # check_end
}; # frameset

$Element->{$HTML_NS}->{frame} = {
  %HTMLEmptyChecker,
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    bordercolor => $HTMLColorAttrChecker,
    frameborder => $GetHTMLEnumeratedAttrChecker->({
      1 => 1, 0 => 1,
      yes => -1, no => -1,
    }),
    longdesc => $HTMLURIAttrChecker,
    marginheight => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    marginwidth => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    name => $HTMLBrowsingContextNameAttrChecker,
    noresize => $GetHTMLBooleanAttrChecker->('noresize'),
    scrolling => $GetHTMLEnumeratedAttrChecker->({
      yes => 1, no => 1, auto => 1,
      on => -1, scroll => -1, off => -1, noscroll => -1,
    }),
    src => $HTMLURIAttrChecker,
  }, {
    %HTMLAttrStatus,
    #bordercolor WA1 prose
    class => FEATURE_HTML5_LC | FEATURE_M12N10_REC,
    frameborder => FEATURE_M12N10_REC,
    id => FEATURE_HTML5_REC,
    longdesc => FEATURE_M12N10_REC,
    marginheight => FEATURE_M12N10_REC,
    marginwidth => FEATURE_M12N10_REC,
    name => FEATURE_M12N10_REC,
    noresize => FEATURE_M12N10_REC,
    scrolling => FEATURE_M12N10_REC,
    src => FEATURE_M12N10_REC,
    style => FEATURE_HTML5_REC,
    title => FEATURE_HTML5_REC,
  }), # check_attrs
}; # frame

$Element->{$HTML_NS}->{noframes} = {
  %HTMLTextChecker, # XXX content model restriction
  status => FEATURE_HTML5_OBSOLETE,
  check_attrs => $GetHTMLAttrsChecker->({
    #
  }, {
    %HTMLAttrStatus,
    %HTMLM12NCommonAttrStatus,
    lang => FEATURE_HTML5_REC,
  }), # check_attrs
}; # noframes

## ------ Elements not supported by this module ------

## Following elements are explicitly not supported: abstract, arg,
## changed, cmd, epilogue, footnote, hide, htmlplus, margin, message,
## prologue, quote, removed, render, rev [HTML+], note, fn, banner,
## lh, bodytext, abbrev, au, bq, bt, credit, fig, figtext, person,
## lang, tab, math, above, added, array, atop, bar, below, box, ddot,
## dot, hat, left, of, over, overlay, range, right, root, row, spot,
## sqrt, tilde, vec [HTML30], access [ACCESS], blockcode, standby, nl,
## l, h, separator [XHTML2ED], m, x, t, dc, ds, datatemplate, rule,
## nest, calendar, card, switch, eventsource, sidebar [WA1 draft],
## repeat [WF2 draft], centre, noflames, noframe, textflow, app,
## server, htmlarea, animate, h7, h8, h9, entity, hype, key, tbl,
## audioscope, limittext, nosmartquotes, shadow, sound, noimg,
## element, attrib, csactionitem, csactions, csaction, csscriptdict,
## csactiondict, csobj, madebywz, x-sas-window, yomi, fn-contents,
## module

$Whatpm::ContentChecker::Namespace->{$HTML_NS}->{loaded} = 1;

1;

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
