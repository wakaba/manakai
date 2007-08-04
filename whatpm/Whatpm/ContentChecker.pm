package Whatpm::ContentChecker;
use strict;

require Whatpm::URIChecker;

## ISSUE: How XML and XML Namespaces conformance can (or cannot)
## be applied to an in-memory representation (i.e. DOM)?

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;
my $XML_NS = q<http://www.w3.org/XML/1998/namespace>;
my $XMLNS_NS = q<http://www.w3.org/2000/xmlns/>;

my $Namespace = {
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
      ## NOTE: "The values of the attribute are language identifiers
      ## as defined by [IETF RFC 3066], Tags for the Identification
      ## of Languages, or its successor; in addition, the empty string
      ## may be specified." ("may" in lower case)
      $self->{onerror}->(node => $attr, level => 'unsupported',
                         type => 'language tag');
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
      push @$new_todos, {type => 'element', node => $node};
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
  my $docel_def = $Element->{$docel_nsuri}->{$docel->manakai_local_name} ||
    $Element->{$docel_nsuri}->{''} ||
    $ElementDefault;
  if ($docel_def->{is_root}) {
    #
  } else {
    $onerror->(node => $docel, type => 'element not allowed');
  }

  ## TODO: Check for other items other than document element
  ## (second (errorous) element, text nodes, PI nodes, doctype nodes)

  return $self->check_element ($docel, $onerror);
} # check_document

sub check_element ($$$) {
  my ($self, $el, $onerror) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;

  $self->{minuses} = {};
  $self->{id} = {};
  $self->{term} = {};
  $self->{usemap} = [];
  $self->{contextmenu} = [];
  $self->{map} = {};
  $self->{menu} = {};
  $self->{has_link_type} = {};
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
    } elsif ($todo->{type} eq 'plus') {
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

sub _remove_minuses ($$) {
  my ($self, $todo) = @_;
  for my $ns (keys %{$todo->{list}}) {
    for my $ln (keys %{$todo->{list}->{$ns}}) {
      delete $self->{minuses}->{$ns}->{$ln} if $todo->{list}->{$ns}->{$ln};
    }
  }
  1;
} # _remove_minuses

sub _check_get_children ($$$) {
  my ($self, $node, $parent_todo) = @_;
  my $new_todos = [];
  my $sib = [];
  TP: {
    my $node_ns = $node->namespace_uri;
    $node_ns = '' unless defined $node_ns;
    my $node_ln = $node->manakai_local_name;
    if ($node_ns eq $HTML_NS) {
      if ($node_ln eq 'noscript') {
        my $end = $self->_add_minuses ({$HTML_NS, {noscript => 1}});
        push @$sib, $end;
      }
    }
    ## TODO: |noscript| is not a transparent element in |head|.
    if ($HTMLTransparentElements->{$node_ns}->{$node_ln}) {
      unshift @$sib, @{$node->child_nodes};
      push @$new_todos, {type => 'element-attributes', node => $node};
      last TP;
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

1;
# $Date: 2007/08/04 13:48:25 $
