package Whatpm::CSS::SelectorsParser;
use strict;
use warnings;
our $VERSION = '1.13';

require Exporter;
push our @ISA, 'Exporter';

use Whatpm::CSS::Tokenizer qw(:token);

sub new ($) {
  my $self = bless {
    onerror => sub { },
    lookup_namespace_uri => sub {
      return undef;
    },
    level => {
      must => 'm',
      uncertain => 'u',
    },
  }, shift;
  #$self->{href} = \(uri in which the selectors appears);
  return $self;
} # new

sub BEFORE_TYPE_SELECTOR_STATE () { 1 }
sub AFTER_NAME_STATE () { 2 }
sub BEFORE_LOCAL_NAME_STATE () { 3 }
sub BEFORE_SIMPLE_SELECTOR_STATE () { 4 }
sub BEFORE_CLASS_NAME_STATE () { 5 }
sub AFTER_COLON_STATE () { 6 }
sub AFTER_DOUBLE_COLON_STATE () { 7 }
sub AFTER_LBRACKET_STATE () { 8 }
sub AFTER_ATTR_NAME_STATE () { 9 }
sub BEFORE_ATTR_LOCAL_NAME_STATE () { 10 }
sub BEFORE_MATCH_STATE () { 11 }
sub BEFORE_VALUE_STATE () { 12 }
sub AFTER_VALUE_STATE () { 13 }
sub BEFORE_COMBINATOR_STATE () { 14 }
sub COMBINATOR_STATE () { 15 }
sub BEFORE_LANG_TAG_STATE () { 16 }
sub AFTER_LANG_TAG_STATE () { 17 }
sub BEFORE_AN_STATE () { 18 }
sub AFTER_AN_STATE () { 19 }
sub BEFORE_B_STATE () { 20 }
sub AFTER_B_STATE () { 21 }
sub AFTER_NEGATION_SIMPLE_SELECTOR_STATE () { 22 }
sub BEFORE_CONTAINS_STRING_STATE () { 23 }

sub NAMESPACE_SELECTOR () { 1 }
sub LOCAL_NAME_SELECTOR () { 2 }
sub ID_SELECTOR () { 3 }
sub CLASS_SELECTOR () { 4 }
sub PSEUDO_CLASS_SELECTOR () { 5 }
sub PSEUDO_ELEMENT_SELECTOR () { 6 }
sub ATTRIBUTE_SELECTOR () { 7 }

sub DESCENDANT_COMBINATOR () { S_TOKEN }
sub CHILD_COMBINATOR () { GREATER_TOKEN }
sub ADJACENT_SIBLING_COMBINATOR () { PLUS_TOKEN }
sub GENERAL_SIBLING_COMBINATOR () { TILDE_TOKEN }

sub EXISTS_MATCH () { 0 }
sub EQUALS_MATCH () { MATCH_TOKEN }
sub INCLUDES_MATCH () { INCLUDES_TOKEN }
sub DASH_MATCH () { DASHMATCH_TOKEN }
sub PREFIX_MATCH () { PREFIXMATCH_TOKEN }
sub SUFFIX_MATCH () { SUFFIXMATCH_TOKEN }
sub SUBSTRING_MATCH () { SUBSTRINGMATCH_TOKEN }

our @EXPORT_OK = qw(NAMESPACE_SELECTOR LOCAL_NAME_SELECTOR ID_SELECTOR
    CLASS_SELECTOR PSEUDO_CLASS_SELECTOR PSEUDO_ELEMENT_SELECTOR
    ATTRIBUTE_SELECTOR
    DESCENDANT_COMBINATOR CHILD_COMBINATOR
    ADJACENT_SIBLING_COMBINATOR GENERAL_SIBLING_COMBINATOR
    EXISTS_MATCH EQUALS_MATCH INCLUDES_MATCH DASH_MATCH PREFIX_MATCH
    SUFFIX_MATCH SUBSTRING_MATCH);

our %EXPORT_TAGS = (
  selector => [qw(NAMESPACE_SELECTOR LOCAL_NAME_SELECTOR ID_SELECTOR
      CLASS_SELECTOR PSEUDO_CLASS_SELECTOR PSEUDO_ELEMENT_SELECTOR
      ATTRIBUTE_SELECTOR)],
  combinator => [qw(DESCENDANT_COMBINATOR CHILD_COMBINATOR
      ADJACENT_SIBLING_COMBINATOR GENERAL_SIBLING_COMBINATOR)],
  match => [qw(EXISTS_MATCH EQUALS_MATCH INCLUDES_MATCH DASH_MATCH
      PREFIX_MATCH SUFFIX_MATCH SUBSTRING_MATCH)],
);

sub parse_string ($$) {
  my $self = $_[0];
  
  my $s = $_[1];
  pos ($s) = 0;

  my $tt = Whatpm::CSS::Tokenizer->new;
  $tt->{onerror} = $self->{onerror};
  $tt->{get_char} = sub {
    if (pos $s < length $s) {
      return ord substr $s, pos ($s)++, 1;
    } else {
      return -1;
    }
  }; # $tt->{get_char}
  $tt->init;

  $self->_parse_selectors_with_tokenizer ($tt, EOF_TOKEN);
} # parse_string

sub _parse_selectors_with_tokenizer ($$$;$) {
  my $self = $_[0];
  my $tt = $_[1];
  # $_[2] : End token (other than EOF_TOKEN - may be EOF_TOKEN if no other).
  # $_[3] : The first token, or undef

  my $default_namespace = $self->{lookup_namespace_uri}->('');

  ## ISSUE: The Selectors spec only poorly defines how tokens are mapped
  ## to each component of selectors.  In addition, it does not well define
  ## where spaces and comments are able to be inserted.

  my $selectors = [];
  my $selector = [DESCENDANT_COMBINATOR];
  my $sss = [];
  my $simple_selector;
  my $has_pseudo_element;
  my $in_negation;

  my $state = BEFORE_TYPE_SELECTOR_STATE;
  my $t = $_[3] || $tt->get_next_token;
  my $name;
  my $name_t;
  S: {
    if ($state == BEFORE_TYPE_SELECTOR_STATE) {
      $in_negation = 2 if $in_negation;

      if ($t->{type} == IDENT_TOKEN) { ## element type or namespace prefix
        $name = $t->{value};
        $name_t = $t;
        $state = AFTER_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == STAR_TOKEN) { ## universal selector or prefix
        undef $name;
        $state = AFTER_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == VBAR_TOKEN) { ## null namespace
        undef $name;
        push @$sss, [NAMESPACE_SELECTOR, undef];

        $state = BEFORE_LOCAL_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } elsif ({
                DOT_TOKEN, 1,
                COLON_TOKEN, 1,
                HASH_TOKEN, 1,
                LBRACKET_TOKEN, 1,
                RPAREN_TOKEN, 1, # :not(a ->> ) <<-
               }->{$t->{type}}) {
        $in_negation = 1 if $in_negation;
        if (defined $default_namespace) {
          if (length $default_namespace) {
            push @$sss, [NAMESPACE_SELECTOR, $default_namespace];
          } else {
            push @$sss, [NAMESPACE_SELECTOR, undef];
          }
        }

        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        # Reprocess.
        redo S;
      } else {
        $self->{onerror}->(type => 'no sss',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_SIMPLE_SELECTOR_STATE) {
      if ($in_negation and $in_negation++ == 2) {
        $state = AFTER_NEGATION_SIMPLE_SELECTOR_STATE;
        ## Reprocess.
        redo S;
      }

      if ($t->{type} == DOT_TOKEN) { ## class selector
        if ($has_pseudo_element) {
          $self->{onerror}->(type => 'ss after pseudo element',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
        $state = BEFORE_CLASS_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == HASH_TOKEN) { ## ID selector
        if ($has_pseudo_element) {
          $self->{onerror}->(type => 'ss after pseudo element',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
        push @$sss, [ID_SELECTOR, $t->{value}];
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == COLON_TOKEN) { ## pseudo-class or pseudo-element
        if ($has_pseudo_element) {
          $self->{onerror}->(type => 'ss after pseudo element',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
        $state = AFTER_COLON_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == LBRACKET_TOKEN) { ## attribute selector
        if ($has_pseudo_element) {
          $self->{onerror}->(type => 'ss after pseudo-element',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
        $state = AFTER_LBRACKET_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        $state = BEFORE_COMBINATOR_STATE;
        ## Reprocess.
        redo S;
      }
    } elsif ($state == AFTER_NAME_STATE) {
      if ($t->{type} == VBAR_TOKEN) {
        $state = BEFORE_LOCAL_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else { ## Type or universal selector w/o namespace prefix
        if (defined $default_namespace) {
          if (length $default_namespace) {
            push @$sss, [NAMESPACE_SELECTOR, $default_namespace];
          } else {
            push @$sss, [NAMESPACE_SELECTOR, undef];
          }
        }
        push @$sss, [LOCAL_NAME_SELECTOR, $name] if defined $name;

        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        ## reprocess.
        redo S;
      }
    } elsif ($state == BEFORE_LOCAL_NAME_STATE) {
      if ($t->{type} == IDENT_TOKEN) {
        if (defined $name) { ## Prefix is neither empty nor "*"
          my $uri = $self->{lookup_namespace_uri}->($name);
          unless (defined $uri) {
            $self->{onerror}->(type => 'namespace prefix:not declared',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $name_t || $t,
                               value => $name);
            return ($t, undef);
          }
          push @$sss, [NAMESPACE_SELECTOR, $uri];
        }
        push @$sss, [LOCAL_NAME_SELECTOR, $t->{value}];

        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == STAR_TOKEN) {
        if (defined $name) { ## Prefix is neither empty nor "*"
          my $uri = $self->{lookup_namespace_uri}->($name);
          unless (defined $uri) {
            $self->{onerror}->(type => 'namespace prefix:not declared',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $name_t || $t,
                               value => $name);
            return ($t, undef);
          }
          push @$sss, [NAMESPACE_SELECTOR, $uri];
        }
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else { ## "|" not followed by type or universal selector
        $self->{onerror}->(type => 'no local name selector',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_CLASS_NAME_STATE) {
      if ($t->{type} == IDENT_TOKEN) {
        push @$sss, [CLASS_SELECTOR, $t->{value}];

        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no class name',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_COMBINATOR_STATE) {
      push @$selector, $sss;
      $sss = [];

      if ($t->{type} == S_TOKEN) {
        $state = COMBINATOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ({
                GREATER_TOKEN, 1,
                PLUS_TOKEN, 1,
                TILDE_TOKEN, 1,
                COMMA_TOKEN, 1,
                EOF_TOKEN, 1,
                $_[2], 1,
               }->{$t->{type}}) {
        $state = COMBINATOR_STATE;
        ## Reprocess.
        redo S;
      } else {
        $self->{onerror}->(type => 'no combinator',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == COMBINATOR_STATE) {
      if ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } elsif ({
                GREATER_TOKEN, 1,
                PLUS_TOKEN, 1,
                TILDE_TOKEN, 1,
               }->{$t->{type}}) {
        push @$selector, $t->{type};

        $state = BEFORE_TYPE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == EOF_TOKEN or $t->{type} == $_[2]) {
        push @$selectors, $selector;
        return ($t, $selectors);
      } elsif ($t->{type} == COMMA_TOKEN) {
        push @$selectors, $selector;
        $selector = [DESCENDANT_COMBINATOR];
        undef $has_pseudo_element;

        $state = BEFORE_TYPE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        push @$selector, S_TOKEN;

        $state = BEFORE_TYPE_SELECTOR_STATE;
        ## Reprocess.
        redo S;
      }
    } elsif ($state == AFTER_COLON_STATE) {
      if ($t->{type} == IDENT_TOKEN) {
        my $class = $t->{value};
        $class =~ tr/A-Z/a-z/; ## TODO: ASCII case-insensitivity ok?
        if ($self->{pseudo_class}->{$class} and 
            {
              active => 1,
              checked => 1,
              '-manakai-current' => 1,
              disabled => 1,
              empty => 1,
              enabled => 1,
              'first-child' => 1,
              'first-of-type' => 1,
              focus => 1,
              hover => 1,
              indeterminate => 1, ## NOTE: Reserved in Selectors Level 3
              'last-child' => 1,
              'last-of-type' => 1,
              link => 1,
              'only-child' => 1,
              'only-of-type' => 1,
              root => 1,
              target => 1,
              visited => 1,
            }->{$class}) {
          push @$sss, [PSEUDO_CLASS_SELECTOR, $class];
        } elsif ($self->{pseudo_element}->{$class} and
                 {'first-letter' => 1, 'first-line' => 1,
                  before => 1, after => 1}->{$class}) {
          push @$sss, [PSEUDO_ELEMENT_SELECTOR, $class];
          $has_pseudo_element = 1;
        } else {
          ## TODO: Should we raise a different kind of error
          ## if a pseudo class is known but not supported?
          ## TODO: Maybe we should raise different type of error
          ## for at least pseudo-classes which requires arguments.
          $self->{onerror}->(type => 'unknown pseudo-class',
                             level => $self->{level}->{uncertain},
                             uri => \$self->{href},
                             token => $t, value => $class);
          return ($t, undef);
        }

        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == FUNCTION_TOKEN) {
        my $class = $t->{value};
        $class =~ tr/A-Z/a-z/; ## TODO: Is ASCII case-insensitivity OK?
        
        if ($class eq 'lang' and $self->{pseudo_class}->{$class}) {
          $state = BEFORE_LANG_TAG_STATE;
          $t = $tt->get_next_token;
          redo S;
        } elsif ($class eq 'not' and $self->{pseudo_class}->{$class} and
                 not $in_negation) {
          $in_negation = 1;

          push @$sss, '';
          $state = BEFORE_TYPE_SELECTOR_STATE;
          $t = $tt->get_next_token;
          redo S;
        } elsif ({
                  'nth-child' => 1,
                  'nth-last-child' => 1,
                  'nth-of-type' => 1,
                  'nth-last-of-type' => 1,
                 }->{$class} and $self->{pseudo_class}->{$class}) {
          $name = $class;

          $state = BEFORE_AN_STATE;
          $t = $tt->get_next_token;
          ## TODO: syntax of value in the spec is vague; need to reverse
          ## engineer what Opera 9.5 does.
          redo S;
        } elsif ($class eq '-manakai-contains' and
                 $self->{pseudo_class}->{$class}) {
          $state = BEFORE_CONTAINS_STRING_STATE;
          $t = $tt->get_next_token;
          redo S;
        } else {
          $self->{onerror}->(type => 'unknown pseudo-class',
                             level => $self->{level}->{uncertain},
                             uri => \$self->{href},
                             token => $t, value => $class);
          return ($t, undef);
        }
      } elsif ($t->{type} == COLON_TOKEN and
               not $in_negation) { ## Pseudo-element
        $state = AFTER_DOUBLE_COLON_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no pseudo-class name',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_LBRACKET_STATE) { ## Attribute selector
      $simple_selector = [ATTRIBUTE_SELECTOR];
      if ($t->{type} == IDENT_TOKEN) {
        $name = $t->{value};
        $name_t = $t;

        $state = AFTER_ATTR_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == VBAR_TOKEN) {
        $simple_selector->[1] = ''; # null namespace
        
        $state = BEFORE_ATTR_LOCAL_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == STAR_TOKEN) {
        $name = undef;
        $name_t = undef;

        $state = AFTER_ATTR_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no attr name',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_ATTR_NAME_STATE) {
      if ($t->{type} == VBAR_TOKEN) {
        if (defined $name) {
          my $uri = $self->{lookup_namespace_uri}->($name);
          unless (defined $uri) {
            $self->{onerror}->(type => 'namespace prefix:not declared',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $name_t || $t,
                               value => $name);
            return ($t, undef);
          }
          $simple_selector->[1] = $uri;
        }

        $state = BEFORE_ATTR_LOCAL_NAME_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        unless (defined $name) { ## [*]
          $self->{onerror}->(type => 'no attr namespace separator',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
        $simple_selector->[1] = ''; # null namespace
        $simple_selector->[2] = $name;

        $state = BEFORE_MATCH_STATE;
        ## Reprocess.
        redo S;
      }
    } elsif ($state == BEFORE_ATTR_LOCAL_NAME_STATE) {
      if ($t->{type} == IDENT_TOKEN) {
        $simple_selector->[2] = $t->{value};
        
        $state = BEFORE_MATCH_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no attr local name',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_MATCH_STATE) {
      if ({
           MATCH_TOKEN, 1,
           INCLUDES_TOKEN, 1,
           DASHMATCH_TOKEN, 1,
           PREFIXMATCH_TOKEN, 1,
           SUFFIXMATCH_TOKEN, 1,
           SUBSTRINGMATCH_TOKEN, 1,
          }->{$t->{type}}) {
        $simple_selector->[3] = $t->{type};

        $state = BEFORE_VALUE_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == RBRACKET_TOKEN) {
        push @$sss, $simple_selector;
        
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no attr match',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_VALUE_STATE) {
      if ($t->{type} == IDENT_TOKEN or $t->{type} == STRING_TOKEN) {
        $simple_selector->[4] = $t->{value};
        push @$sss, $simple_selector;

        $state = AFTER_VALUE_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no attr value',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_VALUE_STATE) {
      if ($t->{type} == RBRACKET_TOKEN) {
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'attr selector not closed',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_DOUBLE_COLON_STATE) {
      if ($t->{type} == IDENT_TOKEN) {
        my $pe = $t->{value};
        $pe =~ tr/A-Z/a-z/; ## TODO: Is ASCII case-insensitive OK?
        if ($self->{pseudo_element}->{$pe} and 
            {'first-letter' => 1, 'first-line' => 1,
             after => 1, before => 1}->{$pe}) {
          push @$sss, [PSEUDO_ELEMENT_SELECTOR, $pe];
          $has_pseudo_element = 1;

          $state = BEFORE_SIMPLE_SELECTOR_STATE;
          $t = $tt->get_next_token;
          redo S;
        } else {
          $self->{onerror}->(type => 'unknown pseudo-element',
                             level => $self->{level}->{uncertain},
                             uri => \$self->{href},
                             token => $t, value => $pe);
          return ($t, undef);
        }
      } else {
        $self->{onerror}->(type => 'no pseudo-element name',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_LANG_TAG_STATE) {
      if ($t->{type} == IDENT_TOKEN) {
        push @$sss, [PSEUDO_CLASS_SELECTOR, 'lang', $t->{value}];
        
        $state = AFTER_LANG_TAG_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no lang tag',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_LANG_TAG_STATE) {
      if ($t->{type} == RPAREN_TOKEN) {
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'lang selector not closed',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_AN_STATE) {
      if ($t->{type} == DIMENSION_TOKEN) {
        if (int $t->{number} == $t->{number}) {
          my $n = $t->{value};
          $n =~ tr/A-Z/a-z/; ## TODO: ascii ?
          if ($n eq 'n') {
            $simple_selector = [PSEUDO_CLASS_SELECTOR, $name,
                                0+$t->{number}, 0];
            
            $state = AFTER_AN_STATE;
            $t = $tt->get_next_token;
            redo S;
          } elsif ($n =~ /\An-([0-9]+)\z/) {
            push @$sss, [PSEUDO_CLASS_SELECTOR, $name, 0+$t->{number}, 0-$1];

            $state = AFTER_B_STATE;
            $t = $tt->get_next_token;
            redo S;
          } else {
            $self->{onerror}->(type => 'an+b syntax error',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $t);
            return ($t, undef);
          }
        } else {
          $self->{onerror}->(type => 'an+b syntax error',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
      } elsif ($t->{type} == NUMBER_TOKEN) {
        if (int $t->{number} == $t->{number}) {
          push @$sss, [PSEUDO_CLASS_SELECTOR, $name, 0, 0+$t->{number}];

          $state = AFTER_B_STATE;
          $t = $tt->get_next_token;
          redo S;
        } else { ## ISSUE: Is :nth-child(0.0) disallowed?
          $self->{onerror}->(type => 'an+b not integer',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t, value => $t->{number});
          return ($t, undef);
        }
      } elsif ($t->{type} == IDENT_TOKEN) {
        my $value = $t->{value};
        $value =~ tr/A-Z/a-z/; ## TODO: ASCII case-insensitive?
        if ($value eq 'odd') {
          push @$sss, [PSEUDO_CLASS_SELECTOR, $name, 2, 1];

          $state = AFTER_B_STATE;
          $t = $tt->get_next_token;
          redo S;
        } elsif ($value eq 'even') {
          push @$sss, [PSEUDO_CLASS_SELECTOR, $name, 2, 0];

          $state = AFTER_B_STATE;
          $t = $tt->get_next_token;
          redo S;
        } elsif ($value eq 'n' or $value eq '-n') {
          ## ISSUE: :nth-child(-n) is not explicitly allowed, but appears
          ## in an example in the spec.
          $simple_selector = [PSEUDO_CLASS_SELECTOR, $name,
                              $value eq 'n' ? 1 : -1, 0];

          $state = AFTER_AN_STATE;
          $t = $tt->get_next_token;
          redo S;
        } elsif ($value =~ /\A(-?)n-([0-9]+)\z/) {
          push @$sss, [PSEUDO_CLASS_SELECTOR, $name, 0+($1.'1'), -$2];

          $state = AFTER_B_STATE;
          $t = $tt->get_next_token;
          redo S;
        } else {
          $self->{onerror}->(type => 'an+b syntax error',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
      } elsif ($t->{type} == MINUS_TOKEN) {
        ## ISSUE: Is :nth-child(- 1) allowed?
        ## ISSUE: Is :nth-child(n-/**/6) or (-n-/**/6) allowed?
        $t = $tt->get_next_token;
        if ($t->{type} == DIMENSION_TOKEN || $t->{type} == IDENT_TOKEN) {
          my $num = $t->{type} == IDENT_TOKEN ? 1 : $t->{number};
          ## NOTE: :nth-child(-/**/n)
          if (int $num == $num) {
            my $n = $t->{value};
            $n =~ tr/A-Z/a-z/; ## TODO: ASCII?
            if ($n eq 'n') {
              $simple_selector = [PSEUDO_CLASS_SELECTOR, $name, -$num, 0];
              
              $state = AFTER_AN_STATE;
              $t = $tt->get_next_token;
              redo S;
            } elsif ($n =~ /\An-([0-9]+)\z/) {
              $simple_selector = [PSEUDO_CLASS_SELECTOR, $name,
                                  -$num, -$1];

              $state = AFTER_AN_STATE;
              $t = $tt->get_next_token;
              redo S;
            } else {
              $self->{onerror}->(type => 'an+b syntax error',
                                 level => $self->{level}->{must},
                                 uri => \$self->{href},
                                 token => $t);
              return ($t, undef);
            }
          } else {
            $self->{onerror}->(type => 'an+b syntax error',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $t);
            return ($t, undef);
          }
        } elsif ($t->{type} == NUMBER_TOKEN) {
          if (int $t->{number} == $t->{number}) {
            push @$sss, [PSEUDO_CLASS_SELECTOR, $name, 0, -$t->{number}];

            $state = AFTER_B_STATE;
            $t = $tt->get_next_token;
            redo S;
          } else {
            $self->{onerror}->(type => 'an+b syntax error',
                               level => $self->{level}->{must},
                               uri => \$self->{href},
                               token => $t);
            return ($t, undef);
          }
        } else {
          $self->{onerror}->(type => 'an+b syntax error',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'an+b syntax error',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_AN_STATE) {
      ## ISSUE: :nth-child(1n +2) is allowed.
      ## :nth-child(1n /**/ +2) and :nth-child(1n -2) are allowed?
      if ($t->{type} == PLUS_TOKEN) {
        $simple_selector->[3] = +1;

        $state = BEFORE_B_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == MINUS_TOKEN) {
        $simple_selector->[3] = -1;

        $state = BEFORE_B_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == RPAREN_TOKEN) {
        push @$sss, $simple_selector;

        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'an+b syntax error',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_B_STATE) {
      ## ISSUE: Is S allowed?
      if ($t->{type} == NUMBER_TOKEN) {
        if (int $t->{number} == $t->{number}) {
          $simple_selector->[3] *= $t->{number};
          push @$sss, $simple_selector;
          
          $state = AFTER_B_STATE;
          $t = $tt->get_next_token;
          redo S;
        } else {
          $self->{onerror}->(type => 'an+b syntax error',
                             level => $self->{level}->{must},
                             uri => \$self->{href},
                             token => $t);
          return ($t, undef);
        }
      } else {
        $self->{onerror}->(type => 'an+b syntax error',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_B_STATE) {
      if ($t->{type} == RPAREN_TOKEN) {
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'an+b not closed',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == AFTER_NEGATION_SIMPLE_SELECTOR_STATE) {
      if ($t->{type} == RPAREN_TOKEN) {
        undef $in_negation;
        my $simple_selector = [];
        unshift @$simple_selector, pop @$sss while ref $sss->[-1];
        pop @$sss; # dummy
        unshift @$simple_selector, 'not';
        unshift @$simple_selector, PSEUDO_CLASS_SELECTOR;
        push @$sss, $simple_selector;
        
        $state = BEFORE_SIMPLE_SELECTOR_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'not not closed',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } elsif ($state == BEFORE_CONTAINS_STRING_STATE) {
      if ($t->{type} == STRING_TOKEN or $t->{type} == IDENT_TOKEN) {
        push @$sss, [PSEUDO_CLASS_SELECTOR, '-manakai-contains', $t->{value}];
        
        $state = AFTER_LANG_TAG_STATE;
        $t = $tt->get_next_token;
        redo S;
      } elsif ($t->{type} == S_TOKEN) {
        ## Stay in the state.
        $t = $tt->get_next_token;
        redo S;
      } else {
        $self->{onerror}->(type => 'no contains string',
                           level => $self->{level}->{must},
                           uri => \$self->{href},
                           token => $t);
        return ($t, undef);
      }
    } else {
      die "$0: Selectors Parser: $state: Unknown state";
    }
  } # S
} # parse_string

## NOTE: Specificity in CSS 2.1 and Selectors 3 are incompatible.
## What is implemented by this method is CSS 2.1's one.
## (With Selectors 3 terminology and with Selectors 3 additions.)
sub get_selector_specificity ($$) {
  my (undef, $selector) = @_;

  my $r = [0, 0, 0, 0]; # a, b, c, d

  ## a = 1 iff style="" attribute
  ## b += 1 for ID attribute selectors
  ## c += 1 for attribute, class, and pseudo-class selectors
  ## d += 1 for type selectors and pseudo-elements

  for my $sss (@$selector) {
    next unless ref $sss; # combinator
    my @sss = @$sss;
    while (@sss) {
      my $ss = shift @sss;
      if ($ss->[0] == LOCAL_NAME_SELECTOR or
          $ss->[0] == PSEUDO_ELEMENT_SELECTOR) {
        $r->[3]++;
      } elsif ($ss->[0] == ATTRIBUTE_SELECTOR or
               $ss->[0] == PSEUDO_CLASS_SELECTOR) {
        $r->[2]++;
      } elsif ($ss->[0] == CLASS_SELECTOR) {
        if ($ss->[1] eq 'not') {
          push @sss, @$ss[2..$#$ss];
        } else {
          $r->[2]++;
        }
      } elsif ($ss->[0] == ID_SELECTOR) {
        $r->[1]++;
      }
    }
  }

  return $r;
} # get_selector_specificity

=head1 LICENSE

Copyright 2007-2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
