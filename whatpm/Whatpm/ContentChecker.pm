package Whatpm::ContentChecker;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.54 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Whatpm::URIChecker;

## ISSUE: How XML and XML Namespaces conformance can (or cannot)
## be applied to an in-memory representation (i.e. DOM)?

## TODO: Conformance of an HTML document with non-html root element.

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;
my $XML_NS = q<http://www.w3.org/XML/1998/namespace>;
my $XMLNS_NS = q<http://www.w3.org/2000/xmlns/>;

my $Namespace = {
  q<http://www.w3.org/2005/Atom> => {module => 'Whatpm::ContentChecker::Atom'},
  $HTML_NS => {module => 'Whatpm::ContentChecker::HTML'},
  $XML_NS => {loaded => 1},
  $XMLNS_NS => {loaded => 1},
};

our $AttrChecker = {
  $XML_NS => {
    space => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value eq 'default' or $value eq 'preserve') {
        #
      } else {
        ## NOTE: An XML "error"
        $self->{onerror}->(node => $attr, level => 'error',
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
          my %opt = @_;
          my $type = 'LangTag:'.$opt{type};
          $type .= ':' . $opt{subtag} if defined $opt{subtag};
          $self->{onerror}->(node => $attr, type => $type,
                             value => $opt{value}, level => $opt{level});
        });
      }

      ## NOTE: "The values of the attribute are language identifiers
      ## as defined by [IETF RFC 3066], Tags for the Identification
      ## of Languages, or its successor; in addition, the empty string
      ## may be specified." ("may" in lower case)
      ## NOTE: Is an RFC 3066-valid (but RFC 4647-invalid) language tag
      ## allowed today?

      ## TODO: test data

      if ($attr->owner_document->manakai_is_html) { # MUST NOT
        $self->{onerror}->(node => $attr, type => 'in HTML:xml:lang');
## TODO: Test data...
      }
    },
    base => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value =~ /[^\x{0000}-\x{10FFFF}]/) { ## ISSUE: Should we disallow noncharacters?
        $self->{onerror}->(node => $attr,
                           type => 'invalid attribute value');
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
      if ($self->{id}->{$value}) { ## NOTE: An xml:id error
        $self->{onerror}->(node => $attr, level => 'error', 
                           type => 'duplicate ID');
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
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xml');
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xmlns');
      }
      if ($ln eq 'xml' and $value ne $XML_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:xmlns:xml=');
      } elsif ($ln eq 'xmlns') {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:xmlns:xmlns=');
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
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xml');
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xmlns');
      }
    },
  },
};

## ISSUE: Should we really allow these attributes?
$AttrChecker->{''}->{'xml:space'} = $AttrChecker->{$XML_NS}->{space};
$AttrChecker->{''}->{'xml:lang'} = $AttrChecker->{$XML_NS}->{lang};
$AttrChecker->{''}->{'xml:base'} = $AttrChecker->{$XML_NS}->{base};
$AttrChecker->{''}->{'xml:id'} = $AttrChecker->{$XML_NS}->{id};

## ANY
our $AnyChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $todo->{flag}->{has_descendant}->{significant} = 1;
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($new_todos);
}; # $AnyChecker

our $ElementDefault = {
  checker => sub {
    my ($self, $todo) = @_;
    $self->{onerror}->(node => $todo->{node}, level => 'unsupported',
                       type => 'element');
    return $AnyChecker->($self, $todo);
  },
  attrs_checker => sub {
    my ($self, $todo) = @_;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker = $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr);
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
      }
    }
  },
};

my $HTMLTransparentElements = {
  $HTML_NS => {qw/ins 1 font 1 noscript 1/},
  ## NOTE: |html:noscript| is transparent if scripting is disabled
  ## and not in |head|.
};

our $Element = {};

sub check_document ($$$) {
  my ($self, $doc, $onerror) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;

  $self->{must_level} = 'm';
  $self->{fact_level} = 'f';
  $self->{should_level} = 's';
  $self->{good_level} = 'w';

  my $docel = $doc->document_element;
  unless (defined $docel) {
    ## ISSUE: Should we check content of Document node?
    $onerror->(node => $doc, type => 'no document element');
    ## ISSUE: Is this non-conforming (to what spec)?  Or just a warning?
    return {
            class => {},
            id => {}, table => [], term => {},
           };
  }

  ## ISSUE: Unexpanded entity references and HTML5 conformance
  
  my $docel_nsuri = $docel->namespace_uri;
  $docel_nsuri = '' unless defined $docel_nsuri;
  unless ($Namespace->{$docel_nsuri}->{loaded}) {
    if ($Namespace->{$docel_nsuri}->{module}) {
      eval qq{ require $Namespace->{$docel_nsuri}->{module} } or die $@;
    } else {
      $Namespace->{$docel_nsuri}->{loaded} = 1;
    }
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
      $onerror->(node => $docel, type => 'element not allowed:root:xml');
    }
  } else {
    $onerror->(node => $docel, type => 'element not allowed:root');
  }

  ## TODO: Check for other items other than document element
  ## (second (errorous) element, text nodes, PI nodes, doctype nodes)

  my $return = $self->check_element ($docel, $onerror);

  ## TODO: Test for these checks are necessary.
  my $charset_name = $doc->input_encoding;
  if (defined $charset_name) {
    require Message::Charset::Info;
    my $charset = $Message::Charset::Info::IANACharset->{$charset_name};

    if ($doc->manakai_is_html and
        not $doc->manakai_has_bom and
        not defined $doc->manakai_charset) {
      unless ($charset->{is_html_ascii_superset}) {
        $onerror->(node => $doc, level => $self->{must_level},
                   type => 'non ascii superset:'.$charset_name);
      }
      
      if (not $self->{has_charset} and
          not $charset->{iana_names}->{'us-ascii'}) {
        $onerror->(node => $doc, level => $self->{must_level},
                   type => 'no character encoding declaration:'.$charset_name);
      }
    }

    if ($charset->{iana_names}->{'utf-8'}) {
      #
    } elsif ($charset->{iana_names}->{'jis_x0212-1990'} or
             $charset->{iana_names}->{'x-jis0208'} or
             $charset->{iana_names}->{'utf-32'} or ## ISSUE: UTF-32BE? UTF-32LE?
             $charset->{is_ebcdic_based}) {
      $onerror->(node => $doc,
                 type => 'character encoding:'.$charset_name,
                 level => $self->{should_level});
    } elsif ($charset->{iana_names}->{'cesu-8'} or
             $charset->{iana_names}->{'utf-8'} or ## ISSUE: UNICODE-1-1-UTF-7?
             $charset->{iana_names}->{'bocu-1'} or
             $charset->{iana_names}->{'scsu'}) {
      $onerror->(node => $doc,
                 type => 'character encoding:'.$charset_name,
                 level => $self->{must_level});
    } else {
      $onerror->(node => $doc,
                 type => 'character encoding:'.$charset_name,
                 level => $self->{good_level});
    }
  } elsif ($doc->manakai_is_html) {
    ## NOTE: MUST and SHOULD requirements above cannot be tested,
    ## since the document has no input charset encoding information.
    $onerror->(node => $doc,
               type => 'character encoding:',
               level => 'unsupported');
  }

  return $return;
} # check_document

sub check_element ($$$) {
  my ($self, $el, $onerror) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;

  $self->{must_level} = 'm';
  $self->{fact_level} = 'f';
  $self->{should_level} = 's';
  $self->{good_level} = 'w';

  $self->{pluses} = {};
  $self->{minuses} = {};
  $self->{id} = {};
  $self->{term} = {};
  $self->{usemap} = [];
  $self->{contextmenu} = [];
  $self->{map} = {};
  $self->{menu} = {};
  $self->{has_link_type} = {};
  #$self->{has_uri_attr};
  #$self->{has_hyperlink_element};
  #$self->{has_charset};
  $self->{return} = {
    class => {},
    id => $self->{id}, table => [], term => $self->{term},
  };

  my @todo = ({type => 'element', node => $el});
  while (@todo) {
    my $todo = shift @todo;
    if ($todo->{type} eq 'element') {
      my $prefix = $todo->{node}->prefix;
      if (defined $prefix and $prefix eq 'xmlns') {
        $self->{onerror}
          ->(node => $todo->{node}, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:<xmlns:>');
      }
      my $nsuri = $todo->{node}->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      unless ($Namespace->{$nsuri}->{loaded}) {
        if ($Namespace->{$nsuri}->{module}) {
          eval qq{ require $Namespace->{$nsuri}->{module} } or die $@;
        } else {
          $Namespace->{$nsuri}->{loaded} = 1;
        }
      }
      my $ln = $todo->{node}->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
          $ElementDefault;
      $eldef->{attrs_checker}->($self, $todo);
      my ($new_todos) = $eldef->{checker}->($self, $todo);
      unshift @todo, @$new_todos;
    } elsif ($todo->{type} eq 'element-attributes') {
      my $prefix = $todo->{node}->prefix;
      if (defined $prefix and $prefix eq 'xmlns') {
        $self->{onerror}
          ->(node => $todo->{node}, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:<xmlns:>');
      }
      my $nsuri = $todo->{node}->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      unless ($Namespace->{$nsuri}->{loaded}) {
        if ($Namespace->{$nsuri}->{module}) {
          eval qq{ require $Namespace->{$nsuri}->{module} } or die $@;
        } else {
          $Namespace->{$nsuri}->{loaded} = 1;
        }
      }
      my $ln = $todo->{node}->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
          $ElementDefault;
      $eldef->{attrs_checker}->($self, $todo);
    } elsif ($todo->{type} eq 'descendant') {
      for my $key (keys %{$todo->{errors}}) {
        unless ($todo->{flag}->{has_descendant}->{$key}) {
          $todo->{errors}->{$key}->($self, $todo);
        }
        for my $key (keys %{$todo->{old_values}}) {
          $todo->{flag}->{has_descendant}->{$key}
              ||= $todo->{old_values}->{$key};
        }
      }
    } elsif ($todo->{type} eq 'plus' or $todo->{type} eq 'minus') {
      $self->_remove_minuses ($todo);
    } elsif ($todo->{type} eq 'code') {
      $todo->{code}->();
    } else {
      die "$0: Internal error: Unsupported checking action type |$todo->{type}|";
    }
  }

  for (@{$self->{usemap}}) {
    unless ($self->{map}->{$_->[0]}) {
      $self->{onerror}->(node => $_->[1], type => 'no referenced map');
    }
  }

  for (@{$self->{contextmenu}}) {
    unless ($self->{menu}->{$_->[0]}) {
      $self->{onerror}->(node => $_->[1], type => 'no referenced menu');
    }
  }

  delete $self->{pluses};
  delete $self->{minuses};
  delete $self->{onerror};
  delete $self->{id};
  delete $self->{usemap};
  delete $self->{map};
  return $self->{return};
} # check_element

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
            if ($cn->data =~ /[^\x09-\x0D\x20]/) {
              last CN;
            }
          }
        } # CN
        unshift @$sib, @cn;
      }
    }
    push @$new_todos, {type => 'element', node => $node};
  } # TP
  
  for my $new_todo (@$new_todos) {
    $new_todo->{flag} = {%{$parent_todo->{flag} or {}}};
  }
  
  return ($sib, $new_todos);
} # _check_get_children

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2007/11/25 08:04:20 $
