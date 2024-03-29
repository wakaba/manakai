package Whatpm::CSS::Parser;
use strict;
use warnings;
our $VERSION = '2.0';
use Whatpm::CSS::Tokenizer qw(:token);
require Whatpm::CSS::SelectorsParser;
require Whatpm::CSS::MediaQueryParser;

sub new ($) {
  my $self = bless {
    level => {
      must => 'm',
      should => 's',
      warning => 'w',
      uncertain => 'u',
    },
    lookup_namespace_uri => sub { undef },
  }, shift;
  # $self->{base_uri}
  # $self->{unitless_px} = 1/0
  # $self->{hashless_rgb} = 1/0

  ## Default error handler
  $self->{onerror} = sub {
    my %opt = @_;
    require Carp;
    Carp::carp
        (sprintf 'Document <%s>: Line %d column %d (token %s): %s%s',
             defined $opt{uri} ? ${$opt{uri}} : 'thisdocument:/',
             $opt{token}->{line},
             $opt{token}->{column},
             Whatpm::CSS::Tokenizer->serialize_token ($opt{token}),
             $opt{type},
             defined $opt{value} ? " (value $opt{value})" : '');
  };

  ## Media-dependent RGB color range clipper
  $self->{clip_color} = sub {
    shift; #my $self = shift;
    my $value = shift;
    if (defined $value and $value->[0] eq 'RGBA') {
      my ($r, $g, $b) = @$value[1, 2, 3];
      $r = 0 if $r < 0;  $r = 255 if $r > 255;
      $g = 0 if $g < 0;  $g = 255 if $g > 255;
      $b = 0 if $b < 0;  $b = 255 if $b > 255;
      return ['RGBA', $r, $g, $b, $value->[4]];
    }
    return $value;
  };

  ## System dependent font expander
  $self->{get_system_font} = sub {
    #my ($self, $normalized_system_font_name, $font_properties) = @_;
    ## Modify $font_properties hash (except for 'font-family' property).
    return $_[2];
  };

  return $self;
} # new

sub BEFORE_STATEMENT_STATE () { 0 }
sub BEFORE_DECLARATION_STATE () { 1 }
sub IGNORED_STATEMENT_STATE () { 2 }
sub IGNORED_DECLARATION_STATE () { 3 }

our $Prop; ## By CSS property name
our $Attr; ## By CSSOM attribute name
our $Key; ## By internal key

sub init ($) {
  my $self = shift;
  delete $self->{style_sheet};
  delete $self->{unitless_px};
  delete $self->{hashless_rgb};
  delete $self->{href};
  delete $self->{base_uri};
} # init

sub parse_char_string ($$) {
  my $self = $_[0];

  my $s = $_[1];
  pos ($s) = 0;
  my $line = 1;
  my $column = 0;
  
  my $tt = Whatpm::CSS::Tokenizer->new;
  my $onerror = $tt->{onerror} = $self->{onerror};
  $tt->{href} = $self->{href};
  $tt->{level} = $self->{level};
  $tt->{get_char} = sub ($) {
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
      $_[0]->{line_prev} = $_[0]->{line};
      $_[0]->{column_prev} = $_[0]->{column};
      $_[0]->{line} = $line;
      $_[0]->{column} = $column;
      return $c;
    } else {
      $_[0]->{line_prev} = $_[0]->{line};
      $_[0]->{column_prev} = $_[0]->{column};
      $_[0]->{line} = $line;
      $_[0]->{column} = $column + 1; ## Set the same number always.
      return -1;
    }
  }; # $tt->{get_char}
  $tt->{line} = $line;
  $tt->{column} = $column;
  $tt->init;

  my $sp = Whatpm::CSS::SelectorsParser->new;
  $sp->{onerror} = $self->{onerror};
  $sp->{level} = $self->{level};
  $sp->{pseudo_element} = $self->{pseudo_element};
  $sp->{pseudo_class} = $self->{pseudo_class};

  my $mp = Whatpm::CSS::MediaQueryParser->new;
  $mp->{onerror} = $self->{onerror};
  $mp->{level} = $self->{level};

  my $nsmap = {prefix_to_uri => {}, uri_to_prefixes => {}};

  # $nsmap->{prefix_to_uri}->{p/""} = uri/undef
  #
  ## A mapping from namespace prefixes to namespace URLs.  The empty
  ## string as the namespace prefix (or the key of the hash)
  ## represents the default namespace.  The empty string as the
  ## namespace URL represents the null namespace, while the |undef|
  ## value as the namespace URL represents the missing of the
  ## namespace prefix declaration.

  # $nsmap->{uri_to_prefixes}->{uri} = ["p|"/"",...]/undef
  # $nsmap->{has_namespace} = 1/0

  ## See the note for the |prefix_to_uri| value above.
  ##
  ## XXX empty vs null should not be distinguished for compat with
  ## DOM's |lookupNamespaceURI| method.
  $self->{lookup_namespace_uri} = 
  $sp->{lookup_namespace_uri} = sub {
    return $nsmap->{prefix_to_uri}->{$_[0]}; # $_[0] is '' (default) or prefix
  }; # $sp->{lookup_namespace_uri}

  require Message::DOM::CSSStyleSheet;
  require Message::DOM::CSSRule;
  require Message::DOM::CSSStyleDeclaration;

  $self->{base_uri} = $self->{href} unless defined $self->{base_uri};
  $sp->{href} = $self->{href};

  my $state = BEFORE_STATEMENT_STATE;
  my $t = $tt->get_next_token;

  my $open_rules = [[]];
  my $current_rules = $open_rules->[-1];
  my $parent_rules = [];
  my $current_decls;
  my $closing_tokens = [];
  my $charset_allowed = 1;
  my $namespace_allowed = 1;
  my $import_allowed = 1;
  my $media_allowed = 1;

  my $ss = $self->{style_sheet} ||= Message::DOM::CSSStyleSheet->____new
      (css_rules => $open_rules->[0],
       ## TODO: href
       ## TODO: owner_node
       ## TODO: media
       type => 'text/css'); ## TODO: OK?
  $$ss->{manakai_base_uri} = $self->{base_uri};
  $$ss->{_parser} = $self;
  $$ss->{_nsmap} = $nsmap;

  S: {
    if ($state == BEFORE_STATEMENT_STATE) {
      $t = $tt->get_next_token
          while $t->{type} == S_TOKEN or
              $t->{type} == CDO_TOKEN or
              $t->{type} == CDC_TOKEN;

      if ($t->{type} == ATKEYWORD_TOKEN) {
        my $t_at = $t;
        my $at_rule_name = lc $t->{value}; ## TODO: case
        if ($at_rule_name eq 'namespace') { # @namespace
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;

          my $prefix;
          if ($t->{type} == IDENT_TOKEN) {
            $prefix = $t->{value};
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          }

          if ($t->{type} == STRING_TOKEN or $t->{type} == URI_TOKEN) {
            my $uri = $t->{value};
            
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;

            if ($t->{type} == SEMICOLON_TOKEN) {
              if ($namespace_allowed) {
                my $p = $prefix;
                $nsmap->{has_namespace} = 1;
                if (defined $prefix) {
                  if (defined $nsmap->{prefix_to_uri}->{$prefix}) {
                    $onerror->(type => 'duplicate @namespace',
                               value => $prefix,
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $t_at);
                  }
                  $nsmap->{prefix_to_uri}->{$prefix} = $uri;
                  $p .= '|';
                } else {
                  if (defined $nsmap->{prefix_to_uri}->{''}) {
                    $onerror->(type => 'duplicate @namespace',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $t_at);
                  }
                  $nsmap->{prefix_to_uri}->{''} = $uri;
                  $p = '';
                }
                for my $u (keys %{$nsmap->{uri_to_prefixes}}) {
                  next if $u eq $uri;
                  my $list = $nsmap->{uri_to_prefixes}->{$u};
                  next unless $list;
                  for (reverse 0..$#$list) {
                    splice @$list, $_, 1, () if $list->[$_] eq $p;
                  }
                }
                push @{$nsmap->{uri_to_prefixes}->{$uri} ||= []}, $p;
                push @$current_rules,
                    Message::DOM::CSSNamespaceRule->____new ($prefix, $uri);
                undef $charset_allowed;
                undef $import_allowed;
              } else {
                $onerror->(type => 'at-rule not allowed',
                           text => 'namespace',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
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

          $onerror->(type => 'at-rule syntax error',
                     text => 'namespace',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          #
        } elsif ($at_rule_name eq 'import') {
          if ($import_allowed) {
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            my $mq = [];
            if ($t->{type} == STRING_TOKEN or $t->{type} == URI_TOKEN) {
              my $uri = $t->{value};
              $t = $tt->get_next_token;
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;
              if ($t->{type} == IDENT_TOKEN or 
                  $t->{type} == DIMENSION_TOKEN or
                  $t->{type} == NUMBER_TOKEN or
                  $t->{type} == LPAREN_TOKEN) {
                ($t, $mq) = $mp->_parse_mq_with_tokenizer ($t, $tt);
                $t = $tt->get_next_token while $t->{type} == S_TOKEN;
              }
              if ($mq and $t->{type} == SEMICOLON_TOKEN) {
                ## TODO: error or warning
                ## TODO: White space definition
                $uri =~ s/^[\x09\x0A\x0D\x20]+//;
                $uri =~ s/[\x09\x0A\x0D\x20]+\z//;

                my $imported = Message::DOM::CSSStyleSheet->____new
                    (css_rules => [],
                     ## TODO: href
                     parent_style_sheet => $ss,
                     ## TODO: media
                     type => 'text/css', ## TODO: OK?
                     _parser => $self, _nsmap => {});

                my $rule = Message::DOM::CSSImportRule->____new
                    ($uri, \($self->{base_uri}), $mq, $ss);

                $$imported->{owner_rule} = $rule;
                Scalar::Util::weaken ($$imported->{owner_rule});
                Scalar::Util::weaken ($$imported->{parent_style_sheet});

                push @$current_rules, $rule;

                undef $charset_allowed;

                $t = $tt->get_next_token;
                ## Stay in the state.
                redo S;
              }
            }

            $onerror->(type => 'at-rule syntax error',
                       text => 'import',
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t)
                if defined $mq; ## NOTE: Otherwise, already raised in MQ parser
            
            #
          } else {
            $onerror->(type => 'at-rule not allowed',
                       text => 'import',
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            
            #
          }
        } elsif ($at_rule_name eq 'media') {
          if ($media_allowed) {
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            
            my $q;
            ($t, $q) = $mp->_parse_mq_with_tokenizer ($t, $tt);
            if ($q) {
              if ($t->{type} == LBRACE_TOKEN) {
                undef $charset_allowed;
                undef $namespace_allowed;
                undef $import_allowed;
                undef $media_allowed;
                my $rule = Message::DOM::CSSMediaRule->____new
                    ($q, my $v = []);
                push @$current_rules, $rule;
                push @$parent_rules, $rule;
                push @$open_rules, $current_rules = $v;
                $t = $tt->get_next_token;
                ## Stay in the state.
                redo S;
              } else {
                $onerror->(type => 'at-rule syntax error',
                           text => 'media',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
              }

              #
            }
            
            #
          } else { ## Nested @media rule
            $onerror->(type => 'at-rule not allowed',
                       text => 'media',
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            
            #
          }
        } elsif ($at_rule_name eq 'charset') {
          if ($charset_allowed) {
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;

            if ($t->{type} == STRING_TOKEN) {
              my $encoding = $t->{value};
              
              $t = $tt->get_next_token;
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            
              if ($t->{type} == SEMICOLON_TOKEN) {
                push @$current_rules,
                    Message::DOM::CSSCharsetRule->____new ($encoding);
                undef $charset_allowed;

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
            
            $onerror->(type => 'at-rule syntax error',
                       text => 'charset',
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            #
          } else {
            $onerror->(type => 'at-rule not allowed',
                       text => 'charset',
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            #
          }
        } else {
          $onerror->(type => 'unknown at-rule',
                     level => $self->{level}->{uncertain},
                     uri => \$self->{href},
                     token => $t,
                     value => $t->{value});
        }

        ## Reprocess.
        #$t = $tt->get_next_token;
        $state = IGNORED_STATEMENT_STATE;
        redo S;
      } elsif (@$open_rules > 1 and $t->{type} == RBRACE_TOKEN) {
        pop @$open_rules;
        $media_allowed = 1;
        $current_rules = $open_rules->[-1];
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == EOF_TOKEN) {
        if (@$open_rules > 1) {
          $onerror->(type => 'block not closed',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
        }

        last S;
      } else {
        undef $charset_allowed;
        undef $namespace_allowed;
        undef $import_allowed;

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
          $onerror->(type => 'no declaration block',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
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
      my $prop_flag = '';
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ($t->{type} == IDENT_TOKEN) { # property
        my $prop_name = lc $t->{value}; ## TODO: case folding
        my $prop_name_t = $t;
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
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
                  $onerror->(type => 'priority syntax error',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
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
            $onerror->(type => 'unknown property',
                       level => $self->{level}->{uncertain},
                       token => $prop_name_t, value => $prop_name,
                       uri => \$self->{href});

            #
            $state = IGNORED_DECLARATION_STATE;
            redo S;
          }
        } else {
          $onerror->(type => 'no property colon',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
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
        $onerror->(type => 'block not closed',
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        ## Reprocess.
        $state = BEFORE_STATEMENT_STATE;
        #redo S;
      } else {
        if ($prop_value) {
          $onerror->(type => 'no property semicolon',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
        } else {
          $onerror->(type => 'no property name',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
        }

        #
        $state = IGNORED_DECLARATION_STATE;
        redo S;
      }

      my $important = ($prop_flag eq 'important');
      for my $set_prop_name (keys %{$prop_value or {}}) {
        my $set_prop_def = $Prop->{$set_prop_name};
        $$current_decls->{$set_prop_def->{key}}
            = [$prop_value->{$set_prop_name}, $prop_flag]
            if $important or
                not $$current_decls->{$set_prop_def->{key}} or
                $$current_decls->{$set_prop_def->{key}}->[1] ne 'important';
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
        } elsif ({
          RBRACE_TOKEN, 1,
          #RBRACKET_TOKEN, 1,
          #RPAREN_TOKEN, 1,
          SEMICOLON_TOKEN, 1,
        }->{$t->{type}}) {
          $t = $tt->get_next_token;
          ## Stay in the state.
          #
        } else {
          #
        }
      } else {
        if ($t->{type} == SEMICOLON_TOKEN) {
          $t = $tt->get_next_token;
          $state = $state == IGNORED_STATEMENT_STATE
              ? BEFORE_STATEMENT_STATE : BEFORE_DECLARATION_STATE;
          redo S;
        } elsif ($t->{type} == RBRACE_TOKEN) {
          if ($state == IGNORED_DECLARATION_STATE) {
            $t = $tt->get_next_token;
            $state = BEFORE_STATEMENT_STATE;
            redo S;
          } else {
            ## NOTE: Maybe this state cannot be reached.
            $t = $tt->get_next_token;
            ## Stay in the state.
            redo S;
          }
        } elsif ($t->{type} == EOF_TOKEN) {
          ## Reprocess.
          $state = $state == IGNORED_STATEMENT_STATE
              ? BEFORE_STATEMENT_STATE : BEFORE_DECLARATION_STATE;
          redo S;
        #} elsif ($t->{type} == RBRACKET_TOKEN or $t->{type} == RPAREN_TOKEN) {
        #  $t = $tt->get_next_token;
        #  ## Stay in the state.
        #  #
        } else {
          #
        }
      }

      while (not {
        EOF_TOKEN, 1,
        RBRACE_TOKEN, 1,
        ## NOTE: ']' and ')' are disabled for browser compatibility.
        #RBRACKET_TOKEN, 1,
        #RPAREN_TOKEN, 1,
        SEMICOLON_TOKEN, 1,
      }->{$t->{type}}) {
        if ($t->{type} == LBRACE_TOKEN) {
          push @$closing_tokens, RBRACE_TOKEN;
        #} elsif ($t->{type} == LBRACKET_TOKEN) {
        #  push @$closing_tokens, RBRACKET_TOKEN;
        #} elsif ($t->{type} == LPAREN_TOKEN or $t->{type} == FUNCTION_TOKEN) {
        #  push @$closing_tokens, RPAREN_TOKEN;
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

  for (@{$$ss->{css_rules}}) {
    $$_->{parent_style_sheet} = $ss;
    Scalar::Util::weaken ($$_->{parent_style_sheet});
  }
  for my $parent_rule (@$parent_rules) {
    for (@{$$parent_rule->{css_rules}}) {
      $$_->{parent_rule} = $parent_rule;
      Scalar::Util::weaken ($$_->{parent_rule});
    }
  }

  return $ss;
} # parse_char_string

## TODO: Test <style>'s base URI change and url()

sub parse_char_string_as_inline ($$) {
  my $self = $_[0];

  my $s = $_[1];
  pos ($s) = 0;
  my $line = 1;
  my $column = 0;
  
  my $tt = Whatpm::CSS::Tokenizer->new;
  my $onerror = $tt->{onerror} = $self->{onerror};
  $tt->{get_char} = sub ($) {
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
      $_[0]->{line} = $line;
      $_[0]->{column} = $column;
      return $c;
    } else {
      $_[0]->{column} = $column + 1; ## Set the same number always.
      return -1;
    }
  }; # $tt->{get_char}
  $tt->init;

  $self->{lookup_namespace_uri} = sub { ## TODO: case
    return undef; ## TODO: get from an external source
  }; # $sp->{lookup_namespace_uri}

  require Message::DOM::CSSStyleDeclaration;

  $self->{base_uri} = $self->{href} unless defined $self->{base_uri};

  my $state = BEFORE_DECLARATION_STATE;
  my $t = $tt->get_next_token;

  my $current_decls = Message::DOM::CSSStyleDeclaration->____new;
  my $closing_tokens = [];

## TODO: ...
#  $$ss->{manakai_base_uri} = $self->{base_uri};
#  $$ss->{_parser} = $self;
#  $$ss->{_nsmap} = $nsmap;

  S: {
    if ($state == BEFORE_DECLARATION_STATE) {
      ## NOTE: DELIM? in declaration will be removed:
      ## <http://csswg.inkedblade.net/spec/css2.1?s=declaration%20delim#issue-2>.

      my $prop_def;
      my $prop_value;
      my $prop_flag = '';
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ($t->{type} == IDENT_TOKEN) { # property
        my $prop_name = lc $t->{value}; ## TODO: case folding
        my $prop_name_t = $t;
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
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
                  $onerror->(type => 'priority syntax error',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
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
            $onerror->(type => 'unknown property',
                       level => $self->{level}->{uncertain},
                       token => $prop_name_t, value => $prop_name,
                       uri => \$self->{href});

            #
            $state = IGNORED_DECLARATION_STATE;
            redo S;
          }
        } else {
          $onerror->(type => 'no property colon',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);

          #
          $state = IGNORED_DECLARATION_STATE;
          redo S;
        }
      }

      ## NOTE: Unlike the main parser, |RBRACE_TOKEN| does not close
      ## the block here.
      if ($t->{type} == SEMICOLON_TOKEN) {
        $t = $tt->get_next_token;
        ## Stay in the state.
        #redo S;
      } elsif ($t->{type} == EOF_TOKEN) {
        ## NOTE: Unlike the main parser, no error is raised here and
        ## exits the parser.
        #last S;
      } else {
        if ($prop_value) {
          $onerror->(type => 'no property semicolon',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
        } else {
          $onerror->(type => 'no property name',
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
        }

        ## Reprocess.
        $state = IGNORED_DECLARATION_STATE;
        redo S;
      }

      my $important = ($prop_flag eq 'important');
      for my $set_prop_name (keys %{$prop_value or {}}) {
        my $set_prop_def = $Prop->{$set_prop_name};
        $$current_decls->{$set_prop_def->{key}}
            = [$prop_value->{$set_prop_name}, $prop_flag]
            if $important or
                not $$current_decls->{$set_prop_def->{key}} or
                $$current_decls->{$set_prop_def->{key}}->[1] ne 'important';
      }
      last S if $t->{type} == EOF_TOKEN; # "color: red{EOF}" (w/ or w/o ";")
      redo S;
    } elsif ($state == IGNORED_DECLARATION_STATE) {
      ## NOTE: Difference from the main parser is that support for the
      ## |IGNORED_STATEMENT_STATE| cases is removed.
      if (@$closing_tokens) { ## Something is yet in opening state.
        if ($t->{type} == EOF_TOKEN) {
          @$closing_tokens = ();
          ## Reprocess.
          $state = BEFORE_DECLARATION_STATE;
          redo S;
        } elsif ($t->{type} == $closing_tokens->[-1]) {
          pop @$closing_tokens;
          $t = $tt->get_next_token;
          ## Stay in the state.
          redo S;
        } elsif ({
          RBRACE_TOKEN, 1,
          #RBRACKET_TOKEN, 1,
          #RPAREN_TOKEN, 1,
          SEMICOLON_TOKEN, 1,
        }->{$t->{type}}) {
          $t = $tt->get_next_token;
          ## Stay in the state.
          #
        } else {
          #
        }
      } else {
        ## NOTE: Unlike the main parser, |RBRACE_TOKEN| does not close
        ## the block here.
        if ($t->{type} == SEMICOLON_TOKEN) {
          $t = $tt->get_next_token;
          $state = BEFORE_DECLARATION_STATE;
          redo S;
        } elsif ($t->{type} == EOF_TOKEN) {
          ## Reprocess.
          $state = $state == IGNORED_STATEMENT_STATE
              ? BEFORE_STATEMENT_STATE : BEFORE_DECLARATION_STATE;
          redo S;
        #} elsif ($t->{type} == RBRACKET_TOKEN or $t->{type} == RPAREN_TOKEN) {
        #  $t = $tt->get_next_token;
        #  ## Stay in the state.
        #  #
        } else {
          #
        }
      }

      while (not {
        EOF_TOKEN, 1,
        #RBRACE_TOKEN, 1, ## NOTE: Difference from the main parser.
        ## NOTE: ']' and ')' are disabled for browser compatibility.
        #RBRACKET_TOKEN, 1,
        #RPAREN_TOKEN, 1,
        SEMICOLON_TOKEN, 1,
      }->{$t->{type}}) {
        if ($t->{type} == LBRACE_TOKEN) {
          push @$closing_tokens, RBRACE_TOKEN;
        #} elsif ($t->{type} == LBRACKET_TOKEN) {
        #  push @$closing_tokens, RBRACKET_TOKEN;
        #} elsif ($t->{type} == LPAREN_TOKEN or $t->{type} == FUNCTION_TOKEN) {
        #  push @$closing_tokens, RPAREN_TOKEN;
        }

        $t = $tt->get_next_token;
      }

      ## Reprocess.
      ## Stay in the state.
      redo S;
    } else {
      die "$0: parse_char_string: Unknown state: $state";
    }
  } # S

  ## TODO: CSSStyleDeclaration attributes ...

  return $current_decls;
} # parse_char_string_as_inline

## TODO: We need test script for the method above.

my $compute_as_specified = sub ($$$$) {
  #my ($self, $element, $prop_name, $specified_value) = @_;
  return $_[3];
}; # $compute_as_specified

require Whatpm::CSS::Colors;
my $x11_colors = $Whatpm::CSS::Colors::X11Colors;
my $system_colors = $Whatpm::CSS::Colors::SystemColors;

my $parse_color = sub {
  my ($self, $prop_name, $tt, $t, $onerror) = @_;

  ## See
  ## <https://suika.suikawiki.org/gate/2005/sw/%3Ccolor%3E>,
  ## <https://suika.suikawiki.org/gate/2005/sw/rgb>,
  ## <https://suika.suikawiki.org/gate/2005/sw/-moz-rgba>,
  ## <https://suika.suikawiki.org/gate/2005/sw/hsl>,
  ## <https://suika.suikawiki.org/gate/2005/sw/-moz-hsla>, and
  ## <https://suika.suikawiki.org/gate/2005/sw/color>
  ## for browser compatibility issue.

  ## NOTE: Implementing CSS3 Color CR (2003), except for attr(),
  ## rgba(), and hsla().
  ## NOTE: rgb(...{EOF} is not supported (only Opera does).

  if ($t->{type} == IDENT_TOKEN) {
    my $value = lc $t->{value}; ## TODO: case
    if ($x11_colors->{$value} or
        $system_colors->{$value}) {
      ## NOTE: "For systems that do not have a corresponding value, the
      ## specified value should be mapped to the nearest system value, or to
      ## a default color." [CSS 2.1].
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['KEYWORD', $value]});
    } elsif ({
      transparent => 1, ## For 'background-color' in CSS2.1, everywhre in CSS3.
      flavor => 1, ## CSS3.
      invert => 1, ## For 'outline-color' in CSS2.1.
      '-moz-use-text-color' => 1, ## For <border-color> in Gecko.
      '-manakai-default' => 1, ## CSS2.1 initial for 'color'
      '-manakai-invert-or-currentcolor' => 1, ## CSS2.1 initial4'outline-color'
    }->{$value} and $self->{prop_value}->{$prop_name}->{$value}) {
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['KEYWORD', $value]});
    } elsif ($value eq 'currentcolor' or $value eq '-moz-use-text-color') {
      ## NOTE: '-manakai-invert-or-currentcolor' is not allowed in 'color'.
      $t = $tt->get_next_token;
      if ($prop_name eq 'color') {
        return ($t, {$prop_name => ['INHERIT']});
      } else {
        return ($t, {$prop_name => ['KEYWORD', $value]});
      }
    } elsif ($value eq 'inherit') {
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['INHERIT']});
    }
  }

  if ($t->{type} == HASH_TOKEN or
      ($self->{hashless_rgb} and {
        IDENT_TOKEN, 1,
        NUMBER_TOKEN, 1,
        DIMENSION_TOKEN, 1,
      }->{$t->{type}})) {
    my $v = lc (defined $t->{number} ? $t->{number} : '' . $t->{value}); ## TODO: case
    if ($v =~ /\A([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\z/) {
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['RGBA', hex $1, hex $2, hex $3, 1]});
    } elsif ($v =~ /\A([0-9a-f])([0-9a-f])([0-9a-f])\z/) {
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['RGBA', hex $1.$1, hex $2.$2,
                                  hex $3.$3, 1]});
    }
  }

  if ($t->{type} == FUNCTION_TOKEN) {
    my $func = lc $t->{value}; ## TODO: case
    if ($func eq 'rgb') {
      $t = $tt->get_next_token;
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      my $sign = 1;
      if ($t->{type} == MINUS_TOKEN) {
        $sign = -1;
        $t = $tt->get_next_token;
      } elsif ($t->{type} == PLUS_TOKEN) {
        $t = $tt->get_next_token;
      }
      if ($t->{type} == NUMBER_TOKEN) {
        my $r = $t->{number} * $sign;
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == COMMA_TOKEN) {
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          $sign = 1;
          if ($t->{type} == MINUS_TOKEN) {
            $sign = -1;
            $t = $tt->get_next_token;
          } elsif ($t->{type} == PLUS_TOKEN) {
            $t = $tt->get_next_token;
          }
          if ($t->{type} == NUMBER_TOKEN) {
            my $g = $t->{number} * $sign;
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == COMMA_TOKEN) {
              $t = $tt->get_next_token;
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;
              $sign = 1;
              if ($t->{type} == MINUS_TOKEN) {
                $sign = -1;
                $t = $tt->get_next_token;
              } elsif ($t->{type} == PLUS_TOKEN) {
                $t = $tt->get_next_token;
              }
              if ($t->{type} == NUMBER_TOKEN) {
                my $b = $t->{number} * $sign;
                $t = $tt->get_next_token;
                $t = $tt->get_next_token while $t->{type} == S_TOKEN;
                if ($t->{type} == RPAREN_TOKEN) {
                  $t = $tt->get_next_token;
                  return ($t,
                          {$prop_name =>
                           $self->{clip_color}->($self,
                                                 ['RGBA', $r, $g, $b, 1])});
                }
              }
            }
          }
        }
      } elsif ($t->{type} == PERCENTAGE_TOKEN) {
        my $r = $t->{number} * 255 / 100 * $sign;
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == COMMA_TOKEN) {
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          $sign = 1;
          if ($t->{type} == MINUS_TOKEN) {
            $sign = -1;
            $t = $tt->get_next_token;
          } elsif ($t->{type} == PLUS_TOKEN) {
            $t = $tt->get_next_token;
          }
          if ($t->{type} == PERCENTAGE_TOKEN) {
            my $g = $t->{number} * 255 / 100 * $sign;
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == COMMA_TOKEN) {
              $t = $tt->get_next_token;
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;
              $sign = 1;
              if ($t->{type} == MINUS_TOKEN) {
                $sign = -1;
                $t = $tt->get_next_token;
              } elsif ($t->{type} == PLUS_TOKEN) {
                $t = $tt->get_next_token;
              }
              if ($t->{type} == PERCENTAGE_TOKEN) {
                my $b = $t->{number} * 255 / 100 * $sign;
                $t = $tt->get_next_token;
                $t = $tt->get_next_token while $t->{type} == S_TOKEN;
                if ($t->{type} == RPAREN_TOKEN) {
                  $t = $tt->get_next_token;
                  return ($t,
                          {$prop_name =>
                           $self->{clip_color}->($self,
                                                 ['RGBA', $r, $g, $b, 1])});
                }
              }
            }
          }
        }
      }
    } elsif ($func eq 'hsl') {
      $t = $tt->get_next_token;
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      my $sign = 1;
      if ($t->{type} == MINUS_TOKEN) {
        $sign = -1;
        $t = $tt->get_next_token;
      } elsif ($t->{type} == PLUS_TOKEN) {
        $t = $tt->get_next_token;
      }
      if ($t->{type} == NUMBER_TOKEN) {
        my $h = (((($t->{number} * $sign) % 360) + 360) % 360) / 360;
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == COMMA_TOKEN) {
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          $sign = 1;
          if ($t->{type} == MINUS_TOKEN) {
            $sign = -1;
            $t = $tt->get_next_token;
          } elsif ($t->{type} == PLUS_TOKEN) {
            $t = $tt->get_next_token;
          }
          if ($t->{type} == PERCENTAGE_TOKEN) {
            my $s = $t->{number} * $sign / 100;
            $s = 0 if $s < 0;
            $s = 1 if $s > 1;
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == COMMA_TOKEN) {
              $t = $tt->get_next_token;
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;
              $sign = 1;
              if ($t->{type} == MINUS_TOKEN) {
                $sign = -1;
                $t = $tt->get_next_token;
              } elsif ($t->{type} == PLUS_TOKEN) {
                $t = $tt->get_next_token;
              }
              if ($t->{type} == PERCENTAGE_TOKEN) {
                my $l = $t->{number} * $sign / 100;
                $l = 0 if $l < 0;
                $l = 1 if $l > 1;
                $t = $tt->get_next_token;
                $t = $tt->get_next_token while $t->{type} == S_TOKEN;
                if ($t->{type} == RPAREN_TOKEN) {
                  my $m2 = $l <= 0.5 ? $l * ($s + 1) : $l + $s - $l * $s;
                  my $m1 = $l * 2 - $m2;
                  my $hue2rgb = sub ($$$) {
                    my ($m1, $m2, $h) = @_;
                    $h++ if $h < 0;
                    $h-- if $h > 1;
                    return $m1 + ($m2 - $m1) * $h * 6 if $h * 6 < 1;
                    return $m2 if $h * 2 < 1;
                    return $m1 + ($m2 - $m1) * (2/3 - $h) * 6 if $h * 3 < 2;
                    return $m1;
                  };
                  $t = $tt->get_next_token;
                  return ($t,
                          {$prop_name =>
                           $self->{clip_color}
                               ->($self,
                                  ['RGBA',
                                   $hue2rgb->($m1, $m2, $h + 1/3) * 255,
                                   $hue2rgb->($m1, $m2, $h) * 255,
                                   $hue2rgb->($m1, $m2, $h - 1/3) * 255, 1])});
                }
              }
            }
          }
        }
      }
    }
  }
  
  $onerror->(type => 'CSS syntax error', text => 'color',
             level => $self->{level}->{must},
             uri => \$self->{href},
             token => $t);
  
  return ($t, undef);
}; # $parse_color

$Prop->{color} = {
  css => 'color',
  dom => 'color',
  key => 'color',
  parse => $parse_color,
  initial => ['KEYWORD', '-manakai-default'],
  inherited => 1,
  compute => sub ($$$$) {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value) {
      if ($specified_value->[0] eq 'KEYWORD') {
        if ($x11_colors->{$specified_value->[1]}) {
          return ['RGBA', @{$x11_colors->{$specified_value->[1]}}, 1];
        } elsif ($specified_value->[1] eq 'transparent') {
          return ['RGBA', 0, 0, 0, 0];
        } elsif ($specified_value->[1] eq 'currentcolor' or
                 $specified_value->[1] eq '-moz-use-text-color' or
                 ($specified_value->[1] eq '-manakai-invert-or-currentcolor'and
                  not $self->{has_invert})) {
          unless ($prop_name eq 'color') {
            return $self->get_computed_value ($element, 'color');
          } else {
            ## NOTE: This is an error, since it should have been
            ## converted to 'inherit' at parse time.
            ## NOTE: 'color: -manakai-invert-or-currentcolor' is not allowed.
            return ['KEYWORD', '-manakai-default'];
          }
        } elsif ($specified_value->[1] eq '-manakai-invert-or-currentcolor') {
          return ['KEYWORD', 'invert'];
        }
      }
    }
    
    return $specified_value;
  },
};
$Attr->{color} = $Prop->{color};
$Key->{color} = $Prop->{color};

$Prop->{'background-color'} = {
  css => 'background-color',
  dom => 'background_color',
  key => 'background_color',
  parse => $parse_color,
  serialize_multiple => sub {
    my $self = shift;

    my $r = {};
    my $has_all;
    
    my $x = $self->background_position_x;
    my $y = $self->background_position_y;
    my $xi = $self->get_property_priority ('background-position-x');
    my $yi = $self->get_property_priority ('background-position-y');
    if (length $x) {
      if (length $y) {
        if ($xi eq $yi) {
          if ($x eq 'inherit') {
            if ($y eq 'inherit') {
              $r->{'background-position'} = ['inherit', $xi];
              $has_all = 1;
            } else {
              $r->{'background-position-x'} = [$x, $xi];
              $r->{'background-position-y'} = [$y, $yi];
            }
          } elsif ($y eq 'inherit') {
            $r->{'background-position-x'} = [$x, $xi];
            $r->{'background-position-y'} = [$y, $yi];
          } else {
            $r->{'background-position'} = [$x . ' ' . $y, $xi];
            $has_all = 1;
          }
        } else {
          $r->{'background-position-x'} = [$x, $xi];
          $r->{'background-position-y'} = [$y, $yi];
        }
      } else {
        $r->{'background-position-x'} = [$x, $xi];
      }
    } else {
      if (length $y) {
        $r->{'background-position-y'} = [$y, $yi];
      } else {
        #
      }
    }
    
    for my $prop (qw/color image repeat attachment/) {
      my $prop_name = 'background_'.$prop;
      my $value = $self->$prop_name;
      if (length $value) {
        my $i = $self->get_property_priority ('background-'.$prop);
        undef $has_all unless $xi eq $i;
        $r->{'background-'.$prop} = [$value, $i];
      } else {
        undef $has_all;
      }
    }

    if ($has_all) {
      my @v;
      push @v, $r->{'background-color'}
          unless $r->{'background-color'}->[0] eq 'transparent';
      push @v, $r->{'background-image'}
          unless $r->{'background-image'}->[0] eq 'none';
      push @v, $r->{'background-repeat'}
          unless $r->{'background-repeat'}->[0] eq 'repeat';
      push @v, $r->{'background-attachment'}
          unless $r->{'background-attachment'}->[0] eq 'scroll';
      push @v, $r->{'background-position'}
          unless $r->{'background-position'}->[0] eq '0% 0%';
      if (@v) {
        my $inherit = 0;
        for (@v) {
          $inherit++ if $_->[0] eq 'inherit';
        }
        if ($inherit == 5) {
          return {background => ['inherit', $xi]};
        } elsif ($inherit) {
          return $r;
        } else {
          return {background => [(join ' ', map {$_->[0]} @v), $xi]};
        }
      } else {
        return {background => ['transparent none repeat scroll 0% 0%', $xi]};
      }
    } else {
      return $r;
    }
  },
  initial => ['KEYWORD', 'transparent'],
  #inherited => 0,
  compute => $Prop->{color}->{compute},
};
$Attr->{background_color} = $Prop->{'background-color'};
$Key->{background_color} = $Prop->{'background-color'};

$Prop->{'border-top-color'} = {
  css => 'border-top-color',
  dom => 'border_top_color',
  key => 'border_top_color',
  parse => $parse_color,
  serialize_multiple => sub {
    my $self = shift;
    ## NOTE: This algorithm returns the same result as that of Firefox 2
    ## in many case, but not always.
    my $r = {
      'border-top-color' => [$self->border_top_color,
                             $self->get_property_priority
                                 ('border-top-color')],
      'border-top-style' => [$self->border_top_style,
                             $self->get_property_priority
                                 ('border-top-style')],
      'border-top-width' => [$self->border_top_width,
                             $self->get_property_priority
                                 ('border-top-width')],
      'border-right-color' => [$self->border_right_color,
                               $self->get_property_priority
                                   ('border-right-color')],
      'border-right-style' => [$self->border_right_style,
                               $self->get_property_priority
                                   ('border-right-style')],
      'border-right-width' => [$self->border_right_width,
                               $self->get_property_priority
                                   ('border-right-width')],
      'border-bottom-color' => [$self->border_bottom_color,
                                $self->get_property_priority
                                    ('border-bottom-color')],
      'border-bottom-style' => [$self->border_bottom_style,
                                $self->get_property_priority
                                    ('border-bottom-style')],
      'border-bottom-width' => [$self->border_bottom_width,
                                $self->get_property_priority
                                    ('border-bottom-width')],
      'border-left-color' => [$self->border_left_color,
                              $self->get_property_priority
                                  ('border-leftcolor')],
      'border-left-style' => [$self->border_left_style,
                              $self->get_property_priority
                                  ('border-left-style')],
      'border-left-width' => [$self->border_left_width,
                              $self->get_property_priority
                                  ('border-left-width')],
    };
    my $i = 0;
    for my $prop (qw/border-top border-right border-bottom border-left/) {
      if (length $r->{$prop.'-color'}->[0] and
          length $r->{$prop.'-style'}->[0] and
          length $r->{$prop.'-width'}->[0] and
          $r->{$prop.'-color'}->[1] eq $r->{$prop.'-style'}->[1] and
          $r->{$prop.'-color'}->[1] eq $r->{$prop.'-width'}->[1]) {
        my $inherit = 0;
        $inherit++ if $r->{$prop.'-color'}->[0] eq 'inherit';
        $inherit++ if $r->{$prop.'-style'}->[0] eq 'inherit';
        $inherit++ if $r->{$prop.'-width'}->[0] eq 'inherit';
        if ($inherit == 3) {
          $r->{$prop} = $r->{$prop.'-color'};
        } elsif ($inherit) {
          next;
        } else {
          $r->{$prop} = [$r->{$prop.'-width'}->[0] . ' ' .
                             $r->{$prop.'-style'}->[0] . ' ' .
                             $r->{$prop.'-color'}->[0],
                         $r->{$prop.'-color'}->[1]];
        }
        delete $r->{$prop.'-width'};
        delete $r->{$prop.'-style'};
        delete $r->{$prop.'-color'};
        $i++;
      }
    }
    if ($i == 4 and
        $r->{'border-top'}->[0] eq $r->{'border-right'}->[0] and
        $r->{'border-right'}->[0] eq $r->{'border-bottom'}->[0] and
        $r->{'border-bottom'}->[0] eq $r->{'border-left'}->[0] and
        $r->{'border-top'}->[1] eq $r->{'border-right'}->[1] and
        $r->{'border-right'}->[1] eq $r->{'border-bottom'}->[1] and
        $r->{'border-bottom'}->[1] eq $r->{'border-left'}->[1]) {
      return {border => $r->{'border-top'}};
    }

    unless ($i) {
      for my $prop (qw/color style width/) {
        if (defined $r->{'border-top-'.$prop} and
            defined $r->{'border-bottom-'.$prop} and
            defined $r->{'border-right-'.$prop} and
            defined $r->{'border-left-'.$prop} and
            length $r->{'border-top-'.$prop}->[0] and
            length $r->{'border-bottom-'.$prop}->[0] and
            length $r->{'border-right-'.$prop}->[0] and
            length $r->{'border-left-'.$prop}->[0] and
            $r->{'border-top-'.$prop}->[1]
                eq $r->{'border-bottom-'.$prop}->[1] and
            $r->{'border-top-'.$prop}->[1]
                eq $r->{'border-right-'.$prop}->[1] and
            $r->{'border-top-'.$prop}->[1]
                eq $r->{'border-left-'.$prop}->[1]) {
          my @v = ($r->{'border-top-'.$prop},
                   $r->{'border-right-'.$prop},
                   $r->{'border-bottom-'.$prop},
                   $r->{'border-left-'.$prop});
          my $inherit = 0;
          for (@v) {
            $inherit++ if $_->[0] eq 'inherit';
          }
          if ($inherit == 4) {
            $r->{'border-'.$prop}
                = ['inherit', $r->{'border-top-'.$prop}->[1]];
          } elsif ($inherit) {
            next;
          } else {
            pop @v
                if $r->{'border-right-'.$prop}->[0]
                    eq $r->{'border-left-'.$prop}->[0];
            pop @v
                if $r->{'border-bottom-'.$prop}->[0]
                    eq $r->{'border-top-'.$prop}->[0];
            pop @v
                if $r->{'border-right-'.$prop}->[0]
                    eq $r->{'border-top-'.$prop}->[0];
            $r->{'border-'.$prop} = [(join ' ', map {$_->[0]} @v),
                                     $r->{'border-top-'.$prop}->[1]];
          }
          delete $r->{'border-top-'.$prop};
          delete $r->{'border-bottom-'.$prop};
          delete $r->{'border-right-'.$prop};
          delete $r->{'border-left-'.$prop};
        }
      }
    }

    delete $r->{$_} for grep {not length $r->{$_}->[0]} keys %$r;
    return $r;
  },
  initial => ['KEYWORD', 'currentcolor'],
  #inherited => 0,
  compute => $Prop->{color}->{compute},
};
$Attr->{border_top_color} = $Prop->{'border-top-color'};
$Key->{border_top_color} = $Prop->{'border-top-color'};

$Prop->{'border-right-color'} = {
  css => 'border-right-color',
  dom => 'border_right_color',
  key => 'border_right_color',
  parse => $parse_color,
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'currentcolor'],
  #inherited => 0,
  compute => $Prop->{color}->{compute},
};
$Attr->{border_right_color} = $Prop->{'border-right-color'};
$Key->{border_right_color} = $Prop->{'border-right-color'};

$Prop->{'border-bottom-color'} = {
  css => 'border-bottom-color',
  dom => 'border_bottom_color',
  key => 'border_bottom_color',
  parse => $parse_color,
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'currentcolor'],
  #inherited => 0,
  compute => $Prop->{color}->{compute},
};
$Attr->{border_bottom_color} = $Prop->{'border-bottom-color'};
$Key->{border_bottom_color} = $Prop->{'border-bottom-color'};

$Prop->{'border-left-color'} = {
  css => 'border-left-color',
  dom => 'border_left_color',
  key => 'border_left_color',
  parse => $parse_color,
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'currentcolor'],
  #inherited => 0,
  compute => $Prop->{color}->{compute},
};
$Attr->{border_left_color} = $Prop->{'border-left-color'};
$Key->{border_left_color} = $Prop->{'border-left-color'};

$Prop->{'outline-color'} = {
  css => 'outline-color',
  dom => 'outline_color',
  key => 'outline_color',
  parse => $parse_color,
  serialize_multiple => sub {
    my $self = shift;
    my $oc = $self->outline_color;
    my $os = $self->outline_style;
    my $ow = $self->outline_width;
    my $r = {};
    if (length $oc and length $os and length $ow) {
      $r->{outline} = [$ow . ' ' . $os . ' ' . $oc];
    } else {
      $r->{'outline-color'} = [$oc] if length $oc;
      $r->{'outline-style'} = [$os] if length $os;
      $r->{'outline-width'} = [$ow] if length $ow;
    }
    return $r;
  },
  initial => ['KEYWORD', '-manakai-invert-or-currentcolor'],
  #inherited => 0,
  compute => $Prop->{color}->{compute},
};
$Attr->{outline_color} = $Prop->{'outline-color'};
$Key->{outline_color} = $Prop->{'outline-color'};

my $one_keyword_parser = sub {
  my ($self, $prop_name, $tt, $t, $onerror) = @_;

  if ($t->{type} == IDENT_TOKEN) {
    my $prop_value = lc $t->{value}; ## TODO: case folding
    if ($Prop->{$prop_name}->{keyword}->{$prop_value} and
        $self->{prop_value}->{$prop_name}->{$prop_value}) {
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["KEYWORD", $prop_value]});
    } elsif (my $v = $Prop->{$prop_name}->{keyword_replace}->{$prop_value}) {
      if ($self->{prop_value}->{$prop_name}->{$v}) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ["KEYWORD", $v]});
      }
    } elsif ($prop_value eq 'inherit') {
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ['INHERIT']});
    }
  }
  
  $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
             level => $self->{level}->{must},
             uri => \$self->{href},
             token => $t);
  return ($t, undef);
};

$Prop->{display} = {
  css => 'display',
  dom => 'display',
  key => 'display',
  parse => $one_keyword_parser,
  keyword => {
    ## CSS 2.1
    block => 1, inline => 1, 'inline-block' => 1, 'inline-table' => 1,
    'list-item' => 1, none => 1,
    table => 1, 'table-caption' => 1, 'table-cell' => 1, 'table-column' => 1,
    'table-column-group' => 1, 'table-header-group' => 1,
    'table-footer-group' => 1, 'table-row' => 1, 'table-row-group' => 1,
    ## CSS 2.0
    compact => 1, marker => 1,
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
          } elsif ($specified_value->[1] eq 'marker') {
            ## TODO: If ::after or ::before, then 'marker'.  Otherwise,
            return ['KEYWORD', 'inline'];
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

                 ## NOTE: Not in CSS 2.1, but maybe...
                 compact => 'block',
                 marker => 'block',
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
  keyword => {
    normal => 1, embed => 1, 'bidi-override' => 1,
  },
  initial => ["KEYWORD", "normal"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{unicode_bidi} = $Prop->{'unicode-bidi'};
$Key->{unicode_bidi} = $Prop->{'unicode-bidi'};

$Prop->{'overflow-x'} = {
  css => 'overflow-x',
  dom => 'overflow_x',
  key => 'overflow_x',
  parse => $one_keyword_parser,
  serialize_multiple => sub {
    my $self = shift;
    
    my $x = $self->overflow_x;
    my $xi = $self->get_property_priority ('overflow-x');
    my $y = $self->overflow_y;
    my $yi = $self->get_property_priority ('overflow-y');

    if (length $x) {
      if (length $y) {
        if ($x eq $y and $xi eq $yi) {
          return {overflow => [$x, $xi]};
        } else {
          return {'overflow-x' => [$x, $xi], 'overflow-y' => [$y, $yi]};
        }
      } else {
        return {'overflow-x' => [$x, $xi]};
      }
    } else {
      if (length $y) {
        return {'overflow-y' => [$y, $yi]};
      } else {
        return {};
      }
    }
  },
  keyword => {
    visible => 1, hidden => 1, scroll => 1, auto => 1,
    '-moz-hidden-unscrollable' => 1, '-webkit-marquee' => 1,
  },
  initial => ["KEYWORD", "visible"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{overflow_x} = $Prop->{'overflow-x'};
$Key->{overflow_x} = $Prop->{'overflow-x'};

$Prop->{'overflow-y'} = {
  css => 'overflow-y',
  dom => 'overflow_y',
  key => 'overflow_y',
  parse => $one_keyword_parser,
  serialize_multiple => $Prop->{'overflow-x'}->{serialize_multiple},
  keyword => $Prop->{'overflow-x'}->{keyword},
  initial => ["KEYWORD", "visible"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{overflow_y} = $Prop->{'overflow-y'};
$Key->{overflow_y} = $Prop->{'overflow-y'};

$Prop->{overflow} = {
  css => 'overflow',
  dom => 'overflow',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;
    my ($t2, $pv) = $one_keyword_parser->($self, $prop_name, $tt, $t, $onerror);
    if (defined $pv) {
      return ($t2, {'overflow-x' => $pv->{overflow},
                   'overflow-y' => $pv->{overflow}});
    } else {
      return ($t2, $pv);
    }
  }, # parse
  keyword => $Prop->{'overflow-x'}->{keyword},
  serialize_multiple => $Prop->{'overflow-x'}->{serialize_multiple},
};
$Attr->{overflow} = $Prop->{overflow};

$Prop->{visibility} = {
  css => 'visibility',
  dom => 'visibility',
  key => 'visibility',
  parse => $one_keyword_parser,
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
  keyword => {
    ## CSS 2.1
    qw/
      disc 1 circle 1 square 1 decimal 1 decimal-leading-zero 1 
      lower-roman 1 upper-roman 1 lower-greek 1 lower-latin 1
      upper-latin 1 armenian 1 georgian 1 lower-alpha 1 upper-alpha 1
      none 1
    /,
    ## CSS 2.0
    hebrew => 1, 'cjk-ideographic' => 1, hiragana => 1, katakana => 1,
    'hiragana-iroha' => 1, 'katakana-iroha' => 1,
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
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
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
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
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
  keyword => {
    normal => 1, pre => 1, nowrap => 1, 'pre-wrap' => 1, 'pre-line' => 1,
  },
  keyword_replace => {
    '-moz-pre-wrap' => 'pre-wrap', '-o-pre-wrap' => 'pre-wrap',
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
  keyword => {
    ## CSS 2.1
    top => 1, bottom => 1,
    ## CSS 2
    left => 1, right => 1,
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

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $sign = -1;
      $has_sign = 1;
      $t = $tt->get_next_token;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $has_sign = 1;
      $t = $tt->get_next_token;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <https://suika.suikawiki.org/gate/2005/sw/z-index> for
      ## browser compatibility issue.
      my $value = $t->{number};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["NUMBER", $sign * int ($value / 1)]});
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'auto') {
        ## NOTE: |z-index| is the default value and therefore it must be
        ## supported anyway.
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ["KEYWORD", 'auto']});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{z_index} = $Prop->{'z-index'};
$Key->{z_index} = $Prop->{'z-index'};

$Prop->{'font-size-adjust'} = {
  css => 'font-size-adjust',
  dom => 'font_size_adjust',
  key => 'font_size_adjust',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $sign = -1;
      $has_sign = 1;
      $t = $tt->get_next_token;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $has_sign = 1;
      $t = $tt->get_next_token;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      my $value = $t->{number};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["NUMBER", $sign * $value]});
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'none') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ["KEYWORD", $value]});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'none'],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{font_size_adjust} = $Prop->{'font-size-adjust'};
$Key->{font_size_adjust} = $Prop->{'font-size-adjust'};

$Prop->{orphans} = {
  css => 'orphans',
  dom => 'orphans',
  key => 'orphans',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <https://suika.suikawiki.org/gate/2005/sw/orphans> and
      ## <https://suika.suikawiki.org/gate/2005/sw/widows> for
      ## browser compatibility issue.
      my $value = $t->{number};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["NUMBER", $sign * int ($value / 1)]});
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
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
  initial => ['NUMBER', 2],
  inherited => 1,
  compute => $compute_as_specified,
};
$Attr->{widows} = $Prop->{widows};
$Key->{widows} = $Prop->{widows};

$Prop->{opacity} = {
  css => 'opacity',
  dom => 'opacity',
  key => 'opacity',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <https://suika.suikawiki.org/gate/2005/sw/opacity> for
      ## browser compatibility issue.
      my $value = $t->{number};
      $t = $tt->get_next_token;
      return ($t, {$prop_name => ["NUMBER", $sign * $value]});
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['NUMBER', 2],
  inherited => 1,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value) {
      if ($specified_value->[0] eq 'NUMBER') {
        if ($specified_value->[1] < 0) {
          return ['NUMBER', 0];
        } elsif ($specified_value->[1] > 1) {
          return ['NUMBER', 1];
        }
      }
    }

    return $specified_value;
  },
  serialize_multiple => sub {
    ## NOTE: This CODE is necessary to avoid two 'opacity' properties
    ## are outputed in |cssText| (for 'opacity' and for '-moz-opacity').
    return {opacity => [shift->opacity]},
  },
};
$Attr->{opacity} = $Prop->{opacity};
$Key->{opacity} = $Prop->{opacity};

$Prop->{'-moz-opacity'} = $Prop->{opacity};
$Attr->{_moz_opacity} = $Attr->{opacity};

my $length_unit = {
  em => 1, ex => 1, px => 1,
  in => 1, cm => 1, mm => 1, pt => 1, pc => 1,
};

my $length_percentage_keyword_parser = sub ($$$$$) {
  my ($self, $prop_name, $tt, $t, $onerror) = @_;

  ## NOTE: Allowed keyword must have true value for $self->{prop_value}->{$_}.

    my $sign = 1;
    my $has_sign;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }
    my $allow_negative = $Prop->{$prop_name}->{allow_negative};

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and ($allow_negative or $value >= 0)) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['DIMENSION', $value, $unit]});
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      if ($allow_negative or $value >= 0) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['PERCENTAGE', $value]});
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      if ($allow_negative or $value >=0) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['DIMENSION', $value, 'px']});
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($Prop->{$prop_name}->{keyword}->{$value}) {
        if ($Prop->{$prop_name}->{keyword}->{$value} == 1 or
            $self->{prop_value}->{$prop_name}->{$value}) {
          $t = $tt->get_next_token;
          return ($t, {$prop_name => ['KEYWORD', $value]});        
        }
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
      ## NOTE: In the "else" case, don't procede the |$t| pointer
      ## for the support of 'border-top' property (and similar ones).
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
}; # $length_percentage_keyword_parser

my $length_keyword_parser = sub {
  my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }
    my $allow_negative = $Prop->{$prop_name}->{allow_negative};

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and ($allow_negative or $value >= 0)) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['DIMENSION', $value, $unit]});
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      if ($allow_negative or $value >= 0) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['DIMENSION', $value, 'px']});
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($Prop->{$prop_name}->{keyword}->{$value}) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', $value]});        
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
}; # $length_keyword_parser

$Prop->{'font-size'} = {
  css => 'font-size',
  dom => 'font_size',
  key => 'font_size',
  parse => $length_percentage_keyword_parser,
  #allow_negative => 0,
  keyword => {
           'xx-small' => 1, 'x-small' => 1, small => 1, medium => 1,
           large => 1, 'x-large' => 1, 'xx-large' => 1, 
           '-manakai-xxx-large' => 1, '-webkit-xxx-large' => 1,
           larger => 1, smaller => 1,
  },
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
        ## else: consistency error

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
          ## TODO: different computation in quirks mode?
          return ['DIMENSION', $self->{font_size}->[{
            'xx-small' => 0,
            'x-small' => 1,
            small => 2,
            medium => 3,
            large => 4,
            'x-large' => 5,
            'xx-large' => 6,
            '-manakai-xxx-large' => 7,
            '-webkit-xxx-large' => 7,
          }->{$specified_value->[1]}], 'px'];
        }
      }
    }

    ## TODO: Should we convert '-manakai-xxx-large' to '-webkit-xxx-large'
    ## at the parse time?
    
    return $specified_value;
  },
};
$Attr->{font_size} = $Prop->{'font-size'};
$Key->{font_size} = $Prop->{'font-size'};

my $compute_length = sub {
  my ($self, $element, $prop_name, $specified_value) = @_;
  
  if (defined $specified_value) {
    if ($specified_value->[0] eq 'DIMENSION') {
      my $unit = $specified_value->[2];
      my $value = $specified_value->[1];

      if ($unit eq 'em' or $unit eq 'ex') {
        $value *= 0.5 if $unit eq 'ex';
        ## TODO: Preferred way to determine the |ex| size is defined
        ## in CSS 2.1.

        $value *= $self->get_computed_value ($element, 'font-size')->[1];
        $unit = 'px';
      } elsif ({in => 1, cm => 1, mm => 1, pt => 1, pc => 1}->{$unit}) {
        ($value *= 12, $unit = 'pc') if $unit eq 'pc';
        ($value /= 72, $unit = 'in') if $unit eq 'pt';
        ($value *= 2.54, $unit = 'cm') if $unit eq 'in';
        ($value *= 10, $unit = 'mm') if $unit eq 'cm';
        ($value /= 0.26, $unit = 'px') if $unit eq 'mm';
      }

      return ['DIMENSION', $value, $unit];
    }
  }
  
  return $specified_value;
}; # $compute_length

$Prop->{'letter-spacing'} = {
  css => 'letter-spacing',
  dom => 'letter_spacing',
  key => 'letter_spacing',
  parse => $length_keyword_parser,
  allow_negative => 1,
  keyword => {normal => 1},
  initial => ['KEYWORD', 'normal'],
  inherited => 1,
  compute => $compute_length,
};
$Attr->{letter_spacing} = $Prop->{'letter-spacing'};
$Key->{letter_spacing} = $Prop->{'letter-spacing'};

$Prop->{'word-spacing'} = {
  css => 'word-spacing',
  dom => 'word_spacing',
  key => 'word_spacing',
  parse => $length_keyword_parser,
  allow_negative => 1,
  keyword => {normal => 1},
  initial => ['KEYWORD', 'normal'],
  inherited => 1,
  compute => $compute_length,
};
$Attr->{word_spacing} = $Prop->{'word-spacing'};
$Key->{word_spacing} = $Prop->{'word-spacing'};

$Prop->{'-manakai-border-spacing-x'} = {
  css => '-manakai-border-spacing-x',
  dom => '_manakai_border_spacing_x',
  key => 'border_spacing_x',
  parse => $length_keyword_parser,
  #allow_negative => 0,
  #keyword => {},
  serialize_multiple => sub {
    my $self = shift;
    
    my $x = $self->_manakai_border_spacing_x;
    my $y = $self->_manakai_border_spacing_y;
    my $xi = $self->get_property_priority ('-manakai-border-spacing-x');
    my $yi = $self->get_property_priority ('-manakai-border-spacing-y');
    if (length $x) {
      if (length $y) {
        if ($xi eq $yi) {
          if ($x eq $y) {
            return {'border-spacing' => [$x, $xi]};
          } else {
            if ($x eq 'inherit' or $y eq 'inherit') {
              return {'-manakai-border-spacing-x' => [$x, $xi],
                      '-manakai-border-spacing-y' => [$y, $yi]};
            } else {
              return {'border-spacing' => [$x . ' ' . $y, $xi]};
            }
          }
        } else {
          return {'-manakai-border-spacing-x' => [$x, $xi],
                  '-manakai-border-spacing-y' => [$y, $yi]};
        }
      } else {
        return {'-manakai-border-spacing-x' => [$x, $xi]};
      }
    } else {
      if (length $y) {
        return {'-manakai-border-spacing-y' => [$y, $yi]};
      } else {
        return {};
      }
    }
  },
  initial => ['DIMENSION', 0, 'px'],
  inherited => 1,
  compute => $compute_length,
};
$Attr->{_manakai_border_spacing_x} = $Prop->{'-manakai-border-spacing-x'};
$Key->{border_spacing_x} = $Prop->{'-manakai-border-spacing-x'};

$Prop->{'-manakai-border-spacing-y'} = {
  css => '-manakai-border-spacing-y',
  dom => '_manakai_border_spacing_y',
  key => 'border_spacing_y',
  parse => $length_keyword_parser,
  #allow_negative => 0,
  #keyword => {},
  serialize_multiple => $Prop->{'-manakai-border-spacing-x'}
      ->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  inherited => 1,
  compute => $compute_length,
};
$Attr->{_manakai_border_spacing_y} = $Prop->{'-manakai-border-spacing-y'};
$Key->{border_spacing_y} = $Prop->{'-manakai-border-spacing-y'};

$Attr->{marker_offset} =
$Key->{marker_offset} =
$Prop->{'marker-offset'} = {
  css => 'marker-offset',
  dom => 'marker_offset',
  key => 'marker_offset',
  parse => $length_keyword_parser,
  allow_negative => 1,
  keyword => {auto => 1},
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => $compute_length,
};

$Prop->{'margin-top'} = {
  css => 'margin-top',
  dom => 'margin_top',
  key => 'margin_top',
  parse => $length_percentage_keyword_parser,
  allow_negative => 1,
  keyword => {auto => 1},
  serialize_multiple => sub {
    my $self = shift;

    ## NOTE: Same as |serialize_multiple| of 'padding-top'.

    my $use_shorthand = 1;
    my $t = $self->margin_top;
    undef $use_shorthand unless length $t;
    my $t_i = $self->get_property_priority ('margin-top');
    my $r = $self->margin_right;
    undef $use_shorthand
        if not length $r or
            ($r eq 'inherit' and $t ne 'inherit') or
            ($t eq 'inherit' and $r ne 'inherit');
    my $r_i = $self->get_property_priority ('margin-right');
    undef $use_shorthand unless $r_i eq $t_i;
    my $b = $self->margin_bottom;
    undef $use_shorthand
        if not length $b or
            ($b eq 'inherit' and $t ne 'inherit') or
            ($t eq 'inherit' and $b ne 'inherit');
    my $b_i = $self->get_property_priority ('margin-bottom');
    undef $use_shorthand unless $b_i eq $t_i;
    my $l = $self->margin_left;
    undef $use_shorthand
        if not length $l or
            ($l eq 'inherit' and $t ne 'inherit') or
            ($t eq 'inherit' and $l ne 'inherit');
    my $l_i = $self->get_property_priority ('margin-left');
    undef $use_shorthand unless $l_i eq $t_i;

    if ($use_shorthand) {
      $b .= ' ' . $l if $r ne $l;
      $r .= ' ' . $b if $t ne $b;
      $t .= ' ' . $r if $t ne $r;
      return {margin => [$t, $t_i]};
    } else {
      my $v = {};
      if (length $t) {
        $v->{'margin-top'} = [$t, $t_i];
      }
      if (length $r) {
        $v->{'margin-right'} = [$r, $r_i];
      }
      if (length $b) {
        $v->{'margin-bottom'} = [$b, $b_i];
      }
      if (length $l) {
        $v->{'margin-left'} = [$l, $l_i];
      }
      return $v;
    }
  },
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{margin_top} = $Prop->{'margin-top'};
$Key->{margin_top} = $Prop->{'margin-top'};

$Prop->{'margin-bottom'} = {
  css => 'margin-bottom',
  dom => 'margin_bottom',
  key => 'margin_bottom',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  serialize_multiple => $Prop->{'margin-top'}->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{margin_bottom} = $Prop->{'margin-bottom'};
$Key->{margin_bottom} = $Prop->{'margin-bottom'};

$Prop->{'margin-right'} = {
  css => 'margin-right',
  dom => 'margin_right',
  key => 'margin_right',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  serialize_multiple => $Prop->{'margin-top'}->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{margin_right} = $Prop->{'margin-right'};
$Key->{margin_right} = $Prop->{'margin-right'};

$Prop->{'margin-left'} = {
  css => 'margin-left',
  dom => 'margin_left',
  key => 'margin_left',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  serialize_multiple => $Prop->{'margin-top'}->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{margin_left} = $Prop->{'margin-left'};
$Key->{margin_left} = $Prop->{'margin-left'};

$Prop->{top} = {
  css => 'top',
  dom => 'top',
  key => 'top',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute_multiple => sub {
    my ($self, $element, $eid, $prop_name) = @_;

    my $pos_value = $self->get_computed_value ($element, 'position');
    if (defined $pos_value and $pos_value->[0] eq 'KEYWORD') {
      if ($pos_value->[1] eq 'static') {
        $self->{computed_value}->{$eid}->{top} = ['KEYWORD', 'auto'];
        $self->{computed_value}->{$eid}->{bottom} = ['KEYWORD', 'auto'];
        return;
      } elsif ($pos_value->[1] eq 'relative') {
        my $top_specified = $self->get_specified_value_no_inherit
          ($element, 'top');
        if (defined $top_specified and
            ($top_specified->[0] eq 'DIMENSION' or
             $top_specified->[0] eq 'PERCENTAGE')) {
          my $tv = $self->{computed_value}->{$eid}->{top}
              = $compute_length->($self, $element, 'top', $top_specified);
          $self->{computed_value}->{$eid}->{bottom}
              = [$tv->[0], -$tv->[1], $tv->[2]];
        } else { # top: auto
          my $bottom_specified = $self->get_specified_value_no_inherit
              ($element, 'bottom');
          if (defined $bottom_specified and
              ($bottom_specified->[0] eq 'DIMENSION' or
               $bottom_specified->[0] eq 'PERCENTAGE')) {
            my $tv = $self->{computed_value}->{$eid}->{bottom}
                = $compute_length->($self, $element, 'bottom',
                                    $bottom_specified);
            $self->{computed_value}->{$eid}->{top}
                = [$tv->[0], -$tv->[1], $tv->[2]];
          } else { # bottom: auto
            $self->{computed_value}->{$eid}->{top} = ['DIMENSION', 0, 'px'];
            $self->{computed_value}->{$eid}->{bottom} = ['DIMENSION', 0, 'px'];
          }
        }
        return;
      }
    }

    my $top_specified = $self->get_specified_value_no_inherit
        ($element, 'top');
    $self->{computed_value}->{$eid}->{top}
        = $compute_length->($self, $element, 'top', $top_specified);
    my $bottom_specified = $self->get_specified_value_no_inherit
        ($element, 'bottom');
    $self->{computed_value}->{$eid}->{bottom}
        = $compute_length->($self, $element, 'bottom', $bottom_specified);
  },
};
$Attr->{top} = $Prop->{top};
$Key->{top} = $Prop->{top};

$Prop->{bottom} = {
  css => 'bottom',
  dom => 'bottom',
  key => 'bottom',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute_multiple => $Prop->{top}->{compute_multiple},
};
$Attr->{bottom} = $Prop->{bottom};
$Key->{bottom} = $Prop->{bottom};

$Prop->{left} = {
  css => 'left',
  dom => 'left',
  key => 'left',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute_multiple => sub {
    my ($self, $element, $eid, $prop_name) = @_;

    my $pos_value = $self->get_computed_value ($element, 'position');
    if (defined $pos_value and $pos_value->[0] eq 'KEYWORD') {
      if ($pos_value->[1] eq 'static') {
        $self->{computed_value}->{$eid}->{left} = ['KEYWORD', 'auto'];
        $self->{computed_value}->{$eid}->{right} = ['KEYWORD', 'auto'];
        return;
      } elsif ($pos_value->[1] eq 'relative') {
        my $left_specified = $self->get_specified_value_no_inherit
            ($element, 'left');
        if (defined $left_specified and
            ($left_specified->[0] eq 'DIMENSION' or
             $left_specified->[0] eq 'PERCENTAGE')) {
          my $right_specified = $self->get_specified_value_no_inherit
              ($element, 'right');
          if (defined $right_specified and
              ($right_specified->[0] eq 'DIMENSION' or
               $right_specified->[0] eq 'PERCENTAGE')) {
            my $direction = $self->get_computed_value ($element, 'direction');
            if (defined $direction and $direction->[0] eq 'KEYWORD' and
                $direction->[0] eq 'ltr') {
              my $tv = $self->{computed_value}->{$eid}->{left}
                  = $compute_length->($self, $element, 'left',
                                      $left_specified);
              $self->{computed_value}->{$eid}->{right}
                  = [$tv->[0], -$tv->[1], $tv->[2]];
            } else {
              my $tv = $self->{computed_value}->{$eid}->{right}
                  = $compute_length->($self, $element, 'right',
                                      $right_specified);
              $self->{computed_value}->{$eid}->{left}
                  = [$tv->[0], -$tv->[1], $tv->[2]];
            }
          } else {
            my $tv = $self->{computed_value}->{$eid}->{left}
                = $compute_length->($self, $element, 'left', $left_specified);
            $self->{computed_value}->{$eid}->{right}
                = [$tv->[0], -$tv->[1], $tv->[2]];
          }
        } else { # left: auto
          my $right_specified = $self->get_specified_value_no_inherit
              ($element, 'right');
          if (defined $right_specified and
              ($right_specified->[0] eq 'DIMENSION' or
               $right_specified->[0] eq 'PERCENTAGE')) {
            my $tv = $self->{computed_value}->{$eid}->{right}
                = $compute_length->($self, $element, 'right',
                                    $right_specified);
            $self->{computed_value}->{$eid}->{left}
                = [$tv->[0], -$tv->[1], $tv->[2]];
          } else { # right: auto
            $self->{computed_value}->{$eid}->{left} = ['DIMENSION', 0, 'px'];
            $self->{computed_value}->{$eid}->{right} = ['DIMENSION', 0, 'px'];
          }
        }
        return;
      }
    }

    my $left_specified = $self->get_specified_value_no_inherit
        ($element, 'left');
    $self->{computed_value}->{$eid}->{left}
        = $compute_length->($self, $element, 'left', $left_specified);
    my $right_specified = $self->get_specified_value_no_inherit
        ($element, 'right');
    $self->{computed_value}->{$eid}->{right}
        = $compute_length->($self, $element, 'right', $right_specified);
  },
};
$Attr->{left} = $Prop->{left};
$Key->{left} = $Prop->{left};

$Prop->{right} = {
  css => 'right',
  dom => 'right',
  key => 'right',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {auto => 1},
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute_multiple => $Prop->{left}->{compute_multiple},
};
$Attr->{right} = $Prop->{right};
$Key->{right} = $Prop->{right};

$Prop->{width} = {
  css => 'width',
  dom => 'width',
  key => 'width',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  keyword => {
    auto => 1,
    
    ## Firefox 3
    '-moz-max-content' => 2, '-moz-min-content' => 2, 
    '-moz-available' => 2, '-moz-fit-content' => 2,
        ## NOTE: By "2", it represents that the parser must be configured
        ## to allow these values.
  },
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => $compute_length,
      ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/width> for
      ## browser compatibility issues.
};
$Attr->{width} = $Prop->{width};
$Key->{width} = $Prop->{width};

$Prop->{'min-width'} = {
  css => 'min-width',
  dom => 'min_width',
  key => 'min_width',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  keyword => {
    ## Firefox 3
    '-moz-max-content' => 2, '-moz-min-content' => 2, 
    '-moz-available' => 2, '-moz-fit-content' => 2,
  },
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{min_width} = $Prop->{'min-width'};
$Key->{min_width} = $Prop->{'min-width'};

$Prop->{'max-width'} = {
  css => 'max-width',
  dom => 'max_width',
  key => 'max_width',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  keyword => {
    none => 1,
    
    ## Firefox 3
    '-moz-max-content' => 2, '-moz-min-content' => 2, 
    '-moz-available' => 2, '-moz-fit-content' => 2,
  },
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{max_width} = $Prop->{'max-width'};
$Key->{max_width} = $Prop->{'max-width'};

$Prop->{height} = {
  css => 'height',
  dom => 'height',
  key => 'height',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  keyword => {auto => 1},
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => $compute_length,
      ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/height> for
      ## browser compatibility issues.
};
$Attr->{height} = $Prop->{height};
$Key->{height} = $Prop->{height};

$Prop->{'min-height'} = {
  css => 'min-height',
  dom => 'min_height',
  key => 'min_height',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  #keyword => {},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{min_height} = $Prop->{'min-height'};
$Key->{min_height} = $Prop->{'min-height'};

$Prop->{'max-height'} = {
  css => 'max-height',
  dom => 'max_height',
  key => 'max_height',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  keyword => {none => 1},
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{max_height} = $Prop->{'max-height'};
$Key->{max_height} = $Prop->{'max-height'};

$Prop->{'line-height'} = {
  css => 'line-height',
  dom => 'line_height',
  key => 'line_height',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    ## NOTE: Similar to 'margin-top', but different handling
    ## for unitless numbers.

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
      $has_sign = 1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['DIMENSION', $value, $unit]});
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      if ($value >= 0) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['PERCENTAGE', $value]});
      }
    } elsif ($t->{type} == NUMBER_TOKEN) {
      my $value = $t->{number} * $sign;
      if ($value >= 0) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['NUMBER', $value]});
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'normal') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', $value]});        
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'normal'],
  inherited => 1,
  compute => $compute_length,
};
$Attr->{line_height} = $Prop->{'line-height'};
$Key->{line_height} = $Prop->{'line-height'};

$Prop->{'vertical-align'} = {
  css => 'vertical-align',
  dom => 'vertical_align',
  key => 'vertical_align',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {
    baseline => 1, sub => 1, super => 1, top => 1, 'text-top' => 1,
    middle => 1, bottom => 1, 'text-bottom' => 1,
  },
  ## NOTE: Currently, we don't support option to select subset of keywords
  ## supported by application (i.e. 
  ## $parser->{prop_value}->{'line-height'->{$keyword}).  Should we support
  ## it?
  initial => ['KEYWORD', 'baseline'],
  #inherited => 0,
  compute => $compute_length,
      ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/vertical-align> for
      ## browser compatibility issues.
};
$Attr->{vertical_align} = $Prop->{'vertical-align'};
$Key->{vertical_align} = $Prop->{'vertical-align'};

$Prop->{'text-indent'} = {
  css => 'text-indent',
  dom => 'text_indent',
  key => 'text_indent',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {},
  initial => ['DIMENSION', 0, 'px'],
  inherited => 1,
  compute => $compute_length,
};
$Attr->{text_indent} = $Prop->{'text-indent'};
$Key->{text_indent} = $Prop->{'text-indent'};

$Prop->{'background-position-x'} = {
  css => 'background-position-x',
  dom => 'background_position_x',
  key => 'background_position_x',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {left => 1, center => 1, right => 1},
  initial => ['PERCENTAGE', 0],
  #inherited => 0,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value and $specified_value->[0] eq 'KEYWORD') {
      my $v = {
        left => 0, center => 50, right => 100, top => 0, bottom => 100,
      }->{$specified_value->[1]};
      if (defined $v) {
        return ['PERCENTAGE', $v];
      } else {
        return $specified_value;
      }
    } else {
      return $compute_length->(@_);
    }
  },
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
};
$Attr->{background_position_x} = $Prop->{'background-position-x'};
$Key->{background_position_x} = $Prop->{'background-position-x'};

$Prop->{'background-position-y'} = {
  css => 'background-position-y',
  dom => 'background_position_y',
  key => 'background_position_y',
  parse => $Prop->{'margin-top'}->{parse},
  allow_negative => 1,
  keyword => {top => 1, center => 1, bottom => 1},
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
  initial => ['PERCENTAGE', 0],
  #inherited => 0,
  compute => $Prop->{'background-position-x'}->{compute},
};
$Attr->{background_position_y} = $Prop->{'background-position-y'};
$Key->{background_position_y} = $Prop->{'background-position-y'};

$Prop->{'padding-top'} = {
  css => 'padding-top',
  dom => 'padding_top',
  key => 'padding_top',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  #keyword => {},
  serialize_multiple => sub {
    my $self = shift;

    ## NOTE: Same as |serialize_multiple| of 'margin-top'.

    my $use_shorthand = 1;
    my $t = $self->padding_top;
    undef $use_shorthand unless length $t;
    my $t_i = $self->get_property_priority ('padding-top');
    my $r = $self->padding_right;
    undef $use_shorthand
        if not length $r or
            ($r eq 'inherit' and $t ne 'inherit') or
            ($t eq 'inherit' and $r ne 'inherit');
    my $r_i = $self->get_property_priority ('padding-right');
    undef $use_shorthand unless $r_i eq $t_i;
    my $b = $self->padding_bottom;
    undef $use_shorthand
        if not length $b or
            ($b eq 'inherit' and $t ne 'inherit') or
            ($t eq 'inherit' and $b ne 'inherit');
    my $b_i = $self->get_property_priority ('padding-bottom');
    undef $use_shorthand unless $b_i eq $t_i;
    my $l = $self->padding_left;
    undef $use_shorthand
        if not length $l or
            ($l eq 'inherit' and $t ne 'inherit') or
            ($t eq 'inherit' and $l ne 'inherit');
    my $l_i = $self->get_property_priority ('padding-left');
    undef $use_shorthand unless $l_i eq $t_i;

    if ($use_shorthand) {
      $b .= ' ' . $l if $r ne $l;
      $r .= ' ' . $b if $t ne $b;
      $t .= ' ' . $r if $t ne $r;
      return {padding => [$t, $t_i]};
    } else {
      my $v = {};
      if (length $t) {
        $v->{'padding-top'} = [$t, $t_i];
      }
      if (length $r) {
        $v->{'padding-right'} = [$r, $r_i];
      }
      if (length $b) {
        $v->{'padding-bottom'} = [$b, $b_i];
      }
      if (length $l) {
        $v->{'padding-left'} = [$l, $l_i];
      }
      return $v;
    }
  },
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{padding_top} = $Prop->{'padding-top'};
$Key->{padding_top} = $Prop->{'padding-top'};

$Prop->{'padding-bottom'} = {
  css => 'padding-bottom',
  dom => 'padding_bottom',
  key => 'padding_bottom',
  parse => $Prop->{'padding-top'}->{parse},
  #allow_negative => 0,
  #keyword => {},
  serialize_multiple => $Prop->{'padding-top'}->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{padding_bottom} = $Prop->{'padding-bottom'};
$Key->{padding_bottom} = $Prop->{'padding-bottom'};

$Prop->{'padding-right'} = {
  css => 'padding-right',
  dom => 'padding_right',
  key => 'padding_right',
  parse => $Prop->{'padding-top'}->{parse},
  #allow_negative => 0,
  #keyword => {},
  serialize_multiple => $Prop->{'padding-top'}->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{padding_right} = $Prop->{'padding-right'};
$Key->{padding_right} = $Prop->{'padding-right'};

$Prop->{'padding-left'} = {
  css => 'padding-left',
  dom => 'padding_left',
  key => 'padding_left',
  parse => $Prop->{'padding-top'}->{parse},
  #allow_negative => 0,
  #keyword => {},
  serialize_multiple => $Prop->{'padding-top'}->{serialize_multiple},
  initial => ['DIMENSION', 0, 'px'],
  #inherited => 0,
  compute => $compute_length,
};
$Attr->{padding_left} = $Prop->{'padding-left'};
$Key->{padding_left} = $Prop->{'padding-left'};

$Prop->{'border-top-width'} = {
  css => 'border-top-width',
  dom => 'border_top_width',
  key => 'border_top_width',
  parse => $Prop->{'margin-top'}->{parse},
  #allow_negative => 0,
  keyword => {thin => 1, medium => 1, thick => 1},
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'medium'],
  #inherited => 0,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    ## NOTE: Used for 'border-top-width', 'border-right-width',
    ## 'border-bottom-width', 'border-right-width', and
    ## 'outline-width'.

    my $style_prop = $prop_name;
    $style_prop =~ s/width/style/;
    my $style = $self->get_computed_value ($element, $style_prop);
    if (defined $style and $style->[0] eq 'KEYWORD' and
        ($style->[1] eq 'none' or $style->[1] eq 'hidden')) {
      return ['DIMENSION', 0, 'px'];
    }

    my $value = $compute_length->(@_);
    if (defined $value and $value->[0] eq 'KEYWORD') {
      if ($value->[1] eq 'thin') {
        return ['DIMENSION', 1, 'px']; ## Firefox/Opera
      } elsif ($value->[1] eq 'medium') {
        return ['DIMENSION', 3, 'px']; ## Firefox/Opera
      } elsif ($value->[1] eq 'thick') {
        return ['DIMENSION', 5, 'px']; ## Firefox
      }
    }
    return $value;
  },
  ## NOTE: CSS3 will allow <percentage> as an option in <border-width>.
  ## Opera 9 has already implemented it.
};
$Attr->{border_top_width} = $Prop->{'border-top-width'};
$Key->{border_top_width} = $Prop->{'border-top-width'};

$Prop->{'border-right-width'} = {
  css => 'border-right-width',
  dom => 'border_right_width',
  key => 'border_right_width',
  parse => $Prop->{'border-top-width'}->{parse},
  #allow_negative => 0,
  keyword => {thin => 1, medium => 1, thick => 1},
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'medium'],
  #inherited => 0,
  compute => $Prop->{'border-top-width'}->{compute},
};
$Attr->{border_right_width} = $Prop->{'border-right-width'};
$Key->{border_right_width} = $Prop->{'border-right-width'};

$Prop->{'border-bottom-width'} = {
  css => 'border-bottom-width',
  dom => 'border_bottom_width',
  key => 'border_bottom_width',
  parse => $Prop->{'border-top-width'}->{parse},
  #allow_negative => 0,
  keyword => {thin => 1, medium => 1, thick => 1},
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'medium'],
  #inherited => 0,
  compute => $Prop->{'border-top-width'}->{compute},
};
$Attr->{border_bottom_width} = $Prop->{'border-bottom-width'};
$Key->{border_bottom_width} = $Prop->{'border-bottom-width'};

$Prop->{'border-left-width'} = {
  css => 'border-left-width',
  dom => 'border_left_width',
  key => 'border_left_width',
  parse => $Prop->{'border-top-width'}->{parse},
  #allow_negative => 0,
  keyword => {thin => 1, medium => 1, thick => 1},
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'medium'],
  #inherited => 0,
  compute => $Prop->{'border-top-width'}->{compute},
};
$Attr->{border_left_width} = $Prop->{'border-left-width'};
$Key->{border_left_width} = $Prop->{'border-left-width'};

$Prop->{'outline-width'} = {
  css => 'outline-width',
  dom => 'outline_width',
  key => 'outline_width',
  parse => $Prop->{'border-top-width'}->{parse},
  #allow_negative => 0,
  keyword => {thin => 1, medium => 1, thick => 1},
  serialize_multiple => $Prop->{'outline-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'medium'],
  #inherited => 0,
  compute => $Prop->{'border-top-width'}->{compute},
};
$Attr->{outline_width} = $Prop->{'outline-width'};
$Key->{outline_width} = $Prop->{'outline-width'};

$Prop->{'font-weight'} = {
  css => 'font-weight',
  dom => 'font_weight',
  key => 'font_weight',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my $has_sign;
    if ($t->{type} == PLUS_TOKEN) {
      $has_sign = 1;
      $t = $tt->get_next_token;
    }

    if ($t->{type} == NUMBER_TOKEN) {
      ## ISSUE: See <https://suika.suikawiki.org/gate/2005/sw/font-weight> for
      ## browser compatibility issue.
      my $value = $t->{number} + 0;
      $t = $tt->get_next_token;
      if ($value % 100 == 0 and 100 <= $value and $value <= 900) {
        return ($t, {$prop_name => ['WEIGHT', $value, 0]});
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ({
           normal => 1, bold => 1, bolder => 1, lighter => 1,
          }->{$value}) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', $value]});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
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
    #    $onerror->(type => 'uri not closed',
    #               level => $self->{level}->{must},
    #               uri => \$self->{href},
    #               token => $t);
    #    
    #    return ($t, {$prop_name => ['URI', $value, \($self->{base_uri})]});
    #  }
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
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
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_uri_or_none,
};
$Attr->{background_image} = $Prop->{'background-image'};
$Key->{background_image} = $Prop->{'background-image'};

$Attr->{font_stretch} =
$Key->{font_stretch} =
$Prop->{'font-stretch'} = {
  css => 'font-stretch',
  dom => 'font_stretch',
  key => 'font_stretch',
  parse => $one_keyword_parser,
  keyword => {
    qw/normal 1 wider 1 narrower 1 ultra-condensed 1 extra-condensed 1
       condensed 1 semi-condensed 1 semi-expanded 1 expanded 1 
       extra-expanded 1 ultra-expanded 1/,
  },
  initial => ["KEYWORD", 'normal'],
  inherited => 1,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value and $specified_value->[0] eq 'KEYWORD') {
      if ($specified_value->[1] eq 'wider') {
        my $parent = $element->manakai_parent_element;
        if ($parent) {
          my $computed = $self->get_computed_value ($parent, $prop_name);
          if (defined $computed and $computed->[0] eq 'KEYWORD') {
            return ['KEYWORD', {
                                'ultra-condensed' => 'extra-condensed',
                                'extra-condensed' => 'condensed',
                                'condensed' => 'semi-condensed',
                                'semi-condensed' => 'normal',
                                'normal' => 'semi-expanded',
                                'semi-expanded' => 'expanded',
                                'expanded' => 'extra-expanded',
                                'extra-expanded' => 'ultra-expanded',
                                'ultra-expanded' => 'ultra-expanded',
                               }->{$computed->[1]} || $computed->[1]];
          } else { ## This is an implementation error.
            #
          }
        } else {
          return ['KEYWORD', 'semi-expanded'];
        }
      } elsif ($specified_value->[1] eq 'narrower') {
        my $parent = $element->manakai_parent_element;
        if ($parent) {
          my $computed = $self->get_computed_value ($parent, $prop_name);
          if (defined $computed and $computed->[0] eq 'KEYWORD') {
            return ['KEYWORD', {
                                'ultra-condensed' => 'ultra-condensed',
                                'extra-condensed' => 'ultra-condensed',
                                'condensed' => 'extra-condensed',
                                'semi-condensed' => 'condensed',
                                'normal' => 'semi-condensed',
                                'semi-expanded' => 'normal',
                                'expanded' => 'semi-expanded',
                                'extra-expanded' => 'expanded',
                                'ultra-expanded' => 'extra-expanded',
                               }->{$computed->[1]} || $computed->[1]];
          } else { ## This is an implementation error.
            #
          }
        } else {
          return ['KEYWORD', 'semi-condensed'];
        }
      }
    }

    return $specified_value;
  },
};

$Attr->{writing_mode} =
$Key->{writing_mode} =
$Prop->{'writing-mode'} = {
  css => 'writing-mode',
  dom => 'writing_mode',
  key => 'writing_mode',
  parse => $one_keyword_parser,
  keyword => {
    'lr' => 1, 'lr-tb' => 1,
    'rl' => 1, 'rl-tb' => 1,
    'tb' => 1, 'tb-rl' => 1,
  },
  initial => ['KEYWORD', 'lr-tb'],
  inherited => 1,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    ## ISSUE: Not defined by any standard.

    if (defined $specified_value and $specified_value->[0] eq 'KEYWORD') {
      if ($specified_value->[1] eq 'lr') {
        return ['KEYWORD', 'lr-tb'];
      } elsif ($specified_value->[1] eq 'rl') {
        return ['KEYWORD', 'rl-tb'];
      } elsif ($specified_value->[1] eq 'tb') {
        return ['KEYWORD', 'tb-rl'];
      }
    }

    return $specified_value;
  },
};

$Attr->{text_anchor} =
$Key->{text_anchor} =
$Prop->{'text-anchor'} = {
  css => 'text-anchor',
  dom => 'text_anchor', ## TODO: manakai extension.  Documentation.
  key => 'text_anchor',
  parse => $one_keyword_parser,
  keyword => {
    start => 1, middle => 1, end => 1,
  },
  initial => ['KEYWORD', 'start'],
  inherited => 1,
  compute => $compute_as_specified,
};

$Attr->{dominant_baseline} =
$Key->{dominant_baseline} =
$Prop->{'dominant-baseline'} = {
  css => 'dominant-baseline',
  dom => 'dominant_baseline', ## TODO: manakai extension.  Documentation.
  key => 'dominant_baseline',
  parse => $one_keyword_parser,
  keyword => {
    qw/auto 1 use-script 1 no-change 1 reset-size 1 ideographic 1 alphabetic 1
       hanging 1 mathematical 1 central 1 middle 1 text-after-edge 1
       text-before-edge 1/
  },
  initial => ['KEYWORD', 'auto'],
  inherited => 0,
  compute => $compute_as_specified,
};

$Attr->{alignment_baseline} =
$Key->{alignment_baseline} =
$Prop->{'alignment-baseline'} = {
  css => 'alignment-baseline',
  dom => 'alignment_baseline', ## TODO: manakai extension.  Documentation.
  key => 'alignment_baseline',
  parse => $one_keyword_parser,
  keyword => {
    qw/auto 1 baseline 1 before-edge 1 text-before-edge 1 middle 1 central 1
       after-edge 1 text-after-edge 1 ideographic 1 alphabetic 1 hanging 1
       mathematical 1/
  },
  initial => ['KEYWORD', 'auto'],
  inherited => 0,
  compute => $compute_as_specified,
};

my $border_style_keyword = {
  none => 1, hidden => 1, dotted => 1, dashed => 1, solid => 1,
  double => 1, groove => 1, ridge => 1, inset => 1, outset => 1,
};

$Prop->{'border-top-style'} = {
  css => 'border-top-style',
  dom => 'border_top_style',
  key => 'border_top_style',
  parse => $one_keyword_parser,
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
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
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
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
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
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
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
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
  serialize_multiple => $Prop->{'outline-color'}->{serialize_multiple},
  keyword => {%$border_style_keyword},
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{outline_style} = $Prop->{'outline-style'};
$Key->{outline_style} = $Prop->{'outline-style'};
delete $Prop->{'outline-style'}->{keyword}->{hidden};

my $generic_font_keywords = {
  serif => 1, 'sans-serif' => 1, cursive => 1,
  fantasy => 1, monospace => 1, '-manakai-default' => 1,
  '-manakai-caption' => 1, '-manakai-icon' => 1,
  '-manakai-menu' => 1, '-manakai-message-box' => 1, 
  '-manakai-small-caption' => 1, '-manakai-status-bar' => 1,
};
## NOTE: "All five generic font families are defined to exist in all CSS
## implementations (they need not necessarily map to five distinct actual
## fonts)." [CSS 2.1].
## NOTE: "If no font with the indicated characteristics exists on a given
## platform, the user agent should either intelligently substitute (e.g., a
## smaller version of the 'caption' font might be used for the 'small-caption'
## font), or substitute a user agent default font." [CSS 2.1].

$Prop->{'font-family'} = {
  css => 'font-family',
  dom => 'font_family',
  key => 'font_family',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/font-family> for
    ## how chaotic browsers are!

    ## NOTE: Opera 9 allows NUMBER and DIMENSION as part of 
    ## <font-family>, while Firefox 2 does not.

    my @prop_value;

    my $font_name = '';
    my $may_be_generic = 1;
    my $may_be_inherit = ($prop_name ne 'font');
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
      } elsif ($t->{type} == COMMA_TOKEN) { ## TODO: case
        if ($may_be_generic and $generic_font_keywords->{lc $font_name}) {
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
        if ($may_be_generic and $generic_font_keywords->{lc $font_name}) {
          push @prop_value, ['KEYWORD', $font_name]; ## TODO: case
        } elsif (not $may_be_generic or length $font_name) {
          push @prop_value, ['STRING', $font_name];
        } else {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
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

    ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/cursor> for browser
    ## compatibility issues.

    my @prop_value = ('CURSOR');

    F: {
      if ($t->{type} == IDENT_TOKEN) {
        my $v = lc $t->{value}; ## TODO: case
        if ($Prop->{$prop_name}->{keyword}->{$v}) {
          push @prop_value, ['KEYWORD', $v];
          $t = $tt->get_next_token;
          last F;
        } elsif ($v eq 'hand' and
                 $Prop->{$prop_name}->{keyword}->{pointer}) {
          ## TODO: add test
          $onerror->(type => 'CSS cursor hand',
                     level => $self->{level}->{must}, # not valid <'cursor'>
                     uri => \$self->{href},
                     token => $t);
          push @prop_value, ['KEYWORD', 'pointer'];
          $t = $tt->get_next_token;
          last F;
        } elsif ($v eq 'inherit' and @prop_value == 1) {
          $t = $tt->get_next_token;
          return ($t, {$prop_name => ['INHERIT']});
        } else {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          return ($t, undef);
        }
      } elsif ($t->{type} == URI_TOKEN) {
        push @prop_value, ['URI', $t->{value}, \($self->{base_uri})];
        $t = $tt->get_next_token;
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
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
    if ($t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($border_style_keyword->{$prop_value} and
          $self->{prop_value}->{'border-top-style'}->{$prop_value}) {
        $prop_value{'border-top-style'} = ["KEYWORD", $prop_value];
      } elsif ($prop_value eq 'inherit') {
        $prop_value{'border-top-style'} = ["INHERIT"];
        $prop_value{'border-right-style'} = $prop_value{'border-top-style'};
        $prop_value{'border-bottom-style'} = $prop_value{'border-top-style'};
        $prop_value{'border-left-style'} = $prop_value{'border-right-style'};
        return ($t, \%prop_value);
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      $prop_value{'border-right-style'} = $prop_value{'border-top-style'};
      $prop_value{'border-bottom-style'} = $prop_value{'border-top-style'};
      $prop_value{'border-left-style'} = $prop_value{'border-right-style'};
    } else {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($border_style_keyword->{$prop_value} and
          $self->{prop_value}->{'border-right-style'}->{$prop_value}) {
        $prop_value{'border-right-style'} = ["KEYWORD", $prop_value];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
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
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
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
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        }
      }
    }        

    return ($t, \%prop_value);
  },
  serialize_shorthand => sub {
    my $self = shift;

    my @v;
    push @v, $self->border_top_style;
    my $i = $self->get_property_priority ('border-top-style');
    return {} unless length $v[-1];
    push @v, $self->border_right_style;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-right-style');
    push @v, $self->border_bottom_style;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-bottom-style');
    push @v, $self->border_left_style;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-left-style');

    my $v = 0;
    for (0..3) {
      $v++ if $v[$_] eq 'inherit';
    }
    if ($v == 4) {
      return {'border-style' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    pop @v if $v[1] eq $v[3];
    pop @v if $v[0] eq $v[2];
    pop @v if $v[0] eq $v[1];
    return {'border-style' => [(join ' ', @v), $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_style} = $Prop->{'border-style'};

$Prop->{'border-color'} = {
  css => 'border-color',
  dom => 'border_color',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;
    ($t, my $pv) = $parse_color->($self, 'border-color', $tt, $t, $onerror);
    if (not defined $pv) {
      return ($t, undef);
    }
    $prop_value{'border-top-color'} = $pv->{'border-color'};
    $prop_value{'border-bottom-color'} = $prop_value{'border-top-color'};
    $prop_value{'border-right-color'} = $prop_value{'border-top-color'};
    $prop_value{'border-left-color'}= $prop_value{'border-right-color'};
    if ($prop_value{'border-top-color'}->[0] eq 'INHERIT') {
      return ($t, \%prop_value);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ({
         IDENT_TOKEN, 1,
         HASH_TOKEN, 1, NUMBER_TOKEN, 1, DIMENSION_TOKEN, 1,
         FUNCTION_TOKEN, 1,
        }->{$t->{type}}) {
      ($t, $pv) = $parse_color->($self, 'border-color', $tt, $t, $onerror);
      if (not defined $pv) {
        return ($t, undef);
      } elsif ($pv->{'border-color'}->[0] eq 'INHERIT') {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      $prop_value{'border-right-color'} = $pv->{'border-color'};
      $prop_value{'border-left-color'}= $prop_value{'border-right-color'};

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ({
           IDENT_TOKEN, 1,
           HASH_TOKEN, 1, NUMBER_TOKEN, 1, DIMENSION_TOKEN, 1,
           FUNCTION_TOKEN, 1,
          }->{$t->{type}}) {
        ($t, $pv) = $parse_color->($self, 'border-color', $tt, $t, $onerror);
        if (not defined $pv) {
          return ($t, undef);
        } elsif ($pv->{'border-color'}->[0] eq 'INHERIT') {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          return ($t, undef);
        }
        $prop_value{'border-bottom-color'} = $pv->{'border-color'};

        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ({
             IDENT_TOKEN, 1,
             HASH_TOKEN, 1, NUMBER_TOKEN, 1, DIMENSION_TOKEN, 1,
             FUNCTION_TOKEN, 1,
            }->{$t->{type}}) {
          ($t, $pv) = $parse_color->($self, 'border-color', $tt, $t, $onerror);
          if (not defined $pv) {
            return ($t, undef);
          } elsif ($pv->{'border-color'}->[0] eq 'INHERIT') {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
          $prop_value{'border-left-color'} = $pv->{'border-color'};
        }
      }
    }
    
    return ($t, \%prop_value);
  },
  serialize_shorthand => sub {
    my $self = shift;

    my @v;
    push @v, $self->border_top_color;
    my $i = $self->get_property_priority ('border-top-color');
    return {} unless length $v[-1];
    push @v, $self->border_right_color;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-right-color');
    push @v, $self->border_bottom_color;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-bottom-color');
    push @v, $self->border_left_color;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-left-color');

    my $v = 0;
    for (0..3) {
      $v++ if $v[$_] eq 'inherit';
    }
    if ($v == 4) {
      return {'border-color' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    pop @v if $v[1] eq $v[3];
    pop @v if $v[0] eq $v[2];
    pop @v if $v[0] eq $v[1];
    return {'border-color' => [(join ' ', @v), $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_color} = $Prop->{'border-color'};

$Prop->{'border-top'} = {
  css => 'border-top',
  dom => 'border_top',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    ## TODO: Need to be rewritten.

    my %prop_value;
    my $pv;
    ## NOTE: Since $onerror is disabled for three invocations below,
    ## some informative warning messages (if they are added someday) will not
    ## be reported.
    ($t, $pv) = $parse_color->($self, $prop_name.'-color', $tt, $t, sub {});
    if (defined $pv) {
      if ($pv->{$prop_name.'-color'}->[0] eq 'INHERIT') {
        return ($t, {$prop_name.'-color' => ['INHERIT'],
                     $prop_name.'-style' => ['INHERIT'],
                     $prop_name.'-width' => ['INHERIT']});
      } else {
        $prop_value{$prop_name.'-color'} = $pv->{$prop_name.'-color'};
      }
    } else {
      ($t, $pv) = $Prop->{'border-top-width'}->{parse}
          ->($self, $prop_name.'-width', $tt, $t, sub {});
      if (defined $pv) {
        $prop_value{$prop_name.'-width'} = $pv->{$prop_name.'-width'};
      } else {
        ($t, $pv) = $Prop->{'border-top-style'}->{parse}
            ->($self, $prop_name.'-style', $tt, $t, sub {});
        if (defined $pv) {
          $prop_value{$prop_name.'-style'} = $pv->{$prop_name.'-style'};
        } else {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          return ($t, undef);
        }
      }
    }

    for (1..2) {
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      if ($t->{type} == IDENT_TOKEN) {
        my $prop_value = lc $t->{value}; ## TODO: case
        if ($border_style_keyword->{$prop_value} and
            $self->{prop_value}->{'border-top-style'}->{$prop_value} and
            not defined $prop_value{$prop_name.'-style'}) {
          $prop_value{$prop_name.'-style'} = ['KEYWORD', $prop_value];
          $t = $tt->get_next_token;
          next;
        } elsif ({thin => 1, medium => 1, thick => 1}->{$prop_value} and
                 not defined $prop_value{$prop_name.'-width'}) {
          $prop_value{$prop_name.'-width'} = ['KEYWORD', $prop_value];
          $t = $tt->get_next_token;
          next;
        }
      }

      undef $pv;
      ($t, $pv) = $parse_color->($self, $prop_name.'-color', $tt, $t, $onerror)
          if not defined $prop_value{$prop_name.'-color'} and
              {
                IDENT_TOKEN, 1,
                HASH_TOKEN, 1, NUMBER_TOKEN, 1, DIMENSION_TOKEN, 1,
                FUNCTION_TOKEN, 1,
              }->{$t->{type}};
      if (defined $pv) {
        if ($pv->{$prop_name.'-color'}->[0] eq 'INHERIT') {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
        } else {
          $prop_value{$prop_name.'-color'} = $pv->{$prop_name.'-color'};
        }
      } else {
        undef $pv;
        ($t, $pv) = $Prop->{'border-top-width'}->{parse}
            ->($self, $prop_name.'-width',
               $tt, $t, $onerror)
            if not defined $prop_value{$prop_name.'-width'} and
                {
                  DIMENSION_TOKEN, 1,
                  NUMBER_TOKEN, 1,
                  IDENT_TOKEN, 1,
                  MINUS_TOKEN, 1,
                }->{$t->{type}};
        if (defined $pv) {
          if ($pv->{$prop_name.'-width'}->[0] eq 'INHERIT') {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
          } else {
            $prop_value{$prop_name.'-width'} = $pv->{$prop_name.'-width'};
          }
        } else {
          last;
        }
      }    
    }

    $prop_value{$prop_name.'-color'}
        ||= $Prop->{$prop_name.'-color'}->{initial};
    $prop_value{$prop_name.'-width'}
        ||= $Prop->{$prop_name.'-width'}->{initial};
    $prop_value{$prop_name.'-style'}
        ||= $Prop->{$prop_name.'-style'}->{initial};
    
    return ($t, \%prop_value);
  },
  serialize_shorthand => sub {
    my $self = shift;

    my $w = $self->border_top_width;
    return {} unless length $w;
    my $i = $self->get_property_priority ('border-top-width');
    my $s = $self->border_top_style;
    return {} unless length $s;
    return {} unless $i eq $self->get_property_priority ('border-top-style');
    my $c = $self->border_top_color;
    return {} unless length $c;
    return {} unless $i eq $self->get_property_priority ('border-top-color');

    my $v = 0;
    $v++ if $w eq 'inherit';
    $v++ if $s eq 'inherit';
    $v++ if $c eq 'inherit';
    if ($v == 3) {
      return {'border-top' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    return {'border-top' => [$w . ' ' . $s . ' ' . $c, $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_top} = $Prop->{'border-top'};

$Prop->{'border-right'} = {
  css => 'border-right',
  dom => 'border_right',
  parse => $Prop->{'border-top'}->{parse},
  serialize_shorthand => sub {
    my $self = shift;

    my $w = $self->border_right_width;
    return {} unless length $w;
    my $i = $self->get_property_priority ('border-right-width');
    my $s = $self->border_right_style;
    return {} unless length $s;
    return {} unless $i eq $self->get_property_priority ('border-right-style');
    my $c = $self->border_right_color;
    return {} unless length $c;
    return {} unless $i eq $self->get_property_priority ('border-right-color');

    my $v = 0;
    $v++ if $w eq 'inherit';
    $v++ if $s eq 'inherit';
    $v++ if $c eq 'inherit';
    if ($v == 3) {
      return {'border-right' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    return {'border-right' => [$w . ' ' . $s . ' ' . $c, $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_right} = $Prop->{'border-right'};

$Prop->{'border-bottom'} = {
  css => 'border-bottom',
  dom => 'border_bottom',
  parse => $Prop->{'border-top'}->{parse},
  serialize_shorthand => sub {
    my $self = shift;

    my $w = $self->border_bottom_width;
    return {} unless length $w;
    my $i = $self->get_property_priority ('border-bottom-width');
    my $s = $self->border_bottom_style;
    return {} unless length $s;
    return {} unless $i eq $self->get_property_priority ('border-bottom-style');
    my $c = $self->border_bottom_color;
    return {} unless length $c;
    return {} unless $i eq $self->get_property_priority ('border-bottom-color');

    my $v = 0;
    $v++ if $w eq 'inherit';
    $v++ if $s eq 'inherit';
    $v++ if $c eq 'inherit';
    if ($v == 3) {
      return {'border-bottom' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    return {'border-bottom' => [$w . ' ' . $s . ' ' . $c, $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_bottom} = $Prop->{'border-bottom'};

$Prop->{'border-left'} = {
  css => 'border-left',
  dom => 'border_left',
  parse => $Prop->{'border-top'}->{parse},
  serialize_shorthand => sub {
    my $self = shift;

    my $w = $self->border_left_width;
    return {} unless length $w;
    my $i = $self->get_property_priority ('border-left-width');
    my $s = $self->border_left_style;
    return {} unless length $s;
    return {} unless $i eq $self->get_property_priority ('border-left-style');
    my $c = $self->border_left_color;
    return {} unless length $c;
    return {} unless $i eq $self->get_property_priority ('border-left-color');

    my $v = 0;
    $v++ if $w eq 'inherit';
    $v++ if $s eq 'inherit';
    $v++ if $c eq 'inherit';
    if ($v == 3) {
      return {'border-left' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    return {'border-left' => [$w . ' ' . $s . ' ' . $c, $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_left} = $Prop->{'border-left'};

## TODO: -moz-outline -> outline

$Prop->{outline} = {
  css => 'outline',
  dom => 'outline',
  parse => $Prop->{'border-top'}->{parse},
  serialize_multiple => $Prop->{'outline-color'}->{serialize_multiple},
};
$Attr->{outline} = $Prop->{outline};

$Prop->{border} = {
  css => 'border',
  dom => 'border',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;
    my $prop_value;
    ($t, $prop_value) = $Prop->{'border-top'}->{parse}
        ->($self, 'border-top', $tt, $t, $onerror);
    return ($t, undef) unless defined $prop_value;
    
    for (qw/border-right border-bottom border-left/) {
      $prop_value->{$_.'-color'} = $prop_value->{'border-top-color'}
          if defined $prop_value->{'border-top-color'};
      $prop_value->{$_.'-style'} = $prop_value->{'border-top-style'}
          if defined $prop_value->{'border-top-style'};
      $prop_value->{$_.'-width'} = $prop_value->{'border-top-width'}
          if defined $prop_value->{'border-top-width'};
    }
    return ($t, $prop_value);
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border} = $Prop->{border};

$Prop->{margin} = {
  css => 'margin',
  dom => 'margin',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;

    my $sign = 1;
    my $has_sign;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit}) {
        $prop_value{'margin-top'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-top'} = ['PERCENTAGE', $value];
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-top'} = ['DIMENSION', $value, 'px'];
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($prop_value eq 'auto') {
        $prop_value{'margin-top'} = ['KEYWORD', $prop_value];
      } elsif ($prop_value eq 'inherit') {
        $prop_value{'margin-top'} = ['INHERIT'];
        $prop_value{'margin-right'} = $prop_value{'margin-top'};
        $prop_value{'margin-bottom'} = $prop_value{'margin-top'};
        $prop_value{'margin-left'} = $prop_value{'margin-right'};
        return ($t, \%prop_value);
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }
    $prop_value{'margin-right'} = $prop_value{'margin-top'};
    $prop_value{'margin-bottom'} = $prop_value{'margin-top'};
    $prop_value{'margin-left'} = $prop_value{'margin-right'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    undef $has_sign;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit}) {
        $prop_value{'margin-right'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-right'} = ['PERCENTAGE', $value];
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-right'} = ['DIMENSION', $value, 'px'];
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($prop_value eq 'auto') {
        $prop_value{'margin-right'} = ['KEYWORD', $prop_value];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }
    $prop_value{'margin-left'} = $prop_value{'margin-right'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    undef $has_sign;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit}) {
        $prop_value{'margin-bottom'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-bottom'} = ['PERCENTAGE', $value];
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-bottom'} = ['DIMENSION', $value, 'px'];
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($prop_value eq 'auto') {
        $prop_value{'margin-bottom'} = ['KEYWORD', $prop_value];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    undef $has_sign;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit}) {
        $prop_value{'margin-left'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-left'} = ['PERCENTAGE', $value];
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'margin-left'} = ['DIMENSION', $value, 'px'];
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($prop_value eq 'auto') {
        $prop_value{'margin-left'} = ['KEYWORD', $prop_value];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    return ($t, \%prop_value);
  },
  serialize_multiple => $Prop->{'margin-top'}->{serialize_multiple},
};
$Attr->{margin} = $Prop->{margin};

$Prop->{padding} = {
  css => 'padding',
  dom => 'padding',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;

    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit} and $value >= 0) {
        $prop_value{'padding-top'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-top'} = ['PERCENTAGE', $value];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-top'} = ['DIMENSION', $value, 'px'];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($sign > 0 and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      $t = $tt->get_next_token;
      if ($prop_value eq 'inherit') {
        $prop_value{'padding-top'} = ['INHERIT'];
        $prop_value{'padding-right'} = $prop_value{'padding-top'};
        $prop_value{'padding-bottom'} = $prop_value{'padding-top'};
        $prop_value{'padding-left'} = $prop_value{'padding-right'};
        return ($t, \%prop_value);
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }
    $prop_value{'padding-right'} = $prop_value{'padding-top'};
    $prop_value{'padding-bottom'} = $prop_value{'padding-top'};
    $prop_value{'padding-left'} = $prop_value{'padding-right'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit} and $value >= 0) {
        $prop_value{'padding-right'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-right'} = ['PERCENTAGE', $value];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-right'} = ['DIMENSION', $value, 'px'];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($sign < 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }
    $prop_value{'padding-left'} = $prop_value{'padding-right'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit} and $value >= 0) {
        $prop_value{'padding-bottom'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-bottom'} = ['PERCENTAGE', $value];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-bottom'} = ['DIMENSION', $value, 'px'];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($sign < 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $sign = -1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      $t = $tt->get_next_token;
      if ($length_unit->{$unit} and $value >= 0) {
        $prop_value{'padding-left'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-left'} = ['PERCENTAGE', $value];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'padding-left'} = ['DIMENSION', $value, 'px'];
      unless ($value >= 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($sign < 0) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    return ($t, \%prop_value);
  },
  serialize_multiple => $Prop->{'padding-top'}->{serialize_multiple},
};
$Attr->{padding} = $Prop->{padding};

$Prop->{'border-spacing'} = {
  css => 'border-spacing',
  dom => 'border_spacing',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;
    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'-manakai-border-spacing-x'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $prop_value{'-manakai-border-spacing-x'} = ['DIMENSION', $value, 'px'];
      if ($value >= 0) {
        $t = $tt->get_next_token;
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      if ($prop_value eq 'inherit') {
        $t = $tt->get_next_token;
        $prop_value{'-manakai-border-spacing-x'} = ['INHERIT'];
        $prop_value{'-manakai-border-spacing-y'}
            = $prop_value{'-manakai-border-spacing-x'};
        return ($t, \%prop_value);
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }
    $prop_value{'-manakai-border-spacing-y'}
        = $prop_value{'-manakai-border-spacing-x'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    undef $has_sign;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'-manakai-border-spacing-y'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $prop_value{'-manakai-border-spacing-y'} = ['DIMENSION', $value, 'px'];
      if ($value >= 0) {
        $t = $tt->get_next_token;
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    return ($t, \%prop_value);
  },
  serialize_multiple => $Prop->{'-manakai-border-spacing-x'}
      ->{serialize_multiple},
};
$Attr->{border_spacing} = $Prop->{'border-spacing'};

## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/background-position> for
## browser compatibility problems.
$Prop->{'background-position'} = {
  css => 'background-position',
  dom => 'background_position',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;

    my $sign = 1;
    my $has_sign;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit}) {
        $t = $tt->get_next_token;
        $prop_value{'background-position-x'} = ['DIMENSION', $value, $unit];
        $prop_value{'background-position-y'} = ['PERCENTAGE', 50];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'background-position-x'} = ['PERCENTAGE', $value];
      $prop_value{'background-position-y'} = ['PERCENTAGE', 50];
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'background-position-x'} = ['DIMENSION', $value, 'px'];
      $prop_value{'background-position-y'} = ['PERCENTAGE', 50];
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      if ($prop_value eq 'left' or $prop_value eq 'right') {
        $t = $tt->get_next_token;
        $prop_value{'background-position-x'} = ['KEYWORD', $prop_value];
        $prop_value{'background-position-y'} = ['KEYWORD', 'center'];
      } elsif ($prop_value eq 'center') {
        $t = $tt->get_next_token;
        $prop_value{'background-position-x'} = ['KEYWORD', $prop_value];

        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == IDENT_TOKEN) {
          my $prop_value = lc $t->{value}; ## TODO: case folding
          if ($prop_value eq 'left' or $prop_value eq 'right') {
            $prop_value{'background-position-y'}
                = $prop_value{'background-position-x'};
            $prop_value{'background-position-x'} = ['KEYWORD', $prop_value];
            $t = $tt->get_next_token;
            return ($t, \%prop_value);
          }
        } else {
          $prop_value{'background-position-y'} = ['KEYWORD', 'center'];
        }
      } elsif ($prop_value eq 'top' or $prop_value eq 'bottom') {
        $t = $tt->get_next_token;
        $prop_value{'background-position-y'} = ['KEYWORD', $prop_value];

        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == IDENT_TOKEN) {
          my $prop_value = lc $t->{value}; ## TODO: case folding
          if ({left => 1, center => 1, right => 1}->{$prop_value}) {
            $prop_value{'background-position-x'} = ['KEYWORD', $prop_value];
            $t = $tt->get_next_token;
            return ($t, \%prop_value);
          }
        }
        $prop_value{'background-position-x'} = ['KEYWORD', 'center'];
        return ($t, \%prop_value);
      } elsif ($prop_value eq 'inherit') {
        $t = $tt->get_next_token;
        $prop_value{'background-position-x'} = ['INHERIT'];
        $prop_value{'background-position-y'} = ['INHERIT'];
        return ($t, \%prop_value);
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    undef $has_sign;
    $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit}) {
        $t = $tt->get_next_token;
        $prop_value{'background-position-y'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == PERCENTAGE_TOKEN) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'background-position-y'} = ['PERCENTAGE', $value];
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      $t = $tt->get_next_token;
      $prop_value{'background-position-y'} = ['DIMENSION', $value, 'px'];
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ({top => 1, center => 1, bottom => 1}->{$value}) {
        $prop_value{'background-position-y'} = ['KEYWORD', $value];
        $t = $tt->get_next_token;
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    return ($t, \%prop_value);
  },
  serialize_shorthand => sub {
    my $self = shift;

    my $r = {};

    my $x = $self->background_position_x;
    my $y = $self->background_position_y;
    my $xi = $self->get_property_priority ('background-position-x');
    my $yi = $self->get_property_priority ('background-position-y');
    if (length $x) {
      if (length $y) {
        if ($xi eq $yi) {
          if ($x eq 'inherit') {
            if ($y eq 'inherit') {
              $r->{'background-position'} = ['inherit', $xi];
            } else {
              $r->{'background-position-x'} = [$x, $xi];
              $r->{'background-position-y'} = [$y, $yi];
            }
          } elsif ($y eq 'inherit') {
            $r->{'background-position-x'} = [$x, $xi];
            $r->{'background-position-y'} = [$y, $yi];
          } else {
            $r->{'background-position'} = [$x . ' ' . $y, $xi];
          }
        } else {
          $r->{'background-position-x'} = [$x, $xi];
          $r->{'background-position-y'} = [$y, $yi];
        }
      } else {
        $r->{'background-position-x'} = [$x, $xi];
      }
    } else {
      if (length $y) {
        $r->{'background-position-y'} = [$y, $yi];
      } else {
        #
      }
    }

    return $r;
  },
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
};
$Attr->{background_position} = $Prop->{'background-position'};

$Prop->{background} = {
  css => 'background',
  dom => 'background',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;
    my %prop_value;
    B: for (1..5) {
      my $has_sign;
      my $sign = 1;
      if ($t->{type} == MINUS_TOKEN) {
        $sign = -1;
        $has_sign = 1;
        $t = $tt->get_next_token;
      } elsif ($t->{type} == PLUS_TOKEN) {
        $has_sign = 1;
        $t = $tt->get_next_token;
      }

      if (not $has_sign and $t->{type} == IDENT_TOKEN) {
        my $value = lc $t->{value}; ## TODO: case
        if ($Prop->{'background-repeat'}->{keyword}->{$value} and
            $self->{prop_value}->{'background-repeat'}->{$value} and
            not defined $prop_value{'background-repeat'}) {
          $prop_value{'background-repeat'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } elsif ($Prop->{'background-attachment'}->{keyword}->{$value} and
                 $self->{prop_value}->{'background-attachment'}->{$value} and
                 not defined $prop_value{'background-attachment'}) {
          $prop_value{'background-attachment'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } elsif ($value eq 'none' and
                 not defined $prop_value{'background-image'}) {
          $prop_value{'background-image'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } elsif ({left => 1, center => 1, right => 1}->{$value} and
                 not defined $prop_value{'background-position-x'}) {
          $prop_value{'background-position-x'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          my $sign = 1;
          my $has_sign;
          if ($t->{type} == MINUS_TOKEN) {
            $sign = -1;
            $has_sign = 1;
            $t = $tt->get_next_token;
          } elsif ($t->{type} == PLUS_TOKEN) {
            $has_sign = 1;
            $t = $tt->get_next_token;
          }
          if (not $has_sign and $t->{type} == IDENT_TOKEN) {
            my $value = lc $t->{value}; ## TODO: case
            if ({top => 1, bottom => 1, center => 1}->{$value}) {
              $prop_value{'background-position-y'} = ['KEYWORD', $value];
              $t = $tt->get_next_token;
            } elsif ($prop_value{'background-position-x'}->[1] eq 'center' and
                     $value eq 'left' or $value eq 'right') {
              $prop_value{'background-position-y'} = ['KEYWORD', 'center'];
              $prop_value{'background-position-x'} = ['KEYWORD', $value];
              $t = $tt->get_next_token;
            } else {
              $prop_value{'background-position-y'} = ['KEYWORD', 'center'];
            }
          } elsif ($t->{type} == DIMENSION_TOKEN) {
            my $value = $t->{number} * $sign;
            my $unit = lc $t->{value}; ## TODO: case
            $t = $tt->get_next_token;
            if ($length_unit->{$unit}) {
              $prop_value{'background-position-y'}
                  = ['DIMENSION', $value, $unit];
            } else {
              $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                         level => $self->{level}->{must},
                         uri => \$self->{href},
                         token => $t);
              return ($t, undef);
            }
          } elsif ($t->{type} == PERCENTAGE_TOKEN) {
            my $value = $t->{number} * $sign;
            $t = $tt->get_next_token;
            $prop_value{'background-position-y'} = ['PERCENTAGE', $value];
          } elsif ($t->{type} == NUMBER_TOKEN and
                   ($self->{unitless_px} or $t->{number} == 0)) {
            my $value = $t->{number} * $sign;
            $t = $tt->get_next_token;
            $prop_value{'background-position-y'} = ['DIMENSION', $value, 'px'];
          } elsif ($has_sign) {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          } else {
            $prop_value{'background-position-y'} = ['KEYWORD', 'center'];
          }
        } elsif (($value eq 'top' or $value eq 'bottom') and
                 not defined $prop_value{'background-position-y'}) {
          $prop_value{'background-position-y'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          if ($t->{type} == IDENT_TOKEN and ## TODO: case
              {
                left => 1, center => 1, right => 1,
              }->{my $value = lc $t->{value}}) {
            $prop_value{'background-position-x'} = ['KEYWORD', $value];
            $t = $tt->get_next_token;
          } else {
            $prop_value{'background-position-x'} = ['KEYWORD', 'center'];
          }
        } elsif ($value eq 'inherit' and not keys %prop_value) {
          $prop_value{'background-color'} =
          $prop_value{'background-image'} =
          $prop_value{'background-repeat'} =
          $prop_value{'background-attachment'} = 
          $prop_value{'background-position-x'} =
          $prop_value{'background-position-y'} = ['INHERIT'];
          $t = $tt->get_next_token;
          return ($t, \%prop_value);
        } elsif (not defined $prop_value{'background-color'} or
                 not keys %prop_value) {
          ($t, my $pv) = $parse_color->($self, 'background', $tt, $t,
                                        $onerror);
          if (defined $pv) {
            $prop_value{'background-color'} = $pv->{background};
          } else {
            ## NOTE: An error should already be raiased.
            return ($t, undef);
          }
        }
      } elsif (($t->{type} == DIMENSION_TOKEN or
                $t->{type} == PERCENTAGE_TOKEN or
                ($t->{type} == NUMBER_TOKEN and
                 ($t->{unitless_px} or $t->{number} == 0))) and
               not defined $prop_value{'background-position-x'}) {
        if ($t->{type} == DIMENSION_TOKEN) {
          my $value = $t->{number} * $sign;
          my $unit = lc $t->{value}; ## TODO: case
          $t = $tt->get_next_token;
          if ($length_unit->{$unit}) {
            $prop_value{'background-position-x'}
                = ['DIMENSION', $value, $unit];
          } else {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        } elsif ($t->{type} == PERCENTAGE_TOKEN) {
          my $value = $t->{number} * $sign;
          $t = $tt->get_next_token;
          $prop_value{'background-position-x'} = ['PERCENTAGE', $value];
        } elsif ($t->{type} == NUMBER_TOKEN and
                 ($self->{unitless_px} or $t->{number} == 0)) {
          my $value = $t->{number} * $sign;
          $t = $tt->get_next_token;
          $prop_value{'background-position-x'} = ['DIMENSION', $value, 'px'];
        } else {
          ## NOTE: Should not be happened.
          last B;
        }
        
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == MINUS_TOKEN) {
          $sign = -1;
          $has_sign = 1;
          $t = $tt->get_next_token;
        } elsif ($t->{type} == PLUS_TOKEN) {
          $has_sign = 1;
          $t = $tt->get_next_token;
        } else {
          undef $has_sign;
          $sign = 1;
        }

        if ($t->{type} == DIMENSION_TOKEN) {
          my $value = $t->{number} * $sign;
          my $unit = lc $t->{value}; ## TODO: case
          $t = $tt->get_next_token;
          if ($length_unit->{$unit}) {
            $prop_value{'background-position-y'}
                = ['DIMENSION', $value, $unit];
          } else {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        } elsif ($t->{type} == PERCENTAGE_TOKEN) {
          my $value = $t->{number} * $sign;
          $t = $tt->get_next_token;
          $prop_value{'background-position-y'} = ['PERCENTAGE', $value];
        } elsif ($t->{type} == NUMBER_TOKEN and
                 ($self->{unitless_px} or $t->{number} == 0)) {
          my $value = $t->{number} * $sign;
          $t = $tt->get_next_token;
          $prop_value{'background-position-y'} = ['DIMENSION', $value, 'px'];
        } elsif ($t->{type} == IDENT_TOKEN) {
          my $value = lc $t->{value}; ## TODO: case
          if ({top => 1, center => 1, bottom => 1}->{$value}) {
            $prop_value{'background-position-y'} = ['KEYWORD', $value];
            $t = $tt->get_next_token;
          } else {
            $prop_value{'background-position-y'} = ['PERCENTAGE', 50];
          }
        } else {
          $prop_value{'background-position-y'} = ['PERCENTAGE', 50];
          if ($has_sign) {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        }
      } elsif (not $has_sign and
               $t->{type} == URI_TOKEN and
               not defined $prop_value{'background-image'}) {
        $prop_value{'background-image'}
            = ['URI', $t->{value}, \($self->{base_uri})];
        $t = $tt->get_next_token;
      } else {
        if (keys %prop_value and not $has_sign) {
          last B;
        } else {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          return ($t, undef);
        }
      }

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    } # B

    $prop_value{$_} ||= $Prop->{$_}->{initial}
        for qw/background-image background-attachment background-repeat
               background-color background-position-x background-position-y/;

    return ($t, \%prop_value);
  },
## TODO: background: #fff does not work.
  serialize_multiple => $Prop->{'background-color'}->{serialize_multiple},
};
$Attr->{background} = $Prop->{background};

$Prop->{font} = {
  css => 'font',
  dom => 'font',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;

    A: for (1..3) {
      if ($t->{type} == IDENT_TOKEN) {
        my $value = lc $t->{value}; ## TODO: case
        if ($value eq 'normal') {
          $t = $tt->get_next_token;
        } elsif ($Prop->{'font-style'}->{keyword}->{$value} and
                 $self->{prop_value}->{'font-style'}->{$value} and
                 not defined $prop_value{'font-style'}) {
          $prop_value{'font-style'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } elsif ($Prop->{'font-variant'}->{keyword}->{$value} and
                 $self->{prop_value}->{'font-variant'}->{$value} and
                 not defined $prop_value{'font-variant'}) {
          $prop_value{'font-variant'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } elsif ({normal => 1, bold => 1,
                  bolder => 1, lighter => 1}->{$value} and
                 not defined $prop_value{'font-weight'}) {
          $prop_value{'font-weight'} = ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } elsif ($value eq 'inherit' and 0 == keys %prop_value) {
          $t = $tt->get_next_token;
          return ($t, {'font-style' => ['INHERIT'],
                       'font-variant' => ['INHERIT'],
                       'font-weight' => ['INHERIT'],
                       'font-size' => ['INHERIT'],
                       'font-size-adjust' => ['INHERIT'],
                       'font-stretch' => ['INHERIT'],
                       'line-height' => ['INHERIT'],
                       'font-family' => ['INHERIT']});
        } elsif ({
                  caption => 1, icon => 1, menu => 1, 
                  'message-box' => 1, 'small-caption' => 1, 'status-bar' => 1,
                 }->{$value} and 0 == keys %prop_value) {
          $t = $tt->get_next_token;
          return ($t, $self->{get_system_font}->($self, $value, {
            'font-style' => $Prop->{'font-style'}->{initial},
            'font-variant' => $Prop->{'font-variant'}->{initial},
            'font-weight' => $Prop->{'font-weight'}->{initial},
            'font-size' => $Prop->{'font-size'}->{initial},
            'font-size-adjust' => $Prop->{'font-size-adjust'}->{initial},
            'font-stretch' => $Prop->{'font-stretch'}->{initial},
            'line-height' => $Prop->{'line-height'}->{initial},
            'font-family' => ['FONT', ['KEYWORD', '-manakai-'.$value]],
          }));
        } else {
          if (keys %prop_value) {
            last A;
          } else {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        }
      } elsif ($t->{type} == NUMBER_TOKEN) {
        if ({100 => 1, 200 => 1, 300 => 1, 400 => 1, 500 => 1,
             600 => 1, 700 => 1, 800 => 1, 900 => 1}->{$t->{number}}) {
          $prop_value{'font-weight'} = ['WEIGHT', $t->{number}, 0];
          $t = $tt->get_next_token;
        } else {
          last A;
        }
      } elsif ($t->{type} == PLUS_TOKEN) {
        $t = $tt->get_next_token;
        if ($t->{type} == NUMBER_TOKEN) {
          if ({100 => 1, 200 => 1, 300 => 1, 400 => 1, 500 => 1,
               600 => 1, 700 => 1, 800 => 1, 900 => 1}->{$t->{number}}) {
            $prop_value{'font-weight'} = ['WEIGHT', $t->{number}, 0];
            $t = $tt->get_next_token;
          } else {
            ## NOTE: <'font-size'> or invalid
            last A;
          }
        } elsif ($t->{type} == DIMENSION_TOKEN or
                 $t->{type} == PERCENTAGE_TOKEN) {
          ## NOTE: <'font-size'> or invalid
          last A;
        } else {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          return ($t, undef);
        }
      } else {
        last A;
      }

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    } # A
    
    for (qw/font-style font-variant font-weight/) {
      $prop_value{$_} = $Prop->{$_}->{initial} unless defined $prop_value{$_};
    }
      
    ($t, my $pv) = $Prop->{'font-size'}->{parse}
        ->($self, 'font', $tt, $t, $onerror);
    return ($t, undef) unless defined $pv;
    if ($pv->{font}->[0] eq 'INHERIT') {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }
    $prop_value{'font-size'} = $pv->{font};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == DELIM_TOKEN and $t->{value} eq '/') {
      $t = $tt->get_next_token;
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      ($t, my $pv) = $Prop->{'line-height'}->{parse}
          ->($self, 'font', $tt, $t, $onerror);
      return ($t, undef) unless defined $pv;
      if ($pv->{font}->[0] eq 'INHERIT') {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      $prop_value{'line-height'} = $pv->{font};
      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    } else {
      $prop_value{'line-height'} = $Prop->{'line-height'}->{initial};
    }

    undef $pv;
    ($t, $pv) = $Prop->{'font-family'}->{parse}
        ->($self, 'font', $tt, $t, $onerror);
    return ($t, undef) unless defined $pv;
    $prop_value{'font-family'} = $pv->{font};

    $prop_value{'font-size-adjust'} = $Prop->{'font-size-adjust'}->{initial};
    $prop_value{'font-stretch'} = $Prop->{'font-stretch'}->{initial};

    return ($t, \%prop_value);
  },
  serialize_shorthand => sub {
    my $self = shift;
    
    local $Error::Depth = $Error::Depth + 1;
    my $style = $self->font_style;
    my $i = $self->get_property_priority ('font-style');
    return {} unless length $style;
    my $variant = $self->font_variant;
    return {} unless length $variant;
    return {} if $i ne $self->get_property_priority ('font-variant');
    my $weight = $self->font_weight;
    return {} unless length $weight;
    return {} if $i ne $self->get_property_priority ('font-weight');
    my $size = $self->font_size;
    return {} unless length $size;
    return {} if $i ne $self->get_property_priority ('font-size');
    my $height = $self->line_height;
    return {} unless length $height;
    return {} if $i ne $self->get_property_priority ('line-height');
    my $family = $self->font_family;
    return {} unless length $family;
    return {} if $i ne $self->get_property_priority ('font-family');

    my $v = 0;
    for ($style, $variant, $weight, $size, $height, $family) {
      $v++ if $_ eq 'inherit';
    }
    if ($v == 6) {
      return {font => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }
    
    my @v;
    push @v, $style unless $style eq 'normal';
    push @v, $variant unless $variant eq 'normal';
    push @v, $weight unless $weight eq 'normal';
    push @v, $size.($height eq 'normal' ? '' : '/'.$height);
    push @v, $family;
    return {font => [(join ' ', @v), $i]};
  },
};
$Attr->{font} = $Prop->{font};

$Prop->{'border-width'} = {
  css => 'border-width',
  dom => 'border_width',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my %prop_value;

    my $has_sign;
    my $sign = 1;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $prop_value{'border-top-width'} = ['DIMENSION', $value, $unit];
        $t = $tt->get_next_token;
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      if ($value >= 0) {
        $prop_value{'border-top-width'} = ['DIMENSION', $value, 'px'];
        $t = $tt->get_next_token;
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case folding
      if ({thin => 1, medium => 1, thick => 1}->{$prop_value}) {
        $t = $tt->get_next_token;
        $prop_value{'border-top-width'} = ['KEYWORD', $prop_value];
      } elsif ($prop_value eq 'inherit') {
        $t = $tt->get_next_token;
        $prop_value{'border-top-width'} = ['INHERIT'];
        $prop_value{'border-right-width'} = $prop_value{'border-top-width'};
        $prop_value{'border-bottom-width'} = $prop_value{'border-top-width'};
        $prop_value{'border-left-width'} = $prop_value{'border-right-width'};
        return ($t, \%prop_value);
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } else {
      $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                 level => $self->{level}->{must},
                 uri => \$self->{href},
                 token => $t);
      return ($t, undef);
    }
    $prop_value{'border-right-width'} = $prop_value{'border-top-width'};
    $prop_value{'border-bottom-width'} = $prop_value{'border-top-width'};
    $prop_value{'border-left-width'} = $prop_value{'border-right-width'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = 1;
    } else {
      undef $has_sign;
      $sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'border-right-width'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      if ($value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'border-right-width'} = ['DIMENSION', $value, 'px'];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case
      if ({thin => 1, medium => 1, thick => 1}->{$prop_value}) {
        $prop_value{'border-right-width'} = ['KEYWORD', $prop_value];
        $t = $tt->get_next_token;
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }
    $prop_value{'border-left-width'} = $prop_value{'border-right-width'};

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = 1;
    } else {
      undef $has_sign;
      $sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'border-bottom-width'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      if ($value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'border-bottom-width'} = ['DIMENSION', $value, 'px'];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case
      if ({thin => 1, medium => 1, thick => 1}->{$prop_value}) {
        $prop_value{'border-bottom-width'} = ['KEYWORD', $prop_value];
        $t = $tt->get_next_token;
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    $t = $tt->get_next_token while $t->{type} == S_TOKEN;
    if ($t->{type} == MINUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = -1;
    } elsif ($t->{type} == PLUS_TOKEN) {
      $t = $tt->get_next_token;
      $has_sign = 1;
      $sign = 1;
    } else {
      undef $has_sign;
      $sign = 1;
    }

    if ($t->{type} == DIMENSION_TOKEN) {
      my $value = $t->{number} * $sign;
      my $unit = lc $t->{value}; ## TODO: case
      if ($length_unit->{$unit} and $value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'border-left-width'} = ['DIMENSION', $value, $unit];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif ($t->{type} == NUMBER_TOKEN and
             ($self->{unitless_px} or $t->{number} == 0)) {
      my $value = $t->{number} * $sign;
      if ($value >= 0) {
        $t = $tt->get_next_token;
        $prop_value{'border-left-width'} = ['DIMENSION', $value, 'px'];
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
      my $prop_value = lc $t->{value}; ## TODO: case
      if ({thin => 1, medium => 1, thick => 1}->{$prop_value}) {
        $prop_value{'border-left-width'} = ['KEYWORD', $prop_value];
        $t = $tt->get_next_token;
      }
    } else {
      if ($has_sign) {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
      return ($t, \%prop_value);
    }

    return ($t, \%prop_value);
  },
  serialize_shorthand => sub {
    my $self = shift;

    my @v;
    push @v, $self->border_top_width;
    my $i = $self->get_property_priority ('border-top-width');
    return {} unless length $v[-1];
    push @v, $self->border_right_width;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-right-width');
    push @v, $self->border_bottom_width;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-bottom-width');
    push @v, $self->border_left_width;
    return {} unless length $v[-1];
    return {} unless $i eq $self->get_property_priority ('border-left-width');

    my $v = 0;
    for (0..3) {
      $v++ if $v[$_] eq 'inherit';
    }
    if ($v == 4) {
      return {'border-width' => ['inherit', $i]};
    } elsif ($v) {
      return {};
    }

    pop @v if $v[1] eq $v[3];
    pop @v if $v[0] eq $v[2];
    pop @v if $v[0] eq $v[1];
    return {'border-width' => [(join ' ', @v), $i]};
  },
  serialize_multiple => $Prop->{'border-top-color'}->{serialize_multiple},
};
$Attr->{border_width} = $Prop->{'border-width'};

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
            $onerror->(type => 'CSS duplication', text => "'list-style-type'",
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          } else {
            $prop_value{'list-style-type'} = ['KEYWORD', $prop_value];
          }
        } elsif ($Prop->{'list-style-position'}->{keyword}->{$prop_value}) {
          if (exists $prop_value{'list-style-position'}) {
            $onerror->(type => 'CSS duplication',
                       text => "'list-style-position'",
                       level => $self->{level}->{must},
                       uri => \$self->{href},
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
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          } else {
            last F;
          }
        }
      } elsif ($t->{type} == URI_TOKEN) {
        if (exists $prop_value{'list-style-image'}) {
          $onerror->(type => 'CSS duplication', text => "'list-style-image'",
                     uri => \$self->{href},
                     level => $self->{level}->{must},
                     token => $t);
          return ($t, undef);
        }
        
        $prop_value{'list-style-image'}
            = ['URI', $t->{value}, \($self->{base_uri})];
        $t = $tt->get_next_token;
      } else {
        if ($f == 1) {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
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
          $onerror->(type => 'CSS duplication', text => "'list-style-image'",
                     uri => \$self->{href},
                     level => $self->{level}->{must},
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
        $onerror->(type => 'CSS duplication', text => "'list-style-type'",
                   uri => \$self->{href},
                   level => $self->{level}->{must},
                   token => $t);
        return ($t, undef);
      }
      if (exists $prop_value{'list-style-image'}) {
        $onerror->(type => 'CSS duplication', text => "'list-style-image'",
                   uri => \$self->{href},
                   level => $self->{level}->{must},
                   token => $t);
        return ($t, undef);
      }
      
      $prop_value{'list-style-type'} = ['KEYWORD', 'none'];
      $prop_value{'list-style-image'} = ['KEYWORD', 'none'];
    } elsif ($none == 3) {
      $onerror->(type => 'CSS duplication', text => "'list-style-type'",
                 uri => \$self->{href},
                 level => $self->{level}->{must},
                 token => $t);
      return ($t, undef);
    }

    for (qw/list-style-type list-style-position list-style-image/) {
      $prop_value{$_} = $Prop->{$_}->{initial} unless exists $prop_value{$_};
    }

    return ($t, \%prop_value);
  },
  ## NOTE: We don't merge longhands in |css_text| serialization,
  ## since no browser does.
  serialize_shorthand => sub {
    my $self = shift;

    ## NOTE: Don't omit any value even if it is the initial value,
    ## since WinIE is buggy.
    
    my $type = $self->list_style_type;
    return {} unless length $type;
    my $type_i = $self->get_property_priority ('list-style-type');
    my $image = $self->list_style_image;
    return {} unless length $image;
    my $image_i = $self->get_property_priority ('list-style-image');
    return {} unless $type_i eq $image_i;
    my $position = $self->list_style_position;
    return {} unless length $position;
    my $position_i = $self->get_property_priority ('list-style-position');
    return {} unless $type_i eq $position_i;

    return {'list-style' => [$type . ' ' . $image . ' ' . $position, $type_i]};
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
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
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
  initial => ["KEYWORD", "none"],
  #inherited => 0,
  compute => $compute_as_specified,
};
$Attr->{text_decoration} = $Prop->{'text-decoration'};
$Key->{text_decoration} = $Prop->{'text-decoration'};

$Attr->{quotes} =
$Key->{quotes} =
$Prop->{quotes} = {
  css => 'quotes',
  dom => 'quotes',
  key => 'quotes',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    my @v;
    A: {
      if ($t->{type} == STRING_TOKEN) {
        my $open = $t->{value};
        $t = $tt->get_next_token;

        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == STRING_TOKEN) {
          push @v, [$open, $t->{value}];
          $t = $tt->get_next_token;
        } else {
          last A;
        }
      } elsif (not @v and $t->{type} == IDENT_TOKEN) {
        my $value = lc $t->{value}; ## TODO: case
        if ($value eq 'none' or $value eq '-manakai-default') {
          $t = $tt->get_next_token;
          return ($t, {$prop_name => ['KEYWORD', $value]});
        } elsif ($value eq 'inherit') {
          $t = $tt->get_next_token;
          return ($t, {$prop_name => ['INHERIT']});
        } else {
          last A;
        }
      } else {
        if (@v) {
          return ($t, {$prop_name => ['QUOTES', \@v]});
        } else {
          last A;
        }
      }

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      redo A;
    }
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', '-manakai-default'],
  inherited => 1,
  compute => $compute_as_specified,
};

$Attr->{content} =
$Key->{content} =
$Prop->{content} = {
  css => 'content',
  dom => 'content',
  key => 'content',
  ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/content>.
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'normal' or $value eq 'none') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', $value]});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }
    
    my @v;
    A: {
      if ($t->{type} == IDENT_TOKEN) {
        my $value = lc $t->{value}; ## TODO: case
        if ({qw/open-quote 1 close-quote 1
                no-open-quote 1 no-close-quote 1/}->{$value} and
            $self->{prop}->{quotes}) {
          push @v, ['KEYWORD', $value];
          $t = $tt->get_next_token;
        } else {
          last A;
        }
      } elsif ($t->{type} == STRING_TOKEN) {
        push @v, ['STRING', $t->{value}];
        $t = $tt->get_next_token;
      } elsif ($t->{type} == URI_TOKEN) {
        push @v, ['URI', $t->{value}, \($self->{base_uri})];
        $t = $tt->get_next_token;
      } elsif ($t->{type} == FUNCTION_TOKEN) {
        my $name = lc $t->{value}; ## TODO: case
        if ($name eq 'attr') {
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          if ($t->{type} == IDENT_TOKEN) {
            my $t_pfx;
            my $t_ln = $t;
            $t = $tt->get_next_token;
            if ($t->{type} == VBAR_TOKEN) {
              $t = $tt->get_next_token;
              if ($t->{type} == IDENT_TOKEN) {
                $t_pfx = $t_ln;
                $t_ln = $t;
                $t = $tt->get_next_token;
              } else {
                last A;
              }
            }
            
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == RPAREN_TOKEN) {
              if (defined $t_pfx) {
                my $pfx = $t_pfx->{value};
                my $uri = $self->{lookup_namespace_uri}->($pfx);
                unless (defined $uri) {
                  $self->{onerror}->(type => 'namespace prefix:not declared',
                                     level => $self->{level}->{must},
                                     uri => \$self->{href},
                                     token => $t_pfx,
                                     value => $pfx);
                  return ($t, undef);
                }
                undef $uri unless length $uri;
                push @v, ['ATTR', $uri, $t_ln->{value}];
              } else {
                push @v, ['ATTR', undef, $t_ln->{value}];
              }
              $t = $tt->get_next_token;
            } else {
              last A;
            }
          } elsif ($t->{type} == VBAR_TOKEN) {
            $t = $tt->get_next_token;
            my $t_ln;
            if ($t->{type} == IDENT_TOKEN) {
              $t_ln = $t;
              $t = $tt->get_next_token;
            } else {
              last A;
            }
            
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == RPAREN_TOKEN) {
              push @v, ['ATTR', undef, $t_ln->{value}];
              $t = $tt->get_next_token;
            } else {
              last A;
            }
          } else {
            last A;
          }
        } elsif (($name eq 'counter' or $name eq 'counters') and
                 $self->{prop}->{'counter-reset'}) {
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          if ($t->{type} == IDENT_TOKEN) {
            my $t_id = $t;
            my $t_str;
            my $type;
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == COMMA_TOKEN) {
              $t = $tt->get_next_token;
              $t = $tt->get_next_token while $t->{type} == S_TOKEN;
              if ($name eq 'counters' and $t->{type} == STRING_TOKEN) {
                $t_str = $t;
                $t = $tt->get_next_token;
                $t = $tt->get_next_token while $t->{type} == S_TOKEN;
                if ($t->{type} == COMMA_TOKEN) {
                  $t = $tt->get_next_token;
                  $t = $tt->get_next_token while $t->{type} == S_TOKEN;
                  if ($t->{type} == IDENT_TOKEN) {
                    $type = lc $t->{value}; ## TODO: value
                    if ($Prop->{'list-style-type'}->{keyword}->{$type}) {
                      $t = $tt->get_next_token;
                    } else {
                      last A;
                    }
                  } else {
                    last A;
                  }
                }
              } elsif ($name eq 'counter' and $t->{type} == IDENT_TOKEN) {
                $type = lc $t->{value}; ## TODO: value
                if ($Prop->{'list-style-type'}->{keyword}->{$type}) {
                  $t = $tt->get_next_token;
                } else {
                  last A;
                }
              } else {
                last A;
              }
            } elsif ($name eq 'counters') {
              last A;
            }
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
            if ($t->{type} == RPAREN_TOKEN) {
              push @v, [uc $name, ## |COUNTER| or |COUNTERS|
                        $t_id->{value},
                        defined $t_str ? $t_str->{value} : undef,
                        defined $type ? $type : 'decimal'];
              $t = $tt->get_next_token;
            } else {
              last A;
            }
          } else {
            last A;
          }
        } else {
          last A;
        }
      } else {
        unshift @v, 'CONTENT';
        return ($t, {$prop_name => \@v});
      }

      $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      redo A;
    } # A

    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'normal'],
  #inherited => 0,
  compute => $compute_as_specified,
      ## NOTE: This is what Opera 9 does, except for 'normal' -> 'none'.
      ## TODO: 'normal' -> 'none' for ::before and ::after [CSS 2.1]
};

$Attr->{counter_reset} =
$Key->{counter_reset} =
$Prop->{'counter-reset'} = {
  css => 'counter-reset',
  dom => 'counter_reset',
  key => 'counter_reset',
  ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/counter-reset>.
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    ## NOTE: For 'counter-increment' and 'counter-reset'.

    my @v = ($prop_name eq 'counter-increment' ? 'ADDCOUNTER' : 'SETCOUNTER');
    B: {
      if ($t->{type} == IDENT_TOKEN) {
        my $value = $t->{value};
        my $lcvalue = lc $value; ## TODO: case
        last B if $lcvalue ne 'inherit' and $lcvalue ne 'none';
        
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == IDENT_TOKEN) {
          push @v, [$value, $prop_name eq 'counter-increment' ? 1 : 0];
        } elsif ($t->{type} == NUMBER_TOKEN) {
          push @v, [$value, int $t->{number}];
          $t = $tt->get_next_token;
        } elsif ($t->{type} == PLUS_TOKEN) {
          $t = $tt->get_next_token;
          if ($t->{type} == NUMBER_TOKEN) {
            push @v, [$value, int $t->{number}];
            $t = $tt->get_next_token;
          } else {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        } elsif ($t->{type} == MINUS_TOKEN) {
          $t = $tt->get_next_token;
          if ($t->{type} == NUMBER_TOKEN) {
            push @v, [$value, -int $t->{number}];
            $t = $tt->get_next_token;
          } else {
            $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                       level => $self->{level}->{must},
                       uri => \$self->{href},
                       token => $t);
            return ($t, undef);
          }
        } else {
          if ($lcvalue eq 'none') {
            return ($t, {$prop_name => ['KEYWORD', $lcvalue]});
          } elsif ($lcvalue eq 'inherit') {
            return ($t, {$prop_name => ['INHERIT']});
          } else {
            last B;
          }
        }
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
      } else {
        $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                   level => $self->{level}->{must},
                   uri => \$self->{href},
                   token => $t);
        return ($t, undef);
      }
    } # B

    A: {
      if ($t->{type} == IDENT_TOKEN) {
        my $value = $t->{value};
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == NUMBER_TOKEN) {
          push @v, [$value, int $t->{number}];
          $t = $tt->get_next_token;
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        } elsif ($t->{type} == MINUS_TOKEN) {
          $t = $tt->get_next_token;
          if ($t->{type} == NUMBER_TOKEN) {
            push @v, [$value, -int $t->{number}];
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          } else {
            last A;
          }
        } elsif ($t->{type} == PLUS_TOKEN) {
          $t = $tt->get_next_token;
          if ($t->{type} == NUMBER_TOKEN) {
            push @v, [$value, int $t->{number}];
            $t = $tt->get_next_token;
            $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          } else {
            last A;
          }
        } else {
          push @v, [$value, $prop_name eq 'counter-increment' ? 1 : 0];
        }
        redo A;
      } else {
        return ($t, {$prop_name => \@v});
      }
    } # A
    
    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_as_specified,
};

$Attr->{counter_increment} =
$Key->{counter_increment} =
$Prop->{'counter-increment'} = {
  css => 'counter-increment',
  dom => 'counter_increment',
  key => 'counter_increment',
  parse => $Prop->{'counter-reset'}->{parse},
  initial => ['KEYWORD', 'none'],
  #inherited => 0,
  compute => $compute_as_specified,
};

$Attr->{clip} =
$Key->{clip} =
$Prop->{clip} = {
  css => 'clip',
  dom => 'clip',
  key => 'clip',
  ## NOTE: See <https://suika.suikawiki.org/gate/2005/sw/clip>.
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == FUNCTION_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'rect') {
        $t = $tt->get_next_token;
        my $prop_value = ['RECT'];

        A: {
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          
          my $has_sign;
          my $sign = 1;
          if ($t->{type} == MINUS_TOKEN) {
            $sign = -1;
            $has_sign = 1;
            $t = $tt->get_next_token;
          } elsif ($t->{type} == PLUS_TOKEN) {
            $has_sign = 1;
            $t = $tt->get_next_token;
          }
          if ($t->{type} == DIMENSION_TOKEN) {
            my $value = $t->{number} * $sign;
            my $unit = lc $t->{value}; ## TODO: case
            if ($length_unit->{$unit}) {
              $t = $tt->get_next_token;
              push @$prop_value, ['DIMENSION', $value, $unit];
            } else {
              $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                         level => $self->{level}->{must},
                         uri => \$self->{href},
                         token => $t);
              return ($t, undef);
            }
          } elsif ($t->{type} == NUMBER_TOKEN and
                   ($self->{unitless_px} or $t->{number} == 0)) {
            my $value = $t->{number} * $sign;
            $t = $tt->get_next_token;
            push @$prop_value, ['DIMENSION', $value, 'px'];
          } elsif (not $has_sign and $t->{type} == IDENT_TOKEN) {
            my $value = lc $t->{value}; ## TODO: case
            if ($value eq 'auto') {
              push @$prop_value, ['KEYWORD', 'auto'];
              $t = $tt->get_next_token;
            } else {
              last A;
            }
          } else {
            if ($has_sign) {
              $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                         level => $self->{level}->{must},
                         uri => \$self->{href},
                         token => $t);
              return ($t, undef);
            } else {
              last A;
            }
          }
        
          $t = $tt->get_next_token while $t->{type} == S_TOKEN;
          if ($#$prop_value == 4) {
            if ($t->{type} == RPAREN_TOKEN) {
              $t = $tt->get_next_token;
              return ($t, {$prop_name => $prop_value});
            } else {
              last A;
            }
          } else {
            $t = $tt->get_next_token if $t->{type} == COMMA_TOKEN;
            redo A;
          }
        } # A
      }
    } elsif ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'auto') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', 'auto']});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }

    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value and $specified_value->[0] eq 'RECT') {
      my $v = ['RECT'];
      for (@$specified_value[1..4]) {
        push @$v, $compute_length->($self, $element, $prop_name, $_);
      }
      return $v;
    }

    return $specified_value;
  },
};

$Attr->{marks} =
$Key->{marks} =
$Prop->{marks} = {
  css => 'marks',
  dom => 'marks',
  key => 'marks',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'crop' and $self->{prop_value}->{$prop_name}->{$value}) {
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == IDENT_TOKEN) {
          my $value = lc $t->{value}; ## TODO: case
          if ($value eq 'cross' and
              $self->{prop_value}->{$prop_name}->{$value}) {
            $t = $tt->get_next_token;
            return ($t, {$prop_name => ['MARKS', 1, 1]});
          }
        }
        return ($t, {$prop_name => ['MARKS', 1, 0]});
      } elsif ($value eq 'cross' and
               $self->{prop_value}->{$prop_name}->{$value}) {
        $t = $tt->get_next_token;
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        if ($t->{type} == IDENT_TOKEN) {
          my $value = lc $t->{value}; ## TODO: case
          if ($value eq 'crop' and
              $self->{prop_value}->{$prop_name}->{$value}) {
            $t = $tt->get_next_token;
            return ($t, {$prop_name => ['MARKS', 1, 1]});
          }
        }
        return ($t, {$prop_name => ['MARKS', 0, 1]});
      } elsif ($value eq 'none') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['MARKS']});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }

    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['MARKS', 0, 0],
  #inherited => 0,
  compute => $compute_as_specified,
};

$Attr->{size} =
$Key->{size} =
$Prop->{size} = {
  css => 'size',
  dom => 'size',
  key => 'size',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ({
           auto => 1, portrait => 1, landscape => 1,
          }->{$value}) {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', $value]});
      } elsif ($value eq 'inherit') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['INHERIT']});
      }
    }

    my $prop_value = ['SIZE'];
    A: {
      my $has_sign;
      my $sign = 1;
      if ($t->{type} == MINUS_TOKEN) {
        $has_sign = 1;
        $sign = -1;
        $t = $tt->get_next_token;
      } elsif ($t->{type} == PLUS_TOKEN) {
        $has_sign = 1;
        $t = $tt->get_next_token;
      }
      
      if ($t->{type} == DIMENSION_TOKEN) {
        my $value = $t->{number} * $sign;
        my $unit = lc $t->{value}; ## TODO: case
        if ($length_unit->{$unit}) {
          $t = $tt->get_next_token;
          push @$prop_value, ['DIMENSION', $value, $unit];
        } else {
          $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
                     level => $self->{level}->{must},
                     uri => \$self->{href},
                     token => $t);
          return ($t, undef);
        }
      } elsif ($t->{type} == NUMBER_TOKEN and
               ($self->{unitless_px} or $t->{number} == 0)) {
        my $value = $t->{number} * $sign;
        $t = $tt->get_next_token;
        push @$prop_value, ['DIMENSION', $value, 'px'];
      } else {
        if (@$prop_value == 2) {
          $prop_value->[2] = $prop_value->[1];
          return ($t, {$prop_name => $prop_value});
        } else {
          last A;
        }
      }

      if (@$prop_value == 3) {
        return ($t, {$prop_name => $prop_value});
      } else {
        $t = $tt->get_next_token while $t->{type} == S_TOKEN;
        redo A;
      }
    } # A

    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'auto'],
  #inherited => 0,
  compute => sub {
    my ($self, $element, $prop_name, $specified_value) = @_;

    if (defined $specified_value and $specified_value->[0] eq 'SIZE') {
      my $v = ['SIZE'];
      for (@$specified_value[1..2]) {
        push @$v, $compute_length->($self, $element, $prop_name, $_);
      }
      return $v;
    }

    return $specified_value;
  },
};

$Attr->{page} =
$Key->{page} =
$Prop->{page} = {
  css => 'page',
  dom => 'page',
  key => 'page',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == IDENT_TOKEN) {
      my $value = lc $t->{value}; ## TODO: case
      if ($value eq 'auto') {
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['KEYWORD', 'auto']});
      } else {
        $value = $t->{value};
        $t = $tt->get_next_token;
        return ($t, {$prop_name => ['PAGE', $value]});
      }
    }

    $onerror->(type => 'CSS syntax error', text => qq['$prop_name'],
               level => $self->{level}->{must},
               uri => \$self->{href},
               token => $t);
    return ($t, undef);
  },
  initial => ['KEYWORD', 'auto'],
  inherited => 1,
  compute => $compute_as_specified,
};

=head1 LICENSE

Copyright 2007-2011 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
