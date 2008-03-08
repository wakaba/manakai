package Whatpm::HTML;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.94 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Error qw(:try);

## ISSUE:
## var doc = implementation.createDocument (null, null, null);
## doc.write ('');
## alert (doc.compatMode);

## TODO: Control charcters and noncharacters are not allowed (HTML5 revision 1263)
## TODO: 1252 parse error (revision 1264)
## TODO: 8859-11 = 874 (revision 1271)

my $permitted_slash_tag_name = {
  base => 1,
  link => 1,
  meta => 1,
  hr => 1,
  br => 1,
  img => 1,
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

sub parse_byte_string ($$$$;$) {
  my $self = ref $_[0] ? shift : shift->new;
  my $charset = shift;
  my $bytes_s = ref $_[0] ? $_[0] : \($_[0]);
  my $s;
  
  if (defined $charset) {
    require Encode; ## TODO: decode(utf8) don't delete BOM
    $s = \ (Encode::decode ($charset, $$bytes_s));
    $self->{input_encoding} = lc $charset; ## TODO: normalize name
    $self->{confident} = 1;
  } else {
    ## TODO: Implement HTML5 detection algorithm
    require Whatpm::Charset::UniversalCharDet;
    $charset = Whatpm::Charset::UniversalCharDet->detect_byte_string
        (substr ($$bytes_s, 0, 1024));
    $charset ||= 'windows-1252';
    $s = \ (Encode::decode ($charset, $$bytes_s));
    $self->{input_encoding} = $charset;
    $self->{confident} = 0;
  }

  $self->{change_encoding} = sub {
    my $self = shift;
    my $charset = lc shift;
    ## TODO: if $charset is supported
    ## TODO: normalize charset name

    ## "Change the encoding" algorithm:

    ## Step 1    
    if ($charset eq 'utf-16') { ## ISSUE: UTF-16BE -> UTF-8? UTF-16LE -> UTF-8?
      $charset = 'utf-8';
    }

    ## Step 2
    if (defined $self->{input_encoding} and
        $self->{input_encoding} eq $charset) {
      $self->{confident} = 1;
      return;
    }

    $self->{parse_error}-> (type => 'charset label detected:'.$self->{input_encoding}.
        ':'.$charset, level => 'w');

    ## Step 3
    # if (can) {
      ## change the encoding on the fly.
      #$self->{confident} = 1;
      #return;
    # }

    ## Step 4
    throw Whatpm::HTML::RestartParser (charset => $charset);
  }; # $self->{change_encoding}

  my @args = @_; shift @args; # $s
  my $return;
  try {
    $return = $self->parse_char_string ($s, @args);  
  } catch Whatpm::HTML::RestartParser with {
    my $charset = shift->{charset};
    $s = \ (Encode::decode ($charset, $$bytes_s));    
    $self->{input_encoding} = $charset; ## TODO: normalize
    $self->{confident} = 1;
    $return = $self->parse_char_string ($s, @args);
  };
  return $return;
} # parse_byte_string

## NOTE: HTML5 spec says that the encoding layer MUST NOT strip BOM
## and the HTML layer MUST ignore it.  However, we does strip BOM in
## the encoding layer and the HTML layer does not ignore any U+FEFF,
## because the core part of our HTML parser expects a string of character,
## not a string of bytes or code units or anything which might contain a BOM.
## Therefore, any parser interface that accepts a string of bytes,
## such as |parse_byte_string| in this module, must ensure that it does
## strip the BOM and never strip any ZWNBSP.

*parse_char_string = \&parse_string;

sub parse_string ($$$;$) {
  my $self = ref $_[0] ? shift : shift->new;
  my $s = ref $_[0] ? $_[0] : \($_[0]);
  $self->{document} = $_[1];
  @{$self->{document}->child_nodes} = ();

  ## NOTE: |set_inner_html| copies most of this method's code

  $self->{confident} = 1 unless exists $self->{confident};
  $self->{document}->input_encoding ($self->{input_encoding})
      if defined $self->{input_encoding};

  my $i = 0;
  my $line = 1;
  my $column = 0;
  $self->{set_next_char} = sub {
    my $self = shift;

    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    $self->{next_char} = -1 and return if $i >= length $$s;
    $self->{next_char} = ord substr $$s, $i++, 1;
    $column++;
    
    if ($self->{next_char} == 0x000A) { # LF
      $line++;
      $column = 0;
    } elsif ($self->{next_char} == 0x000D) { # CR
      $i++ if substr ($$s, $i, 1) eq "\x0A";
      $self->{next_char} = 0x000A; # LF # MUST
      $line++;
      $column = 0;
    } elsif ($self->{next_char} > 0x10FFFF) {
      $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    } elsif ($self->{next_char} == 0x0000) { # NULL
      $self->{parse_error}-> (type => 'NULL');
      $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    }
  };
  $self->{prev_char} = [-1, -1, -1];
  $self->{next_char} = -1;

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
  $self->{set_next_char} = sub {
    $self->{next_char} = -1;
  };
  $self->{parse_error} = sub {
    # 
  };
  $self->{change_encoding} = sub {
    # if ($_[0] is a supported encoding) {
    #   run "change the encoding" algorithm;
    #   throw Whatpm::HTML::RestartParser (charset => $new_encoding);
    # }
  };
  $self->{application_cache_selection} = sub {
    #
  };
  return $self;
} # new

sub CM_ENTITY () { 0b001 } # & markup in data
sub CM_LIMITED_MARKUP () { 0b010 } # < markup in data (limited)
sub CM_FULL_MARKUP () { 0b100 } # < markup in data (any)

sub PLAINTEXT_CONTENT_MODEL () { 0 }
sub CDATA_CONTENT_MODEL () { CM_LIMITED_MARKUP }
sub RCDATA_CONTENT_MODEL () { CM_ENTITY | CM_LIMITED_MARKUP }
sub PCDATA_CONTENT_MODEL () { CM_ENTITY | CM_FULL_MARKUP }

sub DATA_STATE () { 0 }
sub ENTITY_DATA_STATE () { 1 }
sub TAG_OPEN_STATE () { 2 }
sub CLOSE_TAG_OPEN_STATE () { 3 }
sub TAG_NAME_STATE () { 4 }
sub BEFORE_ATTRIBUTE_NAME_STATE () { 5 }
sub ATTRIBUTE_NAME_STATE () { 6 }
sub AFTER_ATTRIBUTE_NAME_STATE () { 7 }
sub BEFORE_ATTRIBUTE_VALUE_STATE () { 8 }
sub ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE () { 9 }
sub ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE () { 10 }
sub ATTRIBUTE_VALUE_UNQUOTED_STATE () { 11 }
sub ENTITY_IN_ATTRIBUTE_VALUE_STATE () { 12 }
sub MARKUP_DECLARATION_OPEN_STATE () { 13 }
sub COMMENT_START_STATE () { 14 }
sub COMMENT_START_DASH_STATE () { 15 }
sub COMMENT_STATE () { 16 }
sub COMMENT_END_STATE () { 17 }
sub COMMENT_END_DASH_STATE () { 18 }
sub BOGUS_COMMENT_STATE () { 19 }
sub DOCTYPE_STATE () { 20 }
sub BEFORE_DOCTYPE_NAME_STATE () { 21 }
sub DOCTYPE_NAME_STATE () { 22 }
sub AFTER_DOCTYPE_NAME_STATE () { 23 }
sub BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE () { 24 }
sub DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE () { 25 }
sub DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE () { 26 }
sub AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE () { 27 }
sub BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE () { 28 }
sub DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE () { 29 }
sub DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE () { 30 }
sub AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE () { 31 }
sub BOGUS_DOCTYPE_STATE () { 32 }
sub AFTER_ATTRIBUTE_VALUE_QUOTED_STATE () { 33 }

sub DOCTYPE_TOKEN () { 1 }
sub COMMENT_TOKEN () { 2 }
sub START_TAG_TOKEN () { 3 }
sub END_TAG_TOKEN () { 4 }
sub END_OF_FILE_TOKEN () { 5 }
sub CHARACTER_TOKEN () { 6 }

sub AFTER_HTML_IMS () { 0b100 }
sub HEAD_IMS ()       { 0b1000 }
sub BODY_IMS ()       { 0b10000 }
sub BODY_TABLE_IMS () { 0b100000 }
sub TABLE_IMS ()      { 0b1000000 }
sub ROW_IMS ()        { 0b10000000 }
sub BODY_AFTER_IMS () { 0b100000000 }
sub FRAME_IMS ()      { 0b1000000000 }

## NOTE: "initial" and "before html" insertion modes have no constants.

## NOTE: "after after body" insertion mode.
sub AFTER_HTML_BODY_IM () { AFTER_HTML_IMS | BODY_AFTER_IMS }

## NOTE: "after after frameset" insertion mode.
sub AFTER_HTML_FRAMESET_IM () { AFTER_HTML_IMS | FRAME_IMS }

sub IN_HEAD_IM () { HEAD_IMS | 0b00 }
sub IN_HEAD_NOSCRIPT_IM () { HEAD_IMS | 0b01 }
sub AFTER_HEAD_IM () { HEAD_IMS | 0b10 }
sub BEFORE_HEAD_IM () { HEAD_IMS | 0b11 }
sub IN_BODY_IM () { BODY_IMS }
sub IN_CELL_IM () { BODY_IMS | BODY_TABLE_IMS | 0b01 }
sub IN_CAPTION_IM () { BODY_IMS | BODY_TABLE_IMS | 0b10 }
sub IN_ROW_IM () { TABLE_IMS | ROW_IMS | 0b01 }
sub IN_TABLE_BODY_IM () { TABLE_IMS | ROW_IMS | 0b10 }
sub IN_TABLE_IM () { TABLE_IMS }
sub AFTER_BODY_IM () { BODY_AFTER_IMS }
sub IN_FRAMESET_IM () { FRAME_IMS | 0b01 }
sub AFTER_FRAMESET_IM () { FRAME_IMS | 0b10 }
sub IN_SELECT_IM () { 0b01 }
sub IN_COLUMN_GROUP_IM () { 0b10 }

## Implementations MUST act as if state machine in the spec

sub _initialize_tokenizer ($) {
  my $self = shift;
  $self->{state} = DATA_STATE; # MUST
  $self->{content_model} = PCDATA_CONTENT_MODEL; # be
  undef $self->{current_token}; # start tag, end tag, comment, or DOCTYPE
  undef $self->{current_attribute};
  undef $self->{last_emitted_start_tag_name};
  undef $self->{last_attribute_value_state};
  $self->{char} = [];
  # $self->{next_char}
  
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
  $self->{token} = [];
  # $self->{escape}
} # _initialize_tokenizer

## A token has:
##   ->{type} == DOCTYPE_TOKEN, START_TAG_TOKEN, END_TAG_TOKEN, COMMENT_TOKEN,
##       CHARACTER_TOKEN, or END_OF_FILE_TOKEN
##   ->{name} (DOCTYPE_TOKEN)
##   ->{tag_name} (START_TAG_TOKEN, END_TAG_TOKEN)
##   ->{public_identifier} (DOCTYPE_TOKEN)
##   ->{system_identifier} (DOCTYPE_TOKEN)
##   ->{quirks} == 1 or 0 (DOCTYPE_TOKEN): "force-quirks" flag
##   ->{attributes} isa HASH (START_TAG_TOKEN, END_TAG_TOKEN)
##        ->{name}
##        ->{value}
##        ->{has_reference} == 1 or 0
##   ->{data} (COMMENT_TOKEN, CHARACTER_TOKEN)

## Emitted token MUST immediately be handled by the tree construction state.

## Before each step, UA MAY check to see if either one of the scripts in
## "list of scripts that will execute as soon as possible" or the first
## script in the "list of scripts that will execute asynchronously",
## has completed loading.  If one has, then it MUST be executed
## and removed from the list.

## NOTE: HTML5 "Writing HTML documents" section, applied to
## documents and not to user agents and conformance checkers,
## contains some requirements that are not detected by the
## parsing algorithm:
## - Some requirements on character encoding declarations. ## TODO
## - "Elements MUST NOT contain content that their content model disallows."
##   ... Some are parse error, some are not (will be reported by c.c.).
## - Polytheistic slash SHOULD NOT be used. (Applied only to atheists.) ## TODO
## - Text (in elements, attributes, and comments) SHOULD NOT contain
##   control characters other than space characters. ## TODO: (what is control character? C0, C1 and DEL?  Unicode control character?)

## TODO: HTML5 poses authors two SHOULD-level requirements that cannot
## be detected by the HTML5 parsing algorithm:
## - Text, 

sub _get_next_token ($) {
  my $self = shift;
  if (@{$self->{token}}) {
    return shift @{$self->{token}};
  }

  A: {
    if ($self->{state} == DATA_STATE) {
      if ($self->{next_char} == 0x0026) { # &
	if ($self->{content_model} & CM_ENTITY and # PCDATA | RCDATA
            not $self->{escape}) {
          
          $self->{state} = ENTITY_DATA_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } else {
          
          #
        }
      } elsif ($self->{next_char} == 0x002D) { # -
	if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
          unless ($self->{escape}) {
            if ($self->{prev_char}->[0] == 0x002D and # -
                $self->{prev_char}->[1] == 0x0021 and # !
                $self->{prev_char}->[2] == 0x003C) { # <
              
              $self->{escape} = 1;
            } else {
              
            }
          } else {
            
          }
        }
        
        #
      } elsif ($self->{next_char} == 0x003C) { # <
        if ($self->{content_model} & CM_FULL_MARKUP or # PCDATA
            (($self->{content_model} & CM_LIMITED_MARKUP) and # CDATA | RCDATA
             not $self->{escape})) {
          
          $self->{state} = TAG_OPEN_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } else {
          
          #
        }
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{escape} and
            ($self->{content_model} & CM_LIMITED_MARKUP)) { # RCDATA | CDATA
          if ($self->{prev_char}->[0] == 0x002D and # -
              $self->{prev_char}->[1] == 0x002D) { # -
            
            delete $self->{escape};
          } else {
            
          }
        } else {
          
        }
        
        #
      } elsif ($self->{next_char} == -1) {
        
        return  ({type => END_OF_FILE_TOKEN});
        last A; ## TODO: ok?
      } else {
        
      }
      # Anything else
      my $token = {type => CHARACTER_TOKEN,
                   data => chr $self->{next_char}};
      ## Stay in the data state
      
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

      return  ($token);

      redo A;
    } elsif ($self->{state} == ENTITY_DATA_STATE) {
      ## (cannot happen in CDATA state)
      
      my $token = $self->_tokenize_attempt_to_consume_an_entity (0, -1);

      $self->{state} = DATA_STATE;
      # next-input-character is already done

      unless (defined $token) {
        
        return  ({type => CHARACTER_TOKEN, data => '&'});
      } else {
        
        return  ($token);
      }

      redo A;
    } elsif ($self->{state} == TAG_OPEN_STATE) {
      if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
        if ($self->{next_char} == 0x002F) { # /
          
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          $self->{state} = CLOSE_TAG_OPEN_STATE;
          redo A;
        } else {
          
          ## reconsume
          $self->{state} = DATA_STATE;

          return  ({type => CHARACTER_TOKEN, data => '<'});

          redo A;
        }
      } elsif ($self->{content_model} & CM_FULL_MARKUP) { # PCDATA
        if ($self->{next_char} == 0x0021) { # !
          
          $self->{state} = MARKUP_DECLARATION_OPEN_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } elsif ($self->{next_char} == 0x002F) { # /
          
          $self->{state} = CLOSE_TAG_OPEN_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } elsif (0x0041 <= $self->{next_char} and
                 $self->{next_char} <= 0x005A) { # A..Z
          
          $self->{current_token}
            = {type => START_TAG_TOKEN,
               tag_name => chr ($self->{next_char} + 0x0020)};
          $self->{state} = TAG_NAME_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } elsif (0x0061 <= $self->{next_char} and
                 $self->{next_char} <= 0x007A) { # a..z
          
          $self->{current_token} = {type => START_TAG_TOKEN,
                            tag_name => chr ($self->{next_char})};
          $self->{state} = TAG_NAME_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } elsif ($self->{next_char} == 0x003E) { # >
          
          $self->{parse_error}-> (type => 'empty start tag');
          $self->{state} = DATA_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

          return  ({type => CHARACTER_TOKEN, data => '<>'});

          redo A;
        } elsif ($self->{next_char} == 0x003F) { # ?
          
          $self->{parse_error}-> (type => 'pio');
          $self->{state} = BOGUS_COMMENT_STATE;
          ## $self->{next_char} is intentionally left as is
          redo A;
        } else {
          
          $self->{parse_error}-> (type => 'bare stago');
          $self->{state} = DATA_STATE;
          ## reconsume

          return  ({type => CHARACTER_TOKEN, data => '<'});

          redo A;
        }
      } else {
        die "$0: $self->{content_model} in tag open";
      }
    } elsif ($self->{state} == CLOSE_TAG_OPEN_STATE) {
      if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
        if (defined $self->{last_emitted_start_tag_name}) {
          ## NOTE: <http://krijnhoetmer.nl/irc-logs/whatwg/20070626#l-564>
          my @next_char;
          TAGNAME: for (my $i = 0; $i < length $self->{last_emitted_start_tag_name}; $i++) {
            push @next_char, $self->{next_char};
            my $c = ord substr ($self->{last_emitted_start_tag_name}, $i, 1);
            my $C = 0x0061 <= $c && $c <= 0x007A ? $c - 0x0020 : $c;
            if ($self->{next_char} == $c or $self->{next_char} == $C) {
              
              
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
              next TAGNAME;
            } else {
              
              $self->{next_char} = shift @next_char; # reconsume
              unshift @{$self->{char}},  (@next_char);
              $self->{state} = DATA_STATE;

              return  ({type => CHARACTER_TOKEN, data => '</'});
  
              redo A;
            }
          }
          push @next_char, $self->{next_char};
      
          unless ($self->{next_char} == 0x0009 or # HT
                  $self->{next_char} == 0x000A or # LF
                  $self->{next_char} == 0x000B or # VT
                  $self->{next_char} == 0x000C or # FF
                  $self->{next_char} == 0x0020 or # SP 
                  $self->{next_char} == 0x003E or # >
                  $self->{next_char} == 0x002F or # /
                  $self->{next_char} == -1) {
            
            $self->{next_char} = shift @next_char; # reconsume
            unshift @{$self->{char}},  (@next_char);
            $self->{state} = DATA_STATE;
            return  ({type => CHARACTER_TOKEN, data => '</'});
            redo A;
          } else {
            
            $self->{next_char} = shift @next_char;
            unshift @{$self->{char}},  (@next_char);
            # and consume...
          }
        } else {
          ## No start tag token has ever been emitted
          
          # next-input-character is already done
          $self->{state} = DATA_STATE;
          return  ({type => CHARACTER_TOKEN, data => '</'});
          redo A;
        }
      }
      
      if (0x0041 <= $self->{next_char} and
          $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_token} = {type => END_TAG_TOKEN,
                          tag_name => chr ($self->{next_char} + 0x0020)};
        $self->{state} = TAG_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif (0x0061 <= $self->{next_char} and
               $self->{next_char} <= 0x007A) { # a..z
        
        $self->{current_token} = {type => END_TAG_TOKEN,
                          tag_name => chr ($self->{next_char})};
        $self->{state} = TAG_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'empty end tag');
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'bare etago');
        $self->{state} = DATA_STATE;
        # reconsume

        return  ({type => CHARACTER_TOKEN, data => '</'});

        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'bogus end tag');
        $self->{state} = BOGUS_COMMENT_STATE;
        ## $self->{next_char} is intentionally left as is
        redo A;
      }
    } elsif ($self->{state} == TAG_NAME_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          #if ($self->{current_token}->{attributes}) {
          #  ## NOTE: This should never be reached.
          #  !!! cp (36);
          #  !!! parse-error (type => 'end tag attribute');
          #} else {
            
          #}
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_token}->{tag_name} .= chr ($self->{next_char} + 0x0020);
          # start tag or end tag
        ## Stay in this state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          #if ($self->{current_token}->{attributes}) {
          #  ## NOTE: This state should never be reached.
          #  !!! cp (40);
          #  !!! parse-error (type => 'end tag attribute');
          #} else {
            
          #}
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x003E and # >
            $self->{current_token}->{type} == START_TAG_TOKEN and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          
          #
        } else {
          
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } else {
        
        $self->{current_token}->{tag_name} .= chr $self->{next_char};
          # start tag or end tag
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == BEFORE_ATTRIBUTE_NAME_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_attribute} = {name => chr ($self->{next_char} + 0x0020),
                              value => ''};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x003E and # >
            $self->{current_token}->{type} == START_TAG_TOKEN and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          
          #
        } else {
          
          $self->{parse_error}-> (type => 'nestc');
        }
        ## Stay in the state
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        if ({
             0x0022 => 1, # "
             0x0027 => 1, # '
             0x003D => 1, # =
            }->{$self->{next_char}}) {
          
          $self->{parse_error}-> (type => 'bad attribute name');
        } else {
          
        }
        $self->{current_attribute} = {name => chr ($self->{next_char}),
                              value => ''};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_NAME_STATE) {
      my $before_leave = sub {
        if (exists $self->{current_token}->{attributes} # start tag or end tag
            ->{$self->{current_attribute}->{name}}) { # MUST
          
          $self->{parse_error}-> (type => 'duplicate attribute:'.$self->{current_attribute}->{name});
          ## Discard $self->{current_attribute} # MUST
        } else {
          
          $self->{current_token}->{attributes}->{$self->{current_attribute}->{name}}
            = $self->{current_attribute};
        }
      }; # $before_leave

      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $before_leave->();
        $self->{state} = AFTER_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003D) { # =
        
        $before_leave->();
        $self->{state} = BEFORE_ATTRIBUTE_VALUE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        $before_leave->();
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}-> (type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_attribute}->{name} .= chr ($self->{next_char} + 0x0020);
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        $before_leave->();
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x003E and # >
            $self->{current_token}->{type} == START_TAG_TOKEN and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          
          #
        } else {
          
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        $before_leave->();
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        if ($self->{next_char} == 0x0022 or # "
            $self->{next_char} == 0x0027) { # '
          
          $self->{parse_error}-> (type => 'bad attribute name');
        } else {
          
        }
        $self->{current_attribute}->{name} .= chr ($self->{next_char});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == AFTER_ATTRIBUTE_NAME_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003D) { # =
        
        $self->{state} = BEFORE_ATTRIBUTE_VALUE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_attribute} = {name => chr ($self->{next_char} + 0x0020),
                              value => ''};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x003E and # >
            $self->{current_token}->{type} == START_TAG_TOKEN and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          
          #
        } else {
          
          $self->{parse_error}-> (type => 'nestc');
          ## TODO: Different error type for <aa / bb> than <aa/>
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        
        $self->{current_attribute} = {name => chr ($self->{next_char}),
                              value => ''};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;        
      }
    } elsif ($self->{state} == BEFORE_ATTRIBUTE_VALUE_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP      
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        ## reconsume
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        if ($self->{next_char} == 0x003D) { # =
          
          $self->{parse_error}-> (type => 'bad attribute value');
        } else {
          
        }
        $self->{current_attribute}->{value} .= chr ($self->{next_char});
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        $self->{last_attribute_value_state} = $self->{state};
        $self->{state} = ENTITY_IN_ATTRIBUTE_VALUE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed attribute value');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        
        $self->{current_attribute}->{value} .= chr ($self->{next_char});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        $self->{last_attribute_value_state} = $self->{state};
        $self->{state} = ENTITY_IN_ATTRIBUTE_VALUE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed attribute value');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        
        $self->{current_attribute}->{value} .= chr ($self->{next_char});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_VALUE_UNQUOTED_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # HT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        $self->{last_attribute_value_state} = $self->{state};
        $self->{state} = ENTITY_IN_ATTRIBUTE_VALUE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        if ({
             0x0022 => 1, # "
             0x0027 => 1, # '
             0x003D => 1, # =
            }->{$self->{next_char}}) {
          
          $self->{parse_error}-> (type => 'bad attribute value');
        } else {
          
        }
        $self->{current_attribute}->{value} .= chr ($self->{next_char});
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == ENTITY_IN_ATTRIBUTE_VALUE_STATE) {
      my $token = $self->_tokenize_attempt_to_consume_an_entity
          (1,
           $self->{last_attribute_value_state}
             == ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE ? 0x0022 : # "
           $self->{last_attribute_value_state}
             == ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE ? 0x0027 : # '
           -1);

      unless (defined $token) {
        
        $self->{current_attribute}->{value} .= '&';
      } else {
        
        $self->{current_attribute}->{value} .= $token->{data};
	$self->{current_attribute}->{has_reference} = $token->{has_reference};
        ## ISSUE: spec says "append the returned character token to the current attribute's value"
      }

      $self->{state} = $self->{last_attribute_value_state};
      # next-input-character is already done
      redo A;
    } elsif ($self->{state} == AFTER_ATTRIBUTE_VALUE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x003E and # >
            $self->{current_token}->{type} == START_TAG_TOKEN and
            $permitted_slash_tag_name->{$self->{current_token}->{tag_name}}) {
          # permitted slash
          
          #
        } else {
          
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'no space between attributes');
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        ## reconsume
        redo A;
      }
    } elsif ($self->{state} == BOGUS_COMMENT_STATE) {
      ## (only happen if PCDATA state)
      
      my $token = {type => COMMENT_TOKEN, data => ''};

      BC: {
        if ($self->{next_char} == 0x003E) { # >
          
          $self->{state} = DATA_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

          return  ($token);

          redo A;
        } elsif ($self->{next_char} == -1) { 
          
          $self->{state} = DATA_STATE;
          ## reconsume

          return  ($token);

          redo A;
        } else {
          
          $token->{data} .= chr ($self->{next_char});
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo BC;
        }
      } # BC

      die "$0: _get_next_token: unexpected case [BC]";
    } elsif ($self->{state} == MARKUP_DECLARATION_OPEN_STATE) {
      ## (only happen if PCDATA state)

      my @next_char;
      push @next_char, $self->{next_char};
      
      if ($self->{next_char} == 0x002D) { # -
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        push @next_char, $self->{next_char};
        if ($self->{next_char} == 0x002D) { # -
          
          $self->{current_token} = {type => COMMENT_TOKEN, data => ''};
          $self->{state} = COMMENT_START_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } else {
          
        }
      } elsif ($self->{next_char} == 0x0044 or # D
               $self->{next_char} == 0x0064) { # d
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        push @next_char, $self->{next_char};
        if ($self->{next_char} == 0x004F or # O
            $self->{next_char} == 0x006F) { # o
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          push @next_char, $self->{next_char};
          if ($self->{next_char} == 0x0043 or # C
              $self->{next_char} == 0x0063) { # c
            
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
            push @next_char, $self->{next_char};
            if ($self->{next_char} == 0x0054 or # T
                $self->{next_char} == 0x0074) { # t
              
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
              push @next_char, $self->{next_char};
              if ($self->{next_char} == 0x0059 or # Y
                  $self->{next_char} == 0x0079) { # y
                
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                push @next_char, $self->{next_char};
                if ($self->{next_char} == 0x0050 or # P
                    $self->{next_char} == 0x0070) { # p
                  
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                  push @next_char, $self->{next_char};
                  if ($self->{next_char} == 0x0045 or # E
                      $self->{next_char} == 0x0065) { # e
                    
                    ## TODO: What a stupid code this is!
                    $self->{state} = DOCTYPE_STATE;
                    
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                    redo A;
                  } else {
                    
                  }
                } else {
                  
                }
              } else {
                
              }
            } else {
              
            }
          } else {
            
          }
        } else {
          
        }
      } else {
        
      }

      $self->{parse_error}-> (type => 'bogus comment');
      $self->{next_char} = shift @next_char;
      unshift @{$self->{char}},  (@next_char);
      $self->{state} = BOGUS_COMMENT_STATE;
      redo A;
      
      ## ISSUE: typos in spec: chacacters, is is a parse error
      ## ISSUE: spec is somewhat unclear on "is the first character that will be in the comment"; what is "that will be in the comment" is what the algorithm defines, isn't it?
    } elsif ($self->{state} == COMMENT_START_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_START_DASH_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'bogus comment');
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} # comment
            .= chr ($self->{next_char});
        $self->{state} = COMMENT_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_START_DASH_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_END_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'bogus comment');
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} # comment
            .= '-' . chr ($self->{next_char});
        $self->{state} = COMMENT_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_END_DASH_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} .= chr ($self->{next_char}); # comment
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_END_DASH_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_END_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} .= '-' . chr ($self->{next_char}); # comment
        $self->{state} = COMMENT_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_END_STATE) {
      if ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == 0x002D) { # -
        
        $self->{parse_error}-> (type => 'dash in comment');
        $self->{current_token}->{data} .= '-'; # comment
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'dash in comment');
        $self->{current_token}->{data} .= '--' . chr ($self->{next_char}); # comment
        $self->{state} = COMMENT_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } 
    } elsif ($self->{state} == DOCTYPE_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = BEFORE_DOCTYPE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'no space before DOCTYPE name');
        $self->{state} = BEFORE_DOCTYPE_NAME_STATE;
        ## reconsume
        redo A;
      }
    } elsif ($self->{state} == BEFORE_DOCTYPE_NAME_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ({type => DOCTYPE_TOKEN, quirks => 1});

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ({type => DOCTYPE_TOKEN, quirks => 1});

        redo A;
      } else {
        
        $self->{current_token}
            = {type => DOCTYPE_TOKEN,
               name => chr ($self->{next_char}),
               #quirks => 0,
              };
## ISSUE: "Set the token's name name to the" in the spec
        $self->{state} = DOCTYPE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_NAME_STATE) {
## ISSUE: Redundant "First," in the spec.
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = AFTER_DOCTYPE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{name}
          .= chr ($self->{next_char}); # DOCTYPE
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == AFTER_DOCTYPE_NAME_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == 0x0050 or # P
               $self->{next_char} == 0x0070) { # p
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x0055 or # U
            $self->{next_char} == 0x0075) { # u
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          if ($self->{next_char} == 0x0042 or # B
              $self->{next_char} == 0x0062) { # b
            
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
            if ($self->{next_char} == 0x004C or # L
                $self->{next_char} == 0x006C) { # l
              
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
              if ($self->{next_char} == 0x0049 or # I
                  $self->{next_char} == 0x0069) { # i
                
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                if ($self->{next_char} == 0x0043 or # C
                    $self->{next_char} == 0x0063) { # c
                  
                  $self->{state} = BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
                  
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                  redo A;
                } else {
                  
                }
              } else {
                
              }
            } else {
              
            }
          } else {
            
          }
        } else {
          
        }

        #
      } elsif ($self->{next_char} == 0x0053 or # S
               $self->{next_char} == 0x0073) { # s
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if ($self->{next_char} == 0x0059 or # Y
            $self->{next_char} == 0x0079) { # y
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          if ($self->{next_char} == 0x0053 or # S
              $self->{next_char} == 0x0073) { # s
            
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
            if ($self->{next_char} == 0x0054 or # T
                $self->{next_char} == 0x0074) { # t
              
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
              if ($self->{next_char} == 0x0045 or # E
                  $self->{next_char} == 0x0065) { # e
                
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                if ($self->{next_char} == 0x004D or # M
                    $self->{next_char} == 0x006D) { # m
                  
                  $self->{state} = BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
                  
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                  redo A;
                } else {
                  
                }
              } else {
                
              }
            } else {
              
            }
          } else {
            
          }
        } else {
          
        }

        #
      } else {
        
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        #
      }

      $self->{parse_error}-> (type => 'string after DOCTYPE name');
      $self->{current_token}->{quirks} = 1;

      $self->{state} = BOGUS_DOCTYPE_STATE;
      # next-input-character is already done
      redo A;
    } elsif ($self->{state} == BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE) {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_char}}) {
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} eq 0x0022) { # "
        
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} eq 0x0027) { # '
        
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} eq 0x003E) { # >
        
        $self->{parse_error}-> (type => 'no PUBLIC literal');

        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'string after PUBLIC');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{public_identifier} # DOCTYPE
            .= chr $self->{next_char};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{public_identifier} # DOCTYPE
            .= chr $self->{next_char};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE) {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_char}}) {
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'string after PUBLIC literal');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE) {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_char}}) {
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'no SYSTEM literal');
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'string after SYSTEM');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{system_identifier} # DOCTYPE
            .= chr $self->{next_char};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{system_identifier} # DOCTYPE
            .= chr $self->{next_char};
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE) {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_char}}) {
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}-> (type => 'string after SYSTEM literal');
        #$self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } elsif ($self->{state} == BOGUS_DOCTYPE_STATE) {
      if ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      }
    } else {
      die "$0: $self->{state}: Unknown state";
    }
  } # A   

  die "$0: _get_next_token: unexpected case";
} # _get_next_token

sub _tokenize_attempt_to_consume_an_entity ($$$) {
  my ($self, $in_attr, $additional) = @_;

  if ({
       0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, # HT, LF, VT, FF,
       0x0020 => 1, 0x003C => 1, 0x0026 => 1, -1 => 1, # SP, <, & # 0x000D # CR
       $additional => 1,
      }->{$self->{next_char}}) {
    
    ## Don't consume
    ## No error
    return undef;
  } elsif ($self->{next_char} == 0x0023) { # #
    
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
    if ($self->{next_char} == 0x0078 or # x
        $self->{next_char} == 0x0058) { # X
      my $code;
      X: {
        my $x_char = $self->{next_char};
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        if (0x0030 <= $self->{next_char} and 
            $self->{next_char} <= 0x0039) { # 0..9
          
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_char} - 0x0030;
          redo X;
        } elsif (0x0061 <= $self->{next_char} and
                 $self->{next_char} <= 0x0066) { # a..f
          
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_char} - 0x0060 + 9;
          redo X;
        } elsif (0x0041 <= $self->{next_char} and
                 $self->{next_char} <= 0x0046) { # A..F
          
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_char} - 0x0040 + 9;
          redo X;
        } elsif (not defined $code) { # no hexadecimal digit
          
          $self->{parse_error}-> (type => 'bare hcro');
          unshift @{$self->{char}},  ($x_char, $self->{next_char});
          $self->{next_char} = 0x0023; # #
          return undef;
        } elsif ($self->{next_char} == 0x003B) { # ;
          
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
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
          
          $self->{parse_error}-> (type => sprintf 'C1 character reference:U+%04X', $code);
          $code = $c1_entity_char->{$code};
        }

        return {type => CHARACTER_TOKEN, data => chr $code,
                has_reference => 1};
      } # X
    } elsif (0x0030 <= $self->{next_char} and
             $self->{next_char} <= 0x0039) { # 0..9
      my $code = $self->{next_char} - 0x0030;
      
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
      
      while (0x0030 <= $self->{next_char} and 
                $self->{next_char} <= 0x0039) { # 0..9
        
        $code *= 10;
        $code += $self->{next_char} - 0x0030;
        
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
      }

      if ($self->{next_char} == 0x003B) { # ;
        
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
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
        
        $self->{parse_error}-> (type => sprintf 'C1 character reference:U+%04X', $code);
        $code = $c1_entity_char->{$code};
      }
      
      return {type => CHARACTER_TOKEN, data => chr $code, has_reference => 1};
    } else {
      
      $self->{parse_error}-> (type => 'bare nero');
      unshift @{$self->{char}},  ($self->{next_char});
      $self->{next_char} = 0x0023; # #
      return undef;
    }
  } elsif ((0x0041 <= $self->{next_char} and
            $self->{next_char} <= 0x005A) or
           (0x0061 <= $self->{next_char} and
            $self->{next_char} <= 0x007A)) {
    my $entity_name = chr $self->{next_char};
    
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

    my $value = $entity_name;
    my $match = 0;
    require Whatpm::_NamedEntityList;
    our $EntityChar;

    while (length $entity_name < 10 and
           ## NOTE: Some number greater than the maximum length of entity name
           ((0x0041 <= $self->{next_char} and # a
             $self->{next_char} <= 0x005A) or # x
            (0x0061 <= $self->{next_char} and # a
             $self->{next_char} <= 0x007A) or # z
            (0x0030 <= $self->{next_char} and # 0
             $self->{next_char} <= 0x0039) or # 9
            $self->{next_char} == 0x003B)) { # ;
      $entity_name .= chr $self->{next_char};
      if (defined $EntityChar->{$entity_name}) {
        if ($self->{next_char} == 0x003B) { # ;
          
          $value = $EntityChar->{$entity_name};
          $match = 1;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          last;
        } else {
          
          $value = $EntityChar->{$entity_name};
          $match = -1;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        }
      } else {
        
        $value .= chr $self->{next_char};
        $match *= 2;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
      }
    }
    
    if ($match > 0) {
      
      return {type => CHARACTER_TOKEN, data => $value, has_reference => 1};
    } elsif ($match < 0) {
      $self->{parse_error}-> (type => 'no refc');
      if ($in_attr and $match < -1) {
        
        return {type => CHARACTER_TOKEN, data => '&'.$entity_name};
      } else {
        
        return {type => CHARACTER_TOKEN, data => $value, has_reference => 1};
      }
    } else {
      
      $self->{parse_error}-> (type => 'bare ero');
      ## NOTE: "No characters are consumed" in the spec.
      return {type => CHARACTER_TOKEN, data => '&'.$value};
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

  undef $self->{form_element};
  undef $self->{head_element};
  $self->{open_elements} = [];
  undef $self->{inner_html_node};

  ## NOTE: The "initial" insertion mode.
  $self->_tree_construction_initial; # MUST

  ## NOTE: The "before html" insertion mode.
  $self->_tree_construction_root_element;
  $self->{insertion_mode} = BEFORE_HEAD_IM;

  ## NOTE: The "before head" insertion mode and so on.
  $self->_tree_construction_main;
} # _construct_tree

sub _tree_construction_initial ($) {
  my $self = shift;

  ## NOTE: "initial" insertion mode

  INITIAL: {
    if ($token->{type} == DOCTYPE_TOKEN) {
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
      } else {
        
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
      
      if ($token->{quirks} or $doctype_name ne 'HTML') {
        
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
          "-//O'REILLY AND ASSOCIATES//DTD HTML EXTENDED RELAXED 1.0//EN" => 1,
          "-//SOFTQUAD SOFTWARE//DTD HOTMETAL PRO 6.0::19990601::EXTENSIONS TO HTML 4.0//EN" => 1,
          "-//SOFTQUAD//DTD HOTMETAL PRO 4.0::19971010::EXTENSIONS TO HTML 4.0//EN" => 1,
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
        } elsif ($pubid eq "-//W3C//DTD XHTML 1.0 FRAMESET//EN" or
                 $pubid eq "-//W3C//DTD XHTML 1.0 TRANSITIONAL//EN") {
          
          $self->{document}->manakai_compat_mode ('limited quirks');
        } else {
          
        }
      } else {
        
      }
      if (defined $token->{system_identifier}) {
        my $sysid = $token->{system_identifier};
        $sysid =~ tr/A-Z/a-z/;
        if ($sysid eq "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd") {
          ## TODO: Check the spec: PUBLIC "(limited quirks)" "(quirks)"
          $self->{document}->manakai_compat_mode ('quirks');
          
        } else {
          
        }
      } else {
        
      }
      
      ## Go to the "before html" insertion mode.
      $token = $self->_get_next_token;
      return;
    } elsif ({
              START_TAG_TOKEN, 1,
              END_TAG_TOKEN, 1,
              END_OF_FILE_TOKEN, 1,
             }->{$token->{type}}) {
      
      $self->{parse_error}-> (type => 'no DOCTYPE');
      $self->{document}->manakai_compat_mode ('quirks');
      ## Go to the "before html" insertion mode.
      ## reprocess
      return;
    } elsif ($token->{type} == CHARACTER_TOKEN) {
      if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) { # \x0D
        ## Ignore the token

        unless (length $token->{data}) {
          
          ## Stay in the insertion mode.
          $token = $self->_get_next_token;
          redo INITIAL;
        } else {
          
        }
      } else {
        
      }

      $self->{parse_error}-> (type => 'no DOCTYPE');
      $self->{document}->manakai_compat_mode ('quirks');
      ## Go to the "before html" insertion mode.
      ## reprocess
      return;
    } elsif ($token->{type} == COMMENT_TOKEN) {
      
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the insertion mode.
      $token = $self->_get_next_token;
      redo INITIAL;
    } else {
      die "$0: $token->{type}: Unknown token type";
    }
  } # INITIAL

  die "$0: _tree_construction_initial: This should be never reached";
} # _tree_construction_initial

sub _tree_construction_root_element ($) {
  my $self = shift;

  ## NOTE: "before html" insertion mode.
  
  B: {
      if ($token->{type} == DOCTYPE_TOKEN) {
        
        $self->{parse_error}-> (type => 'in html:#DOCTYPE');
        ## Ignore the token
        ## Stay in the insertion mode.
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} == COMMENT_TOKEN) {
        
        my $comment = $self->{document}->create_comment ($token->{data});
        $self->{document}->append_child ($comment);
        ## Stay in the insertion mode.
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) { # \x0D
          ## Ignore the token.

          unless (length $token->{data}) {
            
            ## Stay in the insertion mode.
            $token = $self->_get_next_token;
            redo B;
          } else {
            
          }
        } else {
          
        }

        $self->{application_cache_selection}->(undef);

        #
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($token->{tag_name} eq 'html') {
          my $root_element;
          
      $root_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $root_element->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
          $self->{document}->append_child ($root_element);
          push @{$self->{open_elements}}, [$root_element, 'html'];

          if ($token->{attributes}->{manifest}) {
            
            $self->{application_cache_selection}
                ->($token->{attributes}->{manifest}->{value});
            ## ISSUE: No relative reference resolution?
          } else {
            
            $self->{application_cache_selection}->(undef);
          }

          $token = $self->_get_next_token;
          return; ## Go to the "before head" insertion mode.
        } else {
          
          #
        }
      } elsif ({
                END_TAG_TOKEN, 1,
                END_OF_FILE_TOKEN, 1,
               }->{$token->{type}}) {
        
        #
      } else {
        die "$0: $token->{type}: Unknown token type";
      }

    my $root_element; 
      $root_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'html']);
    
    $self->{document}->append_child ($root_element);
    push @{$self->{open_elements}}, [$root_element, 'html'];

    $self->{application_cache_selection}->(undef);

    ## NOTE: Reprocess the token.
    return; ## Go to the "before head" insertion mode.

    ## ISSUE: There is an issue in the spec
  } # B

  die "$0: _tree_construction_root_element: This should never be reached";
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
      ## ISSUE: Oops! "If node is the first node in the stack of open
      ## elements, then set last to true. If the context element of the
      ## HTML fragment parsing algorithm is neither a td element nor a
      ## th element, then set node to the context element. (fragment case)":
      ## The second "if" is in the scope of the first "if"!?
      if ($self->{open_elements}->[0]->[0] eq $node->[0]) {
        $last = 1;
        if (defined $self->{inner_html_node}) {
          if ($self->{inner_html_node}->[1] eq 'td' or
              $self->{inner_html_node}->[1] eq 'th') {
            
            #
          } else {
            
            $node = $self->{inner_html_node};
          }
        }
      }
    
      ## Step 4..13
      my $new_mode = {
                      select => IN_SELECT_IM,
                      ## NOTE: |option| and |optgroup| do not set
                      ## insertion mode to "in select" by themselves.
                      td => IN_CELL_IM,
                      th => IN_CELL_IM,
                      tr => IN_ROW_IM,
                      tbody => IN_TABLE_BODY_IM,
                      thead => IN_TABLE_BODY_IM,
                      tfoot => IN_TABLE_BODY_IM,
                      caption => IN_CAPTION_IM,
                      colgroup => IN_COLUMN_GROUP_IM,
                      table => IN_TABLE_IM,
                      head => IN_BODY_IM, # not in head!
                      body => IN_BODY_IM,
                      frameset => IN_FRAMESET_IM,
                     }->{$node->[1]};
      $self->{insertion_mode} = $new_mode and return if defined $new_mode;
      
      ## Step 14
      if ($node->[1] eq 'html') {
        unless (defined $self->{head_element}) {
          
          $self->{insertion_mode} = BEFORE_HEAD_IM;
        } else {
          ## ISSUE: Can this state be reached?
          
          $self->{insertion_mode} = AFTER_HEAD_IM;
        }
        return;
      } else {
        
      }
      
      ## Step 15
      $self->{insertion_mode} = IN_BODY_IM and return if $last;
      
      ## Step 16
      $i--;
      $node = $self->{open_elements}->[$i];
      
      ## Step 17
      redo S3;
    } # S3

  die "$0: _reset_insertion_mode: This line should never be reached";
} # _reset_insertion_mode

sub _tree_construction_main ($) {
  my $self = shift;

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
          ## NOTE: <!DOCTYPE HTML><p><b><i><u></p> <p>X
          
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
    $self->{content_model} = $content_model_flag; # CDATA or RCDATA
    delete $self->{escape}; # MUST

    ## Step 4
    my $text = '';
    $token = $self->_get_next_token;
    while ($token->{type} == CHARACTER_TOKEN) { # or until stop tokenizing
      
      $text .= $token->{data};
      $token = $self->_get_next_token;
    }

    ## Step 5
    if (length $text) {
      
      my $text = $self->{document}->create_text_node ($text);
      $el->append_child ($text);
    }

    ## Step 6
    $self->{content_model} = PCDATA_CONTENT_MODEL;

    ## Step 7
    if ($token->{type} == END_TAG_TOKEN and
        $token->{tag_name} eq $start_tag_name) {
      
      ## Ignore the token
    } elsif ($content_model_flag == CDATA_CONTENT_MODEL) {
      
      $self->{parse_error}-> (type => 'in CDATA:#'.$token->{type});
    } elsif ($content_model_flag == RCDATA_CONTENT_MODEL) {
      
      $self->{parse_error}-> (type => 'in RCDATA:#'.$token->{type});
    } else {
      die "$0: $content_model_flag in parse_rcdata";
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

    $self->{content_model} = CDATA_CONTENT_MODEL;
    delete $self->{escape}; # MUST
    
    my $text = '';
    $token = $self->_get_next_token;
    while ($token->{type} == CHARACTER_TOKEN) {
      
      $text .= $token->{data};
      $token = $self->_get_next_token;
    } # stop if non-character token or tokenizer stops tokenising
    if (length $text) {
      
      $script_el->manakai_append_text ($text);
    }
              
    $self->{content_model} = PCDATA_CONTENT_MODEL;

    if ($token->{type} == END_TAG_TOKEN and
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

  my $insert;

  B: {
    if ($token->{type} == DOCTYPE_TOKEN) {
      
      $self->{parse_error}-> (type => 'DOCTYPE in the middle');
      ## Ignore the token
      ## Stay in the phase
      $token = $self->_get_next_token;
      redo B;
    } elsif ($token->{type} == END_OF_FILE_TOKEN) {
      if ($self->{insertion_mode} & AFTER_HTML_IMS) {
        
        #
      } else {
        ## Generate implied end tags
        while ({
                dd => 1, dt => 1, li => 1, p => 1,
               }->{$self->{open_elements}->[-1]->[1]}) {
          
          pop @{$self->{open_elements}};
        }
        
        if (@{$self->{open_elements}} > 2 or
            (@{$self->{open_elements}} == 2 and $self->{open_elements}->[1]->[1] ne 'body')) {
          
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        } elsif (defined $self->{inner_html_node} and
                 @{$self->{open_elements}} > 1 and
                 $self->{open_elements}->[1]->[1] ne 'body') {
## ISSUE: This case is never reached.
          
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        } else {
          
        }

        ## ISSUE: There is an issue in the spec.
      }

      ## Stop parsing
      last B;
    } elsif ($token->{type} == START_TAG_TOKEN and
             $token->{tag_name} eq 'html') {
      if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
        
        $self->{parse_error}-> (type => 'after html:html');
        $self->{insertion_mode} = AFTER_BODY_IM;
      } elsif ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
        
        $self->{parse_error}-> (type => 'after html:html');
        $self->{insertion_mode} = AFTER_FRAMESET_IM;
      } else {
        
      }

      
      $self->{parse_error}-> (type => 'not first start tag');
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
    } elsif ($token->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($token->{data});
      if ($self->{insertion_mode} & AFTER_HTML_IMS) {
        
        $self->{document}->append_child ($comment);
      } elsif ($self->{insertion_mode} == AFTER_BODY_IM) {
        
        $self->{open_elements}->[0]->[0]->append_child ($comment);
      } else {
        
        $self->{open_elements}->[-1]->[0]->append_child ($comment);
      }
      $token = $self->_get_next_token;
      redo B;
    } elsif ($self->{insertion_mode} & HEAD_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
            redo B;
          }
        }

        if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          
          ## As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
          $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
          push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

          ## Reprocess in the "in head" insertion mode...
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
          
          ## As if </noscript>
          pop @{$self->{open_elements}};
          $self->{parse_error}-> (type => 'in noscript:#character');
          
          ## Reprocess in the "in head" insertion mode...
          ## As if </head>
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
          
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } else {
          
        }

            ## "after head" insertion mode
            ## As if <body>
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'body'];
    }
  
            $self->{insertion_mode} = IN_BODY_IM;
            ## reprocess
            redo B;
          } elsif ($token->{type} == START_TAG_TOKEN) {
            if ($token->{tag_name} eq 'head') {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          $self->{head_element}->set_attribute_ns (undef, [undef, $attr_name],
                                 $token->{attributes} ->{$attr_name}->{value});
        }
      
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}}, [$self->{head_element}, $token->{tag_name}];
                $self->{insertion_mode} = IN_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                #
              } else {
                
                $self->{parse_error}-> (type => 'in head:head'); # or in head noscript
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
            } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
              
              ## As if <head>
              
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
              $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
              push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

              $self->{insertion_mode} = IN_HEAD_IM;
              ## Reprocess in the "in head" insertion mode...
            } else {
              
            }

            if ($token->{tag_name} eq 'base') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:base');
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } else {
                
              }

              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
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
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'link') {
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
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
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'meta') {
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
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
  
              my $meta_el = pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.

              unless ($self->{confident}) {
                if ($token->{attributes}->{charset}) { ## TODO: And if supported
                  
                  $self->{change_encoding}
                      ->($self, $token->{attributes}->{charset}->{value});
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                      ->set_user_data (manakai_has_reference =>
                                           $token->{attributes}->{charset}
                                               ->{has_reference});
                } elsif ($token->{attributes}->{content}) {
                  ## ISSUE: Algorithm name in the spec was incorrect so that not linked to the definition.
                  if ($token->{attributes}->{content}->{value}
                      =~ /\A[^;]*;[\x09-\x0D\x20]*[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                          [\x09-\x0D\x20]*=
                          [\x09-\x0D\x20]*(?>"([^"]*)"|'([^']*)'|
                          ([^"'\x09-\x0D\x20][^\x09-\x0D\x20]*))/x) {
                    
                    $self->{change_encoding}
                        ->($self, defined $1 ? $1 : defined $2 ? $2 : $3);
                    $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                        ->set_user_data (manakai_has_reference =>
                                             $token->{attributes}->{content}
                                                   ->{has_reference});
                  } else {
                    
                  }
                }
              } else {
                if ($token->{attributes}->{charset}) {
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                      ->set_user_data (manakai_has_reference =>
                                           $token->{attributes}->{charset}
                                               ->{has_reference});
                }
                if ($token->{attributes}->{content}) {
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                      ->set_user_data (manakai_has_reference =>
                                           $token->{attributes}->{content}
                                               ->{has_reference});
                }
              }

              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'title') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:title');
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
              }

              ## NOTE: There is a "as if in head" code clone.
              my $parent = defined $self->{head_element} ? $self->{head_element}
                  : $self->{open_elements}->[-1]->[0];
              $parse_rcdata->(RCDATA_CONTENT_MODEL,
                              sub { $parent->append_child ($_[0]) });
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              redo B;
            } elsif ($token->{tag_name} eq 'style') {
              ## NOTE: Or (scripting is enabled and tag_name eq 'noscript' and
              ## insertion mode IN_HEAD_IM)
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
              }
              $parse_rcdata->(CDATA_CONTENT_MODEL, $insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              redo B;
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_IM) {
                
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
  
                $self->{insertion_mode} = IN_HEAD_NOSCRIPT_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                $self->{parse_error}-> (type => 'in noscript:noscript');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                #
              }
            } elsif ($token->{tag_name} eq 'script') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:script');
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
              }

              ## NOTE: There is a "as if in head" code clone.
              $script_start_tag->($insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              redo B;
            } elsif ($token->{tag_name} eq 'body' or
                     $token->{tag_name} eq 'frameset') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:'.$token->{tag_name});
                
                ## Reprocess in the "in head" insertion mode...
                ## As if </head>
                pop @{$self->{open_elements}};
                
                ## Reprocess in the "after head" insertion mode...
              } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
                
                pop @{$self->{open_elements}};
                
                ## Reprocess in the "after head" insertion mode...
              } else {
                
              }

              ## "after head" insertion mode
              
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
  
              if ($token->{tag_name} eq 'body') {
                
                $self->{insertion_mode} = IN_BODY_IM;
              } elsif ($token->{tag_name} eq 'frameset') {
                
                $self->{insertion_mode} = IN_FRAMESET_IM;
              } else {
                die "$0: tag name: $self->{tag_name}";
              }
              $token = $self->_get_next_token;
              redo B;
            } else {
              
              #
            }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}-> (type => 'in noscript:/'.$token->{tag_name});
              
              ## Reprocess in the "in head" insertion mode...
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
              
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } else {
              
            }

            ## "after head" insertion mode
            ## As if <body>
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'body'];
    }
  
            $self->{insertion_mode} = IN_BODY_IM;
            ## reprocess
            redo B;
          } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'head') {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                ## As if <head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

                ## Reprocess in the "in head" insertion mode...
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:/head');
                
                ## Reprocess in the "in head" insertion mode...
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
                
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                #
              }
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = IN_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                $self->{parse_error}-> (type => 'unmatched end tag:noscript');
                ## Ignore the token ## ISSUE: An issue in the spec.
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                #
              }
            } elsif ({
                      body => 1, html => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                ## As if <head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
              }
               
              #
            } elsif ({
                      p => 1, br => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                ## As if <head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } else {
                
              }

              #
            } else {
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                #
              } else {
                
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
            }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}-> (type => 'in noscript:/'.$token->{tag_name});
              
              ## Reprocess in the "in head" insertion mode...
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
              
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
## ISSUE: This case cannot be reached?
              
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token ## ISSUE: An issue in the spec.
              $token = $self->_get_next_token;
              redo B;
            } else {
              
            }

            ## "after head" insertion mode
            ## As if <body>
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'body']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'body'];
    }
  
            $self->{insertion_mode} = IN_BODY_IM;
            ## reprocess
            redo B;
          } else {
            die "$0: $token->{type}: Unknown token type";
          }

          ## ISSUE: An issue in the spec.
    } elsif ($self->{insertion_mode} & BODY_IMS) {
          if ($token->{type} == CHARACTER_TOKEN) {
            
            ## NOTE: There is a code clone of "character in body".
            $reconstruct_active_formatting_elements->($insert_to_current);
            
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});

            $token = $self->_get_next_token;
            redo B;
          } elsif ($token->{type} == START_TAG_TOKEN) {
            if ({
                 caption => 1, col => 1, colgroup => 1, tbody => 1,
                 td => 1, tfoot => 1, th => 1, thead => 1, tr => 1,
                }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == IN_CELL_IM) {
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
                    
## TODO: This error type is wrong.
                    $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    redo B;
                  }
                
                
                ## Close the cell
                unshift @{$self->{token}}, $token; # <?>
                $token = {type => END_TAG_TOKEN, tag_name => $tn};
                redo B;
              } elsif ($self->{insertion_mode} == IN_CAPTION_IM) {
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
                    
## TODO: this type is wrong.
                    $self->{parse_error}-> (type => 'unmatched end tag:caption');
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    redo B;
                  }
                
                ## generate implied end tags
                while ({
                        dd => 1, dt => 1, li => 1, p => 1,
                       }->{$self->{open_elements}->[-1]->[1]}) {
                  
                  pop @{$self->{open_elements}};
                }

                if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                  
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                ## reprocess
                redo B;
              } else {
                
                #
              }
            } else {
              
              #
            }
          } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'td' or $token->{tag_name} eq 'th') {
              if ($self->{insertion_mode} == IN_CELL_IM) {
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
                while ({
                        dd => 1, dt => 1, li => 1, p => 1,
                       }->{$self->{open_elements}->[-1]->[1]}) {
                  
                  pop @{$self->{open_elements}};
                }

                if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
                  
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_ROW_IM;
                
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_CAPTION_IM) {
                
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                #
              }
            } elsif ($token->{tag_name} eq 'caption') {
              if ($self->{insertion_mode} == IN_CAPTION_IM) {
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
                while ({
                        dd => 1, dt => 1, li => 1, p => 1,
                       }->{$self->{open_elements}->[-1]->[1]}) {
                  
                  pop @{$self->{open_elements}};
                }
                
                if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                  
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_CELL_IM) {
                
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                #
              }
            } elsif ({
                      table => 1, tbody => 1, tfoot => 1, 
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}} and
                     $self->{insertion_mode} == IN_CELL_IM) {
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
              } else {
                
              }

              ## Close the cell
              unshift @{$self->{token}}, $token; # </?>
              $token = {type => END_TAG_TOKEN, tag_name => $tn};
              redo B;
            } elsif ($token->{tag_name} eq 'table' and
                     $self->{insertion_mode} == IN_CAPTION_IM) {
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
              while ({
                      dd => 1, dt => 1, li => 1, p => 1,
                     }->{$self->{open_elements}->[-1]->[1]}) {
                
                pop @{$self->{open_elements}};
              }

              if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              } else {
                
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->();

              $self->{insertion_mode} = IN_TABLE_IM;

              ## reprocess
              redo B;
            } elsif ({
                      body => 1, col => 1, colgroup => 1, html => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} & BODY_TABLE_IMS) {
                
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                #
              }
            } elsif ({
                      tbody => 1, tfoot => 1,
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}} and
                     $self->{insertion_mode} == IN_CAPTION_IM) {
              
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              
              #
            }
      } else {
        die "$0: $token->{type}: Unknown token type";
      }

      $insert = $insert_to_current;
      #
    } elsif ($self->{insertion_mode} & TABLE_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              
              unless (length $token->{data}) {
                
                $token = $self->_get_next_token;
                redo B;
              } else {
                
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
      } elsif ($token->{type} == START_TAG_TOKEN) {
            if ({
                 tr => ($self->{insertion_mode} != IN_ROW_IM),
                 th => 1, td => 1,
                }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == IN_TABLE_IM) {
                ## Clear back to table context
                while ($self->{open_elements}->[-1]->[1] ne 'table' and
                       $self->{open_elements}->[-1]->[1] ne 'html') {
                  
                  pop @{$self->{open_elements}};
                }
                
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'tbody']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'tbody'];
    }
  
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                ## reprocess in the "in table body" insertion mode...
              }

              if ($self->{insertion_mode} == IN_TABLE_BODY_IM) {
                unless ($token->{tag_name} eq 'tr') {
                  
                  $self->{parse_error}-> (type => 'missing start tag:tr');
                }
                
                ## Clear back to table body context
                while (not {
                  tbody => 1, tfoot => 1, thead => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
                  ## ISSUE: Can this case be reached?
                  pop @{$self->{open_elements}};
                }
                
                $self->{insertion_mode} = IN_ROW_IM;
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
                  redo B;
                } else {
                  
                  
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'tr']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'tr'];
    }
  
                  ## reprocess in the "in row" insertion mode
                }
              } else {
                
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                
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
  
              $self->{insertion_mode} = IN_CELL_IM;

              push @$active_formatting_elements, ['#marker', ''];
              
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      caption => 1, col => 1, colgroup => 1,
                      tbody => 1, tfoot => 1, thead => 1,
                      tr => 1, # $self->{insertion_mode} == IN_ROW_IM
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == IN_ROW_IM) {
                ## As if </tr>
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] eq 'tr') {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            html => 1,

                            ## NOTE: This element does not appear here, maybe.
                            table => 1,
                           }->{$node->[1]}) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) { 
                 
## TODO: This type is wrong.
                 $self->{parse_error}-> (type => 'unmacthed end tag:'.$token->{tag_name});
                  ## Ignore the token
                  $token = $self->_get_next_token;
                  redo B;
                }
                
                ## Clear back to table row context
                while (not {
                  tr => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
                  ## ISSUE: Can this case be reached?
                  pop @{$self->{open_elements}};
                }
                
                pop @{$self->{open_elements}}; # tr
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                if ($token->{tag_name} eq 'tr') {
                  
                  ## reprocess
                  redo B;
                } else {
                  
                  ## reprocess in the "in table body" insertion mode...
                }
              }

              if ($self->{insertion_mode} == IN_TABLE_BODY_IM) {
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
                  
## TODO: This erorr type ios wrong.
                  $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                  ## Ignore the token
                  $token = $self->_get_next_token;
                  redo B;
                }

                ## Clear back to table body context
                while (not {
                  tbody => 1, tfoot => 1, thead => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
                  ## ISSUE: Can this state be reached?
                  pop @{$self->{open_elements}};
                }
                
                ## As if <{current node}>
                ## have an element in table scope
                ## true by definition
                
                ## Clear back to table body context
                ## nop by definition
                
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = IN_TABLE_IM;
                ## reprocess in "in table" insertion mode...
              } else {
                
              }

              if ($token->{tag_name} eq 'col') {
                ## Clear back to table context
                while ($self->{open_elements}->[-1]->[1] ne 'table' and
                       $self->{open_elements}->[-1]->[1] ne 'html') {
                  
                  ## ISSUE: Can this state be reached?
                  pop @{$self->{open_elements}};
                }
                
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'colgroup']);
    
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, 'colgroup'];
    }
  
                $self->{insertion_mode} = IN_COLUMN_GROUP_IM;
                ## reprocess
                redo B;
              } elsif ({
                        caption => 1,
                        colgroup => 1,
                        tbody => 1, tfoot => 1, thead => 1,
                       }->{$token->{tag_name}}) {
                ## Clear back to table context
                while ($self->{open_elements}->[-1]->[1] ne 'table' and
                       $self->{open_elements}->[-1]->[1] ne 'html') {
                  
                  ## ISSUE: Can this state be reached?
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
                                           caption => IN_CAPTION_IM,
                                           colgroup => IN_COLUMN_GROUP_IM,
                                           tbody => IN_TABLE_BODY_IM,
                                           tfoot => IN_TABLE_BODY_IM,
                                           thead => IN_TABLE_BODY_IM,
                                          }->{$token->{tag_name}};
                $token = $self->_get_next_token;
                redo B;
              } else {
                die "$0: in table: <>: $token->{tag_name}";
              }
            } elsif ($token->{tag_name} eq 'table') {
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
                          #table => 1,
                          html => 1,
                         }->{$node->[1]}) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
## TODO: The following is wrong, maybe.
                $self->{parse_error}-> (type => 'unmatched end tag:table');
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              while ({
                      dd => 1, dt => 1, li => 1, p => 1,
                     }->{$self->{open_elements}->[-1]->[1]}) {
                
                pop @{$self->{open_elements}};
              }

              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                
## ISSUE: Can this case be reached?
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              } else {
                
              }

              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode; 

              ## reprocess
              redo B;
        } else {
          
          $self->{parse_error}-> (type => 'in table:'.$token->{tag_name});

          $insert = $insert_to_foster;
          #
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'tr' and
                $self->{insertion_mode} == IN_ROW_IM) {
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
              } else {
                
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                
## ISSUE: Can this state be reached?
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}}; # tr
              $self->{insertion_mode} = IN_TABLE_BODY_IM;
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'table') {
              if ($self->{insertion_mode} == IN_ROW_IM) {
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
                  
## TODO: The following is wrong.
                  $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{type});
                  ## Ignore the token
                  $token = $self->_get_next_token;
                  redo B;
                }
                
                ## Clear back to table row context
                while (not {
                  tr => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
## ISSUE: Can this state be reached?
                  pop @{$self->{open_elements}};
                }
                
                pop @{$self->{open_elements}}; # tr
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                ## reprocess in the "in table body" insertion mode...
              }

              if ($self->{insertion_mode} == IN_TABLE_BODY_IM) {
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
                  
                  pop @{$self->{open_elements}};
                }
                
                ## As if <{current node}>
                ## have an element in table scope
                ## true by definition
                
                ## Clear back to table body context
                ## nop by definition
                
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = IN_TABLE_IM;
                ## reprocess in the "in table" insertion mode...
              }

              ## NOTE: </table> in the "in table" insertion mode.
              ## When you edit the code fragment below, please ensure that
              ## the code for <table> in the "in table" insertion mode
              ## is synced with it.

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
                
              splice @{$self->{open_elements}}, $i;
              
              $self->_reset_insertion_mode;
              
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      tbody => 1, tfoot => 1, thead => 1,
                     }->{$token->{tag_name}} and
                     $self->{insertion_mode} & ROW_IMS) {
              if ($self->{insertion_mode} == IN_ROW_IM) {
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
                  
## ISSUE: Can this case be reached?
                  pop @{$self->{open_elements}};
                }
                
                pop @{$self->{open_elements}}; # tr
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                ## reprocess in the "in table body" insertion mode...
              }

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
                
## ISSUE: Can this case be reached?
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}};
              $self->{insertion_mode} = IN_TABLE_IM;
              $token = $self->_get_next_token;
              redo B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, td => 1, th => 1,
                      tr => 1, # $self->{insertion_mode} == IN_ROW_IM
                      tbody => 1, tfoot => 1, thead => 1, # $self->{insertion_mode} == IN_TABLE_IM
                     }->{$token->{tag_name}}) {
              
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
        } else {
          
          $self->{parse_error}-> (type => 'in table:/'.$token->{tag_name});

          $insert = $insert_to_foster;
          #
        }
      } else {
        die "$0: $token->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} == IN_COLUMN_GROUP_IM) {
          if ($token->{type} == CHARACTER_TOKEN) {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            
            #
          } elsif ($token->{type} == START_TAG_TOKEN) {
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
          } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'colgroup') {
              if ($self->{open_elements}->[-1]->[1] eq 'html') {
                
                $self->{parse_error}-> (type => 'unmatched end tag:colgroup');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
                pop @{$self->{open_elements}}; # colgroup
                $self->{insertion_mode} = IN_TABLE_IM;
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
            die "$0: $token->{type}: Unknown token type";
          }

          ## As if </colgroup>
          if ($self->{open_elements}->[-1]->[1] eq 'html') {
            
            $self->{parse_error}-> (type => 'unmatched end tag:colgroup');
            ## Ignore the token
            $token = $self->_get_next_token;
            redo B;
          } else {
            
            pop @{$self->{open_elements}}; # colgroup
            $self->{insertion_mode} = IN_TABLE_IM;
            ## reprocess
            redo B;
          }
    } elsif ($self->{insertion_mode} == IN_SELECT_IM) {
      if ($token->{type} == CHARACTER_TOKEN) {
        
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
            if ($token->{tag_name} eq 'option') {
              if ($self->{open_elements}->[-1]->[1] eq 'option') {
                
                ## As if </option>
                pop @{$self->{open_elements}};
              } else {
                
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
              } else {
                
              }

              if ($self->{open_elements}->[-1]->[1] eq 'optgroup') {
                
                ## As if </optgroup>
                pop @{$self->{open_elements}};
              } else {
                
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
## TODO: The type below is not good - <select> is replaced by </select>
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
          
          $self->{parse_error}-> (type => 'in select:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
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
## TODO: The following is wrong?
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
## ISSUE: Can this state be reached?
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
## TODO: The following error type is correct?
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
          
          $self->{parse_error}-> (type => 'in select:/'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } else {
        die "$0: $token->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} & BODY_AFTER_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          my $data = $1;
          ## As if in body
          $reconstruct_active_formatting_elements->($insert_to_current);
              
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
            redo B;
          }
        }
        
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}-> (type => 'after html:#character');

          ## Reprocess in the "after body" insertion mode.
        } else {
          
        }
        
        ## "after body" insertion mode
        $self->{parse_error}-> (type => 'after body:#character');

        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        redo B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}-> (type => 'after html:'.$token->{tag_name});
          
          ## Reprocess in the "after body" insertion mode.
        } else {
          
        }

        ## "after body" insertion mode
        $self->{parse_error}-> (type => 'after body:'.$token->{tag_name});

        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        redo B;
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}-> (type => 'after html:/'.$token->{tag_name});
          
          $self->{insertion_mode} = AFTER_BODY_IM;
          ## Reprocess in the "after body" insertion mode.
        } else {
          
        }

        ## "after body" insertion mode
        if ($token->{tag_name} eq 'html') {
          if (defined $self->{inner_html_node}) {
            
            $self->{parse_error}-> (type => 'unmatched end tag:html');
            ## Ignore the token
            $token = $self->_get_next_token;
            redo B;
          } else {
            
            $self->{insertion_mode} = AFTER_HTML_BODY_IM;
            $token = $self->_get_next_token;
            redo B;
          }
        } else {
          
          $self->{parse_error}-> (type => 'after body:/'.$token->{tag_name});

          $self->{insertion_mode} = IN_BODY_IM;
          ## reprocess
          redo B;
        }
      } else {
        die "$0: $token->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} & FRAME_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
            redo B;
          }
        }
        
        if ($token->{data} =~ s/^[^\x09\x0A\x0B\x0C\x20]+//) {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}-> (type => 'in frameset:#character');
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}-> (type => 'after frameset:#character');
          } else { # "after html frameset"
            
            $self->{parse_error}-> (type => 'after html:#character');

            $self->{insertion_mode} = AFTER_FRAMESET_IM;
            ## Reprocess in the "after frameset" insertion mode.
            $self->{parse_error}-> (type => 'after frameset:#character');
          }
          
          ## Ignore the token.
          if (length $token->{data}) {
            
            ## reprocess the rest of characters
          } else {
            
            $token = $self->_get_next_token;
          }
          redo B;
        }
        
        die qq[$0: Character "$token->{data}"];
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
          
          $self->{parse_error}-> (type => 'after html:'.$token->{tag_name});

          $self->{insertion_mode} = AFTER_FRAMESET_IM;
          ## Process in the "after frameset" insertion mode.
        } else {
          
        } 

        if ($token->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          
          
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
        } elsif ($token->{tag_name} eq 'frame' and
                 $self->{insertion_mode} == IN_FRAMESET_IM) {
          
          
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
          
          ## NOTE: As if in body.
          $parse_rcdata->(CDATA_CONTENT_MODEL, $insert_to_current);
          redo B;
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}-> (type => 'in frameset:'.$token->{tag_name});
          } else {
            
            $self->{parse_error}-> (type => 'after frameset:'.$token->{tag_name});
          }
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
          
          $self->{parse_error}-> (type => 'after html:/'.$token->{tag_name});

          $self->{insertion_mode} = AFTER_FRAMESET_IM;
          ## Process in the "after frameset" insertion mode.
        } else {
          
        }

        if ($token->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          if ($self->{open_elements}->[-1]->[1] eq 'html' and
              @{$self->{open_elements}} == 1) {
            
            $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
            ## Ignore the token
            $token = $self->_get_next_token;
          } else {
            
            pop @{$self->{open_elements}};
            $token = $self->_get_next_token;
          }

          if (not defined $self->{inner_html_node} and
              $self->{open_elements}->[-1]->[1] ne 'frameset') {
            
            $self->{insertion_mode} = AFTER_FRAMESET_IM;
          } else {
            
          }
          redo B;
        } elsif ($token->{tag_name} eq 'html' and
                 $self->{insertion_mode} == AFTER_FRAMESET_IM) {
          
          $self->{insertion_mode} = AFTER_HTML_FRAMESET_IM;
          $token = $self->_get_next_token;
          redo B;
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}-> (type => 'in frameset:/'.$token->{tag_name});
          } else {
            
            $self->{parse_error}-> (type => 'after frameset:/'.$token->{tag_name});
          }
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } else {
        die "$0: $token->{type}: Unknown token type";
      }

      ## ISSUE: An issue in spec here
    } else {
      die "$0: $self->{insertion_mode}: Unknown insertion mode";
    }

    ## "in body" insertion mode
    if ($token->{type} == START_TAG_TOKEN) {
      if ($token->{tag_name} eq 'script') {
        
        ## NOTE: This is an "as if in head" code clone
        $script_start_tag->($insert);
        redo B;
      } elsif ($token->{tag_name} eq 'style') {
        
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->(CDATA_CONTENT_MODEL, $insert);
        redo B;
      } elsif ({
                base => 1, link => 1,
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
        redo B;
      } elsif ($token->{tag_name} eq 'meta') {
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
  
        my $meta_el = pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.

        unless ($self->{confident}) {
          if ($token->{attributes}->{charset}) { ## TODO: And if supported
            
            $self->{change_encoding}
                ->($self, $token->{attributes}->{charset}->{value});
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                ->set_user_data (manakai_has_reference =>
                                     $token->{attributes}->{charset}
                                         ->{has_reference});
          } elsif ($token->{attributes}->{content}) {
            ## ISSUE: Algorithm name in the spec was incorrect so that not linked to the definition.
            if ($token->{attributes}->{content}->{value}
                =~ /\A[^;]*;[\x09-\x0D\x20]*[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                    [\x09-\x0D\x20]*=
                    [\x09-\x0D\x20]*(?>"([^"]*)"|'([^']*)'|
                    ([^"'\x09-\x0D\x20][^\x09-\x0D\x20]*))/x) {
              
              $self->{change_encoding}
                  ->($self, defined $1 ? $1 : defined $2 ? $2 : $3);
              $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                  ->set_user_data (manakai_has_reference =>
                                       $token->{attributes}->{content}
                                             ->{has_reference});
            }
          }
        } else {
          if ($token->{attributes}->{charset}) {
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                ->set_user_data (manakai_has_reference =>
                                     $token->{attributes}->{charset}
                                         ->{has_reference});
          }
          if ($token->{attributes}->{content}) {
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                ->set_user_data (manakai_has_reference =>
                                     $token->{attributes}->{content}
                                         ->{has_reference});
          }
        }

        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'title') {
        
        $self->{parse_error}-> (type => 'in body:title');
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->(RCDATA_CONTENT_MODEL, sub {
          if (defined $self->{head_element}) {
            
            $self->{head_element}->append_child ($_[0]);
          } else {
            
            $insert->($_[0]);
          }
        });
        redo B;
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
        redo B;
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1, 
                div => 1, dl => 1, fieldset => 1,
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
                listing => 1, menu => 1, ol => 1, p => 1, ul => 1,
                pre => 1,
               }->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
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
          if ($token->{type} == CHARACTER_TOKEN) {
            $token->{data} =~ s/^\x0A//;
            unless (length $token->{data}) {
              
              $token = $self->_get_next_token;
            } else {
              
            }
          } else {
            
          }
        } else {
          
          $token = $self->_get_next_token;
        }
        redo B;
      } elsif ($token->{tag_name} eq 'form') {
        if (defined $self->{form_element}) {
          
          $self->{parse_error}-> (type => 'in form:form');
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        } else {
          ## has a p element in scope
          INSCOPE: for (reverse @{$self->{open_elements}}) {
            if ($_->[1] eq 'p') {
              
              unshift @{$self->{token}}, $token;
              $token = {type => END_TAG_TOKEN, tag_name => 'p'};
              redo B;
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
          redo B;
        }
      } elsif ($token->{tag_name} eq 'li') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
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
            } else {
              
            }
            splice @{$self->{open_elements}}, $i;
            last LI;
          } else {
            
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
        redo B;
      } elsif ($token->{tag_name} eq 'dd' or $token->{tag_name} eq 'dt') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
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
            } else {
              
            }
            splice @{$self->{open_elements}}, $i;
            last LI;
          } else {
            
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
        redo B;
      } elsif ($token->{tag_name} eq 'plaintext') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
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
  
          
        $self->{content_model} = PLAINTEXT_CONTENT_MODEL;
          
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'a') {
        AFE: for my $i (reverse 0..$#$active_formatting_elements) {
          my $node = $active_formatting_elements->[$i];
          if ($node->[1] eq 'a') {
            
            $self->{parse_error}-> (type => 'in a:a');
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'a'};
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
        redo B;
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
        redo B;
      } elsif ($token->{tag_name} eq 'nobr') {
        $reconstruct_active_formatting_elements->($insert_to_current);

        ## has a |nobr| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq 'nobr') {
            
            $self->{parse_error}-> (type => 'in nobr:nobr');
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'nobr'};
            redo B;
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
        redo B;
      } elsif ($token->{tag_name} eq 'button') {
        ## has a button element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq 'button') {
            
            $self->{parse_error}-> (type => 'in button:button');
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'button'};
            redo B;
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
  

        ## TODO: associate with $self->{form_element} if defined

        push @$active_formatting_elements, ['#marker', ''];

        $token = $self->_get_next_token;
        redo B;
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
        redo B;
      } elsif ($token->{tag_name} eq 'xmp') {
        
        $reconstruct_active_formatting_elements->($insert_to_current);
        $parse_rcdata->(CDATA_CONTENT_MODEL, $insert);
        redo B;
      } elsif ($token->{tag_name} eq 'table') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
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
  
          
        $self->{insertion_mode} = IN_TABLE_IM;
          
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                area => 1, basefont => 1, bgsound => 1, br => 1,
                embed => 1, img => 1, param => 1, spacer => 1, wbr => 1,
                image => 1,
               }->{$token->{tag_name}}) {
        if ($token->{tag_name} eq 'image') {
          
          $self->{parse_error}-> (type => 'image');
          $token->{tag_name} = 'img';
        } else {
          
        }

        ## NOTE: There is an "as if <br>" code clone.
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
        redo B;
      } elsif ($token->{tag_name} eq 'hr') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
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
        redo B;
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
        redo B;
      } elsif ($token->{tag_name} eq 'isindex') {
        $self->{parse_error}-> (type => 'isindex');
        
        if (defined $self->{form_element}) {
          
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        } else {
          my $at = $token->{attributes};
          my $form_attrs;
          $form_attrs->{action} = $at->{action} if $at->{action};
          my $prompt_attr = $at->{prompt};
          $at->{name} = {name => 'name', value => 'isindex'};
          delete $at->{action};
          delete $at->{prompt};
          my @tokens = (
                        {type => START_TAG_TOKEN, tag_name => 'form',
                         attributes => $form_attrs},
                        {type => START_TAG_TOKEN, tag_name => 'hr'},
                        {type => START_TAG_TOKEN, tag_name => 'p'},
                        {type => START_TAG_TOKEN, tag_name => 'label'},
                       );
          if ($prompt_attr) {
            
            push @tokens, {type => CHARACTER_TOKEN, data => $prompt_attr->{value}};
          } else {
            
            push @tokens, {type => CHARACTER_TOKEN,
                           data => 'This is a searchable index. Insert your search keywords here: '}; # SHOULD
            ## TODO: make this configurable
          }
          push @tokens,
                        {type => START_TAG_TOKEN, tag_name => 'input', attributes => $at},
                        #{type => CHARACTER_TOKEN, data => ''}, # SHOULD
                        {type => END_TAG_TOKEN, tag_name => 'label'},
                        {type => END_TAG_TOKEN, tag_name => 'p'},
                        {type => START_TAG_TOKEN, tag_name => 'hr'},
                        {type => END_TAG_TOKEN, tag_name => 'form'};
          $token = shift @tokens;
          unshift @{$self->{token}}, (@tokens);
          redo B;
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
        $self->{content_model} = RCDATA_CONTENT_MODEL;
        delete $self->{escape}; # MUST
        
        $insert->($el);
        
        my $text = '';
        $token = $self->_get_next_token;
        if ($token->{type} == CHARACTER_TOKEN) {
          $token->{data} =~ s/^\x0A//;
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
          } else {
            
          }
        } else {
          
        }
        while ($token->{type} == CHARACTER_TOKEN) {
          
          $text .= $token->{data};
          $token = $self->_get_next_token;
        }
        if (length $text) {
          
          $el->manakai_append_text ($text);
        }
        
        $self->{content_model} = PCDATA_CONTENT_MODEL;
        
        if ($token->{type} == END_TAG_TOKEN and
            $token->{tag_name} eq $tag_name) {
          
          ## Ignore the token
        } else {
          
          $self->{parse_error}-> (type => 'in RCDATA:#'.$token->{type});
        }
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                iframe => 1,
                noembed => 1,
                noframes => 1,
                noscript => 0, ## TODO: 1 if scripting is enabled
               }->{$token->{tag_name}}) {
        
        ## NOTE: There is an "as if in body" code clone.
        $parse_rcdata->(CDATA_CONTENT_MODEL, $insert);
        redo B;
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
  

        ## TODO: associate with $self->{form_element} if defined
        
        $self->{insertion_mode} = IN_SELECT_IM;
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
               }->{$token->{tag_name}}) {
        
        $self->{parse_error}-> (type => 'in body:'.$token->{tag_name});
        ## Ignore the token
        $token = $self->_get_next_token;
        redo B;
        
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
        redo B;
      }
    } elsif ($token->{type} == END_TAG_TOKEN) {
      if ($token->{tag_name} eq 'body') {
        if (@{$self->{open_elements}} > 1 and
            $self->{open_elements}->[1]->[1] eq 'body') {
          for (@{$self->{open_elements}}) {
            unless ({
                       dd => 1, dt => 1, li => 1, p => 1, td => 1,
                       th => 1, tr => 1, body => 1, html => 1,
                     tbody => 1, tfoot => 1, thead => 1,
                    }->{$_->[1]}) {
              
              $self->{parse_error}-> (type => 'not closed:'.$_->[1]);
            } else {
              
            }
          }

          $self->{insertion_mode} = AFTER_BODY_IM;
          $token = $self->_get_next_token;
          redo B;
        } else {
          
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ($token->{tag_name} eq 'html') {
        if (@{$self->{open_elements}} > 1 and $self->{open_elements}->[1]->[1] eq 'body') {
          ## ISSUE: There is an issue in the spec.
          if ($self->{open_elements}->[-1]->[1] ne 'body') {
            
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[1]->[1]);
          } else {
            
          }
          $self->{insertion_mode} = AFTER_BODY_IM;
          ## reprocess
          redo B;
        } else {
          
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1,
                div => 1, dl => 1, fieldset => 1, listing => 1,
                menu => 1, ol => 1, pre => 1, ul => 1,
                dd => 1, dt => 1, li => 1,
                button => 1, marquee => 1, object => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            
            $i = $_;
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        } else {
          ## Step 1. generate implied end tags
          while ({
                  dd => ($token->{tag_name} ne 'dd'),
                  dt => ($token->{tag_name} ne 'dt'),
                  li => ($token->{tag_name} ne 'li'),
                  p => 1,
                 }->{$self->{open_elements}->[-1]->[1]}) {
            
            pop @{$self->{open_elements}};
          }

          ## Step 2.
          if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
            
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
          } else {
            
          }

          ## Step 3.
          splice @{$self->{open_elements}}, $i;

          ## Step 4.
          $clear_up_to_marker->()
              if {
                button => 1, marquee => 1, object => 1,
              }->{$token->{tag_name}};
        }
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'form') {
        undef $self->{form_element};

        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            
            $i = $_;
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        } else {
          ## Step 1. generate implied end tags
          while ({
                  dd => 1, dt => 1, li => 1, p => 1,
                 }->{$self->{open_elements}->[-1]->[1]}) {
            
            pop @{$self->{open_elements}};
          }
          
          ## Step 2. 
          if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
            
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
          } else {
            
          }  
          
          ## Step 3.
          splice @{$self->{open_elements}}, $i;
        }

        $token = $self->_get_next_token;
        redo B;
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
            
            $i = $_;
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        } else {
          ## Step 1. generate implied end tags
          while ({
                  dd => 1, dt => 1, li => 1, p => 1,
                 }->{$self->{open_elements}->[-1]->[1]}) {
            
            pop @{$self->{open_elements}};
          }
          
          ## Step 2.
          if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
            
            $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          } else {
            
          }

          ## Step 3.
          splice @{$self->{open_elements}}, $i;
        }
        
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'p') {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            
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
          if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
            
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
          } else {
            
          }

          splice @{$self->{open_elements}}, $i;
        } else {
          
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});

          
          ## As if <p>, then reprocess the current token
          my $el;
          
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'p']);
    
          $insert->($el);
          ## NOTE: Not inserted into |$self->{open_elements}|.
        }

        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                a => 1,
                b => 1, big => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strile => 1,
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        
        $formatting_end_tag->($token->{tag_name});
        redo B;
      } elsif ($token->{tag_name} eq 'br') {
        
        $self->{parse_error}-> (type => 'unmatched end tag:br');

        ## As if <br>
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        my $el;
        
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'br']);
    
        $insert->($el);
        
        ## Ignore the token.
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
                area => 1, basefont => 1, bgsound => 1,
                embed => 1, hr => 1, iframe => 1, image => 1,
                img => 1, input => 1, isindex => 1, noembed => 1,
                noframes => 1, param => 1, select => 1, spacer => 1,
                table => 1, textarea => 1, wbr => 1,
                noscript => 0, ## TODO: if scripting is enabled
               }->{$token->{tag_name}}) {
        
        $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        ## Ignore the token
        $token = $self->_get_next_token;
        redo B;
        
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
            while ({
                    dd => 1, dt => 1, li => 1, p => 1,
                   }->{$self->{open_elements}->[-1]->[1]}) {
              
              ## ISSUE: Can this case be reached?
              pop @{$self->{open_elements}};
            }
        
            ## Step 2
            if ($token->{tag_name} ne $self->{open_elements}->[-1]->[1]) {
              
              ## NOTE: <x><y></x>
              $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
            } else {
              
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
	redo B;
      }
    }
    redo B;
  } # B

  ## Stop parsing # MUST
  
  ## TODO: script stuffs
} # _tree_construct_main

sub set_inner_html ($$$) {
  my $class = shift;
  my $node = shift;
  my $s = \$_[0];
  my $onerror = $_[1];

  ## ISSUE: Should {confident} be true?

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

    ## Step 8 # MUST
    my $i = 0;
    my $line = 1;
    my $column = 0;
    $p->{set_next_char} = sub {
      my $self = shift;

      pop @{$self->{prev_char}};
      unshift @{$self->{prev_char}}, $self->{next_char};

      $self->{next_char} = -1 and return if $i >= length $$s;
      $self->{next_char} = ord substr $$s, $i++, 1;
      $column++;

      if ($self->{next_char} == 0x000A) { # LF
        $line++;
        $column = 0;
        
      } elsif ($self->{next_char} == 0x000D) { # CR
        $i++ if substr ($$s, $i, 1) eq "\x0A";
        $self->{next_char} = 0x000A; # LF # MUST
        $line++;
        $column = 0;
        
      } elsif ($self->{next_char} > 0x10FFFF) {
        $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
        
      } elsif ($self->{next_char} == 0x0000) { # NULL
        
        $self->{parse_error}-> (type => 'NULL');
        $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
      }
    };
    $p->{prev_char} = [-1, -1, -1];
    $p->{next_char} = -1;
    
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
    my $node_ln = $node->manakai_local_name;
    $p->{content_model} = {
      title => RCDATA_CONTENT_MODEL,
      textarea => RCDATA_CONTENT_MODEL,
      style => CDATA_CONTENT_MODEL,
      script => CDATA_CONTENT_MODEL,
      xmp => CDATA_CONTENT_MODEL,
      iframe => CDATA_CONTENT_MODEL,
      noembed => CDATA_CONTENT_MODEL,
      noframes => CDATA_CONTENT_MODEL,
      noscript => CDATA_CONTENT_MODEL,
      plaintext => PLAINTEXT_CONTENT_MODEL,
    }->{$node_ln};
    $p->{content_model} = PCDATA_CONTENT_MODEL
        unless defined $p->{content_model};
        ## ISSUE: What is "the name of the element"? local name?

    $p->{inner_html_node} = [$node, $node_ln];

    ## Step 3
    my $root = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, 'html']);

    ## Step 4 # MUST
    $doc->append_child ($root);

    ## Step 5 # MUST
    push @{$p->{open_elements}}, [$root, 'html'];

    undef $p->{head_element};

    ## Step 6 # MUST
    $p->_reset_insertion_mode;

    ## Step 7 # MUST
    my $anode = $node;
    AN: while (defined $anode) {
      if ($anode->node_type == 1) {
        my $nsuri = $anode->namespace_uri;
        if (defined $nsuri and $nsuri eq 'http://www.w3.org/1999/xhtml') {
          if ($anode->manakai_local_name eq 'form') {
            
            $p->{form_element} = $anode;
            last AN;
          }
        }
      }
      $anode = $anode->parent_node;
    } # AN
    
    ## Step 9 # MUST
    {
      my $self = $p;
      $token = $self->_get_next_token;
    }
    $p->_tree_construction_main;

    ## Step 10 # MUST
    my @cn = @{$node->child_nodes};
    for (@cn) {
      $node->remove_child ($_);
    }
    ## ISSUE: mutation events? read-only?

    ## Step 11 # MUST
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

package Whatpm::HTML::RestartParser;
push our @ISA, 'Error';

1;
# $Date: 2008/03/08 04:13:10 $
