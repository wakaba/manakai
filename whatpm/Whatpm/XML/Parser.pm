package Whatpm::XML::Parser;
use strict;

push our @ISA, 'Whatpm::HTML';
use Whatpm::HTML::Tokenizer qw/:token/;

sub parse_char_string ($$$;$$) {
  #my ($self, $s, $doc, $onerror, $get_wrapper) = @_;
  my $self = shift;
  my $s = ref $_[0] ? $_[0] : \($_[0]);
  require Whatpm::Charset::DecodeHandle;
  my $input = Whatpm::Charset::DecodeHandle::CharString->new ($s);
  return $self->parse_char_stream ($input, @_[1..$#_]);
} # parse_char_string

sub parse_char_stream ($$$;$$) {
  my $self = ref $_[0] ? shift : shift->new;
  my $input = $_[0];
  $self->{document} = $_[1];
  @{$self->{document}->child_nodes} = ();

  ## NOTE: |set_inner_html| copies most of this method's code

  $self->{confident} = 1 unless exists $self->{confident};
  $self->{document}->input_encoding ($self->{input_encoding})
      if defined $self->{input_encoding};
## TODO: |{input_encoding}| is needless?

  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;
  $self->{set_nc} = sub {
    my $self = shift;

    my $char = '';
    if (defined $self->{next_nc}) {
      $char = $self->{next_nc};
      delete $self->{next_nc};
      $self->{nc} = ord $char;
    } else {
      $self->{char_buffer} = '';
      $self->{char_buffer_pos} = 0;

      my $count = $input->manakai_read_until
         ($self->{char_buffer}, qr/[^\x00\x0A\x0D]/, $self->{char_buffer_pos});
      if ($count) {
        $self->{line_prev} = $self->{line};
        $self->{column_prev} = $self->{column};
        $self->{column}++;
        $self->{nc}
            = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
        return;
      }

      if ($input->read ($char, 1)) {
        $self->{nc} = ord $char;
      } else {
        $self->{nc} = -1;
        return;
      }
    }

    ($self->{line_prev}, $self->{column_prev})
        = ($self->{line}, $self->{column});
    $self->{column}++;
    
    if ($self->{nc} == 0x000A) { # LF
      
      $self->{line}++;
      $self->{column} = 0;
    } elsif ($self->{nc} == 0x000D) { # CR
      
## TODO: support for abort/streaming
      my $next = '';
      if ($input->read ($next, 1) and $next ne "\x0A") {
        $self->{next_nc} = $next;
      }
      $self->{nc} = 0x000A; # LF # MUST
      $self->{line}++;
      $self->{column} = 0;
    } elsif ($self->{nc} == 0x0000) { # NULL
      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
      $self->{nc} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    }
  };

  $self->{read_until} = sub {
    #my ($scalar, $specials_range, $offset) = @_;
    return 0 if defined $self->{next_nc};

    my $pattern = qr/[^$_[1]\x00\x0A\x0D]/;
    my $offset = $_[2] || 0;

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      pos ($self->{char_buffer}) = $self->{char_buffer_pos};
      if ($self->{char_buffer} =~ /\G(?>$pattern)+/) {
        substr ($_[0], $offset)
            = substr ($self->{char_buffer}, $-[0], $+[0] - $-[0]);
        my $count = $+[0] - $-[0];
        if ($count) {
          $self->{column} += $count;
          $self->{char_buffer_pos} += $count;
          $self->{line_prev} = $self->{line};
          $self->{column_prev} = $self->{column} - 1;
          $self->{nc} = -1;
        }
        return $count;
      } else {
        return 0;
      }
    } else {
      my $count = $input->manakai_read_until ($_[0], $pattern, $_[2]);
      if ($count) {
        $self->{column} += $count;
        $self->{line_prev} = $self->{line};
        $self->{column_prev} = $self->{column} - 1;
        $self->{nc} = -1;
      }
      return $count;
    }
  }; # $self->{read_until}

  my $onerror = $_[2] || sub {
    my (%opt) = @_;
    my $line = $opt{token} ? $opt{token}->{line} : $opt{line};
    my $column = $opt{token} ? $opt{token}->{column} : $opt{column};
    warn "Parse error ($opt{type}) at line $line column $column\n";
  };
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  my $char_onerror = sub {
    my (undef, $type, %opt) = @_;
    $self->{parse_error}->(level => $self->{level}->{must}, layer => 'encode',
                    line => $self->{line}, column => $self->{column} + 1,
                    %opt, type => $type);
  }; # $char_onerror

  if ($_[3]) {
    $input = $_[3]->($input);
    $input->onerror ($char_onerror);
  } else {
    $input->onerror ($char_onerror) unless defined $input->onerror;
  }

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->_construct_tree;
  $self->_terminate_tree_constructor;

  delete $self->{parse_error}; # remove loop

  return $self->{document};
} # parse_char_stream

sub new ($) {
  my $class = shift;
  my $self = bless {
    level => {must => 'm',
              should => 's',
              warn => 'w',
              info => 'i',
              uncertain => 'u'},
  }, $class;
  $self->{set_nc} = sub {
    $self->{nc} = -1;
  };
  $self->{parse_error} = sub {
    # 
  };
  $self->{change_encoding} = sub {
    # if ($_[0] is a supported encoding) {
    #   run "change the encoding" algorithm;
    #   throw Whatpm::HTML::RestartParser (charset => $new_encoding);
    # }
  };
  $self->{application_cache_selection} = sub {
    #
  };

  $self->{is_xml} = 1;

  return $self;
} # new

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

## Insertion modes
sub INITIAL_IM () { 0 }
sub BEFORE_ROOT_ELEMENT_IM () { 1 }
sub IN_ELEMENT_IM () { 2 }
sub AFTER_ROOT_ELEMENT_IM () { 3 }
sub IN_SUBSET_IM () { 4 }

{
my $token; ## TODO: change to $self->{t}

sub _construct_tree ($) {
  my ($self) = @_;

  delete $self->{tainted};
  $self->{open_elements} = [];
  $self->{insertion_mode} = INITIAL_IM;

  $token = $self->_get_next_token;

  ## XML5: No support for the XML declaration
  if ($token->{type} == PI_TOKEN and
      $token->{target} eq 'xml' and
      $token->{data} =~ /\Aversion[\x09\x0A\x20]*=[\x09\x0A\x20]*
                         (?>"([^"]*)"|'([^']*)')
                         (?:[\x09\x0A\x20]+
                            encoding[\x09\x0A\x20]*=[\x09\x0A\x20]*
                            (?>"([^"]*)"|'([^']*)')[\x09\x0A\x20]*)?
                         (?:[\x09\x0A\x20]+
                            standalone[\x09\x0A\x20]*=[\x09\x0A\x20]*
                            (?>"(yes|no)"|'(yes|no)'))?
                         [\x09\x0A\x20]*\z/x) {
    $self->{document}->xml_version (defined $1 ? $1 : $2);
    $self->{document}->xml_encoding (defined $3 ? $3 : $4); # possibly undef
    $self->{document}->xml_standalone (($5 || $6 || 'no') ne 'no');

    $token = $self->_get_next_token;
  } else {
    $self->{document}->xml_version ('1.0');
    $self->{document}->xml_encoding (undef);
    $self->{document}->xml_standalone (0);
  }
  
  while (1) {
    if ($self->{insertion_mode} == IN_ELEMENT_IM) {
      $self->_tree_in_element;
    } elsif ($self->{insertion_mode} == IN_SUBSET_IM) {
      $self->_tree_in_subset;
    } elsif ($self->{insertion_mode} == AFTER_ROOT_ELEMENT_IM) {
      $self->_tree_after_root_element;
    } elsif ($self->{insertion_mode} == BEFORE_ROOT_ELEMENT_IM) {
      $self->_tree_before_root_element;
    } elsif ($self->{insertion_mode} == INITIAL_IM) {
      $self->_tree_initial;
    } else {
      die "$0: Unknown XML insertion mode: $self->{insertion_mode}";
    }

    last if $token->{type} == ABORT_TOKEN;
  }
} # _construct_tree

sub _tree_initial ($) {
  my $self = shift;

  B: while (1) {
    if ($token->{type} == DOCTYPE_TOKEN) {
      ## XML5: No "DOCTYPE" token.
      
      my $doctype = $self->{document}->create_document_type_definition
          (defined $token->{name} ? $token->{name} : '');
      
      ## NOTE: Default value for both |public_id| and |system_id| attributes
      ## are empty strings, so that we don't set any value in missing cases.
      $doctype->public_id ($token->{pubid}) if defined $token->{pubid};
      $doctype->system_id ($token->{sysid}) if defined $token->{sysid};
      
      ## TODO: internal_subset
      
      $self->{document}->append_child ($doctype);

      ## XML5: No "has internal subset" flag.
      if ($token->{has_internal_subset}) {
        $self->{doctype} = $doctype;
        $self->{insertion_mode} = IN_SUBSET_IM;
      } else {
        $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      }
      $token = $self->_get_next_token;
      return;
    } elsif ($token->{type} == START_TAG_TOKEN or
             $token->{type} == END_OF_FILE_TOKEN) {
      $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      ## Reprocess.
      return;
    } elsif ($token->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($token->{target}, $token->{data});
      $self->{document}->append_child ($pi);

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == CHARACTER_TOKEN) {
      if (not $self->{tainted} and
          not $token->{has_reference} and
          $token->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
        #
      }
      
      if (length $token->{data}) {
        ## XML5: Ignore the token.

        unless ($self->{tainted}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'text outside of root element',
                          token => $token);
          $self->{tainted} = 1;
        }

        $self->{document}->manakai_append_text ($token->{data});
      }

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == END_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                      text => $token->{tag_name},
                      token => $token);
      ## Ignore the token.
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $token->{type}";
    }
  } # B
} # _tree_initial

sub _tree_before_root_element ($) {
  my $self = shift;

  B: while (1) {
    if ($token->{type} == START_TAG_TOKEN) {
      my $nsmap = {
        xml => q<http://www.w3.org/XML/1998/namespace>,
        xmlns => q<http://www.w3.org/2000/xmlns/>,
      };
      
      for (keys %{$token->{attributes}}) {
        if (/^xmlns:./s) {
          my $prefix = substr $_, 6;
          my $value = $token->{attributes}->{$_}->{value};
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
          my $value = $token->{attributes}->{$_}->{value};
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
      my ($prefix, $ln) = split /:/, $token->{tag_name}, 2;
      
      if (defined $ln and $prefix ne '' and $ln ne '') { # prefixed
        if (defined $nsmap->{$prefix}) {
          $ns = $nsmap->{$prefix};
        } else {
          ($prefix, $ln) = (undef, $token->{tag_name});
        }
      } else {
        $ns = $nsmap->{''} if $prefix ne '' and not defined $ln;
        ($prefix, $ln) = (undef, $token->{tag_name});
      }

      my $el = $self->{document}->create_element_ns ($ns, [$prefix, $ln]);
      $el->set_user_data (manakai_source_line => $token->{line});
      $el->set_user_data (manakai_source_column => $token->{column});

      my $has_attr;
      for my $attr_name (sort {$token->{attributes}->{$a}->{index} <=>
                               $token->{attributes}->{$b}->{index}}
                         keys %{$token->{attributes}}) {
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
        
        my $attr_t = $token->{attributes}->{$attr_name};
        my $attr = $self->{document}->create_attribute_ns ($ns, [$p, $l]);
        $attr->value ($attr_t->{value});
        $attr->set_user_data (manakai_source_line => $attr_t->{line});
        $attr->set_user_data (manakai_source_column => $attr_t->{column});
        $el->set_attribute_node_ns ($attr);
      }

      $self->{document}->append_child ($el);

      if ($self->{self_closing}) {
        delete $self->{self_closing};
        $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
      } else {
        push @{$self->{open_elements}}, [$el, $token->{tag_name}, $nsmap];
        $self->{insertion_mode} = IN_ELEMENT_IM;
      }

      #delete $self->{tainted};

      $token = $self->_get_next_token;
      return;
    } elsif ($token->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($token->{target}, $token->{data});
      $self->{document}->append_child ($pi);

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == CHARACTER_TOKEN) {
      if (not $self->{tainted} and
          not $token->{has_reference} and
          $token->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
        #
      }
      
      if (length $token->{data}) {
        ## XML5: Ignore the token.

        unless ($self->{tainted}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'text outside of root element',
                          token => $token);
          $self->{tainted} = 1;
        }

        $self->{document}->manakai_append_text ($token->{data});
      }

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == END_OF_FILE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'no root element',
                      token => $token);
      
      $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
      ## Reprocess.
      return;
    } elsif ($token->{type} == END_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                      text => $token->{tag_name},
                      token => $token);
      ## Ignore the token.

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == DOCTYPE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#doctype',
                      token => $token);
      ## Ignore the token.
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $token->{type}";
    }
  } # B
} # _tree_before_root_element

sub _tree_in_element ($) {
  my $self = shift;
  
  B: while (1) {
    if ($token->{type} == CHARACTER_TOKEN) {
      $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == START_TAG_TOKEN) {
      my $nsmap = {%{$self->{open_elements}->[-1]->[2]}};
      
      for (keys %{$token->{attributes}}) {
        if (/^xmlns:./s) {
          my $prefix = substr $_, 6;
          my $value = $token->{attributes}->{$_}->{value};
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
          my $value = $token->{attributes}->{$_}->{value};
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
      my ($prefix, $ln) = split /:/, $token->{tag_name}, 2;
      
      if (defined $ln and $prefix ne '' and $ln ne '') { # prefixed
        if (defined $nsmap->{$prefix}) {
          $ns = $nsmap->{$prefix};
        } else {
          ## NOTE: Error should be detected at the DOM layer.
          ($prefix, $ln) = (undef, $token->{tag_name});
        }
      } else {
        $ns = $nsmap->{''} if $prefix ne '' and not defined $ln;
        ($prefix, $ln) = (undef, $token->{tag_name});
      }

      my $el = $self->{document}->create_element_ns ($ns, [$prefix, $ln]);
      $el->set_user_data (manakai_source_line => $token->{line});
      $el->set_user_data (manakai_source_column => $token->{column});

      my $has_attr;
      for my $attr_name (sort {$token->{attributes}->{$a}->{index} <=>
                               $token->{attributes}->{$b}->{index}}
                         keys %{$token->{attributes}}) {
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

        my $attr_t = $token->{attributes}->{$attr_name};
        my $attr = $self->{document}->create_attribute_ns ($ns, [$p, $l]);
        $attr->value ($attr_t->{value});
        $attr->set_user_data (manakai_source_line => $attr_t->{line});
        $attr->set_user_data (manakai_source_column => $attr_t->{column});
        $el->set_attribute_node_ns ($attr);
      }

      $self->{open_elements}->[-1]->[0]->append_child ($el);

      if ($self->{self_closing}) {
        delete $self->{self_closing};
      } else {
        push @{$self->{open_elements}}, [$el, $token->{tag_name}, $nsmap];
      }
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == END_TAG_TOKEN) {
      if ($token->{tag_name} eq '') {
        ## Short end tag token.
        pop @{$self->{open_elements}};
      } elsif ($self->{open_elements}->[-1]->[1] eq $token->{tag_name}) {
        pop @{$self->{open_elements}};
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => $token->{tag_name},
                        token => $token);
        
        ## Has an element in scope
        INSCOPE: for my $i (reverse 0..$#{$self->{open_elements}}) {
          if ($self->{open_elements}->[$i]->[1] eq $token->{tag_name}) {
            splice @{$self->{open_elements}}, $i;
            last INSCOPE;
          }
        } # INSCOPE
      }
      
      unless (@{$self->{open_elements}}) {
        $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
        $token = $self->_get_next_token;
        return;
      } else {
        ## Stay in the state.
        $token = $self->_get_next_token;
        redo B;
      }
    } elsif ($token->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{open_elements}->[-1]->[0]->append_child ($comment);
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($token->{target}, $token->{data});
      $self->{open_elements}->[-1]->[0]->append_child ($pi);

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == END_OF_FILE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof',
                      token => $token);
      
      $self->{insertion_mode} = AFTER_ROOT_ELEMENT_IM;
      $token = $self->_get_next_token;
      return;
    } elsif ($token->{type} == DOCTYPE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#doctype',
                      token => $token);
      ## Ignore the token.
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $token->{type}";
    }
  } # B
} # _tree_in_element

sub _tree_after_root_element ($) {
  my $self = shift;

  B: while (1) {
    if ($token->{type} == START_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'second root element',
                      token => $token);

      ## XML5: Ignore the token.

      $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      ## Reprocess.
      return;
    } elsif ($token->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($token->{target}, $token->{data});
      $self->{document}->append_child ($pi);

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == CHARACTER_TOKEN) {
      if (not $self->{tainted} and
          not $token->{has_reference} and
          $token->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
        #
      }
      
      if (length $token->{data}) {
        ## XML5: Ignore the token.

        unless ($self->{tainted}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'text outside of root element',
                          token => $token);
          $self->{tainted} = 1;
        }

        $self->{document}->manakai_append_text ($token->{data});
      }

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == END_OF_FILE_TOKEN) {
      ## Stop parsing.

      ## TODO: implement "stop parsing".

      $token = {type => ABORT_TOKEN};
      return;
    } elsif ($token->{type} == END_TAG_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                      text => $token->{tag_name},
                      token => $token);
      ## Ignore the token.

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == DOCTYPE_TOKEN) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#doctype',
                      token => $token);
      ## Ignore the token.
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser initial: Unknown token type $token->{type}";
    }
  } # B
} # _tree_after_root_element

sub _tree_in_subset ($) {
  my $self = shift;

  B: while (1) {
    if ($token->{type} == COMMENT_TOKEN) {
      ## Ignore the token.

      ## Stay in the state.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == ELEMENT_TOKEN) {
      unless ($self->{doctype}->get_element_type_definition_node
                ($token->{name})) {
        my $node = $self->{document}->create_element_type_definition
            ($token->{name});
        $node->set_user_data (manakai_source_line => $token->{line});
        $node->set_user_data (manakai_source_column => $token->{column});
        
        ## TODO: ...
        
        $self->{doctype}->set_element_type_definition_node ($node);
      } else {
        ## TODO: ...
        
      }

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == ATTLIST_TOKEN) {
      my $ed = $self->{doctype}->get_element_type_definition_node
          ($token->{name});
      unless ($ed) {
        $ed = $self->{document}->create_element_type_definition
            ($token->{name});
        $ed->set_user_data (manakai_source_line => $token->{line});
        $ed->set_user_data (manakai_source_column => $token->{column});
        $self->{doctype}->set_element_type_definition_node ($ed);
      }

      for my $at (@{$token->{attrdefs}}) {
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

          $node->text_content ($at->{value}) if defined $at->{value};
 
          $ed->set_attribute_definition_node ($node);
        } else {
          ## TODO: ...
        }
      } # $at

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == GENERAL_ENTITY_TOKEN) {
      ## TODO: predefined entity names

      unless ($self->{ge}->{$token->{name}}) {
        ## For parser.
        $self->{ge}->{$token->{name}} = $token;

        ## For DOM.
        if (defined $token->{notation}) {
          my $node = $self->{document}->create_general_entity ($token->{name});
          $node->set_user_data (manakai_source_line => $token->{line});
          $node->set_user_data (manakai_source_column => $token->{column});
          
          $node->public_id ($token->{pubid}); # may be undef
          $node->system_id ($token->{sysid}); # may be undef
          $node->notation_name ($token->{notation});
          
          $self->{doctype}->set_general_entity_node ($node);
        }
      } else {
        ## TODO: ...
        
      }

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == PARAMETER_ENTITY_TOKEN) {
      unless ($self->{pe}->{$token->{name}}) {
        ## For parser.
        $self->{pe}->{$token->{name}} = $token;
      } else {
        ## TODO: ...
      }
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == NOTATION_TOKEN) {
      unless ($self->{doctype}->get_notation_node
                ($token->{name})) {
        my $node = $self->{document}->create_notation ($token->{name});
        $node->set_user_data (manakai_source_line => $token->{line});
        $node->set_user_data (manakai_source_column => $token->{column});
        
        $node->public_id ($token->{pubid}); # may be undef
        $node->system_id ($token->{sysid}); # may be undef
        
        $self->{doctype}->set_notation_node ($node);
      } else {
        ## TODO: ...
        
      }

      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == PI_TOKEN) {
      my $pi = $self->{document}->create_processing_instruction
          ($token->{target}, $token->{data});
      $self->{doctype}->append_child ($pi);
      ## TODO: line/col
      
      ## Stay in the mode.
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == END_OF_DOCTYPE_TOKEN) {
      $self->{insertion_mode} = BEFORE_ROOT_ELEMENT_IM;
      $token = $self->_get_next_token;
      return;
    } elsif ($token->{type} == ABORT_TOKEN) {
      return;
    } else {
      die "$0: XML parser subset im: Unknown token type $token->{type}";
    }
  } # B

} # _tree_in_subset

}

1;
