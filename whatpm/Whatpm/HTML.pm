package Whatpm::HTML;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.83 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

sub AFTER_HTML_BODY_IM () { AFTER_HTML_IMS | BODY_AFTER_IMS }
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
          
      $Whatpm::HTML::Debug::cp_pass->(1) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1} = 1;
      }
    
          $self->{state} = ENTITY_DATA_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(2) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{2} = 1;
      }
    
          #
        }
      } elsif ($self->{next_char} == 0x002D) { # -
	if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
          unless ($self->{escape}) {
            if ($self->{prev_char}->[0] == 0x002D and # -
                $self->{prev_char}->[1] == 0x0021 and # !
                $self->{prev_char}->[2] == 0x003C) { # <
              
      $Whatpm::HTML::Debug::cp_pass->(3) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{3} = 1;
      }
    
              $self->{escape} = 1;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->(4) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{4} = 1;
      }
    
            }
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(5) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{5} = 1;
      }
    
          }
        }
        
        #
      } elsif ($self->{next_char} == 0x003C) { # <
        if ($self->{content_model} & CM_FULL_MARKUP or # PCDATA
            (($self->{content_model} & CM_LIMITED_MARKUP) and # CDATA | RCDATA
             not $self->{escape})) {
          
      $Whatpm::HTML::Debug::cp_pass->(6) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{6} = 1;
      }
    
          $self->{state} = TAG_OPEN_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(7) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{7} = 1;
      }
    
          #
        }
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{escape} and
            ($self->{content_model} & CM_LIMITED_MARKUP)) { # RCDATA | CDATA
          if ($self->{prev_char}->[0] == 0x002D and # -
              $self->{prev_char}->[1] == 0x002D) { # -
            
      $Whatpm::HTML::Debug::cp_pass->(8) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{8} = 1;
      }
    
            delete $self->{escape};
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(9) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{9} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(10) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{10} = 1;
      }
    
        }
        
        #
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(11) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{11} = 1;
      }
    
        return  ({type => END_OF_FILE_TOKEN});
        last A; ## TODO: ok?
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(12) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{12} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(13) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{13} = 1;
      }
    
        return  ({type => CHARACTER_TOKEN, data => '&'});
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(14) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{14} = 1;
      }
    
        return  ($token);
      }

      redo A;
    } elsif ($self->{state} == TAG_OPEN_STATE) {
      if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
        if ($self->{next_char} == 0x002F) { # /
          
      $Whatpm::HTML::Debug::cp_pass->(15) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{15} = 1;
      }
    
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          $self->{state} = CLOSE_TAG_OPEN_STATE;
          redo A;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(16) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{16} = 1;
      }
    
          ## reconsume
          $self->{state} = DATA_STATE;

          return  ({type => CHARACTER_TOKEN, data => '<'});

          redo A;
        }
      } elsif ($self->{content_model} & CM_FULL_MARKUP) { # PCDATA
        if ($self->{next_char} == 0x0021) { # !
          
      $Whatpm::HTML::Debug::cp_pass->(17) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{17} = 1;
      }
    
          $self->{state} = MARKUP_DECLARATION_OPEN_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } elsif ($self->{next_char} == 0x002F) { # /
          
      $Whatpm::HTML::Debug::cp_pass->(18) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{18} = 1;
      }
    
          $self->{state} = CLOSE_TAG_OPEN_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } elsif (0x0041 <= $self->{next_char} and
                 $self->{next_char} <= 0x005A) { # A..Z
          
      $Whatpm::HTML::Debug::cp_pass->(19) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{19} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(20) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{20} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(21) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{21} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(22) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{22} = 1;
      }
    
          $self->{parse_error}-> (type => 'pio');
          $self->{state} = BOGUS_COMMENT_STATE;
          ## $self->{next_char} is intentionally left as is
          redo A;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(23) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{23} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->(24) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{24} = 1;
      }
    
              
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
              next TAGNAME;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->(25) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{25} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->(26) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{26} = 1;
      }
    
            $self->{next_char} = shift @next_char; # reconsume
            unshift @{$self->{char}},  (@next_char);
            $self->{state} = DATA_STATE;
            return  ({type => CHARACTER_TOKEN, data => '</'});
            redo A;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(27) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{27} = 1;
      }
    
            $self->{next_char} = shift @next_char;
            unshift @{$self->{char}},  (@next_char);
            # and consume...
          }
        } else {
          ## No start tag token has ever been emitted
          
      $Whatpm::HTML::Debug::cp_pass->(28) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{28} = 1;
      }
    
          # next-input-character is already done
          $self->{state} = DATA_STATE;
          return  ({type => CHARACTER_TOKEN, data => '</'});
          redo A;
        }
      }
      
      if (0x0041 <= $self->{next_char} and
          $self->{next_char} <= 0x005A) { # A..Z
        
      $Whatpm::HTML::Debug::cp_pass->(29) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{29} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(30) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{30} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(31) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{31} = 1;
      }
    
        $self->{parse_error}-> (type => 'empty end tag');
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(32) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{32} = 1;
      }
    
        $self->{parse_error}-> (type => 'bare etago');
        $self->{state} = DATA_STATE;
        # reconsume

        return  ({type => CHARACTER_TOKEN, data => '</'});

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(33) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{33} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(34) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{34} = 1;
      }
    
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(35) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{35} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->(37) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{37} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(38) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{38} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(39) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{39} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->(41) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{41} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(42) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{42} = 1;
      }
    
          #
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(43) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{43} = 1;
      }
    
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(44) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{44} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(45) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{45} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(46) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{46} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(47) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{47} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(48) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{48} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(49) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{49} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(50) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{50} = 1;
      }
    
          #
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(51) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{51} = 1;
      }
    
          $self->{parse_error}-> (type => 'nestc');
        }
        ## Stay in the state
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(52) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{52} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(53) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{53} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(54) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{54} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(55) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{55} = 1;
      }
    
          $self->{parse_error}-> (type => 'bad attribute name');
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(56) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{56} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(57) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{57} = 1;
      }
    
          $self->{parse_error}-> (type => 'duplicate attribute:'.$self->{current_attribute}->{name});
          ## Discard $self->{current_attribute} # MUST
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(58) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{58} = 1;
      }
    
          $self->{current_token}->{attributes}->{$self->{current_attribute}->{name}}
            = $self->{current_attribute};
        }
      }; # $before_leave

      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
      $Whatpm::HTML::Debug::cp_pass->(59) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{59} = 1;
      }
    
        $before_leave->();
        $self->{state} = AFTER_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003D) { # =
        
      $Whatpm::HTML::Debug::cp_pass->(60) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{60} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(61) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{61} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(62) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{62} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(63) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{63} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(64) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{64} = 1;
      }
    
          #
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(65) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{65} = 1;
      }
    
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        $before_leave->();
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(66) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{66} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(67) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{67} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(68) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{68} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(69) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{69} = 1;
      }
    
          $self->{parse_error}-> (type => 'bad attribute name');
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(70) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{70} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(71) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{71} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003D) { # =
        
      $Whatpm::HTML::Debug::cp_pass->(72) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{72} = 1;
      }
    
        $self->{state} = BEFORE_ATTRIBUTE_VALUE_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(73) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{73} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(74) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{74} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(75) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{75} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(76) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{76} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(77) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{77} = 1;
      }
    
          #
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(78) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{78} = 1;
      }
    
          $self->{parse_error}-> (type => 'nestc');
          ## TODO: Different error type for <aa / bb> than <aa/>
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}-> (type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(79) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{79} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(80) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{80} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(81) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{81} = 1;
      }
    
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        # reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(82) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{82} = 1;
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
    } elsif ($self->{state} == BEFORE_ATTRIBUTE_VALUE_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP      
        
      $Whatpm::HTML::Debug::cp_pass->(83) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{83} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
      $Whatpm::HTML::Debug::cp_pass->(84) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{84} = 1;
      }
    
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
      $Whatpm::HTML::Debug::cp_pass->(85) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{85} = 1;
      }
    
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        ## reconsume
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
      $Whatpm::HTML::Debug::cp_pass->(86) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{86} = 1;
      }
    
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(87) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{87} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(88) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{88} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(89) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{89} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(90) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{90} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(91) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{91} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(92) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{92} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(93) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{93} = 1;
      }
    
          $self->{parse_error}-> (type => 'bad attribute value');
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(94) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{94} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(95) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{95} = 1;
      }
    
        $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
      $Whatpm::HTML::Debug::cp_pass->(96) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{96} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(97) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{97} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(98) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{98} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(99) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{99} = 1;
      }
    
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(100) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{100} = 1;
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
    } elsif ($self->{state} == ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
      $Whatpm::HTML::Debug::cp_pass->(101) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{101} = 1;
      }
    
        $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
      $Whatpm::HTML::Debug::cp_pass->(102) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{102} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(103) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{103} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(104) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{104} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(105) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{105} = 1;
      }
    
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(106) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{106} = 1;
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
    } elsif ($self->{state} == ATTRIBUTE_VALUE_UNQUOTED_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # HT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
      $Whatpm::HTML::Debug::cp_pass->(107) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{107} = 1;
      }
    
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
      $Whatpm::HTML::Debug::cp_pass->(108) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{108} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(109) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{109} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(110) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{110} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(111) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{111} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(112) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{112} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(113) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{113} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(114) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{114} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(115) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{115} = 1;
      }
    
          $self->{parse_error}-> (type => 'bad attribute value');
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(116) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{116} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(117) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{117} = 1;
      }
    
        $self->{current_attribute}->{value} .= '&';
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(118) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{118} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(118) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{118} = 1;
      }
    
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->(119) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{119} = 1;
      }
    
          $self->{current_token}->{first_start_tag}
              = not defined $self->{last_emitted_start_tag_name};
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
      $Whatpm::HTML::Debug::cp_pass->(120) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{120} = 1;
      }
    
            $self->{parse_error}-> (type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
      $Whatpm::HTML::Debug::cp_pass->(121) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{121} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(122) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{122} = 1;
      }
    
          #
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(123) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{123} = 1;
      }
    
          $self->{parse_error}-> (type => 'nestc');
        }
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        # next-input-character is already done
        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(124) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{124} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(124) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{124} = 1;
      }
    
          $self->{state} = DATA_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

          return  ($token);

          redo A;
        } elsif ($self->{next_char} == -1) { 
          
      $Whatpm::HTML::Debug::cp_pass->(125) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{125} = 1;
      }
    
          $self->{state} = DATA_STATE;
          ## reconsume

          return  ($token);

          redo A;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(126) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{126} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(127) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{127} = 1;
      }
    
          $self->{current_token} = {type => COMMENT_TOKEN, data => ''};
          $self->{state} = COMMENT_START_STATE;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          redo A;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(128) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{128} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->(129) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{129} = 1;
      }
    
                    ## TODO: What a stupid code this is!
                    $self->{state} = DOCTYPE_STATE;
                    
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                    redo A;
                  } else {
                    
      $Whatpm::HTML::Debug::cp_pass->(130) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{130} = 1;
      }
    
                  }
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->(131) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{131} = 1;
      }
    
                }
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->(132) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{132} = 1;
      }
    
              }
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->(133) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{133} = 1;
      }
    
            }
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(134) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{134} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(135) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{135} = 1;
      }
    
        }
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(136) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{136} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(137) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{137} = 1;
      }
    
        $self->{state} = COMMENT_START_DASH_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(138) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{138} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(139) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{139} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(140) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{140} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(141) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{141} = 1;
      }
    
        $self->{state} = COMMENT_END_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(142) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{142} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(143) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{143} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(144) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{144} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(145) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{145} = 1;
      }
    
        $self->{state} = COMMENT_END_DASH_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(146) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{146} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(147) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{147} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(148) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{148} = 1;
      }
    
        $self->{state} = COMMENT_END_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(149) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{149} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(150) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{150} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(151) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{151} = 1;
      }
    
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == 0x002D) { # -
        
      $Whatpm::HTML::Debug::cp_pass->(152) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{152} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(153) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{153} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(154) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{154} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(155) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{155} = 1;
      }
    
        $self->{state} = BEFORE_DOCTYPE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(156) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{156} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(157) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{157} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(158) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{158} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(159) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{159} = 1;
      }
    
        $self->{parse_error}-> (type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ({type => DOCTYPE_TOKEN, quirks => 1});

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(160) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{160} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(161) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{161} = 1;
      }
    
        $self->{state} = AFTER_DOCTYPE_NAME_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(162) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{162} = 1;
      }
    
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(163) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{163} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(164) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{164} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(165) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{165} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(166) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{166} = 1;
      }
    
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(167) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{167} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->(168) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{168} = 1;
      }
    
                  $self->{state} = BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
                  
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                  redo A;
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->(169) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{169} = 1;
      }
    
                }
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->(170) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{170} = 1;
      }
    
              }
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->(171) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{171} = 1;
      }
    
            }
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(172) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{172} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(173) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{173} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->(174) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{174} = 1;
      }
    
                  $self->{state} = BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
                  
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
                  redo A;
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->(175) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{175} = 1;
      }
    
                }
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->(176) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{176} = 1;
      }
    
              }
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->(177) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{177} = 1;
      }
    
            }
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->(178) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{178} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(179) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{179} = 1;
      }
    
        }

        #
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(180) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{180} = 1;
      }
    
        
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
        
      $Whatpm::HTML::Debug::cp_pass->(181) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{181} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} eq 0x0022) { # "
        
      $Whatpm::HTML::Debug::cp_pass->(182) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{182} = 1;
      }
    
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} eq 0x0027) { # '
        
      $Whatpm::HTML::Debug::cp_pass->(183) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{183} = 1;
      }
    
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} eq 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(184) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{184} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(185) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{185} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(186) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{186} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(187) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{187} = 1;
      }
    
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(188) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{188} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(189) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{189} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(190) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{190} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(191) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{191} = 1;
      }
    
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(192) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{192} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(193) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{193} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(194) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{194} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(195) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{195} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
      $Whatpm::HTML::Debug::cp_pass->(196) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{196} = 1;
      }
    
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
      $Whatpm::HTML::Debug::cp_pass->(197) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{197} = 1;
      }
    
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(198) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{198} = 1;
      }
    
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(199) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{199} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(200) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{200} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(201) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{201} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
      $Whatpm::HTML::Debug::cp_pass->(202) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{202} = 1;
      }
    
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
      $Whatpm::HTML::Debug::cp_pass->(203) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{203} = 1;
      }
    
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(204) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{204} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(205) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{205} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(206) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{206} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(207) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{207} = 1;
      }
    
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(208) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{208} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(209) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{209} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(210) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{210} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(211) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{211} = 1;
      }
    
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(212) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{212} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(213) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{213} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(214) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{214} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(215) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{215} = 1;
      }
    
        ## Stay in the state
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
      $Whatpm::HTML::Debug::cp_pass->(216) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{216} = 1;
      }
    
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(217) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{217} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(218) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{218} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(219) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{219} = 1;
      }
    
        $self->{state} = DATA_STATE;
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(220) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{220} = 1;
      }
    
        $self->{parse_error}-> (type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(221) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{221} = 1;
      }
    
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
    
      $Whatpm::HTML::Debug::cp_pass->(1001) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1001} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(1002) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1002} = 1;
      }
    
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_char} - 0x0030;
          redo X;
        } elsif (0x0061 <= $self->{next_char} and
                 $self->{next_char} <= 0x0066) { # a..f
          
      $Whatpm::HTML::Debug::cp_pass->(1003) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1003} = 1;
      }
    
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_char} - 0x0060 + 9;
          redo X;
        } elsif (0x0041 <= $self->{next_char} and
                 $self->{next_char} <= 0x0046) { # A..F
          
      $Whatpm::HTML::Debug::cp_pass->(1004) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1004} = 1;
      }
    
          $code ||= 0;
          $code *= 0x10;
          $code += $self->{next_char} - 0x0040 + 9;
          redo X;
        } elsif (not defined $code) { # no hexadecimal digit
          
      $Whatpm::HTML::Debug::cp_pass->(1005) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1005} = 1;
      }
    
          $self->{parse_error}-> (type => 'bare hcro');
          unshift @{$self->{char}},  ($x_char, $self->{next_char});
          $self->{next_char} = 0x0023; # #
          return undef;
        } elsif ($self->{next_char} == 0x003B) { # ;
          
      $Whatpm::HTML::Debug::cp_pass->(1006) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1006} = 1;
      }
    
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(1007) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1007} = 1;
      }
    
          $self->{parse_error}-> (type => 'no refc');
        }

        if ($code == 0 or (0xD800 <= $code and $code <= 0xDFFF)) {
          
      $Whatpm::HTML::Debug::cp_pass->(1008) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1008} = 1;
      }
    
          $self->{parse_error}-> (type => sprintf 'invalid character reference:U+%04X', $code);
          $code = 0xFFFD;
        } elsif ($code > 0x10FFFF) {
          
      $Whatpm::HTML::Debug::cp_pass->(1009) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1009} = 1;
      }
    
          $self->{parse_error}-> (type => sprintf 'invalid character reference:U-%08X', $code);
          $code = 0xFFFD;
        } elsif ($code == 0x000D) {
          
      $Whatpm::HTML::Debug::cp_pass->(1010) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1010} = 1;
      }
    
          $self->{parse_error}-> (type => 'CR character reference');
          $code = 0x000A;
        } elsif (0x80 <= $code and $code <= 0x9F) {
          
      $Whatpm::HTML::Debug::cp_pass->(1011) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1011} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->(1012) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1012} = 1;
      }
    
        $code *= 10;
        $code += $self->{next_char} - 0x0030;
        
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
      }

      if ($self->{next_char} == 0x003B) { # ;
        
      $Whatpm::HTML::Debug::cp_pass->(1013) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1013} = 1;
      }
    
        
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(1014) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1014} = 1;
      }
    
        $self->{parse_error}-> (type => 'no refc');
      }

      if ($code == 0 or (0xD800 <= $code and $code <= 0xDFFF)) {
        
      $Whatpm::HTML::Debug::cp_pass->(1015) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1015} = 1;
      }
    
        $self->{parse_error}-> (type => sprintf 'invalid character reference:U+%04X', $code);
        $code = 0xFFFD;
      } elsif ($code > 0x10FFFF) {
        
      $Whatpm::HTML::Debug::cp_pass->(1016) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1016} = 1;
      }
    
        $self->{parse_error}-> (type => sprintf 'invalid character reference:U-%08X', $code);
        $code = 0xFFFD;
      } elsif ($code == 0x000D) {
        
      $Whatpm::HTML::Debug::cp_pass->(1017) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1017} = 1;
      }
    
        $self->{parse_error}-> (type => 'CR character reference');
        $code = 0x000A;
      } elsif (0x80 <= $code and $code <= 0x9F) {
        
      $Whatpm::HTML::Debug::cp_pass->(1018) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1018} = 1;
      }
    
        $self->{parse_error}-> (type => sprintf 'C1 character reference:U+%04X', $code);
        $code = $c1_entity_char->{$code};
      }
      
      return {type => CHARACTER_TOKEN, data => chr $code, has_reference => 1};
    } else {
      
      $Whatpm::HTML::Debug::cp_pass->(1019) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1019} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->(1020) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1020} = 1;
      }
    
          $value = $EntityChar->{$entity_name};
          $match = 1;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
          last;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->(1021) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1021} = 1;
      }
    
          $value = $EntityChar->{$entity_name};
          $match = -1;
          
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  
        }
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(1022) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1022} = 1;
      }
    
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
      
      $Whatpm::HTML::Debug::cp_pass->(1023) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1023} = 1;
      }
    
      return {type => CHARACTER_TOKEN, data => $value, has_reference => 1};
    } elsif ($match < 0) {
      $self->{parse_error}-> (type => 'no refc');
      if ($in_attr and $match < -1) {
        
      $Whatpm::HTML::Debug::cp_pass->(1024) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1024} = 1;
      }
    
        return {type => CHARACTER_TOKEN, data => '&'.$entity_name};
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->(1025) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1025} = 1;
      }
    
        return {type => CHARACTER_TOKEN, data => $value, has_reference => 1};
      }
    } else {
      
      $Whatpm::HTML::Debug::cp_pass->(1026) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1026} = 1;
      }
    
      $self->{parse_error}-> (type => 'bare ero');
      ## NOTE: "No characters are consumed" in the spec.
      return {type => CHARACTER_TOKEN, data => '&'.$value};
    }
  } else {
    
      $Whatpm::HTML::Debug::cp_pass->(1027) if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{1027} = 1;
      }
    
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

  $self->{insertion_mode} = BEFORE_HEAD_IM;
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
        
      $Whatpm::HTML::Debug::cp_pass->('t1') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t1'} = 1;
      }
    
        $self->{parse_error}-> (type => 'not HTML5');
      } elsif ($doctype_name ne 'HTML') {
        
      $Whatpm::HTML::Debug::cp_pass->('t2') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t2'} = 1;
      }
    
        ## ISSUE: ASCII case-insensitive? (in fact it does not matter)
        $self->{parse_error}-> (type => 'not HTML5');
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t3') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t3'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t4') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t4'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t5') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t5'} = 1;
      }
    
          $self->{document}->manakai_compat_mode ('quirks');
        } elsif ($pubid eq "-//W3C//DTD HTML 4.01 FRAMESET//EN" or
                 $pubid eq "-//W3C//DTD HTML 4.01 TRANSITIONAL//EN") {
          if (defined $token->{system_identifier}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t6') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t6'} = 1;
      }
    
            $self->{document}->manakai_compat_mode ('quirks');
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t7') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t7'} = 1;
      }
    
            $self->{document}->manakai_compat_mode ('limited quirks');
          }
        } elsif ($pubid eq "-//W3C//DTD XHTML 1.0 FRAMESET//EN" or
                 $pubid eq "-//W3C//DTD XHTML 1.0 TRANSITIONAL//EN") {
          
      $Whatpm::HTML::Debug::cp_pass->('t8') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t8'} = 1;
      }
    
          $self->{document}->manakai_compat_mode ('limited quirks');
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t9') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t9'} = 1;
      }
    
        }
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t10') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t10'} = 1;
      }
    
      }
      if (defined $token->{system_identifier}) {
        my $sysid = $token->{system_identifier};
        $sysid =~ tr/A-Z/a-z/;
        if ($sysid eq "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd") {
          ## TODO: Check the spec: PUBLIC "(limited quirks)" "(quirks)"
          $self->{document}->manakai_compat_mode ('quirks');
          
      $Whatpm::HTML::Debug::cp_pass->('t11') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t11'} = 1;
      }
    
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t12') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t12'} = 1;
      }
    
        }
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t13') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t13'} = 1;
      }
    
      }
      
      ## Go to the root element phase.
      $token = $self->_get_next_token;
      return;
    } elsif ({
              START_TAG_TOKEN, 1,
              END_TAG_TOKEN, 1,
              END_OF_FILE_TOKEN, 1,
             }->{$token->{type}}) {
      
      $Whatpm::HTML::Debug::cp_pass->('t14') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t14'} = 1;
      }
    
      $self->{parse_error}-> (type => 'no DOCTYPE');
      $self->{document}->manakai_compat_mode ('quirks');
      ## Go to the root element phase
      ## reprocess
      return;
    } elsif ($token->{type} == CHARACTER_TOKEN) {
      if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) { # \x0D
        ## Ignore the token

        unless (length $token->{data}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t15') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t15'} = 1;
      }
    
          ## Stay in the phase
          $token = $self->_get_next_token;
          redo INITIAL;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t16') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t16'} = 1;
      }
    
        }
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t17') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t17'} = 1;
      }
    
      }

      $self->{parse_error}-> (type => 'no DOCTYPE');
      $self->{document}->manakai_compat_mode ('quirks');
      ## Go to the root element phase
      ## reprocess
      return;
    } elsif ($token->{type} == COMMENT_TOKEN) {
      
      $Whatpm::HTML::Debug::cp_pass->('t18') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t18'} = 1;
      }
    
      my $comment = $self->{document}->create_comment ($token->{data});
      $self->{document}->append_child ($comment);
      
      ## Stay in the phase.
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
  
  B: {
      if ($token->{type} == DOCTYPE_TOKEN) {
        
      $Whatpm::HTML::Debug::cp_pass->('t19') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t19'} = 1;
      }
    
        $self->{parse_error}-> (type => 'in html:#DOCTYPE');
        ## Ignore the token
        ## Stay in the phase
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} == COMMENT_TOKEN) {
        
      $Whatpm::HTML::Debug::cp_pass->('t20') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t20'} = 1;
      }
    
        my $comment = $self->{document}->create_comment ($token->{data});
        $self->{document}->append_child ($comment);
        ## Stay in the phase
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) { # \x0D
          ## Ignore the token.

          unless (length $token->{data}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t21') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t21'} = 1;
      }
    
            ## Stay in the phase
            $token = $self->_get_next_token;
            redo B;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t22') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t22'} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t23') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t23'} = 1;
      }
    
        }

        $self->{application_cache_selection}->(undef);

        #
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($token->{tag_name} eq 'html' and
            $token->{attributes}->{manifest}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t24') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t24'} = 1;
      }
    
          $self->{application_cache_selection}
               ->($token->{attributes}->{manifest}->{value});
          ## ISSUE: No relative reference resolution?
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t25') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t25'} = 1;
      }
    
          $self->{application_cache_selection}->(undef);
        }

        ## ISSUE: There is an issue in the spec
        #
      } elsif ({
                END_TAG_TOKEN, 1,
                END_OF_FILE_TOKEN, 1,
               }->{$token->{type}}) {
        
      $Whatpm::HTML::Debug::cp_pass->('t26') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t26'} = 1;
      }
    
        $self->{application_cache_selection}->(undef);
 
        ## ISSUE: There is an issue in the spec
        #
      } else {
        die "$0: $token->{type}: Unknown token type";
      }

      my $root_element; 
      $root_element = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'html']);
    
      $self->{document}->append_child ($root_element);
      push @{$self->{open_elements}}, [$root_element, 'html'];
      ## reprocess
      #redo B;
      return; ## Go to the main phase.
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
            
      $Whatpm::HTML::Debug::cp_pass->('t27') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t27'} = 1;
      }
    
            #
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t28') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t28'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t29') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t29'} = 1;
      }
    
          $self->{insertion_mode} = BEFORE_HEAD_IM;
        } else {
          ## ISSUE: Can this state be reached?
          
      $Whatpm::HTML::Debug::cp_pass->('t30') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t30'} = 1;
      }
    
          $self->{insertion_mode} = AFTER_HEAD_IM;
        }
        return;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t31') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t31'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t32') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t32'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t33_1') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t33_1'} = 1;
      }
    
        #
      } else {
        my $in_open_elements;
        OE: for (@{$self->{open_elements}}) {
          if ($entry->[0] eq $_->[0]) {
            
      $Whatpm::HTML::Debug::cp_pass->('t33') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t33'} = 1;
      }
    
            $in_open_elements = 1;
            last OE;
          }
        }
        if ($in_open_elements) {
          
      $Whatpm::HTML::Debug::cp_pass->('t34') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t34'} = 1;
      }
    
          #
        } else {
          ## NOTE: <!DOCTYPE HTML><p><b><i><u></p> <p>X
          
      $Whatpm::HTML::Debug::cp_pass->('t35') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t35'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t36') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t36'} = 1;
      }
    
        ## Step 7'
        $i++;
        $entry = $active_formatting_elements->[$i];
        
        redo S7;
      }

      
      $Whatpm::HTML::Debug::cp_pass->('t37') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t37'} = 1;
      }
    
    } # S7
  }; # $reconstruct_active_formatting_elements

  my $clear_up_to_marker = sub {
    for (reverse 0..$#$active_formatting_elements) {
      if ($active_formatting_elements->[$_]->[0] eq '#marker') {
        
      $Whatpm::HTML::Debug::cp_pass->('t38') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t38'} = 1;
      }
    
        splice @$active_formatting_elements, $_;
        return;
      }
    }

    
      $Whatpm::HTML::Debug::cp_pass->('t39') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t39'} = 1;
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
      
      $Whatpm::HTML::Debug::cp_pass->('t40') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t40'} = 1;
      }
    
      $text .= $token->{data};
      $token = $self->_get_next_token;
    }

    ## Step 5
    if (length $text) {
      
      $Whatpm::HTML::Debug::cp_pass->('t41') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t41'} = 1;
      }
    
      my $text = $self->{document}->create_text_node ($text);
      $el->append_child ($text);
    }

    ## Step 6
    $self->{content_model} = PCDATA_CONTENT_MODEL;

    ## Step 7
    if ($token->{type} == END_TAG_TOKEN and
        $token->{tag_name} eq $start_tag_name) {
      
      $Whatpm::HTML::Debug::cp_pass->('t42') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t42'} = 1;
      }
    
      ## Ignore the token
    } elsif ($content_model_flag == CDATA_CONTENT_MODEL) {
      
      $Whatpm::HTML::Debug::cp_pass->('t43') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t43'} = 1;
      }
    
      $self->{parse_error}-> (type => 'in CDATA:#'.$token->{type});
    } elsif ($content_model_flag == RCDATA_CONTENT_MODEL) {
      
      $Whatpm::HTML::Debug::cp_pass->('t44') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t44'} = 1;
      }
    
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
      
      $Whatpm::HTML::Debug::cp_pass->('t45') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t45'} = 1;
      }
    
      $text .= $token->{data};
      $token = $self->_get_next_token;
    } # stop if non-character token or tokenizer stops tokenising
    if (length $text) {
      
      $Whatpm::HTML::Debug::cp_pass->('t46') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t46'} = 1;
      }
    
      $script_el->manakai_append_text ($text);
    }
              
    $self->{content_model} = PCDATA_CONTENT_MODEL;

    if ($token->{type} == END_TAG_TOKEN and
        $token->{tag_name} eq 'script') {
      
      $Whatpm::HTML::Debug::cp_pass->('t47') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t47'} = 1;
      }
    
      ## Ignore the token
    } else {
      
      $Whatpm::HTML::Debug::cp_pass->('t48') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t48'} = 1;
      }
    
      $self->{parse_error}-> (type => 'in CDATA:#'.$token->{type});
      ## ISSUE: And ignore?
      ## TODO: mark as "already executed"
    }
    
    if (defined $self->{inner_html_node}) {
      
      $Whatpm::HTML::Debug::cp_pass->('t49') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t49'} = 1;
      }
    
      ## TODO: mark as "already executed"
    } else {
      
      $Whatpm::HTML::Debug::cp_pass->('t50') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t50'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t51') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t51'} = 1;
      }
    
          $formatting_element = $active_formatting_elements->[$_];
          $formatting_element_i_in_active = $_;
          last AFE;
        } elsif ($active_formatting_elements->[$_]->[0] eq '#marker') {
          
      $Whatpm::HTML::Debug::cp_pass->('t52') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t52'} = 1;
      }
    
          last AFE;
        }
      } # AFE
      unless (defined $formatting_element) {
        
      $Whatpm::HTML::Debug::cp_pass->('t53') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t53'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t54') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t54'} = 1;
      }
    
            $formatting_element_i_in_open = $_;
            last INSCOPE;
          } else { # in open elements but not in scope
            
      $Whatpm::HTML::Debug::cp_pass->('t55') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t55'} = 1;
      }
    
            $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
            ## Ignore the token
            $token = $self->_get_next_token;
            return;
          }
        } elsif ({
                  table => 1, caption => 1, td => 1, th => 1,
                  button => 1, marquee => 1, object => 1, html => 1,
                 }->{$node->[1]}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t56') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t56'} = 1;
      }
    
          $in_scope = 0;
        }
      } # INSCOPE
      unless (defined $formatting_element_i_in_open) {
        
      $Whatpm::HTML::Debug::cp_pass->('t57') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t57'} = 1;
      }
    
        $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        pop @$active_formatting_elements; # $formatting_element
        $token = $self->_get_next_token; ## TODO: ok?
        return;
      }
      if (not $self->{open_elements}->[-1]->[0] eq $formatting_element->[0]) {
        
      $Whatpm::HTML::Debug::cp_pass->('t58') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t58'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t59') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t59'} = 1;
      }
    
          $furthest_block = $node;
          $furthest_block_i_in_open = $_;
        } elsif ($node->[0] eq $formatting_element->[0]) {
          
      $Whatpm::HTML::Debug::cp_pass->('t60') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t60'} = 1;
      }
    
          last OE;
        }
      } # OE
      
      ## Step 3
      unless (defined $furthest_block) { # MUST
        
      $Whatpm::HTML::Debug::cp_pass->('t61') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t61'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t62') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t62'} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->('t63') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t63'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t64') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t64'} = 1;
      }
    
          $bookmark_prev_el = $node->[0];
        }
        
        ## Step 5
        if ($node->[0]->has_child_nodes ()) {
          
      $Whatpm::HTML::Debug::cp_pass->('t65') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t65'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t66') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t66'} = 1;
      }
    
          splice @$active_formatting_elements, $_, 1;
          $i-- and last AFE if defined $i;
        } elsif ($active_formatting_elements->[$_]->[0] eq $bookmark_prev_el) {
          
      $Whatpm::HTML::Debug::cp_pass->('t67') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t67'} = 1;
      }
    
          $i = $_;
        }
      } # AFE
      splice @$active_formatting_elements, $i + 1, 0, $clone;
      
      ## Step 13
      undef $i;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        if ($self->{open_elements}->[$_]->[0] eq $formatting_element->[0]) {
          
      $Whatpm::HTML::Debug::cp_pass->('t68') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t68'} = 1;
      }
    
          splice @{$self->{open_elements}}, $_, 1;
          $i-- and last OE if defined $i;
        } elsif ($self->{open_elements}->[$_]->[0] eq $furthest_block->[0]) {
          
      $Whatpm::HTML::Debug::cp_pass->('t69') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t69'} = 1;
      }
    
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
                               
      $Whatpm::HTML::Debug::cp_pass->('t70') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t70'} = 1;
      }
    
                               $foster_parent_element = $parent;
                               $next_sibling = $self->{open_elements}->[$_]->[0];
                             } else {
                               
      $Whatpm::HTML::Debug::cp_pass->('t71') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t71'} = 1;
      }
    
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
                         
      $Whatpm::HTML::Debug::cp_pass->('t72') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t72'} = 1;
      }
    
                         $self->{open_elements}->[-1]->[0]->append_child ($child);
                       }
  }; # $insert_to_foster

  my $insert;

  B: {
    if ($token->{type} == DOCTYPE_TOKEN) {
      
      $Whatpm::HTML::Debug::cp_pass->('t73') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t73'} = 1;
      }
    
      $self->{parse_error}-> (type => 'DOCTYPE in the middle');
      ## Ignore the token
      ## Stay in the phase
      $token = $self->_get_next_token;
      redo B;
    } elsif ($token->{type} == END_OF_FILE_TOKEN) {
      if ($self->{insertion_mode} & AFTER_HTML_IMS) {
        
      $Whatpm::HTML::Debug::cp_pass->('t74') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t74'} = 1;
      }
    
        #
      } else {
        ## Generate implied end tags
        if ({
             dd => 1, dt => 1, li => 1, p => 1, td => 1, th => 1, tr => 1,
             tbody => 1, tfoot=> 1, thead => 1,
            }->{$self->{open_elements}->[-1]->[1]}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t75') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t75'} = 1;
      }
    
          unshift @{$self->{token}}, $token;
          $token = {type => END_TAG_TOKEN, tag_name => $self->{open_elements}->[-1]->[1]};
          redo B;
        }
        
        if (@{$self->{open_elements}} > 2 or
            (@{$self->{open_elements}} == 2 and $self->{open_elements}->[1]->[1] ne 'body')) {
          
      $Whatpm::HTML::Debug::cp_pass->('t76') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t76'} = 1;
      }
    
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        } elsif (defined $self->{inner_html_node} and
                 @{$self->{open_elements}} > 1 and
                 $self->{open_elements}->[1]->[1] ne 'body') {
## ISSUE: This case is never reached.
          
      $Whatpm::HTML::Debug::cp_pass->('t77') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t77'} = 1;
      }
    
          $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t78') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t78'} = 1;
      }
    
        }

        ## ISSUE: There is an issue in the spec.
      }

      ## Stop parsing
      last B;
    } elsif ($token->{type} == START_TAG_TOKEN and
             $token->{tag_name} eq 'html') {
      if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
        
      $Whatpm::HTML::Debug::cp_pass->('t79') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t79'} = 1;
      }
    
        ## Turn into the main phase
        $self->{parse_error}-> (type => 'after html:html');
        $self->{insertion_mode} = AFTER_BODY_IM;
      } elsif ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
        
      $Whatpm::HTML::Debug::cp_pass->('t80') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t80'} = 1;
      }
    
        ## Turn into the main phase
        $self->{parse_error}-> (type => 'after html:html');
        $self->{insertion_mode} = AFTER_FRAMESET_IM;
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t81') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t81'} = 1;
      }
    
      }

## ISSUE: "aa<html>" is not a parse error.
## ISSUE: "<html>" in fragment is not a parse error.
      unless ($token->{first_start_tag}) {
        
      $Whatpm::HTML::Debug::cp_pass->('t82') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t82'} = 1;
      }
    
        $self->{parse_error}-> (type => 'not first start tag');
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t83') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t83'} = 1;
      }
    
      }
      my $top_el = $self->{open_elements}->[0]->[0];
      for my $attr_name (keys %{$token->{attributes}}) {
        unless ($top_el->has_attribute_ns (undef, $attr_name)) {
          
      $Whatpm::HTML::Debug::cp_pass->('t84') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t84'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t85') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t85'} = 1;
      }
    
        $self->{document}->append_child ($comment);
      } elsif ($self->{insertion_mode} == AFTER_BODY_IM) {
        
      $Whatpm::HTML::Debug::cp_pass->('t86') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t86'} = 1;
      }
    
        $self->{open_elements}->[0]->[0]->append_child ($comment);
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t87') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t87'} = 1;
      }
    
        $self->{open_elements}->[-1]->[0]->append_child ($comment);
      }
      $token = $self->_get_next_token;
      redo B;
    } elsif ($self->{insertion_mode} & HEAD_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          unless (length $token->{data}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t88') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t88'} = 1;
      }
    
            $token = $self->_get_next_token;
            redo B;
          }
        }

        if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t89') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t89'} = 1;
      }
    
          ## As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
          $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
          push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

          ## Reprocess in the "in head" insertion mode...
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t90') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t90'} = 1;
      }
    
          ## As if </noscript>
          pop @{$self->{open_elements}};
          $self->{parse_error}-> (type => 'in noscript:#character');
          
          ## Reprocess in the "in head" insertion mode...
          ## As if </head>
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t91') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t91'} = 1;
      }
    
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t92') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t92'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t93') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t93'} = 1;
      }
    
                
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
                
      $Whatpm::HTML::Debug::cp_pass->('t94') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t94'} = 1;
      }
    
                #
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t95') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t95'} = 1;
      }
    
                $self->{parse_error}-> (type => 'in head:head'); # or in head noscript
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
            } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
              
      $Whatpm::HTML::Debug::cp_pass->('t96') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t96'} = 1;
      }
    
              ## As if <head>
              
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
              $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
              push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

              $self->{insertion_mode} = IN_HEAD_IM;
              ## Reprocess in the "in head" insertion mode...
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t97') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t97'} = 1;
      }
    
            }

            if ($token->{tag_name} eq 'base') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t98') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t98'} = 1;
      }
    
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:base');
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t99') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t99'} = 1;
      }
    
              }

              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t100') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t100'} = 1;
      }
    
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t101') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t101'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t102') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t102'} = 1;
      }
    
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t103') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t103'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t104') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t104'} = 1;
      }
    
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t105') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t105'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t106') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t106'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t107') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t107'} = 1;
      }
    
                    $self->{change_encoding}
                        ->($self, defined $1 ? $1 : defined $2 ? $2 : $3);
                    $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                        ->set_user_data (manakai_has_reference =>
                                             $token->{attributes}->{content}
                                                   ->{has_reference});
                  } else {
                    
      $Whatpm::HTML::Debug::cp_pass->('t108') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t108'} = 1;
      }
    
                  }
                }
              } else {
                if ($token->{attributes}->{charset}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t109') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t109'} = 1;
      }
    
                  $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                      ->set_user_data (manakai_has_reference =>
                                           $token->{attributes}->{charset}
                                               ->{has_reference});
                }
                if ($token->{attributes}->{content}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t110') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t110'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t111') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t111'} = 1;
      }
    
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:title');
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t112') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t112'} = 1;
      }
    
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t113') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t113'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t114') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t114'} = 1;
      }
    
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t115') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t115'} = 1;
      }
    
              }
              $parse_rcdata->(CDATA_CONTENT_MODEL, $insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              redo B;
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t116') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t116'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t117') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t117'} = 1;
      }
    
                $self->{parse_error}-> (type => 'in noscript:noscript');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t118') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t118'} = 1;
      }
    
                #
              }
            } elsif ($token->{tag_name} eq 'script') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t119') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t119'} = 1;
      }
    
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:script');
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t120') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t120'} = 1;
      }
    
                $self->{parse_error}-> (type => 'after head:'.$token->{tag_name});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t121') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t121'} = 1;
      }
    
              }

              ## NOTE: There is a "as if in head" code clone.
              $script_start_tag->($insert_to_current);
              pop @{$self->{open_elements}}
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              redo B;
            } elsif ($token->{tag_name} eq 'body' or
                     $token->{tag_name} eq 'frameset') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t122') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t122'} = 1;
      }
    
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:'.$token->{tag_name});
                
                ## Reprocess in the "in head" insertion mode...
                ## As if </head>
                pop @{$self->{open_elements}};
                
                ## Reprocess in the "after head" insertion mode...
              } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t124') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t124'} = 1;
      }
    
                pop @{$self->{open_elements}};
                
                ## Reprocess in the "after head" insertion mode...
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t125') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t125'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t126') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t126'} = 1;
      }
    
                $self->{insertion_mode} = IN_BODY_IM;
              } elsif ($token->{tag_name} eq 'frameset') {
                
      $Whatpm::HTML::Debug::cp_pass->('t127') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t127'} = 1;
      }
    
                $self->{insertion_mode} = IN_FRAMESET_IM;
              } else {
                die "$0: tag name: $self->{tag_name}";
              }
              $token = $self->_get_next_token;
              redo B;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t128') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t128'} = 1;
      }
    
              #
            }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
      $Whatpm::HTML::Debug::cp_pass->('t129') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t129'} = 1;
      }
    
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}-> (type => 'in noscript:/'.$token->{tag_name});
              
              ## Reprocess in the "in head" insertion mode...
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
              
      $Whatpm::HTML::Debug::cp_pass->('t130') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t130'} = 1;
      }
    
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t131') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t131'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t132') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t132'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t133') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t133'} = 1;
      }
    
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}-> (type => 'in noscript:/head');
                
                ## Reprocess in the "in head" insertion mode...
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t134') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t134'} = 1;
      }
    
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t135') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t135'} = 1;
      }
    
                #
              }
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t136') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t136'} = 1;
      }
    
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = IN_HEAD_IM;
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t137') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t137'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:noscript');
                ## Ignore the token ## ISSUE: An issue in the spec.
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t138') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t138'} = 1;
      }
    
                #
              }
            } elsif ({
                      body => 1, html => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t139') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t139'} = 1;
      }
    
                ## As if <head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t140') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t140'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t141') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t141'} = 1;
      }
    
              }
               
              #
            } elsif ({
                      p => 1, br => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t142') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t142'} = 1;
      }
    
                ## As if <head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'head']);
    
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}}, [$self->{head_element}, 'head'];

                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t143') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t143'} = 1;
      }
    
              }

              #
            } else {
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t144') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t144'} = 1;
      }
    
                #
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t145') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t145'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
            }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
      $Whatpm::HTML::Debug::cp_pass->('t146') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t146'} = 1;
      }
    
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}-> (type => 'in noscript:/'.$token->{tag_name});
              
              ## Reprocess in the "in head" insertion mode...
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
              
      $Whatpm::HTML::Debug::cp_pass->('t147') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t147'} = 1;
      }
    
              ## As if </head>
              pop @{$self->{open_elements}};

              ## Reprocess in the "after head" insertion mode...
            } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
## ISSUE: This case cannot be reached?
              
      $Whatpm::HTML::Debug::cp_pass->('t148') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t148'} = 1;
      }
    
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token ## ISSUE: An issue in the spec.
              $token = $self->_get_next_token;
              redo B;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t149') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t149'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t150') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t150'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t151') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t151'} = 1;
      }
    
                    $tn = $node->[1];
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t152') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t152'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $tn) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t153') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t153'} = 1;
      }
    
## TODO: This error type is wrong.
                    $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    redo B;
                  }
                
                
      $Whatpm::HTML::Debug::cp_pass->('t154') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t154'} = 1;
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t155') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t155'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t156') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t156'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t157') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t157'} = 1;
      }
    
## TODO: this type is wrong.
                    $self->{parse_error}-> (type => 'unmatched end tag:caption');
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    redo B;
                  }
                
                ## generate implied end tags
                if ({
                     dd => 1, dt => 1, li => 1, p => 1,

                     ## NOTE: Maybe the following elements never appear here.
                     td => 1, th => 1, tr => 1,
                     tbody => 1, tfoot => 1, thead => 1,
                    }->{$self->{open_elements}->[-1]->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t158') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t158'} = 1;
      }
    
                  unshift @{$self->{token}}, $token; # <?>
                  $token = {type => END_TAG_TOKEN, tag_name => 'caption'};
                  unshift @{$self->{token}}, $token;
                  $token = {type => END_TAG_TOKEN,
                            tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                  redo B;
                }

                if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                  
      $Whatpm::HTML::Debug::cp_pass->('t159') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t159'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->('t160') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t160'} = 1;
      }
    
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                ## reprocess
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t161') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t161'} = 1;
      }
    
                #
              }
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t162') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t162'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t163') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t163'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t164') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t164'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t165') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t165'} = 1;
      }
    
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

                     ## NOTE: Maybe the following elements never appear here.
                     tr => 1,
                     tbody => 1, tfoot => 1, thead => 1,
                    }->{$self->{open_elements}->[-1]->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t166') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t166'} = 1;
      }
    
                  unshift @{$self->{token}}, $token;
                  $token = {type => END_TAG_TOKEN,
                            tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                  redo B;
                }
                
                if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t167') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t167'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->('t168') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t168'} = 1;
      }
    
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_ROW_IM;
                
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_CAPTION_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t169') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t169'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t170') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t170'} = 1;
      }
    
                #
              }
            } elsif ($token->{tag_name} eq 'caption') {
              if ($self->{insertion_mode} == IN_CAPTION_IM) {
                ## have a table element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] eq $token->{tag_name}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t171') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t171'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t172') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t172'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t173') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t173'} = 1;
      }
    
                    $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    redo B;
                  }
                
                ## generate implied end tags
                if ({
                     dd => 1, dt => 1, li => 1, p => 1,

                     ## NOTE: The following elements never appear here, maybe.
                     td => 1, th => 1, tr => 1,
                     tbody => 1, tfoot => 1, thead => 1,
                    }->{$self->{open_elements}->[-1]->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t174') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t174'} = 1;
      }
    
                  unshift @{$self->{token}}, $token;
                  $token = {type => END_TAG_TOKEN,
                            tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                  redo B;
                }
                
                if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                  
      $Whatpm::HTML::Debug::cp_pass->('t175') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t175'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->('t176') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t176'} = 1;
      }
    
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                $token = $self->_get_next_token;
                redo B;
              } elsif ($self->{insertion_mode} == IN_CELL_IM) {
                
      $Whatpm::HTML::Debug::cp_pass->('t177') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t177'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t178') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t178'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t179') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t179'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] eq 'td' or $node->[1] eq 'th') {
                  
      $Whatpm::HTML::Debug::cp_pass->('t180') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t180'} = 1;
      }
    
                  $tn = $node->[1];
                  ## NOTE: There is exactly one |td| or |th| element
                  ## in scope in the stack of open elements by definition.
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t181') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t181'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t182') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t182'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t183') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t183'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t184') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t184'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t185') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t185'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t186') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t186'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:caption');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,

                   ## NOTE: The following elements never appear, maybe.
                   td => 1, th => 1, tr => 1,
                   tbody => 1, tfoot => 1, thead => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                
      $Whatpm::HTML::Debug::cp_pass->('t187') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t187'} = 1;
      }
    
                unshift @{$self->{token}}, $token; # </table>
                $token = {type => END_TAG_TOKEN, tag_name => 'caption'};
                unshift @{$self->{token}}, $token;
                $token = {type => END_TAG_TOKEN,
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'caption') {
                
      $Whatpm::HTML::Debug::cp_pass->('t188') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t188'} = 1;
      }
    
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t189') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t189'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t190') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t190'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t191') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t191'} = 1;
      }
    
                #
              }
            } elsif ({
                      tbody => 1, tfoot => 1,
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}} and
                     $self->{insertion_mode} == IN_CAPTION_IM) {
              
      $Whatpm::HTML::Debug::cp_pass->('t192') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t192'} = 1;
      }
    
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t193') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t193'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t194') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t194'} = 1;
      }
    
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t195') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t195'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t196') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t196'} = 1;
      }
    
                    $foster_parent_element = $parent;
                    $next_sibling = $self->{open_elements}->[$_]->[0];
                    $prev_sibling = $next_sibling->previous_sibling;
                  } else {
                    
      $Whatpm::HTML::Debug::cp_pass->('t197') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t197'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t198') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t198'} = 1;
      }
    
                $prev_sibling->manakai_append_text ($token->{data});
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t199') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t199'} = 1;
      }
    
                $foster_parent_element->insert_before
                  ($self->{document}->create_text_node ($token->{data}),
                   $next_sibling);
              }
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t200') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t200'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t201') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t201'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t202') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t202'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'missing start tag:tr');
                }
                
                ## Clear back to table body context
                while (not {
                  tbody => 1, tfoot => 1, thead => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t203') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t203'} = 1;
      }
    
                  ## ISSUE: Can this case be reached?
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                  pop @{$self->{open_elements}};
                }
                
                $self->{insertion_mode} = IN_ROW_IM;
                if ($token->{tag_name} eq 'tr') {
                  
      $Whatpm::HTML::Debug::cp_pass->('t204') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t204'} = 1;
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
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->('t205') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t205'} = 1;
      }
    
                  
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
                
      $Whatpm::HTML::Debug::cp_pass->('t206') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t206'} = 1;
      }
    
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                
      $Whatpm::HTML::Debug::cp_pass->('t207') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t207'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t208') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t208'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            html => 1,

                            ## NOTE: This element does not appear here, maybe.
                            table => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t209') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t209'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) { 
                 
      $Whatpm::HTML::Debug::cp_pass->('t210') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t210'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t211') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t211'} = 1;
      }
    
                  ## ISSUE: Can this case be reached?
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
                  pop @{$self->{open_elements}};
                }
                
                pop @{$self->{open_elements}}; # tr
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                if ($token->{tag_name} eq 'tr') {
                  
      $Whatpm::HTML::Debug::cp_pass->('t212') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t212'} = 1;
      }
    
                  ## reprocess
                  redo B;
                } else {
                  
      $Whatpm::HTML::Debug::cp_pass->('t213') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t213'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t214') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t214'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t215') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t215'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t216') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t216'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t217') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t217'} = 1;
      }
    
                  ## ISSUE: Can this state be reached?
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
                
      $Whatpm::HTML::Debug::cp_pass->('t218') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t218'} = 1;
      }
    
              }

              if ($token->{tag_name} eq 'col') {
                ## Clear back to table context
                while ($self->{open_elements}->[-1]->[1] ne 'table' and
                       $self->{open_elements}->[-1]->[1] ne 'html') {
                  
      $Whatpm::HTML::Debug::cp_pass->('t219') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t219'} = 1;
      }
    
                  ## ISSUE: Can this state be reached?
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t220') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t220'} = 1;
      }
    
                  ## ISSUE: Can this state be reached?
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t221') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t221'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          #table => 1,
                          html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t222') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t222'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t223') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t223'} = 1;
      }
    
## TODO: The following is wrong, maybe.
                $self->{parse_error}-> (type => 'unmatched end tag:table');
                ## Ignore tokens </table><table>
                $token = $self->_get_next_token;
                redo B;
              }
              
              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                   tbody => 1, tfoot=> 1, thead => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                
      $Whatpm::HTML::Debug::cp_pass->('t224') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t224'} = 1;
      }
    
                unshift @{$self->{token}}, $token; # <table>
                $token = {type => END_TAG_TOKEN, tag_name => 'table'};
                unshift @{$self->{token}}, $token;
                $token = {type => END_TAG_TOKEN,
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }

              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                
      $Whatpm::HTML::Debug::cp_pass->('t225') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t225'} = 1;
      }
    
## ISSUE: Can this case be reached?
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t226') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t226'} = 1;
      }
    
              }

              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode; 

              ## reprocess
              redo B;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t227') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t227'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t228') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t228'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t229') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t229'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t230') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t230'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t232') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t232'} = 1;
      }
    
              }

              ## Clear back to table row context
              while (not {
                tr => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                
      $Whatpm::HTML::Debug::cp_pass->('t231') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t231'} = 1;
      }
    
## ISSUE: Can this state be reached?
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t233') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t233'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t234') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t234'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t235') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t235'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t236') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t236'} = 1;
      }
    
## ISSUE: Can this state be reached?
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t237') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t237'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t238') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t238'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t239') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t239'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                  ## Ignore the token
                  $token = $self->_get_next_token;
                  redo B;
                }
                
                ## Clear back to table body context
                while (not {
                  tbody => 1, tfoot => 1, thead => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t240') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t240'} = 1;
      }
    
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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

              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] eq $token->{tag_name}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t241') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t241'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t242') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t242'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t243') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t243'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## generate implied end tags
              if ({
                   dd => 1, dt => 1, li => 1, p => 1,
                   td => 1, th => 1, tr => 1,
                   tbody => 1, tfoot=> 1, thead => 1,
                  }->{$self->{open_elements}->[-1]->[1]}) {
                
      $Whatpm::HTML::Debug::cp_pass->('t244') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t244'} = 1;
      }
    
## ISSUE: Can this case be reached?
                unshift @{$self->{token}}, $token;
                $token = {type => END_TAG_TOKEN,
                          tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
                redo B;
              }
              
              if ($self->{open_elements}->[-1]->[1] ne 'table') {
                
      $Whatpm::HTML::Debug::cp_pass->('t245') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t245'} = 1;
      }
    
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t246') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t246'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t247') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t247'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t248') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t248'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t249') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t249'} = 1;
      }
    
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
                    
      $Whatpm::HTML::Debug::cp_pass->('t250') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t250'} = 1;
      }
    
                    $i = $_;
                    last INSCOPE;
                  } elsif ({
                            table => 1, html => 1,
                           }->{$node->[1]}) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t251') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t251'} = 1;
      }
    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
      $Whatpm::HTML::Debug::cp_pass->('t252') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t252'} = 1;
      }
    
                    $self->{parse_error}-> (type => 'unmatched end tag:tr');
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    redo B;
                  }
                
                ## Clear back to table row context
                while (not {
                  tr => 1, html => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t253') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t253'} = 1;
      }
    
## ISSUE: Can this case be reached?
                  $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t254') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t254'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t255') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t255'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t256') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t256'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }

              ## Clear back to table body context
              while (not {
                tbody => 1, tfoot => 1, thead => 1, html => 1,
              }->{$self->{open_elements}->[-1]->[1]}) {
                
      $Whatpm::HTML::Debug::cp_pass->('t257') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t257'} = 1;
      }
    
## ISSUE: Can this case be reached?
                $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
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
              
      $Whatpm::HTML::Debug::cp_pass->('t258') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t258'} = 1;
      }
    
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t259') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t259'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t260') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t260'} = 1;
      }
    
                $token = $self->_get_next_token;
                redo B;
              }
            }
            
            
      $Whatpm::HTML::Debug::cp_pass->('t261') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t261'} = 1;
      }
    
            #
          } elsif ($token->{type} == START_TAG_TOKEN) {
            if ($token->{tag_name} eq 'col') {
              
      $Whatpm::HTML::Debug::cp_pass->('t262') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t262'} = 1;
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
  
              pop @{$self->{open_elements}};
              $token = $self->_get_next_token;
              redo B;
            } else { 
              
      $Whatpm::HTML::Debug::cp_pass->('t263') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t263'} = 1;
      }
    
              #
            }
          } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'colgroup') {
              if ($self->{open_elements}->[-1]->[1] eq 'html') {
                
      $Whatpm::HTML::Debug::cp_pass->('t264') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t264'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:colgroup');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t265') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t265'} = 1;
      }
    
                pop @{$self->{open_elements}}; # colgroup
                $self->{insertion_mode} = IN_TABLE_IM;
                $token = $self->_get_next_token;
                redo B;             
              }
            } elsif ($token->{tag_name} eq 'col') {
              
      $Whatpm::HTML::Debug::cp_pass->('t266') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t266'} = 1;
      }
    
              $self->{parse_error}-> (type => 'unmatched end tag:col');
              ## Ignore the token
              $token = $self->_get_next_token;
              redo B;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t267') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t267'} = 1;
      }
    
              # 
            }
          } else {
            die "$0: $token->{type}: Unknown token type";
          }

          ## As if </colgroup>
          if ($self->{open_elements}->[-1]->[1] eq 'html') {
            
      $Whatpm::HTML::Debug::cp_pass->('t269') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t269'} = 1;
      }
    
            $self->{parse_error}-> (type => 'unmatched end tag:colgroup');
            ## Ignore the token
            $token = $self->_get_next_token;
            redo B;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t270') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t270'} = 1;
      }
    
            pop @{$self->{open_elements}}; # colgroup
            $self->{insertion_mode} = IN_TABLE_IM;
            ## reprocess
            redo B;
          }
    } elsif ($self->{insertion_mode} == IN_SELECT_IM) {
      if ($token->{type} == CHARACTER_TOKEN) {
        
      $Whatpm::HTML::Debug::cp_pass->('t271') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t271'} = 1;
      }
    
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
            if ($token->{tag_name} eq 'option') {
              if ($self->{open_elements}->[-1]->[1] eq 'option') {
                
      $Whatpm::HTML::Debug::cp_pass->('t272') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t272'} = 1;
      }
    
                ## As if </option>
                pop @{$self->{open_elements}};
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t273') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t273'} = 1;
      }
    
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
                
      $Whatpm::HTML::Debug::cp_pass->('t274') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t274'} = 1;
      }
    
                ## As if </option>
                pop @{$self->{open_elements}};
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t275') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t275'} = 1;
      }
    
              }

              if ($self->{open_elements}->[-1]->[1] eq 'optgroup') {
                
      $Whatpm::HTML::Debug::cp_pass->('t276') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t276'} = 1;
      }
    
                ## As if </optgroup>
                pop @{$self->{open_elements}};
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t277') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t277'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t278') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t278'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t279') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t279'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t280') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t280'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:select');
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              
      $Whatpm::HTML::Debug::cp_pass->('t281') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t281'} = 1;
      }
    
              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              $token = $self->_get_next_token;
              redo B;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t282') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t282'} = 1;
      }
    
          $self->{parse_error}-> (type => 'in select:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'optgroup') {
              if ($self->{open_elements}->[-1]->[1] eq 'option' and
                  $self->{open_elements}->[-2]->[1] eq 'optgroup') {
                
      $Whatpm::HTML::Debug::cp_pass->('t283') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t283'} = 1;
      }
    
                ## As if </option>
                splice @{$self->{open_elements}}, -2;
              } elsif ($self->{open_elements}->[-1]->[1] eq 'optgroup') {
                
      $Whatpm::HTML::Debug::cp_pass->('t284') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t284'} = 1;
      }
    
                pop @{$self->{open_elements}};
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t285') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t285'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
              }
              $token = $self->_get_next_token;
              redo B;
            } elsif ($token->{tag_name} eq 'option') {
              if ($self->{open_elements}->[-1]->[1] eq 'option') {
                
      $Whatpm::HTML::Debug::cp_pass->('t286') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t286'} = 1;
      }
    
                pop @{$self->{open_elements}};
              } else {
                
      $Whatpm::HTML::Debug::cp_pass->('t287') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t287'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t288') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t288'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t289') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t289'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t290') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t290'} = 1;
      }
    
                $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
                ## Ignore the token
                $token = $self->_get_next_token;
                redo B;
              }
              
              
      $Whatpm::HTML::Debug::cp_pass->('t291') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t291'} = 1;
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t292') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t292'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
                  
      $Whatpm::HTML::Debug::cp_pass->('t293') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t293'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t294') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t294'} = 1;
      }
    
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
                  
      $Whatpm::HTML::Debug::cp_pass->('t295') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t295'} = 1;
      }
    
                  $i = $_;
                  last INSCOPE;
                } elsif ({
                          table => 1, html => 1,
                         }->{$node->[1]}) {
## ISSUE: Can this state be reached?
                  
      $Whatpm::HTML::Debug::cp_pass->('t296') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t296'} = 1;
      }
    
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
      $Whatpm::HTML::Debug::cp_pass->('t297') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t297'} = 1;
      }
    
## TODO: The following error type is correct?
                $self->{parse_error}-> (type => 'unmatched end tag:select');
                ## Ignore the </select> token
                $token = $self->_get_next_token; ## TODO: ok?
                redo B;
              }
              
              
      $Whatpm::HTML::Debug::cp_pass->('t298') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t298'} = 1;
      }
    
              splice @{$self->{open_elements}}, $i;

              $self->_reset_insertion_mode;

              ## reprocess
              redo B;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t299') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t299'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t300') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t300'} = 1;
      }
    
            $token = $self->_get_next_token;
            redo B;
          }
        }
        
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t301') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t301'} = 1;
      }
    
          $self->{parse_error}-> (type => 'after html:#character');

          ## Reprocess in the "main" phase, "after body" insertion mode...
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t302') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t302'} = 1;
      }
    
        }
        
        ## "after body" insertion mode
        $self->{parse_error}-> (type => 'after body:#character');

        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        redo B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t303') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t303'} = 1;
      }
    
          $self->{parse_error}-> (type => 'after html:'.$token->{tag_name});
          
          ## Reprocess in the "main" phase, "after body" insertion mode...
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t304') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t304'} = 1;
      }
    
        }

        ## "after body" insertion mode
        $self->{parse_error}-> (type => 'after body:'.$token->{tag_name});

        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        redo B;
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t305') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t305'} = 1;
      }
    
          $self->{parse_error}-> (type => 'after html:/'.$token->{tag_name});
          
          $self->{insertion_mode} = AFTER_BODY_IM;
          ## Reprocess in the "main" phase, "after body" insertion mode...
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t306') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t306'} = 1;
      }
    
        }

        ## "after body" insertion mode
        if ($token->{tag_name} eq 'html') {
          if (defined $self->{inner_html_node}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t307') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t307'} = 1;
      }
    
            $self->{parse_error}-> (type => 'unmatched end tag:html');
            ## Ignore the token
            $token = $self->_get_next_token;
            redo B;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t308') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t308'} = 1;
      }
    
            $self->{insertion_mode} = AFTER_HTML_BODY_IM;
            $token = $self->_get_next_token;
            redo B;
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t309') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t309'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t310') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t310'} = 1;
      }
    
            $token = $self->_get_next_token;
            redo B;
          }
        }
        
        if ($token->{data} =~ s/^[^\x09\x0A\x0B\x0C\x20]+//) {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
      $Whatpm::HTML::Debug::cp_pass->('t311') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t311'} = 1;
      }
    
            $self->{parse_error}-> (type => 'in frameset:#character');
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
      $Whatpm::HTML::Debug::cp_pass->('t312') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t312'} = 1;
      }
    
            $self->{parse_error}-> (type => 'after frameset:#character');
          } else { # "after html frameset"
            
      $Whatpm::HTML::Debug::cp_pass->('t313') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t313'} = 1;
      }
    
            $self->{parse_error}-> (type => 'after html:#character');

            $self->{insertion_mode} = AFTER_FRAMESET_IM;
            ## Reprocess in the "main" phase, "after frameset"...
            $self->{parse_error}-> (type => 'after frameset:#character');
          }
          
          ## Ignore the token.
          if (length $token->{data}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t314') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t314'} = 1;
      }
    
            ## reprocess the rest of characters
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t315') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t315'} = 1;
      }
    
            $token = $self->_get_next_token;
          }
          redo B;
        }
        
        die qq[$0: Character "$token->{data}"];
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t316') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t316'} = 1;
      }
    
          $self->{parse_error}-> (type => 'after html:'.$token->{tag_name});

          $self->{insertion_mode} = AFTER_FRAMESET_IM;
          ## Process in the "main" phase, "after frameset" insertion mode...
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t317') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t317'} = 1;
      }
    
        } 

        if ($token->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t318') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t318'} = 1;
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
        } elsif ($token->{tag_name} eq 'frame' and
                 $self->{insertion_mode} == IN_FRAMESET_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t319') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t319'} = 1;
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
  
          pop @{$self->{open_elements}};
          $token = $self->_get_next_token;
          redo B;
        } elsif ($token->{tag_name} eq 'noframes') {
          
      $Whatpm::HTML::Debug::cp_pass->('t320') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t320'} = 1;
      }
    
          ## NOTE: As if in body.
          $parse_rcdata->(CDATA_CONTENT_MODEL, $insert_to_current);
          redo B;
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
      $Whatpm::HTML::Debug::cp_pass->('t321') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t321'} = 1;
      }
    
            $self->{parse_error}-> (type => 'in frameset:'.$token->{tag_name});
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t322') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t322'} = 1;
      }
    
            $self->{parse_error}-> (type => 'after frameset:'.$token->{tag_name});
          }
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t323') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t323'} = 1;
      }
    
          $self->{parse_error}-> (type => 'after html:/'.$token->{tag_name});

          $self->{insertion_mode} = AFTER_FRAMESET_IM;
          ## Process in the "main" phase, "after frameset" insertion mode...
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t324') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t324'} = 1;
      }
    
        }

        if ($token->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          if ($self->{open_elements}->[-1]->[1] eq 'html' and
              @{$self->{open_elements}} == 1) {
            
      $Whatpm::HTML::Debug::cp_pass->('t325') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t325'} = 1;
      }
    
            $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
            ## Ignore the token
            $token = $self->_get_next_token;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t326') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t326'} = 1;
      }
    
            pop @{$self->{open_elements}};
            $token = $self->_get_next_token;
          }

          if (not defined $self->{inner_html_node} and
              $self->{open_elements}->[-1]->[1] ne 'frameset') {
            
      $Whatpm::HTML::Debug::cp_pass->('t327') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t327'} = 1;
      }
    
            $self->{insertion_mode} = AFTER_FRAMESET_IM;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t328') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t328'} = 1;
      }
    
          }
          redo B;
        } elsif ($token->{tag_name} eq 'html' and
                 $self->{insertion_mode} == AFTER_FRAMESET_IM) {
          
      $Whatpm::HTML::Debug::cp_pass->('t329') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t329'} = 1;
      }
    
          $self->{insertion_mode} = AFTER_HTML_FRAMESET_IM;
          $token = $self->_get_next_token;
          redo B;
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
      $Whatpm::HTML::Debug::cp_pass->('t330') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t330'} = 1;
      }
    
            $self->{parse_error}-> (type => 'in frameset:/'.$token->{tag_name});
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t331') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t331'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t332') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t332'} = 1;
      }
    
        ## NOTE: This is an "as if in head" code clone
        $script_start_tag->($insert);
        redo B;
      } elsif ($token->{tag_name} eq 'style') {
        
      $Whatpm::HTML::Debug::cp_pass->('t333') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t333'} = 1;
      }
    
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->(CDATA_CONTENT_MODEL, $insert);
        redo B;
      } elsif ({
                base => 1, link => 1,
               }->{$token->{tag_name}}) {
        
      $Whatpm::HTML::Debug::cp_pass->('t334') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t334'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t335') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t335'} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->('t336') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t336'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t337') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t337'} = 1;
      }
    
            $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                ->set_user_data (manakai_has_reference =>
                                     $token->{attributes}->{charset}
                                         ->{has_reference});
          }
          if ($token->{attributes}->{content}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t338') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t338'} = 1;
      }
    
            $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                ->set_user_data (manakai_has_reference =>
                                     $token->{attributes}->{content}
                                         ->{has_reference});
          }
        }

        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'title') {
        
      $Whatpm::HTML::Debug::cp_pass->('t341') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t341'} = 1;
      }
    
        $self->{parse_error}-> (type => 'in body:title');
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->(RCDATA_CONTENT_MODEL, sub {
          if (defined $self->{head_element}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t339') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t339'} = 1;
      }
    
            $self->{head_element}->append_child ($_[0]);
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t340') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t340'} = 1;
      }
    
            $insert->($_[0]);
          }
        });
        redo B;
      } elsif ($token->{tag_name} eq 'body') {
        $self->{parse_error}-> (type => 'in body:body');
              
        if (@{$self->{open_elements}} == 1 or
            $self->{open_elements}->[1]->[1] ne 'body') {
          
      $Whatpm::HTML::Debug::cp_pass->('t342') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t342'} = 1;
      }
    
          ## Ignore the token
        } else {
          my $body_el = $self->{open_elements}->[1]->[0];
          for my $attr_name (keys %{$token->{attributes}}) {
            unless ($body_el->has_attribute_ns (undef, $attr_name)) {
              
      $Whatpm::HTML::Debug::cp_pass->('t343') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t343'} = 1;
      }
    
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
                div => 1, dl => 1, fieldset => 1, listing => 1,
                menu => 1, ol => 1, p => 1, ul => 1,
                pre => 1,
               }->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
      $Whatpm::HTML::Debug::cp_pass->('t344') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t344'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t345') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t345'} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->('t346') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t346'} = 1;
      }
    
              $token = $self->_get_next_token;
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t349') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t349'} = 1;
      }
    
            }
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t348') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t348'} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t347') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t347'} = 1;
      }
    
          $token = $self->_get_next_token;
        }
        redo B;
      } elsif ($token->{tag_name} eq 'form') {
        if (defined $self->{form_element}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t350') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t350'} = 1;
      }
    
          $self->{parse_error}-> (type => 'in form:form');
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        } else {
          ## has a p element in scope
          INSCOPE: for (reverse @{$self->{open_elements}}) {
            if ($_->[1] eq 'p') {
              
      $Whatpm::HTML::Debug::cp_pass->('t351') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t351'} = 1;
      }
    
              unshift @{$self->{token}}, $token;
              $token = {type => END_TAG_TOKEN, tag_name => 'p'};
              redo B;
            } elsif ({
                      table => 1, caption => 1, td => 1, th => 1,
                      button => 1, marquee => 1, object => 1, html => 1,
                     }->{$_->[1]}) {
              
      $Whatpm::HTML::Debug::cp_pass->('t352') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t352'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t353') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t353'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t354') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t354'} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->('t355') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t355'} = 1;
      }
    
              $self->{parse_error}-> (type => 'end tag missing:'.
                              $self->{open_elements}->[-1]->[1]);
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t356') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t356'} = 1;
      }
    
            }
            splice @{$self->{open_elements}}, $i;
            last LI;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t357') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t357'} = 1;
      }
    
          }
          
          ## Step 3
          if (not $formatting_category->{$node->[1]} and
              #not $phrasing_category->{$node->[1]} and
              ($special_category->{$node->[1]} or
               $scoping_category->{$node->[1]}) and
              $node->[1] ne 'address' and $node->[1] ne 'div') {
            
      $Whatpm::HTML::Debug::cp_pass->('t358') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t358'} = 1;
      }
    
            last LI;
          }
          
          
      $Whatpm::HTML::Debug::cp_pass->('t359') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t359'} = 1;
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
            
      $Whatpm::HTML::Debug::cp_pass->('t360') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t360'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t361') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t361'} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->('t362') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t362'} = 1;
      }
    
              $self->{parse_error}-> (type => 'end tag missing:'.
                              $self->{open_elements}->[-1]->[1]);
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t363') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t363'} = 1;
      }
    
            }
            splice @{$self->{open_elements}}, $i;
            last LI;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t364') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t364'} = 1;
      }
    
          }
          
          ## Step 3
          if (not $formatting_category->{$node->[1]} and
              #not $phrasing_category->{$node->[1]} and
              ($special_category->{$node->[1]} or
               $scoping_category->{$node->[1]}) and
              $node->[1] ne 'address' and $node->[1] ne 'div') {
            
      $Whatpm::HTML::Debug::cp_pass->('t365') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t365'} = 1;
      }
    
            last LI;
          }
          
          
      $Whatpm::HTML::Debug::cp_pass->('t366') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t366'} = 1;
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
            
      $Whatpm::HTML::Debug::cp_pass->('t367') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t367'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t368') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t368'} = 1;
      }
    
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
      } elsif ({
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq 'p') {
            
      $Whatpm::HTML::Debug::cp_pass->('t369') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t369'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t370') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t370'} = 1;
      }
    
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
        redo B;
      } elsif ($token->{tag_name} eq 'a') {
        AFE: for my $i (reverse 0..$#$active_formatting_elements) {
          my $node = $active_formatting_elements->[$i];
          if ($node->[1] eq 'a') {
            
      $Whatpm::HTML::Debug::cp_pass->('t371') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t371'} = 1;
      }
    
            $self->{parse_error}-> (type => 'in a:a');
            
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'a'};
            $formatting_end_tag->($token->{tag_name});
            
            AFE2: for (reverse 0..$#$active_formatting_elements) {
              if ($active_formatting_elements->[$_]->[0] eq $node->[0]) {
                
      $Whatpm::HTML::Debug::cp_pass->('t372') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t372'} = 1;
      }
    
                splice @$active_formatting_elements, $_, 1;
                last AFE2;
              }
            } # AFE2
            OE: for (reverse 0..$#{$self->{open_elements}}) {
              if ($self->{open_elements}->[$_]->[0] eq $node->[0]) {
                
      $Whatpm::HTML::Debug::cp_pass->('t373') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t373'} = 1;
      }
    
                splice @{$self->{open_elements}}, $_, 1;
                last OE;
              }
            } # OE
            last AFE;
          } elsif ($node->[0] eq '#marker') {
            
      $Whatpm::HTML::Debug::cp_pass->('t374') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t374'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t375') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t375'} = 1;
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
  
        push @$active_formatting_elements, $self->{open_elements}->[-1];
        
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'nobr') {
        $reconstruct_active_formatting_elements->($insert_to_current);

        ## has a |nobr| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq 'nobr') {
            
      $Whatpm::HTML::Debug::cp_pass->('t376') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t376'} = 1;
      }
    
            $self->{parse_error}-> (type => 'in nobr:nobr');
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'nobr'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t377') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t377'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t378') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t378'} = 1;
      }
    
            $self->{parse_error}-> (type => 'in button:button');
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'button'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t379') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t379'} = 1;
      }
    
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
        redo B;
      } elsif ($token->{tag_name} eq 'marquee' or 
               $token->{tag_name} eq 'object') {
        
      $Whatpm::HTML::Debug::cp_pass->('t380') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t380'} = 1;
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
  
        push @$active_formatting_elements, ['#marker', ''];
        
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'xmp') {
        
      $Whatpm::HTML::Debug::cp_pass->('t381') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t381'} = 1;
      }
    
        $reconstruct_active_formatting_elements->($insert_to_current);
        $parse_rcdata->(CDATA_CONTENT_MODEL, $insert);
        redo B;
      } elsif ($token->{tag_name} eq 'table') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] eq 'p') {
            
      $Whatpm::HTML::Debug::cp_pass->('t382') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t382'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t383') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t383'} = 1;
      }
    
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
          
      $Whatpm::HTML::Debug::cp_pass->('t384') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t384'} = 1;
      }
    
          $self->{parse_error}-> (type => 'image');
          $token->{tag_name} = 'img';
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t385') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t385'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t386') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t386'} = 1;
      }
    
            unshift @{$self->{token}}, $token;
            $token = {type => END_TAG_TOKEN, tag_name => 'p'};
            redo B;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$_->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t387') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t387'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t388') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t388'} = 1;
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
  
        ## TODO: associate with $self->{form_element} if defined
        pop @{$self->{open_elements}};
        
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'isindex') {
        $self->{parse_error}-> (type => 'isindex');
        
        if (defined $self->{form_element}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t389') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t389'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t390') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t390'} = 1;
      }
    
            push @tokens, {type => CHARACTER_TOKEN, data => $prompt_attr->{value}};
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t391') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t391'} = 1;
      }
    
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
            
      $Whatpm::HTML::Debug::cp_pass->('t392') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t392'} = 1;
      }
    
            $token = $self->_get_next_token;
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t393') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t393'} = 1;
      }
    
          }
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t394') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t394'} = 1;
      }
    
        }
        while ($token->{type} == CHARACTER_TOKEN) {
          
      $Whatpm::HTML::Debug::cp_pass->('t395') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t395'} = 1;
      }
    
          $text .= $token->{data};
          $token = $self->_get_next_token;
        }
        if (length $text) {
          
      $Whatpm::HTML::Debug::cp_pass->('t396') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t396'} = 1;
      }
    
          $el->manakai_append_text ($text);
        }
        
        $self->{content_model} = PCDATA_CONTENT_MODEL;
        
        if ($token->{type} == END_TAG_TOKEN and
            $token->{tag_name} eq $tag_name) {
          
      $Whatpm::HTML::Debug::cp_pass->('t397') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t397'} = 1;
      }
    
          ## Ignore the token
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t398') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t398'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t399') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t399'} = 1;
      }
    
        ## NOTE: There is an "as if in body" code clone.
        $parse_rcdata->(CDATA_CONTENT_MODEL, $insert);
        redo B;
      } elsif ($token->{tag_name} eq 'select') {
        
      $Whatpm::HTML::Debug::cp_pass->('t400') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t400'} = 1;
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
  
        
        $self->{insertion_mode} = IN_SELECT_IM;
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
               }->{$token->{tag_name}}) {
        
      $Whatpm::HTML::Debug::cp_pass->('t401') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t401'} = 1;
      }
    
        $self->{parse_error}-> (type => 'in body:'.$token->{tag_name});
        ## Ignore the token
        $token = $self->_get_next_token;
        redo B;
        
        ## ISSUE: An issue on HTML5 new elements in the spec.
      } else {
        
      $Whatpm::HTML::Debug::cp_pass->('t402') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t402'} = 1;
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
              
      $Whatpm::HTML::Debug::cp_pass->('t403') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t403'} = 1;
      }
    
              $self->{parse_error}-> (type => 'not closed:'.$_->[1]);
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t404') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t404'} = 1;
      }
    
            }
          }

          $self->{insertion_mode} = AFTER_BODY_IM;
          $token = $self->_get_next_token;
          redo B;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t405') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t405'} = 1;
      }
    
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
        }
      } elsif ($token->{tag_name} eq 'html') {
        if (@{$self->{open_elements}} > 1 and $self->{open_elements}->[1]->[1] eq 'body') {
          ## ISSUE: There is an issue in the spec.
          if ($self->{open_elements}->[-1]->[1] ne 'body') {
            
      $Whatpm::HTML::Debug::cp_pass->('t406') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t406'} = 1;
      }
    
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[1]->[1]);
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t407') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t407'} = 1;
      }
    
          }
          $self->{insertion_mode} = AFTER_BODY_IM;
          ## reprocess
          redo B;
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t408') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t408'} = 1;
      }
    
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          ## Ignore the token
          $token = $self->_get_next_token;
          redo B;
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
                 tbody => 1, tfoot=> 1, thead => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              
      $Whatpm::HTML::Debug::cp_pass->('t409') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t409'} = 1;
      }
    
              unshift @{$self->{token}}, $token;
              $token = {type => END_TAG_TOKEN,
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
              redo B;
            }
            
            
      $Whatpm::HTML::Debug::cp_pass->('t410') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t410'} = 1;
      }
    
            $i = $_;
            last INSCOPE unless $token->{tag_name} eq 'p';
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t411') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t411'} = 1;
      }
    
            last INSCOPE;
          }
        } # INSCOPE
        
        if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
          if (defined $i) {
            
      $Whatpm::HTML::Debug::cp_pass->('t412') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t412'} = 1;
      }
    
            $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
          } else {
            
      $Whatpm::HTML::Debug::cp_pass->('t413') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t413'} = 1;
      }
    
            $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
          }
        }
        
        if (defined $i) {
          
      $Whatpm::HTML::Debug::cp_pass->('t414') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t414'} = 1;
      }
    
          splice @{$self->{open_elements}}, $i;
        } elsif ($token->{tag_name} eq 'p') {
          
      $Whatpm::HTML::Debug::cp_pass->('t415') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t415'} = 1;
      }
    
          ## As if <p>, then reprocess the current token
          my $el;
          
      $el = $self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef,  'p']);
    
          $insert->($el);
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t416') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t416'} = 1;
      }
    
        }
        $clear_up_to_marker->()
          if {
            button => 1, marquee => 1, object => 1,
          }->{$token->{tag_name}};
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'form') {
        ## has an element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] eq $token->{tag_name}) {
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,

                 ## NOTE: The following elements never appear here, maybe.
                 td => 1, th => 1, tr => 1,
                 tbody => 1, tfoot => 1, thead => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              
      $Whatpm::HTML::Debug::cp_pass->('t417') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t417'} = 1;
      }
    
              unshift @{$self->{token}}, $token;
              $token = {type => END_TAG_TOKEN,
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
              redo B;
            }
            
            
      $Whatpm::HTML::Debug::cp_pass->('t418') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t418'} = 1;
      }
    
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t419') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t419'} = 1;
      }
    
            last INSCOPE;
          }
        } # INSCOPE
        
        if ($self->{open_elements}->[-1]->[1] eq $token->{tag_name}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t420') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t420'} = 1;
      }
    
          pop @{$self->{open_elements}};
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t421') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t421'} = 1;
      }
    
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        }

        undef $self->{form_element};
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
            ## generate implied end tags
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                 tbody => 1, tfoot=> 1, thead => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              
      $Whatpm::HTML::Debug::cp_pass->('t422') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t422'} = 1;
      }
    
              unshift @{$self->{token}}, $token;
              $token = {type => END_TAG_TOKEN,
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
              redo B;
            }

            
      $Whatpm::HTML::Debug::cp_pass->('t423') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t423'} = 1;
      }
    
            $i = $_;
            last INSCOPE;
          } elsif ({
                    table => 1, caption => 1, td => 1, th => 1,
                    button => 1, marquee => 1, object => 1, html => 1,
                   }->{$node->[1]}) {
            
      $Whatpm::HTML::Debug::cp_pass->('t424') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t424'} = 1;
      }
    
            last INSCOPE;
          }
        } # INSCOPE
        
        if ($self->{open_elements}->[-1]->[1] ne $token->{tag_name}) {
          
      $Whatpm::HTML::Debug::cp_pass->('t425') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t425'} = 1;
      }
    
          $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
        } else {
          
      $Whatpm::HTML::Debug::cp_pass->('t426') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t426'} = 1;
      }
    
        }
        
        splice @{$self->{open_elements}}, $i if defined $i;
        $token = $self->_get_next_token;
        redo B;
      } elsif ({
                a => 1,
                b => 1, big => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strile => 1,
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        
      $Whatpm::HTML::Debug::cp_pass->('t427') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t427'} = 1;
      }
    
        $formatting_end_tag->($token->{tag_name});
        redo B;
      } elsif ($token->{tag_name} eq 'br') {
        
      $Whatpm::HTML::Debug::cp_pass->('t428') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t428'} = 1;
      }
    
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
        
      $Whatpm::HTML::Debug::cp_pass->('t429') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t429'} = 1;
      }
    
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
            if ({
                 dd => 1, dt => 1, li => 1, p => 1,
                 td => 1, th => 1, tr => 1,
                 tbody => 1, tfoot => 1, thead => 1,
                }->{$self->{open_elements}->[-1]->[1]}) {
              
      $Whatpm::HTML::Debug::cp_pass->('t430') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t430'} = 1;
      }
    
              ## ISSUE: Can this case be reached?
              unshift @{$self->{token}}, $token;
              $token = {type => END_TAG_TOKEN,
                        tag_name => $self->{open_elements}->[-1]->[1]}; # MUST
              redo B;
            }
        
            ## Step 2
            if ($token->{tag_name} ne $self->{open_elements}->[-1]->[1]) {
              
      $Whatpm::HTML::Debug::cp_pass->('t431') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t431'} = 1;
      }
    
              ## NOTE: <x><y></x>
              $self->{parse_error}-> (type => 'not closed:'.$self->{open_elements}->[-1]->[1]);
            } else {
              
      $Whatpm::HTML::Debug::cp_pass->('t432') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t432'} = 1;
      }
    
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
              
      $Whatpm::HTML::Debug::cp_pass->('t433') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t433'} = 1;
      }
    
              $self->{parse_error}-> (type => 'unmatched end tag:'.$token->{tag_name});
              ## Ignore the token
              $token = $self->_get_next_token;
              last S2;
            }

            
      $Whatpm::HTML::Debug::cp_pass->('t434') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'t434'} = 1;
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

  ## NOTE: The "trailing end" phase in HTML5 is split into
  ## two insertion modes: "after html body" and "after html frameset".
  ## NOTE: States in the main stage is preserved while
  ## the parser stays in the trailing end phase. # MUST

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

    ## Step 9 # MUST
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
        
      $Whatpm::HTML::Debug::cp_pass->('i1') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'i1'} = 1;
      }
    
      } elsif ($self->{next_char} == 0x000D) { # CR
        $i++ if substr ($$s, $i, 1) eq "\x0A";
        $self->{next_char} = 0x000A; # LF # MUST
        $line++;
        $column = 0;
        
      $Whatpm::HTML::Debug::cp_pass->('i2') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'i2'} = 1;
      }
    
      } elsif ($self->{next_char} > 0x10FFFF) {
        $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
        
      $Whatpm::HTML::Debug::cp_pass->('i3') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'i3'} = 1;
      }
    
      } elsif ($self->{next_char} == 0x0000) { # NULL
        
      $Whatpm::HTML::Debug::cp_pass->('i4') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'i4'} = 1;
      }
    
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
          if ($anode->manakai_local_name eq 'form') {
            
      $Whatpm::HTML::Debug::cp_pass->('i5') if $Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        $Whatpm::HTML::Debug::cp->{'i5'} = 1;
      }
    
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

package Whatpm::HTML::RestartParser;
push our @ISA, 'Error';

1;
# $Date: 2008/03/05 13:07:01 $
