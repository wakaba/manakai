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
  0 DELIM PLUS GREATER COMMA TILDE DASHMATCH
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
  #$self->{t} = {type => token-type, value => value, number => number};
} # init

sub get_next_token ($) {
  my $self = shift;
  if (@{$self->{token}}) {
    return shift @{$self->{token}};
  }

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
        $self->{t} = {type => IDENT_TOKEN, value => '-', hyphen => 1};
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0055 or $self->{c} == 0x0075) { # U or u
        $self->{t} = {type => IDENT_TOKEN, value => chr $self->{c}};
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x002B) { # +
          $self->{c} = $self->{get_char}->();
          if ((0x0030 <= $self->{c} and $self->{c} <= 0x0039) or # 0..9
              (0x0041 <= $self->{c} and $self->{c} <= 0x0046) or # A..F
              (0x0061 <= $self->{c} and $self->{c} <= 0x0066) or # a..f
              $self->{c} == 0x003F) { # ?
            $self->{t}->{value} .= '+' . chr $self->{c};
            $self->{t}->{type} = UNICODE_RANGE_TOKEN;
            $self->{c} = $self->{get_char}->();
            C: for (2..6) {
              if ((0x0030 <= $self->{c} and $self->{c} <= 0x0039) or # 0..9
                  (0x0041 <= $self->{c} and $self->{c} <= 0x0046) or # A..F
                  (0x0061 <= $self->{c} and $self->{c} <= 0x0066) or # a..f
                  $self->{c} == 0x003F) { # ?
                $self->{t}->{value} .= chr $self->{c};
                $self->{c} = $self->{get_char}->();
              } else {
                last C;
              }
            } # C

            if ($self->{c} == 0x002D) { # -
              $self->{c} = $self->{get_char}->();
              if ((0x0030 <= $self->{c} and $self->{c} <= 0x0039) or # 0..9
                  (0x0041 <= $self->{c} and $self->{c} <= 0x0046) or # A..F
                  (0x0061 <= $self->{c} and $self->{c} <= 0x0066)) { # a..f
                $self->{t}->{value} .= '-' . chr $self->{c};
                $self->{c} = $self->{get_char}->();
                C: for (2..6) {
                  if ((0x0030 <= $self->{c} and $self->{c} <= 0x0039) or # 0..9
                      (0x0041 <= $self->{c} and $self->{c} <= 0x0046) or # A..F
                      (0x0061 <= $self->{c} and $self->{c} <= 0x0066)) { # a..f
                    $self->{t}->{value} .= chr $self->{c};
                    $self->{c} = $self->{get_char}->();
                  } else {
                    last C;
                  }
                } # C
                
                #
              } else {
                my $token = $self->{t};
                $self->{t} = {type => IDENT_TOKEN, value => '-'};
                $self->{state} = BEFORE_NMSTART_STATE;
                # reprocess
                return $token;
                #redo A;
              }
            }

            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            return $self->{t};
            #redo A;
          } else {
            unshift @{$self->{token}}, {type => PLUS_TOKEN};
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            return $self->{t};
            #redo A;
          }
        } else {
          $self->{state} = NAME_STATE;
          # reprocess
          redo A;
        }
      } elsif ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
               (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
               $self->{c} == 0x005F or # _
               $self->{c} > 0x007F) { # nonascii
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $self->{t} = {type => IDENT_TOKEN, value => chr $self->{c}};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $self->{t} = {type => IDENT_TOKEN, value => ''};
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0040) { # @
        ## NOTE: |@| in |ATKEYWORD|
        $self->{t} = {type => ATKEYWORD_TOKEN, value => ''};
        $self->{state} = AFTER_AT_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0022 or $self->{c} == 0x0027) { # " or '
        $self->{t} = {type => STRING_TOKEN, value => ''};
        $self->{state} = STRING_STATE; $q = $self->{c};
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0023) { # #
        ## NOTE: |#| in |HASH|.
        $self->{t} = {type => HASH_TOKEN, value => ''};
        $self->{state} = HASH_OPEN_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif (0x0030 <= $self->{c} and $self->{c} <= 0x0039) { # 0..9
        ## NOTE: |num|.
        $self->{t} = {type => NUMBER_TOKEN, value => chr $self->{c}};
        $self->{state} = NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002E) { # .
        ## NOTE: |num|.
        $self->{t} = {type => NUMBER_TOKEN, value => '0'};
        $self->{state} = NUMBER_FRACTION_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002F) { # /
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x002A) { # *
          C: {
            $self->{c} = $self->{get_char}->();
            if ($self->{c} == 0x002A) { # *
              D: {
                $self->{c} = $self->{get_char}->();
                if ($self->{c} == 0x002F) { # /
                  #
                } elsif ($self->{c} == 0x002A) { # *
                  redo D;
                } else {
                  redo C;
                }
              } # D
            } elsif ($self->{c} == -1) {
              # stay in the state
              # reprocess
              return {type => COMMENT_INVALID_TOKEN};
              #redo A;
            } else {
              redo C;
            }
          } # C

          # stay in the state.
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          # stay in the state.
          # reprocess
          return {type => DELIM_TOKEN, value => '/'};
          #redo A;
        }         
      } elsif ($self->{c} == 0x003C) { # <
        ## NOTE: |CDO|
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x0021) { # !
          $self->{c} = $self->{get_char}->();
          if ($self->{c} == 0x002D) { # -
            $self->{c} = $self->{get_char}->();
            if ($self->{c} == 0x002D) { # -
              $self->{state} = BEFORE_TOKEN_STATE;
              $self->{c} = $self->{get_char}->();
              return {type => CDO_TOKEN};
              #redo A;
            } else {
              unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '!'};
              ## NOTE: |-| in |ident| in |IDENT|
              $self->{t} = {type => IDENT_TOKEN, value => '-'};
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
        $self->{t} = {type => DELIM_TOKEN, value => chr $self->{c}};
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      }
    } elsif ($self->{state} == BEFORE_NMSTART_STATE) {
      ## NOTE: |nmstart| in |ident| in (|IDENT|, |DIMENSION|, or
      ## |FUNCTION|)
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $self->{t}->{value} .= chr $self->{c};
        $self->{t}->{type} = DIMENSION_TOKEN
            if $self->{t}->{type} == NUMBER_TOKEN;
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002D) { # -
        if ($self->{t}->{type} == IDENT_TOKEN) {
          $self->{c} = $self->{get_char}->();
          if ($self->{c} == 0x003E) { # >
            $self->{state} = BEFORE_TOKEN_STATE;
            $self->{c} = $self->{get_char}->();
            return {type => CDC_TOKEN};
            #redo A;
          } else {
            ## NOTE: |-|, |-|, $self->{c}
            #$self->{t} = {type => IDENT_TOKEN, value => '-'};
            # stay in the state
            # reconsume
            return {type => DELIM_TOKEN, value => '-'};
            #redo A;
          }
        } elsif ($self->{t}->{type} == DIMENSION_TOKEN) {
          $self->{c} = $self->{get_char}->();
          if ($self->{c} == 0x003E) { # >
            unshift @{$self->{token}}, {type => CDC_TOKEN};
            $self->{t}->{type} = NUMBER_TOKEN;
            $self->{t}->{value} = '';
            $self->{state} = BEFORE_TOKEN_STATE;
            $self->{c} = $self->{get_char}->();
            return $self->{t};
            #redo A;
          } else {
            ## NOTE: |-|, |-|, $self->{c}
            my $t = $self->{t};
            $t->{type} = NUMBER_TOKEN;
            $t->{value} = '';
            $self->{t} = {type => IDENT_TOKEN, value => '-', hyphen => 1};
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
            # stay in the state
            # reconsume
            return $t;
            #redo A;
          }
        } else {
          #
        }
      } else {
        #
      }
      
      if ($self->{t}->{type} == DIMENSION_TOKEN) {
        ## NOTE: |-| after |NUMBER|.
        unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        $self->{t}->{type} = NUMBER_TOKEN;
        $self->{t}->{value} = '';
        return $self->{t};
      } else {
        ## NOTE: |-| not followed by |nmstart|.
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return {type => DELIM_TOKEN, value => '-'};
      }
    } elsif ($self->{state} == AFTER_AT_STATE) {
      if ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $self->{t}->{value} .= chr $self->{c};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002D) { # -
        $self->{t}->{value} .= '-';
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
        $self->{t}->{value} .= chr $self->{c};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002D) { # -
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x003E) { # >
          unshift @{$self->{token}}, {type => CDC_TOKEN};
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return {type => DELIM_TOKEN, value => '@'};
          #redo A;
        } else {
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
          $self->{t} = {type => IDENT_TOKEN, value => '-'};
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
        $self->{t}->{hyphen} = 1;
        $self->{t}->{value} = '-';
        $self->{t}->{type} = DIMENSION_TOKEN;
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ((0x0041 <= $self->{c} and $self->{c} <= 0x005A) or # A..Z
               (0x0061 <= $self->{c} and $self->{c} <= 0x007A) or # a..z
               $self->{c} == 0x005F or # _
               $self->{c} > 0x007F) { # nonascii
        ## NOTE: |nmstart| in |ident|.
        $self->{t}->{value} = chr $self->{c};
        $self->{t}->{type} = DIMENSION_TOKEN;
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $self->{t}->{value} = '';
        $self->{t}->{type} = DIMENSION_TOKEN;
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0025) { # %
        $self->{t}->{type} = PERCENTAGE_TOKEN;
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return $self->{t};
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
        $self->{t}->{value} .= chr $self->{c};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
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
        $self->{t}->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0028 and # (
               $self->{t}->{type} == IDENT_TOKEN) { # (
        my $func_name = $self->{t}->{value};
        $func_name =~ tr/A-Z/a-z/; ## TODO: Unicode or ASCII case-insensitive?
        if ($func_name eq 'url' or $func_name eq 'url-prefix') {
          if ($self->{t}->{has_escape}) {
            ## TODO: warn
          }
          $self->{t}->{type}
              = $func_name eq 'url' ? URI_TOKEN : URI_PREFIX_TOKEN;
          $self->{t}->{value} = '';
          $self->{state} = URI_BEFORE_WSP_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          $self->{t}->{type} = FUNCTION_TOKEN;
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $self->{t};
          #redo A;
        }
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reconsume
        return $self->{t};
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
        $self->{t}->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}};        
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      } elsif ($self->{c} < 0x0020 or $self->{c} == 0x0028) { # C0 or (
        ## TODO: Should we consider matches of "(" and ")"?
        $self->{t}->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}};
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
        return $self->{t};
        #redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{t}->{value} .= chr $self->{c};
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
        $self->{t}->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}};        
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      } elsif ($self->{c} < 0x0020 or {
          0x0022 => 1, # "
          0x0027 => 1, # '
          0x0028 => 1, # (
      }->{$self->{c}}) { # C0 or (
        ## TODO: Should we consider matches of "(" and ")", '"', or "'"?
        $self->{t}->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}};
        # stay in the state.
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0029) { # )
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{t}->{value} .= chr $self->{c};
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
        $self->{t}->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}};        
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      } elsif ($self->{c} == 0x0029) { # )
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $self->{t};
        #redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        ## TODO: Should we consider matches of "(" and ")", '"', or "'"?
        $self->{t}->{type} = {
            URI_TOKEN, URI_INVALID_TOKEN,
            URI_INVALID_TOKEN, URI_INVALID_TOKEN,
            URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
            URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}};
        # stay in the state.
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_OPEN_STATE) {
      $self->{t}->{has_escape} = 1;
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
        $char = $self->{c} - 0x0061 + 0xA;
        $self->{state} = ESCAPE_STATE; $i = 2;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000A or # \n
               $self->{c} == 0x000C) { # \f
        if ($q == 0) {
          #
        } elsif ($q == 1) {
          ## NOTE: In |escape| in |URI|.
          $self->{t}->{type} = {
              URI_TOKEN, URI_INVALID_TOKEN,
              URI_INVALID_TOKEN, URI_INVALID_TOKEN,
              URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
              URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
          }->{$self->{t}->{type}};
          $self->{t}->{value} .= chr $self->{c};
          $self->{state} = URI_UNQUOTED_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          ## Note: In |nl| in ... in |string| or |ident|.
          $self->{t}->{value} .= chr $self->{c};
          $self->{state} = STRING_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        }
      } elsif ($self->{c} == 0x000D) { # \r
        if ($q == 0) {
          #
        } elsif ($q == 1) {
          ## NOTE: In |escape| in |URI|.
          $self->{t}->{type} = {
              URI_TOKEN, URI_INVALID_TOKEN,
              URI_INVALID_TOKEN, URI_INVALID_TOKEN,
              URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
              URI_PREFIX_INVALID_TOKEN, URI_PREFIX_INVALID_TOKEN,
          }->{$self->{t}->{type}};
          $self->{t}->{value} .= "\x0D";
          $self->{state} = ESCAPE_BEFORE_LF_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        } else {
          ## Note: In |nl| in ... in |string| or |ident|.
          $self->{t}->{value} .= "\x0D";
          $self->{state} = ESCAPE_BEFORE_LF_STATE;
          $self->{c} = $self->{get_char}->();
          redo A;
        }
      } elsif ($self->{c} == -1) {
        #
      } else {
        ## NOTE: second character of |escape|.
        $self->{t}->{value} .= chr $self->{c};
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      }

      if ($q == 0) {
        if ($self->{t}->{type} == DIMENSION_TOKEN) {
          if ($self->{t}->{hyphen} and $self->{t}->{value} eq '-') {
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
            $self->{t}->{type} = NUMBER_TOKEN;
            $self->{t}->{value} = '';
            return $self->{t};
            #redo A;
          } elsif (length $self->{t}->{value}) {
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
            return $self->{t};
            #redo A;
          } else {
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
            $self->{t}->{type} = NUMBER_TOKEN;
            $self->{t}->{value} = '';
            return $self->{t};
            #redo A;
          }
        } else {
          if ($self->{t}->{hyphen} and $self->{t}->{value} eq '-') {
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
            return {type => DELIM_TOKEN, value => '-'};
            #redo A;
          } elsif (length $self->{t}->{value}) {
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
            return $self->{t};
            #redo A;
          } else {
            $self->{state} = BEFORE_TOKEN_STATE;
            # reprocess
            return {type => DELIM_TOKEN, value => '\\'};
            #redo A;
          }
        }
      } elsif ($q == 1) {
        $self->{state} = URI_UNQUOTED_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '\\'};
        $self->{t}->{type} = {
          STRING_TOKEN, INVALID_TOKEN,
          URI_TOKEN, URI_INVALID_TOKEN,
          URI_PREFIX_TOKEN, URI_PREFIX_INVALID_TOKEN,
        }->{$self->{t}->{type}} || $self->{t}->{type};
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return $self->{t};
        #redo A;
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
        $char = $char * 0x10 + $self->{c} - 0x0061 + 0xA;
        $self->{state} = ++$i == 7 ? ESCAPE_BEFORE_NL_STATE : ESCAPE_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0020 or # SP
               $self->{c} == 0x000A or # \n
               $self->{c} == 0x0009 or # \t
               $self->{c} == 0x000C) { # \f
        $self->{t}->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000D) { # \r
        $self->{state} = ESCAPE_BEFORE_LF_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{t}->{value} .= chr $char;
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
        $self->{t}->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000D) { # \r
        $self->{state} = ESCAPE_BEFORE_NL_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{t}->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        # reconsume
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_BEFORE_LF_STATE) {
      ## NOTE: |\n| in |\r\n| in |unicode| in |escape|.
      if ($self->{c} == 0x000A) { # \n
        $self->{t}->{value} .= chr $self->{c};
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{state} = $q == 0 ? NAME_STATE :
            $q == 1 ? URI_UNQUOTED_STATE : STRING_STATE;
        # reprocess
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
        if ($self->{t}->{type} == STRING_TOKEN) {
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $self->{t};
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
        $self->{t}->{type} = INVALID_TOKEN;
        $self->{state} = BEFORE_TOKEN_STATE;
        # reconsume
        return $self->{t};
        #redo A;
      } else {
        $self->{t}->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      }
    } elsif ($self->{state} == NUMBER_STATE) {
      ## NOTE: 2nd, 3rd, or ... character in |num| before |.|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $self->{t}->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x002E) { # .
        $self->{state} = NUMBER_DOT_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{t}->{number} = $self->{t}->{value};
        $self->{t}->{value} = '';
        $self->{state} = AFTER_NUMBER_STATE;
        # reprocess
        redo A;
      }
    } elsif ($self->{state} == NUMBER_DOT_STATE) {
      ## NOTE: The character immediately following |.| in |num|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $self->{t}->{value} .= '.' . chr $self->{c};
        $self->{state} = NUMBER_DOT_NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '.'};
        $self->{t}->{number} = $self->{t}->{value};
        $self->{t}->{value} = '';
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return $self->{t};
        #redo A;
      }
    } elsif ($self->{state} == NUMBER_FRACTION_STATE) {
      ## NOTE: The character immediately following |.| at the beginning of |num|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $self->{t}->{value} .= '.' . chr $self->{c};
        $self->{state} = NUMBER_DOT_NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return {type => DELIM_TOKEN, value => '.'};
        #redo A;
      }
    } elsif ($self->{state} == NUMBER_DOT_NUMBER_STATE) {
      ## NOTE: |[0-9]| in |num| after |.|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $self->{t}->{value} .= chr $self->{c};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $self->{t}->{number} = $self->{t}->{value};
        $self->{t}->{value} = '';
        $self->{state} = AFTER_NUMBER_STATE;
        # reprocess
        redo A;
      }
    } else {
      die "$0: Unknown state |$self->{state}|";
    }
  } # A
} # get_next_token

1;
# $Date: 2007/09/08 13:43:58 $
