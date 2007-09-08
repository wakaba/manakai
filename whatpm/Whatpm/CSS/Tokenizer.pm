package Whatpm::CSS::Tokenizer;
use strict;

sub BEFORE_TOKEN_STATE () { 0 }
sub BEFORE_NMSTART_STATE () { 1 }
sub NAME_STATE () { 2 }
sub ESCAPE_OPEN_STATE () { 3 }
sub STRING_STATE () { 4 }
sub HASH_OPEN_STATE () { 5 }
sub NUMBER_STATE () { 6 }
sub NUMBER_FRACTION_STATE () { 7 }
sub AFTER_NUMBER_STATE () { 8 }
sub URI_BEFORE_WSP_STATE () { 9 }
sub ESCAPE_STATE () { 10 }
sub ESCAPE_BEFORE_LF_STATE () { 11 }
sub ESCAPE_BEFORE_NL_STATE () { 12 }
sub NUMBER_DOT_STATE () { 13 }
sub NUMBER_DOT_NUMBER_STATE () { 14 }
sub DELIM_STATE () { 15 }
sub URI_UNQUOTED_STATE () { 16 }
sub URI_AFTER_WSP_STATE () { 17 }
sub AFTER_AT_STATE () { 18 }
sub AFTER_AT_HYPHEN_STATE () { 19 }

sub IDENT_TOKEN () { 1 }
sub ATKEYWORD_TOKEN () { 2 }
sub HASH_TOKEN () { 3 }
sub FUNCTION_TOKEN () { 4 }
sub URI_TOKEN () { 5 }
sub URI_INVALID_TOKEN () { 6 }
sub URI_PREFIX_TOKEN () { 7 }
sub URI_PREFIX_INVALID_TOKEN () { 8 }
sub STRING_TOKEN () { 9 }
sub INVALID_TOKEN () { 10 }
sub NUMBER_TOKEN () { 11 }
sub DIMENSION_TOKEN () { 12 }
sub PERCENTAGE_TOKEN () { 13 }
sub UNICODE_RANGE_TOKEN () { 14 }
sub UNICODE_RANGE_INVALID_TOKEN () { 15 }
sub DELIM_TOKEN () { 16 }
sub PLUS_TOKEN () { 17 }
sub GREATER_TOKEN () { 18 }
sub COMMA_TOKEN () { 19 }
sub TILDE_TOKEN () { 20 }
sub DASHMATCH_TOKEN () { 21 }
sub PREFIXMATCH_TOKEN () { 22 }
sub SUFFIXMATCH_TOKEN () { 23 }
sub SUBSTRINGMATCH_TOKEN () { 24 }
sub INCLUDES_TOKEN () { 25 }
sub SEMICOLON_TOKEN () { 26 }
sub LBRACE_TOKEN () { 27 }
sub RBRACE_TOKEN () { 28 }
sub LPAREN_TOKEN () { 29 }
sub RPAREN_TOKEN () { 30 }
sub LBRACKET_TOKEN () { 31 }
sub RBRACKET_TOKEN () { 32 }
sub S_TOKEN () { 33 }
sub CDO_TOKEN () { 34 }
sub CDC_TOKEN () { 35 }
sub COMMENT_TOKEN () { 36 }
sub COMMENT_INVALID_TOKEN () { 37 }
sub EOF_TOKEN () { 38 }

our @TokenName = qw(
  0 IDENT ATKEYWORD HASH FUNCTION URI URI_INVALID URI_PREFIX URI_PREFIX_INVALID
  STRING INVALID NUMBER DIMENSION PERCENTAGE UNICODE_RANGE
  UNICODE_RANGE_INVALID DELIM PLUS GREATER COMMA TILDE DASHMATCH
  PREFIXMATCH SUFFIXMATCH SUBSTRINGMATCH INCLUDES SEMICOLON
  LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET S CDO CDC COMMENT
  COMMENT_INVALID EOF
);

sub new ($) {
  my $self = bless {token => [], get_char => sub { -1 },
                    onerror => sub { }}, shift;
  return $self;
} # new

sub init ($) {
  my $self = shift;
  $self->{state} = BEFORE_TOKEN_STATE;
  $self->{c} = $self->{get_char}->();
} # init

sub get_next_token ($) {
  my $self = shift;
  if (@{$self->{token}}) {
    return shift @{$self->{token}};
  }

  my $current_token;
  my $char;
  my $num; # |{num}|, if any.
  my $i; # |$i + 1|th character in |unicode| in |escape|.
  my $q;
      ## NOTE:
      ##   0: in |ident|.
      ##   1: in |URI| outside of |string|.
      ##   0x0022: in |string1| or |invalid1|.
      ##   0x0027: in |string2| or |invalid2|.

  A: {
    if ($self->{state} == BEFORE_TOKEN_STATE) {
      if ($self->{c} == 0x002D) { # -
        ## NOTE: |-| in |ident| in |IDENT|
        $current_token = {type => IDENT_TOKEN, value => '-'};
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
               (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
               $self->{c} == 0x005F or # _
               $self->{c} > 0x007F) { # nonascii
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $current_token = {type => IDENT_TOKEN, value => chr $self->{c}};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $current_token = {type => IDENT_TOKEN, value => ''};
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0040) { # @
        ## NOTE: |@| in |ATKEYWORD|
        $current_token = {type => ATKEYWORD_TOKEN, value => ''};
        $self->{state} = AFTER_AT_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0022 or $self->{c} == 0x0027) { # " or '
        $current_token = {type => STRING_TOKEN, value => ''};
        $self->{state} = STRING_STATE; $q = $self->{c};
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0023) { # #
        ## NOTE: |#| in |HASH|.
        $current_token = {type => HASH_TOKEN, value => ''};
        $self->{state} = HASH_OPEN_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif (0x0030 <= $self->{c} and $self->{c} <= 0x0039) { # 0..9
        ## NOTE: |num|.
        $current_token = {type => NUMBER_TOKEN, value => chr $self->{c}};
        $self->{state} = NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002E) { # .
        ## NOTE: |num|.
        $current_token = {type => NUMBER_TOKEN, value => '0'};
        $self->{state} = NUMBER_FRACTION_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x003C) { # <
        ## NOTE: |CDO|
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x0021) { # !
          $self->{c} = $self->{get_char}->();
          if ($self->{c} == 0x002C) { # -
            $self->{c} = $self->{get_char}->();
            if ($self->{c} == 0x002C) { # -
              $self->{state} = BEFORE_TOKEN_STATE;
              $self->{c} = $self->{get_char}->();
              return {type => CDO_TOKEN};
              #redo A;
            } else {
              unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '!'};
              ## NOTE: |-| in |ident| in |IDENT|
              $current_token = {type => IDENT_TOKEN, value => '-'};
              $self->{state} = BEFORE_NMSTART_STATE;
              #reprocess
              return {type => DELIM_TOKEN, value => '<'};
              #redo A;
            }
          } else {
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '!'};
            $self->{state} = BEFORE_TOKEN_STATE;
            #reprocess
            return {type => DELIM_TOKEN, value => '<'};
            #redo A;
          }
        } else {
          $self->{state} = BEFORE_TOKEN_STATE;
          #reprocess
          return {type => DELIM_TOKEN, value => '<'};
          #redo A;
        }
      } elsif (my $t = {
                0x003B => SEMICOLON_TOKEN, # ;
                0x007B => LBRACE_TOKEN, # {
                0x007D => RBRACE_TOKEN, # }
                0x0028 => LPAREN_TOKEN, # (
                0x0029 => RPAREN_TOKEN, # )
                0x005B => LBRACKET_TOKEN, # [
                0x005D => RBRACKET_TOKEN, # ]
               }->{$self->{c}}) {
        # stay in the state
        $self->{c} = $self->{get_char}->();
        return {type => $t};
        # redo A;
      } elsif ({
                0x0020 => 1, # SP
                0x0009 => 1, # \t
                0x000D => 1, # \r
                0x000A => 1, # \n
                0x000C => 1, # \f
               }->{$self->{c}}) {
        W: {
          $self->{c} = $self->{get_char}->();
          if ({
                0x0020 => 1, # SP
                0x0009 => 1, # \t
                0x000D => 1, # \r
                0x000A => 1, # \n
                0x000C => 1, # \f
              }->{$self->{c}}) {
            redo W;
          } elsif (my $v = {
                            0x002B => PLUS_TOKEN, # +
                            0x003E => GREATER_TOKEN, # >
                            0x002C => COMMA_TOKEN, # ,
                            0x007E => TILDE_TOKEN, # ~
                           }->{$self->{c}}) {
            # stay in the state
            $self->{c} = $self->{get_char}->();
            return {type => $v};
            #redo A;
          } else {
            # stay in the state
            # reprocess
            return {type => S_TOKEN};
            #redo A;
          }
        } # W
      } elsif (my $v = {
                        0x007C => DASHMATCH_TOKEN, # |
                        0x005E => PREFIXMATCH_TOKEN, # ^
                        0x0024 => SUFFIXMATCH_TOKEN, # $
                        0x002A => SUBSTRINGMATCH_TOKEN, # *
                       }->{$self->{c}}) {
        my $c = $self->{c};
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x003D) { # =
          # stay in the state
          $self->{c} = $self->{get_char}->();
          return {type => $v};
          #redo A;
        } else {
          # stay in the state
          # reprocess
          return {type => DELIM_TOKEN, value => chr $c};
          #redo A;
        }
      } elsif ($self->{c} == 0x002B) { # +
        # stay in the state
        $self->{c} = $self->{get_char}->();
        return {type => PLUS_TOKEN};
        #redo A;
      } elsif ($self->{c} == 0x003E) { # >
        # stay in the state
        $self->{c} = $self->{get_char}->();
        return {type => GREATER_TOKEN};
        #redo A;
      } elsif ($self->{c} == 0x002C) { # ,
        # stay in the state
        $self->{c} = $self->{get_char}->();
        return {type => COMMA_TOKEN};
        #redo A;
      } elsif ($self->{c} == 0x007E) { # ~
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x003D) { # =
          # stay in the state
          $self->{c} = $self->{get_char}->();
          return {type => INCLUDES_TOKEN};
          #redo A;
        } else {
          # stay in the state
          # reprocess
          return {type => TILDE_TOKEN};
          #redo A;
        }
      } elsif ($self->{c} == -1) {
        # stay in the state
        $self->{c} = $self->{get_char}->();
        return {type => EOF_TOKEN};
        #redo A;
      } else {
        # stay in the state
        $current_token = {type => DELIM_TOKEN, value => chr $self->{c}};
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      }
    } elsif ($self->{state} == BEFORE_NMSTART_STATE) {
      ## NOTE: |nmstart| in |ident| in (|IDENT|, |DIMENSION|, or
      ## |FUNCTION|)
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{c};
        $current_token->{type} = DIMENSION_TOKEN
            if $current_token->{type} == NUMBER_TOKEN;
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
## TODO: 12-\X, 12-\{nl}
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002D and # -
               $current_token->{type} == IDENT_TOKEN) {
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x003E) { # >
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return {type => CDC_TOKEN};
          #redo A;
        } else {
          ## NOTE: |-|, |-|, $self->{c}
          #$current_token = {type => IDENT_TOKEN, value => '-'};
          # stay in the state
          # reconsume
          return {type => DELIM_TOKEN, value => '-'};
          #redo A;
        }
      } else {
        if ($current_token->{type} == NUMBER_TOKEN) {
          ## NOTE: |-| after |NUMBER|.
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
          $self->{state} = BEFORE_TOKEN_STATE;
          # reconsume
          $current_token->{value} = $current_token->{number};
          delete $current_token->{number};
          return $current_token;
        } else {
          ## NOTE: |-| not followed by |nmstart|.
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return {type => DELIM_TOKEN, value => '-'};
        }
      }
    } elsif ($self->{state} == AFTER_AT_STATE) {
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{c};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002D) { # -
        $current_token->{value} .= '-';
        $self->{state} = AFTER_AT_HYPHEN_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return {type => DELIM_TOKEN, value => '@'};
      }
    } elsif ($self->{state} == AFTER_AT_HYPHEN_STATE) {
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{c};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002D) { # -
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x003E) { # >
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return {type => CDC_TOKEN};
          #redo A;
        } else {
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
          $current_token = {type => IDENT_TOKEN, value => '-'};
          $self->{state} = BEFORE_NMSTART_STATE;
          # reprocess
          return {type => DELIM_TOKEN, value => '@'};
          #redo A;
        }
      } elsif ($self->{c} == 0x005C) { # \
        ## TODO: @-\{nl}
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return {type => DELIM_TOKEN, value => '@'};
      }
    } elsif ($self->{state} == AFTER_NUMBER_STATE) {
      if ($self->{c} == 0x002D) { # -
        ## NOTE: |-| in |ident|.
        $current_token->{value} = '-';
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
               (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
               $self->{c} == 0x005F or # _
               $self->{c} > 0x007F) { # nonascii
        ## NOTE: |nmstart| in |ident|.
        $current_token->{value} = chr $self->{c};
        $current_token->{type} = DIMENSION_TOKEN;
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $current_token->{value} = '';
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0025) { # %
        $current_token->{type} = PERCENTAGE_TOKEN;
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return $current_token;
        #redo A;
      }
    } elsif ($self->{state} == HASH_OPEN_STATE) {
      ## NOTE: The first |nmchar| in |name| in |HASH|.
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          (0x0030 <= $self->{c} and $self->{c} <= 0x0039) or # 0..9
          $self->{c} == 0x002D or # -
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{c};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return {type => DELIM_TOKEN, value => '#'};
        #redo A;
      }
    } elsif ($self->{state} == NAME_STATE) {
      ## NOTE: |nmchar| in (|ident| or |name|).
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          (0x0030 <= $self->{c} and $self->{c} <= 0x0039) or # 0..9
          $self->{c} == 0x005F or # _
          $self->{c} == 0x002D or # -
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0028 and # (
               $current_token->{type} == IDENT_TOKEN) { # (
        my $func_name = $current_token->{value};
        $func_name =~ tr/A-Z/a-z/; ## TODO: Unicode or ASCII case-insensitive?
        if ($func_name eq 'url' or $func_name eq 'url-prefix') {
          if ($current_token->{has_escape}) {
            ## TODO: warn
          }
          $current_token->{type}
              = $func_name eq 'url' ? URI_TOKEN : URI_PREFIX_TOKEN;
          $current_token->{value} = '';
          $self->{state} = URI_BEFORE_WSP_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          $current_token->{type} = FUNCTION_TOKEN;
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $current_token;
          #redo A;
        }
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reconsume
        return $current_token;
        #redo A;
      }
    } elsif ($self->{state} == URI_BEFORE_WSP_STATE) {
      while ({
                0x0020 => 1, # SP
                0x0009 => 1, # \t
                0x000D => 1, # \r
                0x000A => 1, # \n
                0x000C => 1, # \f
             }->{$self->{c}}) {
        $self->{c} = $self->{get_char}->();
      }
      if ($self->{c} == -1) {
        $current_token->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$current_token->{type}};        
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } elsif ($self->{c} < 0x0020 or $self->{c} == 0x0028) { # C0 or (
        ## TODO: Should we consider matches of "(" and ")"?
        $current_token->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$current_token->{type}};
        $self->{state} = URI_UNQUOTED_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0022 or $self->{c} == 0x0027) { # " or '
        $self->{state} = STRING_STATE; $q = $self->{c};
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0029) { # )
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $self->{c};
        $self->{state} = URI_UNQUOTED_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == URI_UNQUOTED_STATE) {
      if ({
           0x0020 => 1, # SP
           0x0009 => 1, # \t
           0x000D => 1, # \r
           0x000A => 1, # \n
           0x000C => 1, # \f
          }->{$self->{c}}) {
        $self->{state} = URI_AFTER_WSP_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == -1) {
        $current_token->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$current_token->{type}};        
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } elsif ($self->{c} < 0x0020 or {
          0x0022 => 1, # "
          0x0027 => 1, # '
          0x0028 => 1, # (
      }->{$self->{c}}) { # C0 or (
        ## TODO: Should we consider matches of "(" and ")", '"', or "'"?
        $current_token->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$current_token->{type}};
        # stay in the state.
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0029) { # )
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $self->{c};
        # stay in the state.
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == URI_AFTER_WSP_STATE) {
      if ({
           0x0020 => 1, # SP
           0x0009 => 1, # \t
           0x000D => 1, # \r
           0x000A => 1, # \n
           0x000C => 1, # \f
          }->{$self->{c}}) {
        # stay in the state.
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == -1) {
        $current_token->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$current_token->{type}};        
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } elsif ($self->{c} == 0x0029) { # )
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        ## TODO: Should we consider matches of "(" and ")", '"', or "'"?
        $current_token->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$current_token->{type}};
        # stay in the state.
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_OPEN_STATE) {
      $current_token->{has_escape} = 1;
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) { # 0..9
        ## NOTE: second character of |unicode| in |escape|.
        $char = $self->{c} - 0x0030;
        $self->{state} = ESCAPE_STATE; $i = 2;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif (0x0041 <= $self->{c} and $self->{c} <= 0x0046) { # A..F
        ## NOTE: second character of |unicode| in |escape|.
        $char = $self->{c} - 0x0041 + 0xA;
        $self->{state} = ESCAPE_STATE; $i = 2;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif (0x0061 <= $self->{c} and $self->{c} <= 0x0066) { # a..f
        ## NOTE: second character of |unicode| in |escape|.
        $char = $self->{c} - 0x0061 - 0xA;
        $self->{state} = ESCAPE_STATE; $i = 2;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000A or # \n
               $self->{c} == 0x000C) { # \f
        if ($q == 0) {
          ## NOTE: In |escape| in ... in |ident|.
          $self->{state} = BEFORE_TOKEN_STATE;
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
          return $current_token;
          # reconsume
          #redo A;
        } elsif ($q == 1) {
          ## NOTE: In |escape| in |URI|.
          $current_token->{type} = {
              URI_TOKEN, URI_INVALID_TOKEN,
              URI_INVALID_TOKEN, URI_INVALID_TOKEN,
              URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
              URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
          }->{$current_token->{type}};
          $current_token->{value} .= chr $self->{c};
          $self->{state} = URI_UNQUOTED_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          ## Note: In |nl| in ... in |string| or |ident|.
          $current_token->{value} .= chr $self->{c};
          $self->{state} = STRING_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        }
      } elsif ($self->{c} == 0x000D) { # \r
        if ($q == 0) {
          ## NOTE: In |escape| in ... in |ident|.
          $self->{state} = BEFORE_TOKEN_STATE;
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
          return $current_token;
          # reconsume
          #redo A;
        } elsif ($q == 1) {
          $current_token->{type} = {
              URI_TOKEN, URI_INVALID_TOKEN,
              URI_INVALID_TOKEN, URI_INVALID_TOKEN,
              URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
              URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
          }->{$current_token->{type}};
          $current_token->{value} .= "\x0D\x0A";
          $self->{state} = URI_UNQUOTED_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          ## Note: In |nl| in ... in |string| or |ident|.
          $current_token->{value} .= "\x0D\x0A";
          $self->{state} = ESCAPE_BEFORE_LF_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        }
      } else {
        ## NOTE: second character of |escape|.
        $current_token->{value} .= chr $self->{c};
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_STATE) {
      ## NOTE: third..seventh character of |unicode| in |escape|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) { # 0..9
        $char = $char * 0x10 + $self->{c} - 0x0030;
        $self->{state} = ++$i == 7 ? ESCAPE_BEFORE_NL_STATE : ESCAPE_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif (0x0041 <= $self->{c} and $self->{c} <= 0x0046) { # A..F
        $char = $char * 0x10 + $self->{c} - 0x0041 + 0xA;
        $self->{state} = ++$i == 7 ? ESCAPE_BEFORE_NL_STATE : ESCAPE_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif (0x0061 <= $self->{c} and $self->{c} <= 0x0066) { # a..f
        $char = $char * 0x10 + $self->{c} - 0x0061 - 0xA;
        $self->{state} = ++$i == 7 ? ESCAPE_BEFORE_NL_STATE : ESCAPE_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0020 or # SP
               $self->{c} == 0x000A or # \n
               $self->{c} == 0x0009 or # \t
               $self->{c} == 0x000C) { # \f
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000D) { # \r
        $self->{state} = ESCAPE_BEFORE_LF_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        # reconsume
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_BEFORE_NL_STATE) {
      ## NOTE: eightth character of |unicode| in |escape|.
      if ($self->{c} == 0x0020 or # SP
          $self->{c} == 0x000A or # \n
          $self->{c} == 0x0009 or # \t
          $self->{c} == 0x000C) { # \f
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000D) { # \r
        $self->{state} = ESCAPE_BEFORE_NL_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        # reconsume
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_BEFORE_LF_STATE) {
      ## NOTE: |\n| in |\r\n| in |unicode| in |escape|.
      if ($self->{c} == 0x000A) { # \n
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        # reconsume
        redo A;
      }
    } elsif ($self->{state} == STRING_STATE) {
      ## NOTE: A character in |string$Q| in |string| in |STRING|, or
      ## a character in |invalid$Q| in |invalid| in |INVALID|,
      ## where |$Q = $q == 0x0022 ? 1 : 2|.
      ## Or, in |URI|.
      if ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == $q) { # " | '
        if ($current_token->{type} == STRING_TOKEN) {
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $current_token;
          #redo A;
        } else {
          $self->{state} = URI_AFTER_WSP_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        }
      } elsif ($self->{c} == 0x000A or # \n
               $self->{c} == 0x000D or # \r
               $self->{c} == 0x000C or # \f
               $self->{c} == -1) {
        $current_token->{type} = INVALID_TOKEN;
        $self->{state} = BEFORE_TOKEN_STATE;
        # reconsume
        return $current_token;
        #redo A;
      } else {
        $current_token->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == NUMBER_STATE) {
      ## NOTE: 2nd, 3rd, or ... character in |num| before |.|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $current_token->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002E) { # .
        $self->{state} = NUMBER_DOT_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{number} = $current_token->{value};
        $current_token->{value} = '';
        $self->{state} = AFTER_NUMBER_STATE;
        # reprocess
        redo A;
      }
    } elsif ($self->{state} == NUMBER_DOT_STATE) {
      ## NOTE: The character immediately following |.| in |num|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $current_token->{value} .= '.' . chr $self->{c};
        $self->{state} = NUMBER_DOT_NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        unshift @{$self->{token}}, {type => DELIM_STATE, value => '.'};
        $current_token->{number} = $current_token->{value};
        $current_token->{value} = '';
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return $current_token;
        #redo A;
      }
    } elsif ($self->{state} == NUMBER_FRACTION_STATE) {
      ## NOTE: The character immediately following |.| at the beginning of |num|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $current_token->{value} .= '.' . chr $self->{c};
        $self->{state} = NUMBER_DOT_NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return {type => DELIM_TOKEN, value => '.'};
        #redo A;
      }
    } elsif ($self->{state} == NUMBER_DOT_NUMBER_STATE) {
      ## NOTE: |[0-9]| in |num| after |.|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $current_token->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{number} = $current_token->{value};
        $current_token->{value} = '';
        $self->{state} = AFTER_NUMBER_STATE;
        # reprocess
        redo A;
      }
    } else {
      die "$0: Unknown state |$self->{state}|";
    }
  } # A

  ## TODO: |URI|, |UNICODE-RANGE|, |COMMENT|

} # get_next_token

1;
# $Date: 2007/09/08 02:40:47 $
