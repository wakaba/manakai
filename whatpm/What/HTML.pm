package What::HTML;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

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

my $special_category = {
  address => 1, area => 1, base => 1, basefont => 1, bgsound => 1,
  blockquote => 1, body => 1, br => 1, center => 1, col => 1, colgroup => 1,
  dd => 1, dir => 1, div => 1, dl => 1, dt => 1, embed => 1, fieldset => 1,
  form => 1, frame => 1, frameset => 1, h1 => 1, h2 => 1, h3 => 1, 
  h4 => 1, h5 => 1, h6 => 1, head => 1, hr => 1, iframe => 1, image => 1,
  img => 1, input => 1, isindex => 1, li => 1, link => 1, listing => 1,
  menu => 1, meta => 1, noembed => 1, noframes => 1, noscript => 1,
  ol => 1, optgroup => 1, option => 1, p => 1, param => 1, plaintext => 1,
  pre => 1, script => 1, select => 1, spacer => 1, style => 1, tbody => 1,
  textarea => 1, tfoot => 1, thead => 1, title => 1, tr => 1, ul => 1, wbr => 1,
};
my $scoping_category = {
  button => 1, caption => 1, html => 1, marquee => 1, object => 1,
  table => 1, td => 1, th => 1,
};
my $formatting_category = {
  a => 1, b => 1, big => 1, em => 1, font => 1, i => 1, nobr => 1,
  s => 1, small => 1, strile => 1, strong => 1, tt => 1, u => 1,
};
# $phrasing_category: all other elements

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
  

          return  ({type => 'character', data => '<>'});

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
        push @next_char, $self->{next_input_character};
    
        unless ($self->{next_input_character} == 0x0009 or # HT
                $self->{next_input_character} == 0x000A or # LF
                $self->{next_input_character} == 0x000B or # VT
                $self->{next_input_character} == 0x000C or # FF
                $self->{next_input_character} == 0x0020 or # SP 
                $self->{next_input_character} == 0x003E or # >
                $self->{next_input_character} == 0x002F or # /
                $self->{next_input_character} == 0x003C or # <
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
        if (exists $self->{current_token}->{attributes} # start tag or end tag
            ->{$self->{current_attribute}->{name}}) { # MUST
          $self->{parse_error}->();
          ## Discard $self->{current_attribute} # MUST
        } else {
          $self->{current_token}->{attributes}->{$self->{current_attribute}->{name}}
            = $self->{current_attribute};
        }
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
          if ($self->{current_token}->{attributes}) {
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
        $self->{current_token}->{name}
          .= chr ($self->{next_input_character}); # DOCTYPE
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

sub _initialize_tree_constructor ($) {
  my $self = shift;
  require What::NanoDOM;
  $self->{document} = What::NanoDOM::Document->new;
  $self->{document}->strict_error_checking (0);
  ## TODO: Turn mutation events off # MUST
  ## TODO: Turn loose Document option (manakai extension) on
} # _initialize_tree_constructor

sub _terminate_tree_constructor ($) {
  my $self = shift;
  $self->{document}->strict_error_checking (1);
  ## TODO: Turn mutation events on
} # _terminate_tree_constructor

## ISSUE: Should append_child (for example) in script executed in tree construction stage fire mutation events?

sub _construct_tree ($) {
  my ($self) = @_;

  ## When an interactive UA render the $self->{document} available
  ## to the user, or when it begin accepting user input, are
  ## not defined.

  ## Append a character: collect it and all subsequent consecutive
  ## characters and insert one Text node whose data is concatenation
  ## of all those characters. # MUST
  
  my $token;
  $token = $self->_get_next_token;

  my $phase = 'initial'; # MUST

  my $open_elements = [];
  my $active_formatting_elements = [];
  my $head_element;
  my $form_element;
  my $insertion_mode = 'before head';

  my $reconstruct_active_formatting_elements = sub { # MUST
    ## Step 1
    return unless @$active_formatting_elements;

    ## Step 3
    my $i = -1;
    my $entry = $active_formatting_elements->[$i];

    ## Step 2
    return if $entry->[0] eq '#marker';
    for (@$open_elements) {
      if ($entry->[0] eq $_->[0]) {
        return;
      }
    }
    
    ## Step 4
    S4: {
      last S4 if $active_formatting_elements->[0]->[0] eq $entry->[0];

      ## Step 5
      $i--;
      $entry = $active_formatting_elements->[$i];

      ## Step 6
      if ($entry->[0] eq '#marker') {
        #
      } else {
        my $in_open_elements;
        OE: for (@$open_elements) {
          if ($entry->[0] eq $_->[0]) {
          $in_open_elements = 1;
          last OE;
        }
        }
        if ($in_open_elements) {
          #
        } else {
          redo S4;
        }
      }

      ## Step 7
      $i++;
      $entry = $active_formatting_elements->[$i];
    } # S4

    S7: {
      ## Step 8
      my $clone = $entry->[0]->clone_node (0);
    
      ## Step 9
      $open_elements->[-1]->[0]->append_child ($clone);
      push @$open_elements, [$clone, $entry->[1]];
      
      ## Step 10
      $active_formatting_elements->[$i] = $open_elements->[-1];
      
      unless ($i == $#$active_formatting_elements) {
        ## Step 7'
        $i++;
        $entry = $active_formatting_elements->[$i];
        
        redo S7;
      }
    } # S7
  }; # $reconstruct_active_formatting_elements

  my $clear_up_to_marker = sub {
    for (reverse 0..$#$active_formatting_elements) {
      if ($active_formatting_elements->[$_]->[0] eq '#marker') {
        splice @$active_formatting_elements, $_;
        return;
      }
    }
  }; # $clear_up_to_marker

  my $reset_insertion_mode = sub {
    ## Step 1
    my $last;
    
    ## Step 2
    my $i = -1;
    my $node = $open_elements->[$i];
    
    ## Step 3
    S3: {
      $last = 1 if $open_elements->[0]->[0] eq $node->[0];
      ## TODO: the element whose inner_html is set is neither td nor th, then $node = the element
    
      ## Step 4..13
      my $new_mode = {
                      select => 'in select',
                      td => 'in cell',
                      th => 'in cell',
                      tr => 'in row',
                      tbody => 'in table body',
                      thead => 'in table head',
                      tfoot => 'in table foot',
                      caption => 'in caption',
                      colgroup => 'in column group',
                      table => 'in table',
                      head => 'in body', # not in head!
                      body => 'in body',
                      frameset => 'in frameset',
                     }->{$node->[1]};
      $insertion_mode = $new_mode and return if defined $new_mode;
      
      ## Step 14
      if ($node->[1] eq 'html') {
        unless (defined $head_element) {
          $insertion_mode = 'before head';
        } else {
          $insertion_mode = 'after head';
        }
        return;
      }
      
      ## Step 15
      $insertion_mode = 'in body' and return if $last;
      
      ## Step 16
      $i--;
      $node = $open_elements->[$i];
      
      ## Step 17
      redo S3;
    } # S3
  }; # $reset_insertion_mode

  my $style_start_tag = sub {
    my $style_el; 
      $style_el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'style']);
    
    ## $insertion_mode eq 'in head' and ... (always true)
    (($insertion_mode eq 'in head' and defined $head_element)
     ? $head_element : $open_elements->[-1]->[0])
      ->append_child ($style_el);
    $self->{content_model_flag} = 'CDATA';
              
    my $text = '';
    $token = $self->_get_next_token;
    while ($token->{type} eq 'character') {
      $text .= $token->{data};
      $token = $self->_get_next_token;
    } # stop if non-character token or tokenizer stops tokenising
    if (length $text) {
      $style_el->manakai_append_text ($text);
    }
    
    $self->{content_model_flag} = 'PCDATA';
              
    if ($token->{type} eq 'end tag' and $token->{tag_name} eq 'style') {
      ## Ignore the token
    } else {
      $self->{parse_error}->();
      ## ISSUE: And ignore?
    }
    $token = $self->_get_next_token;
  }; # $style_start_tag

  my $script_start_tag = sub {
    my $script_el; 
      $script_el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'script']);
    
    ## TODO: mark as "parser-inserted"

    $self->{content_model_flag} = 'CDATA';
    
    my $text = '';
    $token = $self->_get_next_token;
    while ($token->{type} eq 'character') {
      $text .= $token->{data};
      $token = $self->_get_next_token;
    } # stop if non-character token or tokenizer stops tokenising
    if (length $text) {
      $script_el->manakai_append_text ($text);
    }
              
    $self->{content_model_flag} = 'PCDATA';
              
    if ($token->{type} eq 'end tag' and
        $token->{tag_name} eq 'script') {
      ## Ignore the token
    } else {
      $self->{parse_error}->();
      ## ISSUE: And ignore?
      ## TODO: mark as "already executed"
    }
    
    ## TODO: inner_html mode then mark as "already executed" and skip
    if (1) {
      ## TODO: $old_insertion_point = current insertion point
      ## TODO: insertion point = just before the next input character
      
      (($insertion_mode eq 'in head' and defined $head_element)
       ? $head_element : $open_elements->[-1]->[0])->append_child ($script_el);
      
      ## TODO: insertion point = $old_insertion_point (might be "undefined")
      
      ## TODO: if there is a script that will execute as soon as the parser resume, then...
    }
    
    $token = $self->_get_next_token;
  }; # $script_start_tag

  my $formatting_end_tag = sub {
    my $tag_name = shift;

    FET: {
      ## Step 1
      my $formatting_element;
      my $formatting_element_i_in_active;
      AFE: for (reverse 0..$#$active_formatting_elements) {
        if ($active_formatting_elements->[$_]->[1] eq $tag_name) {
          $formatting_element = $active_formatting_elements->[$_];
          $formatting_element_i_in_active = $_;
          last AFE;
        } elsif ($active_formatting_elements->[$_]->[0] eq '#marker') {
          last AFE;
        }
      } # AFE
      unless (defined $formatting_element) {
        $self->{parse_error}->();
        ## Ignore the token
        $token = $self->_get_next_token;
        return;
      }
      ## has an element in scope
      my $in_scope = 1;
      my $formatting_element_i_in_open;  
      INSCOPE: for (reverse 0..$#$open_elements) {
        my $node = $open_elements->[$_];
        if ($node->[0] eq $formatting_element->[0]) {
          if ($in_scope) {
            $formatting_element_i_in_open = $_;
            last INSCOPE;
          } else { # in open elements but not in scope
            $self->{parse_error}->();
            ## Ignore the token
            $token = $self->_get_next_token;
            return;
          }
        } elsif ({
                  table => 1, caption => 1, td => 1, th => 1,
                  button => 1, marquee => 1, object => 1, html => 1,
                 }->{$node->[1]}) {
          $in_scope = 0;
        }
      } # INSCOPE
      unless (defined $formatting_element_i_in_open) {
        $self->{parse_error}->();
        pop @$active_formatting_elements; # $formatting_element
        $token = $self->_get_next_token; ## TODO: ok?
        return;
      }
      if (not $open_elements->[-1]->[0] eq $formatting_element->[0]) {
        $self->{parse_error}->();
      }
      
      ## Step 2
      my $furthest_block;
      my $furthest_block_i_in_open;
      OE: for (reverse 0..$#$open_elements) {
        my $node = $open_elements->[$_];
        if (not $formatting_category->{$node->[1]} and
            #not $phrasing_category->{$node->[1]} and
            ($special_category->{$node->[1]} or
             $scoping_category->{$node->[1]})) {
          $furthest_block = $node;
          $furthest_block_i_in_open = $_;
        } elsif ($node->[0] eq $formatting_element->[0]) {
          last OE;
        }
      } # OE
      
      ## Step 3
      unless (defined $furthest_block) { # MUST
        splice @$open_elements, $formatting_element_i_in_open;
        splice @$active_formatting_elements, $formatting_element_i_in_active, 1;
        $token = $self->_get_next_token;
        return;
      }
      
      ## Step 4
      my $common_ancestor_node = $open_elements->[$formatting_element_i_in_open - 1];
      
      ## Step 5
      my $furthest_block_parent = $furthest_block->[0]->parent_node;
      if (defined $furthest_block_parent) {
        $furthest_block_parent->remove_child ($furthest_block->[0]);
      }
      
      ## Step 6
      my $bookmark_prev_el
        = $active_formatting_elements->[$formatting_element_i_in_active - 1]
          ->[0];
      
      ## Step 7
      my $node = $furthest_block;
      my $node_i_in_open = $furthest_block_i_in_open;
      my $last_node = $furthest_block;
      S7: {
        ## Step 1
        $node_i_in_open--;
        $node = $open_elements->[$node_i_in_open];
        
        ## Step 2
        my $node_i_in_active;
        S7S2: {
          for (reverse 0..$#$active_formatting_elements) {
            if ($active_formatting_elements->[$_]->[0] eq $node->[0]) {
              $node_i_in_active = $_;
              last S7S2;
            }
          }
          splice @$open_elements, $node_i_in_open, 1;
          redo S7;
        } # S7S2
        
        ## Step 3
        last S7 if $node->[0] eq $formatting_element->[0];
        
        ## Step 4
        if ($last_node->[0] eq $furthest_block->[0]) {
          $bookmark_prev_el = $node->[0];
        }
        
        ## Step 5
        if ($node->[0]->has_child_nodes ()) {
          my $clone = [$node->[0]->clone_node (0), $node->[1]];
          $active_formatting_elements->[$node_i_in_active] = $clone;
          $open_elements->[$node_i_in_open] = $clone;
          $node = $clone;
        }
        
        ## Step 6
        $node->append_child ($last_node);
        
        ## Step 7
        $last_node = $node;
        
        ## Step 8
        redo S7;
      } # S7  
      
      ## Step 8
      $common_ancestor_node->append_child ($last_node);
      
      ## Step 9
      my $clone = [$formatting_element->[0]->clone_node (0),
                   $formatting_element->[1]];
      
      ## Step 10
      my @cn = @{$furthest_block->[0]->child_nodes};
      $clone->[0]->append_child ($_) for @cn;
      
      ## Step 11
      $furthest_block->[0]->append_child ($clone->[0]);
      
      ## Step 12
      my $i;
      AFE: for (reverse 0..$#$active_formatting_elements) {
        if ($active_formatting_elements->[$_]->[0] eq $formatting_element->[0]) {
          splice @$active_formatting_elements, $_, 1;
          $i-- and last AFE if defined $i;
        } elsif ($active_formatting_elements->[$_]->[0] eq $bookmark_prev_el) {
          $i = $_;
        }
      } # AFE
      splice @$active_formatting_elements, $i + 1, 0, $clone;
      
      ## Step 13
      undef $i;
      OE: for (reverse 0..$#$open_elements) {
        if ($open_elements->[$_]->[0] eq $formatting_element->[0]) {
          splice @$open_elements, $_, 1;
          $i-- and last OE if defined $i;
        } elsif ($open_elements->[$_]->[0] eq $furthest_block->[0]) {
          $i = $_;
        }
      } # OE
      splice @$open_elements, $i + 1, 1, $clone;
      
      ## Step 14
      redo FET;
    } # FET
  }; # $formatting_end_tag

  my $in_body = sub {
    my $insert = shift;
    if ($token->{type} eq 'start tag') {
      if ($token->{tag_name} eq 'script') {
        $script_start_tag->();
        return;
      } elsif ($token->{tag_name} eq 'style') {
        $style_start_tag->();
        return;
      } elsif ({
                base => 1, link => 1, meta => 1, title => 1,
               }->{$token->{tag_name}}) {
        $self->{parse_error}->();
        ## NOTE: This is an "as if in head" code clone
        my $el;
        
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
        if (defined $head_element) {
          $head_element->append_child ($el);
        } else {
          $insert->($el);
        }
        
        ## ISSUE: Issue on magical <base> in the spec
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'body') {
        $self->{parse_error}->();
              
        if (@$open_elements == 1 or
            $open_elements->[1]->[1] ne 'body') {
          ## Ignore the token
        } else {
          my $body_el = $open_elements->[1]->[0];
          for my $attr_name (keys %{$token->{attributes}}) {
            unless ($body_el->has_attribute_ns (undef, $attr_name)) {
              $body_el->set_attribute_ns
                (undef, [undef, $attr_name],
                 $token->{attributes}->{$attr_name}->{value});
            }
          }
        }
        $token = $self->_get_next_token;
        return;
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1, 
                div => 1, dl => 1, fieldset => 1, listing => 1,
                menu => 1, ol => 1, p => 1, ul => 1,
                pre => 1,
               }->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse @$open_elements) {
          if ($_->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        if ($token->{tag_name} eq 'pre') {
          $token = $self->_get_next_token;
          if ($token->{type} eq 'character') {
            $token->{data} =~ s/^\x0A//;
            unless (length $token->{data}) {
              $token = $self->_get_next_token;
            }
          }
        } else {
          $token = $self->_get_next_token;
        }
        return;
      } elsif ($token->{tag_name} eq 'form') {
        if (defined $form_element) {
          $self->{parse_error}->();
          ## Ignore the token
        } else {
          ## has a p element in scope
          INSCOPE: for (reverse @$open_elements) {
            if ($_->[1] eq 'p') {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag', tag_name => 'p'};
              return;
            } elsif ({
                      table => 1, caption => 1, td => 1, th => 1,
                      button => 1, marquee => 1, object => 1, html => 1,
                     }->{$_->[1]}) {
              last INSCOPE;
            }
          } # INSCOPE
            
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
          $form_element = $open_elements->[-1]->[0];
          $token = $self->_get_next_token;
          return;
        }
      } elsif ($token->{tag_name} eq 'li') {
        ## has a p element in scope
        INSCOPE: for (reverse @$open_elements) {
          if ($_->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        ## Step 1
        my $i = -1;
        my $node = $open_elements->[$i];
        LI: {
          ## Step 2
          if ($node->[1] eq 'li') {
            splice @$open_elements, $i;
            last LI;
          }
          
          ## Step 3
          if (not $formatting_category->{$node->[1]} and
              #not $phrasing_category->{$node->[1]} and
              ($special_category->{$node->[1]} or
               $scoping_category->{$node->[1]}) and
              $node->[1] ne 'address' and $node->[1] ne 'div') {
            last LI;
          }
          
          ## Step 4
          $i++;
          $node = $open_elements->[$i];
          redo LI;
        } # LI
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'dd' or $token->{tag_name} eq 'dt') {
        ## has a p element in scope
        INSCOPE: for (reverse @$open_elements) {
          if ($_->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        ## Step 1
        my $i = -1;
        my $node = $open_elements->[$i];
        LI: {
          ## Step 2
          if ($node->[1] eq 'dt' or $node->[1] eq 'dd') {
            splice @$open_elements, $i;
            last LI;
          }
          
          ## Step 3
          if (not $formatting_category->{$node->[1]} and
              #not $phrasing_category->{$node->[1]} and
              ($special_category->{$node->[1]} or
               $scoping_category->{$node->[1]}) and
              $node->[1] ne 'address' and $node->[1] ne 'div') {
            last LI;
          }
          
          ## Step 4
          $i++;
          $node = $open_elements->[$i];
          redo LI;
        } # LI
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'plaintext') {
        ## has a p element in scope
        INSCOPE: for (reverse @$open_elements) {
          if ($_->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
          
        $self->{content_model_flag} = 'PLAINTEXT';
          
        $token = $self->_get_next_token;
        return;
      } elsif ({
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse 0..$#$open_elements) {
          my $node = $open_elements->[$_];
          if ($node->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#$open_elements) {
          my $node = $open_elements->[$_];
          if ({
               h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
              }->{$node->[1]}) {
            $i = $_;
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        if (defined $i) {
          $self->{parse_error}->();
          splice @$open_elements, $i;
        }
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
          
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'a') {
        AFE: for my $i (reverse 0..$#$active_formatting_elements) {
          my $node = $active_formatting_elements->[$i];
          if ($node->[1] eq 'a') {
            $self->{parse_error}->();
            
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'a'};
            $formatting_end_tag->($token->{tag_name});
            
            splice @$active_formatting_elements, $i;
            OE: for (reverse 0..$#$open_elements) {
              if ($open_elements->[$_]->[0] eq $node->[0]) {
                splice @$open_elements, $_;
                last OE;
              }
            } # OE
            last AFE;
          } elsif ($node->[0] eq '#marker') {
            last AFE;
          }
        } # AFE
          
        $reconstruct_active_formatting_elements->();

        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, $open_elements->[-1];

        $token = $self->_get_next_token;
        return;
      } elsif ({
                b => 1, big => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strile => 1, 
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, $open_elements->[-1];
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'button') {
        ## has a button element in scope
        INSCOPE: for (reverse 0..$#$open_elements) {
          my $node = $open_elements->[$_];
          if ($node->[1] eq 'button') {
            $self->{parse_error}->();
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'button'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        $reconstruct_active_formatting_elements->();
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, ['#marker', ''];

        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'marquee' or 
               $token->{tag_name} eq 'object') {
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, ['#marker', ''];
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'xmp') {
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        
        $self->{content_model_flag} = 'CDATA';
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'tbale') {
        ## has a p element in scope
        INSCOPE: for (reverse @$open_elements) {
          if ($_->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
          
        $insertion_mode = 'in table';
          
        $token = $self->_get_next_token;
        return;
      } elsif ({
                area => 1, basefont => 1, bgsound => 1, br => 1,
                embed => 1, img => 1, param => 1, spacer => 1, wbr => 1,
                image => 1,
               }->{$token->{tag_name}}) {
        if ($token->{tag_name} eq 'image') {
          $self->{parse_error}->();
          $token->{tag_name} = 'img';
        }
        
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        pop @$open_elements;
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'hr') {
        ## has a p element in scope
        INSCOPE: for (reverse @$open_elements) {
          if ($_->[1] eq 'p') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'p'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        pop @$open_elements;
          
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'input') {
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        ## TODO: associate with $form_element if defined
        pop @$open_elements;
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'isindex') {
        $self->{parse_error}->();
        
        if (defined $form_element) {
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        } else {
          my $at = $token->{attributes};
          $at->{name} = {name => 'name', value => 'isindex'};
          my @tokens = (
                        {type => 'start tag', tag_name => 'form'},
                        {type => 'start tag', tag_name => 'hr'},
                        {type => 'start tag', tag_name => 'p'},
                        {type => 'start tag', tag_name => 'label'},
                        {type => 'character',
                         data => 'This is a searchable index.  Insert your search keywords here: '}, # SHOULD
                        ## TODO: make this configurable
                        {type => 'start tag', tag_name => 'input', attributes => $at},
                        #{type => 'character', data => ''}, # SHOULD
                        {type => 'end tag', tag_name => 'label'},
                        {type => 'end tag', tag_name => 'p'},
                        {type => 'start tag', tag_name => 'hr'},
                        {type => 'end tag', tag_name => 'form'},
                       );
          $token = shift @tokens;
          unshift @{$self->{token}}, (@tokens);
          return;
        }
      } elsif ({
                textarea => 1,
                noembed => 1,
                noframes => 1,
                noscript => 0, ## TODO: 1 if scripting is enabled
               }->{$token->{tag_name}}) {
        my $tag_name = $token->{tag_name};
        my $el;
        
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
        
        if ($token->{tag_name} eq 'textarea') {
          ## TODO: form_element if defined
          $self->{content_model_flag} = 'RCDATA';
        } else {
          $self->{content_model_flag} = 'CDATA';
        }
        
        $insert->($el);
        
        my $text = '';
        $token = $self->_get_next_token;
        while ($token->{type} eq 'character') {
          $text .= $token->{data};
          $token = $self->_get_next_token;
        }
        if (length $text) {
          $el->manakai_append_text ($text);
        }
        
        $self->{content_model_flag} = 'PCDATA';
        
        if ($token->{type} eq 'end tag' and
            $token->{tag_name} eq $tag_name) {
          ## Ignore the token
        } else {
          $self->{parse_error}->();
          ## ISSUE: And ignore?
        }
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{type} eq 'select') {
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        
        $insertion_mode = 'in select';
        $token = $self->_get_next_token;
        return;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
               }->{$token->{tag_name}}) {
        $self->{parse_error}->();
        ## Ignore the token
        $token = $self->_get_next_token;
        return;
        
        ## ISSUE: An issue on HTML5 new elements in the spec.
      } else {
        $reconstruct_active_formatting_elements->();
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
        
        $token = $self->_get_next_token;
        return;
      }
    } elsif ($token->{type} eq 'end tag') {
      if ($token->{tag_name} eq 'body') {
        if (@$open_elements > 1 and $open_elements->[1]->[1] eq 'body') {
          ## ISSUE: There is an issue in the spec.
          if ($open_elements->[-1]->[1] ne 'body') {
            $self->{parse_error}->();
          }
          $insertion_mode = 'after body';
          $token = $self->_get_next_token;
          return;
        } else {
          $self->{parse_error}->();
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        }
      } elsif ($token->{tag_name} eq 'html') {
        if (@$open_elements > 1 and $open_elements->[1]->[1] eq 'body') {
          ## ISSUE: There is an issue in the spec.
          if ($open_elements->[-1]->[1] ne 'body') {
            $self->{parse_error}->();
          }
          $insertion_mode = 'after body';
          ## reprocess
          return;
        } else {
          $self->{parse_error}->();
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        }
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1,
                div => 1, dl => 1, fieldset => 1, listing => 1,
                menu => 1, ol => 1, pre => 1, ul => 1,
                form => 1,
                p => 1,
                dd => 1, dt => 1, li => 1,
                button => 1, marquee => 1, object => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#$open_elements) {
          my $node = $open_elements->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            ## generate implied end tags
            if ({
                 dd => ($token->{tag_name} ne 'dd'),
                 dt => ($token->{tag_name} ne 'dt'),
                 li => ($token->{tag_name} ne 'li'),
                 p => ($token->{tag_name} ne 'p'),
                 td => 1, th => 1, tr => 1,
                }->{$open_elements->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $open_elements->[-1]->[1]}; # MUST
              return;
            }
            $i = $_;
            last INSCOPE unless $token->{tag_name} eq 'p';
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
        
        if ($open_elements->[-1]->[1] ne $token->{tag_name}) {
          $self->{parse_error}->();
        }
        
        splice @$open_elements, $i if defined $i;
        undef $form_element if $token->{tag_name} eq 'form';
        $clear_up_to_marker->()
          if {
            button => 1, marquee => 1, object => 1,
          }->{$token->{tag_name}};
        $token = $self->_get_next_token;
        return;
      } elsif ({
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#$open_elements) {
          my $node = $open_elements->[$_];
          if ({
               h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
              }->{$node->[1]}) {
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                }->{$open_elements->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $open_elements->[-1]->[1]}; # MUST
              return;
            }
            $i = $_;
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
        
        if ($open_elements->[-1]->[1] ne $token->{tag_name}) {
          $self->{parse_error}->();
        }
        
        splice @$open_elements, $i if defined $i;
        $token = $self->_get_next_token;
        return;
      } elsif ({
                a => 1,
                b => 1, big => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strile => 1,
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        $formatting_end_tag->($token->{tag_name});
        return;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
                area => 1, basefont => 1, bgsound => 1, br => 1,
                embed => 1, hr => 1, iframe => 1, image => 1,
                img => 1, input => 1, isindex=> 1, noembed => 1,
                noframes => 1, param => 1, select => 1, spacer => 1,
                table => 1, textarea => 1, wbr => 1,
                noscript => 0, ## TODO: if scripting is enabled
               }->{$token->{tag_name}}) {
        $self->{parse_error}->();
        ## Ignore the token
        $token = $self->_get_next_token;
        return;
        
        ## ISSUE: Issue on HTML5 new elements in spec
        
      } else {
        ## Step 1
        my $node_i = -1;
        my $node = $open_elements->[$node_i];

        ## Step 2
        S2: {
          if ($node->[1] eq $token->{tag_name}) {
            ## Step 1
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                }->{$open_elements->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $open_elements->[-1]->[1]}; # MUST
              return;
            }
        
            ## Step 2
            if ($token->{tag_name} ne $open_elements->[-1]->[1]) {
              $self->{parse_error}->();
            }
            
            ## Step 3
            splice @$open_elements, $node_i;
            last S2;
          } else {
            ## Step 3
            if (not $formatting_category->{$node->[1]} and
                #not $phrasing_category->{$node->[1]} and
                ($special_category->{$node->[1]} or
                 $scoping_category->{$node->[1]})) {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              last S2;
            }
          }
          
          ## Step 4
          $node_i--;
          $node = $open_elements->[$node_i];
          
          ## Step 5;
          redo S2;
        } # S2
      }
    }
  }; # $in_body

  B: {
    if ($phase eq 'initial') {
      if ($token->{type} eq 'DOCTYPE') {
        if ($token->{error}) {
          ## ISSUE: Spec currently left this case undefined.
        }
        my $doctype = $self->{document}->create_document_type_definition
          ($token->{name});
        $self->{document}->append_child ($doctype);
        $phase = 'root element';
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                comment => 1,
                'start tag' => 1,
                'end tag' => 1,
                'end-of-file' => 1,
               }->{$token->{type}}) {
        ## ISSUE: Spec currently left this case undefined.
        $phase = 'root element';
        ## reprocess
        redo B;
      } elsif ($token->{type} eq 'character') {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{document}->manakai_append_text ($1);
          ## ISSUE: DOM3 Core does not allow Document > Text
          unless (length $token->{data}) {
            ## Stay in the phase
            $token = $self->_get_next_token;
            redo B;
          }
        }
        ## ISSUE: Spec currently left this case undefined.
        $phase = 'root element';
        ## reprocess
        redo B;
      } else {
        die "$0: $token->{type}: Unknown token";
      }
    } elsif ($phase eq 'root element') {
      if ($token->{type} eq 'DOCTYPE') {
        $self->{parse_error}->();
        ## Ignore the token
        ## Stay in the phase
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'comment') {
        my $comment = $self->{document}->create_comment ($token->{data});
        $self->{document}->append_child ($comment);
        ## Stay in the phase
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'character') {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{document}->manakai_append_text ($1);
          ## ISSUE: DOM3 Core does not allow Document > Text
          unless (length $token->{data}) {
            ## Stay in the phase
            $token = $self->_get_next_token;
            redo B;
          }
        }
        #
      } elsif ({
                'start tag' => 1,
                'end tag' => 1,
                'end-of-file' => 1,
               }->{$token->{type}}) {
        ## ISSUE: There is an issue in the spec
        #
      } else {
        die "$0: $token->{type}: Unknown token";
      }
      my $root_element; 
      $root_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'html']);
    
      $self->{document}->append_child ($root_element);
      $open_elements = [[$root_element, 'html']];
      $phase = 'main';
      ## reprocess
      redo B;
    } elsif ($phase eq 'main') {
      if ($token->{type} eq 'DOCTYPE') {
        $self->{parse_error}->();
        ## Ignore the token
        ## Stay in the phase
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'start tag' and
               $token->{tag_name} eq 'html') {
        ## TODO: unless it is the first start tag token, parse-error
        my $top_el = $open_elements->[0]->[0];
        for my $attr_name (keys %{$token->{attributes}}) {
          unless ($top_el->has_attribute_ns (undef, $attr_name)) {
            $top_el->set_attribute_ns (undef, [undef, $attr_name], 
                                       $token->{attributes}->{value});
          }
        }
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'end-of-file') {
        ## Generate implied end tags
        if ({
             dd => 1, dt => 1, li => 1, p => 1, td => 1, th => 1, tr => 1,
            }->{$open_elements->[-1]->[1]}) {
          unshift @{$self->{token}}, $token;
          $token = {type => 'end tag', tag_name => $open_elements->[-1]->[1]};
          redo B;
        }
        
        if (@$open_elements > 2 or
            (@$open_elements == 2 and $open_elements->[1]->[1] ne 'body')) {
          $self->{parse_error}->();
        } else {
          ## TODO: inner_html parser and @$open_elements > 1 and $open_elements->[1] ne 'body', then parse-error
        }

        ## Stop parsing
        last B;

        ## ISSUE: There is an issue in the spec.
      } else {
        if ($insertion_mode eq 'before head') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $open_elements->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            ## As if <head>
            
      $head_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
            $open_elements->[-1]->[0]->append_child ($head_element);
            push @$open_elements, [$head_element, 'head'];
            $insertion_mode = 'in head';
            ## reprocess
            redo B;
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            my $attr = $token->{tag_name} eq 'head' ? $token->{attributes} : {};
            
      $head_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
        for my $attr_name (keys %{ $attr}) {
          $head_element->set_attribute_ns (undef, [undef, $attr_name],
                                 $attr ->{$attr_name}->{value});
        }
      
            $open_elements->[-1]->[0]->append_child ($head_element);
            push @$open_elements, [$head_element, 'head'];
            $insertion_mode = 'in head';
            if ($token->{tag_name} eq 'head') {
              $token = $self->_get_next_token;
            #} elsif ({
            #          base => 1, link => 1, meta => 1,
            #          script => 1, style => 1, title => 1,
            #         }->{$token->{tag_name}}) {
            #  ## reprocess
            } else {
              ## reprocess
            }
            redo B;
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'html') {
              ## As if <head>
              
      $head_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
              $open_elements->[-1]->[0]->append_child ($head_element);
              push @$open_elements, [$head_element, 'head'];
              $insertion_mode = 'in head';
              ## reprocess
              redo B;
            } else {
              $self->{parse_error}->();
              ## Ignore the token
              redo B;
            }
          } else {
            die "$0: $token->{type}: Unknown type";
          }
        } elsif ($insertion_mode eq 'in head') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $open_elements->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'title') {
              my $title_el; 
      $title_el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'title']);
    
              (defined $head_element ? $head_element : $open_elements->[-1]->[0])
                ->append_child ($title_el);
              $self->{content_model_flag} = 'RCDATA';
              
              my $text = '';
              $token = $self->_get_next_token;
              while ($token->{type} eq 'character') {
                $text .= $token->{data};
                $token = $self->_get_next_token;
              }
              if (length $text) {
                $title_el->manakai_append_text ($text);
              }
              
              $self->{content_model_flag} = 'PCDATA';
              
              if ($token->{type} eq 'end tag' and
                  $token->{tag_name} eq 'title') {
                ## Ignore the token
              } else {
                $self->{parse_error}->();
                ## ISSUE: And ignore?
              }
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'style') {
              $style_start_tag->();
              redo B;
            } elsif ($token->{tag_name} eq 'script') {
              $script_start_tag->();
              redo B;
            } elsif ({base => 1, link => 1, meta => 1}->{$token->{tag_name}}) {
              ## NOTE: There are "as if in head" code clones
              my $el;
              
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
              (defined $head_element ? $head_element : $open_elements->[-1]->[0])
                ->append_child ($el);
              
              ## ISSUE: Issue on magical <base> in the spec

              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'head') {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'head') {
              if ($open_elements->[-1]->[1] eq 'head') {
                pop @$open_elements;
              } else {
                $self->{parse_error}->();
              }
              $insertion_mode = 'after head';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'html') {
              #
            } else {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            }
          } else {
            #
          }

          if ($open_elements->[-1]->[1] eq 'head') {
            ## As if </head>
            pop @$open_elements;
          }
          $insertion_mode = 'after head';
          ## reprocess
          redo B;

          ## ISSUE: An issue in the spec.
        } elsif ($insertion_mode eq 'after head') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $open_elements->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'body') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, 'body'];
    }
  
              $insertion_mode = 'in body';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'frameset') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'frameset']);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, 'frameset'];
    }
  
              $insertion_mode = 'in frameset';
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      base => 1, link => 1, meta => 1,
                      script=> 1, style => 1, title => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
               $insertion_mode = 'in head';
              ## reprocess
              redo B;
            } else {
              # 
            } 
          } else {
            #
          }
          
          ## As if <body>
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, 'body'];
    }
  
          $insertion_mode = 'in body';
          ## reprocess
          redo B;
        } elsif ($insertion_mode eq 'in body') {
          if ($token->{type} eq 'character') {
            ## NOTE: There is a code clone of "character in body".
            $reconstruct_active_formatting_elements->();
            
            $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## NOTE: There is a code clone of "comment in body".
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } else {
            $in_body->(sub {
                         $open_elements->[-1]->[0]->append_child (shift);
                       });
            redo B;
          }
        } elsif ($insertion_mode eq 'in table') {
          if ($token->{type} eq 'character') {
            $reconstruct_active_formatting_elements->();

            $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({
                 caption => 1,
                 colgroup => 1,
                 tbody => 1, tfoot => 1, thead => 1,
                }->{$token->{tag_name}}) {
              ## Clear back to table context
              while ($open_elements->[-1]->[1] ne 'table' and
                     $open_elements->[-1]->[1] ne 'html') {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              push @$active_formatting_elements, ['#marker', '']
                if $token->{tag_name} eq 'caption';

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              $insertion_mode = {
                                 caption => 'in caption',
                                 colgroup => 'in column group',
                                 tbody => 'in table body',
                                 tfoot => 'in table body',
                                 thead => 'in table body',
                                }->{$token->{tag_name}};
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      col => 1,
                      td => 1, th => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              ## Clear back to table context
              while ($open_elements->[-1]->[1] ne 'table' and
                     $open_elements->[-1]->[1] ne 'html') {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name} eq 'col' ? 'colgroup' : 'tbody']);
    
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name} eq 'col' ? 'colgroup' : 'tbody'];
    }
  
              $insertion_mode = $token->{tag_name} eq 'col'
                ? 'in column group' : 'in table body';
              ## reprocess
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## NOTE: There are code clones for this "table in table"
              $self->{parse_error}->();

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'table') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => 'end tag', tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'table') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $reset_insertion_mode->();              

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'table') {
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'table') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $reset_insertion_mode->();

              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, tbody => 1, td => 1, tfoot => 1, th => 1,
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }

          ## NOTE: There are code clones of "misc in table".
          $self->{parse_error}->();
          $in_body->(sub {
                       my $child = shift;
                       if ({
                            table => 1, tbody => 1, tfoot => 1,
                            thead => 1, tr => 1,
                           }->{$open_elements->[-1]->[1]}) {
                         # MUST
                         my $foster_parent_element;
                         my $next_sibling;
                         OE: for (reverse 0..$#$open_elements) {
                           if ($open_elements->[$_]->[1] eq 'table') {
                             my $parent = $open_elements->[$_]->[0]->parent_node;
                             if (defined $parent and $parent->node_type == 1) {
                               $foster_parent_element = $parent;
                               $next_sibling = $open_elements->[$_]->[0];
                             } else {
                               $foster_parent_element
                                 = $open_elements->[$_ - 1]->[0];
                             }
                             last OE;
                           }
                         } # OE
                         $foster_parent_element = $open_elements->[0]->[0]
                           unless defined $foster_parent_element;
                         $foster_parent_element->insert_before
                           ($child, $next_sibling);
                       } else {
                         $open_elements->[-1]->[0]->append_child ($child);
                       }
                     });
          redo B;
        } elsif ($insertion_mode eq 'in caption') {
          if ($token->{type} eq 'start tag') {
            if ({
                 caption => 1, col => 1, colgroup => 1, tbody => 1,
                 td => 1, tfoot => 1, th => 1, thead => 1, tr => 1,
                }->{$token->{tag_name}}) {
              $self->{parse_error}->();

              ## As if </caption>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'caption') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <?>
                $token = {type => 'end tag', tag_name => 'caption'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'caption') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $clear_up_to_marker->();

              $insertion_mode = 'in table';

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'caption') {
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'caption') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $clear_up_to_marker->();

              $insertion_mode = 'in table';

              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              $self->{parse_error}->();

              ## As if </caption>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'caption') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # </table>
                $token = {type => 'end tag', tag_name => 'caption'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'caption') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $clear_up_to_marker->();

              $insertion_mode = 'in table';

              ## reprocess
              redo B;
            } elsif ({
                      body => 1, col => 1, colgroup => 1,
                      html => 1, tbody => 1, td => 1, tfoot => 1,
                      th => 1, thead => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
              ## Ignore the token
              redo B;
            } else {
              #
            }
          } else {
            #
          }
              
          $in_body->(sub {
                       $open_elements->[-1]->[0]->append_child (shift);
                     });
          redo B;
        } elsif ($insertion_mode eq 'in column group') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $open_elements->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'col') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              pop @$open_elements;
              $token = $self->_get_next_token;
              redo B;
            } else { 
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'colgroup') {
              if ($open_elements->[-1]->[1] eq 'html') {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                pop @$open_elements; # colgroup
                $insertion_mode = 'in table';
                $token = $self->_get_next_token;
                redo B;             
              }
            } elsif ($token->{tag_name} eq 'col') {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              # 
            }
          } else {
            #
          }

          ## As if </colgroup>
          if ($open_elements->[-1]->[1] eq 'html') {
            $self->{parse_error}->();
            ## Ignore the token
            $token = $self->_get_next_token;
            redo B;
          } else {
            pop @$open_elements; # colgroup
            $insertion_mode = 'in table';
            ## reprocess
            redo B;
          }
        } elsif ($insertion_mode eq 'in table body') {
          if ($token->{type} eq 'character') {
            ## Copied from 'in table'
            $reconstruct_active_formatting_elements->();

            $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## Copied from 'in table'
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({
                 tr => 1,
                 th => 1, td => 1,
                }->{$token->{tag_name}}) {
              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }
              
              $insertion_mode = 'in row';
              if ($token->{tag_name} eq 'tr') {
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
                $token = $self->_get_next_token;
              } else {
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'tr']);
    
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, 'tr'];
    }
  
                ## reprocess
              }
              redo B;
            } elsif ({
                      caption => 1, col => 1, colgroup => 1,
                      tbody => 1, tfoot => 1, thead => 1,
                     }->{$token->{tag_name}}) {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ({
                     tbody => 1, thead => 1, tfoot => 1,
                    }->{$node->[1]}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              ## As if <{current node}>
              ## have an element in table scope
              ## true by definition

              ## Clear back to table body context
              ## nop by definition

              pop @$open_elements;
              $insertion_mode = 'in table';
              ## reprocess
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## NOTE: This is a code clone of "table in table"
              $self->{parse_error}->();

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'table') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => 'end tag', tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'table') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $reset_insertion_mode->();              

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ({
                 tbody => 1, tfoot => 1, thead => 1,
                }->{$token->{tag_name}}) {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              pop @$open_elements;
              $insertion_mode = 'in table';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ({
                     tbody => 1, thead => 1, tfoot => 1,
                    }->{$node->[1]}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              ## As if <{current node}>
              ## have an element in table scope
              ## true by definition

              ## Clear back to table body context
              ## nop by definition

              pop @$open_elements;
              $insertion_mode = 'in table';
              ## reprocess
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, td => 1, th => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }
          
          ## As if in table
          ## NOTE: This is a code clone of "misc in table".
          $self->{parse_error}->();
          $in_body->(sub {
                       my $child = shift;
                       if ({
                            table => 1, tbody => 1, tfoot => 1,
                            thead => 1, tr => 1,
                           }->{$open_elements->[-1]->[1]}) {
                         # MUST
                         my $foster_parent_element;
                         my $next_sibling;
                         OE: for (reverse 0..$#$open_elements) {
                           if ($open_elements->[$_]->[1] eq 'table') {
                             my $parent = $open_elements->[$_]->[0]->parent_node;
                             if (defined $parent and $parent->node_type == 1) {
                               $foster_parent_element = $parent;
                               $next_sibling = $open_elements->[$_]->[0];
                             } else {
                               $foster_parent_element
                                 = $open_elements->[$_ - 1]->[0];
                             }
                             last OE;
                           }
                         } # OE
                         $foster_parent_element = $open_elements->[0]->[0]
                           unless defined $foster_parent_element;
                         $foster_parent_element->insert_before
                           ($child, $next_sibling);
                       } else {
                         $open_elements->[-1]->[0]->append_child ($child);
                       }
                     });
          redo B;
        } elsif ($insertion_mode eq 'in row') {
          if ($token->{type} eq 'character') {
            ## Copied from 'in table'
            $reconstruct_active_formatting_elements->();

            $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## Copied from 'in table'
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'th' or
                $token->{tag_name} eq 'td') {
              ## Clear back to table row context
              while (not {
                th => 1, td => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }
              
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              $insertion_mode = 'in cell';

              push @$active_formatting_elements, ['#marker', ''];
              
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      caption => 1, col => 1, colgroup => 1,
                      tbody => 1, tfoot => 1, thead => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              ## As if </tr>
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'tr') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              pop @$open_elements; # tr
              $insertion_mode = 'in table body';
              ## reprocess
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## NOTE: This is a code clone of "table in table"
              $self->{parse_error}->();

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'table') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => 'end tag', tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne 'table') {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $reset_insertion_mode->();              

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'tr') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              pop @$open_elements; # tr
              $insertion_mode = 'in table body';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## As if </tr>
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'tr') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              pop @$open_elements; # tr
              $insertion_mode = 'in table body';
              ## reprocess
              redo B;
            } elsif ({
                      tbody => 1, tfoot => 1, thead => 1,
                     }->{$token->{tag_name}}) {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## As if </tr>
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'tr') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$open_elements->[-1]->[1]}) {
                $self->{parse_error}->();
                pop @$open_elements;
              }

              pop @$open_elements; # tr
              $insertion_mode = 'in table body';
              ## reprocess
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1,
                      colgroup => 1, html => 1, td => 1, th => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }

          ## As if in table
          ## NOTE: This is a code clone of "misc in table".
          $self->{parse_error}->();
          $in_body->(sub {
                       my $child = shift;
                       if ({
                            table => 1, tbody => 1, tfoot => 1,
                            thead => 1, tr => 1,
                           }->{$open_elements->[-1]->[1]}) {
                         # MUST
                         my $foster_parent_element;
                         my $next_sibling;
                         OE: for (reverse 0..$#$open_elements) {
                           if ($open_elements->[$_]->[1] eq 'table') {
                             my $parent = $open_elements->[$_]->[0]->parent_node;
                             if (defined $parent and $parent->node_type == 1) {
                               $foster_parent_element = $parent;
                               $next_sibling = $open_elements->[$_]->[0];
                             } else {
                               $foster_parent_element
                                 = $open_elements->[$_ - 1]->[0];
                             }
                             last OE;
                           }
                         } # OE
                         $foster_parent_element = $open_elements->[0]->[0]
                           unless defined $foster_parent_element;
                         $foster_parent_element->insert_before
                           ($child, $next_sibling);
                       } else {
                         $open_elements->[-1]->[0]->append_child ($child);
                       }
                     });
          redo B;
        } elsif ($insertion_mode eq 'in cell') {
          if ($token->{type} eq 'character') {
            ## NOTE: This is a code clone of "character in body".
            $reconstruct_active_formatting_elements->();
            
            $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## NOTE: This is a code clone of "comment in body".
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({
                 caption => 1, col => 1, colgroup => 1,
                 tbody => 1, td => 1, tfoot => 1, th => 1,
                 thead => 1, tr => 1,
                }->{$token->{tag_name}}) {
              ## have an element in table scope
              my $tn;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'td' or $node->[1] eq 'th') {
                  $tn = $node->[1];
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $tn) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Close the cell
              unshift @{$self->{token}}, $token; # <?>
              $token = {type => 'end tag', tag_name => $tn};
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{type} eq 'td' or $token->{type} eq 'th') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => ($token->{tag_name} eq 'th'),
                   th => ($token->{tag_name} eq 'td'),
                   tr => 1,
                  }->{$open_elements->[-1]->[1]}) {
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $open_elements->[-1]->[1]}; # MUST
                redo B;
              }

              if ($open_elements->[-1]->[1] ne $token->{tag_name}) {
                $self->{parse_error}->();
              }

              splice @$open_elements, $i;

              $clear_up_to_marker->();

              $insertion_mode = 'in row';

              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1,
                      colgroup => 1, html => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      table => 1, tbody => 1, tfoot => 1, 
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              ## have an element in table scope
              my $i;
              my $tn;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  $tn = $node->[1];
                  last INSCOPE;
                } elsif ($node->[1] eq 'td' or $node->[1] eq 'th') {
                  $tn = $node->[1];
                  ## NOTE: There is exactly one |td| or |th| element
                  ## in scope in the stack of open elements by definition.
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Close the cell
              unshift @{$self->{token}}, $token; # </?>
              $token = {type => 'end tag', tag_name => $tn};
              redo B;
            } else {
              #
            }
          } else {
            #
          }
          
          $in_body->(sub {
                       $open_elements->[-1]->[0]->append_child (shift);
                     });
          redo B;
        } elsif ($insertion_mode eq 'in select') {
          if ($token->{type} eq 'character') {
            $open_elements->[-1]->[0]->manakai_append_text ($token->{data});
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'option') {
              if ($open_elements->[-1]->[1] eq 'option') {
                ## As if </option>
                pop @$open_elements;
              }

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'optgroup') {
              if ($open_elements->[-1]->[1] eq 'option') {
                ## As if </option>
                pop @$open_elements;
              }

              if ($open_elements->[-1]->[1] eq 'optgroup') {
                ## As if </optgroup>
                pop @$open_elements;
              }

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'select') {
              $self->{parse_error}->();
              ## As if </select> instead
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              splice @$open_elements, $i;

              $reset_insertion_mode->();

              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'optgroup') {
              if ($open_elements->[-1]->[1] eq 'option' and
                  $open_elements->[-2]->[1] eq 'optgroup') {
                ## As if </option>
                splice @$open_elements, -2;
              } elsif ($open_elements->[-1]->[1] eq 'optgroup') {
                pop @$open_elements;
              } else {
                $self->{parse_error}->();
                ## Ignore the token
              }
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'option') {
              if ($open_elements->[-1]->[1] eq 'option') {
                pop @$open_elements;
              } else {
                $self->{parse_error}->();
                ## Ignore the token
              }
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'select') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              splice @$open_elements, $i;

              $reset_insertion_mode->();

              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      caption => 1, table => 1, tbody => 1,
                      tfoot => 1, thead => 1, tr => 1, td => 1, th => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}->();
              
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## As if </select>
              ## have an element in table scope
              undef $i;
              INSCOPE: for (reverse 0..$#$open_elements) {
                my $node = $open_elements->[$_];
                if ($node->[1] eq 'select') {
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                $self->{parse_error}->();
                ## Ignore the </select> token
                $token = $self->_get_next_token; ## TODO: ok?
                redo B;
              }
              
              splice @$open_elements, $i;

              $reset_insertion_mode->();

              ## reprocess
              redo B;
            } else {
              # 
            }
          } else {
            #
          }

          $self->{parse_error}->();
          ## Ignore the token
          redo B;
        } elsif ($insertion_mode eq 'after body') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              ## As if in body
              $reconstruct_active_formatting_elements->();
              
              $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[0]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{type} eq 'html') {
              ## TODO: if inner_html, parse-error, ignore the token; otherwise,

              $phase = 'trailing end';
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }

          $self->{parse_error}->();
          $insertion_mode = 'in body';
          ## reprocess
          redo B;
        } elsif ($insertion_mode eq 'in frameset') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'frameset') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'frame') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $open_elements->[-1]->[0]->append_child ($el);
      push @$open_elements, [$el, $token->{tag_name}];
    }
  
              pop @$open_elements;
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'noframes') {
              $in_body->(sub {
                           $open_elements->[-1]->[0]->append_child (shift);
                         });
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'frameset') {
              if ($open_elements->[-1]->[1] eq 'html' and
                  @$open_elements == 1) {
                $self->{parse_error}->();
                ## Ignore the token
                $token = $self->_get_next_token;
              } else {
                pop @$open_elements;
                $token = $self->_get_next_token;
              }
              
              ## if not inner_html and
              if ($open_elements->[-1]->[1] ne 'frameset') {
                $insertion_mode = 'after frameset';
              }
              redo B;
            } else {
              #
            }
          } else {
            #
          }
          
          $self->{parse_error}->();
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        } elsif ($insertion_mode eq 'after frameset') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $open_elements->[-1]->[0]->manakai_append_text ($token->{data});

              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $open_elements->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'noframes') {
              $in_body->(sub {
                           $open_elements->[-1]->[0]->append_child (shift);
                         });
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'html') {
              $phase = 'trailing end';
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }
          
          $self->{parse_error}->();
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;

          ## ISSUE: An issue in spec there
        } else {
          die "$0: $insertion_mode: Unknown insertion mode";
        }
      }
    } elsif ($phase eq 'trailing end') {
      ## states in the main stage is preserved yet # MUST
      
      if ($token->{type} eq 'DOCTYPE') {
        $self->{parse_error}->();
        ## Ignore the token
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'comment') {
        my $comment = $self->{document}->create_comment ($token->{data});
        $self->{document}->append_child ($comment);
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'character') {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          ## As if in the main phase.
          ## NOTE: The insertion mode in the main phase
          ## just before the phase has been changed to the trailing
          ## end phase is either "after body" or "after frameset".
          $reconstruct_active_formatting_elements->()
            if $phase eq 'main';
          
          $open_elements->[-1]->[0]->manakai_append_text ($token->{data});
          
          unless (length $token->{data}) {
            $token = $self->_get_next_token;
            redo B;
          }
        }

        $self->{parse_error}->();
        $phase = 'main';
        ## reprocess
        redo B;
      } elsif ($token->{type} eq 'start tag' or
               $token->{type} eq 'end tag') {
        $self->{parse_error}->();
        $phase = 'main';
        ## reprocess
        redo B;
      } elsif ($token->{type} eq 'end-of-file') {
        ## Stop parsing
        last B;
      } else {
        die "$0: $token->{type}: Unknown token";
      }
    }
  } # B

  ## Stop parsing # MUST
  
  ## TODO: script stuffs
} # _construct_tree

sub inner_html ($$$) {
  my ($class, $node, $on_error) = @_;

  ## Step 1
  my $s = '';

  my $in_cdata;
  my $parent = $node;
  while (defined $parent) {
    if ($parent->node_type == 1 and
        $parent->namespace_uri eq 'http://www.w3.org/1999/xhtml' and
        {
          style => 1, script => 1, xmp => 1, iframe => 1,
          noembed => 1, noframes => 1, noscript => 1,
        }->{$parent->local_name}) { ## TODO: case thingy
      $in_cdata = 1;
    }
    $parent = $parent->parent_node;
  }

  ## Step 2
  my @node = @{$node->child_nodes};
  C: while (@node) {
    my $child = shift @node;
    unless (ref $child) {
      if ($child eq 'cdata-out') {
        $in_cdata = 0;
      } else {
        $s .= $child; # end tag
      }
      next C;
    }
    
    my $nt = $child->node_type;
    if ($nt == 1) { # Element
      my $tag_name = lc $child->tag_name; ## ISSUE: Definition of "lowercase"
      $s .= '<' . $tag_name;

      ## ISSUE: Non-html elements

      my @attrs = @{$child->attributes}; # sort order MUST be stable
      for my $attr (@attrs) { # order is implementation dependent
        my $attr_name = lc $attr->name; ## ISSUE: Definition of "lowercase"
        $s .= ' ' . $attr_name . '="';
        my $attr_value = $attr->value;
        ## escape
        $attr_value =~ s/&/&amp;/g;
        $attr_value =~ s/</&lt;/g;
        $attr_value =~ s/>/&gt;/g;
        $attr_value =~ s/"/&quot;/g;
        $s .= $attr_value . '"';
      }
      $s .= '>';
      
      next C if {
        area => 1, base => 1, basefont => 1, bgsound => 1,
        br => 1, col => 1, embed => 1, frame => 1, hr => 1,
        img => 1, input => 1, link => 1, meta => 1, param => 1,
        spacer => 1, wbr => 1,
      }->{$tag_name};

      if (not $in_cdata and {
        style => 1, script => 1, xmp => 1, iframe => 1,
        noembed => 1, noframes => 1, noscript => 1,
      }->{$tag_name}) {
        unshift @node, 'cdata-out';
        $in_cdata = 1;
      }

      unshift @node, @{$child->child_nodes}, '</' . $tag_name . '>';
    } elsif ($nt == 3 or $nt == 4) {
      if ($in_cdata) {
        $s .= $child->data;
      } else {
        my $value = $child->data;
        $value =~ s/&/&amp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
        $value =~ s/"/&quot;/g;
        $s .= $value;
      }
    } elsif ($nt == 8) {
      $s .= '<!--' . $child->data . '-->';
    } elsif ($nt == 10) {
      $s .= '<!DOCTYPE ' . $child->name . '>';
    } elsif ($nt == 5) { # entrefs
      push @node, @{$child->child_nodes};
    } else {
      $on_error->($child);
    }
  } # C
  
  ## Step 3
  return \$s;
} # inner_html

1;
# $Date: 2007/04/30 09:59:35 $
