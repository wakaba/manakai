package What::HTML;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

## This is a very, very early version of an HTML parser.

my $permitted_slash_tag_name = {
  base => 1,
  link => 1,
  meta => 1,
  hr => 1,
  br => 1,
  img=> 1,
  embed => 1,
  param => 1,
  area => 1,
  col => 1,
  input => 1,
};

sub new ($) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->{set_next_input_character} = sub {
    $self->{next_input_character} = -1;
  };
  $self->{parse_error} = sub {
    # 
  };
  return $self;
} # new

## Implementations MUST act as if state machine in the spec

sub _initialize_tokenizer ($) {
  my $self = shift;
  $self->{state} = 'data'; # MUST
  $self->{content_model_flag} = 'PCDATA'; # be
  undef $self->{current_token}; # start tag, end tag, comment, or DOCTYPE
  undef $self->{current_attribute};
  undef $self->{last_emitted_start_tag_name};
  undef $self->{last_attribute_value_state};
  $self->{char} = [];
  # $self->{next_input_character}
  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
  $self->{token} = [];
} # _initialize_tokenizer

## A token has:
##   ->{type} eq 'DOCTYPE', 'start tag', 'end tag', 'comment',
##       'character', or 'end-of-file'
##   ->{name} (DOCTYPE, start tag (tagname), end tag (tagname))
    ## ISSUE: the spec need s/tagname/tag name/
##   ->{error} == 1 or 0 (DOCTYPE)
##   ->{attributes} isa HASH (start tag, end tag)
##   ->{data} (comment, character)

## Macros
##   Macros MUST be preceded by three EXCLAMATION MARKs.
##   emit ($token)
##     Emits the specified token.

## Emitted token MUST immediately be handled by the tree construction state.

## Before each step, UA MAY check to see if either one of the scripts in
## "list of scripts that will execute as soon as possible" or the first
## script in the "list of scripts that will execute asynchronously",
## has completed loading.  If one has, then it MUST be executed
## and removed from the list.

sub _get_next_token ($) {
  my $self = shift;
  if (@{$self->{token}}) {
    return shift @{$self->{token}};
  }

  A: {
    if ($self->{state} eq 'data') {
      if ($self->{next_input_character} == 0x0026) { # &
        if ($self->{content_model_flag} eq 'PCDATA' or
            $self->{content_model_flag} eq 'RCDATA') {
          $self->{state} = 'entity data';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        } else {
          #
        }
      } elsif ($self->{next_input_character} == 0x003C) { # <
        if ($self->{content_model_flag} ne 'PLAINTEXT') {
          $self->{state} = 'tag open';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        } else {
          #
        }
      } elsif ($self->{next_input_character} == -1) {
        return  ({type => 'end-of-file'});
        last A; ## TODO: ok?
      }
      # Anything else
      my $token = {type => 'character',
                   data => chr $self->{next_input_character}};
      ## Stay in the data state
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

      return  ($token);

      redo A;
    } elsif ($self->{state} eq 'entity data') {
      ## (cannot happen in CDATA state)
      
      my $token = $self->_tokenize_attempt_to_consume_an_entity;

      $self->{state} = 'data';
      # next-input-character is already done

      unless (defined $token) {
        return  ({type => 'character', data => '&'});
      } else {
        return  ($token);
      }

      redo A;
    } elsif ($self->{state} eq 'tag open') {
      if ($self->{content_model_flag} eq 'RCDATA' or
          $self->{content_model_flag} eq 'CDATA') {
        if ($self->{next_input_character} == 0x002F) { # /
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          $self->{state} = 'close tag open';
          redo A;
        } else {
          ## reconsume
          $self->{state} = 'data';

          return  (type => 'character', data => {'/'});

          redo A;
        }
      } elsif ($self->{content_model_flag} eq 'PCDATA') {
        if ($self->{next_input_character} == 0x0021) { # !
          $self->{state} = 'markup declaration open';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        } elsif ($self->{next_input_character} == 0x002F) { # /
          $self->{state} = 'close tag open';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        } elsif (0x0041 <= $self->{next_input_character} and
                 $self->{next_input_character} <= 0x005A) { # A..Z
          $self->{current_token}
            = {type => 'start tag',
               tag_name => chr ($self->{next_input_character} + 0x0020)};
          $self->{state} = 'tag name';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        } elsif (0x0061 <= $self->{next_input_character} and
                 $self->{next_input_character} <= 0x007A) { # a..z
          $self->{current_token} = {type => 'start tag',
                            tag_name => chr ($self->{next_input_character})};
          $self->{state} = 'tag name';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        } elsif ($self->{next_input_character} == 0x003E) { # >
          $self->{parse_error}->();
          $self->{state} = 'data';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

          return  ({type => 'character', data => '>'});

          redo A;
        } elsif ($self->{next_input_character} == 0x003F) { # ?
          $self->{parse_error}->();
          $self->{state} = 'bogus comment';
          ## $self->{next_input_character} is intentionally left as is
          redo A;
        } else {
          $self->{parse_error}->();
          $self->{state} = 'data';
          ## reconsume

          return  ({type => 'character', data => '<'});

          redo A;
        }
      } else {
        die "$0: $self->{content_model_flag}: Unknown content model flag";
      }
    } elsif ($self->{state} eq 'close tag open') {
      if ($self->{content_model_flag} eq 'RCDATA' or
          $self->{content_model_flag} eq 'CDATA') {
        my @next_char;
        TAGNAME: for (my $i = 0; $i < length $self->{last_emitted_start_tag_name}; $i++) {
          push @next_char, $self->{next_input_character};
          my $c = ord substr ($self->{last_emitted_start_tag_name}, $i, 1);
          my $C = 0x0061 <= $c && $c <= 0x007A ? $c - 0x0020 : $c;
          if ($self->{next_input_character} == $c or $self->{next_input_character} == $C) {
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            next TAGNAME;
          } else {
            $self->{parse_error}->();
            $self->{next_input_character} = shift @next_char; # reconsume
            unshift @{$self->{char}},  (@next_char);
            $self->{state} = 'data';

            return  ({type => 'character', data => '</'});

            redo A;
          }
        }
    
        unless ($self->{next_input_character} == 0x0009 or
                $self->{next_input_character} == 0x000A or
                $self->{next_input_character} == 0x000B or
                $self->{next_input_character} == 0x000C or
                $self->{next_input_character} == 0x0020 or
                $self->{next_input_character} == 0x003E or
                $self->{next_input_character} == 0x002F or
                $self->{next_input_character} == 0x003C or
                $self->{next_input_character} == -1) {
          $self->{parse_error}->();
          $self->{next_input_character} = shift @next_char; # reconsume
          unshift @{$self->{char}},  (@next_char);
          $self->{state} = 'data';

          return  ({type => 'character', data => '</'});

          redo A;
        } else {
          $self->{next_input_character} = shift @next_char;
          unshift @{$self->{char}},  (@next_char);
          # and consume...
        }
      }
      
      if (0x0041 <= $self->{next_input_character} and
          $self->{next_input_character} <= 0x005A) { # A..Z
        $self->{current_token} = {type => 'end tag',
                          tag_name => chr ($self->{next_input_character} + 0x0020)};
        $self->{state} = 'tag name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif (0x0061 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x007A) { # a..z
        $self->{current_token} = {type => 'end tag',
                          tag_name => chr ($self->{next_input_character})};
        $self->{state} = 'tag name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{parse_error}->();
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{state} = 'data';
        # reconsume

        return  ({type => 'character', data => '</'});

        redo A;
      } else {
        $self->{parse_error}->();
        $self->{state} = 'bogus comment';
        ## $self->{next_input_character} is intentionally left as is
        redo A;
      }
    } elsif ($self->{state} eq 'tag name') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        $self->{state} = 'before attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif (0x0041 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x005A) { # A..Z
        $self->{current_token}->{tag_name} .= chr ($self->{next_input_character} + 0x0020);
          # start tag or end tag
        ## Stay in this state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003C or # <
               $self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif ($self->{next_input_character} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 0x003E and # >
            $self->{current_token}->{type} eq 'start tag' and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          #
        } else {
          $self->{parse_error}->();
        }
        $self->{state} = 'before attribute name';
        # next-input-character is already done
        redo A;
      } else {
        $self->{current_token}->{tag_name} .= chr $self->{next_input_character};
          # start tag or end tag
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'before attribute name') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif (0x0041 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x005A) { # A..Z
        $self->{current_attribute} = {name => chr ($self->{next_input_character} + 0x0020),
                              value => ''};
        $self->{state} = 'attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 0x003E and # >
            $self->{current_token}->{type} eq 'start tag' and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          #
        } else {
          $self->{parse_error}->();
        }
        ## Stay in the state
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_input_character} == 0x003C or # <
               $self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute} = {name => chr ($self->{next_input_character}),
                              value => ''};
        $self->{state} = 'attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'attribute name') {
      my $before_leave = sub {
        if (exists $self->{current_token}->{attribute} # start tag or end tag
            ->{$self->{current_attribute}->{name}}) { # MUST
          $self->{parse_error}->();
          ## Discard $self->{current_attribute} # MUST
        } else {
          $self->{current_token}->{attribute}->{$self->{current_attribute}->{name}}
            = $self->{current_attribute};
        }
        undef $self->{current_attribute};
      }; # $before_leave

      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        $before_leave->();
        $self->{state} = 'after attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003D) { # =
        $before_leave->();
        $self->{state} = 'before attribute value';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $before_leave->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif (0x0041 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x005A) { # A..Z
        $self->{current_attribute}->{name} .= chr ($self->{next_input_character} + 0x0020);
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x002F) { # /
        $before_leave->();
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 0x003E and # >
            $self->{current_token}->{type} eq 'start tag' and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          #
        } else {
          $self->{parse_error}->();
        }
        $self->{state} = 'before attribute name';
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_input_character} == 0x003C or # <
               $self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $before_leave->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute}->{name} .= chr ($self->{next_input_character});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'after attribute name') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003D) { # =
        $self->{state} = 'before attribute value';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif (0x0041 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x005A) { # A..Z
        $self->{current_attribute} = {name => chr ($self->{next_input_character} + 0x0020),
                              value => ''};
        $self->{state} = 'attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 0x003E and # >
            $self->{current_token}->{type} eq 'start tag' and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          #
        } else {
          $self->{parse_error}->();
        }
        $self->{state} = 'before attribute name';
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_input_character} == 0x003C or # <
               $self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute} = {name => chr ($self->{next_input_character}),
                              value => ''};
        $self->{state} = 'attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;        
      }
    } elsif ($self->{state} eq 'before attribute value') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP      
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0022) { # "
        $self->{state} = 'attribute value (double-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0026) { # &
        $self->{state} = 'attribute value (unquoted)';
        ## reconsume
        redo A;
      } elsif ($self->{next_input_character} == 0x0027) { # '
        $self->{state} = 'attribute value (single-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif ($self->{next_input_character} == 0x003C or # <
               $self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute}->{value} .= chr ($self->{next_input_character});
        $self->{state} = 'attribute value (unquoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'attribute value (double-quoted)') {
      if ($self->{next_input_character} == 0x0022) { # "
        $self->{state} = 'before attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0026) { # &
        $self->{last_attribute_value_state} = 'attribute value (double-quoted)';
        $self->{state} = 'entity in attribute value';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute}->{value} .= chr ($self->{next_input_character});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'attribute value (single-quoted)') {
      if ($self->{next_input_character} == 0x0027) { # '
        $self->{state} = 'before attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0026) { # &
        $self->{last_attribute_value_state} = 'attribute value (single-quoted)';
        $self->{state} = 'entity in attribute value';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute}->{value} .= chr ($self->{next_input_character});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'attribute value (unquoted)') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # HT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        $self->{state} = 'before attribute name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0026) { # &
        $self->{last_attribute_value_state} = 'attribute value (unquoted)';
        $self->{state} = 'entity in attribute value';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } elsif ($self->{next_input_character} == 0x003C or # <
               $self->{next_input_character} == -1) {
        $self->{parse_error}->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attribute}) {
            $self->{parse_error}->();
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_attribute}->{value} .= chr ($self->{next_input_character});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'entity in attribute value') {
      my $token = $self->_tokenize_attempt_to_consume_an_entity;

      unless (defined $token) {
        $self->{current_attribute}->{value} .= '&';
      } else {
        $self->{current_attribute}->{value} .= $token->{data};
        ## ISSUE: spec says "append the returned character token to the current attribute's value"
      }

      $self->{state} = $self->{last_attribute_value_state};
      # next-input-character is already done
      redo A;
    } elsif ($self->{state} eq 'bogus comment') {
      ## (only happen if PCDATA state)
      
      my $token = {type => 'comment', data => ''};

      BC: {
        if ($self->{next_input_character} == 0x003E) { # >
          $self->{state} = 'data';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

          return  ($token);

          redo A;
        } elsif ($self->{next_input_character} == -1) { 
          $self->{state} = 'data';
          ## reconsume

          return  ($token);

          redo A;
        } else {
          $token->{data} .= chr ($self->{next_input_character});
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo BC;
        }
      } # BC
    } elsif ($self->{state} eq 'markup declaration open') {
      ## (only happen if PCDATA state)

      my @next_char;
      push @next_char, $self->{next_input_character};
      
      if ($self->{next_input_character} == 0x002D) { # -
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        push @next_char, $self->{next_input_character};
        if ($self->{next_input_character} == 0x002D) { # -
          $self->{current_token} = {type => 'comment', data => ''};
          $self->{state} = 'comment';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo A;
        }
      } elsif ($self->{next_input_character} == 0x0044 or # D
               $self->{next_input_character} == 0x0064) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        push @next_char, $self->{next_input_character};
        if ($self->{next_input_character} == 0x004F or # O
            $self->{next_input_character} == 0x006F) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          push @next_char, $self->{next_input_character};
          if ($self->{next_input_character} == 0x0043 or # C
              $self->{next_input_character} == 0x0063) { # c
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            push @next_char, $self->{next_input_character};
            if ($self->{next_input_character} == 0x0054 or # T
                $self->{next_input_character} == 0x0074) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              push @next_char, $self->{next_input_character};
              if ($self->{next_input_character} == 0x0059 or # Y
                  $self->{next_input_character} == 0x0079) { # y
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                push @next_char, $self->{next_input_character};
                if ($self->{next_input_character} == 0x0050 or # P
                    $self->{next_input_character} == 0x0070) { # p
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  push @next_char, $self->{next_input_character};
                  if ($self->{next_input_character} == 0x0045 or # E
                      $self->{next_input_character} == 0x0065) { # e
                    ## ISSUE: What a stupid code this is!
                    $self->{state} = 'DOCTYPE';
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    redo A;
                  }
                }
              }
            }
          }
        }
      }

      $self->{parse_error}->();
      $self->{next_input_character} = shift @next_char;
      unshift @{$self->{char}},  (@next_char);
      $self->{state} = 'bogus comment';
      redo A;
      
      ## ISSUE: typos in spec: chacacters, is is a parse error
      ## ISSUE: spec is somewhat unclear on "is the first character that will be in the comment"; what is "that will be in the comment" is what the algorithm defines, isn't it?
    } elsif ($self->{state} eq 'comment') {
      if ($self->{next_input_character} == 0x002D) { # -
        $self->{state} = 'comment dash';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_token}->{data} .= chr ($self->{next_input_character}); # comment
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'comment dash') {
      if ($self->{next_input_character} == 0x002D) { # -
        $self->{state} = 'comment end';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_token}->{data} .= '-' . chr ($self->{next_input_character}); # comment
        $self->{state} = 'comment';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'comment end') {
      if ($self->{next_input_character} == 0x003E) { # >
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # comment
        undef $self->{current_token};

        redo A;
      } elsif ($self->{next_input_character} == 0x002D) { # -
        $self->{parse_error}->();
        $self->{current_token}->{data} .= '-'; # comment
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment
        undef $self->{current_token};

        redo A;
      } else {
        $self->{parse_error}->();
        $self->{current_token}->{data} .= '--' . chr ($self->{next_input_character}); # comment
        $self->{state} = 'comment';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } 
    } elsif ($self->{state} eq 'DOCTYPE') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        $self->{state} = 'before DOCTYPE name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } else {
        $self->{parse_error}->();
        $self->{state} = 'before DOCTYPE name';
        ## reconsume
        redo A;
      }
    } elsif ($self->{state} eq 'before DOCTYPE name') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif (0x0061 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x007A) { # a..z
        $self->{current_token} = {type => 'DOCTYPE',
                          name => chr ($self->{next_input_character} - 0x0020),
                          error => 1};
        $self->{state} = 'DOCTYPE name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{parse_error}->();
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ({type => 'DOCTYPE', name => '', error => 1});

        redo A;
      } elsif ($self->{next_input_character} == -1) { 
        $self->{parse_error}->();
        $self->{state} = 'data';
        ## reconsume

        return  ({type => 'DOCTYPE', name => '', error => 1});

        redo A;
      } else {
        $self->{current_token} = {type => 'DOCTYPE',
                          name => chr ($self->{next_input_character}),
                          error => 1};
        $self->{state} = 'DOCTYPE name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'DOCTYPE name') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        $self->{current_token}->{error} = ($self->{current_token}->{name} ne 'HTML'); # DOCTYPE
        $self->{state} = 'after DOCTYPE name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{current_token}->{error} = ($self->{current_token}->{name} ne 'HTML'); # DOCTYPE
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE
        undef $self->{current_token};

        redo A;
      } elsif (0x0061 <= $self->{next_input_character} and
               $self->{next_input_character} <= 0x007A) { # a..z
        $self->{current_token}->{name} .= chr ($self->{next_input_character} - 0x0020); # DOCTYPE
        #$self->{current_token}->{error} = ($self->{current_token}->{name} ne 'HTML');
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{current_token}->{error} = ($self->{current_token}->{name} ne 'HTML'); # DOCTYPE
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token});
        undef $self->{current_token};

        redo A;
      } else {
        $self->{current_token}->{name} .= chr ($self->{next_input_character} - 0x0020); # DOCTYPE
        #$self->{current_token}->{error} = ($self->{current_token}->{name} ne 'HTML');
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'after DOCTYPE name') {
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE
        undef $self->{current_token};

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # DOCTYPE
        undef $self->{current_token};

        redo A;
      } else {
        $self->{parse_error}->();
        $self->{current_token}->{error} = 1; # DOCTYPE
        $self->{state} = 'bogus DOCTYPE';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'bogus DOCTYPE') {
      if ($self->{next_input_character} == 0x003E) { # >
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE
        undef $self->{current_token};

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}->();
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # DOCTYPE
        undef $self->{current_token};

        redo A;
      } else {
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } else {
      die "$0: $self->{state}: Unknown state";
    }
  } # A   

  die "$0: _get_next_token: unexpected case";
} # _get_next_token

sub _tokenize_attempt_to_consume_an_entity ($) {
  my $self = shift;
  my $r;
  
  if ($self->{next_input_character} == 0x0023) { # #
    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
    my $num;
    if ($self->{next_input_character} == 0x0078 or # x
        $self->{next_input_character} == 0x0058) { # X
      X: {
        my $x_char = $self->{next_input_character};
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if (0x0030 <= $self->{next_input_character} and 
            $self->{next_input_character} <= 0x0039) { # 0..9
          $num ||= 0;
          $num *= 0x10;
          $num += $self->{next_input_character} - 0x0030;
          redo X;
        } elsif (0x0061 <= $self->{next_input_character} and
                 $self->{next_input_character} <= 0x0066) { # a..f
          ## ISSUE: the spec says U+0078, which is apparently incorrect
          $num ||= 0;
          $num *= 0x10;
          $num += $self->{next_input_character} - 0x0060 + 9;
          redo X;
        } elsif (0x0041 <= $self->{next_input_character} and
                 $self->{next_input_character} <= 0x0046) { # A..F
          ## ISSUE: the spec says U+0058, which is apparently incorrect
          $num ||= 0;
          $num *= 0x10;
          $num += $self->{next_input_character} - 0x0040 + 9;
          redo X;
        } elsif (not defined $num) { # no hexadecimal digit
          $self->{parse_error}->();
          $self->{next_input_character} = 0x0023; # #
          unshift @{$self->{char}},  ($x_char);
          last X; ## nothing is returned
        } elsif ($self->{next_input_character} == 0x003B) { # ;
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        } else {
          $self->{parse_error}->();
        }

        ## TODO: check the definition for |a valid Unicode character|.
        if ($num > 1114111 or $num == 0) {
          $num = 0xFFFD; # REPLACEMENT CHARACTER
          ## ISSUE: Why this is not an error?
        }

        $r = {type => 'character', data => chr $num};
      } # X
    } else {
      D: {
        if (0x0030 <= $self->{next_input_character} and 
            $self->{next_input_character} <= 0x0039) { # 0..9
          $num *= 10;
          $num += $self->{next_input_character} - 0x0030;
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          redo D;
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  ($self->{next_input_character});
          $self->{next_input_character} = 0x0023; # #
          last D; ## nothing is returned
        }

        if ($self->{next_input_character} == 0x003B) { # ;
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        } else {
          $self->{parse_error}->();
        }

        ## TODO: check the definition for |a valid Unicode character|.
        if ($num > 1114111 or $num == 0) {
          $num = 0xFFFD; # REPLACEMENT CHARACTER
          ## ISSUE: Why this is not an error?
        }

        $r = {type => 'character', data => chr $num};
      } # D
    }
      } elsif ($self->{next_input_character} == 65) { # A
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 69) { # E
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00C6}>}; # AElig
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (69, 108, 105, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (69, 108, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (69, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00C1}>}; # Aacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 65;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00C2}>}; # Acirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00C0}>}; # Agrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 65;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 108) { # l
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 104) { # h
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{0391}>}; # Alpha
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (108, 112, 104, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (108, 112, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (108, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 110) { # n
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00C5}>}; # Aring
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 105, 110, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 105, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00C3}>}; # Atilde
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 108, 100, $self->{next_input_character});
                $self->{next_input_character} = 65;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 108, $self->{next_input_character});
              $self->{next_input_character} = 65;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (116, 105, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00C4}>}; # Auml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 65;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } elsif ($self->{next_input_character} == 77) { # M
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 80) { # P
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{0026}>}; # AMP
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (77, $self->{next_input_character});
          $self->{next_input_character} = 65;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 65;
      }
    } elsif ($self->{next_input_character} == 66) { # B
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0392}>}; # Beta
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 116, $self->{next_input_character});
            $self->{next_input_character} = 66;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 66;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 66;
      }
    } elsif ($self->{next_input_character} == 67) { # C
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 105) { # i
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 108) { # l
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00C7}>}; # Ccedil
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (99, 101, 100, 105, $self->{next_input_character});
                $self->{next_input_character} = 67;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 101, 100, $self->{next_input_character});
              $self->{next_input_character} = 67;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 101, $self->{next_input_character});
            $self->{next_input_character} = 67;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 67;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03A7}>}; # Chi
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 67;
        }
      } elsif ($self->{next_input_character} == 79) { # O
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 80) { # P
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 89) { # Y
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00A9}>}; # COPY
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (79, 80, $self->{next_input_character});
            $self->{next_input_character} = 67;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (79, $self->{next_input_character});
          $self->{next_input_character} = 67;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 67;
      }
    } elsif ($self->{next_input_character} == 68) { # D
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 114) { # r
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2021}>}; # Dagger
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 103, 103, 101, $self->{next_input_character});
                $self->{next_input_character} = 68;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 103, 103, $self->{next_input_character});
              $self->{next_input_character} = 68;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 103, $self->{next_input_character});
            $self->{next_input_character} = 68;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 68;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{0394}>}; # Delta
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 108, 116, $self->{next_input_character});
              $self->{next_input_character} = 68;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 108, $self->{next_input_character});
            $self->{next_input_character} = 68;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 68;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 68;
      }
    } elsif ($self->{next_input_character} == 69) { # E
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 84) { # T
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 72) { # H
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00D0}>}; # ETH
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (84, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00C9}>}; # Eacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 69;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 69;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 69;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00CA}>}; # Ecirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 69;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 69;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00C8}>}; # Egrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 69;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 69;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 69;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 110) { # n
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{0395}>}; # Epsilon
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (112, 115, 105, 108, 111, $self->{next_input_character});
                  $self->{next_input_character} = 69;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (112, 115, 105, 108, $self->{next_input_character});
                $self->{next_input_character} = 69;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (112, 115, 105, $self->{next_input_character});
              $self->{next_input_character} = 69;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 115, $self->{next_input_character});
            $self->{next_input_character} = 69;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{0397}>}; # Eta
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00CB}>}; # Euml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 69;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 69;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 69;
      }
    } elsif ($self->{next_input_character} == 71) { # G
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{0393}>}; # Gamma
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 109, 109, $self->{next_input_character});
              $self->{next_input_character} = 71;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 109, $self->{next_input_character});
            $self->{next_input_character} = 71;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 71;
        }
      } elsif ($self->{next_input_character} == 84) { # T
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{003E}>}; # GT
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 71;
      }
    } elsif ($self->{next_input_character} == 73) { # I
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00CD}>}; # Iacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 73;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 73;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 73;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 73;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00CE}>}; # Icirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 73;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 73;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 73;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00CC}>}; # Igrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 73;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 73;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 73;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 73;
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0399}>}; # Iota
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 116, $self->{next_input_character});
            $self->{next_input_character} = 73;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 73;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00CF}>}; # Iuml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 73;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 73;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 73;
      }
    } elsif ($self->{next_input_character} == 75) { # K
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{039A}>}; # Kappa
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 112, 112, $self->{next_input_character});
              $self->{next_input_character} = 75;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 112, $self->{next_input_character});
            $self->{next_input_character} = 75;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 75;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 75;
      }
    } elsif ($self->{next_input_character} == 76) { # L
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 98) { # b
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 97) { # a
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{039B}>}; # Lambda
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 109, 98, 100, $self->{next_input_character});
                $self->{next_input_character} = 76;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 109, 98, $self->{next_input_character});
              $self->{next_input_character} = 76;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 109, $self->{next_input_character});
            $self->{next_input_character} = 76;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 76;
        }
      } elsif ($self->{next_input_character} == 84) { # T
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{003C}>}; # LT
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 76;
      }
    } elsif ($self->{next_input_character} == 77) { # M
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{039C}>}; # Mu
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 77;
      }
    } elsif ($self->{next_input_character} == 78) { # N
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00D1}>}; # Ntilde
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 108, 100, $self->{next_input_character});
                $self->{next_input_character} = 78;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 108, $self->{next_input_character});
              $self->{next_input_character} = 78;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (116, 105, $self->{next_input_character});
            $self->{next_input_character} = 78;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 78;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{039D}>}; # Nu
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 78;
      }
    } elsif ($self->{next_input_character} == 79) { # O
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 69) { # E
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{0152}>}; # OElig
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (69, 108, 105, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (69, 108, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (69, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00D3}>}; # Oacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 79;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00D4}>}; # Ocirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00D2}>}; # Ograve
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 79;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 109) { # m
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03A9}>}; # Omega
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (109, 101, 103, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 101, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } elsif ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 99) { # c
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 114) { # r
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 110) { # n
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{039F}>}; # Omicron
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (109, 105, 99, 114, 111, $self->{next_input_character});
                  $self->{next_input_character} = 79;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (109, 105, 99, 114, $self->{next_input_character});
                $self->{next_input_character} = 79;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (109, 105, 99, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 105, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (109, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 104) { # h
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00D8}>}; # Oslash
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (115, 108, 97, 115, $self->{next_input_character});
                $self->{next_input_character} = 79;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 108, 97, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 108, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00D5}>}; # Otilde
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 108, 100, $self->{next_input_character});
                $self->{next_input_character} = 79;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 108, $self->{next_input_character});
              $self->{next_input_character} = 79;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (116, 105, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00D6}>}; # Ouml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 79;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 79;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 79;
      }
    } elsif ($self->{next_input_character} == 80) { # P
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03A6}>}; # Phi
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 80;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{03A0}>}; # Pi
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2033}>}; # Prime
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 105, 109, $self->{next_input_character});
              $self->{next_input_character} = 80;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 105, $self->{next_input_character});
            $self->{next_input_character} = 80;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 80;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03A8}>}; # Psi
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 80;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 80;
      }
    } elsif ($self->{next_input_character} == 82) { # R
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03A1}>}; # Rho
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 82;
        }
      } elsif ($self->{next_input_character} == 69) { # E
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 71) { # G
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00AE}>}; # REG
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (69, $self->{next_input_character});
          $self->{next_input_character} = 82;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 82;
      }
    } elsif ($self->{next_input_character} == 83) { # S
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 110) { # n
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{0160}>}; # Scaron
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (99, 97, 114, 111, $self->{next_input_character});
                $self->{next_input_character} = 83;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 97, 114, $self->{next_input_character});
              $self->{next_input_character} = 83;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 97, $self->{next_input_character});
            $self->{next_input_character} = 83;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 83;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03A3}>}; # Sigma
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 103, 109, $self->{next_input_character});
              $self->{next_input_character} = 83;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 103, $self->{next_input_character});
            $self->{next_input_character} = 83;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (105, $self->{next_input_character});
          $self->{next_input_character} = 83;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 83;
      }
    } elsif ($self->{next_input_character} == 84) { # T
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 72) { # H
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 79) { # O
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 82) { # R
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 78) { # N
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00DE}>}; # THORN
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (72, 79, 82, $self->{next_input_character});
              $self->{next_input_character} = 84;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (72, 79, $self->{next_input_character});
            $self->{next_input_character} = 84;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (72, $self->{next_input_character});
          $self->{next_input_character} = 84;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03A4}>}; # Tau
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 84;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{0398}>}; # Theta
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (104, 101, 116, $self->{next_input_character});
              $self->{next_input_character} = 84;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (104, 101, $self->{next_input_character});
            $self->{next_input_character} = 84;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 84;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 84;
      }
    } elsif ($self->{next_input_character} == 85) { # U
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00DA}>}; # Uacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 85;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 85;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 85;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 85;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00DB}>}; # Ucirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 85;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 85;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 85;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00D9}>}; # Ugrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 85;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 85;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 85;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 85;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 110) { # n
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{03A5}>}; # Upsilon
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (112, 115, 105, 108, 111, $self->{next_input_character});
                  $self->{next_input_character} = 85;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (112, 115, 105, 108, $self->{next_input_character});
                $self->{next_input_character} = 85;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (112, 115, 105, $self->{next_input_character});
              $self->{next_input_character} = 85;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 115, $self->{next_input_character});
            $self->{next_input_character} = 85;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 85;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00DC}>}; # Uuml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 85;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 85;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 85;
      }
    } elsif ($self->{next_input_character} == 88) { # X
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{039E}>}; # Xi
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 88;
      }
    } elsif ($self->{next_input_character} == 89) { # Y
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00DD}>}; # Yacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 89;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 89;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 89;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 89;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0178}>}; # Yuml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 89;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 89;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 89;
      }
    } elsif ($self->{next_input_character} == 90) { # Z
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0396}>}; # Zeta
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 116, $self->{next_input_character});
            $self->{next_input_character} = 90;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 90;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 90;
      }
    } elsif ($self->{next_input_character} == 97) { # a
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00E1}>}; # aacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 97;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00E2}>}; # acirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } elsif ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00B4}>}; # acute
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 117, 116, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 117, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00E6}>}; # aelig
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 108, 105, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 108, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00E0}>}; # agrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 97;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 108) { # l
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 102) { # f
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 121) { # y
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 109) { # m
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{2135}>}; # alefsym
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (108, 101, 102, 115, 121, $self->{next_input_character});
                  $self->{next_input_character} = 97;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (108, 101, 102, 115, $self->{next_input_character});
                $self->{next_input_character} = 97;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (108, 101, 102, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (108, 101, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } elsif ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 104) { # h
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03B1}>}; # alpha
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (108, 112, 104, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (108, 112, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (108, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 109) { # m
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{0026}>}; # amp
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (109, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 110) { # n
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 100) { # d
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{2227}>}; # and
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{2220}>}; # ang
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (110, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 115) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0027}>}; # apos
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 111, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 110) { # n
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00E5}>}; # aring
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 105, 110, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 105, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 121) { # y
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 112) { # p
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2248}>}; # asymp
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 121, 109, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 121, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00E3}>}; # atilde
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 108, 100, $self->{next_input_character});
                $self->{next_input_character} = 97;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 108, $self->{next_input_character});
              $self->{next_input_character} = 97;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (116, 105, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00E4}>}; # auml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 97;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 97;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 97;
      }
    } elsif ($self->{next_input_character} == 98) { # b
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 100) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{201E}>}; # bdquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (100, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 98;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (100, 113, $self->{next_input_character});
            $self->{next_input_character} = 98;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (100, $self->{next_input_character});
          $self->{next_input_character} = 98;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{03B2}>}; # beta
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 116, $self->{next_input_character});
            $self->{next_input_character} = 98;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 98;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 118) { # v
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 98) { # b
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 114) { # r
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00A6}>}; # brvbar
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (114, 118, 98, 97, $self->{next_input_character});
                $self->{next_input_character} = 98;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 118, 98, $self->{next_input_character});
              $self->{next_input_character} = 98;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 118, $self->{next_input_character});
            $self->{next_input_character} = 98;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 98;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2022}>}; # bull
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 108, $self->{next_input_character});
            $self->{next_input_character} = 98;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 98;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 98;
      }
    } elsif ($self->{next_input_character} == 99) { # c
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{2229}>}; # cap
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 105) { # i
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 108) { # l
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00E7}>}; # ccedil
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (99, 101, 100, 105, $self->{next_input_character});
                $self->{next_input_character} = 99;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 101, 100, $self->{next_input_character});
              $self->{next_input_character} = 99;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 101, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 100) { # d
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00B8}>}; # cedil
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 100, 105, $self->{next_input_character});
              $self->{next_input_character} = 99;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 100, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } elsif ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00A2}>}; # cent
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 110, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03C7}>}; # chi
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 99) { # c
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{02C6}>}; # circ
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 114, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (105, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 108) { # l
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 98) { # b
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2663}>}; # clubs
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (108, 117, 98, $self->{next_input_character});
              $self->{next_input_character} = 99;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (108, 117, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (108, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2245}>}; # cong
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 110, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } elsif ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 121) { # y
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00A9}>}; # copy
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 112, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 114) { # r
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{21B5}>}; # crarr
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 97, 114, $self->{next_input_character});
              $self->{next_input_character} = 99;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 97, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{222A}>}; # cup
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 110) { # n
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00A4}>}; # curren
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (117, 114, 114, 101, $self->{next_input_character});
                $self->{next_input_character} = 99;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (117, 114, 114, $self->{next_input_character});
              $self->{next_input_character} = 99;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 114, $self->{next_input_character});
            $self->{next_input_character} = 99;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 99;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 99;
      }
    } elsif ($self->{next_input_character} == 100) { # d
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 65) { # A
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{21D3}>}; # dArr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (65, 114, $self->{next_input_character});
            $self->{next_input_character} = 100;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (65, $self->{next_input_character});
          $self->{next_input_character} = 100;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 114) { # r
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2020}>}; # dagger
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 103, 103, 101, $self->{next_input_character});
                $self->{next_input_character} = 100;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 103, 103, $self->{next_input_character});
              $self->{next_input_character} = 100;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 103, $self->{next_input_character});
            $self->{next_input_character} = 100;
          }
        } elsif ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2193}>}; # darr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 114, $self->{next_input_character});
            $self->{next_input_character} = 100;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 100;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00B0}>}; # deg
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03B4}>}; # delta
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 108, 116, $self->{next_input_character});
              $self->{next_input_character} = 100;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 108, $self->{next_input_character});
            $self->{next_input_character} = 100;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 100;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2666}>}; # diams
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 97, 109, $self->{next_input_character});
              $self->{next_input_character} = 100;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 97, $self->{next_input_character});
            $self->{next_input_character} = 100;
          }
        } elsif ($self->{next_input_character} == 118) { # v
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F7}>}; # divide
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (105, 118, 105, 100, $self->{next_input_character});
                $self->{next_input_character} = 100;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 118, 105, $self->{next_input_character});
              $self->{next_input_character} = 100;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 118, $self->{next_input_character});
            $self->{next_input_character} = 100;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (105, $self->{next_input_character});
          $self->{next_input_character} = 100;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 100;
      }
    } elsif ($self->{next_input_character} == 101) { # e
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00E9}>}; # eacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 101;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00EA}>}; # ecirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00E8}>}; # egrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 101;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 109) { # m
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 121) { # y
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2205}>}; # empty
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (109, 112, 116, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 112, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } elsif ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2003}>}; # emsp
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 115, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (109, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 110) { # n
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2002}>}; # ensp
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (110, 115, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (110, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 110) { # n
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{03B5}>}; # epsilon
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (112, 115, 105, 108, 111, $self->{next_input_character});
                  $self->{next_input_character} = 101;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (112, 115, 105, 108, $self->{next_input_character});
                $self->{next_input_character} = 101;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (112, 115, 105, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 115, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 113) { # q
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2261}>}; # equiv
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (113, 117, 105, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (113, 117, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (113, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03B7}>}; # eta
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 104) { # h
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00F0}>}; # eth
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00EB}>}; # euml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } elsif ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 111) { # o
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{20AC}>}; # euro
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 114, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } elsif ($self->{next_input_character} == 120) { # x
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 115) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2203}>}; # exist
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (120, 105, 115, $self->{next_input_character});
              $self->{next_input_character} = 101;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (120, 105, $self->{next_input_character});
            $self->{next_input_character} = 101;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (120, $self->{next_input_character});
          $self->{next_input_character} = 101;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 101;
      }
    } elsif ($self->{next_input_character} == 102) { # f
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 110) { # n
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 102) { # f
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0192}>}; # fnof
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (110, 111, $self->{next_input_character});
            $self->{next_input_character} = 102;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (110, $self->{next_input_character});
          $self->{next_input_character} = 102;
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 108) { # l
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2200}>}; # forall
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (111, 114, 97, 108, $self->{next_input_character});
                $self->{next_input_character} = 102;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (111, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 102;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 114, $self->{next_input_character});
            $self->{next_input_character} = 102;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 102;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 99) { # c
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 49) { # 1
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 50) { # 2
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00BD}>}; # frac12
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } elsif ($self->{next_input_character} == 52) { # 4
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00BC}>}; # frac14
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (114, 97, 99, 49, $self->{next_input_character});
                $self->{next_input_character} = 102;
              }
            } elsif ($self->{next_input_character} == 51) { # 3
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 52) { # 4
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00BE}>}; # frac34
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (114, 97, 99, 51, $self->{next_input_character});
                $self->{next_input_character} = 102;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 97, 99, $self->{next_input_character});
              $self->{next_input_character} = 102;
            }
          } elsif ($self->{next_input_character} == 115) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2044}>}; # frasl
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 97, 115, $self->{next_input_character});
              $self->{next_input_character} = 102;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 97, $self->{next_input_character});
            $self->{next_input_character} = 102;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 102;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 102;
      }
    } elsif ($self->{next_input_character} == 103) { # g
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03B3}>}; # gamma
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 109, 109, $self->{next_input_character});
              $self->{next_input_character} = 103;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 109, $self->{next_input_character});
            $self->{next_input_character} = 103;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 103;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{2265}>}; # ge
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{003E}>}; # gt
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 103;
      }
    } elsif ($self->{next_input_character} == 104) { # h
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 65) { # A
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{21D4}>}; # hArr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (65, 114, $self->{next_input_character});
            $self->{next_input_character} = 104;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (65, $self->{next_input_character});
          $self->{next_input_character} = 104;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2194}>}; # harr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 114, $self->{next_input_character});
            $self->{next_input_character} = 104;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 104;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 115) { # s
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2665}>}; # hearts
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (101, 97, 114, 116, $self->{next_input_character});
                $self->{next_input_character} = 104;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 97, 114, $self->{next_input_character});
              $self->{next_input_character} = 104;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 97, $self->{next_input_character});
            $self->{next_input_character} = 104;
          }
        } elsif ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 105) { # i
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 112) { # p
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2026}>}; # hellip
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (101, 108, 108, 105, $self->{next_input_character});
                $self->{next_input_character} = 104;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 108, 108, $self->{next_input_character});
              $self->{next_input_character} = 104;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 108, $self->{next_input_character});
            $self->{next_input_character} = 104;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 104;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 104;
      }
    } elsif ($self->{next_input_character} == 105) { # i
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00ED}>}; # iacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 105;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00EE}>}; # icirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 120) { # x
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 99) { # c
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00A1}>}; # iexcl
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 120, 99, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 120, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00EC}>}; # igrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 105;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 109) { # m
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2111}>}; # image
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (109, 97, 103, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 97, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (109, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 110) { # n
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 102) { # f
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 110) { # n
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{221E}>}; # infin
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (110, 102, 105, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (110, 102, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } elsif ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{222B}>}; # int
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (110, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{03B9}>}; # iota
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 116, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 113) { # q
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 101) { # e
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 116) { # t
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00BF}>}; # iquest
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (113, 117, 101, 115, $self->{next_input_character});
                $self->{next_input_character} = 105;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (113, 117, 101, $self->{next_input_character});
              $self->{next_input_character} = 105;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (113, 117, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (113, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 110) { # n
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2208}>}; # isin
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 105, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00EF}>}; # iuml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 105;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 105;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 105;
      }
    } elsif ($self->{next_input_character} == 107) { # k
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03BA}>}; # kappa
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 112, 112, $self->{next_input_character});
              $self->{next_input_character} = 107;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 112, $self->{next_input_character});
            $self->{next_input_character} = 107;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 107;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 107;
      }
    } elsif ($self->{next_input_character} == 108) { # l
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 65) { # A
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{21D0}>}; # lArr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (65, 114, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (65, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 98) { # b
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 97) { # a
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{03BB}>}; # lambda
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 109, 98, 100, $self->{next_input_character});
                $self->{next_input_character} = 108;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 109, 98, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 109, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } elsif ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2329}>}; # lang
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 110, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } elsif ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00AB}>}; # laquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 113, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } elsif ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2190}>}; # larr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 114, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2308}>}; # lceil
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 101, 105, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 101, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 100) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{201C}>}; # ldquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (100, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (100, 113, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (100, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{2264}>}; # le
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 102) { # f
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 111) { # o
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 114) { # r
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{230A}>}; # lfloor
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (102, 108, 111, 111, $self->{next_input_character});
                $self->{next_input_character} = 108;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (102, 108, 111, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (102, 108, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (102, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 119) { # w
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 116) { # t
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2217}>}; # lowast
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (111, 119, 97, 115, $self->{next_input_character});
                $self->{next_input_character} = 108;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (111, 119, 97, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 119, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } elsif ($self->{next_input_character} == 122) { # z
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{25CA}>}; # loz
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{200E}>}; # lrm
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 113) { # q
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 117) { # u
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2039}>}; # lsaquo
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (115, 97, 113, 117, $self->{next_input_character});
                $self->{next_input_character} = 108;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 97, 113, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 97, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } elsif ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2018}>}; # lsquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 108;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 113, $self->{next_input_character});
            $self->{next_input_character} = 108;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 108;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{003C}>}; # lt
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 108;
      }
    } elsif ($self->{next_input_character} == 109) { # m
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00AF}>}; # macr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 109;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 109;
        }
      } elsif ($self->{next_input_character} == 100) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 115) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 104) { # h
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2014}>}; # mdash
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (100, 97, 115, $self->{next_input_character});
              $self->{next_input_character} = 109;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (100, 97, $self->{next_input_character});
            $self->{next_input_character} = 109;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (100, $self->{next_input_character});
          $self->{next_input_character} = 109;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00B5}>}; # micro
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 99, 114, $self->{next_input_character});
              $self->{next_input_character} = 109;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 99, $self->{next_input_character});
            $self->{next_input_character} = 109;
          }
        } elsif ($self->{next_input_character} == 100) { # d
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 116) { # t
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00B7}>}; # middot
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (105, 100, 100, 111, $self->{next_input_character});
                $self->{next_input_character} = 109;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 100, 100, $self->{next_input_character});
              $self->{next_input_character} = 109;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 100, $self->{next_input_character});
            $self->{next_input_character} = 109;
          }
        } elsif ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2212}>}; # minus
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 110, 117, $self->{next_input_character});
              $self->{next_input_character} = 109;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 110, $self->{next_input_character});
            $self->{next_input_character} = 109;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (105, $self->{next_input_character});
          $self->{next_input_character} = 109;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{03BC}>}; # mu
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 109;
      }
    } elsif ($self->{next_input_character} == 110) { # n
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 98) { # b
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2207}>}; # nabla
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 98, 108, $self->{next_input_character});
              $self->{next_input_character} = 110;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 98, $self->{next_input_character});
            $self->{next_input_character} = 110;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 110;
        }
      } elsif ($self->{next_input_character} == 98) { # b
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00A0}>}; # nbsp
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (98, 115, $self->{next_input_character});
            $self->{next_input_character} = 110;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (98, $self->{next_input_character});
          $self->{next_input_character} = 110;
        }
      } elsif ($self->{next_input_character} == 100) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 115) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 104) { # h
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2013}>}; # ndash
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (100, 97, 115, $self->{next_input_character});
              $self->{next_input_character} = 110;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (100, 97, $self->{next_input_character});
            $self->{next_input_character} = 110;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (100, $self->{next_input_character});
          $self->{next_input_character} = 110;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{2260}>}; # ne
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{220B}>}; # ni
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 110) { # n
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2209}>}; # notin
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (111, 116, 105, $self->{next_input_character});
              $self->{next_input_character} = 110;
            }
          } else {
            $r = {type => 'character', data => qq<\x{00AC}>}; # not
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 110;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 98) { # b
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2284}>}; # nsub
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 117, $self->{next_input_character});
            $self->{next_input_character} = 110;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 110;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F1}>}; # ntilde
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 108, 100, $self->{next_input_character});
                $self->{next_input_character} = 110;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 108, $self->{next_input_character});
              $self->{next_input_character} = 110;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (116, 105, $self->{next_input_character});
            $self->{next_input_character} = 110;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 110;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{03BD}>}; # nu
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 110;
      }
    } elsif ($self->{next_input_character} == 111) { # o
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F3}>}; # oacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 111;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00F4}>}; # ocirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{0153}>}; # oelig
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 108, 105, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 108, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F2}>}; # ograve
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 111;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 108) { # l
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 110) { # n
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{203E}>}; # oline
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (108, 105, 110, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (108, 105, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (108, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 109) { # m
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03C9}>}; # omega
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (109, 101, 103, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 101, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } elsif ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 99) { # c
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 114) { # r
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 110) { # n
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{03BF}>}; # omicron
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (109, 105, 99, 114, 111, $self->{next_input_character});
                  $self->{next_input_character} = 111;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (109, 105, 99, 114, $self->{next_input_character});
                $self->{next_input_character} = 111;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (109, 105, 99, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (109, 105, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (109, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2295}>}; # oplus
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (112, 108, 117, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 108, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 100) { # d
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 102) { # f
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00AA}>}; # ordf
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } elsif ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00BA}>}; # ordm
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 100, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $r = {type => 'character', data => qq<\x{2228}>}; # or
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 104) { # h
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F8}>}; # oslash
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (115, 108, 97, 115, $self->{next_input_character});
                $self->{next_input_character} = 111;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 108, 97, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 108, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 116) { # t
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F5}>}; # otilde
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 108, 100, $self->{next_input_character});
                $self->{next_input_character} = 111;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 108, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } elsif ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 115) { # s
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2297}>}; # otimes
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (116, 105, 109, 101, $self->{next_input_character});
                $self->{next_input_character} = 111;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (116, 105, 109, $self->{next_input_character});
              $self->{next_input_character} = 111;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (116, 105, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (116, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00F6}>}; # ouml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 111;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 111;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 111;
      }
    } elsif ($self->{next_input_character} == 112) { # p
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00B6}>}; # para
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } elsif ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2202}>}; # part
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 114, $self->{next_input_character});
            $self->{next_input_character} = 112;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 105) { # i
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 108) { # l
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2030}>}; # permil
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (101, 114, 109, 105, $self->{next_input_character});
                $self->{next_input_character} = 112;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 114, 109, $self->{next_input_character});
              $self->{next_input_character} = 112;
            }
          } elsif ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{22A5}>}; # perp
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 114, $self->{next_input_character});
            $self->{next_input_character} = 112;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03C6}>}; # phi
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 118) { # v
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03D6}>}; # piv
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $r = {type => 'character', data => qq<\x{03C0}>}; # pi
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } elsif ($self->{next_input_character} == 108) { # l
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 115) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 109) { # m
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 110) { # n
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00B1}>}; # plusmn
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (108, 117, 115, 109, $self->{next_input_character});
                $self->{next_input_character} = 112;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (108, 117, 115, $self->{next_input_character});
              $self->{next_input_character} = 112;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (108, 117, $self->{next_input_character});
            $self->{next_input_character} = 112;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (108, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } elsif ($self->{next_input_character} == 111) { # o
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 110) { # n
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 100) { # d
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00A3}>}; # pound
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (111, 117, 110, $self->{next_input_character});
              $self->{next_input_character} = 112;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (111, 117, $self->{next_input_character});
            $self->{next_input_character} = 112;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (111, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2032}>}; # prime
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 105, 109, $self->{next_input_character});
              $self->{next_input_character} = 112;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 105, $self->{next_input_character});
            $self->{next_input_character} = 112;
          }
        } elsif ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{220F}>}; # prod
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } elsif ($self->{next_input_character} == 112) { # p
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{221D}>}; # prop
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 111, $self->{next_input_character});
            $self->{next_input_character} = 112;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03C8}>}; # psi
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 112;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 112;
      }
    } elsif ($self->{next_input_character} == 113) { # q
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0022}>}; # quot
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 111, $self->{next_input_character});
            $self->{next_input_character} = 113;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 113;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 113;
      }
    } elsif ($self->{next_input_character} == 81) { # Q
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 85) { # U
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 79) { # O
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 84) { # T
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{0022}>}; # QUOT
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (85, 79, $self->{next_input_character});
            $self->{next_input_character} = 81;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (85, $self->{next_input_character});
          $self->{next_input_character} = 81;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 81;
      }
    } elsif ($self->{next_input_character} == 114) { # r
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 65) { # A
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{21D2}>}; # rArr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (65, 114, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (65, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 100) { # d
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{221A}>}; # radic
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 100, 105, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 100, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } elsif ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 103) { # g
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{232A}>}; # rang
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 110, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } elsif ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00BB}>}; # raquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 113, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } elsif ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2192}>}; # rarr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 114, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2309}>}; # rceil
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 101, 105, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 101, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 100) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{201D}>}; # rdquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (100, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (100, 113, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (100, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{211C}>}; # real
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 97, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } elsif ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00AE}>}; # reg
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 102) { # f
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 111) { # o
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 114) { # r
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{230B}>}; # rfloor
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (102, 108, 111, 111, $self->{next_input_character});
                $self->{next_input_character} = 114;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (102, 108, 111, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (102, 108, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (102, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03C1}>}; # rho
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 108) { # l
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{200F}>}; # rlm
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (108, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } elsif ($self->{next_input_character} == 115) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 113) { # q
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 117) { # u
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{203A}>}; # rsaquo
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (115, 97, 113, 117, $self->{next_input_character});
                $self->{next_input_character} = 114;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 97, 113, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 97, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } elsif ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2019}>}; # rsquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (115, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 114;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (115, 113, $self->{next_input_character});
            $self->{next_input_character} = 114;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (115, $self->{next_input_character});
          $self->{next_input_character} = 114;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 114;
      }
    } elsif ($self->{next_input_character} == 115) { # s
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 98) { # b
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 113) { # q
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{201A}>}; # sbquo
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (98, 113, 117, $self->{next_input_character});
              $self->{next_input_character} = 115;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (98, 113, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (98, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 111) { # o
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 110) { # n
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{0161}>}; # scaron
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (99, 97, 114, 111, $self->{next_input_character});
                $self->{next_input_character} = 115;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 97, 114, $self->{next_input_character});
              $self->{next_input_character} = 115;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 97, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 100) { # d
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{22C5}>}; # sdot
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (100, 111, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (100, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00A7}>}; # sect
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 99, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 121) { # y
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00AD}>}; # shy
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 103) { # g
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 109) { # m
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 102) { # f
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{03C2}>}; # sigmaf
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $r = {type => 'character', data => qq<\x{03C3}>}; # sigma
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 103, 109, $self->{next_input_character});
              $self->{next_input_character} = 115;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 103, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } elsif ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{223C}>}; # sim
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (105, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 115) { # s
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2660}>}; # spades
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (112, 97, 100, 101, $self->{next_input_character});
                $self->{next_input_character} = 115;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (112, 97, 100, $self->{next_input_character});
              $self->{next_input_character} = 115;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 97, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 98) { # b
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 101) { # e
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2286}>}; # sube
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $r = {type => 'character', data => qq<\x{2282}>}; # sub
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{2211}>}; # sum
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 112) { # p
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 49) { # 1
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00B9}>}; # sup1
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } elsif ($self->{next_input_character} == 50) { # 2
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00B2}>}; # sup2
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } elsif ($self->{next_input_character} == 51) { # 3
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00B3}>}; # sup3
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } elsif ($self->{next_input_character} == 101) { # e
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2287}>}; # supe
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $r = {type => 'character', data => qq<\x{2283}>}; # sup
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } elsif ($self->{next_input_character} == 122) { # z
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 103) { # g
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00DF}>}; # szlig
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (122, 108, 105, $self->{next_input_character});
              $self->{next_input_character} = 115;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (122, 108, $self->{next_input_character});
            $self->{next_input_character} = 115;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (122, $self->{next_input_character});
          $self->{next_input_character} = 115;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 115;
      }
    } elsif ($self->{next_input_character} == 116) { # t
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 117) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{03C4}>}; # tau
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 116;
        }
      } elsif ($self->{next_input_character} == 104) { # h
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 101) { # e
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 52) { # 4
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2234}>}; # there4
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (104, 101, 114, 101, $self->{next_input_character});
                $self->{next_input_character} = 116;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (104, 101, 114, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } elsif ($self->{next_input_character} == 116) { # t
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 97) { # a
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 115) { # s
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 121) { # y
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  if ($self->{next_input_character} == 109) { # m
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    {
                      $r = {type => 'character', data => qq<\x{03D1}>}; # thetasym
                      if ($self->{next_input_character} == 0x003B) { # ;
                        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                      } else {
                        $self->{parse_error}->();
                        ## reconsume
                      }
                    }
                  } else {
                    $self->{parse_error}->();
                    unshift @{$self->{char}},  (104, 101, 116, 97, 115, 121, $self->{next_input_character});
                    $self->{next_input_character} = 116;
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (104, 101, 116, 97, 115, $self->{next_input_character});
                  $self->{next_input_character} = 116;
                }
              } else {
                $r = {type => 'character', data => qq<\x{03B8}>}; # theta
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (104, 101, 116, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (104, 101, $self->{next_input_character});
            $self->{next_input_character} = 116;
          }
        } elsif ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 110) { # n
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 112) { # p
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2009}>}; # thinsp
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (104, 105, 110, 115, $self->{next_input_character});
                $self->{next_input_character} = 116;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (104, 105, 110, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (104, 105, $self->{next_input_character});
            $self->{next_input_character} = 116;
          }
        } elsif ($self->{next_input_character} == 111) { # o
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 110) { # n
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00FE}>}; # thorn
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (104, 111, 114, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (104, 111, $self->{next_input_character});
            $self->{next_input_character} = 116;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (104, $self->{next_input_character});
          $self->{next_input_character} = 116;
        }
      } elsif ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{02DC}>}; # tilde
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 108, 100, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 108, $self->{next_input_character});
            $self->{next_input_character} = 116;
          }
        } elsif ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 101) { # e
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 115) { # s
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00D7}>}; # times
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (105, 109, 101, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (105, 109, $self->{next_input_character});
            $self->{next_input_character} = 116;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (105, $self->{next_input_character});
          $self->{next_input_character} = 116;
        }
      } elsif ($self->{next_input_character} == 114) { # r
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 97) { # a
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 100) { # d
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 101) { # e
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{2122}>}; # trade
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (114, 97, 100, $self->{next_input_character});
              $self->{next_input_character} = 116;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (114, 97, $self->{next_input_character});
            $self->{next_input_character} = 116;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (114, $self->{next_input_character});
          $self->{next_input_character} = 116;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 116;
      }
    } elsif ($self->{next_input_character} == 117) { # u
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 65) { # A
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{21D1}>}; # uArr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (65, 114, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (65, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } elsif ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00FA}>}; # uacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 117;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 117;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } elsif ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{2191}>}; # uarr
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 114, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } elsif ($self->{next_input_character} == 99) { # c
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 114) { # r
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 99) { # c
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{00FB}>}; # ucirc
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (99, 105, 114, $self->{next_input_character});
              $self->{next_input_character} = 117;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (99, 105, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (99, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } elsif ($self->{next_input_character} == 103) { # g
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 114) { # r
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 118) { # v
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00F9}>}; # ugrave
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (103, 114, 97, 118, $self->{next_input_character});
                $self->{next_input_character} = 117;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (103, 114, 97, $self->{next_input_character});
              $self->{next_input_character} = 117;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (103, 114, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (103, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } elsif ($self->{next_input_character} == 109) { # m
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 108) { # l
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00A8}>}; # uml
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (109, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } elsif ($self->{next_input_character} == 112) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 115) { # s
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 105) { # i
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 104) { # h
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              {
                $r = {type => 'character', data => qq<\x{03D2}>}; # upsih
                if ($self->{next_input_character} == 0x003B) { # ;
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                } else {
                  $self->{parse_error}->();
                  ## reconsume
                }
              }
            } elsif ($self->{next_input_character} == 108) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 111) { # o
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 110) { # n
                  
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  {
                    $r = {type => 'character', data => qq<\x{03C5}>}; # upsilon
                    if ($self->{next_input_character} == 0x003B) { # ;
                      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                    } else {
                      $self->{parse_error}->();
                      ## reconsume
                    }
                  }
                } else {
                  $self->{parse_error}->();
                  unshift @{$self->{char}},  (112, 115, 105, 108, 111, $self->{next_input_character});
                  $self->{next_input_character} = 117;
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (112, 115, 105, 108, $self->{next_input_character});
                $self->{next_input_character} = 117;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (112, 115, 105, $self->{next_input_character});
              $self->{next_input_character} = 117;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (112, 115, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (112, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00FC}>}; # uuml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 117;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 117;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 117;
      }
    } elsif ($self->{next_input_character} == 119) { # w
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 105) { # i
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 101) { # e
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 114) { # r
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 112) { # p
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{2118}>}; # weierp
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (101, 105, 101, 114, $self->{next_input_character});
                $self->{next_input_character} = 119;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (101, 105, 101, $self->{next_input_character});
              $self->{next_input_character} = 119;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 105, $self->{next_input_character});
            $self->{next_input_character} = 119;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 119;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 119;
      }
    } elsif ($self->{next_input_character} == 120) { # x
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 105) { # i
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        {
          $r = {type => 'character', data => qq<\x{03BE}>}; # xi
          if ($self->{next_input_character} == 0x003B) { # ;
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          } else {
            $self->{parse_error}->();
            ## reconsume
          }
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 120;
      }
    } elsif ($self->{next_input_character} == 121) { # y
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 97) { # a
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 99) { # c
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 117) { # u
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 116) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 101) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                {
                  $r = {type => 'character', data => qq<\x{00FD}>}; # yacute
                  if ($self->{next_input_character} == 0x003B) { # ;
                    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                  } else {
                    $self->{parse_error}->();
                    ## reconsume
                  }
                }
              } else {
                $self->{parse_error}->();
                unshift @{$self->{char}},  (97, 99, 117, 116, $self->{next_input_character});
                $self->{next_input_character} = 121;
              }
            } else {
              $self->{parse_error}->();
              unshift @{$self->{char}},  (97, 99, 117, $self->{next_input_character});
              $self->{next_input_character} = 121;
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (97, 99, $self->{next_input_character});
            $self->{next_input_character} = 121;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (97, $self->{next_input_character});
          $self->{next_input_character} = 121;
        }
      } elsif ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{00A5}>}; # yen
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 121;
        }
      } elsif ($self->{next_input_character} == 117) { # u
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 109) { # m
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 108) { # l
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{00FF}>}; # yuml
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (117, 109, $self->{next_input_character});
            $self->{next_input_character} = 121;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (117, $self->{next_input_character});
          $self->{next_input_character} = 121;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 121;
      }
    } elsif ($self->{next_input_character} == 122) { # z
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      if ($self->{next_input_character} == 101) { # e
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 116) { # t
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 97) { # a
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{03B6}>}; # zeta
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (101, 116, $self->{next_input_character});
            $self->{next_input_character} = 122;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (101, $self->{next_input_character});
          $self->{next_input_character} = 122;
        }
      } elsif ($self->{next_input_character} == 119) { # w
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 106) { # j
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          {
            $r = {type => 'character', data => qq<\x{200D}>}; # zwj
            if ($self->{next_input_character} == 0x003B) { # ;
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            } else {
              $self->{parse_error}->();
              ## reconsume
            }
          }
        } elsif ($self->{next_input_character} == 110) { # n
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 106) { # j
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            {
              $r = {type => 'character', data => qq<\x{200C}>}; # zwnj
              if ($self->{next_input_character} == 0x003B) { # ;
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              } else {
                $self->{parse_error}->();
                ## reconsume
              }
            }
          } else {
            $self->{parse_error}->();
            unshift @{$self->{char}},  (119, 110, $self->{next_input_character});
            $self->{next_input_character} = 122;
          }
        } else {
          $self->{parse_error}->();
          unshift @{$self->{char}},  (119, $self->{next_input_character});
          $self->{next_input_character} = 122;
        }
      } else {
        $self->{parse_error}->();
        unshift @{$self->{char}},  ($self->{next_input_character});
        $self->{next_input_character} = 122;
      }
    } else {
      $self->{parse_error}->();
    }
    

  return $r;
} # _tokenize_attempt_to_consume_an_entity

1;
# $Date: 2007/04/28 14:29:00 $
