package Whatpm::ContentChecker;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.96 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Whatpm::URIChecker;

## ISSUE: How XML and XML Namespaces conformance can (or cannot)
## be applied to an in-memory representation (i.e. DOM)?

## TODO: Conformance of an HTML document with non-html root element.

## Stability
sub FEATURE_STATUS_REC () { 0b1 } ## Interoperable standard
sub FEATURE_STATUS_CR () { 0b10 } ## Call for implementation
sub FEATURE_STATUS_LC () { 0b100 } ## Last call for comments
sub FEATURE_STATUS_WD () { 0b1000 } ## Working or editor's draft

## Deprecated
sub FEATURE_DEPRECATED_SHOULD () { 0b100000 } ## SHOULD-level
sub FEATURE_DEPRECATED_INFO () { 0b1000000 } ## Does not affect conformance

## Conformance
sub FEATURE_ALLOWED () { 0b10000 }

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;
my $XML_NS = q<http://www.w3.org/XML/1998/namespace>;
my $XMLNS_NS = q<http://www.w3.org/2000/xmlns/>;

my $Namespace = {
  '' => {loaded => 1},
  q<http://www.w3.org/2005/Atom> => {module => 'Whatpm::ContentChecker::Atom'},
  q<http://purl.org/syndication/history/1.0>
      => {module => 'Whatpm::ContentChecker::Atom'},
  q<http://purl.org/syndication/threading/1.0>
      => {module => 'Whatpm::ContentChecker::Atom'},
  $HTML_NS => {module => 'Whatpm::ContentChecker::HTML'},
  $XML_NS => {loaded => 1},
  $XMLNS_NS => {loaded => 1},
  q<http://www.w3.org/1999/02/22-rdf-syntax-ns#> => {loaded => 1},
};

sub load_ns_module ($) {
  my $nsuri = shift; # namespace URI or ''
  unless ($Namespace->{$nsuri}->{loaded}) {
    if ($Namespace->{$nsuri}->{module}) {
      eval qq{ require $Namespace->{$nsuri}->{module} } or die $@;
    } else {
      $Namespace->{$nsuri}->{loaded} = 1;
    }
  }
} # load_ns_module

our $AttrChecker = {
  $XML_NS => {
    space => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value eq 'default' or $value eq 'preserve') {
        #
      } else {
        ## NOTE: An XML "error"
        $self->{onerror}->(node => $attr, level => $self->{level}->{xml_error},
                           type => 'invalid attribute value');
      }
    },
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

      ## NOTE: "The values of the attribute are language identifiers
      ## as defined by [IETF RFC 3066], Tags for the Identification
      ## of Languages, or its successor; in addition, the empty string
      ## may be specified." ("may" in lower case)
      ## NOTE: Is an RFC 3066-valid (but RFC 4646-invalid) language tag
      ## allowed today?

      ## TODO: test data

      my $nsuri = $attr->owner_element->namespace_uri;
      if (defined $nsuri and $nsuri eq $HTML_NS) {
        my $lang_attr = $attr->owner_element->get_attribute_node_ns
            (undef, 'lang');
        if ($lang_attr) {
          my $lang_attr_value = $lang_attr->value;
          $lang_attr_value =~ tr/A-Z/a-z/; ## ASCII case-insensitive
          my $value = $value;
          $value =~ tr/A-Z/a-z/; ## ASCII case-insensitive
          if ($lang_attr_value ne $value) {
            ## NOTE: HTML5 Section "The |lang| and |xml:lang| attributes"
            $self->{onerror}->(node => $attr,
                               type => 'xml:lang ne lang',
                               level => $self->{level}->{must});
          }
        }
      }

      if ($attr->owner_document->manakai_is_html) { # MUST NOT
        $self->{onerror}->(node => $attr, type => 'in HTML:xml:lang',
                           level => $self->{level}->{must});
## TODO: Test data...
      }
    },
    base => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value =~ /[^\x{0000}-\x{10FFFF}]/) { ## ISSUE: Should we disallow noncharacters?
        $self->{onerror}->(node => $attr,
                           type => 'invalid attribute value',
                           level => $self->{level}->{fact}, ## TODO: correct?
                          );
      }
      ## NOTE: Conformance to URI standard is not checked since there is
      ## no author requirement on conformance in the XML Base specification.
    },
    id => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      $value =~ s/[\x09\x0A\x0D\x20]+/ /g;
      $value =~ s/^\x20//;
      $value =~ s/\x20$//;
      ## TODO: NCName in XML 1.0 or 1.1
      ## TODO: declared type is ID?
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr,
                           type => 'duplicate ID',
                           level => $self->{level}->{xml_id_error});
        push @{$self->{id}->{$value}}, $attr;
      } else {
        $self->{id}->{$value} = [$attr];
      }
    },
  },
  $XMLNS_NS => {
    '' => sub {
      my ($self, $attr) = @_;
      my $ln = $attr->manakai_local_name;
      my $value = $attr->value;
      if ($value eq $XML_NS and $ln ne 'xml') {
        $self->{onerror}
          ->(node => $attr,
             type => 'Reserved Prefixes and Namespace Names:Name',
             text => $value,
             level => $self->{level}->{nc});
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'Reserved Prefixes and Namespace Names:Name',
             text => $value,
             level => $self->{level}->{nc});
      }
      if ($ln eq 'xml' and $value ne $XML_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'Reserved Prefixes and Namespace Names:Prefix',
             text => $ln,
             level => $self->{level}->{nc});
      } elsif ($ln eq 'xmlns') {
        $self->{onerror}
          ->(node => $attr, 
             type => 'Reserved Prefixes and Namespace Names:Prefix',
             text => $ln,
             level => $self->{level}->{nc});
      }
      ## TODO: If XML 1.0 and empty
    },
    xmlns => sub {
      my ($self, $attr) = @_;
      ## TODO: In XML 1.0, URI reference [RFC 3986] or an empty string
      ## TODO: In XML 1.1, IRI reference [RFC 3987] or an empty string
      ## TODO: relative references are deprecated
      my $value = $attr->value;
      if ($value eq $XML_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'Reserved Prefixes and Namespace Names:Name',
             text => $value,
             level => $self->{level}->{nc});
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'Reserved Prefixes and Namespace Names:Name',
             text => $value,
             level => $self->{level}->{nc});
      }
    },
  },
};

## ISSUE: Should we really allow these attributes?
$AttrChecker->{''}->{'xml:space'} = $AttrChecker->{$XML_NS}->{space};
$AttrChecker->{''}->{'xml:lang'} = $AttrChecker->{$XML_NS}->{lang};
    ## NOTE: Checker for (null, "xml:lang") attribute is shadowed for
    ## HTML elements in Whatpm::ContentChecker::HTML.
$AttrChecker->{''}->{'xml:base'} = $AttrChecker->{$XML_NS}->{base};
$AttrChecker->{''}->{'xml:id'} = $AttrChecker->{$XML_NS}->{id};

our $AttrStatus;

for (qw/space lang base id/) {
  $AttrStatus->{$XML_NS}->{$_} = FEATURE_STATUS_REC | FEATURE_ALLOWED;
  $AttrStatus->{''}->{"xml:$_"} = FEATURE_STATUS_REC | FEATURE_ALLOWED;
  ## XML 1.0: FEATURE_STATUS_CR
  ## XML 1.1: FEATURE_STATUS_REC
  ## XML Namespaces 1.0: FEATURE_STATUS_CR
  ## XML Namespaces 1.1: FEATURE_STATUS_REC
  ## XML Base: FEATURE_STATUS_REC
  ## xml:id: FEATURE_STATUS_REC
}

$AttrStatus->{$XMLNS_NS}->{''} = FEATURE_STATUS_REC | FEATURE_ALLOWED;

## TODO: xsi:schemaLocation for XHTML2 support (very, very low priority)

our %AnyChecker = (
  check_start => sub { },
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      if (defined $attr_ns) {
        load_ns_module ($attr_ns);
      } else {
        $attr_ns = '';
      }
      my $attr_ln = $attr->manakai_local_name;
      
      my $checker = $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      my $status = $AttrStatus->{$attr_ns}->{$attr_ln}
          || $AttrStatus->{$attr_ns}->{''};
      if (not defined $status) {
        $status = FEATURE_ALLOWED;
        ## NOTE: FEATURE_ALLOWED for all attributes, since the element
        ## is not supported and therefore "attribute not defined" error
        ## should not raised (too verbose) and global attributes should be
        ## allowed anyway (if a global attribute has its specified creteria
        ## for where it may be specified, then it should be checked in it's
        ## checker function).
      }
      if ($checker) {
        $checker->($self, $attr);
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
      }
      $self->_attr_status_info ($attr, $status);
    }
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      #
    }
  },
  check_child_text => sub { },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    ## NOTE: There is a modified copy of the code below for |html:ruby|.
    if ($element_state->{has_significant}) {
      $item->{real_parent_state}->{has_significant} = 1;
    }    
  },
);

our $ElementDefault = {
  %AnyChecker,
  status => FEATURE_ALLOWED,
      ## NOTE: No "element not defined" error - it is not supported anyway.
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->{onerror}->(node => $item->{node},
                       type => 'unknown element',
                       level => $self->{level}->{uncertain});
  },
};

our $HTMLEmbeddedContent = {
  ## NOTE: All embedded content is also phrasing content.
  $HTML_NS => {
    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,
  },
  q<http://www.w3.org/1998/Math/MathML> => {math => 1},
  q<http://www.w3.org/2000/svg> => {svg => 1},
  ## NOTE: Foreign elements with content (but no metadata) are 
  ## embedded content.
};  

our $IsInHTMLInteractiveContent = sub {
  my ($el, $nsuri, $ln) = @_;

  ## NOTE: This CODE returns whether an element that is conditionally
  ## categorizzed as an interactive content is currently in that
  ## condition or not.  See $HTMLInteractiveContent list defined in
  ## Whatpm::ContentChecler::HTML for the list of all (conditionally
  ## or permanently) interactive content.

  if ($nsuri eq $HTML_NS and ($ln eq 'video' or $ln eq 'audio')) {
    return $el->has_attribute ('controls');
  } elsif ($nsuri eq $HTML_NS and $ln eq 'menu') {
    my $value = $el->get_attribute ('type');
    $value =~ tr/A-Z/a-z/; # ASCII case-insensitive
    return ($value eq 'toolbar');
  } else {
    return 1;
  }
}; # $IsInHTMLInteractiveContent

my $HTMLTransparentElements = {
  $HTML_NS => {qw/ins 1 del 1 font 1 noscript 1 canvas 1 a 1/},
  ## NOTE: |html:noscript| is transparent if scripting is disabled
  ## and not in |head|.
};

my $HTMLSemiTransparentElements = {
  $HTML_NS => {object => 1, video => 1, audio => 1},
};

our $Element = {};

$Element->{q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>}->{RDF} = {
  %AnyChecker,
  status => FEATURE_STATUS_REC | FEATURE_ALLOWED,
  is_root => 1, ## ISSUE: Not explicitly allowed for non application/rdf+xml
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    my $triple = [];
    push @{$self->{return}->{rdf}}, [$item->{node}, $triple];
    require Whatpm::RDFXML;
    my $rdf = Whatpm::RDFXML->new;
    ## TODO: Should we make bnodeid unique in a document?
    $rdf->{onerror} = $self->{onerror};
    $rdf->{level} = $self->{level};
    $rdf->{ontriple} = sub {
      my %opt = @_;
      push @$triple,
          [$opt{node}, $opt{subject}, $opt{predicate}, $opt{object}];
      if (defined $opt{id}) {
        push @$triple,
            [$opt{node},
             $opt{id},
             {uri => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#subject>},
             $opt{subject}];
        push @$triple,
            [$opt{node},
             $opt{id},
             {uri => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate>},
             $opt{predicate}];
        push @$triple,
            [$opt{node},
             $opt{id},
             {uri => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#object>},
             $opt{object}];
        push @$triple,
            [$opt{node},
             $opt{id},
             {uri => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>},
             {uri => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement>}];
      }
    };
    $rdf->convert_rdf_element ($item->{node});
  },
};

my $default_error_level = {
  must => 'm',
  should => 's',
  warn => 'w',
  good => 'w',
  undefined => 'w',
  info => 'i',

  uncertain => 'u',

  html4_fact => 'm',
  html5_no_may => 'm',

  xml_error => 'm', ## TODO: correct?
  xml_id_error => 'm', ## TODO: ?
  nc => 'm', ## XML Namespace Constraints ## TODO: correct?

  ## |Whatpm::URIChecker|
  uri_syntax => 'm',
  uri_fact => 'm',
  uri_lc_must => 'm',
  uri_lc_should => 'w',

  ## |Whatpm::IMTChecker|
  mime_must => 'm', # lowercase "must"
  mime_fact => 'm',
  mime_strongly_discouraged => 'w',
  mime_discouraged => 'w',

  ## |Whatpm::LangTag|
  langtag_fact => 'm',

  ## |Whatpm::RDFXML|
  rdf_fact => 'm',
  rdf_grammer => 'm',
  rdf_lc_must => 'm',

  ## |Message::Charset::Info| and |Whatpm::Charset::DecodeHandle|
  charset_variant => 'm',
    ## An error caused by use of a variant charset that is not conforming
    ## to the original charset (e.g. use of 0x80 in an ISO-8859-1 document
    ## which is interpreted as a Windows-1252 document instead).
  charset_fact => 'm',
  iso_shall => 'm',
};

sub check_document ($$$;$) {
  my ($self, $doc, $onerror, $onsubdoc) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;
  $self->{onsubdoc} = $onsubdoc || sub {
    warn "A subdocument is not conformance-checked";
  };

  $self->{level} ||= $default_error_level;

  ## TODO: If application/rdf+xml, RDF/XML mode should be invoked.

  my $docel = $doc->document_element;
  unless (defined $docel) {
    ## ISSUE: Should we check content of Document node?
    $onerror->(node => $doc, type => 'no document element',
               level => $self->{level}->{must});
    ## ISSUE: Is this non-conforming (to what spec)?  Or just a warning?
    return {
            class => {},
            id => {}, table => [], term => {},
           };
  }

  ## ISSUE: Unexpanded entity references and HTML5 conformance
  
  my $docel_nsuri = $docel->namespace_uri;
  if (defined $docel_nsuri) {
    load_ns_module ($docel_nsuri);
  } else {
    $docel_nsuri = '';
  }
  my $docel_def = $Element->{$docel_nsuri}->{$docel->manakai_local_name} ||
    $Element->{$docel_nsuri}->{''} ||
    $ElementDefault;
  if ($docel_def->{is_root}) {
    #
  } elsif ($docel_def->{is_xml_root}) {
    unless ($doc->manakai_is_html) {
      #
    } else {
      $onerror->(node => $docel, type => 'element not allowed:root:xml',
                 level => $self->{level}->{must});
    }
  } else {
    $onerror->(node => $docel, type => 'element not allowed:root',
               level => $self->{level}->{must});
  }

  ## TODO: Check for other items other than document element
  ## (second (errorous) element, text nodes, PI nodes, doctype nodes)

  my $return = $self->check_element ($docel, $onerror, $onsubdoc);

  ## TODO: Test for these checks are necessary.
  my $charset_name = $doc->input_encoding;
  if (defined $charset_name) {
    require Message::Charset::Info;
    my $charset = $Message::Charset::Info::IANACharset->{$charset_name};

    if ($doc->manakai_is_html) {
      if (not $doc->manakai_has_bom and
          not defined $doc->manakai_charset) {
        unless ($charset->{is_html_ascii_superset}) {
          $onerror->(node => $doc,
                     level => $self->{level}->{must},
                     type => 'non ascii superset',
                     text => $charset_name);
        }
        
        if (not $self->{has_charset} and ## TODO: This does not work now.
            not $charset->{iana_names}->{'us-ascii'}) {
          $onerror->(node => $doc,
                     level => $self->{level}->{must},
                     type => 'no character encoding declaration',
                     text => $charset_name);
        }
      }

      if ($charset->{iana_names}->{'utf-8'}) {
        #
      } elsif ($charset->{iana_names}->{'jis_x0212-1990'} or
               $charset->{iana_names}->{'x-jis0208'} or
               $charset->{iana_names}->{'utf-32'} or ## ISSUE: UTF-32BE? UTF-32LE?
               ($charset->{category} & Message::Charset::Info::CHARSET_CATEGORY_EBCDIC ())) {
        $onerror->(node => $doc,
                   type => 'bad character encoding',
                   text => $charset_name,
                   level => $self->{level}->{should},
                   layer => 'encode');
      } elsif ($charset->{iana_names}->{'cesu-8'} or
               $charset->{iana_names}->{'utf-8'} or ## ISSUE: UNICODE-1-1-UTF-7?
               $charset->{iana_names}->{'bocu-1'} or
               $charset->{iana_names}->{'scsu'}) {
        $onerror->(node => $doc,
                   type => 'disallowed character encoding',
                   text => $charset_name,
                   level => $self->{level}->{must},
                   layer => 'encode');
      } else {
        $onerror->(node => $doc,
                   type => 'non-utf-8 character encoding',
                   text => $charset_name,
                   level => $self->{level}->{good},
                   layer => 'encode');
      }
    }
  } elsif ($doc->manakai_is_html) {
    ## NOTE: MUST and SHOULD requirements above cannot be tested,
    ## since the document has no input charset encoding information.
    $onerror->(node => $doc,
               type => 'character encoding unchecked',
               level => $self->{level}->{info},
               layer => 'encode');
  }

  return $return;
} # check_document

## Check an element.  The element is checked as if it is an orphan node (i.e.
## an element without a parent node).
sub check_element ($$$;$) {
  my ($self, $el, $onerror, $onsubdoc) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;
  $self->{onsubdoc} = $onsubdoc || sub {
    warn "A subdocument is not conformance-checked";
  };

  $self->{level} ||= $default_error_level;

  $self->{plus_elements} = {};
  $self->{minus_elements} = {};
  $self->{id} = {};
  $self->{term} = {};
  $self->{usemap} = [];
  $self->{ref} = []; # datetemplate data references
  $self->{template} = []; # datatemplate template references
  $self->{contextmenu} = [];
  $self->{map} = {};
  $self->{menu} = {};
  $self->{has_link_type} = {};
  $self->{flag} = {};
  #$self->{has_uri_attr};
  #$self->{has_hyperlink_element};
  #$self->{has_charset};
  #$self->{has_base};
  $self->{return} = {
    class => {},
    id => $self->{id},
    table => [], # table objects returned by Whatpm::HTMLTable
    term => $self->{term},
    uri => {}, # URIs other than those in RDF triples
                     ## TODO: xmlns="", SYSTEM "", atom:* src="", xml:base=""
    rdf => [],
  };

  my @item = ({type => 'element', node => $el, parent_state => {}});
  $item[-1]->{real_parent_state} = $item[-1]->{parent_state};
  while (@item) {
    my $item = shift @item;
    if (ref $item eq 'ARRAY') {
      my $code = shift @$item;
next unless $code;## TODO: temp.
      $code->(@$item);
    } elsif ($item->{type} eq 'element') {
      my $el_nsuri = $item->{node}->namespace_uri;
      if (defined $el_nsuri) {
        load_ns_module ($el_nsuri);
      } else {
        $el_nsuri = '';
      }
      my $el_ln = $item->{node}->manakai_local_name;
      
      my $element_state = {};
      my $eldef = $Element->{$el_nsuri}->{$el_ln} ||
          $Element->{$el_nsuri}->{''} ||
          $ElementDefault;
      my $content_def = $item->{transparent}
          ? $item->{parent_def} || $eldef : $eldef;
      my $content_state = $item->{transparent}
          ? $item->{parent_def}
              ? $item->{parent_state} || $element_state : $element_state
          : $element_state;

      unless ($eldef->{status} & FEATURE_STATUS_REC) {
        my $status = $eldef->{status} & FEATURE_STATUS_CR ? 'cr' :
            $eldef->{status} & FEATURE_STATUS_LC ? 'lc' :
            $eldef->{status} & FEATURE_STATUS_WD ? 'wd' : 'non-standard';
        $self->{onerror}->(node => $item->{node},
                           type => 'status:'.$status.':element',
                           level => $self->{level}->{info});
      }
      if (not ($eldef->{status} & FEATURE_ALLOWED)) {
        $self->{onerror}->(node => $item->{node},
                           type => 'element not defined',
                           level => $self->{level}->{must});
      } elsif ($eldef->{status} & FEATURE_DEPRECATED_SHOULD) {
        $self->{onerror}->(node => $item->{node},
                           type => 'deprecated:element',
                           level => $self->{level}->{should});
      } elsif ($eldef->{status} & FEATURE_DEPRECATED_INFO) {
        $self->{onerror}->(node => $item->{node},
                           type => 'deprecated:element',
                           level => $self->{level}->{info});
      }

      my @new_item;
      push @new_item, [$eldef->{check_start}, $self, $item, $element_state];
      push @new_item, [$eldef->{check_attrs}, $self, $item, $element_state];
      
      my @child = @{$item->{node}->child_nodes};
      while (@child) {
        my $child = shift @child;
        my $child_nt = $child->node_type;
        if ($child_nt == 1) { # ELEMENT_NODE
          my $child_nsuri = $child->namespace_uri;
          $child_nsuri = '' unless defined $child_nsuri;
          my $child_ln = $child->manakai_local_name;
          if ($HTMLTransparentElements->{$child_nsuri}->{$child_ln} and
              not (($self->{flag}->{in_head} or
                    ($el_nsuri eq $HTML_NS and $el_ln eq 'head')) and
                   $child_nsuri eq $HTML_NS and $child_ln eq 'noscript')) {
            push @new_item, [$content_def->{check_child_element},
                             $self, $item, $child,
                             $child_nsuri, $child_ln, 1,
                             $content_state, $element_state];
            push @new_item, {type => 'element', node => $child,
                             parent_state => $content_state,
                             parent_def => $content_def,
                             real_parent_state => $element_state,
                             transparent => 1};
          } else {
            if ($item->{parent_def} and # has parent
                $el_nsuri eq $HTML_NS) { ## $HTMLSemiTransparentElements
              if ($el_ln eq 'object') {
                if ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
                  #
                } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'param') {
                  #
                } else {
                  $content_def = $item->{parent_def} || $content_def;
                  $content_state = $item->{parent_state} || $content_state;
                }
              } elsif ($el_ln eq 'video' or $el_ln eq 'audio') {
                if ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
                  #
                } elsif ($child_nsuri eq $HTML_NS and $child_ln eq 'source') {
                  $element_state->{has_source} = 1;
                } else {
                  $content_def = $item->{parent_def} || $content_def;
                  $content_state = $item->{parent_state} || $content_state;
                }
              }
            }

            push @new_item, [$content_def->{check_child_element},
                             $self, $item, $child,
                             $child_nsuri, $child_ln,
                             $HTMLSemiTransparentElements
                                 ->{$child_nsuri}->{$child_ln},
                             $content_state, $element_state];
            push @new_item, {type => 'element', node => $child,
                             parent_def => $content_def,
                             real_parent_state => $element_state,
                             parent_state => $content_state};
          }

          if ($HTMLEmbeddedContent->{$child_nsuri}->{$child_ln}) {
            $element_state->{has_significant} = 1;
          }
        } elsif ($child_nt == 3 or # TEXT_NODE
                 $child_nt == 4) { # CDATA_SECTION_NODE
          my $has_significant = ($child->data =~ /[^\x09\x0A\x0C\x0D\x20]/);
          push @new_item, [$content_def->{check_child_text},
                           $self, $item, $child, $has_significant,
                           $content_state, $element_state];
          $element_state->{has_significant} ||= $has_significant;
          if ($has_significant and
              $HTMLSemiTransparentElements->{$el_nsuri}->{$el_ln}) {
            $content_def = $item->{parent_def} || $content_def;
          }
        } elsif ($child_nt == 5) { # ENTITY_REFERENCE_NODE
          push @child, @{$child->child_nodes};
        }
        ## TODO: PI_NODE
        ## TODO: Unknown node type
      }
      
      push @new_item, [$eldef->{check_end}, $self, $item, $element_state];
      
      unshift @item, @new_item;
    } else {
      die "$0: Internal error: Unsupported checking action type |$item->{type}|";
    }
  }

  for (@{$self->{template}}) {
    ## TODO: If the document is an XML document, ...
    ## NOTE: If the document is an HTML document:
    ## ISSUE: We need to percent-decode?
    F: {
      if ($self->{id}->{$_->[0]}) {
        my $el = $self->{id}->{$_->[0]}->[0]->owner_element;
        if ($el->node_type == 1 and # ELEMENT_NODE
            $el->manakai_local_name eq 'datatemplate') {
          my $nsuri = $el->namespace_uri;
          if (defined $nsuri and $nsuri eq $HTML_NS) {
            if ($el eq $_->[1]->owner_element) {
              $self->{onerror}->(node => $_->[1],
                                 type => 'fragment points itself',
                                 level => $self->{level}->{must});
            }
            
            last F;
          }
        }
      }
      ## TODO: Should we raise a "fragment points nothing" error instead
      ## if the fragment identifier identifies no element?

      $self->{onerror}->(node => $_->[1], type => 'template:not template',
                         level => $self->{level}->{must});
    } # F
  }
  
  for (@{$self->{ref}}) {
    ## TOOD: If XML
    ## NOTE: If it is an HTML document:
    if ($_->[0] eq '') {
      ## NOTE: It points the top of the document.
    } elsif ($self->{id}->{$_->[0]}) {
      if ($self->{id}->{$_->[0]}->[0]->owner_element
              eq $_->[1]->owner_element) {
        $self->{onerror}->(node => $_->[1], type => 'fragment points itself',
                           level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}->(node => $_->[1], type => 'fragment points nothing',
                         level => $self->{level}->{must});
    }
  }

  ## TODO: Maybe we should have $document->manakai_get_by_fragment or something

  for (@{$self->{usemap}}) {
    unless ($self->{map}->{$_->[0]}) {
      $self->{onerror}->(node => $_->[1], type => 'no referenced map',
                         level => $self->{level}->{must});
    }
  }

  for (@{$self->{contextmenu}}) {
    unless ($self->{menu}->{$_->[0]}) {
      $self->{onerror}->(node => $_->[1], type => 'no referenced menu',
                         level => $self->{level}->{must});
    }
  }

  delete $self->{plus_elements};
  delete $self->{minus_elements};
  delete $self->{onerror};
  delete $self->{id};
  delete $self->{usemap};
  delete $self->{ref};
  delete $self->{template};
  delete $self->{map};
  return $self->{return};
} # check_element

sub _add_minus_elements ($$@) {
  my $self = shift;
  my $element_state = shift;
  for my $elements (@_) {
    for my $nsuri (keys %$elements) {
      for my $ln (keys %{$elements->{$nsuri}}) {
        unless ($self->{minus_elements}->{$nsuri}->{$ln}) {
          $element_state->{minus_elements_original}->{$nsuri}->{$ln} = 0;
          $self->{minus_elements}->{$nsuri}->{$ln} = 1;
        }
      }
    }
  }
} # _add_minus_elements

sub _remove_minus_elements ($$) {
  my $self = shift;
  my $element_state = shift;
  for my $nsuri (keys %{$element_state->{minus_elements_original}}) {
    for my $ln (keys %{$element_state->{minus_elements_original}->{$nsuri}}) {
      delete $self->{minus_elements}->{$nsuri}->{$ln};
    }
  }
} # _remove_minus_elements

sub _add_plus_elements ($$@) {
  my $self = shift;
  my $element_state = shift;
  for my $elements (@_) {
    for my $nsuri (keys %$elements) {
      for my $ln (keys %{$elements->{$nsuri}}) {
        unless ($self->{plus_elements}->{$nsuri}->{$ln}) {
          $element_state->{plus_elements_original}->{$nsuri}->{$ln} = 0;
          $self->{plus_elements}->{$nsuri}->{$ln} = 1;
        }
      }
    }
  }
} # _add_plus_elements

sub _remove_plus_elements ($$) {
  my $self = shift;
  my $element_state = shift;
  for my $nsuri (keys %{$element_state->{plus_elements_original}}) {
    for my $ln (keys %{$element_state->{plus_elements_original}->{$nsuri}}) {
      delete $self->{plus_elements}->{$nsuri}->{$ln};
    }
  }
} # _remove_plus_elements

sub _attr_status_info ($$$) {
  my ($self, $attr, $status_code) = @_;

  if (not ($status_code & FEATURE_ALLOWED)) {
    $self->{onerror}->(node => $attr,
                       type => 'attribute not defined',
                       level => $self->{level}->{must});
  } elsif ($status_code & FEATURE_DEPRECATED_SHOULD) {
    $self->{onerror}->(node => $attr,
                       type => 'deprecated:attr',
                       level => $self->{level}->{should});
  } elsif ($status_code & FEATURE_DEPRECATED_INFO) {
    $self->{onerror}->(node => $attr,
                       type => 'deprecated:attr',
                       level => $self->{level}->{info});
  }

  my $status;
  if ($status_code & FEATURE_STATUS_REC) {
    return;
  } elsif ($status_code & FEATURE_STATUS_CR) {
    $status = 'cr';
  } elsif ($status_code & FEATURE_STATUS_LC) {
    $status = 'lc';
  } elsif ($status_code & FEATURE_STATUS_WD) {
    $status = 'wd';
  } else {
    $status = 'non-standard';
  }
  $self->{onerror}->(node => $attr,
                     type => 'status:'.$status.':attr',
                     level => $self->{level}->{info});
} # _attr_status_info

sub _add_minuses ($@) {
  my $self = shift;
  my $r = {};
  for my $list (@_) {
    for my $ns (keys %$list) {
      for my $ln (keys %{$list->{$ns}}) {
        unless ($self->{minuses}->{$ns}->{$ln}) {
          $self->{minuses}->{$ns}->{$ln} = 1;
          $r->{$ns}->{$ln} = 1;
        }
      }
    }
  }
  return {type => 'plus', list => $r};
} # _add_minuses

sub _add_pluses ($@) {
  my $self = shift;
  my $r = {};
  for my $list (@_) {
    for my $ns (keys %$list) {
      for my $ln (keys %{$list->{$ns}}) {
        unless ($self->{pluses}->{$ns}->{$ln}) {
          $self->{pluses}->{$ns}->{$ln} = 1;
          $r->{$ns}->{$ln} = 1;
        }
      }
    }
  }
  return {type => 'minus', list => $r};
} # _add_pluses

sub _remove_minuses ($$) {
  my ($self, $todo) = @_;
  if ($todo->{type} eq 'minus') {
    for my $ns (keys %{$todo->{list}}) {
      for my $ln (keys %{$todo->{list}->{$ns}}) {
        delete $self->{pluses}->{$ns}->{$ln} if $todo->{list}->{$ns}->{$ln};
      }
    }
  } elsif ($todo->{type} eq 'plus') {
    for my $ns (keys %{$todo->{list}}) {
      for my $ln (keys %{$todo->{list}->{$ns}}) {
        delete $self->{minuses}->{$ns}->{$ln} if $todo->{list}->{$ns}->{$ln};
      }
    }
  } else {
    die "$0: Unknown +- type: $todo->{type}";
  }
  1;
} # _remove_minuses

## NOTE: Priority for "minuses" and "pluses" are currently left
## undefined and implemented inconsistently; it is not a problem for
## now, since no element belongs to both lists.

sub _check_get_children ($$$) {
  my ($self, $node, $parent_todo) = @_;
  my $new_todos = [];
  my $sib = [];
  TP: {
    my $node_ns = $node->namespace_uri;
    $node_ns = '' unless defined $node_ns;
    my $node_ln = $node->manakai_local_name;
    if ($HTMLTransparentElements->{$node_ns}->{$node_ln}) {
      if ($node_ns eq $HTML_NS and $node_ln eq 'noscript') {
        if ($parent_todo->{flag}->{in_head}) {
          #
        } else {
          my $end = $self->_add_minuses ({$HTML_NS, {noscript => 1}});
          push @$sib, $end;
          
          unshift @$sib, @{$node->child_nodes};
          push @$new_todos, {type => 'element-attributes', node => $node};
          last TP;
        }
      } elsif ($node_ns eq $HTML_NS and $node_ln eq 'del') {
        my $sig_flag = $parent_todo->{flag}->{has_descendant}->{significant};
        unshift @$sib, @{$node->child_nodes};
        push @$new_todos, {type => 'element-attributes', node => $node};
        push @$new_todos,
            {type => 'code',
             code => sub {
               $parent_todo->{flag}->{has_descendant}->{significant} = 0
                   if not $sig_flag;
             }};
        last TP;
      } else {
        unshift @$sib, @{$node->child_nodes};
        push @$new_todos, {type => 'element-attributes', node => $node};
        last TP;
      }
    }
    if ($node_ns eq $HTML_NS and ($node_ln eq 'video' or $node_ln eq 'audio')) {
      if ($node->has_attribute_ns (undef, 'src')) {
        unshift @$sib, @{$node->child_nodes};
        push @$new_todos, {type => 'element-attributes', node => $node};
        last TP;
      } else {
        my @cn = @{$node->child_nodes};
        CN: while (@cn) {
          my $cn = shift @cn;
          my $cnt = $cn->node_type;
          if ($cnt == 1) {
            my $cn_nsuri = $cn->namespace_uri;
            $cn_nsuri = '' unless defined $cn_nsuri;
            if ($cn_nsuri eq $HTML_NS and $cn->manakai_local_name eq 'source') {
              #
            } else {
              last CN;
            }
          } elsif ($cnt == 3 or $cnt == 4) {
            if ($cn->data =~ /[^\x09\x0A\x0C\x0D\x20]/) {
              last CN;
            }
          }
        } # CN
        unshift @$sib, @cn;
      }
    } elsif ($node_ns eq $HTML_NS and $node_ln eq 'object') {
      my @cn = @{$node->child_nodes};
      CN: while (@cn) {
        my $cn = shift @cn;
        my $cnt = $cn->node_type;
        if ($cnt == 1) {
          my $cn_nsuri = $cn->namespace_uri;
          $cn_nsuri = '' unless defined $cn_nsuri;
          if ($cn_nsuri eq $HTML_NS and $cn->manakai_local_name eq 'param') {
            #
          } else {
            last CN;
          }
        } elsif ($cnt == 3 or $cnt == 4) {
          if ($cn->data =~ /[^\x09\x0A\x0C\x0D\x20]/) {
            last CN;
          }
        }
      } # CN
      unshift @$sib, @cn;
    }
    push @$new_todos, {type => 'element', node => $node};
  } # TP
  
  for my $new_todo (@$new_todos) {
    $new_todo->{flag} = {%{$parent_todo->{flag} or {}}};
  }
  
  return ($sib, $new_todos);
} # _check_get_children

=head1 LICENSE

Copyright 2007-2008 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2008/09/20 11:25:56 $
