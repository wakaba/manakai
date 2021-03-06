package Whatpm::RDFXML;
use strict;

## NOTE: EntityReference nodes are not supported except that
## unexpected entity reference are simply ignored.  (In fact
## all EntityRefernce nodes are ignored.)

## TODO: Add a callback function invoked for every element
## when XMLCC is implemented in WDCC.

## ISSUE: <html:nest/> in RDF subtree?

## ISSUE: PIs in RDF subtree should be validated?

## TODO: Should we validate expanded URI created from QName?

## TODO: elements in null namespace (not mentioned in the spec.)

my $RDF_URI = q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>;

use Char::Class::XML qw(InXML_NCNameStartChar10 InXMLNCNameChar10);
require Whatpm::URIChecker;

sub new ($) {
  my $self = bless {
    level => {
      rdf_fact => 'm',
      rdf_grammer => 'm',
      rdf_lc_must => 'm',
      info => 'i',
    },
    next_id => 0,
  }, shift;
  $self->{onerror} = sub {
    my %opt = @_;
    warn $opt{type}, "\n";
  };
  $self->{ontriple} = sub {
    my %opt = @_;
    my $dump_resource = sub {
      my $resource = shift;
      if (defined $resource->{uri}) {
        return '<' . $resource->{uri} . '>';
      } elsif (defined $resource->{bnodeid}) {
        return '_:' . $resource->{bnodeid};
      } elsif ($resource->{nodes}) {
        return '"' . join ('', map {$_->inner_html} @{$resource->{nodes}}) .
            '"^^<' . $resource->{datatype} . '>';
      } elsif (defined $resource->{value}) {
        return '"' . $resource->{value} . '"' .
            (defined $resource->{datatype}
                 ? '^^<' . $resource->{datatype} . '>'
                 : '@' . $resource->{language});
      } else {
        return '??';
      }
    };
    print STDERR $dump_resource->($opt{subject}) . ' ';
    print STDERR $dump_resource->($opt{predicate}) . ' ';
    print STDERR $dump_resource->($opt{object}) . "\n";
    if ($dump_resource->{id}) {
      print STDERR $dump_resource->($dump_resource->{id}) . ' ';
      print STDERR $dump_resource->({uri => $RDF_URI . 'subject'}) . ' ';
      print STDERR $dump_resource->($opt{subject}) . "\n";
      print STDERR $dump_resource->($dump_resource->{id}) . ' ';
      print STDERR $dump_resource->({uri => $RDF_URI . 'predicate'}) . ' ';
      print STDERR $dump_resource->($opt{predicate}) . "\n";
      print STDERR $dump_resource->($dump_resource->{id}) . ' ';
      print STDERR $dump_resource->({uri => $RDF_URI . 'object'}) . ' ';
      print STDERR $dump_resource->($opt{object}) . "\n";
      print STDERR $dump_resource->($dump_resource->{id}) . ' ';
      print STDERR $dump_resource->({uri => $RDF_URI . 'type'}) . ' ';
      print STDERR $dump_resource->({uri => $RDF_URI . 'Statement'}) . "\n";
    }
  };
  return $self;
} # new

sub convert_document ($$) {
  my $self = shift;
  my $node = shift; # Document

  ## ISSUE: An RDF/XML document, either |doc| or |nodeElement|
  ## is allowed as a starting production.  However, |nodeElement|
  ## is not a Root Event.

  my $has_element;

  for my $cn (@{$node->child_nodes}) {
    if ($cn->node_type == $cn->ELEMENT_NODE) {
      unless ($has_element) {
        if ($cn->manakai_expanded_uri eq $RDF_URI . q<RDF>) {
          $self->convert_rdf_element ($cn, language => '');
        } else {
          $self->convert_rdf_node_element ($cn, language => '');
        }
        $has_element = 1;
      } else {
        $self->{onerror}->(type => 'second node element',
                           level => $self->{level}->{rdf_grammer},
                           node => $cn);
      }
    } elsif ($cn->node_type == $cn->TEXT_NODE or
             $cn->node_type == $cn->CDATA_SECTION_NODE) {
      $self->{onerror}->(type => 'character not allowed',
                         level => $self->{level}->{rdf_grammer},
                         node => $cn);
    }
  }
} # convert_document

my $check_rdf_namespace = sub {
  my $self = shift;
  my $node = shift;
  my $node_nsuri = $node->namespace_uri;
  return unless defined $node_nsuri;
  if (substr ($node_nsuri, 0, length $RDF_URI) eq $RDF_URI and
      length $RDF_URI < length $node_nsuri) {
    $self->{onerror}->(type => 'bad rdf namespace',
                       level => $self->{level}->{rdf_fact}, # Section 5.1
                       node => $node);
  }
}; # $check_rdf_namespace

sub convert_rdf_element ($$%) {
  my ($self, $node, %opt) = @_;
  $opt{language} = '' unless defined $opt{language};
      ## ISSUE: Not explicitly defined in the spec.

  $check_rdf_namespace->($self, $node);

  # |RDF|

  for my $attr (@{$node->attributes}) {
    my $nsuri = $attr->namespace_uri;
    if (defined $nsuri and
        $nsuri eq q<http://www.w3.org/XML/1998/namespace> and
        $attr->manakai_local_name eq 'lang') {
      $opt{language} = $attr->value;
      next;
    }

    my $prefix = $attr->prefix;
    if (defined $prefix) {
      next if $prefix =~ /^[Xx][Mm][Ll]/;
    } else {
      next if $attr->manakai_local_name =~ /^[Xx][Mm][Ll]/;
      ## TODO: "ignored" warning...
    }

    $check_rdf_namespace->($self, $attr);
    $self->{onerror}->(type => 'attribute not allowed',
                       level => $self->{level}->{rdf_grammer},
                       node => $attr);
  }

  # |nodeElementList|
  for my $cn (@{$node->child_nodes}) {
    if ($cn->node_type == $cn->ELEMENT_NODE) {
      $self->convert_node_element ($cn, language => $opt{language});
    } elsif ($cn->node_type == $cn->TEXT_NODE or
             $cn->node_type == $cn->CDATA_SECTION_NODE) {
      if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
        $self->{onerror}->(type => 'character not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $cn);
      }
    }
  }
} # convert_rdf_element

my %coreSyntaxTerms = (
  $RDF_URI . 'RDF' => 1,
  $RDF_URI . 'ID' => 1,
  $RDF_URI . 'about' => 1,
  $RDF_URI . 'parseType' => 1,
  $RDF_URI . 'resource' => 1,
  $RDF_URI . 'nodeID' => 1,
  $RDF_URI . 'datatype' => 1,
);

my %oldTerms = (
  $RDF_URI . 'aboutEach' => 1,
  $RDF_URI . 'aboutEachPrefix' => 1,
  $RDF_URI . 'bagID' => 1,
);

require Message::DOM::DOMImplementation;
my $resolve = sub {
  return Message::DOM::DOMImplementation->create_uri_reference ($_[0])
      ->get_absolute_reference ($_[1]->base_uri)
      ->uri_reference;

  ## TODO: Ummm... RDF/XML spec refers dated version of xml:base and RFC 2396...

  ## TODO: Check latest xml:base and IRI spec...
  ## (non IRI/URI chars should be percent-encoded before resolve?)
}; # $resolve

my $generate_bnodeid = sub {
  return 'g'.$_[0]->{next_id}++;
}; # $generate_bnodeid

my $get_bnodeid = sub {
  return 'b'.$_[0];
}; # $get_bnodeid

my $uri_attr = sub {
  my ($self, $attr) = @_;

  my $abs_uri = $resolve->($attr->value, $attr);

  ## TODO: check as RDF URI reference
  Whatpm::URIChecker->check_iri_reference ($abs_uri, sub {
    $self->{onerror}->(@_, node => $attr);
  }, $self->{level});

  return $abs_uri;
}; # $uri_attr

my $id_attr = sub {
  my ($self, $attr) = @_;
  
  my $id = $attr->value;
  unless ($id =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
    $self->{onerror}->(type => 'XML 1.0 NCName:syntax error',
                       level => $self->{level}->{rdf_grammer},
                       node => $attr);
  }

  my $base_uri = $attr->base_uri;
  if ($self->{id}->{$base_uri}->{$id}) {
    $self->{onerror}->(type => 'duplicate rdf id',
                       level => $self->{level}->{rdf_lc_must},
                       node => $attr);
    ## TODO: RDF Validator?
  } else {
    $self->{id}->{$base_uri}->{$id} = 1;
  }
  
  return $resolve->('#' . $id, $attr);
}; # $id_attr

my $check_local_attr = sub {
  my ($self, $node, $attr, $attr_xuri) = @_;
  
  if ({
       ID => 1, about => 1, resource => 1, parseType => 1, type => 1,
      }->{$attr_xuri}) {
    $self->{onerror}->(type => 'unqualified rdf attr',
                       level => $self->{level}->{should},
                       node => $attr);
    if ($node->has_attribute_ns ($RDF_URI, $attr_xuri)) {
      $self->{onerror}->(type => 'duplicate unqualified attr',
                         level => $self->{level}->{rdf_fact},
                         node => $attr);
      ## NOTE: <? rdfa:bout="" about=""> and such are not catched
      ## by this check; but who cares?  rdfa:bout="" is itself illegal.
    }
    $attr_xuri = $RDF_URI . $attr_xuri;
  } else {
    $self->{onerror}->(type => 'unqualified attr',
                       level => $self->{level}->{rdf_fact},
                       node => $attr);
    ## TODO: RDF Validator?
  }
  
  return $attr_xuri;
}; # $check_local_attr

sub convert_node_element ($$;%) {
  my ($self, $node, %opt) = @_;
  $opt{language} = '' unless defined $opt{language};
      ## ISSUE: Not explicitly defined in the spec.

  $check_rdf_namespace->($self, $node);

  # |nodeElement|

  my $xuri = $node->manakai_expanded_uri;

  if ({
    %coreSyntaxTerms,
    $RDF_URI . 'li' => 1,
    %oldTerms,
  }->{$xuri}) {
    $self->{onerror}->(type => 'element not allowed',
                       level => $self->{level}->{rdf_grammer},
                       node => $node);

    ## TODO: W3C RDF Validator: Continue validation, but triples that would
    ## be generated from the subtree are ignored.
  }

  my $subject;
  my $type_attr;
  my @prop_attr;

  for my $attr (@{$node->attributes}) {
    my $nsuri = $attr->namespace_uri;
    if (defined $nsuri and
        $nsuri eq q<http://www.w3.org/XML/1998/namespace> and
        $attr->manakai_local_name eq 'lang') {
      $opt{language} = $attr->value;
    }

    my $prefix = $attr->prefix;
    if (defined $prefix) {
      next if $prefix =~ /^[Xx][Mm][Ll]/;
    } else {
      next if $attr->manakai_local_name =~ /^[Xx][Mm][Ll]/;
    }

    $check_rdf_namespace->($self, $attr);

    my $attr_xuri = $attr->manakai_expanded_uri;

    unless (defined $nsuri) {
      $attr_xuri = $check_local_attr->($self, $node, $attr, $attr_xuri);
    }

    if ($attr_xuri eq $RDF_URI . 'ID') {
      unless (defined $subject) {
        $subject = {uri => $id_attr->($self, $attr)};
      } else {
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $attr);

        ## TODO: Ignore triple as W3C RDF Validator does
      }
    } elsif ($attr_xuri eq $RDF_URI . 'nodeID') {
      unless (defined $subject) {
        my $id = $attr->value;
        unless ($id =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
          $self->{onerror}->(type => 'XML 1.0 NCName:syntax error',
                             level => $self->{level}->{rdf_grammer},
                             node => $self);
        }

        $subject = {bnodeid => $get_bnodeid->($id)};
      } else {
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $attr);

        ## TODO: Ignore triple as W3C RDF Validator does
      }
    } elsif ($attr_xuri eq $RDF_URI . 'about') {
      unless (defined $subject) {
        $subject = {uri => $uri_attr->($self, $attr)};
      } else {
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $attr);

        ## TODO: Ignore triple as W3C RDF Validator does
      }
    } elsif ($attr_xuri eq $RDF_URI . 'type') {
      $type_attr = $attr;
    } elsif ({
      %coreSyntaxTerms,
      $RDF_URI . 'li' => 1,
      $RDF_URI . 'Description' => 1,
      %oldTerms,
    }->{$attr_xuri}) {
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{level}->{rdf_grammer},
                         node => $attr);

      ## TODO: W3C RDF Validator: Ignore triples
    } else {
      push @prop_attr, $attr;
    }
  }
  
  unless (defined $subject) {
    $subject = {bnodeid => $generate_bnodeid->($self)};
  }

  if ($xuri ne $RDF_URI . 'Description') {
    $self->{ontriple}->(subject => $subject,
                        predicate => {uri => $RDF_URI . 'type'},
                        object => {uri => $xuri},
                        node => $node);
  }

  if ($type_attr) {
    $self->{ontriple}->(subject => $subject,
                        predicate => {uri => $RDF_URI . 'type'},
                        object => {uri => $resolve->($type_attr->value,
                                                     $type_attr)},
                        node => $type_attr);
  }

  for my $attr (@prop_attr) {
    $self->{ontriple}->(subject => $subject,
                        predicate => {uri => $attr->manakai_expanded_uri},
                        object => {value => $attr->value,
                                   language => $opt{language}},
                        node => $attr);
    ## TODO: SHOULD in NFC
  }

  # |propertyEltList|

  my $li_counter = 1;
  for my $cn (@{$node->child_nodes}) {
    my $cn_type = $cn->node_type;
    if ($cn_type == $cn->ELEMENT_NODE) {
      $self->convert_property_element ($cn, li_counter => \$li_counter,
                                       subject => $subject,
                                       language => $opt{language});
    } elsif ($cn_type == $cn->TEXT_NODE or
             $cn_type == $cn->CDATA_SECTION_NODE) {
      if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
        $self->{onerror}->(type => 'character not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $cn);
      }
    }
  }

  return $subject;
} # convert_node_element

my $get_id_resource = sub {
  my $self = shift;
  my $node = shift;

  return undef unless $node;

  return {uri => $id_attr->($self, $node)};
}; # $get_id_resource

sub convert_property_element ($$%) {
  my ($self, $node, %opt) = @_;
  
  $check_rdf_namespace->($self, $node);

  # |propertyElt|

  my $xuri = $node->manakai_expanded_uri;
  if ($xuri eq $RDF_URI . 'li') {
    $xuri = $RDF_URI . '_' . ${$opt{li_counter}}++;
  }

  if ({
       %coreSyntaxTerms,
       $RDF_URI . 'Description' => 1,
       %oldTerms,
      }->{$xuri}) {
    $self->{onerror}->(type => 'element not allowed',
                       level => $self->{level}->{rdf_grammer},
                       node => $node);
    ## TODO: RDF Validator?
  }

  my $rdf_id_attr;
  my $dt_attr;
  my $parse_attr;
  my $nodeid_attr;
  my $resource_attr;
  my @prop_attr;
  for my $attr (@{$node->attributes}) {
    my $nsuri = $attr->namespace_uri;
    if (defined $nsuri and
        $nsuri eq q<http://www.w3.org/XML/1998/namespace> and
        $attr->manakai_local_name eq 'lang') {
      $opt{language} = $attr->value;
    }

    my $prefix = $attr->prefix;
    if (defined $prefix) {
      next if $prefix =~ /^[Xx][Mm][Ll]/;
    } else {
      next if $attr->manakai_local_name =~ /^[Xx][Mm][Ll]/;
    }

    $check_rdf_namespace->($self, $attr);

    my $attr_xuri = $attr->manakai_expanded_uri;

    unless (defined $nsuri) {
      $attr_xuri = $check_local_attr->($self, $node, $attr, $attr_xuri);
    }

    if ($attr_xuri eq $RDF_URI . 'ID') {
      $rdf_id_attr = $attr;
    } elsif ($attr_xuri eq $RDF_URI . 'datatype') {
      $dt_attr = $attr;
    } elsif ($attr_xuri eq $RDF_URI . 'parseType') {
      $parse_attr = $attr;
    } elsif ($attr_xuri eq $RDF_URI . 'resource') {
      $resource_attr = $attr;
    } elsif ($attr_xuri eq $RDF_URI . 'nodeID') {
      $nodeid_attr = $attr;
    } elsif ({
      %coreSyntaxTerms,
      $RDF_URI . 'li' => 1,
      $RDF_URI . 'Description' => 1,
      %oldTerms,
    }->{$attr_xuri}) {
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{level}->{rdf_grammer},
                         node => $attr);
      ## TODO: RDF Validator?
    } else {
      push @prop_attr, $attr;
    }
  }

  my $parse = $parse_attr ? $parse_attr->value : '';
  if ($parse eq 'Resource') {
    # |parseTypeResourcePropertyElt|

    for my $attr ($resource_attr, $nodeid_attr, $dt_attr) {
      next unless $attr;
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{level}->{rdf_grammer},
                         node => $attr);
      ## TODO: RDF Validator?
    }
    
    my $object = {bnodeid => $generate_bnodeid->($self)};
    $self->{ontriple}->(subject => $opt{subject},
                        predicate => {uri => $xuri},
                        object => $object,
                        node => $node,
                        id => $get_id_resource->($self, $rdf_id_attr));
    
    ## As if nodeElement

    # |propertyEltList|
    
    my $li_counter = 1;
    for my $cn (@{$node->child_nodes}) {
      my $cn_type = $cn->node_type;
      if ($cn_type == $cn->ELEMENT_NODE) {
        $self->convert_property_element ($cn, li_counter => \$li_counter,
                                         subject => $object,
                                         language => $opt{language});
      } elsif ($cn_type == $cn->TEXT_NODE or
               $cn_type == $cn->CDATA_SECTION_NODE) {
        if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
          $self->{onerror}->(type => 'character not allowed',
                             level => $self->{level}->{rdf_grammer},
                             node => $cn);
        }
      }
    }
  } elsif ($parse eq 'Collection') {
    # |parseTypeCollectionPropertyElt|

    for my $attr ($resource_attr, $nodeid_attr, $dt_attr) {
      next unless $attr;
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{level}->{rdf_grammer},
                         node => $attr);
      ## TODO: RDF Validator?
    }
    
    # |nodeElementList|
    my @resource;
    for my $cn (@{$node->child_nodes}) {
      if ($cn->node_type == $cn->ELEMENT_NODE) {
        push @resource, [$self->convert_node_element ($cn),
                         {bnodeid => $generate_bnodeid->($self)},
                         $cn];
      } elsif ($cn->node_type == $cn->TEXT_NODE or
               $cn->node_type == $cn->CDATA_SECTION_NODE) {
        if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
          $self->{onerror}->(type => 'character not allowed',
                             level => $self->{level}->{rdf_grammer},
                             node => $cn);
        }
      }
    }

    if (@resource) {
      $self->{ontriple}->(subject => $opt{subject},
                          predicate => {uri => $xuri},
                          object => $resource[0]->[1],
                          node => $node);
    } else {
      $self->{ontriple}->(subject => $opt{subject},
                          predicate => {uri => $xuri},
                          object => {uri => $RDF_URI . 'nil'},
                          node => $node,
                          id => $get_id_resource->($self, $rdf_id_attr));
    }
    
    while (@resource) {
      my $resource = shift @resource;
      $self->{ontriple}->(subject => $resource->[1],
                          predicate => {uri => $RDF_URI . 'first'},
                          object => $resource->[0],
                          node => $resource->[2]);
      if (@resource) {
        $self->{ontriple}->(subject => $resource->[1],
                            predicate => {uri => $RDF_URI . 'rest'},
                            object => $resource[0]->[1],
                            node => $resource->[2]);
      } else {
        $self->{ontriple}->(subject => $resource->[1],
                            predicate => {uri => $RDF_URI . 'rest'},
                            object => {uri => $RDF_URI . 'nil'},
                            node => $resource->[2]);
      }
    }
  } elsif ($parse_attr) {
    # |parseTypeLiteralPropertyElt|

    if ($parse ne 'Literal') {
      # |parseTypeOtherPropertyElt| ## TODO: What RDF Validator does?

      $self->{onerror}->(type => 'parse type other',
                         level => $self->{level}->{rdf_info},
                         node => $parse_attr);
    }

    for my $attr ($resource_attr, $nodeid_attr, $dt_attr) {
      next unless $attr;
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{level}->{rdf_grammer},
                         node => $attr);
      ## TODO: RDF Validator?
    }

    my $value = [@{$node->child_nodes}];
    ## TODO: Callback for validation
    ## TODO: Serialized form SHOULD be in NFC.
    
    $self->{ontriple}->(subject => $opt{subject},
                        predicate => {uri => $xuri},
                        object => {nodes => $value,
                                   datatype => $RDF_URI . 'XMLLiteral'},
                        node => $node,
                        id => $get_id_resource->($self, $rdf_id_attr));
  } else {
    my $mode = 'unknown';

    if ($dt_attr) {
      $mode = 'literal'; # |literalPropertyElt|
      ## TODO: What RDF Validator does for |< rdf:datatype><el/></>|?
    }
    ## TODO: What RDF Validator does for |< prop-attr><non-empty/></>|?
    
    my $node_element;
    my $text = '';
    for my $cn (@{$node->child_nodes}) {
      my $cn_type = $cn->node_type;
      if ($cn_type == $cn->ELEMENT_NODE) {
        unless ($node_element) {
          $node_element = $cn;
          if ({
               resource => 1, unknown => 1, 'literal-or-resource' => 1,
              }->{$mode}) {
            $mode = 'resource';
          } else {
            $self->{onerror}->(type => 'element not allowed',
                               level => $self->{level}->{rdf_grammer},
                               node => $cn);
            ## TODO: RDF Validator?
          }
        } else {
          ## TODO: What RDF Validator does?
          $self->{onerror}->(type => 'second node element',
                             level => $self->{level}->{rdf_grammer},
                             node => $cn);
        }
      } elsif ($cn_type == $cn->TEXT_NODE or
               $cn_type == $cn->CDATA_SECTION_NODE) {
        my $data = $cn->data;
        $text .= $data;
        if ($data =~ /[^\x09\x0A\x0D\x20]/) {
          if ({
               literal => 1, unknown => 1, 'literal-or-resource' => 1,
              }->{$mode}) {
            $mode = 'literal';
          } else {
            $self->{onerror}->(type => 'character not allowed',
                               level => $self->{level}->{rdf_grammer},
                               node => $cn);
            ## TODO: RDF Validator?
          }
        } else {
          if ($mode eq 'unknown') {
            $mode = 'literal-or-resource';
          } else {
            #
          }
        }
      }
    }
    
    if ($mode eq 'resource') {
      # |resourcePropertyElt|
      
      for my $attr (@prop_attr, $resource_attr, $nodeid_attr, $dt_attr) {
        next unless $attr;
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $attr);
        ## TODO: RDF Validator?
      }
      
      my $object = $self->convert_node_element ($node_element,
                                                language => $opt{language});
      
      $self->{ontriple}->(subject => $opt{subject},
                          predicate => {uri => $xuri},
                          object => $object,
                          node => $node,
                          id => $get_id_resource->($self, $rdf_id_attr));
    } elsif ($mode eq 'literal' or $mode eq 'literal-or-resource') {
      # |literalPropertyElt|
      
      for my $attr (@prop_attr, $resource_attr, $nodeid_attr) {
        next unless $attr;
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $attr);
        ## TODO: RDF Validator?
      }
      
      ## TODO: $text SHOULD be in NFC
      
      if ($dt_attr) {
        $self->{ontriple}
            ->(subject => $opt{subject},
               predicate => {uri => $xuri},
               object => {value => $text,
                          datatype => $uri_attr->($self, $dt_attr)},
               ## ISSUE: No resolve() in the spec (but spec says that
               ## xml:base is applied also to rdf:datatype).
               node => $node,
               id => $get_id_resource->($self, $rdf_id_attr));
      } else {
        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => {value => $text,
                                       language => $opt{language}},
                            node => $node,
                            id => $get_id_resource->($self, $rdf_id_attr));
      }
    } else {
      ## |emptyPropertyElt|

      for my $attr ($dt_attr) {
        next unless $attr;
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{level}->{rdf_grammer},
                           node => $attr);
        ## TODO: RDF Validator?
      }
      
      if (not $resource_attr and not $nodeid_attr and not @prop_attr) {
        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => {value => '',
                                       language => $opt{language}},
                            node => $node,
                            id => $get_id_resource->($self, $rdf_id_attr));
      } else {
        my $object;
        if ($resource_attr) {
          $object = {uri => $uri_attr->($self, $resource_attr)};
          if (defined $nodeid_attr) {
            $self->{onerror}->(type => 'attribute not allowed',
                               level => $self->{level}->{rdf_grammer},
                               node => $nodeid_attr);
             ## TODO: RDF Validator?
          }
        } elsif ($nodeid_attr) {
          my $id = $nodeid_attr->value;
          unless ($id =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
            $self->{onerror}->(type => 'XML 1.0 NCName:syntax error',
                               level => $self->{level}->{rdf_grammer},
                               node => $self);
          }
          $object = {bnodeid => $get_bnodeid->($id)};
        } else {
          $object = {bnodeid => $generate_bnodeid->($self)};
        }
        
        for my $attr (@prop_attr) {
          my $attr_xuri = $attr->manakai_expanded_uri;
          if ($attr_xuri eq $RDF_URI . 'type') {
            $self->{ontriple}->(subject => $object,
                                predicate => {uri => $attr_xuri},
                                object => $resolve->($attr->value, $attr),
                                node => $attr);
          } else {
            ## TODO: SHOULD be in NFC
            $self->{ontriple}->(subject => $object,
                                predicate => {uri => $attr_xuri},
                                object => {value => $attr->value,
                                           language => $opt{language}},
                                node => $attr);
          }
        }

        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => $object,
                            node => $node,
                            id => $get_id_resource->($self, $rdf_id_attr));
      }
    }
  }
} # convert_property_element

## TODO: We need to normalize language tags into lowercase (see RDF abstract
## syntax spec) before invoking callbak.  In addition, we need to validate
## them against RFC 3066 (fact-level, referencing abstract syntax spec).

1;

