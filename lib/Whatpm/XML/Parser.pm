package Whatpm::XML::Parser; # -*- Perl -*-
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '3.0';
use Whatpm::HTML::Defs;
use Whatpm::HTML::InputStream;
use Whatpm::HTML::Tokenizer;
push our @ISA, qw(Whatpm::HTML::Tokenizer);

sub parse_char_string ($$$;$$) {
  #my ($self, $string, $document, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[2];
  @{$self->{document}->child_nodes} = ();

  ## Confidence: irrelevant.
  $self->{confident} = 1 unless exists $self->{confident};

  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;

  $self->{chars} = [split //, $_[1]];
  $self->{chars_pos} = 0;
  $self->{chars_pull_next} = sub { 0 };
  delete $self->{chars_was_cr};

  my $onerror = $_[3] || $self->onerror;
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  $self->{is_xml} = 1;

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->{t} = $self->_get_next_token;
  $self->_construct_tree;
  $self->_terminate_tree_constructor;
  $self->_clear_refs;

  return $doc;
} # parse_char_string

## DEPRECATED
sub parse_char_stream ($$$;$$) {
  #my ($self, $handle, $document, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[2];
  @{$self->{document}->child_nodes} = ();

  ## Confidence: irrelevant.
  $self->{confident} = 1 unless exists $self->{confident};

  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;

  my $handle = $_[1];
  $self->{chars} = [];
  $self->{chars_pos} = 0;
  $self->{chars_pull_next} = sub {
    $self->{chars} = [];
    $self->{chars_pos} = 0;
    my $i = 0;
    my $char = '';
    while ($handle->read ($char, 1, 0)) {
      push @{$self->{chars}}, $char;
      last if $i++ == 1024;
    }
    return $i > 0;
  };
  delete $self->{chars_was_cr};

  my $onerror = $_[3] || $self->onerror;
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  $self->{is_xml} = 1;

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->{t} = $self->_get_next_token;
  {
    $self->_construct_tree;
    redo if $self->{nc} != EOF_CHAR;
  }
  $self->_terminate_tree_constructor;
  $self->_clear_refs;

  return $doc;
} # parse_char_stream

## ------ Tree construction ------

## Insertion modes
sub BEFORE_XML_DECL_IM () { 0 }
sub AFTER_XML_DECL_IM () { 1 }
sub BEFORE_ROOT_ELEMENT_IM () { 2 }
sub IN_ELEMENT_IM () { 3 }
sub AFTER_ROOT_ELEMENT_IM () { 4 }
sub IN_SUBSET_IM () { 5 }

sub _initialize_tree_constructor ($) {
  my $self = shift;
  ## NOTE: $self->{document} MUST be specified before this method is called
  $self->{document}->strict_error_checking (0);
  ## TODO: Turn mutation events off # MUST
  $self->{document}->dom_config
      ->{'http://suika.fam.cx/www/2006/dom-config/strict-document-children'}
      = 0;
  $self->{document}->manakai_is_html (0);
  $self->{document}->set_user_data (manakai_source_line => 1);
  $self->{document}->set_user_data (manakai_source_column => 1);

  $self->{ge}->{'amp;'} = {value => '&', only_text => 1};
  $self->{ge}->{'apos;'} = {value => "'", only_text => 1};
  $self->{ge}->{'gt;'} = {value => '>', only_text => 1};
  $self->{ge}->{'lt;'} = {value => '<', only_text => 1};
  $self->{ge}->{'quot;'} = {value => '"', only_text => 1};

  delete $self->{tainted};
  $self->{open_elements} = [];
  $self->{insertion_mode} = BEFORE_XML_DECL_IM;
} # _initialize_tree_constructor

sub _terminate_tree_constructor ($) {
  my $self = shift;
  $self->{document}->strict_error_checking (1);
  $self->{document}->dom_config
      ->{'http://suika.fam.cx/www/2006/dom-config/strict-document-children'}
      = 1;
  ## TODO: Turn mutation events on
} # _terminate_tree_constructor

## Tree construction stage


## NOTE: Differences from the XML5 draft are marked as "XML5:".

## XML5: No namespace support.

## XML5: Start, main, end phases.  In this implementation, they are
## represented by insertion modes.

sub _construct_tree ($) {
  my ($self) = @_;
  while (1) {
    if ($self->{insertion_mode} == IN_ELEMENT_IM) {
      $self->_tree_in_element;
    } elsif ($self->{insertion_mode} == IN_SUBSET_IM) {
      $self->_tree_in_subset;
    } elsif ($self->{insertion_mode} == AFTER_ROOT_ELEMENT_IM) {
      $self->_tree_after_root_element;
    } elsif ($self->{insertion_mode} == BEFORE_ROOT_ELEMENT_IM) {
      $self->_tree_before_root_element;
    } elsif ($self->{insertion_mode} == AFTER_XML_DECL_IM) {
      $self->_tree_after_xml_decl;
    } elsif ($self->{insertion_mode} == BEFORE_XML_DECL_IM) {
      $self->_tree_before_xml_decl;
    } else {
      die "$0: Unknown XML insertion mode: $self->{insertion_mode}";
    }

    last if $self->{t}->{type} == ABORT_TOKEN;
  }
} # _construct_tree

sub _tree_before_xml_decl ($) {
  my $self = $_[0];
  
  ## XML5: No support for the XML declaration
  if ($self->{t}->{type} == PI_TOKEN and
      $self->{t}->{target} eq 'xml' and
      $self->{t}->{data} =~ /\Aversion[\x09\x0A\x20]*=[\x09\x0A\x20]*
                         (?>"([^"]*)"|'([^']*)')
                         (?:[\x09\x0A\x20]+
                            encoding[\x09\x0A\x20]*=[\x09\x0A\x20]*
                            (?>"([^"]*)"|'([^']*)')[\x09\x0A\x20]*)?
                         (?:[\x09\x0A\x20]+
                            standalone[\x09\x0A\x20]*=[\x09\x0A\x20]*
                            (?>"(yes|no)"|'(yes|no)'))?
                         [\x09\x0A\x20]*\z/x) {
    $self->{document}->xml_version (defined $1 ? $1 : $2);
    $self->{is_xml} = 1.1 if defined $1 and $1 eq '1.1';
    $self->{document}->xml_encoding (defined $3 ? $3 : $4); # possibly undef
    $self->{document}->xml_standalone (($5 || $6 || 'no') ne 'no');

    $self->{insertion_mode} = AFTER_XML_DECL_IM;
    $self->{t} = $self->_get_next_token;
    return;
  } elsif ($self->{t}->{type} == ABORT_TOKEN) {
    return;
  } else {
    $self->{document}->xml_version ('1.0');
    $self->{document}->xml_encoding (undef);
    $self->{document}->xml_standalone (0);
    $self->{insertion_mode} = AFTER_XML_DECL_IM;
    ## Reconsume the token,
    return;
  }
} # _tree_before_xml_decl

sub _tree_after_xml_decl ($) {
  my $self = shift;

  B: while (1) {
    if ($self->{t}->{type} == DOCTYPE_TOKEN) {
      ## XML5: No "DOCTYPE" token.
      
      my $doctype = $self->{document}->create_document_type_definition
          (defined $self->{t}->{name} ? $self->{t}->{name} : '');
      
      ## NOTE: Default value for both |public_id| and |system_id| attributes
      ## are empty strings, so that we don't set any value in missing cases.
      $doctype->public_id ($self->{t}->{pubid}) if defined $self->{t}->{pubid};
      $doctype->system_id ($self->{t}->{sysid}) if defined $self->{t}->{sysid};
      
      ## TODO: internal_subset
      
      $self->{document}->append_child ($doctype);

      $self->{ge} = {};

      ## XML5: No "has internal subset" flag.
      if ($self->{t}->{has_internal_subset}) {
        $self->{doctype} = $doctype;
        $self->{insertion_mode} = IN_SUBSET_IM;
      } else {
        $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      }
      $self->{t} = $self->_get_next_token;
      return;
    } elsif ($self->{t}->{type} == START_TAG_TOKEN or
             $self->{t}->{type} == END_OF_FILE_TOKEN) {
      $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      ## Reprocess.
      return;
    } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($self->{t}->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($self->{t}->{target}, $self->{t}->{data});
      $self->{document}->append_child ($pi);

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == CHARACTER_TOKEN) {
      while ($self->{t}->{data} =~ s/\x00/\x{FFFD}/) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
      }

      if (not $self->{tainted} and
          not $self->{t}->{has_reference} and
          $self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
        #
      }
      
      if (length $self->{t}->{data}) {
        ## XML5: Ignore the token.

        unless ($self->{tainted}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'text outside of root element',
                          token => $self->{t});
          $self->{tainted} = 1;
        }

        $self->{document}->manakai_append_text ($self->{t}->{data});
      }

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                      text => $self->{t}->{tag_name},
                      token => $self->{t});
      ## Ignore the token.
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $self->{t}->{type}";
    }
  } # B
} # _tree_initial

sub _tree_before_root_element ($) {
  my $self = shift;

  B: while (1) {
    if ($self->{t}->{type} == START_TAG_TOKEN) {
      my $nsmap = {
        xml => q<http://www.w3.org/XML/1998/namespace>,
        xmlns => q<http://www.w3.org/2000/xmlns/>,
      };

      my $attrs = $self->{t}->{attributes};
      my $attrdefs = $self->{attrdef}->{$self->{t}->{tag_name}};
      for my $attr_name (keys %{$attrdefs}) {
        if ($attrs->{$attr_name}) {
          $attrs->{$attr_name}->{type} = $attrdefs->{$attr_name}->{type} || 0;
          if ($attrdefs->{$attr_name}->{tokenize}) {
            $attrs->{$attr_name}->{value} =~ s/  +/ /g;
            $attrs->{$attr_name}->{value} =~ s/\A //;
            $attrs->{$attr_name}->{value} =~ s/ \z//;
          }
        } elsif (defined $attrdefs->{$attr_name}->{default}) {
          $attrs->{$attr_name} = {
                                  value => $attrdefs->{$attr_name}->{default},
                                  type => $attrdefs->{$attr_name}->{type} || 0,
                                  not_specified => 1,
                                  line => $attrdefs->{$attr_name}->{line},
                                  column => $attrdefs->{$attr_name}->{column},
                                  index => 1 + keys %{$attrs},
                                 };
        }
      }
      
      for (keys %{$attrs}) {
        if (/^xmlns:./s) {
          my $prefix = substr $_, 6;
          my $value = $attrs->{$_}->{value};
          if ($prefix eq 'xml' or $prefix eq 'xmlns' or
              $value eq q<http://www.w3.org/XML/1998/namespace> or
              $value eq q<http://www.w3.org/2000/xmlns/>) {
            ## NOTE: Error should be detected at the DOM layer.
            #
          } elsif (length $value) {
            $nsmap->{$prefix} = $value;
          } else {
            delete $nsmap->{$prefix};
          }
        } elsif ($_ eq 'xmlns') {
          my $value = $attrs->{$_}->{value};
          if ($value eq q<http://www.w3.org/XML/1998/namespace> or
              $value eq q<http://www.w3.org/2000/xmlns/>) {
            ## NOTE: Error should be detected at the DOM layer.
            #
          } elsif (length $value) {
            $nsmap->{''} = $value;
          } else {
            delete $nsmap->{''};
          }
        }
      }
      
      my $ns;
      my ($prefix, $ln) = split /:/, $self->{t}->{tag_name}, 2;
      
      if (defined $ln and $prefix ne '' and $ln ne '') { # prefixed
        if (defined $nsmap->{$prefix}) {
          $ns = $nsmap->{$prefix};
        } else {
          ($prefix, $ln) = (undef, $self->{t}->{tag_name});
        }
      } else {
        $ns = $nsmap->{''} if $prefix ne '' and not defined $ln;
        ($prefix, $ln) = (undef, $self->{t}->{tag_name});
      }

      my $el = $self->{document}->create_element_ns ($ns, [$prefix, $ln]);
      $el->set_user_data (manakai_source_line => $self->{t}->{line});
      $el->set_user_data (manakai_source_column => $self->{t}->{column});

      my $has_attr;
      for my $attr_name (sort {$attrs->{$a}->{index} <=> $attrs->{$b}->{index}}
                         keys %{$attrs}) {
        my $ns;
        my ($p, $l) = split /:/, $attr_name, 2;

        if ($attr_name eq 'xmlns:xmlns') {
          ($p, $l) = (undef, $attr_name);
        } elsif (defined $l and $p ne '' and $l ne '') { # prefixed
          if (defined $nsmap->{$p}) {
            $ns = $nsmap->{$p};
          } else {
            ## NOTE: Error should be detected at the DOM-layer.
            ($p, $l) = (undef, $attr_name);
          }
        } else {
          if ($attr_name eq 'xmlns') {
            $ns = $nsmap->{xmlns};
          }
          ($p, $l) = (undef, $attr_name);
        }
        
        if ($has_attr->{defined $ns ? $ns : ''}->{$l}) {
          $ns = undef;
          ($p, $l) = (undef, $attr_name);
        } else {
          $has_attr->{defined $ns ? $ns : ''}->{$l} = 1;
        }
        
        my $attr_t = $attrs->{$attr_name};
        my $attr = $self->{document}->create_attribute_ns ($ns, [$p, $l]);
        $attr->value ($attr_t->{value});
        if (defined $attr_t->{type}) {
          $attr->manakai_attribute_type ($attr_t->{type});
        } elsif ($self->{document}->all_declarations_processed) {
          $attr->manakai_attribute_type (0); # no value
        } else {
          $attr->manakai_attribute_type (11); # unknown
        }
        $attr->set_user_data (manakai_source_line => $attr_t->{line});
        $attr->set_user_data (manakai_source_column => $attr_t->{column});
        $el->set_attribute_node_ns ($attr);
        $attr->specified (0) if $attr_t->{not_specified};
      }

      $self->{document}->append_child ($el);

      if ($self->{self_closing}) {
        delete $self->{self_closing};
        $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
      } else {
        push @{$self->{open_elements}}, [$el, $self->{t}->{tag_name}, $nsmap];
        $self->{insertion_mode} = IN_ELEMENT_IM;
      }

      #delete $self->{tainted};

      $self->{t} = $self->_get_next_token;
      return;
    } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($self->{t}->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($self->{t}->{target}, $self->{t}->{data});
      $self->{document}->append_child ($pi);

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == CHARACTER_TOKEN) {
      while ($self->{t}->{data} =~ s/\x00/\x{FFFD}/) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
      }

      if (not $self->{tainted} and
          not $self->{t}->{has_reference} and
          $self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
        #
      }
      
      if (length $self->{t}->{data}) {
        ## XML5: Ignore the token.

        unless ($self->{tainted}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'text outside of root element',
                          token => $self->{t});
          $self->{tainted} = 1;
        }

        $self->{document}->manakai_append_text ($self->{t}->{data});
      }

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'no root element',
                      token => $self->{t});
      
      $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
      ## Reprocess.
      return;
    } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                      text => $self->{t}->{tag_name},
                      token => $self->{t});
      ## Ignore the token.

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == DOCTYPE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#doctype',
                      token => $self->{t});
      ## Ignore the token.
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $self->{t}->{type}";
    }
  } # B
} # _tree_before_root_element

sub _tree_in_element ($) {
  my $self = shift;
  
  B: while (1) {
    if ($self->{t}->{type} == CHARACTER_TOKEN) {
      while ($self->{t}->{data} =~ s/\x00/\x{FFFD}/) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
      }
      $self->{open_elements}->[-1]->[0]->manakai_append_text ($self->{t}->{data});
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
      my $nsmap = {%{$self->{open_elements}->[-1]->[2]}};

      my $attrs = $self->{t}->{attributes};
      my $attrdefs = $self->{attrdef}->{$self->{t}->{tag_name}};
      for my $attr_name (keys %{$attrdefs}) {
        if ($attrs->{$attr_name}) {
          $attrs->{$attr_name}->{type} = $attrdefs->{$attr_name}->{type} || 0;
          if ($attrdefs->{$attr_name}->{tokenize}) {
            $attrs->{$attr_name}->{value} =~ s/  +/ /g;
            $attrs->{$attr_name}->{value} =~ s/\A //;
            $attrs->{$attr_name}->{value} =~ s/ \z//;
          }
        } elsif (defined $attrdefs->{$attr_name}->{default}) {
          $attrs->{$attr_name} = {
                                  value => $attrdefs->{$attr_name}->{default},
                                  type => $attrdefs->{$attr_name}->{type} || 0,
                                  not_specified => 1,
                                  line => $attrdefs->{$attr_name}->{line},
                                  column => $attrdefs->{$attr_name}->{column},
                                  index => 1 + keys %{$attrs},
                                 };
        }
      }
      
      for (keys %{$attrs}) {
        if (/^xmlns:./s) {
          my $prefix = substr $_, 6;
          my $value = $attrs->{$_}->{value};
          if ($prefix eq 'xml' or $prefix eq 'xmlns' or
              $value eq q<http://www.w3.org/XML/1998/namespace> or
              $value eq q<http://www.w3.org/2000/xmlns/>) {
            ## NOTE: Error should be detected at the DOM layer.
            #
          } elsif (length $value) {
            $nsmap->{$prefix} = $value;
          } else {
            delete $nsmap->{$prefix};
          }
        } elsif ($_ eq 'xmlns') {
          my $value = $attrs->{$_}->{value};
          if ($value eq q<http://www.w3.org/XML/1998/namespace> or
              $value eq q<http://www.w3.org/2000/xmlns/>) {
            ## NOTE: Error should be detected at the DOM layer.
            #
          } elsif (length $value) {
            $nsmap->{''} = $value;
          } else {
            delete $nsmap->{''};
          }
        }
      }
      
      my $ns;
      my ($prefix, $ln) = split /:/, $self->{t}->{tag_name}, 2;
      
      if (defined $ln and $prefix ne '' and $ln ne '') { # prefixed
        if (defined $nsmap->{$prefix}) {
          $ns = $nsmap->{$prefix};
        } else {
          ## NOTE: Error should be detected at the DOM layer.
          ($prefix, $ln) = (undef, $self->{t}->{tag_name});
        }
      } else {
        $ns = $nsmap->{''} if $prefix ne '' and not defined $ln;
        ($prefix, $ln) = (undef, $self->{t}->{tag_name});
      }

      my $el = $self->{document}->create_element_ns ($ns, [$prefix, $ln]);
      $el->set_user_data (manakai_source_line => $self->{t}->{line});
      $el->set_user_data (manakai_source_column => $self->{t}->{column});

      my $has_attr;
      for my $attr_name (sort {$attrs->{$a}->{index} <=> $attrs->{$b}->{index}}
                         keys %{$attrs}) {
        my $ns;
        my ($p, $l) = split /:/, $attr_name, 2;

        if ($attr_name eq 'xmlns:xmlns') {
          ($p, $l) = (undef, $attr_name);
        } elsif (defined $l and $p ne '' and $l ne '') { # prefixed
          if (defined $nsmap->{$p}) {
            $ns = $nsmap->{$p};
          } else {
            ## NOTE: Error should be detected at the DOM-layer.
            ($p, $l) = (undef, $attr_name);
          }
        } else {
          if ($attr_name eq 'xmlns') {
            $ns = $nsmap->{xmlns};
          }
          ($p, $l) = (undef, $attr_name);
        }
        
        if ($has_attr->{defined $ns ? $ns : ''}->{$l}) {
          $ns = undef;
          ($p, $l) = (undef, $attr_name);
        } else {
          $has_attr->{defined $ns ? $ns : ''}->{$l} = 1;
        }

        my $attr_t = $attrs->{$attr_name};
        my $attr = $self->{document}->create_attribute_ns ($ns, [$p, $l]);
        $attr->value ($attr_t->{value});
        if (defined $attr_t->{type}) {
          $attr->manakai_attribute_type ($attr_t->{type});
        } elsif ($self->{document}->all_declarations_processed) {
          $attr->manakai_attribute_type (0); # no value
        } else {
          $attr->manakai_attribute_type (11); # unknown
        }
        $attr->set_user_data (manakai_source_line => $attr_t->{line});
        $attr->set_user_data (manakai_source_column => $attr_t->{column});
        $el->set_attribute_node_ns ($attr);
        $attr->specified (0) if $attr_t->{not_specified};
      }

      $self->{open_elements}->[-1]->[0]->append_child ($el);

      if ($self->{self_closing}) {
        delete $self->{self_closing};
      } else {
        push @{$self->{open_elements}}, [$el, $self->{t}->{tag_name}, $nsmap];
      }
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
      if ($self->{t}->{tag_name} eq '') {
        ## Short end tag token.
        pop @{$self->{open_elements}};
      } elsif ($self->{open_elements}->[-1]->[1] eq $self->{t}->{tag_name}) {
        pop @{$self->{open_elements}};
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => $self->{t}->{tag_name},
                        token => $self->{t});
        
        ## Has an element in scope
        INSCOPE: for my $i (reverse 0..$#{$self->{open_elements}}) {
          if ($self->{open_elements}->[$i]->[1] eq $self->{t}->{tag_name}) {
            splice @{$self->{open_elements}}, $i;
            last INSCOPE;
          }
        } # INSCOPE
      }
      
      unless (@{$self->{open_elements}}) {
        $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
        $self->{t} = $self->_get_next_token;
        return;
      } else {
        ## Stay in the state.
        $self->{t} = $self->_get_next_token;
        redo B;
      }
    } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($self->{t}->{data});
      $self->{open_elements}->[-1]->[0]->append_child ($comment);
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($self->{t}->{target}, $self->{t}->{data});
      $self->{open_elements}->[-1]->[0]->append_child ($pi);

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof',
                      token => $self->{t});
      
      $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
      $self->{t} = $self->_get_next_token;
      return;
    } elsif ($self->{t}->{type} == DOCTYPE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#doctype',
                      token => $self->{t});
      ## Ignore the token.
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $self->{t}->{type}";
    }
  } # B
} # _tree_in_element

sub _tree_after_root_element ($) {
  my $self = shift;

  B: while (1) {
    if ($self->{t}->{type} == START_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'second root element',
                      token => $self->{t});

      ## XML5: Ignore the token.

      $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      ## Reprocess.
      return;
    } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($self->{t}->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($self->{t}->{target}, $self->{t}->{data});
      $self->{document}->append_child ($pi);

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == CHARACTER_TOKEN) {
      while ($self->{t}->{data} =~ s/\x00/\x{FFFD}/) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
      }

      if (not $self->{tainted} and
          not $self->{t}->{has_reference} and
          $self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
        #
      }
      
      if (length $self->{t}->{data}) {
        ## XML5: Ignore the token.

        unless ($self->{tainted}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'text outside of root element',
                          token => $self->{t});
          $self->{tainted} = 1;
        }

        $self->{document}->manakai_append_text ($self->{t}->{data});
      }

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
      ## Stop parsing.

      ## TODO: implement "stop parsing".

      $self->{t} = {type => ABORT_TOKEN};
      return;
    } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                      text => $self->{t}->{tag_name},
                      token => $self->{t});
      ## Ignore the token.

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == DOCTYPE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#doctype',
                      token => $self->{t});
      ## Ignore the token.
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $self->{t}->{type}";
    }
  } # B
} # _tree_after_root_element

sub _tree_in_subset ($) {
  my $self = shift;

  B: while (1) {
    if ($self->{t}->{type} == COMMENT_TOKEN) {
      ## Ignore the token.

      ## Stay in the state.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == ELEMENT_TOKEN) {
      unless ($self->{has_element_decl}->{$self->{t}->{name}}) {
        my $node = $self->{doctype}->get_element_type_definition_node
            ($self->{t}->{name});
        unless ($node) {
          $node = $self->{document}->create_element_type_definition
              ($self->{t}->{name});
          $self->{doctype}->set_element_type_definition_node ($node);
        }
        
        $node->set_user_data (manakai_source_line => $self->{t}->{line});
        $node->set_user_data (manakai_source_column => $self->{t}->{column});
        
        $node->content_model_text (join '', @{$self->{t}->{content}})
            if $self->{t}->{content};
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate element decl', ## TODO: type
                        value => $self->{t}->{name},
                        token => $self->{t});
        
        ## TODO: $self->{t}->{content} syntax check.
      }
      $self->{has_element_decl}->{$self->{t}->{name}} = 1;

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == ATTLIST_TOKEN) {
      if ($self->{stop_processing}) {
        ## TODO: syntax validation
      } else {
        my $ed = $self->{doctype}->get_element_type_definition_node
            ($self->{t}->{name});
        unless ($ed) {
          $ed = $self->{document}->create_element_type_definition
              ($self->{t}->{name});
          $ed->set_user_data (manakai_source_line => $self->{t}->{line});
          $ed->set_user_data (manakai_source_column => $self->{t}->{column});
          $self->{doctype}->set_element_type_definition_node ($ed);
        } elsif ($self->{has_attlist}->{$self->{t}->{name}}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate attlist decl', ## TODO: type
                          value => $self->{t}->{name},
                          token => $self->{t},
                          level => $self->{level}->{warn});
        }
        $self->{has_attlist}->{$self->{t}->{name}} = 1;
        
        unless (@{$self->{t}->{attrdefs}}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty attlist decl', ## TODO: type
                          value => $self->{t}->{name},
                          token => $self->{t},
                          level => $self->{level}->{warn});
        }
        
        for my $at (@{$self->{t}->{attrdefs}}) {
          unless ($ed->get_attribute_definition_node ($at->{name})) {
            my $node = $self->{document}->create_attribute_definition
                ($at->{name});
            $node->set_user_data (manakai_source_line => $at->{line});
            $node->set_user_data (manakai_source_column => $at->{column});
            
            my $type = defined $at->{type} ? {
              CDATA => 1, ID => 2, IDREF => 3, IDREFS => 4, ENTITY => 5,
              ENTITIES => 6, NMTOKEN => 7, NMTOKENS => 8, NOTATION => 9,
            }->{$at->{type}} : 10;
            if (defined $type) {
              $node->declared_type ($type);
            } else {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unknown declared type', ## TODO: type
                              value => $at->{type},
                              token => $at);
            }
            
            push @{$node->allowed_tokens}, @{$at->{tokens}};
            
            my $default = defined $at->{default} ? {
              FIXED => 1, REQUIRED => 2, IMPLIED => 3,
            }->{$at->{default}} : 4;
            if (defined $default) {
              $node->default_type ($default);
              if (defined $at->{value}) {
                if ($default == 1 or $default == 4) {
                  #
                } elsif (length $at->{value}) {
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'default value not allowed', ## TODO: type
                                  token => $at);
                }
              } else {
                if ($default == 1 or $default == 4) {
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'default value not provided', ## TODO: type
                                  token => $at);
                }
              }
            } else {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unknown default type', ## TODO: type
                              value => $at->{default},
                              token => $at);
            }

            $type ||= 0;
            my $tokenize = (2 <= $type and $type <= 10);

            if (defined $at->{value}) {
              if ($tokenize) {
                $at->{value} =~ s/  +/ /g;
                $at->{value} =~ s/\A //;
                $at->{value} =~ s/ \z//;
              }
              $node->text_content ($at->{value});
            }
            
            $ed->set_attribute_definition_node ($node);

            ## For tree construction
            $self->{attrdef}->{$self->{t}->{name}}->{$at->{name}}
                = {
                   type => $type,
                   tokenize => $tokenize,
                   default => (($default and ($default == 1 or $default == 4))
                                 ? defined $at->{value} ? $at->{value} : ''
                                 : undef),
                  };
          } else {
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate attrdef', ## TODO: type
                            value => $at->{name},
                            token => $at,
                            level => $self->{level}->{warn});
            
            ## TODO: syntax validation
          }
        } # $at
      }

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == GENERAL_ENTITY_TOKEN) {
      if ($self->{stop_processing}) {
        ## TODO: syntax validation
      } elsif ({
                amp => 1, apos => 1, quot => 1, lt => 1, gt => 1,
               }->{$self->{t}->{name}}) {
        if (not defined $self->{t}->{value} or
            $self->{t}->{value} !~
            {
             amp => qr/\A&#(?:x0*26|0*38);\z/,
             lt => qr/\A&#(?:x0*3[Cc]|0*60);\z/,
             gt => qr/\A(?>&#(?:x0*3[Ee]|0*62);|>)\z/,
             quot => qr/\A(?>&#(?:x0*22|0*34);|")\z/,
             apos => qr/\A(?>&#(?:x0*27|0*39);|')\z/,
            }->{$self->{t}->{name}}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad predefined entity decl', ## TODO: type
                          value => $self->{t}->{name},
                          token => $self->{t});
        }

        $self->{ge}->{$self->{t}->{name}.';'} = {name => $self->{t}->{name},
                                             value => {
                                                       amp => '&',
                                                       lt => '<',
                                                       gt => '>',
                                                       quot => '"',
                                                       apos => "'",
                                                      }->{$self->{t}->{name}},
                                             only_text => 1};
      } elsif (not $self->{ge}->{$self->{t}->{name}.';'}) {
        ## For parser.
        $self->{ge}->{$self->{t}->{name}.';'} = $self->{t};
        if (defined $self->{t}->{value} and
            $self->{t}->{value} !~ /[&<]/) {
          $self->{t}->{only_text} = 1;
        }
        
        ## For DOM.
        if (defined $self->{t}->{notation}) {
          my $node = $self->{document}->create_general_entity ($self->{t}->{name});
          $node->set_user_data (manakai_source_line => $self->{t}->{line});
          $node->set_user_data (manakai_source_column => $self->{t}->{column});
          
          $node->public_id ($self->{t}->{pubid}); # may be undef
          $node->system_id ($self->{t}->{sysid}); # may be undef
          $node->notation_name ($self->{t}->{notation});
          
          $self->{doctype}->set_general_entity_node ($node);
        } else {
          ## TODO: syntax validation
        }
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate general entity decl', ## TODO: type
                        value => $self->{t}->{name},
                        token => $self->{t},
                        level => $self->{level}->{warn});

        ## TODO: syntax validation        
      }

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == PARAMETER_ENTITY_TOKEN) {
      if ($self->{stop_processing}) {
        ## TODO: syntax validation
      } elsif (not $self->{pe}->{$self->{t}->{name}}) {
        ## For parser.
        $self->{pe}->{$self->{t}->{name}} = $self->{t};

        ## TODO: syntax validation
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate para entity decl', ## TODO: type
                        value => $self->{t}->{name},
                        token => $self->{t},
                        level => $self->{level}->{warn});

        ## TODO: syntax validation        
      }
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == NOTATION_TOKEN) {
      unless ($self->{doctype}->get_notation_node
                ($self->{t}->{name})) {
        my $node = $self->{document}->create_notation ($self->{t}->{name});
        $node->set_user_data (manakai_source_line => $self->{t}->{line});
        $node->set_user_data (manakai_source_column => $self->{t}->{column});
        
        $node->public_id ($self->{t}->{pubid}); # may be undef
        $node->system_id ($self->{t}->{sysid}); # may be undef
        
        $self->{doctype}->set_notation_node ($node);
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate notation decl', ## TODO: type
                        value => $self->{t}->{name},
                        token => $self->{t});

        ## TODO: syntax validation
      }

      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($self->{t}->{target}, $self->{t}->{data});
      $self->{doctype}->append_child ($pi);
      ## TODO: line/col
      
      ## Stay in the mode.
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == END_OF_DOCTYPE_TOKEN) {
      $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      $self->{t} = $self->_get_next_token;
      return;
    } elsif ($self->{t}->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser subset im: Unknown token type $self->{t}->{type}";
    }
  } # B

} # _tree_in_subset

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
