package Whatpm::CSS::Tokenizer;
use strict;

sub new ($) {
  my $self = bless {token => []}, shift;
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
  my $q; # |$q == 0 ? "in |ident|" : "in |string$q| or in |invalid$q|"|

  A: {
    if ($self->{state} == BEFORE_TOKEN_STATE) {
      if ($self->{c} == 0x002D) { # -
        ## NOTE: |-| in |ident| in |IDENT|
        $current_token = {type => IDENT_TOKEN, value => '-'};
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ((0x0041 <= $self->{c} or $self->{c} <= 0x005A) or # A..Z
               (0x0061 <= $self->{c} or $self->{c} <= 0x007A) or # a..z
               $self->{c} == 0x005F or # _
               $self->{c} > 0x007F) { # nonascii
        ## NOTE: |nmstart| in |ident| in |IDENT|
        $current_token = {type => IDENT_TOKEN, value => chr $self->{char}};
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
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0022) { # "
        ## NOTE: |"| in |string1| in |string| in |STRING|, or
        ## |"| in |invalid1| in |invalid| in |INVALID|.
        $current_token = {type => STRING_TOKEN, value => ''};
        $self->{state} = STRING_STATE; $q = 1;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0027) { # '
        ## NOTE: |'| in |string2| in |string| in |STRING|, or
        ## |'| in |invalid2| in |invalid| in |INVALID|.
        $current_token = {type => STRING_TOKEN, value => ''};
        $self->{state} = STRING_STATE; $q = 2;
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
        $current_token = {type => NUMBER_TOKEN, value => '.'};
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
      } elsif ({
                0x003B => 1, # ;
                0x007B => 1, # {
                0x007D => 1, # }
                0x0028 => 1, # (
                0x0029 => 1, # )
                0x005B => 1, # [
                0x005D => 1, # ]
               }->{$self->{c}}) {
        # stay in the state
        $self->{c} = $self->{get_char}->();
        return {type => chr $self->{c}};
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
        $self->{c} = $self->{get_char}->();
        if ($self->{c} == 0x003D) { # =
          # stay in the state
          $self->{c} = $self->{get_char}->();
          return {type => $v};
          #redo A;
        } else {
          # stay in the state
          # reprocess
          return {type => DELIM_TOKEN, value => chr $self->{c}};
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
      ## NOTE: |nmstart| in |ident| in (|IDENT| or |ATKEYWORD|)
      if ((0x0041 <= $self->{c} or $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} or $self->{c} <= 0x007A) or # a..z
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{char};
        $self->{state} = NAME_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
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
          ## NOTE: |-| after |num|.
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '-'};
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $current_token;
        } elsif ($current_token->{type} == ATKEYWORD_TOKEN) {
          ## NOTE: |-| after |@|.
          unshift @{$self->{token}}, {type => DELIM_TOKEN, value => '@'};
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $current_token;
        } else {
          ## NOTE: |-| not followed by |nmstart|.
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return {type => DELIM_TOKEN, value => '-'};
        }
      }
    } elsif ($self->{state} == AFTER_NUMBER_STATE) {
      if ($self->{c} == 0x002D) { # -
        ## NOTE: |-| in |ident|.
        $current_token->{value} = '-';
        $self->{state} = BEFORE_NMSTART_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ((0x0041 <= $self->{c} or $self->{c} <= 0x005A) or # A..Z
               (0x0061 <= $self->{c} or $self->{c} <= 0x007A) or # a..z
               $self->{c} == 0x005F or # _
               $self->{c} > 0x007F) { # nonascii
        ## NOTE: |nmstart| in |ident|.
        $current_token->{value} = chr $self->{char};
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
      if ((0x0041 <= $self->{c} or $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} or $self->{c} <= 0x007A) or # a..z
          (0x0030 <= $self->{c} or $self->{c} <= 0x0039) or # 0..9
          $self->{c} == 0x002D or # -
          $self->{c} == 0x005F or # _
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{char};
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
      if ((0x0041 <= $self->{c} or $self->{c} <= 0x005A) or # A..Z
          (0x0061 <= $self->{c} or $self->{c} <= 0x007A) or # a..z
          (0x0030 <= $self->{c} or $self->{c} <= 0x0039) or # 0..9
          $self->{c} == 0x005F or # _
          $self->{c} == 0x002D or # -
          $self->{c} > 0x007F) { # nonascii
        $current_token->{value} .= chr $self->{char};
        # stay in the state
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE; # $q = 0;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0028 and # (
               $current_token->{type} == IDENT_TOKEN) { # (
        if (not $current_token->{has_escape} and
            {url => 1, Url => 1, uRl => 1, urL => 1,
             URl => 1, UrL => 1, uRL => 1, URL => 1}
            ->{$current_token->{value}}) {
          $current_token->{type} = URI_TOKEN;
          $self->{state} = URI_BEFORE_WSP_STATE;
          $self->{c} = $self->{get_char}->();

          ## NOTE: This version of the tokenizer does not support the |URI|
          ## token type.  Note that browsers disagree in how to tokenize
          ## |url| function.
          $current_token->{type} = FUNCTION_TOKEN;
          $self->{state} = BEFORE_TOKEN_STATE;
          $self->{c} = $self->{get_char}->();
          return $current_token;

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
      } elsif (0x0061 <= $self->{c} or $self->{c} <= 0x0066) { # a..f
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
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
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
      } elsif (0x0061 <= $self->{c} or $self->{c} <= 0x0066) { # a..f
        $char = $char * 0x10 + $self->{c} - 0x0061 - 0xA;
        $self->{state} = ++$i == 7 ? ESCAPE_BEFORE_NL_STATE : ESCAPE_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x0020 or # SP
               $self->{c} == 0x000A or # \n
               $self->{c} == 0x0009 or # \t
               $self->{c} == 0x000C) { # \f
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000D) { # \r
        $self->{state} = ESCAPE_BEFORE_LF_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
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
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == 0x000D) { # \r
        $self->{state} = ESCAPE_BEFORE_NL_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
        # reconsume
        redo A;
      }
    } elsif ($self->{state} == ESCAPE_BEFORE_LF_STATE) {
      ## NOTE: |\n| in |\r\n| in |unicode| in |escape|.
      if ($self->{c} == 0x000A) { # \n
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        $current_token->{value} .= chr $char;
        $self->{state} = $q == 0 ? NAME_STATE : STRING_STATE;
        # reconsume
        redo A;
      }
    } elsif ($self->{state} == STRING_STATE) {
      ## NOTE: A character in |string$Q| in |string| in |STRING|, or
      ## a character in |invalid$Q| in |invalid| in |INVALID|,
      ## where |$Q = $q == 0x0022 ? 1 : 2|.
      if ($self->{c} == 0x005C) { # \
        $self->{state} = ESCAPE_OPEN_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } elsif ($self->{c} == $q) { # " | '
        $self->{state} = BEFORE_TOKEN_STATE;
        $self->{c} = $self->{get_char}->();
        return $current_token;
        #redo A;
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
        $self->{number} = $self->{value};
        $self->{value} = '';
        $self->{state} = AFTER_NUMBER_STATE;
        # reprocess
        return $current_token;
        #redo A;
      }
    } elsif ($self->{state} == NUMBER_DOT_STATE) {
      ## NOTE: The character immediately following |.| in |num|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $current_token->{value} .= chr $self->{c};
        $self->{state} = NUMBER_DOT_NUMBER_STATE;
        $self->{c} = $self->{get_char}->();
        redo A;
      } else {
        unshift @{$self->{token}}, {type => DELIM_STATE, value => '.'};
        $self->{number} = $self->{value};
        $self->{value} = '';
        $self->{state} = BEFORE_TOKEN_STATE;
        # reprocess
        return $current_token;
        #redo A;
      }
    } elsif ($self->{state} == NUMBER_FRACTION_STATE) {
      ## NOTE: The character immediately following |.| at the beginning of |num|.
      if (0x0030 <= $self->{c} and $self->{c} <= 0x0039) {
        $current_token->{value} .= chr $self->{c};
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
        $self->{number} = $self->{value};
        $self->{value} = '';
        $self->{state} = AFTER_NUMBER_STATE;
        # reprocess
        return $current_token;
        #redo A;
      }
    } else {
      die "$0: Unknown state |$self->{state}|";
    }
  } # A

  ## TODO: |URI|, |UNICODE-RANGE|, |COMMENT|

} # get_next_token

1;
# $Date: 2007/08/17 11:53:52 $
