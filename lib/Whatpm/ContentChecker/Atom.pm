package Whatpm::ContentChecker;
use strict;
require Whatpm::ContentChecker;

require Whatpm::URIChecker;

my $ATOM_NS = q<http://www.w3.org/2005/Atom>;
my $THR_NS = q<http://purl.org/syndication/thread/1.0>;
my $FH_NS = q<http://purl.org/syndication/history/1.0>;
my $LINK_REL = q<http://www.iana.org/assignments/relation/>;

sub FEATURE_RFC4287 () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}

sub FEATURE_RFC4685 () {
  Whatpm::ContentChecker::FEATURE_STATUS_CR |
  Whatpm::ContentChecker::FEATURE_ALLOWED
}

## MUST be well-formed XML (RFC 4287 references XML 1.0 REC 20040204)

## NOTE: Commants and PIs are not explicitly allowed.

our $IsInHTMLInteractiveContent; # See Whatpm::ContentChecker.

our $AttrChecker;

## Atom 1.0 [RFC 4287] cites RFC 4288 (Media Type Registration) for
## "MIME media type".  However, RFC 4288 only defines syntax of
## component such as |type|, |subtype|, and |parameter-name| and does
## not define the whole syntax.  We use Web Applications 1.0's "valid
## MIME type" definition here.
our $MIMETypeChecker; ## See |Whatpm::ContentChecker|.

## Any element MAY have xml:base, xml:lang
my $GetAtomAttrsChecker = sub {
  my $element_specific_checker = shift;
  my $element_specific_status = shift;
  return sub {
    my ($self, $todo, $element_state) = @_;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = $element_specific_checker->{$attr_ln};
      } else {
        $checker = $AttrChecker->{$attr_ns}->{$attr_ln}
            || $AttrChecker->{$attr_ns}->{''};
      }
      if ($checker) {
        $checker->($self, $attr, $todo, $element_state);
      } elsif ($attr_ln eq '') {
        #
      } else {
        $self->{onerror}->(node => $attr,
                           type => 'unknown attribute',
                           level => $self->{level}->{uncertain});
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }

      if ($attr_ns eq '') {
        $self->_attr_status_info ($attr, $element_specific_status->{$attr_ln});
      }
      ## TODO: global attribute
    }
  };
}; # $GetAtomAttrsChecker

my $AtomLanguageTagAttrChecker = sub {
  ## NOTE: See also $HTMLLanguageTagAttrChecker in HTML.pm.

  my ($self, $attr) = @_;
  my $value = $attr->value;
  require Whatpm::LangTag;
  Whatpm::LangTag->check_rfc3066_language_tag ($value, sub {
    $self->{onerror}->(@_, node => $attr);
  }, $self->{level});
  ## ISSUE: RFC 4646 (3066bis)?
}; # $AtomLanguageTagAttrChecker

my %AtomChecker = (
  %Whatpm::ContentChecker::AnyChecker,
  status => FEATURE_RFC4287,
  check_attrs => $GetAtomAttrsChecker->({}, {}),
);

my %AtomTextConstruct = (
  %AtomChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{type} = 'text';
    $element_state->{value} = '';
  },
  check_attrs => $GetAtomAttrsChecker->({
    type => sub {
      my ($self, $attr, $item, $element_state) = @_;
      my $value = $attr->value;
      if ($value eq 'text' or $value eq 'html' or $value eq 'xhtml') { # MUST
        $element_state->{type} = $value;
      } else {
        ## NOTE: IMT MUST NOT be used here.
        $self->{onerror}->(node => $attr,
                           type => 'invalid attribute value',
                           level => $self->{level}->{must});
      }
    }, # checked in |checker|
  }, {
    type => FEATURE_RFC4287,
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
    } else {
      if ($element_state->{type} eq 'text' or
          $element_state->{type} eq 'html') { # MUST NOT
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:atom|TextConstruct',
                           level => $self->{level}->{must});
      } elsif ($element_state->{type} eq 'xhtml') {
        if ($child_nsuri eq q<http://www.w3.org/1999/xhtml> and
            $child_ln eq 'div') { # MUST
          if ($element_state->{has_div}) {
            $self->{onerror}
                ->(node => $child_el,
                   type => 'element not allowed:atom|TextConstruct',
                   level => $self->{level}->{must});
          } else {
            $element_state->{has_div} = 1;
            ## TODO: SHOULD be suitable for handling as HTML [XHTML10]
          }
        } else {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:atom|TextConstruct',
                             level => $self->{level}->{must});
        }
      } else {
        die "atom:TextConstruct type error: $element_state->{type}";
      }
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($element_state->{type} eq 'text') {
      #
    } elsif ($element_state->{type} eq 'html') {
      $element_state->{value} .= $child_node->text_content;
      ## NOTE: Markup MUST be escaped.
    } elsif ($element_state->{type} eq 'xhtml') {
      if ($has_significant) {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed:atom|TextConstruct',
                           level => $self->{level}->{must});
      }
    } else {
      die "atom:TextConstruct type error: $element_state->{type}";
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{type} eq 'xhtml') {
      unless ($element_state->{has_div}) {
        $self->{onerror}->(node => $item->{node},
                           type => 'child element missing',
                           text => 'div',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{type} eq 'html') {
      ## TODO: SHOULD be suitable for handling as HTML [HTML4]
      # markup MUST be escaped
      $self->{onsubdoc}->({s => $element_state->{value},
                           container_node => $item->{node},
                           media_type => 'text/html',
                           inner_html_element => 'div',
                           is_char_string => 1});
    }

    $AtomChecker{check_end}->(@_);
  },
); # %AtomTextConstruct

my %AtomPersonConstruct = (
  %AtomChecker,
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
    } elsif ($child_nsuri eq $ATOM_NS) {
      if ($child_ln eq 'name') {
        if ($element_state->{has_name}) {
          $self->{onerror}
              ->(node => $child_el,
                 type => 'element not allowed:atom|PersonConstruct',
                 level => $self->{level}->{must});
        } else {
          $element_state->{has_name} = 1;
        }
      } elsif ($child_ln eq 'uri') {
        if ($element_state->{has_uri}) {
          $self->{onerror}
              ->(node => $child_el,
                 type => 'element not allowed:atom|PersonConstruct',
                 level => $self->{level}->{must});
        } else {
          $element_state->{has_uri} = 1;
        }
      } elsif ($child_ln eq 'email') {
        if ($element_state->{has_email}) {
          $self->{onerror}
              ->(node => $child_el,
                 type => 'element not allowed:atom|PersonConstruct',
                 level => $self->{level}->{must});
        } else {
          $element_state->{has_email} = 1;
        }
      } else {
        $self->{onerror}
            ->(node => $child_el,
               type => 'element not allowed:atom|PersonConstruct',
               level => $self->{level}->{must});
      }
    } else {
      $self->{onerror}
          ->(node => $child_el,
             type => 'element not allowed:atom|PersonConstruct',
             level => $self->{level}->{must});
    }
    ## TODO: extension element
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    if ($has_significant) {
      $self->{onerror}->(node => $child_node,
                         type => 'character not allowed:atom|PersonConstruct',
                         level => $self->{level}->{must});
    }
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    unless ($element_state->{has_name}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'name',
                         level => $self->{level}->{must});
    }

    $AtomChecker{check_end}->(@_);
  },
); # %AtomPersonConstruct

our $Element;

$Element->{$ATOM_NS}->{''} = {
  %AtomChecker,
  status => 0,
};

$Element->{$ATOM_NS}->{name} = {
  %AtomChecker,

  ## NOTE: Strictly speaking, structure and semantics for atom:name
  ## element outside of Person construct is not defined.

  ## NOTE: No constraint.
};

$Element->{$ATOM_NS}->{uri} = {
  %AtomChecker,

  ## NOTE: Strictly speaking, structure and semantics for atom:uri
  ## element outside of Person construct is not defined.

  ## NOTE: Elements are not explicitly disallowed.

  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{value} = '';
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{value} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri_reference ($element_state->{value}, sub {
      $self->{onerror}->(@_, node => $item->{node});
    }, $self->{level});

    $AtomChecker{check_end}->(@_);
  },
};

$Element->{$ATOM_NS}->{email} = {
  %AtomChecker,

  ## NOTE: Strictly speaking, structure and semantics for atom:email
  ## element outside of Person construct is not defined.

  ## NOTE: Elements are not explicitly disallowed.

  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## TODO: addr-spec
    $self->{onerror}->(node => $item->{node},
                       type => 'addr-spec not supported',
                       level => $self->{level}->{uncertain});

    $AtomChecker{check_end}->(@_);
  },
};

## MUST NOT be any white space
my %AtomDateConstruct = (
  %AtomChecker,

  ## NOTE: It does not explicitly say that there MUST NOT be any element.

  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{value} = '';
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{value} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## MUST: RFC 3339 |date-time| with uppercase |T| and |Z|
    if ($element_state->{value} =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(?>\.[0-9]+)?(?>Z|[+-]([0-9]{2}):([0-9]{2}))\z/) {
      my ($y, $M, $d, $h, $m, $s, $zh, $zm)
          = ($1, $2, $3, $4, $5, $6, $7, $8);
      my $node = $item->{node};

      ## Check additional constraints described or referenced in
      ## comments of ABNF rules for |date-time|.
      if (0 < $M and $M < 13) {      
        $self->{onerror}->(node => $node, type => 'datetime:bad day',
                           level => $self->{level}->{must})
            if $d < 1 or
                $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
        $self->{onerror}->(node => $node, type => 'datetime:bad day',
                           level => $self->{level}->{must})
            if $M == 2 and $d == 29 and
                not ($y % 400 == 0 or ($y % 4 == 0 and $y % 100 != 0));
      } else {
        $self->{onerror}->(node => $node, type => 'datetime:bad month',
                           level => $self->{level}->{must});
      }
      $self->{onerror}->(node => $node, type => 'datetime:bad hour',
                         level => $self->{level}->{must}) if $h > 23;
      $self->{onerror}->(node => $node, type => 'datetime:bad minute',
                         level => $self->{level}->{must}) if $m > 59;
      $self->{onerror}->(node => $node, type => 'datetime:bad second',
                         level => $self->{level}->{must})
          if $s > 60; ## NOTE: Validness of leap seconds are not checked.
      $self->{onerror}->(node => $node, type => 'datetime:bad timezone hour',
                         level => $self->{level}->{must}) if $zh > 23;
      $self->{onerror}->(node => $node, type => 'datetime:bad timezone minute',
                         level => $self->{level}->{must}) if $zm > 59;
    } else {
      $self->{onerror}->(node => $item->{node},
                         type => 'datetime:syntax error',
                         level => $self->{level}->{must});
    }
    ## NOTE: SHOULD be accurate as possible (cannot be checked)

    $AtomChecker{check_end}->(@_);
  },
); # %AtomDateConstruct

$Element->{$ATOM_NS}->{entry} = {
  %AtomChecker,
  is_root => 1,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;

    ## NOTE: metadata elements, followed by atom:entry* (no explicit MAY)

    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $ATOM_NS) {
      my $not_allowed;
      if ({ # MUST (0, 1)
           content => 1,
           id => 1,
           published => 1,
           rights => 1,
           source => 1,
           summary => 1,
           title => 1,
           updated => 1,
          }->{$child_ln}) {
        unless ($element_state->{has_element}->{$child_ln}) {
          $element_state->{has_element}->{$child_ln} = 1;
          $not_allowed = $element_state->{has_element}->{entry};
        } else {
          $not_allowed = 1;
        }
      } elsif ($child_ln eq 'link') { # MAY
        if ($child_el->rel eq $LINK_REL . 'alternate') {
          my $type = $child_el->get_attribute_ns (undef, 'type');
          $type = '' unless defined $type;
          my $hreflang = $child_el->get_attribute_ns (undef, 'hreflang');
          $hreflang = '' unless defined $hreflang;
          my $key = 'link:'.(defined $type ? ':'.$type : '').':'.
              (defined $hreflang ? ':'.$hreflang : '');
          unless ($element_state->{has_element}->{$key}) {
            $element_state->{has_element}->{$key} = 1;
            $element_state->{has_element}->{'link.alternate'} = 1;
          } else {
            $not_allowed = 1;
          }
        }
        
        ## NOTE: MAY
        $not_allowed ||= $element_state->{has_element}->{entry};
      } elsif ({ # MAY
                category => 1,
                contributor => 1,
               }->{$child_ln}) {
        $not_allowed = $element_state->{has_element}->{entry};
      } elsif ($child_ln eq 'author') { # MAY
        $not_allowed = $element_state->{has_element}->{entry};
        $element_state->{has_author} = 1; # ./author | ./source/author
        $element_state->{has_element}->{$child_ln} = 1; # ./author
      } else {
        $not_allowed = 1;
      }
      if ($not_allowed) {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } elsif ($child_nsuri eq $THR_NS and $child_ln eq 'in-reply-to') {
      ## ISSUE: Where |thr:in-reply-to| is allowed is not explicit;y
      ## defined in RFC 4685.
      #
    } elsif ($child_nsuri eq $THR_NS and $child_ln eq 'total') {
      #
    } else {
      ## TODO: extension element
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

    if ($element_state->{has_author}) {
      ## NOTE: There is either a child atom:author element
      ## or a child atom:source element which contains an atom:author
      ## child element.
      #
    } else {
      A: {
        my $root = $item->{node}->owner_document->document_element;
        if ($root and $root->manakai_local_name eq 'feed') {
          my $nsuri = $root->namespace_uri;
          if (defined $nsuri and $nsuri eq $ATOM_NS) {
            ## NOTE: An Atom Feed Document.
            for my $root_child (@{$root->child_nodes}) {
              ## NOTE: Entity references are not supported.
              next unless $root_child->node_type == 1; # ELEMENT_NODE
              next unless $root_child->manakai_local_name eq 'author';
              my $root_child_nsuri = $root_child->namespace_uri;
              next unless defined $root_child_nsuri;
              next unless $root_child_nsuri eq $ATOM_NS;
              last A;
            }
          }
        }
        
        $self->{onerror}->(node => $item->{node},
                           type => 'child element missing:atom',
                           text => 'author',
                           level => $self->{level}->{must});
      } # A
    }

    unless ($element_state->{has_element}->{author}) {
      $item->{parent_state}->{has_no_author_entry} = 1; # for atom:feed's check
    }

    ## TODO: If entry's with same id, then updated SHOULD be different

    unless ($element_state->{has_element}->{id}) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'id',
                         level => $self->{level}->{must});
    }
    unless ($element_state->{has_element}->{title}) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'title',
                         level => $self->{level}->{must});
    }
    unless ($element_state->{has_element}->{updated}) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'updated',
                         level => $self->{level}->{must});
    }
    if (not $element_state->{has_element}->{content} and
        not $element_state->{has_element}->{'link.alternate'}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom:link:alternate',
                         level => $self->{level}->{must});
    }

    if ($element_state->{require_summary} and
        not $element_state->{has_element}->{summary}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'summary',
                         level => $self->{level}->{must});
    }
  },
};

$Element->{$ATOM_NS}->{feed} = {
  %AtomChecker,
  is_root => 1,
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;

    ## NOTE: metadata elements, followed by atom:entry* (no explicit MAY)

    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln} and
        $IsInHTMLInteractiveContent->($child_el, $child_nsuri, $child_ln)) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{level}->{must});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } elsif ($child_nsuri eq $ATOM_NS) {
      my $not_allowed;
      if ($child_ln eq 'entry') {
        $element_state->{has_element}->{entry} = 1;
      } elsif ({ # MUST (0, 1)
                generator => 1,
                icon => 1,
                id => 1,
                logo => 1,
                rights => 1,
                subtitle => 1,
                title => 1,
                updated => 1,
               }->{$child_ln}) {
        unless ($element_state->{has_element}->{$child_ln}) {
          $element_state->{has_element}->{$child_ln} = 1;
          $not_allowed = $element_state->{has_element}->{entry};
        } else {
          $not_allowed = 1;
        }
      } elsif ($child_ln eq 'link') {
        my $rel = $child_el->rel;
        if ($rel eq $LINK_REL . 'alternate') {
          my $type = $child_el->get_attribute_ns (undef, 'type');
          $type = '' unless defined $type;
          my $hreflang = $child_el->get_attribute_ns (undef, 'hreflang');
          $hreflang = '' unless defined $hreflang;
          my $key = 'link:'.(defined $type ? ':'.$type : '').':'.
              (defined $hreflang ? ':'.$hreflang : '');
          unless ($element_state->{has_element}->{$key}) {
            $element_state->{has_element}->{$key} = 1;
          } else {
            $not_allowed = 1;
          }
        } elsif ($rel eq $LINK_REL . 'self') {
          $element_state->{has_element}->{'link.self'} = 1;
        }
        
        ## NOTE: MAY
        $not_allowed = $element_state->{has_element}->{entry};
      } elsif ({ # MAY
                category => 1,
                contributor => 1,
               }->{$child_ln}) {
        $not_allowed = $element_state->{has_element}->{entry};
      } elsif ($child_ln eq 'author') { # MAY
        $not_allowed = $element_state->{has_element}->{entry};
        $element_state->{has_element}->{author} = 1;
      } else {
        $not_allowed = 1;
      }
      $self->{onerror}->(node => $child_el, type => 'element not allowed',
                         level => $self->{level}->{must})
          if $not_allowed;
    } else {
      ## TODO: extension element
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

    if ($element_state->{has_no_author_entry} and
        not $element_state->{has_element}->{author}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'author',
                         level => $self->{level}->{must});
      ## ISSUE: If there is no |atom:entry| element,
      ## there should be an |atom:author| element?
    }

    ## TODO: If entry's with same id, then updated SHOULD be different

    unless ($element_state->{has_element}->{id}) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'id',
                         level => $self->{level}->{must});
    }
    unless ($element_state->{has_element}->{title}) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'child element missing:atom',
                         text => 'title',
                         level => $self->{level}->{must});
    }
    unless ($element_state->{has_element}->{updated}) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'element missing:atom',
                         text => 'updated',
                         level => $self->{level}->{must});
    }
    unless ($element_state->{has_element}->{'link.self'}) {
      $self->{onerror}->(node => $item->{node}, 
                         type => 'element missing:atom:link:self',
                         level => $self->{level}->{should});
    }

    $AtomChecker{check_end}->(@_);
  },
};

$Element->{$ATOM_NS}->{content} = {
  %AtomChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{type} = 'text';
    $element_state->{value} = '';
  },
  check_attrs => $GetAtomAttrsChecker->({
    src => sub {
      my ($self, $attr, $item, $element_state) = @_;

      $element_state->{has_src} = 1;
      $item->{parent_state}->{require_summary} = 1;

      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri_reference ($attr->value, sub {
        $self->{onerror}->(@_, node => $item->{node});
      }, $self->{level});
    },
    type => sub {
      my ($self, $attr, $item, $element_state) = @_;

      $element_state->{has_type} = 1;

      my $value = $attr->value;
      if ($value eq 'text' or $value eq 'html' or $value eq 'xhtml') {
        # MUST
      } else {
        my $type = $MIMETypeChecker->(@_);
        if ($type) {
          if ($type->is_composite_type) {
            $self->{onerror}->(node => $attr, type => 'IMT:composite',
                               level => $self->{level}->{must});
          }

          if ($type->is_xml_mime_type) {
            $value = 'xml';
          } elsif ($type->type eq 'text') {
            $value = 'mime_text';
          } else {
            $item->{parent_state}->{require_summary} = 1;
          }
        } else {
          $item->{parent_state}->{require_summary} = 1;
        }
      }

      $element_state->{type} = $value;
    },
  }, {
    src => FEATURE_RFC4287,
    type => FEATURE_RFC4287,
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
    } else {
      if ($element_state->{type} eq 'text' or
          $element_state->{type} eq 'html' or
          $element_state->{type} eq 'mime_text') {
        # MUST NOT
        $self->{onerror}->(node => $child_el,
                           type => 'element not allowed:atom|content',
                           level => $self->{level}->{must});
      } elsif ($element_state->{type} eq 'xhtml') {
        if ($element_state->{has_div}) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:atom|content',
                             level => $self->{level}->{must});
        } else {
          ## TODO: SHOULD be suitable for handling as HTML [XHTML10]
          $element_state->{has_div} = 1;
        }
      } elsif ($element_state->{type} eq 'xml') {
        ## MAY contain elements
        if ($element_state->{has_src}) {
          $self->{onerror}->(node => $child_el,
                             type => 'element not allowed:atom|content',
                             level => $self->{level}->{must});
        }
      } else {
        ## NOTE: Elements are not explicitly disallowed.
      }
    }
  },
  ## NOTE: If @src, the element MUST be empty.  What is "empty"?
  ## Is |<e><!----></e>| empty?  |<e>&e;</e>| where |&e;| has
  ## empty replacement tree shuld be empty, since Atom is defined
  ## in terms of XML Information Set where entities are expanded.
  ## (but what if |&e;| is an unexpanded entity?)
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;    
    if ($has_significant) {
      if ($element_state->{has_src}) {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed:empty',
                           level => $self->{level}->{must});
      } elsif ($element_state->{type} eq 'xhtml' or
               $element_state->{type} eq 'xml') {
        $self->{onerror}->(node => $child_node,
                           type => 'character not allowed:atom|content',
                           level => $self->{level}->{must});
      }
    }

    $element_state->{value} .= $child_node->data;

    ## NOTE: type=text/* has no further restriction (i.e. the content don't
    ## have to conform to the definition of the type).
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    if ($element_state->{has_src}) {
      if (not $element_state->{has_type}) {
        $self->{onerror}->(node => $item->{node},
                           type => 'attribute missing',
                           text => 'type',
                           level => $self->{level}->{should});
      } elsif ($element_state->{type} eq 'text' or
               $element_state->{type} eq 'html' or
               $element_state->{type} eq 'xhtml') {
        $self->{onerror}
            ->(node => $item->{node}->get_attribute_node_ns (undef, 'type'),
               type => 'not IMT', level => $self->{level}->{must});
      }
    }

    if ($element_state->{type} eq 'xhtml') {
      unless ($element_state->{has_div}) {
        $self->{onerror}->(node => $item->{node},
                           type => 'child element missing',
                           text => 'div',
                           level => $self->{level}->{must});
      }
    } elsif ($element_state->{type} eq 'html') {
      ## TODO: SHOULD be suitable for handling as HTML [HTML4]
      # markup MUST be escaped
      $self->{onsubdoc}->({s => $element_state->{value},
                           container_node => $item->{node},
                           media_type => 'text/html',
                           inner_html_element => 'div',
                           is_char_string => 1});
    } elsif ($element_state->{type} eq 'xml') {
      ## NOTE: SHOULD be suitable for handling as $value.
      ## If no @src, this would normally mean it contains a 
      ## single child element that would serve as the root element.
      $self->{onerror}->(node => $item->{node},
                         type => 'atom|content not supported',
                         text => $item->{node}->get_attribute_ns
                             (undef, 'type'),
                         level => $self->{level}->{uncertain});
    } elsif ($element_state->{type} eq 'text' or
             $element_state->{type} eq 'mime-text') {
      #
    } else {
      ## TODO: $s = valid Base64ed [RFC 3548] where 
      ## MAY leading and following "white space" (what?)
      ## and lines separated by a single U+000A

      ## NOTE: SHOULD be suitable for the indicated media type.
      $self->{onerror}->(node => $item->{node},
                         type => 'atom|content not supported',
                         text => $item->{node}->get_attribute_ns
                             (undef, 'type'),
                         level => $self->{level}->{uncertain});
    }

    $AtomChecker{check_end}->(@_);
  },
}; # atom:content

$Element->{$ATOM_NS}->{author} = \%AtomPersonConstruct;

$Element->{$ATOM_NS}->{category} = {
  %AtomChecker,
  check_attrs => $GetAtomAttrsChecker->({
    label => sub { 1 }, # no value constraint
    scheme => sub { # NOTE: No MUST.
      my ($self, $attr) = @_;
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri ($attr->value, sub {
        $self->{onerror}->(@_, node => $attr);
      }, $self->{level});
    },
    term => sub {
      my ($self, $attr, $item, $element_state) = @_;
      
      ## NOTE: No value constraint.
      
      $element_state->{has_term} = 1;
    },
  }, {
    label => FEATURE_RFC4287,
    scheme => FEATURE_RFC4287,
    term => FEATURE_RFC4287,
  }),
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    unless ($element_state->{has_term}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'term',
                         level => $self->{level}->{must});
    }

    $AtomChecker{check_end}->(@_);
  },
  ## NOTE: Meaning of content is not defined.
};

$Element->{$ATOM_NS}->{contributor} = \%AtomPersonConstruct;

## TODO: Anything below does not support <html:nest/> yet.

$Element->{$ATOM_NS}->{generator} = {
  %AtomChecker,
  check_attrs => $GetAtomAttrsChecker->({
    uri => sub { # MUST
      my ($self, $attr) = @_;
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri_reference ($attr->value, sub {
        $self->{onerror}->(@_, node => $attr);
      }, $self->{level});
      ## NOTE: Dereferencing SHOULD produce a representation
      ## that is relevant to the agent.
    },
    version => sub { 1 }, # no value constraint
  }, {
    uri => FEATURE_RFC4287,
    version => FEATURE_RFC4287,
  }),

  ## NOTE: Elements are not explicitly disallowed.

  ## NOTE: Content MUST be a string that is a human-readable name for
  ## the generating agent.
};

$Element->{$ATOM_NS}->{icon} = {
  %AtomChecker,
  check_start =>  sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{value} = '';
  },
  ## NOTE: Elements are not explicitly disallowed.
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{value} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## NOTE: No MUST.
    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri_reference ($element_state->{value}, sub {
      $self->{onerror}->(@_, node => $item->{node});
    }, $self->{level});

    ## NOTE: Image SHOULD be 1:1 and SHOULD be small

    $AtomChecker{check_end}->(@_);
  },
};

$Element->{$ATOM_NS}->{id} = {
  %AtomChecker,
  check_start =>  sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{value} = '';
  },
  ## NOTE: Elements are not explicitly disallowed.
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{value} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri ($element_state->{value}, sub {
      $self->{onerror}->(@_, node => $item->{node});
    }, $self->{level});
    ## TODO: SHOULD be normalized

    $AtomChecker{check_end}->(@_);
  },
};

my $AtomIMTAttrChecker = sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
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
}; # $AtomIMTAttrChecker

my $AtomIRIReferenceAttrChecker = sub {
  my ($self, $attr) = @_;
  ## NOTE: There MUST NOT be any white space.
  Whatpm::URIChecker->check_iri_reference ($attr->value, sub {
    $self->{onerror}->(@_, node => $attr);
  }, $self->{level});
}; # $AtomIRIReferenceAttrChecker

$Element->{$ATOM_NS}->{link} = {
  %AtomChecker,
  check_attrs => $GetAtomAttrsChecker->({
    href => $AtomIRIReferenceAttrChecker,
    hreflang => $AtomLanguageTagAttrChecker,
    length => sub { }, # No MUST; in octets.
    rel => sub { # MUST
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value =~ /\A(?>[0-9A-Za-z._~!\$&'()*+,;=\x{A0}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}-]|%[0-9A-Fa-f][0-9A-Fa-f]|\@)+\z/) {
        $value = $LINK_REL . $value;
      }

      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri ($value, sub {
        $self->{onerror}->(@_, node => $attr);
      }, $self->{level});

      ## TODO: Warn if unregistered

      ## TODO: rel=license [RFC 4946]
      ## MUST NOT multiple rel=license with same href="",type="" pairs
      ## href="" SHOULD be dereferencable
      ## title="" SHOULD be there if multiple rel=license
      ## MUST NOT "unspecified" and other rel=license
    },
    title => sub { }, # No MUST
    type => $AtomIMTAttrChecker,
    ## NOTE: MUST be a MIME media type.  What is "MIME media type"?
  }, {
    href => FEATURE_RFC4287,
    hreflang => FEATURE_RFC4287,
    length => FEATURE_RFC4287,
    rel => FEATURE_RFC4287,
    title => FEATURE_RFC4287,
    type => FEATURE_RFC4287,

    ## TODO: thr:count
    ## TODO: thr:updated
  }),
  check_start =>  sub {
    my ($self, $item, $element_state) = @_;

    unless ($item->{node}->has_attribute_ns (undef, 'href')) { # MUST
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'href',
                         level => $self->{level}->{must});
    }

    if ($item->{node}->rel eq $LINK_REL . 'enclosure' and
        not $item->{node}->has_attribute_ns (undef, 'length')) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'length',
                         level => $self->{level}->{should});
    }
  },
};

$Element->{$ATOM_NS}->{logo} = {
  %AtomChecker,
  ## NOTE: Child elements are not explicitly disallowed
  check_start =>  sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{value} = '';
  },
  ## NOTE: Elements are not explicitly disallowed.
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{value} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;  

    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri_reference ($element_state->{value}, sub {
      $self->{onerror}->(@_, node => $item->{node});
    }, $self->{level});
    
    ## NOTE: Image SHOULD be 2:1

    $AtomChecker{check_end}->(@_);
  },
};

$Element->{$ATOM_NS}->{published} = \%AtomDateConstruct;

$Element->{$ATOM_NS}->{rights} = \%AtomTextConstruct;
## NOTE: SHOULD NOT be used to convey machine-readable information.

$Element->{$ATOM_NS}->{source} = {
  %AtomChecker,
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
    } elsif ($child_nsuri eq $ATOM_NS) {
      my $not_allowed;
      if ($child_ln eq 'entry') {
        $element_state->{has_element}->{entry} = 1;
      } elsif ({
                generator => 1,
                icon => 1,
                id => 1,
                logo => 1,
                rights => 1,
                subtitle => 1,
                title => 1,
                updated => 1,
               }->{$child_ln}) {
        unless ($element_state->{has_element}->{$child_ln}) {
          $element_state->{has_element}->{$child_ln} = 1;
          $not_allowed = $element_state->{has_element}->{entry};
        } else {
          $not_allowed = 1;
        }
      } elsif ($child_ln eq 'link') {
        if ($child_el->rel eq $LINK_REL . 'alternate') {
          my $type = $child_el->get_attribute_ns (undef, 'type');
          $type = '' unless defined $type;
          my $hreflang = $child_el->get_attribute_ns (undef, 'hreflang');
          $hreflang = '' unless defined $hreflang;
          my $key = 'link:'.(defined $type ? ':'.$type : '').':'.
              (defined $hreflang ? ':'.$hreflang : '');
          unless ($element_state->{has_element}->{$key}) {
            $element_state->{has_element}->{$key} = 1;
          } else {
            $not_allowed = 1;
          }
        }
        $not_allowed ||= $element_state->{has_element}->{entry};
      } elsif ({
                category => 1,
                contributor => 1,
               }->{$child_ln}) {
        $not_allowed = $element_state->{has_element}->{entry};
      } elsif ($child_ln eq 'author') {
        $not_allowed = $element_state->{has_element}->{entry};
        $item->{parent_state}->{has_author} = 1; # parent::atom:entry's flag
      } else {
        $not_allowed = 1;
      }
      if ($not_allowed) {
        $self->{onerror}->(node => $child_el, type => 'element not allowed',
                           level => $self->{level}->{must});
      }
    } else {
      ## TODO: extension element
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

$Element->{$ATOM_NS}->{subtitle} = \%AtomTextConstruct;

$Element->{$ATOM_NS}->{summary} = \%AtomTextConstruct;

$Element->{$ATOM_NS}->{title} = \%AtomTextConstruct;

$Element->{$ATOM_NS}->{updated} = \%AtomDateConstruct;

## TODO: signature element

## TODO: simple extension element and structured extension element

## -- Atom Threading 1.0 [RFC 4685]

$Element->{$THR_NS}->{''} = {
  %AtomChecker,
  status => 0,
};

## ISSUE: Strictly speaking, thr:* element/attribute,
## where * is an undefined local name, is not disallowed.

$Element->{$THR_NS}->{'in-reply-to'} = {
  %AtomChecker,
  status => FEATURE_RFC4685,
  check_attrs => $GetAtomAttrsChecker->({
    href => $AtomIRIReferenceAttrChecker,
        ## TODO: fact-level.
        ## TODO: MUST be dereferencable.
    ref => sub {
      my ($self, $attr, $item, $element_state) = @_;
      $element_state->{has_ref} = 1;

      ## NOTE: Same as |atom:id|.
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri ($attr->value, sub {
        $self->{onerror}->(@_, node => $attr);
      }, $self->{level});

      ## TODO: Check against ID guideline...
    },
    source => $AtomIRIReferenceAttrChecker,
        ## TODO: fact-level.
        ## TODO: MUST be dereferencable.
    type => $AtomIMTAttrChecker,
        ## TODO: fact-level.
  }, {
    href => FEATURE_RFC4685,
    source => FEATURE_RFC4685,
    ref => FEATURE_RFC4685,
    type => FEATURE_RFC4685,
  }),
  check_end => sub {
    my ($self, $item, $element_state) = @_;
  
    unless ($element_state->{has_ref}) {
      $self->{onerror}->(node => $item->{node},
                         type => 'attribute missing',
                         text => 'ref',
                         level => $self->{level}->{must});
    }

    $AtomChecker{check_end}->(@_);
  },
  ## NOTE: Content model has no constraint.
};

$Element->{$THR_NS}->{total} = {
  %AtomChecker,
  check_start =>  sub {
    my ($self, $item, $element_state) = @_;
    $element_state->{value} = '';
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
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed',
                         level => $self->{level}->{must});
    }
  },
  check_child_text => sub {
    my ($self, $item, $child_node, $has_significant, $element_state) = @_;
    $element_state->{value} .= $child_node->data;
  },
  check_end => sub {
    my ($self, $item, $element_state) = @_;

    ## NOTE: xsd:nonNegativeInteger
    unless ($element_state->{value} =~ /\A(?>[0-9]+|-0+)\z/) {
      $self->{onerror}->(node => $item->{node},
                         type => 'invalid attribute value', 
                         level => $self->{level}->{must});
    }

    $AtomChecker{check_end}->(@_);
  },
};

## TODO: fh:complete

## TODO: fh:archive

## TODO: Check as archive document, page feed document, ...

## TODO: APP [RFC 5023]

$Whatpm::ContentChecker::Namespace->{$ATOM_NS}->{loaded} = 1;
$Whatpm::ContentChecker::Namespace->{$THR_NS}->{loaded} = 1;

1;
