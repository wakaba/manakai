package Whatpm::CSS::Parser;
use strict;
use Whatpm::CSS::Tokenizer qw(:token);
require Whatpm::CSS::SelectorsParser;

sub new ($) {
  my $self = bless {onerror => sub { }, must_level => 'm',
                    message_level => 'w',
                    unsupported_level => 'unsupported'}, shift;
  # $self->{base_uri}
  # $self->{unitless_px} = 1/0

  return $self;
} # new

sub BEFORE_STATEMENT_STATE () { 0 }
sub BEFORE_DECLARATION_STATE () { 1 }
sub IGNORED_STATEMENT_STATE () { 2 }
sub IGNORED_DECLARATION_STATE () { 3 }

our $Prop; ## By CSS property name
our $Attr; ## By CSSOM attribute name
our $Key; ## By internal key

sub parse_char_string ($$) {
  my $self = $_[0];

  my $s = $_[1];
  pos ($s) = 0;
  my $line = 1;
  my $column = 0;

  my $_onerror = $self->{onerror};
  my $onerror = sub {
    $_onerror->(@_, line => $line, column => $column);
  };
  
  my $tt = Whatpm::CSS::Tokenizer->new;
  $tt->{onerror} = $onerror;
  $tt->{get_char} = sub {
    if (pos $s < length $s) {
      my $c = ord substr $s, pos ($s)++, 1;
      if ($c == 0x000A) {
        $line++;
        $column = 0;
      } elsif ($c == 0x000D) {
        unless (substr ($s, pos ($s), 1) eq "\x0A") {
          $line++;
          $column = 0;
        } else {
          $column++;
        }
      } else {
        $column++;
      }
      return $c;
    } else {
      return -1;
    }
  }; # $tt->{get_char}
  $tt->init;

  my $sp = Whatpm::CSS::SelectorsParser->new;
  $sp->{onerror} = $onerror;
  $sp->{must_level} = $self->{must_level};
  $sp->{pseudo_element} = $self->{pseudo_element};
  $sp->{pseudo_class} = $self->{pseudo_class};

  my $nsmap = {};
  $sp->{lookup_namespace_uri} = sub {
    return $nsmap->{$_[0]}; # $_[0] is '' (default namespace) or prefix
  }; # $sp->{lookup_namespace_uri}

  ## TODO: Supported pseudo classes and elements...

  require Message::DOM::CSSStyleSheet;
  require Message::DOM::CSSRule;
  require Message::DOM::CSSStyleDeclaration;

  $self->{base_uri} = $self->{href} unless defined $self->{base_uri};

  my $state = BEFORE_STATEMENT_STATE;
  my $t = $tt->get_next_token;

  my $open_rules = [[]];
  my $current_rules = $open_rules->[-1];
  my $current_decls;
  my $closing_tokens = [];
  my $charset_allowed = 1;
  my $namespace_allowed = 1;

  S: {
    if ($state == BEFORE_STATEMENT_STATE) {
      $t = $tt->get_next_token
          while $t->{type} == S_TOKEN or
              $t->{type} == CDO_TOKEN or
              $t->{type} == CDC_TOKEN;

      if ($t->{type} == ATKEYWORD_TOKEN) {
        if (lc $t->{value} eq 'namespace') { ## TODO: case folding
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;

          my $prefix;
          if ($t->{type} == IDENT_TOKEN) {
            $prefix = lc $t->{value};
            ## TODO: Unicode lowercase
            
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          }

          if ($t->{type} == STRING_TOKEN or $t->{type} == URI_TOKEN) {
            my $uri = $t->{value};
            
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;

            ## ISSUE: On handling of empty namespace URI, Firefox 2 and
            ## Opera 9 work differently (See SuikaWiki:namespace).
            ## TODO: We need to check what we do once it is specced.

            if ($t->{type} == SEMICOLON_TOKEN) {
              if ($namespace_allowed) {
                $nsmap->{defined $prefix ? $prefix : ''} = $uri;
                push @$current_rules,
                    Message::DOM::CSSNamespaceRule->____new ($prefix, $uri);
                undef $charset_allowed;
              } else {
                $onerror->(type => 'at:namespace:not allowed',
                           level => $self->{must_level},
                           token => $t);
              }
              
              $t = $tt->get_next_token;
              ## Stay in the state.
              redo S;
            } else {
              #
            }
          } else {
            #
          }

          $onerror->(type => 'syntax error:at:namespace',
                     level => $self->{must_level},
                     token => $t);
          #
        } elsif (lc $t->{value} eq 'charset') { ## TODO: case folding
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;

          if ($t->{type} == STRING_TOKEN) {
            my $encoding = $t->{value};
            
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            
            if ($t->{type} == SEMICOLON_TOKEN) {
              if ($charset_allowed) {
                push @$current_rules,
                    Message::DOM::CSSCharsetRule->____new ($encoding);
                undef $charset_allowed;
              } else {
                 $onerror->(type => 'at:charset:not allowed',
                            level => $self->{must_level},
                            token => $t);
              }

              ## TODO: Detect the conformance errors for @charset...
              
              $t = $tt->get_next_token;
              ## Stay in the state.
              redo S;
            } else {
              #
            }
          } else {
            #
          }

          $onerror->(type => 'syntax error:at:charset',
                     level => $self->{must_level},
                     token => $t);
          #
        ## NOTE: When adding support for new at-rule, insert code
        ## "undef $charset_allowed" and "undef $namespace_token" as
        ## appropriate.
        } else {
          $onerror->(type => 'not supported:at:'.$t->{value},
                     level => $self->{unsupported_level},
                     token => $t);
        }

        $t = $tt->get_next_token;
        $state = IGNORED_STATEMENT_STATE;
        redo S;
      } elsif (@$open_rules > 1 and $t->{type} == RBRACE_TOKEN) {
        pop @$open_rules;
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == EOF_TOKEN) {
        if (@$open_rules > 1) {
          $onerror->(type => 'syntax error:block not closed',
                     level => $self->{must_level},
                     token => $t);
        }

        last S;
      } else {
        undef $charset_allowed;
        undef $namespace_allowed;

        ($t, my $selectors) = $sp->_parse_selectors_with_tokenizer
            ($tt, LBRACE_TOKEN, $t);

        $t = $tt->get_next_token
            while $t->{type} != LBRACE_TOKEN and $t->{type} != EOF_TOKEN;

        if ($t->{type} == LBRACE_TOKEN) {
          $current_decls = Message::DOM::CSSStyleDeclaration->____new;
          my $rs = Message::DOM::CSSStyleRule->____new
              ($selectors, $current_decls);
          push @{$current_rules}, $rs if defined $selectors;

          $state = BEFORE_DECLARATION_STATE;
          $t = $tt->get_next_token;
          redo S;
        } else {
          $onerror->(type => 'syntax error:after selectors',
                     level => $self->{must_level},
                     token => $t);

          ## Stay in the state.
          $t = $tt->get_next_token;
          redo S;
        }
      }
    } elsif ($state == BEFORE_DECLARATION_STATE) {
      ## NOTE: DELIM? in declaration will be removed:
      ## <http://csswg.inkedblade.net/spec/css2.1?s=declaration%20delim#issue-2>.

      my $prop_def;
      my $prop_value;
      my $prop_flag;
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ($t->{type} == IDENT_TOKEN) { # property
        my $prop_name = lc $t->{value}; ## TODO: case folding
        $t = $tt->get_next_token;
        if ($t->{type} == COLON_TOKEN) {
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;

          $prop_def = $Prop->{$prop_name};
          if ($prop_def and $self->{prop}->{$prop_name}) {
            ($t, $prop_value)
                = $prop_def->{parse}->($self, $prop_name, $tt, $t, $onerror);
            if ($prop_value) {
              ## NOTE: {parse} don't have to consume trailing spaces.
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;

              if ($t->{type} == EXCLAMATION_TOKEN) {
                $t = $tt->get_next_token;
                $t = $tt->get_next_token while $t->{type} == S_TOKEN;
                if ($t->{type} == IDENT_TOKEN and
                    lc $t->{value} eq 'important') { ## TODO: case folding
                  $prop_flag = 'important';
                  
                  $t = $tt->get_next_token;
                  $t = $tt->get_next_token while $t->{type} == S_TOKEN;

                  #
                } else {
                  $onerror->(type => 'syntax error:important',
                             level => $self->{must_level},
                             token => $t);
                  
                  ## Reprocess.
                  $state = IGNORED_DECLARATION_STATE;
                  redo S;
                }
              }

              #
            } else {
              ## Syntax error.
        
              ## Reprocess.
              $state = IGNORED_DECLARATION_STATE;
              redo S;
            }
          } else {
            $onerror->(type => 'not supported:property',
                       level => $self->{unsupported_level},
                       token => $t, value => $prop_name);

            #
            $state = IGNORED_DECLARATION_STATE;
            redo S;
          }
        } else {
          $onerror->(type => 'syntax error:property colon',
                     level => $self->{must_level},
                     token => $t);

          #
          $state = IGNORED_DECLARATION_STATE;
          redo S;
        }
      }

      if ($t->{type} == RBRACE_TOKEN) {
        $t = $tt->get_next_token;
        $state = BEFORE_STATEMENT_STATE;
        #redo S;
      } elsif ($t->{type} == SEMICOLON_TOKEN) {
        $t = $tt->get_next_token;
        ## Stay in the state.
        #redo S;
      } elsif ($t->{type} == EOF_TOKEN) {
        $onerror->(type => 'syntax error:ruleset not closed',
                   level => $self->{must_level},
                   token => $t);
        ## Reprocess.
        $state = BEFORE_STATEMENT_STATE;
        #redo S;
      } else {
        if ($prop_value) {
          $onerror->(type => 'syntax error:property semicolon',
                     level => $self->{must_level},
                     token => $t);
        } else {
          $onerror->(type => 'syntax error:property name',
                     level => $self->{must_level},
                     token => $t);
        }

        #
        $state = IGNORED_DECLARATION_STATE;
        redo S;
      }

      my $important = (defined $prop_flag and $prop_flag eq 'important');
      for my $set_prop_name (keys %{$prop_value or {}}) {
        my $set_prop_def = $Prop->{$set_prop_name};
        $$current_decls->{$set_prop_def->{key}}
            = [$prop_value->{$set_prop_name}, $prop_flag]
            if $important or
                not $$current_decls->{$set_prop_def->{key}} or
                not defined $$current_decls->{$set_prop_def->{key}}->[1];
      }
      redo S;
    } elsif ($state == IGNORED_STATEMENT_STATE or
             $state == IGNORED_DECLARATION_STATE) {
      if (@$closing_tokens) { ## Something is yet in opening state.
        if ($t->{type} == EOF_TOKEN) {
          @$closing_tokens = ();
          ## Reprocess.
          $state = $state == IGNORED_STATEMENT_STATE
              ? BEFORE_STATEMENT_STATE : BEFORE_DECLARATION_STATE;
          redo S;
        } elsif ($t->{type} == $closing_tokens->[-1]) {
          pop @$closing_tokens;
          if (@$closing_tokens == 0 and
              $t->{type} == RBRACE_TOKEN and
              $state == IGNORED_STATEMENT_STATE) {
            $t = $tt->get_next_token;
            $state = BEFORE_STATEMENT_STATE;
            redo S;
          } else {
            $t = $tt->get_next_token;
            ## Stay in the state.
            redo S;
          }
        } else {
          #
        }
      } else {
        if ($t->{type} == SEMICOLON_TOKEN) {
          $t = $tt->get_next_token;
          $state = $state == IGNORED_STATEMENT_STATE
              ? BEFORE_STATEMENT_STATE : BEFORE_DECLARATION_STATE;
          redo S;
        } elsif ($state == IGNORED_DECLARATION_STATE and
                 $t->{type} == RBRACE_TOKEN) {
          $t = $tt->get_next_token;
          $state = BEFORE_STATEMENT_STATE;
          redo S;
        } elsif ($t->{type} == EOF_TOKEN) {
          ## Reprocess.
          $state = $state == IGNORED_STATEMENT_STATE
              ? BEFORE_STATEMENT_STATE : BEFORE_DECLARATION_STATE;
          redo S;
        } else {
          #
        }
      }

      while (not {
        EOF_TOKEN, 1,
        RBRACE_TOKEN, 1,
        RBRACKET_TOKEN, 1,
        RPAREN_TOKEN, 1,
        SEMICOLON_TOKEN, 1,
      }->{$t->{type}}) {
        if ($t->{type} == LBRACE_TOKEN) {
          push @$closing_tokens, RBRACE_TOKEN;
        } elsif ($t->{type} == LBRACKET_TOKEN) {
          push @$closing_tokens, RBRACKET_TOKEN;
        } elsif ($t->{type} == LPAREN_TOKEN or $t->{type} == FUNCTION_TOKEN) {
          push @$closing_tokens, RPAREN_TOKEN;
        }

        $t = $tt->get_next_token;
      }

      #
      ## Stay in the state.
      redo S;
    } else {
      die "$0: parse_char_string: Unknown state: $state";
    }
  } # S

  my $ss = Message::DOM::CSSStyleSheet->____new
      (manakai_base_uri => $self->{base_uri},
       css_rules => $open_rules->[0],
       ## TODO: href
       ## TODO: owner_node
       ## TODO: media
       type => 'text/css', ## TODO: OK?
       _parser => $self);
  return $ss;
} # parse_char_string

my $compute_as_specified = sub ($$$$) {
  #my ($self, $element, $prop_name, $specified_value) = @_;
  return $_[3];
}; # $compute_as_specified

my $default_serializer = sub {
  my ($self, $prop_name, $value) = @_;
  if ($value->[0] eq 'NUMBER' or $value->[0] eq 'WEIGHT') {
    ## TODO: What we currently do for 'font-weight' is different from
    ## any browser for lighter/bolder cases.  We need to fix this, but
    ## how?
    return $value->[1]; ## TODO: big or small number cases?
  } elsif ($value->[0] eq 'DIMENSION') {
    return $value->[1] . $value->[2]; ## NOTE: This is what browsers do.
  } elsif ($value->[0] eq 'KEYWORD') {
    return $value->[1];
  } elsif ($value->[0] eq 'URI') {
    ## NOTE: This is what browsers do.
    return 'url('.$value->[1].')';
  } elsif ($value->[0] eq 'INHERIT') {
    return 'inherit';
  } elsif ($value->[0] eq 'DECORATION') {
    my @v = ();
    push @v, 'underline' if $value->[1];
    push @v, 'overline' if $value->[2];
    push @v, 'line-through' if $value->[3];
    push @v, 'blink' if $value->[4];
    return 'none' unless @v;
    return join ' ', @v;
  } else {
    return undef;
  }
}; # $default_serializer

$Prop->{color} = {
  css => 'color',
  dom => 'color',
  key => 'color',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == IDENT_TOKEN) {
      if (lc $t->{value} eq 'blue') { ## TODO: case folding
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ["RGBA", 0, 0, 255, 1]});
      } else {
        #
      }
    } else {
      #
    }

    $onerror->(type => 'syntax error:color',
               level => $self->{must_level},
               token => $t);
    
    return ($t, undef);
  },
  serialize => sub {
    my ($self, $prop_name, $value) = @_;
    if ($value->[0] eq 'RGBA') { ## TODO: %d? %f?
      return sprintf 'rgba(%d, %d, %d, %f)', @$value[1, 2, 3, 4];
    } else {
      return undef;
    }
  },
  initial => ["KEYWORD", "-manakai-initial-color"], ## NOTE: UA-dependent in CSS 2.1.
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{color} = $Prop->{color};
$Key->{color} = $Prop->{color};

my $one_keyword_parser = sub {
  my ($self, $prop_name, $tt, $t, $onerror) = @_;

  if ($t->{type} == IDENT_TOKEN) {
    my $prop_value = lc $t->{value}; ## TODO: case folding
    $t = $tt->get_next_token;
    if ($Prop->{$prop_name}->{keyword}->{$prop_value} and
        $self->{prop_value}->{$prop_name}->{$prop_value}) {
      return ($t, {$prop_name => ["KEYWORD", $prop_value]});
    } elsif ($prop_value eq 'inherit') {
      return ($t, {$prop_name => ['INHERIT']});
    }
  }
  
  $onerror->(type => 'syntax error:keyword:'.$prop_name,
             level => $self->{must_level},
             token => $t);
  return ($t, undef);
};

$Prop->{display} = {
  css => 'display',
  dom => 'display',
  key => 'display',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    block => 1, inline => 1, 'inline-block' => 1, 'inline-table' => 1,
    'list-item' => 1, none => 1,
    table => 1, 'table-caption' => 1, 'table-cell' => 1, 'table-column' => 1,
    'table-column-group' => 1, 'table-header-group' => 1,
    'table-footer-group' => 1, 'table-row' => 1, 'table-row-group' => 1,
  },
  initial => ["KEYWORD", "inline"],
  #inherited => 0,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;
    ## NOTE: CSS 2.1 Section 9.7.

    ## WARNING: |compute| for 'float' property invoke this CODE
    ## in some case.  Careless modification might cause a infinite loop.

    if (defined $specified_value and $specified_value->[0] eq 'KEYWORD') {
      if ($specified_value->[1] eq 'none') {
        ## Case 1 [CSS 2.1]
        return $specified_value;
      } else {
        my $position = $self->get_computed_value ($element, 'position');
        if ($position->[0] eq 'KEYWORD' and 
            ($position->[1] eq 'absolute' or 
             $position->[1] eq 'fixed')) {
          ## Case 2 [CSS 2.1]
          #
        } else {
          my $float = $self->get_computed_value ($element, 'float');
          if ($float->[0] eq 'KEYWORD' and $float->[1] ne 'none') {
            ## Caes 3 [CSS 2.1]
            #
          } elsif (not defined $element->manakai_parent_element) {
            ## Case 4 [CSS 2.1]
            #
          } else {
            ## Case 5 [CSS 2.1]
            return $specified_value;
          }
        }
        
        return ["KEYWORD",
                {
                 'inline-table' => 'table',
                 inline => 'block',
                 'run-in' => 'block',
                 'table-row-group' => 'block',
                 'table-column' => 'block',
                 'table-column-group' => 'block',
                 'table-header-group' => 'block',
                 'table-footer-group' => 'block',
                 'table-row' => 'block',
                 'table-cell' => 'block',
                 'table-caption' => 'block',
                 'inline-block' => 'block',
                }->{$specified_value->[1]} || $specified_value->[1]];
      }
    } else {
      return $specified_value; ## Maybe an error of the implementation.
    }
  },
};
$Attr->{display} = $Prop->{display};
$Key->{display} = $Prop->{display};

$Prop->{position} = {
  css => 'position',
  dom => 'position',
  key => 'position',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    static => 1, relative => 1, absolute => 1, fixed => 1,
  },
  initial => ["KEYWORD", "static"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{position} = $Prop->{position};
$Key->{position} = $Prop->{position};

$Prop->{float} = {
  css => 'float',
  dom => 'css_float',
  key => 'float',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    left => 1, right => 1, none => 1,
  },
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;
    ## NOTE: CSS 2.1 Section 9.7.

    ## WARNING: |compute| for 'display' property invoke this CODE
    ## in some case.  Careless modification might cause a infinite loop.
    
    if (defined $specified_value and $specified_value->[0] eq 'KEYWORD') {
      if ($specified_value->[1] eq 'none') {
        ## Case 1 [CSS 2.1]
        return $specified_value;
      } else {
        my $position = $self->get_computed_value ($element, 'position');
        if ($position->[0] eq 'KEYWORD' and 
            ($position->[1] eq 'absolute' or 
             $position->[1] eq 'fixed')) {
          ## Case 2 [CSS 2.1]
          return ["KEYWORD", "none"];
        }
      }
    }

    ## ISSUE: CSS 2.1 section 9.7 and 9.5.1 ('float' definition) disagree
    ## on computed value of 'float' property.
    
    ## Case 3, 4, and 5 [CSS 2.1]
    return $specified_value;
  },
};
$Attr->{css_float} = $Prop->{float};
$Attr->{style_float} = $Prop->{float}; ## NOTE: IEism
$Key->{float} = $Prop->{float};

$Prop->{clear} = {
  css => 'clear',
  dom => 'clear',
  key => 'clear',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    left => 1, right => 1, none => 1, both => 1,
  },
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{clear} = $Prop->{clear};
$Key->{clear} = $Prop->{clear};

$Prop->{direction} = {
  css => 'direction',
  dom => 'direction',
  key => 'direction',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    ltr => 1, rtl => 1,
  },
  initial => ["KEYWORD", "ltr"],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{direction} = $Prop->{direction};
$Key->{direction} = $Prop->{direction};

$Prop->{'unicode-bidi'} = {
  css => 'unicode-bidi',
  dom => 'unicode_bidi',
  key => 'unicode_bidi',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    normal => 1, embed => 1, 'bidi-override' => 1,
  },
  initial => ["KEYWORD", "normal"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{unicode_bidi} = $Prop->{'unicode-bidi'};
$Key->{unicode_bidi} = $Prop->{'unicode-bidi'};

$Prop->{overflow} = {
  css => 'overflow',
  dom => 'overflow',
  key => 'overflow',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    visible => 1, hidden => 1, scroll => 1, auto => 1,
  },
  initial => ["KEYWORD", "visible"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{overflow} = $Prop->{overflow};
$Key->{overflow} = $Prop->{overflow};

$Prop->{visibility} = {
  css => 'visibility',
  dom => 'visibility',
  key => 'visibility',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    visible => 1, hidden => 1, collapse => 1,
  },
  initial => ["KEYWORD", "visible"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{visibility} = $Prop->{visibility};
$Key->{visibility} = $Prop->{visibility};

$Prop->{'list-style-type'} = {
  css => 'list-style-type',
  dom => 'list_style_type',
  key => 'list_style_type',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    qw/
      disc 1 circle 1 square 1 decimal 1 decimal-leading-zero 1 
      lower-roman 1 upper-roman 1 lower-greek 1 lower-latin 1
      upper-latin 1 armenian 1 georgian 1 lower-alpha 1 upper-alpha 1
      none 1
    /,
  },
  initial => ["KEYWORD", 'disc'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{list_style_type} = $Prop->{'list-style-type'};
$Key->{list_style_type} = $Prop->{'list-style-type'};

$Prop->{'list-style-position'} = {
  css => 'list-style-position',
  dom => 'list_style_position',
  key => 'list_style_position',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    inside => 1, outside => 1,
  },
  initial => ["KEYWORD", 'outside'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{list_style_position} = $Prop->{'list-style-position'};
$Key->{list_style_position} = $Prop->{'list-style-position'};

$Prop->{'page-break-before'} = {
  css => 'page-break-before',
  dom => 'page_break_before',
  key => 'page_break_before',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    auto => 1, always => 1, avoid => 1, left => 1, right => 1,
  },
  initial => ["KEYWORD", 'auto'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{page_break_before} = $Prop->{'page-break-before'};
$Key->{page_break_before} = $Prop->{'page-break-before'};

$Prop->{'page-break-after'} = {
  css => 'page-break-after',
  dom => 'page_break_after',
  key => 'page_break_after',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    auto => 1, always => 1, avoid => 1, left => 1, right => 1,
  },
  initial => ["KEYWORD", 'auto'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{page_break_after} = $Prop->{'page-break-after'};
$Key->{page_break_after} = $Prop->{'page-break-after'};

$Prop->{'page-break-inside'} = {
  css => 'page-break-inside',
  dom => 'page_break_inside',
  key => 'page_break_inside',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    auto => 1, avoid => 1,
  },
  initial => ["KEYWORD", 'auto'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{page_break_inside} = $Prop->{'page-break-inside'};
$Key->{page_break_inside} = $Prop->{'page-break-inside'};

$Prop->{'background-repeat'} = {
  css => 'background-repeat',
  dom => 'background_repeat',
  key => 'background_repeat',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    repeat => 1, 'repeat-x' => 1, 'repeat-y' => 1, 'no-repeat' => 1,
  },
  initial => ["KEYWORD", 'repeat'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{background_repeat} = $Prop->{'background-repeat'};
$Key->{backgroud_repeat} = $Prop->{'background-repeat'};

$Prop->{'background-attachment'} = {
  css => 'background-attachment',
  dom => 'background_attachment',
  key => 'background_attachment',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    scroll => 1, fixed => 1,
  },
  initial => ["KEYWORD", 'scroll'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{background_attachment} = $Prop->{'background-attachment'};
$Key->{backgroud_attachment} = $Prop->{'background-attachment'};

$Prop->{'font-style'} = {
  css => 'font-style',
  dom => 'font_style',
  key => 'font_style',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    normal => 1, italic => 1, oblique => 1,
  },
  initial => ["KEYWORD", 'normal'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{font_style} = $Prop->{'font-style'};
$Key->{font_style} = $Prop->{'font-style'};

$Prop->{'font-variant'} = {
  css => 'font-variant',
  dom => 'font_variant',
  key => 'font_variant',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    normal => 1, 'small-caps' => 1,
  },
  initial => ["KEYWORD", 'normal'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{font_variant} = $Prop->{'font-variant'};
$Key->{font_variant} = $Prop->{'font-variant'};

$Prop->{'text-align'} = {
  css => 'text-align',
  dom => 'text_align',
  key => 'text_align',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    left => 1, right => 1, center => 1, justify => 1, ## CSS 2
    begin => 1, end => 1, ## CSS 3
  },
  initial => ["KEYWORD", 'begin'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{text_align} = $Prop->{'text-align'};
$Key->{text_align} = $Prop->{'text-align'};

$Prop->{'text-transform'} = {
  css => 'text-transform',
  dom => 'text_transform',
  key => 'text_transform',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    capitalize => 1, uppercase => 1, lowercase => 1, none => 1,
  },
  initial => ["KEYWORD", 'none'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{text_transform} = $Prop->{'text-transform'};
$Key->{text_transform} = $Prop->{'text-transform'};

$Prop->{'white-space'} = {
  css => 'white-space',
  dom => 'white_space',
  key => 'white_space',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    normal => 1, pre => 1, nowrap => 1, 'pre-wrap' => 1, 'pre-line' => 1,
  },
  initial => ["KEYWORD", 'normal'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{white_space} = $Prop->{'white-space'};
$Key->{white_space} = $Prop->{'white-space'};

$Prop->{'caption-side'} = {
  css => 'caption-side',
  dom => 'caption_side',
  key => 'caption_side',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    top => 1, bottom => 1,
  },
  initial => ['KEYWORD', 'top'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{caption_side} = $Prop->{'caption-side'};
$Key->{caption_side} = $Prop->{'caption-side'};

$Prop->{'table-layout'} = {
  css => 'table-layout',
  dom => 'table_layout',
  key => 'table_layout',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    auto => 1, fixed => 1,
  },
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{table_layout} = $Prop->{'table-layout'};
$Key->{table_layout} = $Prop->{'table-layout'};

$Prop->{'border-collapse'} = {
  css => 'border-collapse',
  dom => 'border_collapse',
  key => 'border_collapse',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    collapse => 1, separate => 1,
  },
  initial => ['KEYWORD', 'separate'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{border_collapse} = $Prop->{'border-collapse'};
$Key->{border_collapse} = $Prop->{'border-collapse'};

$Prop->{'empty-cells'} = {
  css => 'empty-cells',
  dom => 'empty_cells',
  key => 'empty_cells',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => {
    show => 1, hide => 1,
  },
  initial => ['KEYWORD', 'show'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{empty_cells} = $Prop->{'empty-cells'};
$Key->{empty_cells} = $Prop->{'empty-cells'};

$Prop->{'z-index'} = {
  css => 'z-index',
  dom => 'z_index',
  key => 'z_index',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $sign = -1;
      $t = $tt->get_next_token;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <http://suika.fam.cx/gate/2005/sw/z-index> for
      ## browser compatibility issue.
      my $value = $t->{number};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["NUMBER", $sign * int ($value / 1)]});
    } elsif ($sign > 0 and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($value eq 'auto') {
        ## NOTE: |z-index| is the default value and therefore it must be
        ## supported anyway.
        return ($t, {$prop_name => ["KEYWORD", 'auto']});
      } elsif ($value eq 'inherit') {
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'syntax error:'.$prop_name,
               level => $self->{must_level},
               token => $t);
    return ($t, undef);
  },
  serialize => $default_serializer,
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{z_index} = $Prop->{'z-index'};
$Key->{z_index} = $Prop->{'z-index'};

$Prop->{orphans} = {
  css => 'orphans',
  dom => 'orphans',
  key => 'orphans',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <http://suika.fam.cx/gate/2005/sw/orphans> and
      ## <http://suika.fam.cx/gate/2005/sw/widows> for
      ## browser compatibility issue.
      my $value = $t->{number};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["NUMBER", $sign * int ($value / 1)]});
    } elsif ($sign > 0 and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($value eq 'inherit') {
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'syntax error:'.$prop_name,
               level => $self->{must_level},
               token => $t);
    return ($t, undef);
  },
  serialize => $default_serializer,
  initial => ['NUMBER', 2],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{orphans} = $Prop->{orphans};
$Key->{orphans} = $Prop->{orphans};

$Prop->{widows} = {
  css => 'widows',
  dom => 'widows',
  key => 'widows',
  parse => $Prop->{orphans}->{parse},
  serialize => $default_serializer,
  initial => ['NUMBER', 2],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{widows} = $Prop->{widows};
$Key->{widows} = $Prop->{widows};

$Prop->{'font-size'} = {
  css => 'font-size',
  dom => 'font_size',
  key => 'font_size',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ({in => 1, cm => 1, mm => 1, pt => 1, pc => 1,
           em => 1, ex => 1, pt => 1}->{$unit} and $value >= 0) {
        return ($t, {$prop_name => ['DIMENSION', $value, $unit]});
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['PERCENTAGE', $value]}) if $value >= 0;
    } elsif ($self->{unitless_px} and $t->{type} == NUMBER_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['DIMENSION', $value, 'px']}) if $value >= 0;
    } elsif ($sign > 0 and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ({
           'xx-small' => 1, 'x-small' => 1, small => 1, medium => 1,
           large => 1, 'x-large' => 1, 'xx-large' => 1, 
           '-manakai-xxx-large' => 1, # -webkit-xxx-large
           larger => 1, smaller => 1,
          }->{$value}) {
        return ($t, {$prop_name => ['KEYWORD', $value]});        
      } elsif ($value eq 'inherit') {
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'syntax error:'.$prop_name,
               level => $self->{must_level},
               token => $t);
    return ($t, undef);
  },
  serialize => $default_serializer,
  initial => ['KEYWORD', 'medium'],
  inherited => 1,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;
    
    if (defined $specified_value) {
      if ($specified_value->[0] eq 'DIMENSION') {
        my $unit = $specified_value->[2];
        my $value = $specified_value->[1];

        if ($unit eq 'em' or $unit eq 'ex') {
          $value *= 0.5 if $unit eq 'ex';
          ## TODO: Preferred way to determine the |ex| size is defined
          ## in CSS 2.1.

          my $parent_element = $element->manakai_parent_element;
          if (defined $parent_element) {
            $value *= $self->get_computed_value ($parent_element, $prop_name)
                ->[1];
          } else {
            $value *= $self->{font_size}->[3]; # medium
          }
          $unit = 'px';
        } elsif ({in => 1, cm => 1, mm => 1, pt => 1, pc => 1}->{$unit}) {
          ($value *= 12, $unit = 'pc') if $unit eq 'pc';
          ($value /= 72, $unit = 'in') if $unit eq 'pt';
          ($value *= 2.54, $unit = 'cm') if $unit eq 'in';
          ($value *= 10, $unit = 'mm') if $unit eq 'cm';
          ($value /= 0.26, $unit = 'px') if $unit eq 'mm';
        }

        return ['DIMENSION', $value, $unit];
      } elsif ($specified_value->[0] eq 'PERCENTAGE') {
        my $parent_element = $element->manakai_parent_element;
        my $parent_cv;
        if (defined $parent_element) {
          $parent_cv = $self->get_computed_value
              ($parent_element, $prop_name);
        } else {
          $parent_cv = [undef, $self->{font_size}->[3]];
        }
        return ['DIMENSION', $parent_cv->[1] * $specified_value->[1] / 100,
                'px'];
      } elsif ($specified_value->[0] eq 'KEYWORD') {
        if ($specified_value->[1] eq 'larger') {
          my $parent_element = $element->manakai_parent_element;
          if (defined $parent_element) {
            my $parent_cv = $self->get_computed_value
                ($parent_element, $prop_name);
            return ['DIMENSION',
                    $self->{get_larger_font_size}->($self, $parent_cv->[1]),
                    'px'];
          } else { ## 'larger' relative to 'medium', initial of 'font-size'
            return ['DIMENSION', $self->{font_size}->[4], 'px'];
          }
        } elsif ($specified_value->[1] eq 'smaller') {
          my $parent_element = $element->manakai_parent_element;
          if (defined $parent_element) {
            my $parent_cv = $self->get_computed_value
                ($parent_element, $prop_name);
            return ['DIMENSION',
                    $self->{get_smaller_font_size}->($self, $parent_cv->[1]),
                    'px'];
          } else { ## 'smaller' relative to 'medium', initial of 'font-size'
            return ['DIMENSION', $self->{font_size}->[2], 'px'];
          }
        } else {
          return ['DIMENSION', $self->{font_size}->[{
            'xx-small' => 0,
            'x-small' => 1,
            small => 2,
            medium => 3,
            large => 4,
            'x-large' => 5,
            'xx-large' => 6,
            '-manakai-xxx-large' => 7,
          }->{$specified_value->[1]}], 'px'];
        }
      }
    }
    
    return $specified_value;
  },
};
$Attr->{font_size} = $Prop->{'font-size'};
$Key->{font_size} = $Prop->{'font-size'};

$Prop->{'font-weight'} = {
  css => 'font-weight',
  dom => 'font_weight',
  key => 'font_weight',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <http://suika.fam.cx/gate/2005/sw/font-weight> for
      ## browser compatibility issue.
      my $value = $t->{number};
      $t = $tt->get_next_token;
      if ($value % 100 == 0 and 100 <= $value and $value <= 900) {
        return ($t, {$prop_name => ['WEIGHT', $value, 0]});
      }
    } elsif ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ({
           normal => 1, bold => 1, bolder => 1, lighter => 1,
          }->{$value}) {
        return ($t, {$prop_name => ['KEYWORD', $value]});
      } elsif ($value eq 'inherit') {
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'syntax error:'.$prop_name,
               level => $self->{must_level},
               token => $t);
    return ($t, undef);
  },
  serialize => $default_serializer,
  initial => ['KEYWORD', 'normal'],
  inherited => 1,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value and $specified_value->[0] eq 'KEYWORD') {
      if ($specified_value->[1] eq 'normal') {
        return ['WEIGHT', 400, 0];
      } elsif ($specified_value->[1] eq 'bold') {
        return ['WEIGHT', 700, 0];
      } elsif ($specified_value->[1] eq 'bolder') {
        my $parent_element = $element->manakai_parent_element;
        if (defined $parent_element) {
          my $parent_value = $self->get_cascaded_value
              ($parent_element, $prop_name); ## NOTE: What Firefox does.
          return ['WEIGHT', $parent_value->[1], $parent_value->[2] + 1];
        } else {
          return ['WEIGHT', 400, 1];
        }
      } elsif ($specified_value->[1] eq 'lighter') {
        my $parent_element = $element->manakai_parent_element;
        if (defined $parent_element) {
          my $parent_value = $self->get_cascaded_value
              ($parent_element, $prop_name); ## NOTE: What Firefox does.
          return ['WEIGHT', $parent_value->[1], $parent_value->[2] - 1];
        } else {
          return ['WEIGHT', 400, 1];
        }
      }
    #} elsif (defined $specified_value and $specified_value->[0] eq 'WEIGHT') {
      #
    }

    return $specified_value;
  },
};
$Attr->{font_weight} = $Prop->{'font-weight'};
$Key->{font_weight} = $Prop->{'font-weight'};

my $uri_or_none_parser = sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == URI_TOKEN) {
      my $value = $t->{value};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['URI', $value, \($self->{base_uri})]});
    } elsif ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($value eq 'none') {
        ## NOTE: |none| is the default value and therefore it must be
        ## supported anyway.
        return ($t, {$prop_name => ["KEYWORD", 'none']});
      } elsif ($value eq 'inherit') {
        return ($t, {$prop_name => ['INHERIT']});
      }
    ## NOTE: None of Firefox2, WinIE6, and Opera9 support this case.
    #} elsif ($t->{type} == URI_INVALID_TOKEN) {
    #  my $value = $t->{value};
    #  $t = $tt->get_next_token;
    #  if ($t->{type} == EOF_TOKEN) {
    #    $onerror->(type => 'syntax error:eof:'.$prop_name,
    #               level => $self->{must_level},
    #               token => $t);
    #    
    #    return ($t, {$prop_name => ['URI', $value, \($self->{base_uri})]});
    #  }
    }
    
    $onerror->(type => 'syntax error:'.$prop_name,
               level => $self->{must_level},
               token => $t);
    return ($t, undef);
}; # $uri_or_none_parser

my $compute_uri_or_none = sub {
    my ($self, $element, $prop_name, $specified_value) = @_;
    
    if (defined $specified_value and
        $specified_value->[0] eq 'URI' and
        defined $specified_value->[2]) {
      require Message::DOM::DOMImplementation;
      return ['URI',
              Message::DOM::DOMImplementation->create_uri_reference
                  ($specified_value->[1])
                  ->get_absolute_reference (${$specified_value->[2]})
                  ->get_uri_reference,
              $specified_value->[2]];
    }

    return $specified_value;
}; # $compute_uri_or_none

$Prop->{'list-style-image'} = {
  css => 'list-style-image',
  dom => 'list_style_image',
  key => 'list_style_image',
  parse => $uri_or_none_parser,
  serialize => $default_serializer,
  initial => ['KEYWORD', 'none'],
  inherited => 1,
  compute => $compute_uri_or_none,
};
$Attr->{list_style_image} = $Prop->{'list-style-image'};
$Key->{list_style_image} = $Prop->{'list-style-image'};

$Prop->{'background-image'} = {
  css => 'background-image',
  dom => 'background_image',
  key => 'background_image',
  parse => $uri_or_none_parser,
  serialize => $default_serializer,
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_uri_or_none,
};
$Attr->{background_image} = $Prop->{'background-image'};
$Key->{background_image} = $Prop->{'background-image'};

my $border_style_keyword = {
  none => 1, hidden => 1, dotted => 1, dashed => 1, solid => 1,
  double => 1, groove => 1, ridge => 1, inset => 1, outset => 1,
};

$Prop->{'border-top-style'} = {
  css => 'border-top-style',
  dom => 'border_top_style',
  key => 'border_top_style',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => $border_style_keyword,
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{border_top_style} = $Prop->{'border-top-style'};
$Key->{border_top_style} = $Prop->{'border-top-style'};

$Prop->{'border-right-style'} = {
  css => 'border-right-style',
  dom => 'border_right_style',
  key => 'border_right_style',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => $border_style_keyword,
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{border_right_style} = $Prop->{'border-right-style'};
$Key->{border_right_style} = $Prop->{'border-right-style'};

$Prop->{'border-bottom-style'} = {
  css => 'border-bottom-style',
  dom => 'border_bottom_style',
  key => 'border_bottom_style',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => $border_style_keyword,
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{border_bottom_style} = $Prop->{'border-bottom-style'};
$Key->{border_bottom_style} = $Prop->{'border-bottom-style'};

$Prop->{'border-left-style'} = {
  css => 'border-left-style',
  dom => 'border_left_style',
  key => 'border_left_style',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => $border_style_keyword,
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{border_left_style} = $Prop->{'border-left-style'};
$Key->{border_left_style} = $Prop->{'border-left-style'};

$Prop->{'outline-style'} = {
  css => 'outline-style',
  dom => 'outline_style',
  key => 'outline_style',
  parse => $one_keyword_parser,
  serialize => $default_serializer,
  keyword => $border_style_keyword,
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{outline_style} = $Prop->{'outline-style'};
$Key->{outline_style} = $Prop->{'outline-style'};

$Prop->{'font-family'} = {
  css => 'font-family',
  dom => 'font_family',
  key => 'font_family',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    ## NOTE: See <http://suika.fam.cx/gate/2005/sw/font-family> for
    ## how chaotic browsers are!

    my @prop_value;

    my $font_name = '';
    my $may_be_generic = 1;
    my $may_be_inherit = 1;
    my $has_s = 0;
    F: {
      if ($t->{type} == IDENT_TOKEN) {
        undef $may_be_inherit if $has_s or length $font_name;
        undef $may_be_generic if $has_s or length $font_name;
        $font_name .= ' ' if $has_s;
        $font_name .= $t->{value};
        undef $has_s;
        $t = $tt->get_next_token;
      } elsif ($t->{type} == STRING_TOKEN) {
        $font_name .= ' ' if $has_s;
        $font_name .= $t->{value};
        undef $may_be_inherit;
        undef $may_be_generic;
        undef $has_s;
        $t = $tt->get_next_token;
      } elsif ($t->{type} == COMMA_TOKEN) {
        if ($may_be_generic and
            {
              serif => 1, 'sans-serif' => 1, cursive => 1,
              fantasy => 1, monospace => 1, '-manakai-default' => 1,
            }->{lc $font_name}) { ## TODO: case
          push @prop_value, ['KEYWORD', $font_name];
        } elsif (not $may_be_generic or length $font_name) {
          push @prop_value, ["STRING", $font_name];
        }
        undef $may_be_inherit;
        $may_be_generic = 1;
        undef $has_s;
        $font_name = '';
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      } elsif ($t->{type} == S_TOKEN) {
        $has_s = 1;
        $t = $tt->get_next_token;
      } else {
        if ($may_be_generic and
            {
              serif => 1, 'sans-serif' => 1, cursive => 1,
              fantasy => 1, monospace => 1, '-manakai-default' => 1,
            }->{lc $font_name}) { ## TODO: case
          push @prop_value, ['KEYWORD', $font_name];
        } elsif (not $may_be_generic or length $font_name) {
          push @prop_value, ['STRING', $font_name];
        } else {
          $onerror->(type => 'syntax error:'.$prop_name,
                     level => $self->{must_level},
                     token => $t);
          return ($t, undef);
        }
        last F;
      }
      redo F;
    } # F

    if ($may_be_inherit and
        @prop_value == 1 and
        $prop_value[0]->[0] eq 'STRING' and
        lc $prop_value[0]->[1] eq 'inherit') { ## TODO: case
      return ($t, {$prop_name => ['INHERIT']});
    } else {
      unshift @prop_value, 'FONT';
      return ($t, {$prop_name => \@prop_value});
    }
  },
  serialize => sub {
    my ($self, $prop_name, $value) = @_;

    if ($value->[0] eq 'FONT') {
      return join ', ', map {
        if ($_->[0] eq 'STRING') {
          '"'.$_->[1].'"'; ## NOTE: This is what Firefox does.
        } elsif ($_->[0] eq 'KEYWORD') {
          $_->[1]; ## NOTE: This is what Firefox does.
        } else {
          ## NOTE: This should be an error.
          '""';
        }
      } @$value[1..$#$value];
    } elsif ($value->[0] eq 'INHERIT') {
      return 'inherit';
    } else {
      return undef;
    }
  },
  initial => ['FONT', ['KEYWORD', '-manakai-default']],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{font_family} = $Prop->{'font-family'};
$Key->{font_family} = $Prop->{'font-family'};

$Prop->{cursor} = {
  css => 'cursor',
  dom => 'cursor',
  key => 'cursor',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    ## NOTE: See <http://suika.fam.cx/gate/2005/sw/cursor> for browser
    ## compatibility issues.

    my @prop_value = ('CURSOR');

    F: {
      if ($t->{type} == IDENT_TOKEN) {
        my $v = lc $t->{value}; ## TODO: case
        $t = $tt->get_next_token;
        if ($Prop->{$prop_name}->{keyword}->{$v}) {
          push @prop_value, ['KEYWORD', $v];
          last F;
        } elsif ($v eq 'inherit' and @prop_value == 1) {
          return ($t, {$prop_name => ['INHERIT']});
        } else {
          $onerror->(type => 'syntax error:'.$prop_name,
                     level => $self->{must_level},
                     token => $t);
          return ($t, undef);
        }
      } elsif ($t->{type} == URI_TOKEN) {
        push @prop_value, ['URI', $t->{value}, \($self->{base_uri})];
        $t = $tt->get_next_token;
      } else {
        $onerror->(type => 'syntax error:'.$prop_name,
                   level => $self->{must_level},
                   token => $t);
        return ($t, undef);
      }
    
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ($t->{type} == COMMA_TOKEN) {
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        redo F;
      }
    } # F

    return ($t, {$prop_name => \@prop_value});
  },
  serialize => sub {
    my ($self, $prop_name, $value) = @_;

    if ($value->[0] eq 'CURSOR') {
      return join ', ', map {
        if ($_->[0] eq 'URI') {
          'url('.$_->[1].')'; ## NOTE: This is what Firefox does.
        } elsif ($_->[0] eq 'KEYWORD') {
          $_->[1];
        } else {
          ## NOTE: This should be an error.
          '""';
        }
      } @$value[1..$#$value];
    } elsif ($value->[0] eq 'INHERIT') {
      return 'inherit';
    } else {
      return undef;
    }
  },
  keyword => {
    auto => 1, crosshair => 1, default => 1, pointer => 1, move => 1,
    'e-resize' => 1, 'ne-resize' => 1, 'nw-resize' => 1, 'n-resize' => 1,
    'n-resize' => 1, 'se-resize' => 1, 'sw-resize' => 1, 's-resize' => 1,
    'w-resize' => 1, text => 1, wait => 1, help => 1, progress => 1,
  },
  initial => ['CURSOR', ['KEYWORD', 'auto']],
  inherited => 1,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value and $specified_value->[0] eq 'CURSOR') {
      my @new_value = ('CURSOR');
      for my $value (@$specified_value[1..$#$specified_value]) {
        if ($value->[0] eq 'URI') {
          if (defined $value->[2]) {
            require Message::DOM::DOMImplementation;
            push @new_value, ['URI',
                              Message::DOM::DOMImplementation
                                  ->create_uri_reference ($value->[1])
                                  ->get_absolute_reference (${$value->[2]})
                                  ->get_uri_reference,
                              $value->[2]];
          } else {
            push @new_value, $value;
          }
        } else {
          push @new_value, $value;
        }
      }
      return \@new_value;
    }

    return $specified_value;
  },
};
$Attr->{cursor} = $Prop->{cursor};
$Key->{cursor} = $Prop->{cursor};

$Prop->{'border-style'} = {
  css => 'border-style',
  dom => 'border_style',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;
    my $has_inherit;
    if ($t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($border_style_keyword->{$prop_value} and
          $self->{prop_value}->{'border-top-style'}->{$prop_value}) {
        $prop_value{'border-top-style'} = ["KEYWORD", $prop_value];
      } elsif ($prop_value eq 'inherit') {
        $prop_value{'border-top-style'} = ["INHERIT"];
        $has_inherit = 1;
      } else {
        $onerror->(type => 'syntax error:keyword:'.$prop_name,
                   level => $self->{must_level},
                   token => $t);
        return ($t, undef);
      }
      $prop_value{'border-right-style'} = $prop_value{'border-top-style'};
      $prop_value{'border-bottom-style'} = $prop_value{'border-top-style'};
      $prop_value{'border-left-style'} = $prop_value{'border-right-style'};
    } else {
      $onerror->(type => 'syntax error:keyword:'.$prop_name,
                 level => $self->{must_level},
                 token => $t);
      return ($t, undef);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if (not $has_inherit and
          $border_style_keyword->{$prop_value} and
          $self->{prop_value}->{'border-right-style'}->{$prop_value}) {
        $prop_value{'border-right-style'} = ["KEYWORD", $prop_value];
      } else {
        $onerror->(type => 'syntax error:keyword:'.$prop_name,
                   level => $self->{must_level},
                   token => $t);
        return ($t, undef);
      }
      $prop_value{'border-left-style'} = $prop_value{'border-right-style'};

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ($t->{type} == IDENT_TOKEN) {
        my $prop_value = lc $t->{value}; ## TODO: case folding
        $t = $tt->get_next_token;
        if ($border_style_keyword->{$prop_value} and
            $self->{prop_value}->{'border-bottom-style'}->{$prop_value}) {
          $prop_value{'border-bottom-style'} = ["KEYWORD", $prop_value];
        } else {
          $onerror->(type => 'syntax error:keyword:'.$prop_name,
                     level => $self->{must_level},
                     token => $t);
          return ($t, undef);
        }
        
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == IDENT_TOKEN) {
          my $prop_value = lc $t->{value}; ## TODO: case folding
          $t = $tt->get_next_token;
          if ($border_style_keyword->{$prop_value} and
              $self->{prop_value}->{'border-left-style'}->{$prop_value}) {
            $prop_value{'border-left-style'} = ["KEYWORD", $prop_value];
          } else {
            $onerror->(type => 'syntax error:keyword:'.$prop_name,
                       level => $self->{must_level},
                       token => $t);
            return ($t, undef);
          }
        }
      }
    }        

    return ($t, \%prop_value);
  },
  serialize => sub {
    my ($self, $prop_name, $value) = @_;
    
    local $Error::Depth = $Error::Depth + 1;
    my @v;
    push @v, $self->border_top_style;
    return undef unless defined $v[-1];
    push @v, $self->border_right_style;
    return undef unless defined $v[-1];
    push @v, $self->border_bottom_style;
    return undef unless defined $v[-1];
    push @v, $self->border_bottom_style;
    return undef unless defined $v[-1];

    pop @v if $v[1] eq $v[3];
    pop @v if $v[0] eq $v[2];
    pop @v if $v[0] eq $v[1];
    return join ' ', @v;
  },
};
$Attr->{border_style} = $Prop->{'border-style'};

$Prop->{'list-style'} = {
  css => 'list-style',
  dom => 'list_style',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;
    my $none = 0;

    F: for my $f (1..3) {
      if ($t->{type} == IDENT_TOKEN) {
        my $prop_value = lc $t->{value}; ## TODO: case folding
        $t = $tt->get_next_token;

        if ($prop_value eq 'none') {
          $none++;
        } elsif ($Prop->{'list-style-type'}->{keyword}->{$prop_value}) {
          if (exists $prop_value{'list-style-type'}) {
            $onerror->(type => q[syntax error:duplicate:'list-style-type':].
                           $prop_name,
                       level => $self->{must_level},
                       token => $t);
            return ($t, undef);
          } else {
            $prop_value{'list-style-type'} = ['KEYWORD', $prop_value];
          }
        } elsif ($Prop->{'list-style-position'}->{keyword}->{$prop_value}) {
          if (exists $prop_value{'list-style-position'}) {
            $onerror->(type => q[syntax error:duplicate:'list-style-position':].
                           $prop_name,
                       level => $self->{must_level},
                       token => $t);
            return ($t, undef);
          }

          $prop_value{'list-style-position'} = ['KEYWORD', $prop_value];
        } elsif ($f == 1 and $prop_value eq 'inherit') {
          $prop_value{'list-style-type'} = ["INHERIT"];
          $prop_value{'list-style-position'} = ["INHERIT"];
          $prop_value{'list-style-image'} = ["INHERIT"];
          last F;
        } else {
          if ($f == 1) {
            $onerror->(type => 'syntax error:'.$prop_name,
                       level => $self->{must_level},
                       token => $t);
            return ($t, undef);
          } else {
            last F;
          }
        }
      } elsif ($t->{type} == URI_TOKEN) {
        if (exists $prop_value{'list-style-image'}) {
          $onerror->(type => q[syntax error:duplicate:'list-style-image':].
                         $prop_name,
                     level => $self->{must_level},
                     token => $t);
          return ($t, undef);
        }
        
        $prop_value{'list-style-image'}
            = ['URI', $t->{value}, \($self->{base_uri})];
        $t = $tt->get_next_token;
      } else {
        if ($f == 1) {
          $onerror->(type => 'syntax error:keyword:'.$prop_name,
                     level => $self->{must_level},
                     token => $t);
          return ($t, undef);
        } else {
          last F;
        }
      }

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    } # F
    ## NOTE: No browser support |list-style: url(xxx|{EOF}.

    if ($none == 1) {
      if (exists $prop_value{'list-style-type'}) {
        if (exists $prop_value{'list-style-image'}) {
          $onerror->(type => q[syntax error:duplicate:'list-style-image':].
                         $prop_name,
                     level => $self->{must_level},
                     token => $t);
          return ($t, undef);
        } else {
          $prop_value{'list-style-image'} = ['KEYWORD', 'none'];
        }
      } else {
        $prop_value{'list-style-type'} = ['KEYWORD', 'none'];
        $prop_value{'list-style-image'} = ['KEYWORD', 'none']
            unless exists $prop_value{'list-style-image'};
      }
    } elsif ($none == 2) {
      if (exists $prop_value{'list-style-type'}) {
        $onerror->(type => q[syntax error:duplicate:'list-style-type':].
                       $prop_name,
                   level => $self->{must_level},
                   token => $t);
        return ($t, undef);
      }
      if (exists $prop_value{'list-style-image'}) {
        $onerror->(type => q[syntax error:duplicate:'list-style-image':].
                       $prop_name,
                   level => $self->{must_level},
                   token => $t);
        return ($t, undef);
      }
      
      $prop_value{'list-style-type'} = ['KEYWORD', 'none'];
      $prop_value{'list-style-image'} = ['KEYWORD', 'none'];
    } elsif ($none == 3) {
      $onerror->(type => q[syntax error:duplicate:'list-style-type':].
                     $prop_name,
                 level => $self->{must_level},
                 token => $t);
      return ($t, undef);
    }

    for (qw/list-style-type list-style-position list-style-image/) {
      $prop_value{$_} = $Prop->{$_}->{initial} unless exists $prop_value{$_};
    }

    return ($t, \%prop_value);
  },
  serialize => sub {
    my ($self, $prop_name, $value) = @_;
    
    local $Error::Depth = $Error::Depth + 1;
    return $self->list_style_type . ' ' . $self->list_style_position .
        ' ' . $self->list_style_image;
  },
};
$Attr->{list_style} = $Prop->{'list-style'};

## NOTE: Future version of the implementation will change the way to
## store the parsed value to support CSS 3 properties.
$Prop->{'text-decoration'} = {
  css => 'text-decoration',
  dom => 'text_decoration',
  key => 'text_decoration',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $value = ['DECORATION']; # , underline, overline, line-through, blink

    if ($t->{type} == IDENT_TOKEN) {
      my $v = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($v eq 'inherit') {
        return ($t, {$prop_name => ['INHERIT']});
      } elsif ($v eq 'none') {
        return ($t, {$prop_name => $value});
      } elsif ($v eq 'underline' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[1] = 1;
      } elsif ($v eq 'overline' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[2] = 1;
      } elsif ($v eq 'line-through' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[3] = 1;
      } elsif ($v eq 'blink' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[4] = 1;
      } else {
        $onerror->(type => 'syntax error:'.$prop_name,
                   level => $self->{must_level},
                   token => $t);
        return ($t, undef);
      }
    }

    F: {
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      last F unless $t->{type} == IDENT_TOKEN;

      my $v = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($v eq 'underline' and
          $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[1] = 1;
      } elsif ($v eq 'overline' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[1] = 2;
      } elsif ($v eq 'line-through' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[1] = 3;
      } elsif ($v eq 'blink' and
               $self->{prop_value}->{$prop_name}->{$v}) {
        $value->[1] = 4;
      } else {
        last F;
      }

      redo F;
    } # F

    return ($t, {$prop_name => $value});
  },
  serialize => $default_serializer,
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{text_decoration} = $Prop->{'text-decoration'};
$Key->{text_decoration} = $Prop->{'text-decoration'};

1;
## $Date: 2008/01/03 08:37:22 $
