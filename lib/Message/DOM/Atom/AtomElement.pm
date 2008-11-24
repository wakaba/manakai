package Message::DOM::Atom::AtomElement;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Element';
require Message::DOM::Element;

my $ATOM_NS = q<http://www.w3.org/2005/Atom>;
my $CREATE_CHILD_URI = q<http://suika.fam.cx/www/2006/dom-config/create-child-element>;

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  return if $method_name =~ /::DESTROY$/;

  my $ln;
  if ($ln = {  ## Reflecting the string value of a content attribute
    'Message::DOM::Atom::AtomElement::AtomCategoryElement::label' => 'label',
    'Message::DOM::Atom::AtomElement::AtomCategoryElement::term' => 'term',
    'Message::DOM::Atom::AtomElement::AtomGeneratorElement::version' => 'version',
    'Message::DOM::Atom::AtomElement::AtomLinkElement::hreflang' => 'hreflang',
    'Message::DOM::Atom::AtomElement::AtomLinkElement::title' => 'title',
    'Message::DOM::Atom::AtomElement::AtomLinkElement::length' => 'length',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        local \$Error::Depth = \$Error::Depth + 1;

        if (\@_ > 1) {
          if (defined \$_[1]) {
            \$_[0]->set_attribute_ns (undef, '$ln', ''.\$_[1]);
          } else {
            \$_[0]->remove_attribute_ns (undef, '$ln');
          }
          return unless defined wantarray;
        }

        return \$_[0]->get_attribute_ns (undef, '$ln');
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Reflecting the URI value of a content attribute
    'Message::DOM::Atom::AtomElement::AtomContentElement::src' => 'src',
    'Message::DOM::Atom::AtomElement::AtomCategoryElement::scheme' => 'scheme',
    'Message::DOM::Atom::AtomElement::AtomGeneratorElement::uri' => 'uri',
    'Message::DOM::Atom::AtomElement::AtomLinkElement::href' => 'href',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        local \$Error::Depth = \$Error::Depth + 1;

        if (\@_ > 1) {
          if (defined \$_[1]) {
            \$_[0]->set_attribute_ns (undef, '$ln', ''.\$_[1]);
          } else {
            \$_[0]->remove_attribute_ns (undef, '$ln');
          }
          return unless defined wantarray;
        }
        
        my \$v = \$_[0]->get_attribute_ns (undef, '$ln');
        if (defined \$v) {
          my \$base = \$_[0]->base_uri;
          if (defined \$base) {
            return \$_[0]->owner_document->implementation
                ->create_uri_reference (\$v)
                ->get_absolute_reference (\$base)->uri_reference;
          } else {
            return \$v;
          }
        } else {
          return undef; 
        }
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Reflecting the string value of a child element
    'Message::DOM::Atom::AtomElement::AtomPersonConstruct::email' => 'email',
    'Message::DOM::Atom::AtomElement::AtomPersonConstruct::name' => 'name',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::id' => 'id',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::id' => 'id',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::id' => 'id',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        no warnings 'uninitialized';
        local \$Error::Depth = \$Error::Depth + 1;

        if (\@_ > 1) {
          if (defined \$_[1]) {
            my \$target;
            E: {
              for my \$cl (\@{\$_[0]->child_nodes}) {
                if (\$cl->node_type == 1 and # ELEMENT_NODE
                    \$cl->manakai_local_name eq '$ln' and
                    \$cl->namespace_uri eq '$ATOM_NS') {
                  \$target = \$cl;
                  last E;
                }
              }

              \$target = \$_[0]->owner_document->create_element_ns
                  ('$ATOM_NS', '$ln');
              \$_[0]->append_child (\$target);
            } # E
 
            return \$target->text_content (\$_[1]);
          } else {
            my \@remove;
            for my \$cl (\@{\$_[0]->child_nodes}) {
              if (\$cl->node_type == 1 and # ELEMENT_NODE
                  \$cl->manakai_local_name eq '$ln' and
                  \$cl->namespace_uri eq '$ATOM_NS') {
                push \@remove, \$cl;
              }
            }
            
            \$_[0]->remove_child (\$_) for \@remove;
            return undef;
          }
        }

        for my \$cl (\@{\$_[0]->child_nodes}) {
          if (\$cl->node_type == 1 and # ELEMENT_NODE
              \$cl->manakai_local_name eq '$ln' and
              \$cl->namespace_uri eq '$ATOM_NS') {
            return \$cl->text_content;
          }
        }

        return undef;
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Reflecting the URI value of a child element
    'Message::DOM::Atom::AtomElement::AtomPersonConstruct::uri' => 'uri',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::icon' => 'icon',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::logo' => 'logo',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::icon' => 'icon',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::logo' => 'logo',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        no warnings 'uninitialized';
        local \$Error::Depth = \$Error::Depth + 1;

        if (\@_ > 1) {
          if (defined \$_[1]) {
            my \$target;
            E: {
              for my \$cl (\@{\$_[0]->child_nodes}) {
                if (\$cl->node_type == 1 and # ELEMENT_NODE
                    \$cl->manakai_local_name eq '$ln' and
                    \$cl->namespace_uri eq '$ATOM_NS') {
                  \$target = \$cl;
                  last E;
                }
              }

              \$target = \$_[0]->owner_document->create_element_ns
                  ('$ATOM_NS', '$ln');
              \$_[0]->append_child (\$target);
            } # E
 
            \$target->text_content (\$_[1]);
            return unless defined wantarray;
          } else {
            my \@remove;
            for my \$cl (\@{\$_[0]->child_nodes}) {
              if (\$cl->node_type == 1 and # ELEMENT_NODE
                  \$cl->manakai_local_name eq '$ln' and
                  \$cl->namespace_uri eq '$ATOM_NS') {
                push \@remove, \$cl;
              }
            }
            
            \$_[0]->remove_child (\$_) for \@remove;
            return undef;
          }
        }

        for my \$cl (\@{\$_[0]->child_nodes}) {
          if (\$cl->node_type == 1 and # ELEMENT_NODE
              \$cl->manakai_local_name eq '$ln' and
              \$cl->namespace_uri eq '$ATOM_NS') {
            my \$base = \$cl->base_uri;
            if (defined \$base) {
              return \$cl->owner_document->implementation
                  ->create_uri_reference (\$cl->text_content)
                  ->get_absolute_reference (\$base)->uri_reference;
            } else {
              return \$cl->text_content;
            }
          }
        }

        return undef;
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Return the child element
    'Message::DOM::Atom::AtomElement::AtomPersonConstruct::name_element' => 'name',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::generator_element' => 'generator',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::rights_element' => 'rights',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::subtitle_element' => 'subtitle',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::title_element' => 'title',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::updated_element' => 'updated',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::content_element' => 'content',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::published_element' => 'published',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::rights_element' => 'rights',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::source_element' => 'source',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::summary_element' => 'summary',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::title_element' => 'title',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::updated_element' => 'updated',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::generator_element' => 'generator',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::rights_element' => 'rights',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::subtitle_element' => 'subtitle',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::title_element' => 'title',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::updated_element' => 'updated',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        no warnings 'uninitialized';
        local \$Error::Depth = \$Error::Depth + 1;

        for my \$el (\@{\$_[0]->child_nodes}) {
          if (\$el->node_type == 1 and # ELEMENT_NODE
              \$el->manakai_local_name eq '$ln' and
              \$el->namespace_uri eq '$ATOM_NS') {
            return \$el;
          }
        }
        
        my \$od = \$_[0]->owner_document;
        if (\$od->dom_config->get_parameter ('$CREATE_CHILD_URI')) {
          return \$_[0]->append_child
             (\$od->create_element_ns ('$ATOM_NS', '$ln'));
        } else {
          return undef;
        }
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Return a child element list
    'Message::DOM::Atom::AtomElement::AtomFeedElement::author_elements' => 'author',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::category_elements' => 'category',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::contributor_elements' => 'contributor',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::entry_elements' => 'entry',
    'Message::DOM::Atom::AtomElement::AtomFeedElement::link_elements' => 'link',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::author_elements' => 'author',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::category_elements' => 'category',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::contributor_elements' => 'contributor',
    'Message::DOM::Atom::AtomElement::AtomEntryElement::link_elements' => 'link',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::author_elements' => 'author',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::category_elements' => 'category',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::contributor_elements' => 'contributor',
    'Message::DOM::Atom::AtomElement::AtomSourceElement::link_elements' => 'link',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        local \$Error::Depth = \$Error::Depth + 1;
        no warnings 'uninitialized';
        my \$r = [];
        for my \$el (\@{\$_[0]->child_nodes}) {
          if (\$el->node_type == 1 and # ELEMENT_NODE
              \$el->manakai_local_name eq '$ln' and
              \$el->namespace_uri eq '$ATOM_NS') {
            push \@\$r, \$el;
          }
        }
        require Message::DOM::NodeList;
        return bless \$r, 'Message::DOM::NodeList::StaticNodeList';
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

package Message::DOM::Atom::AtomElement::AtomTextConstruct;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub container ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $type = $_[0]->type;
  if ($type eq 'xhtml') {
    ## "Return the child element"
    no warnings 'uninitialized';
    for my $el (@{$_[0]->child_nodes}) {
      if ($el->node_type == 1 and # ELEMENT_NODE
          $el->manakai_local_name eq 'div' and
          $el->namespace_uri eq q<http://www.w3.org/1999/xhtml>) {
        return $el;
      }
    }

    my $od = $_[0]->owner_document;
    if ($od->dom_config->get_parameter ($CREATE_CHILD_URI)) {
      return $_[0]->append_child
          ($od->create_element_ns (q<http://www.w3.org/1999/xhtml>, 'div'));
    } else {
      return undef;
    }
  } else {
    return $_[0];
  }
} # container

sub type ($;$) {
  local $Error::Depth = $Error::Depth + 1;

  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->set_attribute_ns (undef, 'type', ''.$_[1]);
    } else {
      $_[0]->remove_attribute_ns (undef, 'type');
    }

    return unless defined wantarray;
  }

  my $v = $_[0]->get_attribute_ns (undef, 'type');
  return defined $v ? $v : 'text';
} # type

package Message::DOM::Atom::AtomElement::AtomPersonConstruct;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub email ($;$);

sub name ($;$);

sub name_element ($);

sub uri ($;$);

package Message::DOM::Atom::AtomElement::AtomDateConstruct;
push our @ISA, 'Message::DOM::Atom::AtomElement';

## TODO: Use HTML5 algorithm
sub value ($;$) {
  local $Error::Depth = $Error::Depth + 1;

  if (@_ > 1) {
    my $given = 0+($_[1] or 0);
    my @value = gmtime (int ($given / 1));
    my $value = sprintf '%04d-%02d-%02dT%02d:%02d:%02d',
        $value[5] + 1900, $value[4] + 1,
        $value[3], $value[2], $value[1], $value[0];
    my $f = $given % 1;
    $value .= substr (''.$f, 1) if $f;
    $value .= 'Z';
    $_[0]->text_content ($value);
    return unless defined wantarray;
  }

  my $value = $_[0]->text_content;
  if ($value =~ /\A(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(\.\d+)?
      (?:Z|([+-]\d+):(\d+))\z/x) {
    require Time::Local;
    my $r = Time::Local::timegm_nocheck
        ($6, defined $8 ? $8 > 0 ? $5 - $9 : $5 + $9 : $5,
         defined $8 ? $4 - $8 : $4, $3, $2-1, $1-1900);
    $r += "0$7" if defined $7;
    return $r;
  } else {
    return 0;
  }  
} # value

package Message::DOM::Atom::AtomElement::AtomFeedElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub add_new_entry ($$;$$) {
  local $Error::Depth = $Error::Depth + 1;
  
  my $od = $_[0]->owner_document;
  my $r = $od->create_element_ns ($ATOM_NS, 'entry');
  $r->manakai_language (''.$_[3]) if defined $_[3];
  $r->id (''.$_[1]);
  
  my $titlee = $od->create_element_ns ($ATOM_NS, 'title');
  $titlee->text_content (defined $_[2] ? ''.$_[2] : '');
  $r->append_child ($titlee);

  my $updatede = $od->create_element_ns ($ATOM_NS, 'updated');
  $updatede->value (scalar time);
  $r->append_child ($updatede);

  my $first_entry;
  for (@{$_[0]->child_nodes}) {
    next unless $_->node_type == 1; # ELEMENT_NODE;
    next unless $_->manakai_local_name eq 'entry';
    my $nsurl = $_->namespace_uri;
    next unless defined $nsurl;
    next unless $nsurl eq $ATOM_NS;
    $first_entry = $_;
    last;
  }

  return $_[0]->insert_before ($r, $first_entry);
} # add_new_entry

sub author_elements ($);

sub category_elements ($);

sub contributor_elements ($);

sub entry_elements ($);

sub generator_element ($);

sub get_entry_element_by_id ($$) {
  my $id = ''.$_[1];
  no warnings 'uninitialized';
  local $Error::Depth = $Error::Depth + 1;

  for my $cn (@{$_[0]->child_nodes}) {
    if ($cn->node_type == 1 and # ELEMENT_NODE
        $cn->manakai_local_name eq 'entry' and
        $cn->namespace_uri eq $ATOM_NS) {
      if ($cn->id eq $id) {
        return $cn;
      }
    }
  }

  ## TODO: documentation
  my $od = $_[0]->owner_document;
  if ($od->dom_config->get_parameter ($CREATE_CHILD_URI)) {
    my $r = $_[0]->append_child ($od->create_element_ns ($ATOM_NS, 'entry'));
    $r->id ($id);

    my $titlee = $od->create_element_ns ($ATOM_NS, 'title');
    $r->append_child ($titlee);

    my $updatede = $od->create_element_ns ($ATOM_NS, 'updated');
    $updatede->value (scalar time);
    $r->append_child ($updatede);

    return $r;
  } else {
    return undef;
  }
} # get_entry_element_by_id

sub icon ($;$);

sub id ($;$);

sub link_elements ($);

sub logo ($;$);

sub rights_element ($);

sub subtitle_element ($);

sub title_element ($);

sub updated_element ($);

package Message::DOM::Atom::AtomElement::AtomEntryElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub author_elements ($);

sub entry_author_elements ($) {
  no warnings 'uninitialized';
  local $Error::Depth = $Error::Depth + 1;

  require Message::DOM::NodeList;
  my $r = bless [], 'Message::DOM::NodeList::StaticNodeList';
  my $source;
  for my $cn (@{$_[0]->child_nodes}) {
    if ($cn->node_type == 1 and # ELEMENT_NODE
        $cn->namespace_uri eq $ATOM_NS) {
      my $ln = $cn->manakai_local_name;
      if ($ln eq 'author') {
        push @$r, $cn;
      } elsif ($cn->manakai_local_name eq 'source') {
        $source = $cn;
      }
    }
  }
  return $r unless @$r == 0;
  
  if (defined $source) {
    $r = $source->author_elements;
    return $r unless @$r == 0;
  }
  
  my $parent = $_[0]->parent_node;
  if (defined $parent and
      $parent->node_type == 1 and # ELEMENT_NODE
      $parent->manakai_local_name eq 'feed' and
      $parent->namespace_uri eq $ATOM_NS) {
    return $parent->author_elements;
  }
  
  return $r;
} # entry_author_elements

sub category_elements ($);

sub content_element ($);

sub contributor_elements ($);

sub id ($;$);

sub link_elements ($);

sub published_element ($);

sub rights_element ($);

sub entry_rights_element ($) {
  no warnings 'uninitialized';
  local $Error::Depth = $Error::Depth + 1;

  for my $cn (@{$_[0]->child_nodes}) {
    if ($cn->node_type == 1 and # ELEMENT_NODE
        $cn->manakai_local_name eq 'rights' and
        $cn->namespace_uri eq $ATOM_NS) {
      return $cn;
    }
  }

  my $parent = $_[0]->parent_node;
  if (defined $parent and
      $parent->node_type == 1 and # ELEMENT_NODE
      $parent->manakai_local_name eq 'feed' and
      $parent->namespace_uri eq $ATOM_NS) {
    for my $cn (@{$parent->child_nodes}) {
      if ($cn->node_type == 1 and # ELEMENT_NODE
          $cn->manakai_local_name eq 'rights' and
          $cn->namespace_uri eq $ATOM_NS) {
        return $cn;
      }
    }
  }

  my $od = $_[0]->owner_document;
  if ($od->dom_config->get_parameter ($CREATE_CHILD_URI)) {
    return $_[0]->append_child ($od->create_element_ns ($ATOM_NS, 'rights'));
  }
} # entry_rights_element

sub source_element ($);

sub summary_element ($);

sub title_element ($);

sub updated_element ($);

package Message::DOM::Atom::AtomElement::AtomContentElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub container ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $type = $_[0]->type;
  if ($type eq 'xhtml') {
    ## "Return the child element"
    no warnings 'uninitialized';
    for my $el (@{$_[0]->child_nodes}) {
      if ($el->node_type == 1 and # ELEMENT_NODE
          $el->manakai_local_name eq 'div' and
          $el->namespace_uri eq q<http://www.w3.org/1999/xhtml>) {
        return $el;
      }
    }

    my $od = $_[0]->owner_document;
    if ($od->dom_config->get_parameter ($CREATE_CHILD_URI)) {
      return $_[0]->append_child
          ($od->create_element_ns (q<http://www.w3.org/1999/xhtml>, 'div'));
    } else {
      return undef;
    }
  } elsif ($_[0]->has_attribute_ns (undef, 'src')) {
    return undef;
  } else {
    return $_[0];
  }
} # container

sub src ($;$);

sub type ($;$) {
  local $Error::Depth = $Error::Depth + 1;

  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->set_attribute_ns (undef, 'type', ''.$_[1]);
    } else {
      $_[0]->remove_attribute_ns (undef, 'type');
    }

    return unless defined wantarray;
  }

  my $v = $_[0]->get_attribute_ns (undef, 'type');
  return defined $v ? $v : $_[0]->has_attribute_ns (undef, 'src') ? undef : 'text';
} # type

package Message::DOM::Atom::AtomElement::AtomCategoryElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub label ($;$);

sub scheme ($;$);

sub term ($;$);

package Message::DOM::Atom::AtomElement::AtomGeneratorElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub uri ($;$);

sub version ($;$);

package Message::DOM::Atom::AtomElement::AtomLinkElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub href ($;$);

sub hreflang ($;$);

sub length ($;$);

sub rel ($;$) {
  local $Error::Depth = $Error::Depth + 1;

  if (@_ > 1) {
    if (defined $_[1]) {
      my $given = ''.$_[1];
      $given =~ s[\Ahttp://www.iana.org/assignments/relation/([^:/?#]+)\z][$1];
      $_[0]->set_attribute_ns (undef, 'rel', $given);
    } else {
      $_[0]->remove_attribute_ns (undef, 'rel');
    }

    return unless defined wantarray;
  }

  my $v = $_[0]->get_attribute_ns (undef, 'rel');
  if (defined $v and index ($v, ':') == -1) {
    return q<http://www.iana.org/assignments/relation/> . $v;
  } elsif (defined $v) {
    return $v;
  } else {
    return q<http://www.iana.org/assignments/relation/alternate>;
  }
} # rel

sub title ($;$);

sub type ($;$) {
  local $Error::Depth = $Error::Depth + 1;

  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->set_attribute_ns (undef, 'type', ''.$_[1]);
    } else {
      $_[0]->remove_attribute_ns (undef, 'type');
    }

    return unless defined wantarray;
  }

  my $v = $_[0]->get_attribute_ns (undef, 'type');
  if (defined $v) {
    return $v;
  } else {
    my $rel = $_[0]->rel;
    if (defined $rel and
        $rel eq q<http://www.iana.org/assignments/relation/replies>) {
      return q<application/atom+xml>;
    }
  }
  return undef;
} # type

package Message::DOM::Atom::AtomElement::AtomSourceElement;
push our @ISA, 'Message::DOM::Atom::AtomElement';

sub author_elements ($);

sub category_elements ($);

sub contributor_elements ($);

sub generator_element ($);

sub icon ($;$);

sub id ($;$);

sub link_elements ($);

sub logo ($;$);

sub rights_element ($);

sub subtitle_element ($);

sub title_element ($);

sub updated_element ($);

## TODO: Threading extension

package Message::DOM::DOMImplementation;

sub create_atom_entry_document ($$;$$) {
  local $Error::Depth = $Error::Depth + 1;
  
  my $r = $_[0]->create_document ($ATOM_NS, 'entry');
  $r->xml_version ('1.0');

  my $feede = $r->document_element;
  $feede->manakai_language (defined $_[3] ? $_[3] : '');
  $feede->id (''.$_[1]);

  my $titlee = $r->create_element_ns ($ATOM_NS, 'title');
  $titlee->text_content (defined $_[2] ? $_[2] : '');
  $feede->append_child ($titlee);

  my $updatede = $r->create_element_ns ($ATOM_NS, 'updated');
  $updatede->value (scalar time);
  $feede->append_child ($updatede);

  return $r;
} # create_atom_entry_document

sub create_atom_feed_document ($$;$$) {
  local $Error::Depth = $Error::Depth + 1;
  
  my $r = $_[0]->create_document ($ATOM_NS, 'feed');
  $r->xml_version ('1.0');

  my $feede = $r->document_element;
  $feede->manakai_language (defined $_[3] ? $_[3] : '');
  $feede->id (''.$_[1]);

  my $titlee = $r->create_element_ns ($ATOM_NS, 'title');
  $titlee->text_content (defined $_[2] ? $_[2] : '');
  $feede->append_child ($titlee);

  my $updatede = $r->create_element_ns ($ATOM_NS, 'updated');
  $updatede->value (scalar time);
  $feede->append_child ($updatede);

  return $r;
} # create_atom_feed_document

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2008/11/24 06:45:24 $
