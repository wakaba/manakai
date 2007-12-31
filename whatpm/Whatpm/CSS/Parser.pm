package Whatpm::CSS::Parser;
use strict;
use Whatpm::CSS::Tokenizer qw(:token);
require Whatpm::CSS::SelectorsParser;

sub new ($) {
  my $self = bless {onerror => sub { }, must_level => 'm',
                    message_level => 'w',
                    unsupported_level => 'unsupported'}, shift;

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
                undef $namespace_allowed;
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
          if ($prop_def) {
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

      if ($prop_value) {
        $$current_decls->{$prop_def->{key}} = [$prop_value, $prop_flag];
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
      (css_rules => $open_rules->[0],
       ## TODO: href
       ## TODO: owner_node
       ## TODO: media
       type => 'text/css', ## TODO: OK?
       _parser => $self);
  return $ss;
} # parse_char_string

$Prop->{color} = {
  css => 'color',
  dom => 'color',
  key => 'color',
  parse => sub {
    my ($self, $prop_name, $tt, $t, $onerror) = @_;

    if ($t->{type} == IDENT_TOKEN) {
      if (lc $t->{value} eq 'blue') { ## TODO: case folding
        $t = $tt->get_next_token;
        return ($t, ["RGBA", 0, 0, 255, 0]);
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
};
$Attr->{color} = $Prop->{color};
$Key->{color} = $Prop->{color};

1;
## $Date: 2007/12/31 03:00:42 $
