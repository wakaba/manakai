package Whatpm::RDFXML;
use strict;

## NOTE: EntityReference nodes are not supported except that
## unexpected entity reference are simply ignored.  (In fact
## all EntityRefernce nodes are ignored.)

## TODO: Add a callback function invoked for every element
## when XMLCC is implemented in WDCC.

## ISSUE: <html:nest/> in RDF subtree?

## ISSUE: PIs in RDF subtree should be validated?

my $RDF_URI = q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>;

sub new ($) {
  my $self = bless {fact_level => 'm', grammer_level => 'm'}, shift;
  $self->{onerror} = sub {
    my %opt = @_;
    warn $opt{type}, "\n";
  };
  $self->{ontriple} = sub {
    my %opt = @_;
    my $dump_resource = sub {
      my $resource = shift;
      if ($resource->{uri}) {
        return '<' . $resource->{uri} . '>';
      } elsif ($resource->{bnodeid}) {
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
          $self->convert_rdf_element ($cn);
        } else {
          $self->convert_rdf_node_element ($cn);
        }
        $has_element = 1;
      } else {
        $self->{onerror}->(type => 'second node element',
                           level => $self->{grammer_level},
                           node => $cn);
      }
    } elsif ($cn->node_type == $cn->TEXT_NODE or
             $cn->node_type == $cn->CDATA_SECTION_NODE) {
      $self->{onerror}->(type => 'character not allowed',
                         level => $self->{grammer_level},
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
                       level => $self->{fact_level}, # Section 5.1
                       node => $node);
  }
}; # $check_rdf_namespace

sub convert_rdf_element ($$) {
  my ($self, $node) = @_;

  $check_rdf_namespace->($self, $node);

  # |RDF|

  for my $attr (@{$node->attributes}) {
    my $prefix = $attr->prefix;
    if (defined $prefix) {
      next if $prefix =~ /^[Xx][Mm][Ll]/;
    } else {
      next if $attr->manakai_local_name =~ /^[Xx][Mm][Ll]/;
    }

    $check_rdf_namespace->($self, $attr);
    $self->{onerror}->(type => 'attribute not allowed',
                       level => $self->{grammer_level},
                       node => $attr);
  }

  # |nodeElementList|
  for my $cn (@{$node->child_nodes}) {
    if ($cn->node_type == $cn->ELEMENT_NODE) {
      $self->convert_node_element ($cn);
    } elsif ($cn->node_type == $cn->TEXT_NODE or
             $cn->node_type == $cn->CDATA_SECTION_NODE) {
      if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
        $self->{onerror}->(type => 'character not allowed',
                           level => $self->{grammer_level},
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

sub convert_node_element ($$) {
  my ($self, $node) = @_;

  $check_rdf_namespace->($self, $node);

  # |nodeElement|

  my $xuri = $node->manakai_expanded_uri;

  if ({
    %coreSyntaxTerms,
    $RDF_URI . 'li' => 1,
    %oldTerms,
  }->{$xuri}) {
    $self->{onerror}->(type => 'element not allowed',
                       level => $self->{grammer_level},
                       node => $node);

    ## TODO: W3C RDF Validator: Continue validation, but triples that would
    ## be generated from the subtree are ignored.
  }

  my $subject;
  my $rdf_type_attr;
  my @prop_attr;

  for my $attr (@{$node->attributes}) {
    my $prefix = $attr->prefix;
    if (defined $prefix) {
      next if $prefix =~ /^[Xx][Mm][Ll]/;
    } else {
      next if $attr->manakai_local_name =~ /^[Xx][Mm][Ll]/;
    }

    $check_rdf_namespace->($self, $attr);

    my $attr_xuri = $attr->manakai_expanded_uri;
    if ($attr_xuri eq $RDF_URI . 'ID') {
      unless (defined $subject) {
        $subject = {uri => '#' . $attr->value}; ## TODO: resolve()
      } else {
        ## TODO: Ignore triple as W3C RDF Validator does
      }
    } elsif ($attr_xuri eq $RDF_URI . 'nodeID') {
      unless (defined $subject) {
        $subject = {bnodeid => '## TODO: bnode: ' . $attr->value};
      } else {
        ## TODO: Ignore triple as W3C RDF Validator does
      }
    } elsif ($attr_xuri eq $RDF_URI . 'about') {
      unless (defined $subject) {
        $subject = {uri => $attr->value}; ## TODO: resolve
      } else {
        ## TODO: Ignore triple as W3C RDF Validator does
      }
    } elsif ($attr_xuri eq $RDF_URI . 'type') {
      $rdf_type_attr = $attr;
    } elsif ({
      %coreSyntaxTerms,
      $RDF_URI . 'li' => 1,
      $RDF_URI . 'Description' => 1,
      %oldTerms,
    }->{$attr_xuri}) {
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{grammer_level},
                         node => $attr);

      ## TODO: W3C RDF Validator: Ignore triples
    } else {
      push @prop_attr, $attr;
    }
  }
  
  unless (defined $subject) {
    $subject = {bnodeid => '## TODO: new bnodeid'};
  }

  if ($xuri ne $RDF_URI . 'Description') {
    $self->{ontriple}->(subject => $subject,
                        predicate => {uri => $RDF_URI . 'type'},
                        object => {uri => $xuri},
                        node => $node);
  }

  if ($rdf_type_attr) {
    $self->{ontriple}->(subject => $subject,
                        predicate => {uri => $RDF_URI . 'type'},
                        object => {uri => $rdf_type_attr->value}, ## TODO: resolve
                        node => $rdf_type_attr);
  }

  for my $attr (@prop_attr) {
    $self->{ontriple}->(subject => $subject,
                        predicate => {uri => $attr->manakai_expanded_uri},
                        object => {value => $attr->value}, ## TODO: language
                        node => $attr);
    ## TODO: SHOULD in NFC
  }

  # |propertyEltList|

  my $li_counter = 1;
  for my $cn (@{$node->child_nodes}) {
    my $cn_type = $cn->node_type;
    if ($cn_type == $cn->ELEMENT_NODE) {
      $self->convert_property_element ($cn, li_counter => \$li_counter,
                                       subject => $subject);
    } elsif ($cn_type == $cn->TEXT_NODE or
             $cn_type == $cn->CDATA_SECTION_NODE) {
      if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
        $self->{onerror}->(type => 'character not allowed',
                           level => $self->{grammer_level},
                           node => $cn);
      }
    }
  }

  return $subject;
} # convert_node_element

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
                       level => $self->{grammer_level},
                       node => $node);
    ## TODO: RDF Validator?
  }

  my $id_attr;
  my $dt_attr;
  my $parse_attr;
  my $nodeid_attr;
  my $resource_attr;
  my @prop_attr;
  for my $attr (@{$node->attributes}) {
    my $prefix = $attr->prefix;
    if (defined $prefix) {
      next if $prefix =~ /^[Xx][Mm][Ll]/;
    } else {
      next if $attr->manakai_local_name =~ /^[Xx][Mm][Ll]/;
    }

    $check_rdf_namespace->($self, $attr);

    my $attr_xuri = $attr->manakai_expanded_uri;
    if ($attr_xuri eq $RDF_URI . 'ID') {
      $id_attr = $attr;
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
                         level => $self->{grammer_level},
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
                         level => $self->{grammer_level},
                         node => $attr);
      ## TODO: RDF Validator?
    }
    
    my $object = {bnodeid => '## TODO: generate bnodeid'};
    $self->{ontriple}->(subject => $opt{subject},
                        predicate => {uri => $xuri},
                        object => $object,
                        node => $node);
    ## TODO: reification
    
    ## As if nodeElement

    # |propertyEltList|
    
    my $li_counter = 1;
    for my $cn (@{$node->child_nodes}) {
      my $cn_type = $cn->node_type;
      if ($cn_type == $cn->ELEMENT_NODE) {
        $self->convert_property_element ($cn, li_counter => \$li_counter,
                                         subject => $object);
      } elsif ($cn_type == $cn->TEXT_NODE or
               $cn_type == $cn->CDATA_SECTION_NODE) {
        if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
          $self->{onerror}->(type => 'character not allowed',
                             level => $self->{grammer_level},
                             node => $cn);
        }
      }
    }
  } elsif ($parse eq 'Collection') {
    # |parseTypeCollectionPropertyElt|

    for my $attr ($resource_attr, $nodeid_attr, $dt_attr) {
      next unless $attr;
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{grammer_level},
                         node => $attr);
      ## TODO: RDF Validator?
    }
    
    # |nodeElementList|
    my @resource;
    for my $cn (@{$node->child_nodes}) {
      if ($cn->node_type == $cn->ELEMENT_NODE) {
        push @resource, [$self->convert_node_element ($cn),
                         {bnodeid => '## TODO: bnodeid generated'},
                         $cn];
      } elsif ($cn->node_type == $cn->TEXT_NODE or
               $cn->node_type == $cn->CDATA_SECTION_NODE) {
        if ($cn->data =~ /[^\x09\x0A\x0D\x20]/) {
          $self->{onerror}->(type => 'character not allowed',
                             level => $self->{grammer_level},
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
                          node => $node);
    }
    ## TODO: reification

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
    # |parseTypeOtherPropertyElt| ## TODO: What RDF Validator does?

    for my $attr ($resource_attr, $nodeid_attr, $dt_attr) {
      next unless $attr;
      $self->{onerror}->(type => 'attribute not allowed',
                         level => $self->{grammer_level},
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
                        node => $node);
    ## TODO: reification
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
                               level => $self->{grammer_level},
                               node => $cn);
            ## TODO: RDF Validator?
          }
        } else {
          ## TODO: What RDF Validator does?
          $self->{onerror}->(type => 'second node element',
                             level => $self->{grammer_level},
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
                               level => $self->{grammer_level},
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
                           level => $self->{grammer_level},
                           node => $attr);
        ## TODO: RDF Validator?
      }
      
      my $object = $self->convert_node_element ($node_element);
      
      $self->{ontriple}->(subject => $opt{subject},
                          predicate => {uri => $xuri},
                          object => $object,
                          node => $node);

      ## TODO: reification
    } elsif ($mode eq 'literal' or $mode eq 'literal-or-resource') {
      # |literalPropertyElt|
      
      for my $attr (@prop_attr, $resource_attr, $nodeid_attr) {
        next unless $attr;
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{grammer_level},
                           node => $attr);
        ## TODO: RDF Validator?
      }
      
      ## TODO: $text SHOULD be in NFC
      
      if ($dt_attr) {
        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => {value => $text,
                                       datatype => $dt_attr->value},
                            node => $node);
      } else {
        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => {value => $text,
                                       ## TODO: language
                                      },
                            node => $node);
      }

      ## TODO: reification
    } else {
      ## |emptyPropertyElt|

      for my $attr ($dt_attr) {
        next unless $attr;
        $self->{onerror}->(type => 'attribute not allowed',
                           level => $self->{grammer_level},
                           node => $attr);
        ## TODO: RDF Validator?
      }
      
      if (not $resource_attr and not $nodeid_attr and not @prop_attr) {
        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => {value => '',
                                       ## TODO: language
                                      },
                            node => $node);
        
        ## TODO: reification
      } else {
        my $object;
        if ($resource_attr) {
          $object = {uri => $resource_attr->value}; ## TODO: resolve
        } elsif ($nodeid_attr) {
          $object = {bnodeid => $nodeid_attr->value};
        } else {
          $object = {bnodeid => '## TODO: generated bnodeid'};
        }
        
        for my $attr (@prop_attr) {
          my $attr_xuri = $attr->manakai_expanded_uri;
          if ($attr_xuri eq $RDF_URI . 'type') {
            $self->{ontriple}->(subject => $object,
                                predicate => {uri => $attr_xuri},
                                object => $attr->value, ## TODO: resolve
                                node => $attr);
          } else {
            ## TODO: SHOULD be in NFC
            $self->{ontriple}->(subject => $object,
                                predicate => {uri => $attr_xuri},
                                object => {value => $attr->value,
                                           ## TODO: lang
                                          },
                                node => $attr);
          }
        }

        $self->{ontriple}->(subject => $opt{subject},
                            predicate => {uri => $xuri},
                            object => $object,
                            node => $node);
        
        ## TODO: reification
      }
    }
  }
} # convert_property_element

1;

