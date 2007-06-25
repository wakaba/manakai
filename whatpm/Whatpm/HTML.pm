package Whatpm::HTML;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.28 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

## ISSUE:
## var doc = implementation.createDocument (null, null, null);
## doc.write ('');
## alert (doc.compatMode);

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

my $c1_entity_char = {
  0x80 => 0x20AC,
  0x81 => 0xFFFD,
  0x82 => 0x201A,
  0x83 => 0x0192,
  0x84 => 0x201E,
  0x85 => 0x2026,
  0x86 => 0x2020,
  0x87 => 0x2021,
  0x88 => 0x02C6,
  0x89 => 0x2030,
  0x8A => 0x0160,
  0x8B => 0x2039,
  0x8C => 0x0152,
  0x8D => 0xFFFD,
  0x8E => 0x017D,
  0x8F => 0xFFFD,
  0x90 => 0xFFFD,
  0x91 => 0x2018,
  0x92 => 0x2019,
  0x93 => 0x201C,
  0x94 => 0x201D,
  0x95 => 0x2022,
  0x96 => 0x2013,
  0x97 => 0x2014,
  0x98 => 0x02DC,
  0x99 => 0x2122,
  0x9A => 0x0161,
  0x9B => 0x203A,
  0x9C => 0x0153,
  0x9D => 0xFFFD,
  0x9E => 0x017E,
  0x9F => 0x0178,
}; # $c1_entity_char

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

sub parse_string ($$$;$) {
  my $self = shift->new;
  my $s = \$_[0];
  $self->{document} = $_[1];

  ## NOTE: |set_inner_html| copies most of this method's code

  my $i = 0;
  my $line = 1;
  my $column = 0;
  $self->{set_next_input_character} = sub {
    my $self = shift;

    pop @{$self->{prev_input_character}};
    unshift @{$self->{prev_input_character}}, $self->{next_input_character};

    $self->{next_input_character} = -1 and return if $i >= length $$s;
    $self->{next_input_character} = ord substr $$s, $i++, 1;
    $column++;
    
    if ($self->{next_input_character} == 0x000A) { # LF
      $line++;
      $column = 0;
    } elsif ($self->{next_input_character} == 0x000D) { # CR
      $i++ if substr ($$s, $i, 1) eq "\x0A";
      $self->{next_input_character} = 0x000A; # LF # MUST
      $line++;
      $column = 0;
    } elsif ($self->{next_input_character} > 0x10FFFF) {
      $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    } elsif ($self->{next_input_character} == 0x0000) { # NULL
      $self->{parse_error}-> (type => 'NULL');
      $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    }
  };
  $self->{prev_input_character} = [-1, -1, -1];
  $self->{next_input_character} = -1;

  my $onerror = $_[2] || sub {
    my (%opt) = @_;
    warn "Parse error ($opt{type}) at line $opt{line} column $opt{column}\n";
  };
  $self->{parse_error} = sub {
    $onerror->(@_, line => $line, column => $column);
  };

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->_construct_tree;
  $self->_terminate_tree_constructor;

  return $self->{document};
} # parse_string

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
  # $self->{escape}
} # _initialize_tokenizer

## A token has:
##   ->{type} eq 'DOCTYPE', 'start tag', 'end tag', 'comment',
##       'character', or 'end-of-file'
##   ->{name} (DOCTYPE, start tag (tag name), end tag (tag name))
##   ->{public_identifier} (DOCTYPE)
##   ->{system_identifier} (DOCTYPE)
##   ->{correct} == 1 or 0 (DOCTYPE)
##   ->{attributes} isa HASH (start tag, end tag)
##   ->{data} (comment, character)

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
      } elsif ($self->{next_input_character} == 0x002D) { # -
        if ($self->{content_model_flag} eq 'RCDATA' or
            $self->{content_model_flag} eq 'CDATA') {
          unless ($self->{escape}) {
            if ($self->{prev_input_character}->[0] == 0x002D and # -
                $self->{prev_input_character}->[1] == 0x0021 and # !
                $self->{prev_input_character}->[2] == 0x003C) { # <
              $self->{escape} = 1;
            }
          }
        }
        
        #
      } elsif ($self->{next_input_character} == 0x003C) { # <
        if ($self->{content_model_flag} eq 'PCDATA' or
            (($self->{content_model_flag} eq 'CDATA' or
              $self->{content_model_flag} eq 'RCDATA') and
             not $self->{escape})) {
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
      } elsif ($self->{next_input_character} == 0x003E) { # >
        if ($self->{escape} and
            ($self->{content_model_flag} eq 'RCDATA' or
             $self->{content_model_flag} eq 'CDATA')) {
          if ($self->{prev_input_character}->[0] == 0x002D and # -
              $self->{prev_input_character}->[1] == 0x002D) { # -
            delete $self->{escape};
          }
        }
        
        #
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
      
      my $token = $self->_tokenize_attempt_to_consume_an_entity (0);

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

          return  ({type => 'character', data => '<'});

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
          $self->{parse_error}-> (type => 'empty start tag');
          $self->{state} = 'data';
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

          return  ({type => 'character', data => '<>'});

          redo A;
        } elsif ($self->{next_input_character} == 0x003F) { # ?
          $self->{parse_error}-> (type => 'pio');
          $self->{state} = 'bogus comment';
          ## $self->{next_input_character} is intentionally left as is
          redo A;
        } else {
          $self->{parse_error}-> (type => 'bare stago');
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
        if (defined $self->{last_emitted_start_tag_name}) {
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
                  $self->{next_input_character} == -1) {
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
        } else {
          ## No start tag token has ever been emitted
          # next-input-character is already done
          $self->{state} = 'data';
          return  ({type => 'character', data => '</'});
          redo A;
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
        $self->{parse_error}-> (type => 'empty end tag');
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'bare etago');
        $self->{state} = 'data';
        # reconsume

        return  ({type => 'character', data => '</'});

        redo A;
      } else {
        $self->{parse_error}-> (type => 'bogus end tag');
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
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
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
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

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
          $self->{parse_error}-> (type => 'nestc');
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
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
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
          $self->{parse_error}-> (type => 'nestc');
        }
        ## Stay in the state
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

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
          $self->{parse_error}-> (type => 'dupulicate attribute');
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
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
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
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = 'before attribute name';
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        $before_leave->();
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

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
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
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
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = 'before attribute name';
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

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
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
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

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

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
        $self->{parse_error}-> (type => 'unclosed attribute value');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

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
        $self->{parse_error}-> (type => 'unclosed attribute value');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

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
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
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

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} eq 'start tag') {
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} eq 'end tag') {
          $self->{content_model_flag} = 'PCDATA'; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

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
      my $token = $self->_tokenize_attempt_to_consume_an_entity (1);

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
          $self->{state} = 'comment start';
          
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

      $self->{parse_error}-> (type => 'bogus comment open');
      $self->{next_input_character} = shift @next_char;
      unshift @{$self->{char}},  (@next_char);
      $self->{state} = 'bogus comment';
      redo A;
      
      ## ISSUE: typos in spec: chacacters, is is a parse error
      ## ISSUE: spec is somewhat unclear on "is the first character that will be in the comment"; what is "that will be in the comment" is what the algorithm defines, isn't it?
    } elsif ($self->{state} eq 'comment start') {
      if ($self->{next_input_character} == 0x002D) { # -
        $self->{state} = 'comment start dash';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{parse_error}-> (type => 'bogus comment');
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        $self->{current_token}->{data} # comment
            .= chr ($self->{next_input_character});
        $self->{state} = 'comment';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'comment start dash') {
      if ($self->{next_input_character} == 0x002D) { # -
        $self->{state} = 'comment end';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{parse_error}-> (type => 'bogus comment');
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        $self->{current_token}->{data} # comment
            .= chr ($self->{next_input_character});
        $self->{state} = 'comment';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'comment') {
      if ($self->{next_input_character} == 0x002D) { # -
        $self->{state} = 'comment end dash';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment

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
    } elsif ($self->{state} eq 'comment end dash') {
      if ($self->{next_input_character} == 0x002D) { # -
        $self->{state} = 'comment end';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment

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

        redo A;
      } elsif ($self->{next_input_character} == 0x002D) { # -
        $self->{parse_error}-> (type => 'dash in comment');
        $self->{current_token}->{data} .= '-'; # comment
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = 'data';
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        $self->{parse_error}-> (type => 'dash in comment');
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
        $self->{parse_error}-> (type => 'no space before DOCTYPE name');
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
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{parse_error}-> (type => 'no DOCTYPE name');
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        return  ({type => 'DOCTYPE'}); # incorrect

        redo A;
      } elsif ($self->{next_input_character} == -1) { 
        $self->{parse_error}-> (type => 'no DOCTYPE name');
        $self->{state} = 'data';
        ## reconsume

        return  ({type => 'DOCTYPE'}); # incorrect

        redo A;
      } else {
        $self->{current_token}
            = {type => 'DOCTYPE',
               name => chr ($self->{next_input_character}),
               correct => 1};
## ISSUE: "Set the token's name name to the" in the spec
        $self->{state} = 'DOCTYPE name';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'DOCTYPE name') {
## ISSUE: Redundant "First," in the spec.
      if ($self->{next_input_character} == 0x0009 or # HT
          $self->{next_input_character} == 0x000A or # LF
          $self->{next_input_character} == 0x000B or # VT
          $self->{next_input_character} == 0x000C or # FF
          $self->{next_input_character} == 0x0020) { # SP
        $self->{state} = 'after DOCTYPE name';
        
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

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{current_token}->{name}
          .= chr ($self->{next_input_character}); # DOCTYPE
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

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_input_character} == 0x0050 or # P
               $self->{next_input_character} == 0x0070) { # p
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 0x0055 or # U
            $self->{next_input_character} == 0x0075) { # u
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 0x0042 or # B
              $self->{next_input_character} == 0x0062) { # b
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 0x004C or # L
                $self->{next_input_character} == 0x006C) { # l
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 0x0049 or # I
                  $self->{next_input_character} == 0x0069) { # i
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 0x0043 or # C
                    $self->{next_input_character} == 0x0063) { # c
                  $self->{state} = 'before DOCTYPE public identifier';
                  
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

        #
      } elsif ($self->{next_input_character} == 0x0053 or # S
               $self->{next_input_character} == 0x0073) { # s
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if ($self->{next_input_character} == 0x0059 or # Y
            $self->{next_input_character} == 0x0079) { # y
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          if ($self->{next_input_character} == 0x0053 or # S
              $self->{next_input_character} == 0x0073) { # s
            
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
            if ($self->{next_input_character} == 0x0054 or # T
                $self->{next_input_character} == 0x0074) { # t
              
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
              if ($self->{next_input_character} == 0x0045 or # E
                  $self->{next_input_character} == 0x0065) { # e
                
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
                if ($self->{next_input_character} == 0x004D or # M
                    $self->{next_input_character} == 0x006D) { # m
                  $self->{state} = 'before DOCTYPE system identifier';
                  
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

        #
      } else {
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        #
      }

      $self->{parse_error}-> (type => 'string after DOCTYPE name');
      $self->{state} = 'bogus DOCTYPE';
      # next-input-character is already done
      redo A;
    } elsif ($self->{state} eq 'before DOCTYPE public identifier') {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_input_character}}) {
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} eq 0x0022) { # "
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = 'DOCTYPE public identifier (double-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} eq 0x0027) { # '
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = 'DOCTYPE public identifier (single-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} eq 0x003E) { # >
        $self->{parse_error}-> (type => 'no PUBLIC literal');

        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{parse_error}-> (type => 'string after PUBLIC');
        $self->{state} = 'bogus DOCTYPE';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'DOCTYPE public identifier (double-quoted)') {
      if ($self->{next_input_character} == 0x0022) { # "
        $self->{state} = 'after DOCTYPE public identifier';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{current_token}->{public_identifier} # DOCTYPE
            .= chr $self->{next_input_character};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'DOCTYPE public identifier (single-quoted)') {
      if ($self->{next_input_character} == 0x0027) { # '
        $self->{state} = 'after DOCTYPE public identifier';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{current_token}->{public_identifier} # DOCTYPE
            .= chr $self->{next_input_character};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'after DOCTYPE public identifier') {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_input_character}}) {
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0022) { # "
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = 'DOCTYPE system identifier (double-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0027) { # '
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = 'DOCTYPE system identifier (single-quoted)';
        
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

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{parse_error}-> (type => 'string after PUBLIC literal');
        $self->{state} = 'bogus DOCTYPE';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'before DOCTYPE system identifier') {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_input_character}}) {
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0022) { # "
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = 'DOCTYPE system identifier (double-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x0027) { # '
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = 'DOCTYPE system identifier (single-quoted)';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == 0x003E) { # >
        $self->{parse_error}-> (type => 'no SYSTEM literal');
        $self->{state} = 'data';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{parse_error}-> (type => 'string after PUBLIC literal');
        $self->{state} = 'bogus DOCTYPE';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'DOCTYPE system identifier (double-quoted)') {
      if ($self->{next_input_character} == 0x0022) { # "
        $self->{state} = 'after DOCTYPE system identifier';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed SYSTEM literal');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{current_token}->{system_identifier} # DOCTYPE
            .= chr $self->{next_input_character};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'DOCTYPE system identifier (single-quoted)') {
      if ($self->{next_input_character} == 0x0027) { # '
        $self->{state} = 'after DOCTYPE system identifier';
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed SYSTEM literal');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{current_token}->{system_identifier} # DOCTYPE
            .= chr $self->{next_input_character};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} eq 'after DOCTYPE system identifier') {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_input_character}}) {
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

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        $self->{parse_error}-> (type => 'string after SYSTEM literal');
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
  

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_input_character} == -1) {
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = 'data';
        ## reconsume

        delete $self->{current_token}->{correct};
        return  ($self->{current_token}); # DOCTYPE

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

sub _tokenize_attempt_to_consume_an_entity ($$) {
  my ($self, $in_attr) = @_;

  if ({
       0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, # HT, LF, VT, FF,
       0x0020 => 1, 0x003C => 1, 0x0026 => 1, -1 => 1, # SP, <, & # 0x000D # CR
      }->{$self->{next_input_character}}) {
    ## Don't consume
    ## No error
    return undef;
  } elsif ($self->{next_input_character} == 0x0023) { # #
    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
    if ($self->{next_input_character} == 0x0078 or # x
        $self->{next_input_character} == 0x0058) { # X
      my $code;
      X: {
        my $x_char = $self->{next_input_character};
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        if (0x0030 <= $self->{next_input_character} and 
            $self->{next_input_character} <= 0x0039) { # 0..9
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_input_character} - 0x0030;
          redo X;
        } elsif (0x0061 <= $self->{next_input_character} and
                 $self->{next_input_character} <= 0x0066) { # a..f
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_input_character} - 0x0060 + 9;
          redo X;
        } elsif (0x0041 <= $self->{next_input_character} and
                 $self->{next_input_character} <= 0x0046) { # A..F
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_input_character} - 0x0040 + 9;
          redo X;
        } elsif (not defined $code) { # no hexadecimal digit
          $self->{parse_error}-> (type => 'bare hcro');
          $self->{next_input_character} = 0x0023; # #
          unshift @{$self->{char}},  ($x_char);
          return undef;
        } elsif ($self->{next_input_character} == 0x003B) { # ;
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
        } else {
          $self->{parse_error}-> (type => 'no refc');
        }

        if ($code == 0 or (0xD800 <= $code and $code <= 0xDFFF)) {
          $self->{parse_error}-> (type => sprintf 'invalid character reference:U+%04X', $code);
          $code = 0xFFFD;
        } elsif ($code > 0x10FFFF) {
          $self->{parse_error}-> (type => sprintf 'invalid character reference:U-%08X', $code);
          $code = 0xFFFD;
        } elsif ($code == 0x000D) {
          $self->{parse_error}-> (type => 'CR character reference');
          $code = 0x000A;
        } elsif (0x80 <= $code and $code <= 0x9F) {
          $self->{parse_error}-> (type => sprintf 'c1 entity:U+%04X', $code);
          $code = $c1_entity_char->{$code};
        }

        return {type => 'character', data => chr $code};
      } # X
    } elsif (0x0030 <= $self->{next_input_character} and
             $self->{next_input_character} <= 0x0039) { # 0..9
      my $code = $self->{next_input_character} - 0x0030;
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      
      while (0x0030 <= $self->{next_input_character} and 
                $self->{next_input_character} <= 0x0039) { # 0..9
        $code *= 10;
        $code += $self->{next_input_character} - 0x0030;
        
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      }

      if ($self->{next_input_character} == 0x003B) { # ;
        
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
      } else {
        $self->{parse_error}-> (type => 'no refc');
      }

      if ($code == 0 or (0xD800 <= $code and $code <= 0xDFFF)) {
        $self->{parse_error}-> (type => sprintf 'invalid character reference:U+%04X', $code);
        $code = 0xFFFD;
      } elsif ($code > 0x10FFFF) {
        $self->{parse_error}-> (type => sprintf 'invalid character reference:U-%08X', $code);
        $code = 0xFFFD;
      } elsif ($code == 0x000D) {
        $self->{parse_error}-> (type => 'CR character reference');
        $code = 0x000A;
      } elsif (0x80 <= $code and $code <= 0x9F) {
        $self->{parse_error}-> (type => sprintf 'c1 entity:U+%04X', $code);
        $code = $c1_entity_char->{$code};
      }
      
      return {type => 'character', data => chr $code};
    } else {
      $self->{parse_error}-> (type => 'bare nero');
      unshift @{$self->{char}},  ($self->{next_input_character});
      $self->{next_input_character} = 0x0023; # #
      return undef;
    }
  } elsif ((0x0041 <= $self->{next_input_character} and
            $self->{next_input_character} <= 0x005A) or
           (0x0061 <= $self->{next_input_character} and
            $self->{next_input_character} <= 0x007A)) {
    my $entity_name = chr $self->{next_input_character};
    
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  

    my $value = $entity_name;
    my $match;
    require Whatpm::_NamedEntityList;
    our $EntityChar;

    while (length $entity_name < 10 and
           ## NOTE: Some number greater than the maximum length of entity name
           ((0x0041 <= $self->{next_input_character} and # a
             $self->{next_input_character} <= 0x005A) or # x
            (0x0061 <= $self->{next_input_character} and # a
             $self->{next_input_character} <= 0x007A) or # z
            (0x0030 <= $self->{next_input_character} and # 0
             $self->{next_input_character} <= 0x0039) or # 9
            $self->{next_input_character} == 0x003B)) { # ;
      $entity_name .= chr $self->{next_input_character};
      if (defined $EntityChar->{$entity_name}) {
        if ($self->{next_input_character} == 0x003B) { # ;
          $value = $EntityChar->{$entity_name};
          $match = 1;
          
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
          last;
        } elsif (not $in_attr) {
          $value = $EntityChar->{$entity_name};
          $match = -1;
        } else {
          $value .= chr $self->{next_input_character};
        }
      } else {
        $value .= chr $self->{next_input_character};
      }
      
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  
    }
    
    if ($match > 0) {
      return {type => 'character', data => $value};
    } elsif ($match < 0) {
      $self->{parse_error}-> (type => 'refc');
      return {type => 'character', data => $value};
    } else {
      $self->{parse_error}-> (type => 'bare ero');
      ## NOTE: No characters are consumed in the spec.
      return {type => 'character', data => '&'.$value};
    }
  } else {
    ## no characters are consumed
    $self->{parse_error}-> (type => 'bare ero');
    return undef;
  }
} # _tokenize_attempt_to_consume_an_entity

sub _initialize_tree_constructor ($) {
  my $self = shift;
  ## NOTE: $self->{document} MUST be specified before this method is called
  $self->{document}->strict_error_checking (0);
  ## TODO: Turn mutation events off # MUST
  ## TODO: Turn loose Document option (manakai extension) on
  $self->{document}->manakai_is_html (1); # MUST
} # _initialize_tree_constructor

sub _terminate_tree_constructor ($) {
  my $self = shift;
  $self->{document}->strict_error_checking (1);
  ## TODO: Turn mutation events on
} # _terminate_tree_constructor

## ISSUE: Should append_child (for example) in script executed in tree construction stage fire mutation events?

{ # tree construction stage
  my $token;

sub _construct_tree ($) {
  my ($self) = @_;

  ## When an interactive UA render the $self->{document} available
  ## to the user, or when it begin accepting user input, are
  ## not defined.

  ## Append a character: collect it and all subsequent consecutive
  ## characters and insert one Text node whose data is concatenation
  ## of all those characters. # MUST
  
  $token = $self->_get_next_token;

  $self->{insertion_mode} = 'before head';
  undef $self->{form_element};
  undef $self->{head_element};
  $self->{open_elements} = [];
  undef $self->{inner_html_node};

  $self->_tree_construction_initial; # MUST
  $self->_tree_construction_root_element;
  $self->_tree_construction_main;
} # _construct_tree

sub _tree_construction_initial ($) {
  my $self = shift;
  INITIAL: {
    if ($token->{type} eq 'DOCTYPE') {
      ## NOTE: Conformance checkers MAY, instead of reporting "not HTML5"
      ## error, switch to a conformance checking mode for another 
      ## language.
      my $doctype_name = $token->{name};
      $doctype_name = '' unless defined $doctype_name;
      $doctype_name =~ tr/a-z/A-Z/; 
      if (not defined $token->{name} or # <!DOCTYPE>
          defined $token->{public_identifier} or
          defined $token->{system_identifier}) {
        $self->{parse_error}-> (type => 'not HTML5');
      } elsif ($doctype_name ne 'HTML') {
        ## ISSUE: ASCII case-insensitive? (in fact it does not matter)
        $self->{parse_error}-> (type => 'not HTML5');
      }
      
      my $doctype = $self->{document}->create_document_type_definition
        ($token->{name}); ## ISSUE: If name is missing (e.g. <!DOCTYPE>)?
      $doctype->public_id ($token->{public_identifier})
          if defined $token->{public_identifier};
      $doctype->system_id ($token->{system_identifier})
          if defined $token->{system_identifier};
      ## NOTE: Other DocumentType attributes are null or empty lists.
      ## ISSUE: internalSubset = null??
      $self->{document}->append_child ($doctype);
      
      if (not $token->{correct} or $doctype_name ne 'HTML') {
        $self->{document}->manakai_compat_mode ('quirks');
      } elsif (defined $token->{public_identifier}) {
        my $pubid = $token->{public_identifier};
        $pubid =~ tr/a-z/A-z/;
        if ({
          "+//SILMARIL//DTD HTML PRO V0R11 19970101//EN" => 1,
          "-//ADVASOFT LTD//DTD HTML 3.0 ASWEDIT + EXTENSIONS//EN" => 1,
          "-//AS//DTD HTML 3.0 ASWEDIT + EXTENSIONS//EN" => 1,
          "-//IETF//DTD HTML 2.0 LEVEL 1//EN" => 1,
          "-//IETF//DTD HTML 2.0 LEVEL 2//EN" => 1,
          "-//IETF//DTD HTML 2.0 STRICT LEVEL 1//EN" => 1,
          "-//IETF//DTD HTML 2.0 STRICT LEVEL 2//EN" => 1,
          "-//IETF//DTD HTML 2.0 STRICT//EN" => 1,
          "-//IETF//DTD HTML 2.0//EN" => 1,
          "-//IETF//DTD HTML 2.1E//EN" => 1,
          "-//IETF//DTD HTML 3.0//EN" => 1,
          "-//IETF//DTD HTML 3.0//EN//" => 1,
          "-//IETF//DTD HTML 3.2 FINAL//EN" => 1,
          "-//IETF//DTD HTML 3.2//EN" => 1,
          "-//IETF//DTD HTML 3//EN" => 1,
          "-//IETF//DTD HTML LEVEL 0//EN" => 1,
          "-//IETF//DTD HTML LEVEL 0//EN//2.0" => 1,
          "-//IETF//DTD HTML LEVEL 1//EN" => 1,
          "-//IETF//DTD HTML LEVEL 1//EN//2.0" => 1,
          "-//IETF//DTD HTML LEVEL 2//EN" => 1,
          "-//IETF//DTD HTML LEVEL 2//EN//2.0" => 1,
          "-//IETF//DTD HTML LEVEL 3//EN" => 1,
          "-//IETF//DTD HTML LEVEL 3//EN//3.0" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 0//EN" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 0//EN//2.0" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 1//EN" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 1//EN//2.0" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 2//EN" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 2//EN//2.0" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 3//EN" => 1,
          "-//IETF//DTD HTML STRICT LEVEL 3//EN//3.0" => 1,
          "-//IETF//DTD HTML STRICT//EN" => 1,
          "-//IETF//DTD HTML STRICT//EN//2.0" => 1,
          "-//IETF//DTD HTML STRICT//EN//3.0" => 1,
          "-//IETF//DTD HTML//EN" => 1,
          "-//IETF//DTD HTML//EN//2.0" => 1,
          "-//IETF//DTD HTML//EN//3.0" => 1,
          "-//METRIUS//DTD METRIUS PRESENTATIONAL//EN" => 1,
          "-//MICROSOFT//DTD INTERNET EXPLORER 2.0 HTML STRICT//EN" => 1,
          "-//MICROSOFT//DTD INTERNET EXPLORER 2.0 HTML//EN" => 1,
          "-//MICROSOFT//DTD INTERNET EXPLORER 2.0 TABLES//EN" => 1,
          "-//MICROSOFT//DTD INTERNET EXPLORER 3.0 HTML STRICT//EN" => 1,
          "-//MICROSOFT//DTD INTERNET EXPLORER 3.0 HTML//EN" => 1,
          "-//MICROSOFT//DTD INTERNET EXPLORER 3.0 TABLES//EN" => 1,
          "-//NETSCAPE COMM. CORP.//DTD HTML//EN" => 1,
          "-//NETSCAPE COMM. CORP.//DTD STRICT HTML//EN" => 1,
          "-//O'REILLY AND ASSOCIATES//DTD HTML 2.0//EN" => 1,
          "-//O'REILLY AND ASSOCIATES//DTD HTML EXTENDED 1.0//EN" => 1,
          "-//SPYGLASS//DTD HTML 2.0 EXTENDED//EN" => 1,
          "-//SQ//DTD HTML 2.0 HOTMETAL + EXTENSIONS//EN" => 1,
          "-//SUN MICROSYSTEMS CORP.//DTD HOTJAVA HTML//EN" => 1,
          "-//SUN MICROSYSTEMS CORP.//DTD HOTJAVA STRICT HTML//EN" => 1,
          "-//W3C//DTD HTML 3 1995-03-24//EN" => 1,
          "-//W3C//DTD HTML 3.2 DRAFT//EN" => 1,
          "-//W3C//DTD HTML 3.2 FINAL//EN" => 1,
          "-//W3C//DTD HTML 3.2//EN" => 1,
          "-//W3C//DTD HTML 3.2S DRAFT//EN" => 1,
          "-//W3C//DTD HTML 4.0 FRAMESET//EN" => 1,
          "-//W3C//DTD HTML 4.0 TRANSITIONAL//EN" => 1,
          "-//W3C//DTD HTML EXPERIMETNAL 19960712//EN" => 1,
          "-//W3C//DTD HTML EXPERIMENTAL 970421//EN" => 1,
          "-//W3C//DTD W3 HTML//EN" => 1,
          "-//W3O//DTD W3 HTML 3.0//EN" => 1,
          "-//W3O//DTD W3 HTML 3.0//EN//" => 1,
          "-//W3O//DTD W3 HTML STRICT 3.0//EN//" => 1,
          "-//WEBTECHS//DTD MOZILLA HTML 2.0//EN" => 1,
          "-//WEBTECHS//DTD MOZILLA HTML//EN" => 1,
          "-/W3C/DTD HTML 4.0 TRANSITIONAL/EN" => 1,
          "HTML" => 1,
        }->{$pubid}) {
          $self->{document}->manakai_compat_mode ('quirks');
        } elsif ($pubid eq "-//W3C//DTD HTML 4.01 FRAMESET//EN" or
                 $pubid eq "-//W3C//DTD HTML 4.01 TRANSITIONAL//EN") {
          if (defined $token->{system_identifier}) {
            $self->{document}->manakai_compat_mode ('quirks');
          } else {
            $self->{document}->manakai_compat_mode ('limited quirks');
          }
        } elsif ($pubid eq "-//W3C//DTD XHTML 1.0 Frameset//EN" or
                 $pubid eq "-//W3C//DTD XHTML 1.0 Transitional//EN") {
          $self->{document}->manakai_compat_mode ('limited quirks');
        }
      }
      if (defined $token->{system_identifier}) {
        my $sysid = $token->{system_identifier};
        $sysid =~ tr/A-Z/a-z/;
        if ($sysid eq "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd") {
          $self->{document}->manakai_compat_mode ('quirks');
        }
      }
      
      ## Go to the root element phase.
      $token = $self->_get_next_token;
      return;
    } elsif ({
              'start tag' => 1,
              'end tag' => 1,
              'end-of-file' => 1,
             }->{$token->{type}}) {
      $self->{parse_error}-> (type => 'no DOCTYPE');
      $self->{document}->manakai_compat_mode ('quirks');
      ## Go to the root element phase
      ## reprocess
      return;
    } elsif ($token->{type} eq 'character') {
      if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) { # \x0D
        ## Ignore the token

        unless (length $token->{data}) {
          ## Stay in the phase
          $token = $self->_get_next_token;
          redo INITIAL;
        }
      }

      $self->{parse_error}-> (type => 'no DOCTYPE');
      $self->{document}->manakai_compat_mode ('quirks');
      ## Go to the root element phase
      ## reprocess
      return;
    } elsif ($token->{type} eq 'comment') {
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the phase.
      $token = $self->_get_next_token;
      redo INITIAL;
    } else {
      die "$0: $token->{type}: Unknown token";
    }
  } # INITIAL
} # _tree_construction_initial

sub _tree_construction_root_element ($) {
  my $self = shift;
  
  B: {
      if ($token->{type} eq 'DOCTYPE') {
        $self->{parse_error}-> (type => 'in html:#DOCTYPE');
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
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) { # \x0D
          ## Ignore the token.

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
      push @{$self->{open_elements}}, [$root_element, 'html'];
      #$phase = 'main';
      ## reprocess
      #redo B;
      return;
  } # B
} # _tree_construction_root_element

sub _reset_insertion_mode ($) {
  my $self = shift;

    ## Step 1
    my $last;
    
    ## Step 2
    my $i = -1;
    my $node = $self->{open_elements}->[$i];
    
    ## Step 3
    S3: {
      $last = 1 if $self->{open_elements}->[0]->[0] eq $node->[0];
      if (defined $self->{inner_html_node}) {
        if ($self->{inner_html_node}->[1] eq 'td' or
            $self->{inner_html_node}->[1] eq 'th') {
          #
        } else {
          $node = $self->{inner_html_node};
        }
      }
    
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
      $self->{insertion_mode} = $new_mode and return if defined $new_mode;
      
      ## Step 14
      if ($node->[1] eq 'html') {
        unless (defined $self->{head_element}) {
          $self->{insertion_mode} = 'before head';
        } else {
          $self->{insertion_mode} = 'after head';
        }
        return;
      }
      
      ## Step 15
      $self->{insertion_mode} = 'in body' and return if $last;
      
      ## Step 16
      $i--;
      $node = $self->{open_elements}->[$i];
      
      ## Step 17
      redo S3;
    } # S3
} # _reset_insertion_mode

sub _tree_construction_main ($) {
  my $self = shift;

  my $phase = 'main';

  my $active_formatting_elements = [];

  my $reconstruct_active_formatting_elements = sub { # MUST
    my $insert = shift;

    ## Step 1
    return unless @$active_formatting_elements;

    ## Step 3
    my $i = -1;
    my $entry = $active_formatting_elements->[$i];

    ## Step 2
    return if $entry->[0] eq '#marker';
    for (@{$self->{open_elements}}) {
      if ($entry->[0] eq $_->[0]) {
        return;
      }
    }
    
    S4: {
      ## Step 4
      last S4 if $active_formatting_elements->[0]->[0] eq $entry->[0];

      ## Step 5
      $i--;
      $entry = $active_formatting_elements->[$i];

      ## Step 6
      if ($entry->[0] eq '#marker') {
        #
      } else {
        my $in_open_elements;
        OE: for (@{$self->{open_elements}}) {
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
      my $clone = [$entry->[0]->clone_node (0), $entry->[1]];
    
      ## Step 9
      $insert->($clone->[0]);
      push @{$self->{open_elements}}, $clone;
      
      ## Step 10
      $active_formatting_elements->[$i] = $self->{open_elements}->[-1];

      ## Step 11
      unless ($clone->[0] eq $active_formatting_elements->[-1]->[0]) {
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

  my $parse_rcdata = sub ($$) {
    my ($content_model_flag, $insert) = @_;

    ## Step 1
    my $start_tag_name = $token->{tag_name};
    my $el;
    
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $start_tag_name]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      

    ## Step 2
    $insert->($el); # /context node/->append_child ($el)

    ## Step 3
    $self->{content_model_flag} = $content_model_flag; # CDATA or RCDATA
    delete $self->{escape}; # MUST

    ## Step 4
    my $text = '';
    $token = $self->_get_next_token;
    while ($token->{type} eq 'character') { # or until stop tokenizing
      $text .= $token->{data};
      $token = $self->_get_next_token;
    }

    ## Step 5
    if (length $text) {
      my $text = $self->{document}->create_text_node ($text);
      $el->append_child ($text);
    }

    ## Step 6
    $self->{content_model_flag} = 'PCDATA';

    ## Step 7
    if ($token->{type} eq 'end tag' and $token->{tag_name} eq $start_tag_name) {
      ## Ignore the token
    } else {
      $self->{parse_error}-> (type => 'in '.$content_model_flag.':#'.$token->{type});
    }
    $token = $self->_get_next_token;
  }; # $parse_rcdata

  my $script_start_tag = sub ($) {
    my $insert = $_[0];
    my $script_el;
    
      $script_el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'script']);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $script_el->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
    ## TODO: mark as "parser-inserted"

    $self->{content_model_flag} = 'CDATA';
    delete $self->{escape}; # MUST
    
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
      $self->{parse_error}-> (type => 'in CDATA:#'.$token->{type});
      ## ISSUE: And ignore?
      ## TODO: mark as "already executed"
    }
    
    if (defined $self->{inner_html_node}) {
      ## TODO: mark as "already executed"
    } else {
      ## TODO: $old_insertion_point = current insertion point
      ## TODO: insertion point = just before the next input character

      $insert->($script_el);
      
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
        $self->{parse_error}-> (type => 'unmatched end tag:'.$tag_name);
        ## Ignore the token
        $token = $self->_get_next_token;
        return;
      }
      ## has an element in scope
      my $in_scope = 1;
      my $formatting_element_i_in_open;  
      INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
        my $node = $self->{open_elements}->[$_];
        if ($node->[0] eq $formatting_element->[0]) {
          if ($in_scope) {
            $formatting_element_i_in_open = $_;
            last INSCOPE;
          } else { # in open elements but not in scope
            $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
        $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        pop @$active_formatting_elements; # $formatting_element
        $token = $self->_get_next_token; ## TODO: ok?
        return;
      }
      if (not $self->{open_elements}->[-1]->[0] eq $formatting_element->[0]) {
        $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
      }
      
      ## Step 2
      my $furthest_block;
      my $furthest_block_i_in_open;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        my $node = $self->{open_elements}->[$_];
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
        splice @{$self->{open_elements}}, $formatting_element_i_in_open;
        splice @$active_formatting_elements, $formatting_element_i_in_active, 1;
        $token = $self->_get_next_token;
        return;
      }
      
      ## Step 4
      my $common_ancestor_node = $self->{open_elements}->[$formatting_element_i_in_open - 1];
      
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
        $node = $self->{open_elements}->[$node_i_in_open];
        
        ## Step 2
        my $node_i_in_active;
        S7S2: {
          for (reverse 0..$#$active_formatting_elements) {
            if ($active_formatting_elements->[$_]->[0] eq $node->[0]) {
              $node_i_in_active = $_;
              last S7S2;
            }
          }
          splice @{$self->{open_elements}}, $node_i_in_open, 1;
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
          $self->{open_elements}->[$node_i_in_open] = $clone;
          $node = $clone;
        }
        
        ## Step 6
        $node->[0]->append_child ($last_node->[0]);
        
        ## Step 7
        $last_node = $node;
        
        ## Step 8
        redo S7;
      } # S7  
      
      ## Step 8
      $common_ancestor_node->[0]->append_child ($last_node->[0]);
      
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
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        if ($self->{open_elements}->[$_]->[0] eq $formatting_element->[0]) {
          splice @{$self->{open_elements}}, $_, 1;
          $i-- and last OE if defined $i;
        } elsif ($self->{open_elements}->[$_]->[0] eq $furthest_block->[0]) {
          $i = $_;
        }
      } # OE
      splice @{$self->{open_elements}}, $i + 1, 1, $clone;
      
      ## Step 14
      redo FET;
    } # FET
  }; # $formatting_end_tag

  my $insert_to_current = sub {
    $self->{open_elements}->[-1]->[0]->append_child ($_[0]);
  }; # $insert_to_current

  my $insert_to_foster = sub {
                       my $child = shift;
                       if ({
                            table => 1, tbody => 1, tfoot => 1,
                            thead => 1, tr => 1,
                           }->{$self->{open_elements}->[-1]->[1]}) {
                         # MUST
                         my $foster_parent_element;
                         my $next_sibling;
                         OE: for (reverse 0..$#{$self->{open_elements}}) {
                           if ($self->{open_elements}->[$_]->[1] eq 'table') {
                             my $parent = $self->{open_elements}->[$_]->[0]->parent_node;
                             if (defined $parent and $parent->node_type == 1) {
                               $foster_parent_element = $parent;
                               $next_sibling = $self->{open_elements}->[$_]->[0];
                             } else {
                               $foster_parent_element
                                 = $self->{open_elements}->[$_ - 1]->[0];
                             }
                             last OE;
                           }
                         } # OE
                         $foster_parent_element = $self->{open_elements}->[0]->[0]
                           unless defined $foster_parent_element;
                         $foster_parent_element->insert_before
                           ($child, $next_sibling);
                       } else {
                         $self->{open_elements}->[-1]->[0]->append_child ($child);
                       }
  }; # $insert_to_foster

  my $in_body = sub {
    my $insert = shift;
    if ($token->{type} eq 'start tag') {
      if ($token->{tag_name} eq 'script') {
        ## NOTE: This is an "as if in head" code clone
        $script_start_tag->($insert);
        return;
      } elsif ($token->{tag_name} eq 'style') {
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->('CDATA', $insert);
        return;
      } elsif ({
                base => 1, link => 1, meta => 1,
               }->{$token->{tag_name}}) {
        ## NOTE: This is an "as if in head" code clone, only "-t" differs
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.
        $token = $self->_get_next_token;
        ## TODO: Extracting |charset| from |meta|.
        return;
      } elsif ($token->{tag_name} eq 'title') {
        $self->{parse_error}-> (type => 'in body:title');
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->('RCDATA', $insert);
        return;
      } elsif ($token->{tag_name} eq 'body') {
        $self->{parse_error}-> (type => 'in body:body');
              
        if (@{$self->{open_elements}} == 1 or
            $self->{open_elements}->[1]->[1] ne 'body') {
          ## Ignore the token
        } else {
          my $body_el = $self->{open_elements}->[1]->[0];
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
        INSCOPE: for (reverse @{$self->{open_elements}}) {
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
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
        if (defined $self->{form_element}) {
          $self->{parse_error}-> (type => 'in form:form');
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        } else {
          ## has a p element in scope
          INSCOPE: for (reverse @{$self->{open_elements}}) {
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
          $self->{form_element} = $self->{open_elements}->[-1]->[0];
          $token = $self->_get_next_token;
          return;
        }
      } elsif ($token->{tag_name} eq 'li') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
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
        my $node = $self->{open_elements}->[$i];
        LI: {
          ## Step 2
          if ($node->[1] eq 'li') {
            if ($i != -1) {
              $self->{parse_error}-> (type => 'end tag missing:'.
                              $self->{open_elements}->[-1]->[1]);
            }
            splice @{$self->{open_elements}}, $i;
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
          $i--;
          $node = $self->{open_elements}->[$i];
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'dd' or $token->{tag_name} eq 'dt') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
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
        my $node = $self->{open_elements}->[$i];
        LI: {
          ## Step 2
          if ($node->[1] eq 'dt' or $node->[1] eq 'dd') {
            if ($i != -1) {
              $self->{parse_error}-> (type => 'end tag missing:'.
                              $self->{open_elements}->[-1]->[1]);
            }
            splice @{$self->{open_elements}}, $i;
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
          $i--;
          $node = $self->{open_elements}->[$i];
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'plaintext') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
          
        $self->{content_model_flag} = 'PLAINTEXT';
          
        $token = $self->_get_next_token;
        return;
      } elsif ({
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
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
          
        ## NOTE: See <http://html5.org/tools/web-apps-tracker?from=925&to=926>
        ## has an element in scope
        #my $i;
        #INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
        #  my $node = $self->{open_elements}->[$_];
        #  if ({
        #       h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
        #      }->{$node->[1]}) {
        #    $i = $_;
        #    last INSCOPE;
        #  } elsif ({
        #            table => 1, caption => 1, td => 1, th => 1,
        #            button => 1, marquee => 1, object => 1, html => 1,
        #           }->{$node->[1]}) {
        #    last INSCOPE;
        #  }
        #} # INSCOPE
        #  
        #if (defined $i) {
        #  !!! parse-error (type => 'in hn:hn');
        #  splice @{$self->{open_elements}}, $i;
        #}
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
          
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'a') {
        AFE: for my $i (reverse 0..$#$active_formatting_elements) {
          my $node = $active_formatting_elements->[$i];
          if ($node->[1] eq 'a') {
            $self->{parse_error}-> (type => 'in a:a');
            
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'a'};
            $formatting_end_tag->($token->{tag_name});
            
            AFE2: for (reverse 0..$#$active_formatting_elements) {
              if ($active_formatting_elements->[$_]->[0] eq $node->[0]) {
                splice @$active_formatting_elements, $_, 1;
                last AFE2;
              }
            } # AFE2
            OE: for (reverse 0..$#{$self->{open_elements}}) {
              if ($self->{open_elements}->[$_]->[0] eq $node->[0]) {
                splice @{$self->{open_elements}}, $_, 1;
                last OE;
              }
            } # OE
            last AFE;
          } elsif ($node->[0] eq '#marker') {
            last AFE;
          }
        } # AFE
          
        $reconstruct_active_formatting_elements->($insert_to_current);

        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, $self->{open_elements}->[-1];

        $token = $self->_get_next_token;
        return;
      } elsif ({
                b => 1, big => 1, em => 1, font => 1, i => 1,
                s => 1, small => 1, strile => 1, 
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, $self->{open_elements}->[-1];
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'nobr') {
        $reconstruct_active_formatting_elements->($insert_to_current);

        ## has a |nobr| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq 'nobr') {
            unshift @{$self->{token}}, $token;
            $token = {type => 'end tag', tag_name => 'nobr'};
            return;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, $self->{open_elements}->[-1];
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'button') {
        ## has a button element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq 'button') {
            $self->{parse_error}-> (type => 'in button:button');
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
          
        $reconstruct_active_formatting_elements->($insert_to_current);
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, ['#marker', ''];

        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'marquee' or 
               $token->{tag_name} eq 'object') {
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        push @$active_formatting_elements, ['#marker', ''];
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'xmp') {
        $reconstruct_active_formatting_elements->($insert_to_current);
        $parse_rcdata->('CDATA', $insert);
        return;
      } elsif ($token->{tag_name} eq 'table') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
          
        $self->{insertion_mode} = 'in table';
          
        $token = $self->_get_next_token;
        return;
      } elsif ({
                area => 1, basefont => 1, bgsound => 1, br => 1,
                embed => 1, img => 1, param => 1, spacer => 1, wbr => 1,
                image => 1,
               }->{$token->{tag_name}}) {
        if ($token->{tag_name} eq 'image') {
          $self->{parse_error}-> (type => 'image');
          $token->{tag_name} = 'img';
        }
        
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        pop @{$self->{open_elements}};
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'hr') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
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
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        pop @{$self->{open_elements}};
          
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'input') {
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        ## TODO: associate with $self->{form_element} if defined
        pop @{$self->{open_elements}};
        
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'isindex') {
        $self->{parse_error}-> (type => 'isindex');
        
        if (defined $self->{form_element}) {
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        } else {
          my $at = $token->{attributes};
          my $form_attrs;
          $form_attrs->{action} = $at->{action} if $at->{action};
          my $prompt_attr = $at->{prompt};
          $at->{name} = {name => 'name', value => 'isindex'};
          delete $at->{action};
          delete $at->{prompt};
          my @tokens = (
                        {type => 'start tag', tag_name => 'form',
                         attributes => $form_attrs},
                        {type => 'start tag', tag_name => 'hr'},
                        {type => 'start tag', tag_name => 'p'},
                        {type => 'start tag', tag_name => 'label'},
                       );
          if ($prompt_attr) {
            push @tokens, {type => 'character', data => $prompt_attr->{value}};
          } else {
            push @tokens, {type => 'character',
                           data => 'This is a searchable index. Insert your search keywords here: '}; # SHOULD
            ## TODO: make this configurable
          }
          push @tokens,
                        {type => 'start tag', tag_name => 'input', attributes => $at},
                        #{type => 'character', data => ''}, # SHOULD
                        {type => 'end tag', tag_name => 'label'},
                        {type => 'end tag', tag_name => 'p'},
                        {type => 'start tag', tag_name => 'hr'},
                        {type => 'end tag', tag_name => 'form'};
          $token = shift @tokens;
          unshift @{$self->{token}}, (@tokens);
          return;
        }
      } elsif ($token->{tag_name} eq 'textarea') {
        my $tag_name = $token->{tag_name};
        my $el;
        
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
        
        ## TODO: $self->{form_element} if defined
        $self->{content_model_flag} = 'RCDATA';
        delete $self->{escape}; # MUST
        
        $insert->($el);
        
        my $text = '';
        $token = $self->_get_next_token;
        if ($token->{type} eq 'character') {
          $token->{data} =~ s/^\x0A//;
          unless (length $token->{data}) {
            $token = $self->_get_next_token;
          }
        }
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
          $self->{parse_error}-> (type => 'in RCDATA:#'.$token->{type});
        }
        $token = $self->_get_next_token;
        return;
      } elsif ({
                iframe => 1,
                noembed => 1,
                noframes => 1,
                noscript => 0, ## TODO: 1 if scripting is enabled
               }->{$token->{tag_name}}) {
        $parse_rcdata->('CDATA', $insert);
        return;
      } elsif ($token->{tag_name} eq 'select') {
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        
        $self->{insertion_mode} = 'in select';
        $token = $self->_get_next_token;
        return;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
               }->{$token->{tag_name}}) {
        $self->{parse_error}-> (type => 'in body:'.$token->{tag_name});
        ## Ignore the token
        $token = $self->_get_next_token;
        return;
        
        ## ISSUE: An issue on HTML5 new elements in the spec.
      } else {
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
        
        $token = $self->_get_next_token;
        return;
      }
    } elsif ($token->{type} eq 'end tag') {
      if ($token->{tag_name} eq 'body') {
        if (@{$self->{open_elements}} > 1 and
            $self->{open_elements}->[1]->[1] eq 'body') {
          for (@{$self->{open_elements}}) {
            unless ({
                       dd => 1, dt => 1, li => 1, p => 1, td => 1,
                       th => 1, tr => 1, body => 1, html => 1,
                    }->{$_->[1]}) {
              $self->{parse_error}-> (type => 'not closed:'.$_->[1]);
            }
          }

          $self->{insertion_mode} = 'after body';
          $token = $self->_get_next_token;
          return;
        } else {
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        }
      } elsif ($token->{tag_name} eq 'html') {
        if (@{$self->{open_elements}} > 1 and $self->{open_elements}->[1]->[1] eq 'body') {
          ## ISSUE: There is an issue in the spec.
          if ($self->{open_elements}->[-1]->[1] ne 'body') {
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[1]->[1]);
          }
          $self->{insertion_mode} = 'after body';
          ## reprocess
          return;
        } else {
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          return;
        }
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1,
                div => 1, dl => 1, fieldset => 1, listing => 1,
                menu => 1, ol => 1, pre => 1, ul => 1,
                p => 1,
                dd => 1, dt => 1, li => 1,
                button => 1, marquee => 1, object => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            ## generate implied end tags
            if ({
                 dd => ($token->{tag_name} ne 'dd'),
                 dt => ($token->{tag_name} ne 'dt'),
                 li => ($token->{tag_name} ne 'li'),
                 p => ($token->{tag_name} ne 'p'),
                 td => 1, th => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
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
        
        if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        }
        
        splice @{$self->{open_elements}}, $i if defined $i;
        $clear_up_to_marker->()
          if {
            button => 1, marquee => 1, object => 1,
          }->{$token->{tag_name}};
        $token = $self->_get_next_token;
        return;
      } elsif ($token->{tag_name} eq 'form') {
        ## has an element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
              return;
            }
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            last INSCOPE;
          }
        } # INSCOPE
        
        if ($self->{open_elements}->[-1]->[1] eq $token->{tag_name}) {
          pop @{$self->{open_elements}};
        } else {
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        }

        undef $self->{form_element};
        $token = $self->_get_next_token;
        return;
      } elsif ({
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ({
               h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
              }->{$node->[1]}) {
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
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
        
        if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        }
        
        splice @{$self->{open_elements}}, $i if defined $i;
        $token = $self->_get_next_token;
        return;
      } elsif ({
                a => 1,
                b => 1, big => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strile => 1,
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        $formatting_end_tag->($token->{tag_name});
## TODO: <http://html5.org/tools/web-apps-tracker?from=883&to=884>
        return;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
                area => 1, basefont => 1, bgsound => 1, br => 1,
                embed => 1, hr => 1, iframe => 1, image => 1,
                img => 1, input => 1, isindex => 1, noembed => 1,
                noframes => 1, param => 1, select => 1, spacer => 1,
                table => 1, textarea => 1, wbr => 1,
                noscript => 0, ## TODO: if scripting is enabled
               }->{$token->{tag_name}}) {
        $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        ## Ignore the token
        $token = $self->_get_next_token;
        return;
        
        ## ISSUE: Issue on HTML5 new elements in spec
        
      } else {
        ## Step 1
        my $node_i = -1;
        my $node = $self->{open_elements}->[$node_i];

        ## Step 2
        S2: {
          if ($node->[1] eq $token->{tag_name}) {
            ## Step 1
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              unshift @{$self->{token}}, $token;
              $token = {type => 'end tag',
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
              return;
            }
        
            ## Step 2
            if ($token->{tag_name} ne $self->{open_elements}->[-1]->[1]) {
              $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
            }
            
            ## Step 3
            splice @{$self->{open_elements}}, $node_i;

            $token = $self->_get_next_token;
            last S2;
          } else {
            ## Step 3
            if (not $formatting_category->{$node->[1]} and
                #not $phrasing_category->{$node->[1]} and
                ($special_category->{$node->[1]} or
                 $scoping_category->{$node->[1]})) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              last S2;
            }
          }
          
          ## Step 4
          $node_i--;
          $node = $self->{open_elements}->[$node_i];
          
          ## Step 5;
          redo S2;
        } # S2
	return;
      }
    }
  }; # $in_body

  B: {
    if ($phase eq 'main') {
      if ($token->{type} eq 'DOCTYPE') {
        $self->{parse_error}-> (type => 'in html:#DOCTYPE');
        ## Ignore the token
        ## Stay in the phase
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'start tag' and
               $token->{tag_name} eq 'html') {
        unless ($token->{first_start_tag}) {
          $self->{parse_error}-> (type => 'not first start tag');
        }
        my $top_el = $self->{open_elements}->[0]->[0];
        for my $attr_name (keys %{$token->{attributes}}) {
          unless ($top_el->has_attribute_ns (undef, $attr_name)) {
            $top_el->set_attribute_ns
              (undef, [undef, $attr_name], 
               $token->{attributes}->{$attr_name}->{value});
          }
        }
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} eq 'end-of-file') {
        ## Generate implied end tags
        if ({
             dd => 1, dt => 1, li => 1, p => 1, td => 1, th => 1, tr => 1,
            }->{$self->{open_elements}->[-1]->[1]}) {
          unshift @{$self->{token}}, $token;
          $token = {type => 'end tag', tag_name => $self->{open_elements}->[-1]->[1]};
          redo B;
        }
        
        if (@{$self->{open_elements}} > 2 or
            (@{$self->{open_elements}} == 2 and $self->{open_elements}->[1]->[1] ne 'body')) {
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        } elsif (defined $self->{inner_html_node} and
                 @{$self->{open_elements}} > 1 and
                 $self->{open_elements}->[1]->[1] ne 'body') {
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        }

        ## Stop parsing
        last B;

        ## ISSUE: There is an issue in the spec.
      } else {
        if ($self->{insertion_mode} eq 'before head') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            ## As if <head>
            
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
            $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
            push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
            $self->{insertion_mode} = 'in head';
            ## reprocess
            redo B;
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            my $attr = $token->{tag_name} eq 'head' ? $token->{attributes} : {};
            
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
        for my $attr_name (keys %{ $attr}) {
          $self->{head_element}->set_attribute_ns (undef, [undef, $attr_name],
                                 $attr ->{$attr_name}->{value});
        }
      
            $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
            push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
            $self->{insertion_mode} = 'in head';
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
            if ({head => 1, body => 1, html => 1}->{$token->{tag_name}}) {
              ## As if <head>
              
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
              $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
              push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              $self->{insertion_mode} = 'in head';
              ## reprocess
              redo B;
            } else {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token ## ISSUE: An issue in the spec.
              $token = $self->_get_next_token;
              redo B;
            }
          } else {
            die "$0: $token->{type}: Unknown type";
          }
        } elsif ($self->{insertion_mode} eq 'in head' or
                 $self->{insertion_mode} eq 'in head noscript' or
                 $self->{insertion_mode} eq 'after head') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({base => ($self->{insertion_mode} eq 'in head' or
                          $self->{insertion_mode} eq 'after head'),
                 link => 1, meta => 1}->{$token->{tag_name}}) {
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} eq 'after head') {
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              }
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.
              ## TODO: Extracting |charset| from |meta|.
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} eq 'after head';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'title' and
                     $self->{insertion_mode} eq 'in head') {
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} eq 'after head') {
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              }
              $parse_rcdata->('RCDATA', $insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} eq 'after head';
              redo B;
            } elsif ($token->{tag_name} eq 'style') {
              ## NOTE: Or (scripting is enabled and tag_name eq 'noscript' and
              ## insertion mode 'in head')
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} eq 'after head') {
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              }
              $parse_rcdata->('CDATA', $insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} eq 'after head';
              redo B;
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} eq 'in head') {
                ## NOTE: and scripting is disalbed
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
                $self->{insertion_mode} = 'in head noscript';
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} eq 'in head noscript') {
                $self->{parse_error}-> (type => 'noscript in noscript');
                ## Ignore the token
                redo B;
              } else {
                #
              }
            } elsif ($token->{tag_name} eq 'head' and
                     $self->{insertion_mode} ne 'after head') {
              $self->{parse_error}-> (type => 'in head:head'); # or in head noscript
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } elsif ($self->{insertion_mode} ne 'in head noscript' and
                     $token->{tag_name} eq 'script') {
              if ($self->{insertion_mode} eq 'after head') {
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              }
              ## NOTE: There is a "as if in head" code clone.
              $script_start_tag->($insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} eq 'after head';
              redo B;
            } elsif ($self->{insertion_mode} eq 'after head' and
                     $token->{tag_name} eq 'body') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'body'];
    }
  
              $self->{insertion_mode} = 'in body';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($self->{insertion_mode} eq 'after head' and
                     $token->{tag_name} eq 'frameset') {
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'frameset']);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'frameset'];
    }
  
              $self->{insertion_mode} = 'in frameset';
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($self->{insertion_mode} eq 'in head' and
                $token->{tag_name} eq 'head') {
              pop @{$self->{open_elements}};
              $self->{insertion_mode} = 'after head';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($self->{insertion_mode} eq 'in head noscript' and
                $token->{tag_name} eq 'noscript') {
              pop @{$self->{open_elements}};
              $self->{insertion_mode} = 'in head';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($self->{insertion_mode} eq 'in head' and
                     ($token->{tag_name} eq 'body' or
                      $token->{tag_name} eq 'html')) {
              #
            } elsif ($self->{insertion_mode} ne 'after head') {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }

          ## As if </head> or </noscript> or <body>
          if ($self->{insertion_mode} eq 'in head') {
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = 'after head';
          } elsif ($self->{insertion_mode} eq 'in head noscript') {
            pop @{$self->{open_elements}};
            $self->{parse_error}-> (type => 'in noscript:'.(defined $token->{tag_name} ? ($token->{type} eq 'end tag' ? '/' : '') . $token->{tag_name} : '#' . $token->{type}));
            $self->{insertion_mode} = 'in head';
          } else { # 'after head'
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'body'];
    }
  
            $self->{insertion_mode} = 'in body';
          }
          ## reprocess
          redo B;

          ## ISSUE: An issue in the spec.
        } elsif ($self->{insertion_mode} eq 'in body') {
          if ($token->{type} eq 'character') {
            ## NOTE: There is a code clone of "character in body".
            $reconstruct_active_formatting_elements->($insert_to_current);
            
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## NOTE: There is a code clone of "comment in body".
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } else {
            $in_body->($insert_to_current);
            redo B;
          }
        } elsif ($self->{insertion_mode} eq 'in table') {
          if ($token->{type} eq 'character') {
            ## NOTE: There are "character in table" code clones.
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            $self->{parse_error}-> (type => 'in table:#character');

            ## As if in body, but insert into foster parent element
            ## ISSUE: Spec says that "whenever a node would be inserted
            ## into the current node" while characters might not be
            ## result in a new Text node.
            $reconstruct_active_formatting_elements->($insert_to_foster);
            
            if ({
                 table => 1, tbody => 1, tfoot => 1,
                 thead => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              # MUST
              my $foster_parent_element;
              my $next_sibling;
              my $prev_sibling;
              OE: for (reverse 0..$#{$self->{open_elements}}) {
                if ($self->{open_elements}->[$_]->[1] eq 'table') {
                  my $parent = $self->{open_elements}->[$_]->[0]->parent_node;
                  if (defined $parent and $parent->node_type == 1) {
                    $foster_parent_element = $parent;
                    $next_sibling = $self->{open_elements}->[$_]->[0];
                    $prev_sibling = $next_sibling->previous_sibling;
                  } else {
                    $foster_parent_element = $self->{open_elements}->[$_ - 1]->[0];
                    $prev_sibling = $foster_parent_element->last_child;
                  }
                  last OE;
                }
              } # OE
              $foster_parent_element = $self->{open_elements}->[0]->[0] and
              $prev_sibling = $foster_parent_element->last_child
                unless defined $foster_parent_element;
              if (defined $prev_sibling and
                  $prev_sibling->node_type == 3) {
                $prev_sibling->manakai_append_text ($token->{data});
              } else {
                $foster_parent_element->insert_before
                  ($self->{document}->create_text_node ($token->{data}),
                   $next_sibling);
              }
            } else {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
            }
            
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({
                 caption => 1,
                 colgroup => 1,
                 tbody => 1, tfoot => 1, thead => 1,
                }->{$token->{tag_name}}) {
              ## Clear back to table context
              while ($self->{open_elements}->[-1]->[1] ne 'table' and
                     $self->{open_elements}->[-1]->[1] ne 'html') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
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
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              $self->{insertion_mode} = {
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
              while ($self->{open_elements}->[-1]->[1] ne 'table' and
                     $self->{open_elements}->[-1]->[1] ne 'html') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name} eq 'col' ? 'colgroup' : 'tbody']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name} eq 'col' ? 'colgroup' : 'tbody'];
    }
  
              $self->{insertion_mode} = $token->{tag_name} eq 'col'
                ? 'in column group' : 'in table body';
              ## reprocess
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## NOTE: There are code clones for this "table in table"
              $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:table');
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => 'end tag', tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode; 

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'table') {
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, tbody => 1, td => 1, tfoot => 1, th => 1,
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } else {
            #
          }

          $self->{parse_error}-> (type => 'in table:'.$token->{tag_name});
          $in_body->($insert_to_foster);
          redo B;
        } elsif ($self->{insertion_mode} eq 'in caption') {
          if ($token->{type} eq 'character') {
            ## NOTE: This is a code clone of "character in body".
            $reconstruct_active_formatting_elements->($insert_to_current);
            
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## NOTE: This is a code clone of "comment in body".
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({
                 caption => 1, col => 1, colgroup => 1, tbody => 1,
                 td => 1, tfoot => 1, th => 1, thead => 1, tr => 1,
                }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'not closed:caption');

              ## As if </caption>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:caption');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <?>
                $token = {type => 'end tag', tag_name => 'caption'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->();

              $self->{insertion_mode} = 'in table';

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'caption') {
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->();

              $self->{insertion_mode} = 'in table';

              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              $self->{parse_error}-> (type => 'not closed:caption');

              ## As if </caption>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:caption');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # </table>
                $token = {type => 'end tag', tag_name => 'caption'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->();

              $self->{insertion_mode} = 'in table';

              ## reprocess
              redo B;
            } elsif ({
                      body => 1, col => 1, colgroup => 1,
                      html => 1, tbody => 1, td => 1, tfoot => 1,
                      th => 1, thead => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              redo B;
            } else {
              #
            }
          } else {
            #
          }
              
          $in_body->($insert_to_current);
          redo B;
        } elsif ($self->{insertion_mode} eq 'in column group') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
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
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              pop @{$self->{open_elements}};
              $token = $self->_get_next_token;
              redo B;
            } else { 
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'colgroup') {
              if ($self->{open_elements}->[-1]->[1] eq 'html') {
                $self->{parse_error}-> (type => 'unmatched end tag:colgroup');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                pop @{$self->{open_elements}}; # colgroup
                $self->{insertion_mode} = 'in table';
                $token = $self->_get_next_token;
                redo B;             
              }
            } elsif ($token->{tag_name} eq 'col') {
              $self->{parse_error}-> (type => 'unmatched end tag:col');
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
          if ($self->{open_elements}->[-1]->[1] eq 'html') {
            $self->{parse_error}-> (type => 'unmatched end tag:colgroup');
            ## Ignore the token
            $token = $self->_get_next_token;
            redo B;
          } else {
            pop @{$self->{open_elements}}; # colgroup
            $self->{insertion_mode} = 'in table';
            ## reprocess
            redo B;
          }
        } elsif ($self->{insertion_mode} eq 'in table body') {
          if ($token->{type} eq 'character') {
            ## NOTE: This is a "character in table" code clone.
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            $self->{parse_error}-> (type => 'in table:#character');

            ## As if in body, but insert into foster parent element
            ## ISSUE: Spec says that "whenever a node would be inserted
            ## into the current node" while characters might not be
            ## result in a new Text node.
            $reconstruct_active_formatting_elements->($insert_to_foster);

            if ({
                 table => 1, tbody => 1, tfoot => 1,
                 thead => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              # MUST
              my $foster_parent_element;
              my $next_sibling;
              my $prev_sibling;
              OE: for (reverse 0..$#{$self->{open_elements}}) {
                if ($self->{open_elements}->[$_]->[1] eq 'table') {
                  my $parent = $self->{open_elements}->[$_]->[0]->parent_node;
                  if (defined $parent and $parent->node_type == 1) {
                    $foster_parent_element = $parent;
                    $next_sibling = $self->{open_elements}->[$_]->[0];
                    $prev_sibling = $next_sibling->previous_sibling;
                  } else {
                    $foster_parent_element = $self->{open_elements}->[$_ - 1]->[0];
                    $prev_sibling = $foster_parent_element->last_child;
                  }
                  last OE;
                }
              } # OE
              $foster_parent_element = $self->{open_elements}->[0]->[0] and
              $prev_sibling = $foster_parent_element->last_child
                unless defined $foster_parent_element;
              if (defined $prev_sibling and
                  $prev_sibling->node_type == 3) {
                $prev_sibling->manakai_append_text ($token->{data});
              } else {
                $foster_parent_element->insert_before
                  ($self->{document}->create_text_node ($token->{data}),
                   $next_sibling);
              }
            } else {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
            }
            
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## Copied from 'in table'
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ({
                 tr => 1,
                 th => 1, td => 1,
                }->{$token->{tag_name}}) {
              unless ($token->{tag_name} eq 'tr') {
                $self->{parse_error}-> (type => 'missing start tag:tr');
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }
              
              $self->{insertion_mode} = 'in row';
              if ($token->{tag_name} eq 'tr') {
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
                $token = $self->_get_next_token;
              } else {
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'tr']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'tr'];
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
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              ## As if <{current node}>
              ## have an element in table scope
              ## true by definition

              ## Clear back to table body context
              ## nop by definition

              pop @{$self->{open_elements}};
              $self->{insertion_mode} = 'in table';
              ## reprocess
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## NOTE: This is a code clone of "table in table"
              $self->{parse_error}-> (type => 'not closed:table');

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:table');
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => 'end tag', tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

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
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}};
              $self->{insertion_mode} = 'in table';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              ## As if <{current node}>
              ## have an element in table scope
              ## true by definition

              ## Clear back to table body context
              ## nop by definition

              pop @{$self->{open_elements}};
              $self->{insertion_mode} = 'in table';
              ## reprocess
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, td => 1, th => 1, tr => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
          $self->{parse_error}-> (type => 'in table:'.$token->{tag_name});
          $in_body->($insert_to_foster);
          redo B;
        } elsif ($self->{insertion_mode} eq 'in row') {
          if ($token->{type} eq 'character') {
            ## NOTE: This is a "character in table" code clone.
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              
              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            $self->{parse_error}-> (type => 'in table:#character');

            ## As if in body, but insert into foster parent element
            ## ISSUE: Spec says that "whenever a node would be inserted
            ## into the current node" while characters might not be
            ## result in a new Text node.
            $reconstruct_active_formatting_elements->($insert_to_foster);
            
            if ({
                 table => 1, tbody => 1, tfoot => 1,
                 thead => 1, tr => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              # MUST
              my $foster_parent_element;
              my $next_sibling;
              my $prev_sibling;
              OE: for (reverse 0..$#{$self->{open_elements}}) {
                if ($self->{open_elements}->[$_]->[1] eq 'table') {
                  my $parent = $self->{open_elements}->[$_]->[0]->parent_node;
                  if (defined $parent and $parent->node_type == 1) {
                    $foster_parent_element = $parent;
                    $next_sibling = $self->{open_elements}->[$_]->[0];
                    $prev_sibling = $next_sibling->previous_sibling;
                  } else {
                    $foster_parent_element = $self->{open_elements}->[$_ - 1]->[0];
                    $prev_sibling = $foster_parent_element->last_child;
                  }
                  last OE;
                }
              } # OE
              $foster_parent_element = $self->{open_elements}->[0]->[0] and
              $prev_sibling = $foster_parent_element->last_child
                unless defined $foster_parent_element;
              if (defined $prev_sibling and
                  $prev_sibling->node_type == 3) {
                $prev_sibling->manakai_append_text ($token->{data});
              } else {
                $foster_parent_element->insert_before
                  ($self->{document}->create_text_node ($token->{data}),
                   $next_sibling);
              }
            } else {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
            }
            
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## Copied from 'in table'
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'th' or
                $token->{tag_name} eq 'td') {
              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }
              
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              $self->{insertion_mode} = 'in cell';

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
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmacthed end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}}; # tr
              $self->{insertion_mode} = 'in table body';
              ## reprocess
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## NOTE: This is a code clone of "table in table"
              $self->{parse_error}-> (type => 'not closed:table');

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:table');
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => 'end tag', tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              ## reprocess
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'tr') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}}; # tr
              $self->{insertion_mode} = 'in table body';
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              ## As if </tr>
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{type});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}}; # tr
              $self->{insertion_mode} = 'in table body';
              ## reprocess
              redo B;
            } elsif ({
                      tbody => 1, tfoot => 1, thead => 1,
                     }->{$token->{tag_name}}) {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## As if </tr>
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:tr');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}}; # tr
              $self->{insertion_mode} = 'in table body';
              ## reprocess
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1,
                      colgroup => 1, html => 1, td => 1, th => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
          $self->{parse_error}-> (type => 'in table:'.$token->{tag_name});
          $in_body->($insert_to_foster);
          redo B;
        } elsif ($self->{insertion_mode} eq 'in cell') {
          if ($token->{type} eq 'character') {
            ## NOTE: This is a code clone of "character in body".
            $reconstruct_active_formatting_elements->($insert_to_current);
            
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            ## NOTE: This is a code clone of "comment in body".
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
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
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
            if ($token->{tag_name} eq 'td' or $token->{tag_name} eq 'th') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
                  }->{$self->{open_elements}->[-1]->[1]}) {
                unshift @{$self->{token}}, $token;
                $token = {type => 'end tag',
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->();

              $self->{insertion_mode} = 'in row';

              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1,
                      colgroup => 1, html => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  $i = $_;
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
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
          
          $in_body->($insert_to_current);
          redo B;
        } elsif ($self->{insertion_mode} eq 'in select') {
          if ($token->{type} eq 'character') {
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'option') {
              if ($self->{open_elements}->[-1]->[1] eq 'option') {
                ## As if </option>
                pop @{$self->{open_elements}};
              }

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'optgroup') {
              if ($self->{open_elements}->[-1]->[1] eq 'option') {
                ## As if </option>
                pop @{$self->{open_elements}};
              }

              if ($self->{open_elements}->[-1]->[1] eq 'optgroup') {
                ## As if </optgroup>
                pop @{$self->{open_elements}};
              }

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          $el->set_attribute_ns (undef, [undef, $attr_name],
                                  $token->{attributes} ->{$attr_name}->{value});
        }
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'select') {
              $self->{parse_error}-> (type => 'not closed:select');
              ## As if </select> instead
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:select');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              $token = $self->_get_next_token;
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'optgroup') {
              if ($self->{open_elements}->[-1]->[1] eq 'option' and
                  $self->{open_elements}->[-2]->[1] eq 'optgroup') {
                ## As if </option>
                splice @{$self->{open_elements}}, -2;
              } elsif ($self->{open_elements}->[-1]->[1] eq 'optgroup') {
                pop @{$self->{open_elements}};
              } else {
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
              }
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'option') {
              if ($self->{open_elements}->[-1]->[1] eq 'option') {
                pop @{$self->{open_elements}};
              } else {
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
              }
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'select') {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      caption => 1, table => 1, tbody => 1,
                      tfoot => 1, thead => 1, tr => 1, td => 1, th => 1,
                     }->{$token->{tag_name}}) {
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
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
                $self->{parse_error}-> (type => 'unmatched end tag:select');
                ## Ignore the </select> token
                $token = $self->_get_next_token; ## TODO: ok?
                redo B;
              }
              
              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              ## reprocess
              redo B;
            } else {
              # 
            }
          } else {
            #
          }

          $self->{parse_error}-> (type => 'in select:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        } elsif ($self->{insertion_mode} eq 'after body') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              ## As if in body
              $reconstruct_active_formatting_elements->($insert_to_current);
              
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            #
            $self->{parse_error}-> (type => 'after body:#'.$token->{type});
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[0]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            $self->{parse_error}-> (type => 'after body:'.$token->{tag_name});
            #
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'html') {
              if (defined $self->{inner_html_node}) {
                $self->{parse_error}-> (type => 'unmatched end tag:html');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                $phase = 'trailing end';
                $token = $self->_get_next_token;
                redo B;
              }
            } else {
              $self->{parse_error}-> (type => 'after body:/'.$token->{tag_name});
            }
          } else {
            $self->{parse_error}-> (type => 'after body:#'.$token->{type});
          }

          $self->{insertion_mode} = 'in body';
          ## reprocess
          redo B;
        } elsif ($self->{insertion_mode} eq 'in frameset') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
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
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
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
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $token->{tag_name}];
    }
  
              pop @{$self->{open_elements}};
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'noframes') {
              $in_body->($insert_to_current);
              redo B;
            } else {
              #
            }
          } elsif ($token->{type} eq 'end tag') {
            if ($token->{tag_name} eq 'frameset') {
              if ($self->{open_elements}->[-1]->[1] eq 'html' and
                  @{$self->{open_elements}} == 1) {
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
              } else {
                pop @{$self->{open_elements}};
                $token = $self->_get_next_token;
              }
              
              ## if not inner_html and
              if ($self->{open_elements}->[-1]->[1] ne 'frameset') {
                $self->{insertion_mode} = 'after frameset';
              }
              redo B;
            } else {
              #
            }
          } else {
            #
          }
          
          if (defined $token->{tag_name}) {
            $self->{parse_error}-> (type => 'in frameset:'.$token->{tag_name});
          } else {
            $self->{parse_error}-> (type => 'in frameset:#'.$token->{type});
          }
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        } elsif ($self->{insertion_mode} eq 'after frameset') {
          if ($token->{type} eq 'character') {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

              unless (length $token->{data}) {
                $token = $self->_get_next_token;
                redo B;
              }
            }

            #
          } elsif ($token->{type} eq 'comment') {
            my $comment = $self->{document}->create_comment ($token->{data});
            $self->{open_elements}->[-1]->[0]->append_child ($comment);
            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} eq 'start tag') {
            if ($token->{tag_name} eq 'noframes') {
              $in_body->($insert_to_current);
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
          
          if (defined $token->{tag_name}) {
            $self->{parse_error}-> (type => 'after frameset:'.$token->{tag_name});
          } else {
            $self->{parse_error}-> (type => 'after frameset:#'.$token->{type});
          }
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;

          ## ISSUE: An issue in spec there
        } else {
          die "$0: $self->{insertion_mode}: Unknown insertion mode";
        }
      }
    } elsif ($phase eq 'trailing end') {
      ## states in the main stage is preserved yet # MUST
      
      if ($token->{type} eq 'DOCTYPE') {
        $self->{parse_error}-> (type => 'after html:#DOCTYPE');
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
          my $data = $1;
          ## As if in the main phase.
          ## NOTE: The insertion mode in the main phase
          ## just before the phase has been changed to the trailing
          ## end phase is either "after body" or "after frameset".
          $reconstruct_active_formatting_elements->($insert_to_current)
            if $phase eq 'main';
          
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($data);
          
          unless (length $token->{data}) {
            $token = $self->_get_next_token;
            redo B;
          }
        }

        $self->{parse_error}-> (type => 'after html:#character');
        $phase = 'main';
        ## reprocess
        redo B;
      } elsif ($token->{type} eq 'start tag' or
               $token->{type} eq 'end tag') {
        $self->{parse_error}-> (type => 'after html:'.$token->{tag_name});
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
} # _tree_construct_main

sub set_inner_html ($$$) {
  my $class = shift;
  my $node = shift;
  my $s = \$_[0];
  my $onerror = $_[1];

  my $nt = $node->node_type;
  if ($nt == 9) {
    # MUST
    
    ## Step 1 # MUST
    ## TODO: If the document has an active parser, ...
    ## ISSUE: There is an issue in the spec.
    
    ## Step 2 # MUST
    my @cn = @{$node->child_nodes};
    for (@cn) {
      $node->remove_child ($_);
    }

    ## Step 3, 4, 5 # MUST
    $class->parse_string ($$s => $node, $onerror);
  } elsif ($nt == 1) {
    ## TODO: If non-html element

    ## NOTE: Most of this code is copied from |parse_string|

    ## Step 1 # MUST
    my $this_doc = $node->owner_document;
    my $doc = $this_doc->implementation->create_document;
    $doc->manakai_is_html (1);
    my $p = $class->new;
    $p->{document} = $doc;

    ## Step 9 # MUST
    my $i = 0;
    my $line = 1;
    my $column = 0;
    $p->{set_next_input_character} = sub {
      my $self = shift;

      pop @{$self->{prev_input_character}};
      unshift @{$self->{prev_input_character}}, $self->{next_input_character};

      $self->{next_input_character} = -1 and return if $i >= length $$s;
      $self->{next_input_character} = ord substr $$s, $i++, 1;
      $column++;

      if ($self->{next_input_character} == 0x000A) { # LF
        $line++;
        $column = 0;
      } elsif ($self->{next_input_character} == 0x000D) { # CR
        $i++ if substr ($$s, $i, 1) eq "\x0A";
        $self->{next_input_character} = 0x000A; # LF # MUST
        $line++;
        $column = 0;
      } elsif ($self->{next_input_character} > 0x10FFFF) {
        $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
      } elsif ($self->{next_input_character} == 0x0000) { # NULL
        $self->{parse_error}-> (type => 'NULL');
        $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
      }
    };
    $p->{prev_input_character} = [-1, -1, -1];
    $p->{next_input_character} = -1;
    
    my $ponerror = $onerror || sub {
      my (%opt) = @_;
      warn "Parse error ($opt{type}) at line $opt{line} column $opt{column}\n";
    };
    $p->{parse_error} = sub {
      $ponerror->(@_, line => $line, column => $column);
    };
    
    $p->_initialize_tokenizer;
    $p->_initialize_tree_constructor;

    ## Step 2
    my $node_ln = $node->local_name;
    $p->{content_model_flag} = {
      title => 'RCDATA',
      textarea => 'RCDATA',
      style => 'CDATA',
      script => 'CDATA',
      xmp => 'CDATA',
      iframe => 'CDATA',
      noembed => 'CDATA',
      noframes => 'CDATA',
      noscript => 'CDATA',
      plaintext => 'PLAINTEXT',
    }->{$node_ln} || 'PCDATA';
       ## ISSUE: What is "the name of the element"? local name?

    $p->{inner_html_node} = [$node, $node_ln];

    ## Step 4
    my $root = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, 'html']);

    ## Step 5 # MUST
    $doc->append_child ($root);

    ## Step 6 # MUST
    push @{$p->{open_elements}}, [$root, 'html'];

    undef $p->{head_element};

    ## Step 7 # MUST
    $p->_reset_insertion_mode;

    ## Step 8 # MUST
    my $anode = $node;
    AN: while (defined $anode) {
      if ($anode->node_type == 1) {
        my $nsuri = $anode->namespace_uri;
        if (defined $nsuri and $nsuri eq 'http://www.w3.org/1999/xhtml') {
          if ($anode->local_name eq 'form') { ## TODO: case?
            $p->{form_element} = $anode;
            last AN;
          }
        }
      }
      $anode = $anode->parent_node;
    } # AN
    
    ## Step 3 # MUST
    ## Step 10 # MUST
    {
      my $self = $p;
      $token = $self->_get_next_token;
    }
    $p->_tree_construction_main;

    ## Step 11 # MUST
    my @cn = @{$node->child_nodes};
    for (@cn) {
      $node->remove_child ($_);
    }
    ## ISSUE: mutation events? read-only?

    ## Step 12 # MUST
    @cn = @{$root->child_nodes};
    for (@cn) {
      $this_doc->adopt_node ($_);
      $node->append_child ($_);
    }
    ## ISSUE: mutation events?

    $p->_terminate_tree_constructor;
  } else {
    die "$0: |set_inner_html| is not defined for node of type $nt";
  }
} # set_inner_html

} # tree construction stage

sub get_inner_html ($$$) {
  my (undef, $node, $on_error) = @_;

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
      my $tag_name = $child->tag_name; ## TODO: manakai_tag_name
      $s .= '<' . $tag_name;
      ## NOTE: Non-HTML case: 
      ## <http://permalink.gmane.org/gmane.org.w3c.whatwg.discuss/11191>

      my @attrs = @{$child->attributes}; # sort order MUST be stable
      for my $attr (@attrs) { # order is implementation dependent
        my $attr_name = $attr->name; ## TODO: manakai_name
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

      $s .= "\x0A" if $tag_name eq 'pre' or $tag_name eq 'textarea';

      if (not $in_cdata and {
        style => 1, script => 1, xmp => 1, iframe => 1,
        noembed => 1, noframes => 1, noscript => 1,
        plaintext => 1,
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
      $on_error->($child) if defined $on_error;
    }
    ## ISSUE: This code does not support PIs.
  } # C
  
  ## Step 3
  return \$s;
} # get_inner_html

1;
# $Date: 2007/06/25 00:14:39 $
