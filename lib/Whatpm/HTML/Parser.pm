package Whatpm::HTML::Parser; # -*- Perl -*-
use strict;
#use warnings;
no warnings 'utf8';
our $VERSION = '1.0';
use Encode;
use Whatpm::HTML::Defs;
use Whatpm::HTML::Tokenizer;
push our @ISA, qw(Whatpm::HTML::Tokenizer);



use Whatpm::HTML::Tokenizer;

## Namespace URLs

sub HTML_NS () { q<http://www.w3.org/1999/xhtml> }
sub MML_NS () { q<http://www.w3.org/1998/Math/MathML> }
sub SVG_NS () { q<http://www.w3.org/2000/svg> }

## Element categories

## Bits 14-18
sub BUTTON_SCOPING_EL () { 0b1_000000000000000000 } ## Special
sub SPECIAL_EL () { 0b1_00000000000000000 }         ## Special
sub SCOPING_EL () { 0b1_0000000000000000 }          ## Special
sub FORMATTING_EL () { 0b1_000000000000000 }        ## Formatting
sub PHRASING_EL () { 0b1_00000000000000 }           ## Ordinary

## Bits 10-13
sub SVG_EL () { 0b1_0000000000000 }
sub MML_EL () { 0b1_000000000000 }
#sub FOREIGN_EL () { 0b1_00000000000 } # see Whatpm::HTML::Tokenizer
sub FOREIGN_FLOW_CONTENT_EL () { 0b1_0000000000 }

## Bits 6-9
sub TABLE_SCOPING_EL () { 0b1_000000000 }
sub TABLE_ROWS_SCOPING_EL () { 0b1_00000000 }
sub TABLE_ROW_SCOPING_EL () { 0b1_0000000 }
sub TABLE_ROWS_EL () { 0b1_000000 }

## Bit 5
sub ADDRESS_DIV_P_EL () { 0b1_00000 }

## NOTE: Used in </body> and EOF algorithms.
## Bit 4
sub ALL_END_TAG_OPTIONAL_EL () { 0b1_0000 }

## NOTE: Used in "generate implied end tags" algorithm.
## NOTE: There is a code where a modified version of
## END_TAG_OPTIONAL_EL is used in "generate implied end tags"
## implementation (search for the algorithm name).
## Bit 3
sub END_TAG_OPTIONAL_EL () { 0b1_000 }

## Bits 0-2

sub MISC_SPECIAL_EL () { SPECIAL_EL | 0b000 }
sub FORM_EL () { SPECIAL_EL | 0b001 }
sub FRAMESET_EL () { SPECIAL_EL | 0b010 }
sub HEADING_EL () { SPECIAL_EL | 0b011 }
sub SELECT_EL () { SPECIAL_EL | 0b100 }
sub SCRIPT_EL () { SPECIAL_EL | 0b101 }
sub BUTTON_EL () { SPECIAL_EL | BUTTON_SCOPING_EL | 0b110 }

sub ADDRESS_DIV_EL () { SPECIAL_EL | ADDRESS_DIV_P_EL | 0b001 }
sub BODY_EL () { SPECIAL_EL | ALL_END_TAG_OPTIONAL_EL | 0b001 }

sub DTDD_EL () {
  SPECIAL_EL |
  END_TAG_OPTIONAL_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b010
}
sub LI_EL () {
  SPECIAL_EL |
  END_TAG_OPTIONAL_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b100
}
sub P_EL () {
  SPECIAL_EL |
  ADDRESS_DIV_P_EL |
  END_TAG_OPTIONAL_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b001
}

sub TABLE_ROW_EL () {
  SPECIAL_EL |
  TABLE_ROWS_EL |
  TABLE_ROW_SCOPING_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b001
}
sub TABLE_ROW_GROUP_EL () {
  SPECIAL_EL |
  TABLE_ROWS_EL |
  TABLE_ROWS_SCOPING_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b001
}

sub MISC_SCOPING_EL () { SCOPING_EL | BUTTON_SCOPING_EL | 0b000 }
sub CAPTION_EL () { SCOPING_EL | BUTTON_SCOPING_EL | 0b010 }
sub HTML_EL () {
  SCOPING_EL |
  BUTTON_SCOPING_EL |
  TABLE_SCOPING_EL |
  TABLE_ROWS_SCOPING_EL |
  TABLE_ROW_SCOPING_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b001
}
sub TABLE_EL () {
  SCOPING_EL |
  BUTTON_SCOPING_EL |
  TABLE_ROWS_EL |
  TABLE_SCOPING_EL |
  0b001
}
sub TABLE_CELL_EL () {
  SCOPING_EL |
  BUTTON_SCOPING_EL |
  ALL_END_TAG_OPTIONAL_EL |
  0b001
}

sub MISC_FORMATTING_EL () { FORMATTING_EL | 0b000 }
sub A_EL () { FORMATTING_EL | 0b001 }
sub NOBR_EL () { FORMATTING_EL | 0b010 }

sub RUBY_EL () { PHRASING_EL | 0b001 }

## NOTE: These elements are not included in |ALL_END_TAG_OPTIONAL_EL|.
sub OPTGROUP_EL () { PHRASING_EL | END_TAG_OPTIONAL_EL | 0b001 }
sub OPTION_EL () { PHRASING_EL | END_TAG_OPTIONAL_EL | 0b010 }
sub RUBY_COMPONENT_EL () { PHRASING_EL | END_TAG_OPTIONAL_EL | 0b100 }

## "MathML text integration point" elements.
sub MML_TEXT_INTEGRATION_EL () {
  MML_EL |
  SCOPING_EL |
  BUTTON_SCOPING_EL |
  FOREIGN_EL |
  FOREIGN_FLOW_CONTENT_EL
} # MML_TEXT_INTEGRATION_EL

sub MML_AXML_EL () {
  MML_EL |
  SCOPING_EL |
  BUTTON_SCOPING_EL |
  FOREIGN_EL |
  0b001
} # MML_AXML_EL

## "HTML integration point" elements in SVG namespace.
sub SVG_INTEGRATION_EL () {
  SVG_EL |
  SCOPING_EL |
  BUTTON_SCOPING_EL |
  FOREIGN_EL |
  FOREIGN_FLOW_CONTENT_EL
} # SVG_INTEGRATION_EL

sub SVG_SCRIPT_EL () {
  SVG_EL |
  FOREIGN_EL |
  0b101
} # SVG_SCRIPT_EL

my $el_category = {
  a => A_EL,
  address => ADDRESS_DIV_EL,
  applet => MISC_SCOPING_EL,
  area => MISC_SPECIAL_EL,
  article => MISC_SPECIAL_EL,
  aside => MISC_SPECIAL_EL,
  b => FORMATTING_EL,
  base => MISC_SPECIAL_EL,
  basefont => MISC_SPECIAL_EL,
  bgsound => MISC_SPECIAL_EL,
  big => FORMATTING_EL,
  blockquote => MISC_SPECIAL_EL,
  body => BODY_EL,
  br => MISC_SPECIAL_EL,
  button => BUTTON_EL,
  caption => CAPTION_EL,
  center => MISC_SPECIAL_EL,
  code => FORMATTING_EL,
  col => MISC_SPECIAL_EL,
  colgroup => MISC_SPECIAL_EL,
  command => MISC_SPECIAL_EL,
  #datagrid => MISC_SPECIAL_EL,
  dd => DTDD_EL,
  details => MISC_SPECIAL_EL,
  dir => MISC_SPECIAL_EL,
  div => ADDRESS_DIV_EL,
  dl => MISC_SPECIAL_EL,
  dt => DTDD_EL,
  em => FORMATTING_EL,
  embed => MISC_SPECIAL_EL,
  fieldset => MISC_SPECIAL_EL,
  figcaption => MISC_SPECIAL_EL,
  figure => MISC_SPECIAL_EL,
  font => FORMATTING_EL,
  footer => MISC_SPECIAL_EL,
  form => FORM_EL,
  frame => MISC_SPECIAL_EL,
  frameset => FRAMESET_EL,
  h1 => HEADING_EL,
  h2 => HEADING_EL,
  h3 => HEADING_EL,
  h4 => HEADING_EL,
  h5 => HEADING_EL,
  h6 => HEADING_EL,
  head => MISC_SPECIAL_EL,
  header => MISC_SPECIAL_EL,
  hgroup => MISC_SPECIAL_EL,
  hr => MISC_SPECIAL_EL,
  html => HTML_EL,
  i => FORMATTING_EL,
  iframe => MISC_SPECIAL_EL,
  img => MISC_SPECIAL_EL,
  #image => MISC_SPECIAL_EL, ## NOTE: Commented out in the spec.
  input => MISC_SPECIAL_EL,
  isindex => MISC_SPECIAL_EL,
  ## XXX keygen? (Whether a void element is in Special or not does not
  ## affect to the processing, however.)
  li => LI_EL,
  link => MISC_SPECIAL_EL,
  listing => MISC_SPECIAL_EL,
  marquee => MISC_SCOPING_EL,
  menu => MISC_SPECIAL_EL,
  meta => MISC_SPECIAL_EL,
  nav => MISC_SPECIAL_EL,
  nobr => NOBR_EL,
  noembed => MISC_SPECIAL_EL,
  noframes => MISC_SPECIAL_EL,
  noscript => MISC_SPECIAL_EL,
  object => MISC_SCOPING_EL,
  ol => MISC_SPECIAL_EL,
  optgroup => OPTGROUP_EL,
  option => OPTION_EL,
  p => P_EL,
  param => MISC_SPECIAL_EL,
  plaintext => MISC_SPECIAL_EL,
  pre => MISC_SPECIAL_EL,
  rp => RUBY_COMPONENT_EL,
  rt => RUBY_COMPONENT_EL,
  ruby => RUBY_EL,
  s => FORMATTING_EL,
  script => MISC_SPECIAL_EL,
  select => SELECT_EL,
  section => MISC_SPECIAL_EL,
  small => FORMATTING_EL,
  strike => FORMATTING_EL,
  strong => FORMATTING_EL,
  style => MISC_SPECIAL_EL,
  summary => MISC_SPECIAL_EL,
  table => TABLE_EL,
  tbody => TABLE_ROW_GROUP_EL,
  td => TABLE_CELL_EL,
  textarea => MISC_SPECIAL_EL,
  tfoot => TABLE_ROW_GROUP_EL,
  th => TABLE_CELL_EL,
  thead => TABLE_ROW_GROUP_EL,
  title => MISC_SPECIAL_EL,
  tr => TABLE_ROW_EL,
  tt => FORMATTING_EL,
  u => FORMATTING_EL,
  ul => MISC_SPECIAL_EL,
  wbr => MISC_SPECIAL_EL,
  xmp => MISC_SPECIAL_EL,
};

my $el_category_f = {
  (MML_NS) => {
    'annotation-xml' => MML_AXML_EL,
    mi => MML_TEXT_INTEGRATION_EL,
    mo => MML_TEXT_INTEGRATION_EL,
    mn => MML_TEXT_INTEGRATION_EL,
    ms => MML_TEXT_INTEGRATION_EL,
    mtext => MML_TEXT_INTEGRATION_EL,
  },
  (SVG_NS) => {
    foreignObject => SVG_INTEGRATION_EL,
    desc => SVG_INTEGRATION_EL,
    title => SVG_INTEGRATION_EL,
    script => SVG_SCRIPT_EL,
  },
  ## NOTE: In addition, FOREIGN_EL is set to non-HTML elements, MML_EL
  ## is set to MathML elements, and SVG_EL is set to SVG elements.
};

require Whatpm::HTML::ParserData;

my $svg_attr_name = $Whatpm::HTML::ParserData::SVGAttrNameFixup;
my $mml_attr_name = $Whatpm::HTML::ParserData::MathMLAttrNameFixup;
my $foreign_attr_xname = $Whatpm::HTML::ParserData::ForeignAttrNamespaceFixup;

## TODO: Invoke the reset algorithm when a resettable element is
## created (cf. HTML5 revision 2259).

## ------ String parse API ------

sub parse_byte_string ($$$$;$$) {
  #my ($self, $charset_name, $string, $doc, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[3];

  my $embedded_encoding_name;
  PARSER: {
    @{$self->{document}->child_nodes} = ();
    
    my $inputref = \($_[2]);
    $self->_encoding_sniffing
        (transport_encoding_name => $_[1],
         embedded_encoding_name => $embedded_encoding_name,
         read_head => sub {
           return $inputref;
         });
    $self->{document}->input_encoding ($self->{input_encoding});

    $self->{line_prev} = $self->{line} = 1;
    $self->{column_prev} = -1;
    $self->{column} = 0;

    $self->{chars} = [split //, decode $self->{input_encoding}, $$inputref];
    $self->{chars_pos} = 0;
    $self->{chars_pull_next} = sub { 0 };
    delete $self->{chars_was_cr};

    $self->{restart_parser} = sub {
      $embedded_encoding_name = $_[0];
      die bless {}, 'Whatpm::HTML::InputStream::RestartParser';
      return 0;
    };

    my $onerror = $_[4] || $self->onerror;
    $self->{parse_error} = sub {
      $onerror->(line => $self->{line}, column => $self->{column}, @_);
    };

    $self->_initialize_tokenizer;
    $self->_initialize_tree_constructor;
    $self->{t} = $self->_get_next_token;
    my $error;
    {
      local $@;
      eval { $self->_construct_tree; 1 } or $error = $@;
    }
    if ($error) {
      if (ref $error eq 'Whatpm::HTML::InputStream::RestartParser') {
        redo PARSER;
      }
      die $error;
    }
    $self->_terminate_tree_constructor;
    $self->_clear_refs;
  } # PARSER

  return $doc;
} # parse_byte_string

## NOTE: HTML5 spec says that the encoding layer MUST NOT strip BOM
## and the HTML layer MUST ignore it.  However, we does strip BOM in
## the encoding layer and the HTML layer does not ignore any U+FEFF,
## because the core part of our HTML parser expects a string of
## character, not a string of bytes or code units or anything which
## might contain a BOM.  Therefore, any parser interface that accepts
## a string of bytes, such as |parse_byte_string| in this module, must
## ensure that it does strip the BOM and never strip any ZWNBSP.

## XXX The policy mentioned above might change when we implement
## Encoding Standard spec.

sub parse_char_string ($$$;$$) {
  #my ($self, $string, $document, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[2];
  @{$self->{document}->child_nodes} = ();

  ## Confidence: irrelevant.
  $self->{confident} = 1 unless exists $self->{confident};

  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;

  $self->{chars} = [split //, $_[1]];
  $self->{chars_pos} = 0;
  $self->{chars_pull_next} = sub { 0 };
  delete $self->{chars_was_cr};

  my $onerror = $_[3] || $self->onerror;
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->{t} = $self->_get_next_token;
  $self->_construct_tree;
  $self->_terminate_tree_constructor;
  $self->_clear_refs;

  return $doc;
} # parse_char_string

## ------ Stream parse API (experimental) ------

## XXX tests

sub parse_bytes_start ($$$) {
  #my ($self, $charset_name, $doc) = @_;
  my $self = ref $_[0] ? $_[0] : $_[0]->new;
  my $doc = $self->{document} = $_[2];
  
  $self->{chars_pull_next} = sub { 1 };
  $self->{restart_parser} = sub {
    $self->{embedded_encoding_name} = $_[0];
    return 1;
  };
  
  my $onerror = $self->onerror;
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  $self->{byte_buffer} = '';
  $self->{byte_buffer_orig} = '';

  $self->_parse_bytes_start_parsing
      (transport_encoding_name => $_[1],
       no_body_data_yet => 1);
} # parse_bytes_start

sub _parse_bytes_start_parsing ($;%) {
  my ($self, %args) = @_;
  @{$self->{document}->child_nodes} = ();
  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;
  $self->{chars} = [];
  $self->{chars_pos} = 0;
  delete $self->{chars_was_cr};
  
  $self->_encoding_sniffing
      (embedded_encoding_name => delete $self->{embedded_encoding_name},
       transport_encoding_name => $args{transport_encoding_name},
       no_body_data_yet => $args{no_body_data_yet},
       read_head => sub {
         return \($self->{byte_buffer});
     });
  if (not $self->{input_encoding} and $args{no_body_data_yet}) {
    delete $self->{parse_bytes_started};
    return;
  }

  $self->{parse_bytes_started} = 1;
  
  $self->{document}->input_encoding ($self->{input_encoding});
  
  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;

  push @{$self->{chars}}, split //,
      decode $self->{input_encoding}, $self->{byte_buffer},
          Encode::FB_QUIET;
  $self->{t} = $self->_get_next_token;
  $self->_construct_tree;
  if ($self->{embedded_encoding_name}) {
    ## Restarting
    $self->_parse_bytes_start_parsing;
  }
} # _parse_bytes_start_parsing

## The $args{start_parsing} flag should be set true if it has taken
## more than 500ms from the start of overall parsing process.
sub parse_bytes_feed ($$;%) {
  my ($self, undef, %args) = @_;

  if ($self->{parse_bytes_started}) {
    $self->{byte_buffer} .= $_[1];
    $self->{byte_buffer_orig} .= $_[1];
    $self->{chars}
        = [split //, decode $self->{input_encoding}, $self->{byte_buffer},
                         Encode::FB_QUIET];
    $self->{chars_pos} = 0;
    my $i = 0;
    if (length $self->{byte_buffer} and @{$self->{chars}} == $i) {
      substr ($self->{byte_buffer}, 0, 1) = '';
      push @{$self->{chars}}, "\x{FFFD}", split //,
          decode $self->{input_encoding}, $self->{byte_buffer},
              Encode::FB_QUIET;
      $i++;
    }
    
    $self->{t} = $self->_get_next_token;
    $self->_construct_tree;
    if ($self->{embedded_encoding_name}) {
      ## Restarting the parser
      $self->_parse_bytes_start_parsing;
    }
  } else {
    $self->{byte_buffer} .= $_[1];
    $self->{byte_buffer_orig} .= $_[1];
    if ($args{start_parsing} or 1024 <= length $self->{byte_buffer}) {
      $self->_parse_bytes_start_parsing;
    }
  }
} # parse_bytes_feed

sub parse_bytes_end {
  my $self = $_[0];
  unless ($self->{parse_bytes_started}) {
    $self->_parse_bytes_start_parsing;
  }

  if (length $self->{byte_buffer}) {
    push @{$self->{chars}},
        split //, decode $self->{input_encoding}, $self->{byte_buffer};
    $self->{byte_buffer} = '';
  }
  $self->{chars_pull_next} = sub { 0 };
  $self->{t} = $self->_get_next_token;
  $self->_construct_tree;
  if ($self->{embedded_encoding_name}) {
    ## Restarting the parser
    $self->_parse_bytes_start_parsing;
  }

  $self->_terminate_tree_constructor;
  $self->_clear_refs;
} # parse_bytes_end

## ------ Insertion modes ------

sub AFTER_HTML_IMS () { 0b100 }
sub HEAD_IMS ()       { 0b1000 }
sub BODY_IMS ()       { 0b10000 }
sub BODY_TABLE_IMS () { 0b100000 }
sub TABLE_IMS ()      { 0b1000000 }
sub ROW_IMS ()        { 0b10000000 }
sub BODY_AFTER_IMS () { 0b100000000 }
sub FRAME_IMS ()      { 0b1000000000 }
sub SELECT_IMS ()     { 0b10000000000 }
sub IN_CDATA_RCDATA_IM () { 0b1000000000000 }
    ## NOTE: "in CDATA/RCDATA" insertion mode is also special; it is
    ## combined with the original insertion mode.  In thie parser,
    ## they are stored together in the bit-or'ed form.

sub IM_MASK () { 0b11111111111 }

## NOTE: These insertion modes are special.
sub INITIAL_IM () { -1 }
sub BEFORE_HTML_IM () { -2 }

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
sub IN_SELECT_IM () { SELECT_IMS | 0b01 }
sub IN_SELECT_IN_TABLE_IM () { SELECT_IMS | 0b10 }
sub IN_COLUMN_GROUP_IM () { 0b10 }



sub _initialize_tree_constructor ($) {
  my $self = shift;
  ## NOTE: $self->{document} MUST be specified before this method is called
  $self->{document}->strict_error_checking (0);
  ## TODO: Turn mutation events off # MUST
  ## TODO: Turn loose Document option (manakai extension) on
  $self->{document}->manakai_is_html (1); # MUST
  $self->{document}->set_user_data (manakai_source_line => 1);
  $self->{document}->set_user_data (manakai_source_column => 1);

  $self->{frameset_ok} = 1;
  delete $self->{active_formatting_elements};
  delete $self->{insert};
  delete $self->{open_tables};

  $self->{insertion_mode} = INITIAL_IM;
  undef $self->{form_element};
  undef $self->{head_element};
  $self->{open_elements} = [];
  undef $self->{inner_html_node};
  undef $self->{ignore_newline};
} # _initialize_tree_constructor

sub _terminate_tree_constructor ($) {
  my $self = shift;
  $self->{document}->strict_error_checking (1);
  delete $self->{active_formatting_elements};
  delete $self->{insert};
  delete $self->{open_tables};
  ## TODO: Turn mutation events on
} # _terminate_tree_constructor

## ISSUE: Should append_child (for example) in script executed in tree construction stage fire mutation events?

## When an interactive UA render the $self->{document} available to
## the user, or when it begin accepting user input, are not defined.

sub _reset_insertion_mode ($) {
  my $self = shift;

  ## Step 1
  my $last;
  
  ## Step 2
  my $i = -1;
  my $node = $self->{open_elements}->[$i];
    
  ## LOOP: Step 3
  LOOP: {
    if ($self->{open_elements}->[0]->[0] eq $node->[0]) {
      $last = 1;
      if (defined $self->{inner_html_node}) {
        
        $node = $self->{inner_html_node};
      } else {
        die "_reset_insertion_mode: t27";
      }
    }
    
    ## Step 4..13
    my $new_mode;
    if ($node->[1] == TABLE_CELL_EL) {
      if ($last) {
        
        #
      } else {
        
        $new_mode = IN_CELL_IM;
      } 
    } elsif ($node->[1] & FOREIGN_EL) {
      #
    } else {
      
      $new_mode = {
        select => IN_SELECT_IM,
        ## NOTE: |option| and |optgroup| do not set insertion mode to
        ## "in select" by themselves.
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
      }->{$node->[0]->manakai_local_name};
    }
    $self->{insertion_mode} = $new_mode and last LOOP if defined $new_mode;
    
    ## Step 14
    if ($node->[1] == HTML_EL) {
      ## NOTE: Commented out in the spec (HTML5 revision 3894).
      #unless (defined $self->{head_element}) {
        
        $self->{insertion_mode} = BEFORE_HEAD_IM;
      #} else {
        
      #  $self->{insertion_mode} = AFTER_HEAD_IM;
      #}
      last LOOP;
    } else {
      
    }
    
    ## Step 15
    $self->{insertion_mode} = IN_BODY_IM and last LOOP if $last;
    
    ## Step 16
    $i--;
    $node = $self->{open_elements}->[$i];
    
    ## Step 17
    redo LOOP;
  } # LOOP
  
  ## END
} # _reset_insertion_mode

  my $parse_rcdata = sub ($$$$) {
    my ($self, $insert, $open_tables, $parse_refs) = @_;

    ## Step 1
    my $start_tag_name = $self->{t}->{tag_name};
    
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  

    ## Step 2
    if ($parse_refs) {
      $self->{state} = RCDATA_STATE;
    } else {
      $self->{state} = RAWTEXT_STATE;
    }
    delete $self->{escape}; # MUST

    ## Step 3, 4
    $self->{insertion_mode} |= IN_CDATA_RCDATA_IM;

    
    $self->{t} = $self->_get_next_token;
  }; # $parse_rcdata

  my $script_start_tag = sub ($$$) {
    my ($self, $insert, $open_tables) = @_;

    ## Step 1
    my $script_el;
    
      $script_el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'script']);
    
        for my $attr_name (keys %{ $self->{t}->{attributes}}) {
          my $attr_t =  $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $script_el->set_attribute_node_ns ($attr);
        }
      
        $script_el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $script_el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      

    ## Step 2
    ## TODO: mark as "parser-inserted"

    ## Step 3
    ## TODO: Mark as "already executed", if ...

    ## Step 4 (HTML5 revision 2702)
    $insert->($self, $script_el, $open_tables);
    push @{$self->{open_elements}}, [$script_el, $el_category->{script}];

    ## Step 5
    $self->{state} = SCRIPT_DATA_STATE;
    delete $self->{escape}; # MUST

    ## Step 6-7
    $self->{insertion_mode} |= IN_CDATA_RCDATA_IM;

    
    $self->{t} = $self->_get_next_token;
  }; # $script_start_tag

sub push_afe ($$) {
  my ($item => $afes) = @_;
  my $item_token = $item->[2];

  my $depth = 0;
  OUTER: for my $i (reverse 0..$#$afes) {
    my $afe = $afes->[$i];
    if ($afe->[0] eq '#marker') {
      last OUTER;
    } else {
      my $afe_token = $afe->[2];
      ## Both |$afe_token| and |$item_token| should be start tag tokens.
      if ($afe_token->{tag_name} eq $item_token->{tag_name}) {
        if ((keys %{$afe_token->{attributes}}) !=
            (keys %{$item_token->{attributes}})) {
          next OUTER;
        }
        for my $attr_name (keys %{$item_token->{attributes}}) {
          next OUTER unless $afe_token->{attributes}->{$attr_name};
          next OUTER unless
              $afe_token->{attributes}->{$attr_name}->{value} eq 
              $item_token->{attributes}->{$attr_name}->{value};
        }

        $depth++;
        if ($depth == 3) {
          splice @$afes, $i, 1 => ();
          last OUTER;
        }
      }

      ## We don't have to check namespaces of elements and attributes,
      ##  nevertheless the spec requires it, because |$afes| could
      ##  never contain a non-HTML element at the time of writing.  In
      ##  addition, scripted changes would never change the original
      ##  start tag token.
    }
  } # OUTER

  push @$afes, $item;
} # push_afe

  my $formatting_end_tag = sub {
    my ($self, $active_formatting_elements, $open_tables, $end_tag_token) = @_;
    my $tag_name = $end_tag_token->{tag_name};

    ## NOTE: The adoption agency algorithm (AAA).

    ## Step 1
    my $outer_loop_counter = 0;

    ## Step 2
    OUTER: {
      if ($outer_loop_counter >= 8) {
        $self->{t} = $self->_get_next_token;
        last OUTER;
      }

      ## Step 3
      $outer_loop_counter++;
      
      ## Step 4
      my $formatting_element;
      my $formatting_element_i_in_active;
      AFE: for (reverse 0..$#$active_formatting_elements) {
        if ($active_formatting_elements->[$_]->[0] eq '#marker') {
          
          last AFE;
        } elsif ($active_formatting_elements->[$_]->[0]->manakai_local_name
                     eq $tag_name) {
          ## NOTE: Non-HTML elements can't be in the list of active
          ## formatting elements.
          
          $formatting_element = $active_formatting_elements->[$_];
          $formatting_element_i_in_active = $_;
          last AFE;
        }
      } # AFE
      unless (defined $formatting_element) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag', text => $tag_name, token => $end_tag_token);
        ## Ignore the token
        $self->{t} = $self->_get_next_token;
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
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name},
                            token => $end_tag_token);
            ## Ignore the token
            $self->{t} = $self->_get_next_token;
            return;
          }
        } elsif ($node->[1] & SCOPING_EL) {
          
          $in_scope = 0;
        }
      } # INSCOPE
      unless (defined $formatting_element_i_in_open) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => $self->{t}->{tag_name},
                        token => $end_tag_token);
        pop @$active_formatting_elements; # $formatting_element
        $self->{t} = $self->_get_next_token; ## TODO: ok?
        return;
      }
      if (not $self->{open_elements}->[-1]->[0] eq $formatting_element->[0]) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                        text => $self->{open_elements}->[-1]->[0]
                            ->manakai_local_name,
                        token => $end_tag_token);
      }
      
      ## Step 5
      my $furthest_block;
      my $furthest_block_i_in_open;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        my $node = $self->{open_elements}->[$_];
        if ($node->[1] & SPECIAL_EL or $node->[1] & SCOPING_EL) { ## "Special"
          
          $furthest_block = $node;
          $furthest_block_i_in_open = $_;
	  ## NOTE: The topmost (eldest) node.
        } elsif ($node->[0] eq $formatting_element->[0]) {
          
          last OE;
        }
      } # OE
      
      ## Step 6
      unless (defined $furthest_block) { # MUST
        
        splice @{$self->{open_elements}}, $formatting_element_i_in_open;
        splice @$active_formatting_elements, $formatting_element_i_in_active, 1;
        $self->{t} = $self->_get_next_token;
        return;
      }
      
      ## Step 7
      my $common_ancestor_node = $self->{open_elements}->[$formatting_element_i_in_open - 1];
      
      ## Step 8
      my $bookmark_prev_el
        = $active_formatting_elements->[$formatting_element_i_in_active - 1]
          ->[0];
      
      ## Step 9
      my $node = $furthest_block;
      my $node_i_in_open = $furthest_block_i_in_open;
      my $last_node = $furthest_block;

      ## Step 9.1
      my $inner_loop_counter = 0;

      INNER: {
        ## Step 9.2
        if ($inner_loop_counter >= 3) {
          $self->{t} = $self->_get_next_token;
          last OUTER;
        }

        ## Step 9.3
        $inner_loop_counter++;

        ## Step 9.4
        $node_i_in_open--;
        $node = $self->{open_elements}->[$node_i_in_open];
        
        ## Step 9.5
        my $node_i_in_active;
        my $node_token;
        S7S2: {
          for (reverse 0..$#$active_formatting_elements) {
            if ($active_formatting_elements->[$_]->[0] eq $node->[0]) {
              
              $node_i_in_active = $_;
              $node_token = $active_formatting_elements->[$_]->[2];
              last S7S2;
            }
          }
          splice @{$self->{open_elements}}, $node_i_in_open, 1;
          redo INNER;
        } # S7S2
        
        ## Step 9.6
        last INNER if $node->[0] eq $formatting_element->[0];
        
        ## Step 9.7
        my $new_element = [];
        
      $new_element->[0] = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $node_token->{tag_name}]);
    
        for my $attr_name (keys %{ $node_token->{attributes}}) {
          my $attr_t =  $node_token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $new_element->[0]->set_attribute_node_ns ($attr);
        }
      
        $new_element->[0]->set_user_data (manakai_source_line => $node_token->{line})
            if defined $node_token->{line};
        $new_element->[0]->set_user_data (manakai_source_column => $node_token->{column})
            if defined $node_token->{column};
      
        $new_element->[1] = $node->[1];
        $new_element->[2] = $node_token;
        $active_formatting_elements->[$node_i_in_active] = $new_element;
        $self->{open_elements}->[$node_i_in_open] = $new_element;
        $node = $new_element;
        
        ## Step 9.8
        if ($last_node->[0] eq $furthest_block->[0]) {
          
          $bookmark_prev_el = $node->[0];
        }
        
        ## Step 9.9
        $node->[0]->append_child ($last_node->[0]);
        
        ## Step 9.10
        $last_node = $node;
        
        ## Step 9.11
        redo INNER;
      } # INNER
      
      ## Step 10
      if ($common_ancestor_node->[1] & TABLE_ROWS_EL) {
        ## Foster parenting.
        my $foster_parent_element;
        my $next_sibling;
        OE: for (reverse 0..$#{$self->{open_elements}}) {
          if ($self->{open_elements}->[$_]->[1] == TABLE_EL) {
            
            $foster_parent_element = $self->{open_elements}->[$_ - 1]->[0];
            $next_sibling = $self->{open_elements}->[$_]->[0];
            undef $next_sibling
                unless $next_sibling->parent_node eq $foster_parent_element;
            last OE;
          }
        } # OE
        $foster_parent_element ||= $self->{open_elements}->[0]->[0];

        $foster_parent_element->insert_before ($last_node->[0], $next_sibling);
        $open_tables->[-1]->[1] = 1; # tainted
      } else {
        
        $common_ancestor_node->[0]->append_child ($last_node->[0]);
      }
      
      ## Step 11
      my $new_element = [];
      
      $new_element->[0] = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $formatting_element->[2]->{tag_name}]);
    
        for my $attr_name (keys %{ $formatting_element->[2]->{attributes}}) {
          my $attr_t =  $formatting_element->[2]->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $new_element->[0]->set_attribute_node_ns ($attr);
        }
      
        $new_element->[0]->set_user_data (manakai_source_line => $formatting_element->[2]->{line})
            if defined $formatting_element->[2]->{line};
        $new_element->[0]->set_user_data (manakai_source_column => $formatting_element->[2]->{column})
            if defined $formatting_element->[2]->{column};
      
      $new_element->[1] = $formatting_element->[1];
      $new_element->[2] = $formatting_element->[2];
      
      ## Step 12
      $new_element->[0]->append_child ($_)
          for $furthest_block->[0]->child_nodes->to_list;
      
      ## Step 13
      $furthest_block->[0]->append_child ($new_element->[0]);
      
      ## Step 14
      my $i;
      AFE: for (reverse 0..$#$active_formatting_elements) {
        if ($active_formatting_elements->[$_]->[0] eq $formatting_element->[0]) {
          
          splice @$active_formatting_elements, $_, 1;
          $i-- and last AFE if defined $i;
        } elsif ($active_formatting_elements->[$_]->[0] eq $bookmark_prev_el) {
          
          $i = $_;
        }
      } # AFE
      splice @$active_formatting_elements, $i + 1, 0 => $new_element;
      
      ## Step 15
      undef $i;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        if ($self->{open_elements}->[$_]->[0] eq $formatting_element->[0]) {
          
          splice @{$self->{open_elements}}, $_, 1;
          $i-- and last OE if defined $i;
        } elsif ($self->{open_elements}->[$_]->[0] eq $furthest_block->[0]) {
          
          $i = $_;
        }
      } # OE
      splice @{$self->{open_elements}}, $i + 1, 0, $new_element;
      
      ## Step 16
      redo OUTER;
    } # OUTER
  }; # $formatting_end_tag

  my $reconstruct_active_formatting_elements = sub ($$$$) {
    my ($self, $insert, $active_formatting_elements, $open_tables) = @_;

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
      my $clone = [$entry->[0]->clone_node (0), $entry->[1], $entry->[2]];
    
      ## Step 9
      $insert->($self, $clone->[0], $open_tables);
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

  my $clear_up_to_marker = sub ($) {
    my $active_formatting_elements = $_[0];
    for (reverse 0..$#$active_formatting_elements) {
      if ($active_formatting_elements->[$_]->[0] eq '#marker') {
        
        splice @$active_formatting_elements, $_;
        return;
      }
    }

    
  }; # $clear_up_to_marker
  my $insert_to_current = sub {
    #my ($self, $child, $open_tables) = @_;
    $_[0]->{open_elements}->[-1]->[0]->append_child ($_[1]);
  }; # $insert_to_current

  ## Foster parenting.  Note that there are three "foster parenting"
  ## code in the parser: for elements (this one), for texts, and for
  ## elements in the AAA code.
  my $insert_to_foster = sub {
    my ($self, $child, $open_tables) = @_;
    if ($self->{open_elements}->[-1]->[1] & TABLE_ROWS_EL) {
      # MUST
      my $foster_parent_element;
      my $next_sibling;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        if ($self->{open_elements}->[$_]->[1] == TABLE_EL) {
          
          $foster_parent_element = $self->{open_elements}->[$_ - 1]->[0];
          $next_sibling = $self->{open_elements}->[$_]->[0];
          undef $next_sibling
              unless $next_sibling->parent_node eq $foster_parent_element;
          last OE;
        }
      } # OE
      $foster_parent_element ||= $self->{open_elements}->[0]->[0];

      $foster_parent_element->insert_before ($child, $next_sibling);
      $open_tables->[-1]->[1] = 1; # tainted
    } else {
      
      $self->{open_elements}->[-1]->[0]->append_child ($child);
    }
  }; # $insert_to_foster

sub _construct_tree ($) {
  my $self = $_[0];

  ## "List of active formatting elements".  Each item in this array is
  ## an array reference, which contains: [0] - the element node; [1] -
  ## the local name of the element; [2] - the token that is used to
  ## create [0].
  my $active_formatting_elements = $self->{active_formatting_elements} ||= [];

  my $insert = $self->{insert} ||= $insert_to_current;

  ## NOTE: $open_tables->[-1]->[0] is the "current table" element node.
  ## NOTE: $open_tables->[-1]->[1] is the "tainted" flag (OBSOLETE; unused).
  ## NOTE: $open_tables->[-1]->[2] is set false when non-Text node inserted.
  my $open_tables = $self->{open_tables} ||= [];

  B: while (1) {
    

    if ($self->{t}->{type} == ABORT_TOKEN) {
      return;
    }

    if ($self->{t}->{n}++ == 100) {
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'parser impl error', # XXXtest
                      token => $self->{t});
      require Data::Dumper;
      warn "====== HTML Parser Error ======\n";
      warn join (' ', map { $_->[0]->manakai_local_name } @{$self->{open_elements}}) . ' #' . $self->{insertion_mode} . "\n";
      warn Data::Dumper::Dumper ($self->{t});
      $self->{t} = $self->_get_next_token;
      next B;
    }

    if ($self->{insertion_mode} == INITIAL_IM) {
      if ($self->{t}->{type} == DOCTYPE_TOKEN) {
        ## NOTE: Conformance checkers MAY, instead of reporting "not
        ## HTML5" error, switch to a conformance checking mode for
        ## another language.  (We don't support such mode switchings;
        ## it is nonsense to do anything different from what browsers
        ## do.)
        my $doctype_name = $self->{t}->{name};
        $doctype_name = '' unless defined $doctype_name;
        my $doctype = $self->{document}->create_document_type_definition
            ($doctype_name);
        
        if ($doctype_name ne 'html') {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not HTML5', token => $self->{t});
        } elsif (defined $self->{t}->{pubid}) {
          ## Obsolete permitted DOCTYPEs (case-sensitive)
          my $xsysid = $Whatpm::HTML::ParserData::ObsoletePermittedDoctypes
              ->{$self->{t}->{pubid}};
          if (defined $xsysid and
              ((not defined $self->{t}->{sysid} and
                $self->{t}->{pubid} =~ /HTML 4/) or
               (defined $self->{t}->{sysid} and
                $self->{t}->{sysid} eq $xsysid))) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'obs DOCTYPE', token => $self->{t},
                            level => $self->{level}->{obsconforming});
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not HTML5', token => $self->{t});
          }
        } elsif (defined $self->{t}->{sysid}) {
          if ($self->{t}->{sysid} eq 'about:legacy-compat') {
            ## <!DOCTYPE HTML SYSTEM "about:legacy-compat">
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'XSLT-compat', token => $self->{t},
                            level => $self->{level}->{should});
          } else {
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not HTML5', token => $self->{t});
          }
        } else { ## <!DOCTYPE HTML>
          
          #
        }
        
        ## NOTE: Default value for both |public_id| and |system_id|
        ## attributes are empty strings, so that we don't set any
        ## value in missing cases.
        $doctype->public_id ($self->{t}->{pubid})
            if defined $self->{t}->{pubid};
        $doctype->system_id ($self->{t}->{sysid})
            if defined $self->{t}->{sysid};
        
        ## NOTE: Other DocumentType attributes are null or empty
        ## lists.  In Firefox3, |internalSubset| attribute is set to
        ## the empty string, while |null| is an allowed value for the
        ## attribute according to DOM3 Core.

        $self->{document}->append_child ($doctype);
        
        ## Resetting the quirksness.  Not in the spec, but this has to
        ## be done for reusing Document object (or for
        ## |document.open|).
        $self->{document}->manakai_compat_mode ('no quirks');
        
        if ($self->{t}->{quirks} or $doctype_name ne 'html') {
          
          $self->{document}->manakai_compat_mode ('quirks');
        } elsif (defined $self->{t}->{pubid}) {
          my $pubid = $self->{t}->{pubid};
          $pubid =~ tr/a-z/A-Z/; ## ASCII case-insensitive.
          my $prefix = $Whatpm::HTML::ParserData::QuirkyPublicIDPrefixes;
          my $match;
          for (@$prefix) {
            if (substr ($pubid, 0, length $_) eq $_) {
              $match = 1;
              last;
            }
          }
          if ($match or
              $Whatpm::HTML::ParserData::QuirkyPublicIDs->{$pubid}) {
            
            $self->{document}->manakai_compat_mode ('quirks');
          } elsif ($pubid =~ m[^-//W3C//DTD HTML 4.01 FRAMESET//] or
                   $pubid =~ m[^-//W3C//DTD HTML 4.01 TRANSITIONAL//]) {
            if (not defined $self->{t}->{sysid}) {
              
              $self->{document}->manakai_compat_mode ('quirks');
            } else {
              
              $self->{document}->manakai_compat_mode ('limited quirks');
            }
          } elsif ($pubid =~ m[^-//W3C//DTD XHTML 1.0 FRAMESET//] or
                   $pubid =~ m[^-//W3C//DTD XHTML 1.0 TRANSITIONAL//]) {
            
            $self->{document}->manakai_compat_mode ('limited quirks');
          } else {
            
          }
        } else {
          
        }
        if (defined $self->{t}->{sysid}) {
          my $sysid = $self->{t}->{sysid};
          $sysid =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
          if ($sysid eq "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd") {
            ## NOTE: Ensure that |PUBLIC "(limited quirks)"
            ## "(quirks)"| is signaled as in quirks mode!
            $self->{document}->manakai_compat_mode ('quirks');
            
          } else {
            
          }
        } else {
          
        }
        
        $self->{insertion_mode} = BEFORE_HTML_IM;
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ({
                START_TAG_TOKEN, 1,
                END_TAG_TOKEN, 1,
                END_OF_FILE_TOKEN, 1,
               }->{$self->{t}->{type}}) {
        unless ($self->{document}->manakai_is_srcdoc) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE', token => $self->{t});
          $self->{document}->manakai_compat_mode ('quirks');
        } else {
          
        }
        $self->{insertion_mode} = BEFORE_HTML_IM;
        ## Reprocess the token.
        
        redo B;
      } elsif ($self->{t}->{type} == CHARACTER_TOKEN) {
        if ($self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
          ## Ignore the token
          
          unless (length $self->{t}->{data}) {
            
            ## Stay in the insertion mode.
            $self->{t} = $self->_get_next_token;
            redo B;
          } else {
            
          }
        } else {
          
        }
        
        unless ($self->{document}->manakai_is_srcdoc) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE', token => $self->{t});
          $self->{document}->manakai_compat_mode ('quirks');
        } else {
          
        }
        $self->{insertion_mode} = BEFORE_HTML_IM;
        ## Reprocess the token.
        redo B;
      } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
        
        my $comment = $self->{document}->create_comment
            ($self->{t}->{data});
        $self->{document}->append_child ($comment);
        
        ## Stay in the insertion mode.
        $self->{t} = $self->_get_next_token;
        next B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} == BEFORE_HTML_IM) {
      if ($self->{t}->{type} == DOCTYPE_TOKEN) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#DOCTYPE', token => $self->{t});
        ## Ignore the token.
        $self->{t} = $self->_get_next_token;
        redo B;
      } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
        
        my $comment = $self->{document}->create_comment
            ($self->{t}->{data});
        $self->{document}->append_child ($comment);
        $self->{t} = $self->_get_next_token;
        redo B;
      } elsif ($self->{t}->{type} == CHARACTER_TOKEN) {
        if ($self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
          ## Ignore the token.
          
          unless (length $self->{t}->{data}) {
            
            $self->{t} = $self->_get_next_token;
            redo B;
          } else {
            
          }
        } else {
          
        }
        
        $self->{application_cache_selection}->(undef);
        
        #
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'html') {
          my $root_element;
          
      $root_element = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{ $self->{t}->{attributes}}) {
          my $attr_t =  $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $root_element->set_attribute_node_ns ($attr);
        }
      
        $root_element->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $root_element->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
          $self->{document}->append_child ($root_element);
          push @{$self->{open_elements}},
              [$root_element, $el_category->{html}];
          
          if ($self->{t}->{attributes}->{manifest}) {
            
            ## XXX resolve URL and drop fragment
            ## <http://html5.org/tools/web-apps-tracker?from=3479&to=3480>
            ## <http://manakai.g.hatena.ne.jp/task/2/95>
            $self->{application_cache_selection}
                 ->($self->{t}->{attributes}->{manifest}->{value});
          } else {
            
            $self->{application_cache_selection}->(undef);
          }
          
          
          
          $self->{t} = $self->_get_next_token;
          $self->{insertion_mode} = BEFORE_HEAD_IM;
          next B;
        } else {
          
          #
        }
      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        if ({
             head => 1, body => 1, html => 1, br => 1,
            }->{$self->{t}->{tag_name}}) {
          
          #
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name},
                          token => $self->{t});
          ## Ignore the token.
          $self->{t} = $self->_get_next_token;
          redo B;
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        
        #
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }
      
      my $root_element;
      
      $root_element = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'html']);
    
        $root_element->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $root_element->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{document}->append_child ($root_element);
      push @{$self->{open_elements}},
          [$root_element, $el_category->{html}];
      push @$open_tables, [[$root_element]];
      
      $self->{application_cache_selection}->(undef);
      
      ## Reprocess the token.
      
      $self->{insertion_mode} = BEFORE_HEAD_IM;
      redo B;
    } # insertion mode

    if (
      (not @{$self->{open_elements}}) or
      (not $self->{open_elements}->[-1]->[1] & FOREIGN_EL) or ## HTML element
      ($self->{open_elements}->[-1]->[1] == MML_TEXT_INTEGRATION_EL and
       (($self->{t}->{type} == START_TAG_TOKEN and
         $self->{t}->{tag_name} ne 'mglyph' and
         $self->{t}->{tag_name} ne 'malignmark') or
        $self->{t}->{type} == CHARACTER_TOKEN)) or
      ($self->{open_elements}->[-1]->[1] & MML_AXML_EL and
       $self->{t}->{type} == START_TAG_TOKEN and
       $self->{t}->{tag_name} eq 'svg') or
      ( ## If the current node is an HTML integration point (other
        ## than |annotation-xml|).
       $self->{open_elements}->[-1]->[1] == SVG_INTEGRATION_EL and
       ($self->{t}->{type} == START_TAG_TOKEN or
        $self->{t}->{type} == CHARACTER_TOKEN)) or
      ( ## If the current node is an |annotation-xml| whose |encoding|
        ## is |text/html| or |application/xhtml+xml| (HTML integration
        ## point).
       $self->{open_elements}->[-1]->[1] == MML_AXML_EL and
       ($self->{t}->{type} == START_TAG_TOKEN or
        $self->{t}->{type} == CHARACTER_TOKEN) and
       do {
         my $encoding = $self->{open_elements}->[-1]->[0]->get_attribute_ns (undef, 'encoding') || '';
         $encoding =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
         if ($encoding eq 'text/html' or 
             $encoding eq 'application/xhtml+xml') {
           1;
         } else {
           0;
         }
       }) or
      ($self->{t}->{type} == END_OF_FILE_TOKEN)) {
      
      ## Use the rules for the current insertion mode in HTML content.
      #
    } else {
      ## Use the rules for the foreign content.

      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        ## "In foreign content", character tokens.
        my $data = $self->{t}->{data};
        while ($data =~ s/\x00/\x{FFFD}/) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
        }
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($data);
        if ($data =~ /[^\x09\x0A\x0C\x0D\x20]/) {
          delete $self->{frameset_ok};
        }
        
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
        ## "In foreign content", start tag token.

        if (
          $Whatpm::HTML::ParserData::ForeignContentBreakers->{$self->{t}->{tag_name}} or
          ($self->{t}->{tag_name} eq 'font' and
           ($self->{t}->{attributes}->{color} or
            $self->{t}->{attributes}->{face} or
            $self->{t}->{attributes}->{size}))
        ) {
          ## "In foreign content", HTML-only start tag.
          

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                          text => $self->{open_elements}->[-1]->[0]
                              ->manakai_local_name,
                          token => $self->{t});

          pop @{$self->{open_elements}};
          V: {
            my $current_node = $self->{open_elements}->[-1];
            if (
              ## An HTML element.
              not $current_node->[1] & FOREIGN_EL or

              ## An MathML text integration point.
              $current_node->[1] == MML_TEXT_INTEGRATION_EL or
              
              ## An HTML integration point.
              $current_node->[1] == SVG_INTEGRATION_EL or
              ($current_node->[1] == MML_AXML_EL and
               do {
                 my $encoding = $current_node->[0]->get_attribute_ns (undef, 'encoding') || '';
                 $encoding =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
                 ($encoding eq 'text/html' or
                  $encoding eq 'application/xhtml+xml');
               })
            ) {
              last V;
            }
            
            pop @{$self->{open_elements}};
            redo V;
          }
          
          ## Reprocess the token.
          next B;

        } else {
          ## "In foreign content", foreign start tag.

          my $nsuri = $self->{open_elements}->[-1]->[0]->namespace_uri;
          my $tag_name = $self->{t}->{tag_name};
          if ($nsuri eq SVG_NS) {
            $tag_name = $Whatpm::HTML::ParserData::SVGElementNameFixup
                ->{$tag_name} || $tag_name;
          }

          ## "adjust SVG attributes" (SVG only) - done in insert-element-f

          ## "adjust foreign attributes" - done in insert-element-f

          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($nsuri, [undef,   $tag_name]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (
          @{
            $foreign_attr_xname->{$attr_name} ||
            [undef, [undef,
                     ($nsuri) eq SVG_NS ?
                         ($svg_attr_name->{$attr_name} || $attr_name) :
                     ($nsuri) eq MML_NS ?
                         ($mml_attr_name->{$attr_name} || $attr_name) :
                         $attr_name]]
          }
        );
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, ($el_category_f->{$nsuri}->{ $tag_name} || 0) | FOREIGN_EL | (($nsuri) eq SVG_NS ? SVG_EL : ($nsuri) eq MML_NS ? MML_EL : 0)];

      if ( $self->{t}->{attributes}->{xmlns} and  $self->{t}->{attributes}->{xmlns}->{value} ne ($nsuri)) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad namespace', token =>  $self->{t});
## TODO: Error type documentation
      }
      if ( $self->{t}->{attributes}->{'xmlns:xlink'} and
           $self->{t}->{attributes}->{'xmlns:xlink'}->{value} ne q<http://www.w3.org/1999/xlink>) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad namespace', token =>  $self->{t});
      }
    }
  

          if ($self->{self_closing}) {
            pop @{$self->{open_elements}};
            delete $self->{self_closing};
          } else {
            
          }

          $self->{t} = $self->_get_next_token;
          next B;
        }

      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        ## "In foreign content", end tag.

        if ($self->{t}->{tag_name} eq 'script' and
            $self->{open_elements}->[-1]->[1] == SVG_SCRIPT_EL) {
          ## "In foreign content", "script" end tag, if the current
          ## node is an SVG |script| element.
          
          pop @{$self->{open_elements}};

          ## XXXscript: Execute script here.
          $self->{t} = $self->_get_next_token;
          next B;

        } else {
          ## "In foreign content", end tag.
          
          
          ## 1.
          my $i = -1;
          my $node = $self->{open_elements}->[$i];
          
          ## 2.
          my $tag_name = $node->[0]->manakai_local_name;
          $tag_name =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
          if ($tag_name ne $self->{t}->{tag_name}) {
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name},
                            level => $self->{level}->{must});
          }

          ## 3.
          LOOP: {
            my $tag_name = $node->[0]->manakai_local_name;
            $tag_name =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
            if ($tag_name eq $self->{t}->{tag_name}) {
              splice @{$self->{open_elements}}, $i, -$i, ();
              $self->{t} = $self->_get_next_token;
              next B;
            }
            
            ## 4.
            $i--;
            $node = $self->{open_elements}->[$i];

            ## 5.
            if ($node->[1] & FOREIGN_EL) {
              redo LOOP;
            }
          } # LOOP

          ## Step 6 (Use the current insertion mode in HTML content)
          #
        }

      } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
        ## "In foreign content", comment token.
        my $comment = $self->{document}->create_comment ($self->{t}->{data});
        $self->{open_elements}->[-1]->[0]->append_child ($comment);
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{type} == DOCTYPE_TOKEN) {
        
        ## "In foreign content", DOCTYPE token.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#DOCTYPE', token => $self->{t});
        ## Ignore the token.
        $self->{t} = $self->_get_next_token;
        next B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";        
      }
    } # foreign

    ## The "in table text" insertion mode.
    if ($self->{insertion_mode} & TABLE_IMS and
        not $self->{insertion_mode} & IN_CDATA_RCDATA_IM) {
      C: {
        my $s;
        if ($self->{t}->{type} == CHARACTER_TOKEN) {
          
          $self->{pending_chars} ||= [];
          push @{$self->{pending_chars}}, $self->{t};
          $self->{t} = $self->_get_next_token;
          next B;
        } else {
          ## There is an "insert pending chars" code clone.
          if ($self->{pending_chars}) {
            $s = join '', map { $_->{data} } @{$self->{pending_chars}};
            delete $self->{pending_chars};
            while ($s =~ s/\x00//) {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
            }
            if ($s eq '') {
              last C;
            } elsif ($s =~ /[^\x09\x0A\x0C\x0D\x20]/) {
              
              #
            } else {
              
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($s);
              last C;
            }
          } else {
            
            last C;
          }
        }

        ## "in table" insertion mode, "Anything else".

        ## Foster parenting.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table:#text', token => $self->{t});

        ## NOTE: As if in body, but insert into the foster parent element.
        $reconstruct_active_formatting_elements
            ->($self, $insert_to_foster, $active_formatting_elements,
               $open_tables);
            
        if ($self->{open_elements}->[-1]->[1] & TABLE_ROWS_EL) {
          # MUST
          my $foster_parent_element;
          my $next_sibling;
          OE: for (reverse 0..$#{$self->{open_elements}}) {
            if ($self->{open_elements}->[$_]->[1] == TABLE_EL) {
              
              $foster_parent_element = $self->{open_elements}->[$_ - 1]->[0];
              $next_sibling = $self->{open_elements}->[$_]->[0];
              undef $next_sibling
                unless $next_sibling->parent_node eq $foster_parent_element;
              last OE;
            }
          } # OE
          $foster_parent_element ||= $self->{open_elements}->[0]->[0];

          
          $foster_parent_element->insert_before
              ($self->{document}->create_text_node ($s), $next_sibling);

          $open_tables->[-1]->[1] = 1; # tainted
          $open_tables->[-1]->[2] = 1; # ~node inserted
        } else {
          ## NOTE: Fragment case or in a foster parent'ed element
          ## (e.g. |<table><span>a|).  In fragment case, whether the
          ## character is appended to existing node or a new node is
          ## created is irrelevant, since the foster parent'ed nodes
          ## are discarded and fragment parsing does not invoke any
          ## script.
          
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($s);
        }
      } # C
    } # TABLE_IMS

    if ($self->{t}->{type} == DOCTYPE_TOKEN) {
      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#DOCTYPE', token => $self->{t});
      ## Ignore the token
      ## Stay in the phase
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == START_TAG_TOKEN and
             $self->{t}->{tag_name} eq 'html') {
      if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html', text => 'html', token => $self->{t});
        $self->{insertion_mode} = AFTER_BODY_IM;
      } elsif ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html', text => 'html', token => $self->{t});
        $self->{insertion_mode} = AFTER_FRAMESET_IM;
      } else {
        
      }

      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'not first start tag', token => $self->{t});
      my $top_el = $self->{open_elements}->[0]->[0];
      for my $attr_name (keys %{$self->{t}->{attributes}}) {
        unless ($top_el->has_attribute_ns (undef, $attr_name)) {
          
          $top_el->set_attribute_ns
            (undef, [undef, $attr_name], 
             $self->{t}->{attributes}->{$attr_name}->{value});
        }
      }
      
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{t}->{type} == COMMENT_TOKEN) {
      my $comment = $self->{document}->create_comment ($self->{t}->{data});
      if ($self->{insertion_mode} & AFTER_HTML_IMS) {
        
        $self->{document}->append_child ($comment);
      } elsif ($self->{insertion_mode} == AFTER_BODY_IM) {
        
        $self->{open_elements}->[0]->[0]->append_child ($comment);
      } else {
        
        $self->{open_elements}->[-1]->[0]->append_child ($comment);
        $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
      }
      $self->{t} = $self->_get_next_token;
      next B;
    } elsif ($self->{insertion_mode} & IN_CDATA_RCDATA_IM) {
      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        $self->{t}->{data} =~ s/^\x0A// if $self->{ignore_newline};
        delete $self->{ignore_newline};

        if (length $self->{t}->{data}) {
          
          ## NOTE: NULLs are replaced into U+FFFDs in tokenizer.
          $self->{open_elements}->[-1]->[0]->manakai_append_text
              ($self->{t}->{data});
        } else {
          
        }
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        delete $self->{ignore_newline};

        if ($self->{t}->{tag_name} eq 'script') {
          
          
          ## Para 1-2
          my $script = pop @{$self->{open_elements}};
          
          ## Para 3
          $self->{insertion_mode} &= ~ IN_CDATA_RCDATA_IM;

          ## Para 4
          ## TODO: $old_insertion_point = $current_insertion_point;
          ## TODO: $current_insertion_point = just before $self->{nc};

          ## Para 5
          ## TODO: Run the $script->[0].

          ## Para 6
          ## TODO: $current_insertion_point = $old_insertion_point;

          ## Para 7
          ## TODO: if ($pending_external_script) {
            ## TODO: ...
          ## TODO: }

          $self->{t} = $self->_get_next_token;
          next B;
        } else {
          
 
          pop @{$self->{open_elements}};

          $self->{insertion_mode} &= ~ IN_CDATA_RCDATA_IM;
          $self->{t} = $self->_get_next_token;
          next B;
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        delete $self->{ignore_newline};

        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                        text => $self->{open_elements}->[-1]->[0]
                            ->manakai_local_name,
                        token => $self->{t});

        #if ($self->{open_elements}->[-1]->[1] == SCRIPT_EL) {
        #  ## TODO: Mark as "already executed"
        #}

        pop @{$self->{open_elements}};

        $self->{insertion_mode} &= ~ IN_CDATA_RCDATA_IM;
        ## Reprocess.
        next B;
      } else {
        die "$0: $self->{t}->{type}: In CDATA/RCDATA: Unknown token type";        
      }
    } # insertion_mode

    if ($self->{insertion_mode} & HEAD_IMS) {
      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        if ($self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
          unless ($self->{insertion_mode} == BEFORE_HEAD_IM) {
            
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          } else {
            
            ## Ignore the token.
            #
          }
          unless (length $self->{t}->{data}) {
            
            $self->{t} = $self->_get_next_token;
            next B;
          }
## TODO: set $self->{t}->{column} appropriately
        }

        if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          
          ## As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
          $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
          push @{$self->{open_elements}},
              [$self->{head_element}, $el_category->{head}];

          ## Reprocess in the "in head" insertion mode...
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
          
          ## As if </noscript>
          pop @{$self->{open_elements}};
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:#text', token => $self->{t});
          
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
        (HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
        $self->{insertion_mode} = IN_BODY_IM;
        ## The "frameset-ok" flag is left unchanged in this case.
        ## Reporcess the token.
        next B;
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'head') {
          if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
            
            
      $self->{head_element} = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{ $self->{t}->{attributes}}) {
          my $attr_t =  $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $self->{head_element}->set_attribute_node_ns ($attr);
        }
      
        $self->{head_element}->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
            $self->{open_elements}->[-1]->[0]->append_child
                ($self->{head_element});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
            $self->{insertion_mode} = IN_HEAD_IM;
            
            $self->{t} = $self->_get_next_token;
            next B;
          } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head', text => 'head',
                            token => $self->{t});
            ## Ignore the token
            
            $self->{t} = $self->_get_next_token;
            next B;
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in head:head',
                            token => $self->{t}); # or in head noscript
            ## Ignore the token
            
            $self->{t} = $self->_get_next_token;
            next B;
          }
        } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          
          ## As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
          $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
          push @{$self->{open_elements}},
              [$self->{head_element}, $el_category->{head}];

          $self->{insertion_mode} = IN_HEAD_IM;
          ## Reprocess in the "in head" insertion mode...
        } else {
          
        }

        if ($self->{t}->{tag_name} eq 'base') {
          if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            ## As if </noscript>
            pop @{$self->{open_elements}};
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'base',
                            token => $self->{t});
          
            $self->{insertion_mode} = IN_HEAD_IM;
            ## Reprocess in the "in head" insertion mode...
          } else {
            
          }

          ## NOTE: There is a "as if in head" code clone.
          if ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
          } else {
            
          }
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          pop @{$self->{open_elements}};
          pop @{$self->{open_elements}} # <head>
              if $self->{insertion_mode} == AFTER_HEAD_IM;
          
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ({
          link => 1, basefont => 1, bgsound => 1,
        }->{$self->{t}->{tag_name}}) {
          ## NOTE: There is a "as if in head" code clone.
          if ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
          } else {
            
          }
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          pop @{$self->{open_elements}};
          pop @{$self->{open_elements}} # <head>
              if $self->{insertion_mode} == AFTER_HEAD_IM;
          delete $self->{self_closing};
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'command') {
          if ($self->{insertion_mode} == IN_HEAD_IM) {
            ## NOTE: If the insertion mode at the time of the emission
            ## of the token was "before head", $self->{insertion_mode}
            ## is already changed to |IN_HEAD_IM|.

            ## NOTE: There is a "as if in head" code clone.
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
            pop @{$self->{open_elements}};
            pop @{$self->{open_elements}} # <head>
                if $self->{insertion_mode} == AFTER_HEAD_IM;
            delete $self->{self_closing};
            $self->{t} = $self->_get_next_token;
            next B;
          } else {
            ## NOTE: "in head noscript" or "after head" insertion mode
            ## - in these cases, these tags are treated as same as
            ## normal in-body tags.
            
            #
          }
        } elsif ($self->{t}->{tag_name} eq 'meta') {
          ## NOTE: There is a "as if in head" code clone.
          if ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
          } else {
            
          }
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          my $meta_el = pop @{$self->{open_elements}};

              unless ($self->{confident}) {
                if ($self->{t}->{attributes}->{charset}) {
                  
                  ## NOTE: Whether the encoding is supported or not,
                  ## an ASCII-compatible charset is not, is handled in
                  ## the |_change_encoding| method.
                  if ($self->_change_encoding
                          ($self->{t}->{attributes}->{charset}->{value},
                           $self->{t})) {
                    return {type => ABORT_TOKEN};
                  }
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                      ->set_user_data (manakai_has_reference =>
                                           $self->{t}->{attributes}->{charset}
                                               ->{has_reference});
                } elsif ($self->{t}->{attributes}->{content} and
                         $self->{t}->{attributes}->{'http-equiv'}) {
                  if ($self->{t}->{attributes}->{'http-equiv'}->{value}
                      =~ /\A[Cc][Oo][Nn][Tt][Ee][Nn][Tt]-[Tt][Yy][Pp][Ee]\z/ and
                      $self->{t}->{attributes}->{content}->{value}
                      =~ /[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                          [\x09\x0A\x0C\x0D\x20]*=
                          [\x09\x0A\x0C\x0D\x20]*(?>"([^"]*)"|'([^']*)'|
                          ([^"'\x09\x0A\x0C\x0D\x20]
                           [^\x09\x0A\x0C\x0D\x20\x3B]*))/x) {
                    
                    ## NOTE: Whether the encoding is supported or not,
                    ## an ASCII-compatible charset is not, is handled
                    ## in the |_change_encoding| method.
                    if ($self->_change_encoding
                            (defined $1 ? $1 : defined $2 ? $2 : $3,
                             $self->{t})) {
                      return {type => ABORT_TOKEN};
                    }
                    $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                        ->set_user_data (manakai_has_reference =>
                                             $self->{t}->{attributes}->{content}
                                                   ->{has_reference});
                  } else {
                    
                  }
                }
              } else {
                if ($self->{t}->{attributes}->{charset}) {
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                      ->set_user_data (manakai_has_reference =>
                                           $self->{t}->{attributes}->{charset}
                                               ->{has_reference});
                }
                if ($self->{t}->{attributes}->{content}) {
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                      ->set_user_data (manakai_has_reference =>
                                           $self->{t}->{attributes}->{content}
                                               ->{has_reference});
                }
              }

              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              delete $self->{self_closing};
              $self->{t} = $self->_get_next_token;
              next B;
        } elsif ($self->{t}->{tag_name} eq 'title') {
          if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            ## As if </noscript>
            pop @{$self->{open_elements}};
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'title',
                            token => $self->{t});
          
            $self->{insertion_mode} = IN_HEAD_IM;
            ## Reprocess in the "in head" insertion mode...
          } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
          } else {
            
          }

          ## NOTE: There is a "as if in head" code clone.
          $parse_rcdata->($self, $insert, $open_tables, 1); # RCDATA

          ## NOTE: At this point the stack of open elements contain
          ## the |head| element (index == -2) and the |script| element
          ## (index == -1).  In the "after head" insertion mode the
          ## |head| element is inserted only for the purpose of
          ## providing the context for the |script| element, and
          ## therefore we can now and have to remove the element from
          ## the stack.
          splice @{$self->{open_elements}}, -2, 1, () # <head>
              if ($self->{insertion_mode} & IM_MASK) == AFTER_HEAD_IM;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'style' or
                 $self->{t}->{tag_name} eq 'noframes') {
          ## NOTE: Or (scripting is enabled and tag_name eq 'noscript' and
          ## insertion mode IN_HEAD_IM)
          ## NOTE: There is a "as if in head" code clone.
          if ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
          } else {
            
          }
          $parse_rcdata->($self, $insert, $open_tables, 0); # RAWTEXT
          splice @{$self->{open_elements}}, -2, 1, () # <head>
              if ($self->{insertion_mode} & IM_MASK) == AFTER_HEAD_IM;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_IM) {
                
                ## NOTE: and scripting is disalbed
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
                $self->{insertion_mode} = IN_HEAD_NOSCRIPT_IM;
                
                $self->{t} = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'noscript',
                                token => $self->{t});
                ## Ignore the token
                
                $self->{t} = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
        } elsif ($self->{t}->{tag_name} eq 'script') {
          if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            ## As if </noscript>
            pop @{$self->{open_elements}};
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'script',
                            token => $self->{t});
          
            $self->{insertion_mode} = IN_HEAD_IM;
            ## Reprocess in the "in head" insertion mode...
          } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
          } else {
            
          }

          ## NOTE: There is a "as if in head" code clone.
          $script_start_tag->($self, $insert, $open_tables);
          ## ISSUE: A spec bug  [Bug 6038]
          splice @{$self->{open_elements}}, -2, 1 # <head>
              if ($self->{insertion_mode} & IM_MASK) == AFTER_HEAD_IM;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'body' or
                 $self->{t}->{tag_name} eq 'frameset') {
          if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            ## As if </noscript>
            pop @{$self->{open_elements}};
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            
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
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          if ($self->{t}->{tag_name} eq 'body') {
            
            delete $self->{frameset_ok};
            $self->{insertion_mode} = IN_BODY_IM;
          } elsif ($self->{t}->{tag_name} eq 'frameset') {
            
            $self->{insertion_mode} = IN_FRAMESET_IM;
          } else {
            die "$0: tag name: $self->{tag_name}";
          }
          
          $self->{t} = $self->_get_next_token;
          next B;
        } else {
          
          #
        }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:/',
                              text => $self->{t}->{tag_name}, token => $self->{t});
              
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
        (HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
        $self->{insertion_mode} = IN_BODY_IM;
        ## The "frameset-ok" flag is not changed in this case.
        ## Reprocess the token.
        
        next B;
      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        ## "Before head", "in head", and "after head" insertion modes
        ## ignore most of end tags.  Exceptions are "body", "html",
        ## and "br" end tags.  "Before head" and "in head" insertion
        ## modes also recognize "head" end tag.  "In head noscript"
        ## insertion modes ignore end tags except for "noscript" and
        ## "br".

        if ($self->{t}->{tag_name} eq 'head') {
          if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
            
            ## As if <head>
            
      $self->{head_element} = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
            $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];

            ## Reprocess in the "in head" insertion mode...
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = AFTER_HEAD_IM;
            $self->{t} = $self->_get_next_token;
            next B;
          } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            #
          } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
            
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = AFTER_HEAD_IM;
            $self->{t} = $self->_get_next_token;
            next B;
          } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            #
          } else {
            die "$0: $self->{insertion_mode}: Unknown insertion mode";
          }
        } elsif ($self->{t}->{tag_name} eq 'noscript') {
          if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = IN_HEAD_IM;
            $self->{t} = $self->_get_next_token;
            next B;
          } else {
            
            #
          }
        } elsif ({
            body => ($self->{insertion_mode} != IN_HEAD_NOSCRIPT_IM),
            html => ($self->{insertion_mode} != IN_HEAD_NOSCRIPT_IM),
            br => 1,
        }->{$self->{t}->{tag_name}}) {
          if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
            
            ## (before head) as if <head>, (in head) as if </head>
            
      $self->{head_element} = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
            $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
            $self->{insertion_mode} = AFTER_HEAD_IM;
  
            ## Reprocess in the "after head" insertion mode...
          } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
            
            ## As if </head>
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = AFTER_HEAD_IM;
  
            ## Reprocess in the "after head" insertion mode...
          } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
            
            ## NOTE: Two parse errors for <head><noscript></br>
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            ## As if </noscript>
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = IN_HEAD_IM;

            ## Reprocess in the "in head" insertion mode...
            ## As if </head>
            pop @{$self->{open_elements}};
            $self->{insertion_mode} = AFTER_HEAD_IM;

            ## Reprocess in the "after head" insertion mode...
          } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            #
          } else {
            die "$0: $self->{insertion_mode}: Unknown insertion mode";
          }

          ## "after head" insertion mode
          ## As if <body>
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
          $self->{insertion_mode} = IN_BODY_IM;
          ## The "frameset-ok" flag is left unchanged in this case.
          ## Reprocess the token.
          next B;
        }

        ## End tags are ignored by default.
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => $self->{t}->{tag_name}, token => $self->{t});
        ## Ignore the token.
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          

          ## NOTE: As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
          $self->{open_elements}->[-1]->[0]->append_child
              ($self->{head_element});
          #push @{$self->{open_elements}},
          #    [$self->{head_element}, $el_category->{head}];
          #$self->{insertion_mode} = IN_HEAD_IM;
          ## NOTE: Reprocess.

          ## NOTE: As if </head>
          #pop @{$self->{open_elements}};
          #$self->{insertion_mode} = IN_AFTER_HEAD_IM;
          ## NOTE: Reprocess.
          
          #
        } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
          

          ## NOTE: As if </head>
          pop @{$self->{open_elements}};
          #$self->{insertion_mode} = IN_AFTER_HEAD_IM;
          ## NOTE: Reprocess.

          #
        } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
          

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:#eof', token => $self->{t});

          ## As if </noscript>
          pop @{$self->{open_elements}};
          #$self->{insertion_mode} = IN_HEAD_IM;
          ## NOTE: Reprocess.

          ## NOTE: As if </head>
          pop @{$self->{open_elements}};
          #$self->{insertion_mode} = IN_AFTER_HEAD_IM;
          ## NOTE: Reprocess.

          #
        } else {
          
          #
        }

        ## NOTE: As if <body>
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
        $self->{insertion_mode} = IN_BODY_IM;
        ## The "frameset-ok" flag is left unchanged in this case.
        ## Reprocess the token.
        next B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }

    } elsif ($self->{insertion_mode} & BODY_IMS) {
      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        ## "In body" insertion mode, character token.  It is also used
        ## for character tokens "in foreign content" for certain
        ## cases.

        while ($self->{t}->{data} =~ s/\x00//g) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
        }
        if ($self->{t}->{data} eq '') {
          $self->{t} = $self->_get_next_token;
          next B;
        }

        
        $reconstruct_active_formatting_elements
            ->($self, $insert_to_current, $active_formatting_elements,
               $open_tables);
        
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($self->{t}->{data});

        if ($self->{frameset_ok} and
            $self->{t}->{data} =~ /[^\x09\x0A\x0C\x0D\x20]/) {
          delete $self->{frameset_ok};
        }

        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
            if ({
                 caption => 1, col => 1, colgroup => 1, tbody => 1,
                 td => 1, tfoot => 1, th => 1, thead => 1, tr => 1,
                }->{$self->{t}->{tag_name}}) {
              if (($self->{insertion_mode} & IM_MASK) == IN_CELL_IM) {
                ## have an element in table scope
                for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] == TABLE_CELL_EL) {
                    

                    ## Close the cell
                    
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <x>
                    $self->{t} = {type => END_TAG_TOKEN,
                              tag_name => $node->[0]->manakai_local_name,
                              line => $self->{t}->{line},
                              column => $self->{t}->{column}};
                    next B;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    ## ISSUE: This case can never be reached, maybe.
                    last;
                  }
                }

                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'start tag not allowed',
                    text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                
                $self->{t} = $self->_get_next_token;
                next B;
              } elsif (($self->{insertion_mode} & IM_MASK) == IN_CAPTION_IM) {
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'caption',
                                token => $self->{t});
                
                ## NOTE: As if </caption>.
                ## have a table element in table scope
                my $i;
                INSCOPE: {
                  for (reverse 0..$#{$self->{open_elements}}) {
                    my $node = $self->{open_elements}->[$_];
                    if ($node->[1] == CAPTION_EL) {
                      
                      $i = $_;
                      last INSCOPE;
                    } elsif ($node->[1] & TABLE_SCOPING_EL) {
                      
                      last;
                    }
                  }

                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'start tag not allowed',
                                  text => $self->{t}->{tag_name}, token => $self->{t});
                  ## Ignore the token
                  
                  $self->{t} = $self->_get_next_token;
                  next B;
                } # INSCOPE
                
                ## generate implied end tags
                while ($self->{open_elements}->[-1]->[1]
                           & END_TAG_OPTIONAL_EL) {
                  
                  pop @{$self->{open_elements}};
                }

                unless ($self->{open_elements}->[-1]->[1] == CAPTION_EL) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                  text => $self->{open_elements}->[-1]->[0]
                                      ->manakai_local_name,
                                  token => $self->{t});
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->($active_formatting_elements);
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                ## reprocess
                
                next B;
              } else {
                
                #
              }
            } else {
              
              #
            }
          } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
            if ($self->{t}->{tag_name} eq 'td' or $self->{t}->{tag_name} eq 'th') {
              if (($self->{insertion_mode} & IM_MASK) == IN_CELL_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[0]->manakai_local_name eq $self->{t}->{tag_name}) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
                    $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                    text => $self->{t}->{tag_name},
                                    token => $self->{t});
                    ## Ignore the token
                    $self->{t} = $self->_get_next_token;
                    next B;
                  }
                
                ## generate implied end tags
                while ($self->{open_elements}->[-1]->[1]
                           & END_TAG_OPTIONAL_EL) {
                  
                  pop @{$self->{open_elements}};
                }

                if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                        ne $self->{t}->{tag_name}) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                  text => $self->{open_elements}->[-1]->[0]
                                      ->manakai_local_name,
                                  token => $self->{t});
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->($active_formatting_elements);
                
                $self->{insertion_mode} = IN_ROW_IM;
                
                $self->{t} = $self->_get_next_token;
                next B;
              } elsif (($self->{insertion_mode} & IM_MASK) == IN_CAPTION_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                $self->{t} = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
            } elsif ($self->{t}->{tag_name} eq 'caption') {
              if (($self->{insertion_mode} & IM_MASK) == IN_CAPTION_IM) {
                ## have a table element in table scope
                my $i;
                INSCOPE: {
                  for (reverse 0..$#{$self->{open_elements}}) {
                    my $node = $self->{open_elements}->[$_];
                    if ($node->[1] == CAPTION_EL) {
                      
                      $i = $_;
                      last INSCOPE;
                    } elsif ($node->[1] & TABLE_SCOPING_EL) {
                      
                      last;
                    }
                  }

                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $self->{t}->{tag_name}, token => $self->{t});
                  ## Ignore the token
                  $self->{t} = $self->_get_next_token;
                  next B;
                } # INSCOPE
                
                ## generate implied end tags
                while ($self->{open_elements}->[-1]->[1]
                           & END_TAG_OPTIONAL_EL) {
                  
                  pop @{$self->{open_elements}};
                }
                
                unless ($self->{open_elements}->[-1]->[1] == CAPTION_EL) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                  text => $self->{open_elements}->[-1]->[0]
                                      ->manakai_local_name,
                                  token => $self->{t});
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->($active_formatting_elements);
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                $self->{t} = $self->_get_next_token;
                next B;
              } elsif (($self->{insertion_mode} & IM_MASK) == IN_CELL_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                $self->{t} = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
            } elsif ({
                      table => 1, tbody => 1, tfoot => 1, 
                      thead => 1, tr => 1,
                     }->{$self->{t}->{tag_name}} and
                     ($self->{insertion_mode} & IM_MASK) == IN_CELL_IM) {
              ## have an element in table scope
              my $i;
              my $tn;
              INSCOPE: {
                for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[0]->manakai_local_name eq $self->{t}->{tag_name}) {
                    
                    $i = $_;

                    ## Close the cell
                    
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # </x>
                    $self->{t} = {type => END_TAG_TOKEN, tag_name => $tn,
                              line => $self->{t}->{line},
                              column => $self->{t}->{column}};
                    next B;
                  } elsif ($node->[1] == TABLE_CELL_EL) {
                    
                    $tn = $node->[0]->manakai_local_name;
                    ## NOTE: There is exactly one |td| or |th| element
                    ## in scope in the stack of open elements by definition.
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    ## ISSUE: Can this be reached?
                    
                    last;
                  }
                }

                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                    text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                $self->{t} = $self->_get_next_token;
                next B;
              } # INSCOPE
            } elsif ($self->{t}->{tag_name} eq 'table' and
                     ($self->{insertion_mode} & IM_MASK) == IN_CAPTION_IM) {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'caption',
                              token => $self->{t});

              ## As if </caption>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] == CAPTION_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
	## TODO: Wrong error type?
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => 'caption', token => $self->{t});
                ## Ignore the token
                $self->{t} = $self->_get_next_token;
                next B;
              }
              
              ## generate implied end tags
              while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
                
                pop @{$self->{open_elements}};
              }

              unless ($self->{open_elements}->[-1]->[1] == CAPTION_EL) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                text => $self->{open_elements}->[-1]->[0]
                                    ->manakai_local_name,
                                token => $self->{t});
              } else {
                
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->($active_formatting_elements);

              $self->{insertion_mode} = IN_TABLE_IM;

              ## reprocess
              next B;
            } elsif ({
                      body => 1, col => 1, colgroup => 1, html => 1,
                     }->{$self->{t}->{tag_name}}) {
              if ($self->{insertion_mode} & BODY_TABLE_IMS) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                $self->{t} = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
        } elsif ({
                  tbody => 1, tfoot => 1,
                  thead => 1, tr => 1,
                 }->{$self->{t}->{tag_name}} and
                 ($self->{insertion_mode} & IM_MASK) == IN_CAPTION_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## Ignore the token
          $self->{t} = $self->_get_next_token;
          next B;
        } else {
          
          #
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        for my $entry (@{$self->{open_elements}}) {
          unless ($entry->[1] & ALL_END_TAG_OPTIONAL_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $self->{t});
            last;
          }
        }

        ## Stop parsing.
        last B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }

      $self->{insert} = $insert = $insert_to_current;
      #
    } elsif ($self->{insertion_mode} & TABLE_IMS) {
      if ($self->{t}->{type} == START_TAG_TOKEN) {
        if ({
             tr => (($self->{insertion_mode} & IM_MASK) != IN_ROW_IM),
             th => 1, td => 1,
            }->{$self->{t}->{tag_name}}) {
          if (($self->{insertion_mode} & IM_MASK) == IN_TABLE_IM) {
            ## Clear back to table context
            while (not ($self->{open_elements}->[-1]->[1]
                            & TABLE_SCOPING_EL)) {
              
              pop @{$self->{open_elements}};
            }
            
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'tbody']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'tbody'} || 0];
    }
  
            $self->{insertion_mode} = IN_TABLE_BODY_IM;
            ## reprocess in the "in table body" insertion mode...
          }
          
          if (($self->{insertion_mode} & IM_MASK) == IN_TABLE_BODY_IM) {
            unless ($self->{t}->{tag_name} eq 'tr') {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'missing start tag:tr', token => $self->{t});
            }
                
            ## Clear back to table body context
            while (not ($self->{open_elements}->[-1]->[1]
                            & TABLE_ROWS_SCOPING_EL)) {
              
              ## ISSUE: Can this case be reached?
              pop @{$self->{open_elements}};
            }
                
            $self->{insertion_mode} = IN_ROW_IM;
            if ($self->{t}->{tag_name} eq 'tr') {
              
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
              $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
              
              $self->{t} = $self->_get_next_token;
              next B;
            } else {
              
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'tr']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'tr'} || 0];
    }
  
              ## reprocess in the "in row" insertion mode
            }
          } else {
            
          }

              ## Clear back to table row context
              while (not ($self->{open_elements}->[-1]->[1]
                              & TABLE_ROW_SCOPING_EL)) {
                
                pop @{$self->{open_elements}};
              }
              
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
          $self->{insertion_mode} = IN_CELL_IM;

          push @$active_formatting_elements, ['#marker', '', undef];
          
          
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ({
                  caption => 1, col => 1, colgroup => 1,
                  tbody => 1, tfoot => 1, thead => 1,
                  tr => 1, # $self->{insertion_mode} == IN_ROW_IM
                 }->{$self->{t}->{tag_name}}) {
          if (($self->{insertion_mode} & IM_MASK) == IN_ROW_IM) {
            ## XXXgeneratetoken
            ## As if </tr>
            ## have an element in table scope
            my $i;
            INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
              my $node = $self->{open_elements}->[$_];
              if ($node->[1] == TABLE_ROW_EL) {
                
                $i = $_;
                last INSCOPE;
              } elsif ($node->[1] & TABLE_SCOPING_EL) {
                
                last INSCOPE;
              }
            } # INSCOPE
            unless (defined $i) { 
              
              ## TODO: This type is wrong.
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmacthed end tag',
                              text => $self->{t}->{tag_name}, token => $self->{t});
              ## Ignore the token
              
              $self->{t} = $self->_get_next_token;
              next B;
            }
                
                ## Clear back to table row context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_ROW_SCOPING_EL)) {
                  
                  ## ISSUE: Can this case be reached?
                  pop @{$self->{open_elements}};
                }
                
                pop @{$self->{open_elements}}; # tr
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                if ($self->{t}->{tag_name} eq 'tr') {
                  
                  ## reprocess
                  
                  next B;
                } else {
                  
                  ## reprocess in the "in table body" insertion mode...
                }
              }

              if (($self->{insertion_mode} & IM_MASK) == IN_TABLE_BODY_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] == TABLE_ROW_GROUP_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
## TODO: This erorr type is wrong.
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $self->{t}->{tag_name}, token => $self->{t});
                  ## Ignore the token
                  
                  $self->{t} = $self->_get_next_token;
                  next B;
                }

                ## Clear back to table body context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_ROWS_SCOPING_EL)) {
                  
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

          if ($self->{t}->{tag_name} eq 'col') {
            ## Clear back to table context
            while (not ($self->{open_elements}->[-1]->[1]
                            & TABLE_SCOPING_EL)) {
              
              ## ISSUE: Can this state be reached?
              pop @{$self->{open_elements}};
            }
            
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'colgroup']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'colgroup'} || 0];
    }
  
            $self->{insertion_mode} = IN_COLUMN_GROUP_IM;
            ## reprocess
            $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
            
            next B;
          } elsif ({
                    caption => 1,
                    colgroup => 1,
                    tbody => 1, tfoot => 1, thead => 1,
                   }->{$self->{t}->{tag_name}}) {
            ## Clear back to table context
            while (not ($self->{open_elements}->[-1]->[1]
                        & TABLE_SCOPING_EL)) {
              
              ## ISSUE: Can this state be reached?
              pop @{$self->{open_elements}};
            }
            
            push @$active_formatting_elements, ['#marker', '', undef]
                if $self->{t}->{tag_name} eq 'caption';
            
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
            $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
            $self->{insertion_mode} = {
                                       caption => IN_CAPTION_IM,
                                       colgroup => IN_COLUMN_GROUP_IM,
                                       tbody => IN_TABLE_BODY_IM,
                                       tfoot => IN_TABLE_BODY_IM,
                                       thead => IN_TABLE_BODY_IM,
                                      }->{$self->{t}->{tag_name}};
            $self->{t} = $self->_get_next_token;
            
            next B;
          } else {
            die "$0: in table: <>: $self->{t}->{tag_name}";
          }
            } elsif ($self->{t}->{tag_name} eq 'table') {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $self->{t});

              ## XXXgeneratetoken
              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] == TABLE_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
## TODO: The following is wrong, maybe.
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag', text => 'table',
                                token => $self->{t});
                ## Ignore tokens </table><table>
                
                $self->{t} = $self->_get_next_token;
                next B;
              }
              
## TODO: Followings are removed from the latest spec. 
              ## generate implied end tags
              while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
                
                pop @{$self->{open_elements}};
              }

              unless ($self->{open_elements}->[-1]->[1] == TABLE_EL) {
                
                ## NOTE: |<table><tr><table>|
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                text => $self->{open_elements}->[-1]->[0]
                                    ->manakai_local_name,
                                token => $self->{t});
              } else {
                
              }

              splice @{$self->{open_elements}}, $i;
              pop @{$open_tables};

              $self->_reset_insertion_mode; 

          ## reprocess
          
          next B;
        } elsif ($self->{t}->{tag_name} eq 'style') {
          
          ## NOTE: This is a "as if in head" code clone.
          $parse_rcdata->($self, $insert, $open_tables, 0); # RAWTEXT
          $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
          next B;
        } elsif ($self->{t}->{tag_name} eq 'script') {
          
          ## NOTE: This is a "as if in head" code clone.
          $script_start_tag->($self, $insert, $open_tables);
          $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted
          next B;
        } elsif ($self->{t}->{tag_name} eq 'input') {
          if ($self->{t}->{attributes}->{type}) {
            my $type = $self->{t}->{attributes}->{type}->{value};
            $type =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
            if ($type eq 'hidden') {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table',
                              text => $self->{t}->{tag_name}, token => $self->{t});

              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
              $open_tables->[-1]->[2] = 0 if @$open_tables; # ~node inserted

              ## TODO: form element pointer

              pop @{$self->{open_elements}};

              $self->{t} = $self->_get_next_token;
              delete $self->{self_closing};
              next B;
            } else {
              
              #
            }
          } else {
            
            #
          }
        } elsif ($self->{t}->{tag_name} eq 'form') {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'form in table', token => $self->{t}); # XXX documentation
          
          if ($self->{form_element}) {
            ## Ignore the token.
            $self->{t} = $self->_get_next_token;
            
            next B;
          } else {
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
            $self->{form_element} = $self->{open_elements}->[-1]->[0];
            
            pop @{$self->{open_elements}};
            
            $self->{t} = $self->_get_next_token;
            
            next B;
          }
        } else {
          
          #
        }

        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table', text => $self->{t}->{tag_name},
                        token => $self->{t});

        $self->{insert} = $insert = $insert_to_foster;
        #
      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'tr' and
            ($self->{insertion_mode} & IM_MASK) == IN_ROW_IM) {
          ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] == TABLE_ROW_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                
                $self->{t} = $self->_get_next_token;
                next B;
              } else {
                
              }

              ## Clear back to table row context
              while (not ($self->{open_elements}->[-1]->[1]
                              & TABLE_ROW_SCOPING_EL)) {
                
## ISSUE: Can this state be reached?
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}}; # tr
              $self->{insertion_mode} = IN_TABLE_BODY_IM;
              $self->{t} = $self->_get_next_token;
              
              next B;
            } elsif ($self->{t}->{tag_name} eq 'table') {
              if (($self->{insertion_mode} & IM_MASK) == IN_ROW_IM) {
                ## XXXgeneratetoken
                ## As if </tr>
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] == TABLE_ROW_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
## TODO: The following is wrong.
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $self->{t}->{type}, token => $self->{t});
                  ## Ignore the token
                  
                  $self->{t} = $self->_get_next_token;
                  next B;
                }
                
                ## Clear back to table row context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_ROW_SCOPING_EL)) {
                  
## ISSUE: Can this state be reached?
                  pop @{$self->{open_elements}};
                }
                
                pop @{$self->{open_elements}}; # tr
                $self->{insertion_mode} = IN_TABLE_BODY_IM;
                ## reprocess in the "in table body" insertion mode...
              }

              if (($self->{insertion_mode} & IM_MASK) == IN_TABLE_BODY_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] == TABLE_ROW_GROUP_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $self->{t}->{tag_name}, token => $self->{t});
                  ## Ignore the token
                  
                  $self->{t} = $self->_get_next_token;
                  next B;
                }
                
                ## Clear back to table body context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_ROWS_SCOPING_EL)) {
                  
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
                if ($node->[1] == TABLE_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                
                $self->{t} = $self->_get_next_token;
                next B;
              }
                
              splice @{$self->{open_elements}}, $i;
              pop @{$open_tables};
              
              $self->_reset_insertion_mode;
              
              $self->{t} = $self->_get_next_token;
              next B;
            } elsif ({
                      tbody => 1, tfoot => 1, thead => 1,
                     }->{$self->{t}->{tag_name}} and
                     $self->{insertion_mode} & ROW_IMS) {
              if (($self->{insertion_mode} & IM_MASK) == IN_ROW_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[0]->manakai_local_name eq $self->{t}->{tag_name}) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
                    $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                    text => $self->{t}->{tag_name}, token => $self->{t});
                    ## Ignore the token
                    
                    $self->{t} = $self->_get_next_token;
                    next B;
                  }
                
                ## XXXgeneratetoken
                ## As if </tr>
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] == TABLE_ROW_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
                    $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                    text => 'tr', token => $self->{t});
                    ## Ignore the token
                    
                    $self->{t} = $self->_get_next_token;
                    next B;
                  }
                
                ## Clear back to table row context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_ROW_SCOPING_EL)) {
                  
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
                if ($node->[0]->manakai_local_name eq $self->{t}->{tag_name}) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $self->{t}->{tag_name}, token => $self->{t});
                ## Ignore the token
                
                $self->{t} = $self->_get_next_token;
                next B;
              }

              ## Clear back to table body context
              while (not ($self->{open_elements}->[-1]->[1]
                              & TABLE_ROWS_SCOPING_EL)) {
                
## ISSUE: Can this case be reached?
                pop @{$self->{open_elements}};
              }

              pop @{$self->{open_elements}};
              $self->{insertion_mode} = IN_TABLE_IM;
              
              $self->{t} = $self->_get_next_token;
              next B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, td => 1, th => 1,
                      tr => 1, # $self->{insertion_mode} == IN_ROW_IM
                      tbody => 1, tfoot => 1, thead => 1, # $self->{insertion_mode} == IN_TABLE_IM
                     }->{$self->{t}->{tag_name}}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## Ignore the token
          
           $self->{t} = $self->_get_next_token;
          next B;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table:/',
                          text => $self->{t}->{tag_name}, token => $self->{t});

          $self->{insert} = $insert = $insert_to_foster;
          #
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        unless ($self->{open_elements}->[-1]->[1] == HTML_EL and
                @{$self->{open_elements}} == 1) { # redundant, maybe
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $self->{t});
          
          #
        } else {
          
          #
        }

        ## Stop parsing
        last B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }
    } elsif (($self->{insertion_mode} & IM_MASK) == IN_COLUMN_GROUP_IM) {
          if ($self->{t}->{type} == CHARACTER_TOKEN) {
            if ($self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              unless (length $self->{t}->{data}) {
                
                $self->{t} = $self->_get_next_token;
                next B;
              }
            }
            
            
            #
          } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
            if ($self->{t}->{tag_name} eq 'col') {
              
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
              pop @{$self->{open_elements}};
              delete $self->{self_closing};
              $self->{t} = $self->_get_next_token;
              next B;
            } else { 
              
              #
            }
          } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
            if ($self->{t}->{tag_name} eq 'colgroup') {
              if ($self->{open_elements}->[-1]->[1] == HTML_EL) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => 'colgroup', token => $self->{t});
                ## Ignore the token
                $self->{t} = $self->_get_next_token;
                next B;
              } else {
                
                pop @{$self->{open_elements}}; # colgroup
                $self->{insertion_mode} = IN_TABLE_IM;
                $self->{t} = $self->_get_next_token;
                next B;             
              }
            } elsif ($self->{t}->{tag_name} eq 'col') {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => 'col', token => $self->{t});
              ## Ignore the token
              $self->{t} = $self->_get_next_token;
              next B;
            } else {
              
              # 
            }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        if ($self->{open_elements}->[-1]->[1] == HTML_EL and
            @{$self->{open_elements}} == 1) { # redundant, maybe
          
          ## Stop parsing.
          last B;
        } else {
          ## XXXgeneratetoken
          ## NOTE: As if </colgroup>.
          
          pop @{$self->{open_elements}}; # colgroup
          $self->{insertion_mode} = IN_TABLE_IM;
          ## Reprocess.
          next B;
        }
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }

          ## XXXgeneratetoken
          ## As if </colgroup>
          if ($self->{open_elements}->[-1]->[1] == HTML_EL) {
            
## TODO: Wrong error type?
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => 'colgroup', token => $self->{t});
            ## Ignore the token
            
            $self->{t} = $self->_get_next_token;
            next B;
          } else {
            
            pop @{$self->{open_elements}}; # colgroup
            $self->{insertion_mode} = IN_TABLE_IM;
            
            ## reprocess
            next B;
          }
    } elsif ($self->{insertion_mode} & SELECT_IMS) {
      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        
        my $data = $self->{t}->{data};
        while ($data =~ s/\x00//) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL', token => $self->{t});
        }
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($data)
            if $data ne '';
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'option') {
          if ($self->{open_elements}->[-1]->[1] == OPTION_EL) {
            
            ## XXXgeneratetoken
            ## As if </option>
            pop @{$self->{open_elements}};
          } else {
            
          }

          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'optgroup') {
          if ($self->{open_elements}->[-1]->[1] == OPTION_EL) {
            
            ## XXXgenereatetoken
            ## As if </option>
            pop @{$self->{open_elements}};
          } else {
            
          }

          if ($self->{open_elements}->[-1]->[1] == OPTGROUP_EL) {
            
            ## XXXgeneratetoken
            ## As if </optgroup>
            pop @{$self->{open_elements}};
          } else {
            
          }

          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          
          $self->{t} = $self->_get_next_token;
          next B;

        } elsif ($self->{t}->{tag_name} eq 'select') {
          ## "In select" / "in select in table" insertion mode,
          ## "select" start tag.
          

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'select in select', ## XXX: documentation
                          token => $self->{t});

          ## XXXgenereatetoken
          ## Act as if the token were </select>.
          $self->{t} = {type => END_TAG_TOKEN, tag_name => 'select',
                    line => $self->{t}->{line}, column => $self->{t}->{column}};
          next B;

        } elsif ({
          input => 1, textarea => 1, keygen => 1,
        }->{$self->{t}->{tag_name}}) {
          ## "In select" / "in select in table" insertion mode,
          ## "input", "keygen", "textarea" start tag.

          ## Parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'select',
                          token => $self->{t});

          ## If there "have an element in select scope" where element
          ## is a |select| element.
          my $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[1] == SELECT_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] == OPTGROUP_EL or
                     $node->[1] == OPTION_EL) {
              
              #
            } else {
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            ## Ignore the token.
            
            $self->{t} = $self->_get_next_token;
            next B;
          }

          ## Otherwise, act as if there were </select>, then reprocess
          ## the token.
          
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
    
          $self->{t} = {type => END_TAG_TOKEN, tag_name => 'select',
                    line => $self->{t}->{line}, column => $self->{t}->{column}};
          next B;

        } elsif (
          ($self->{insertion_mode} & IM_MASK) == IN_SELECT_IN_TABLE_IM and
          {
            caption => 1, table => 1, tbody => 1, tfoot => 1, thead => 1,
            tr => 1, td => 1, th => 1,
          }->{$self->{t}->{tag_name}}
        ) {
          ## "In select in table" insertion mode, table-related start
          ## tags.

          ## Parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'select',
                          token => $self->{t});

          ## Act as if there were </select>, then reprocess the token.
          
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
    
          $self->{t} = {type => END_TAG_TOKEN, tag_name => 'select',
                    line => $self->{t}->{line}, column => $self->{t}->{column}};
          next B;

        } elsif ($self->{t}->{tag_name} eq 'script') {
          
          ## NOTE: This is an "as if in head" code clone
          $script_start_tag->($self, $insert, $open_tables);
          next B;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in select',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## Ignore the token
          
          $self->{t} = $self->_get_next_token;
          next B;
        }

      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'optgroup') {
          if ($self->{open_elements}->[-1]->[1] == OPTION_EL and
              $self->{open_elements}->[-2]->[1] == OPTGROUP_EL) {
            
            ## XXXgeneratetoken
            ## As if </option>
            splice @{$self->{open_elements}}, -2;
          } elsif ($self->{open_elements}->[-1]->[1] == OPTGROUP_EL) {
            
            pop @{$self->{open_elements}};
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            ## Ignore the token
          }
          
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'option') {
          if ($self->{open_elements}->[-1]->[1] == OPTION_EL) {
            
            pop @{$self->{open_elements}};
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            ## Ignore the token
          }
          
          $self->{t} = $self->_get_next_token;
          next B;

        } elsif ($self->{t}->{tag_name} eq 'select') {
          ## "In select" / "in select in table" insertion mode,
          ## "select" end tag.

          ## There "have an element in select scope" where the element
          ## is |select|.
          my $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[1] == SELECT_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] == OPTION_EL or
                     $node->[1] == OPTGROUP_EL) {
              
              #
            } else {
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            ## Ignore the token.
            
            $self->{t} = $self->_get_next_token;
            next B;
          }
          
          ## Otherwise,
          
          splice @{$self->{open_elements}}, $i;

          $self->_reset_insertion_mode;

          
          $self->{t} = $self->_get_next_token;
          next B;

        } elsif (
          ($self->{insertion_mode} & IM_MASK) == IN_SELECT_IN_TABLE_IM and
          {
            caption => 1, table => 1, tbody => 1, tfoot => 1, thead => 1,
            tr => 1, td => 1, th => 1,
          }->{$self->{t}->{tag_name}}
        ) {
          ## "In select in table" insertion mode, table-related end
          ## tags.

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});

          ## There "have an element in table scope" where the element
          ## is same tag name as |$self->{t}|.
          my $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[0]->manakai_local_name eq $self->{t}->{tag_name}) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] & TABLE_SCOPING_EL) {
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            
            ## Ignore the token
            
            $self->{t} = $self->_get_next_token;
            next B;
          }
          
          ## Act as if there were </select>, then reprocess the token.
          
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
    
          $self->{t} = {type => END_TAG_TOKEN, tag_name => 'select',
                    line => $self->{t}->{line}, column => $self->{t}->{column}};
          next B;

        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in select:/',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## Ignore the token
          
          $self->{t} = $self->_get_next_token;
          next B;
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        unless ($self->{open_elements}->[-1]->[1] == HTML_EL and
                @{$self->{open_elements}} == 1) { # redundant, maybe
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $self->{t});
        } else {
          
        }

        ## Stop parsing.
        last B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} & BODY_AFTER_IMS) {
      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        if ($self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
          my $data = $1;
          ## As if in body
          $reconstruct_active_formatting_elements
              ->($self, $insert_to_current, $active_formatting_elements,
                 $open_tables);
              
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          
          unless (length $self->{t}->{data}) {
            
            $self->{t} = $self->_get_next_token;
            next B;
          }
        }
        
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html:#text', token => $self->{t});
          #
        } else {
          
          ## "after body" insertion mode
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after body:#text', token => $self->{t});
          #
        }

        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        next B;
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          #
        } else {
          
          ## "after body" insertion mode
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after body',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          #
        }

        $self->{insertion_mode} = IN_BODY_IM;
        
        ## reprocess
        next B;
      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html:/',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          
          $self->{insertion_mode} = IN_BODY_IM;
          ## Reprocess.
          next B;
        } else {
          
        }

        ## "after body" insertion mode
        if ($self->{t}->{tag_name} eq 'html') {
          if (defined $self->{inner_html_node}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => 'html', token => $self->{t});
            ## Ignore the token
            $self->{t} = $self->_get_next_token;
            next B;
          } else {
            
            $self->{insertion_mode} = AFTER_HTML_BODY_IM;
            $self->{t} = $self->_get_next_token;
            next B;
          }
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after body:/',
                          text => $self->{t}->{tag_name}, token => $self->{t});

          $self->{insertion_mode} = IN_BODY_IM;
          ## reprocess
          next B;
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        
        ## Stop parsing
        last B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} & FRAME_IMS) {
      if ($self->{t}->{type} == CHARACTER_TOKEN) {
        if ($self->{t}->{data} =~ s/^([\x09\x0A\x0C\x20]+)//) {
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          
          unless (length $self->{t}->{data}) {
            
            $self->{t} = $self->_get_next_token;
            next B;
          }
        }
        
        if ($self->{t}->{data} =~ s/^[^\x09\x0A\x0C\x20]+//) {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in frameset:#text', token => $self->{t});
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after frameset:#text', token => $self->{t});
          } else { # "after after frameset"
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html:#text', token => $self->{t});
          }
          
          ## Ignore the token.
          if (length $self->{t}->{data}) {
            
            ## reprocess the rest of characters
          } else {
            
            $self->{t} = $self->_get_next_token;
          }
          next B;
        }
        
        die qq[$0: Character "$self->{t}->{data}"];
      } elsif ($self->{t}->{type} == START_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'frame' and
                 $self->{insertion_mode} == IN_FRAMESET_IM) {
          
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
          pop @{$self->{open_elements}};
          delete $self->{self_closing};
          $self->{t} = $self->_get_next_token;
          next B;
        } elsif ($self->{t}->{tag_name} eq 'noframes') {
          
          ## NOTE: As if in head.
          $parse_rcdata->($self, $insert, $open_tables, 0); # RAWTEXT
          next B;

          ## NOTE: |<!DOCTYPE HTML><frameset></frameset></html><noframes></noframes>|
          ## has no parse error.
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in frameset',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after frameset',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          } else { # "after after frameset"
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after after frameset',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          }
          ## Ignore the token
          
          $self->{t} = $self->_get_next_token;
          next B;
        }
      } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
        if ($self->{t}->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          if ($self->{open_elements}->[-1]->[1] == HTML_EL and
              @{$self->{open_elements}} == 1) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name}, token => $self->{t});
            ## Ignore the token
            $self->{t} = $self->_get_next_token;
          } else {
            
            pop @{$self->{open_elements}};
            $self->{t} = $self->_get_next_token;
          }

          if (not defined $self->{inner_html_node} and
              not ($self->{open_elements}->[-1]->[1] == FRAMESET_EL)) {
            
            $self->{insertion_mode} = AFTER_FRAMESET_IM;
          } else {
            
          }
          next B;
        } elsif ($self->{t}->{tag_name} eq 'html' and
                 $self->{insertion_mode} == AFTER_FRAMESET_IM) {
          
          $self->{insertion_mode} = AFTER_HTML_FRAMESET_IM;
          $self->{t} = $self->_get_next_token;
          next B;
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in frameset:/',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after frameset:/',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          } else { # "after after html"
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after after frameset:/',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          }
          ## Ignore the token
          $self->{t} = $self->_get_next_token;
          next B;
        }
      } elsif ($self->{t}->{type} == END_OF_FILE_TOKEN) {
        unless ($self->{open_elements}->[-1]->[1] == HTML_EL and
                @{$self->{open_elements}} == 1) { # redundant, maybe
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $self->{t});
        } else {
          
        }
        
        ## Stop parsing
        last B;
      } else {
        die "$0: $self->{t}->{type}: Unknown token type";
      }
    } else {
      die "$0: $self->{insertion_mode}: Unknown insertion mode";
    }

    ## "in body" insertion mode
    if ($self->{t}->{type} == START_TAG_TOKEN) {
      if ($self->{t}->{tag_name} eq 'script') {
        
        ## NOTE: This is an "as if in head" code clone
        $script_start_tag->($self, $insert, $open_tables);
        next B;
      } elsif ($self->{t}->{tag_name} eq 'style') {
        
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->($self, $insert, $open_tables, 0); # RAWTEXT
        next B;
      } elsif ({
        base => 1, command => 1, link => 1, basefont => 1, bgsound => 1,
      }->{$self->{t}->{tag_name}}) {
        
        ## NOTE: This is an "as if in head" code clone, only "-t" differs
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        pop @{$self->{open_elements}};
        delete $self->{self_closing};
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'meta') {
        ## NOTE: This is an "as if in head" code clone, only "-t" differs
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        my $meta_el = pop @{$self->{open_elements}};

        unless ($self->{confident}) {
          if ($self->{t}->{attributes}->{charset}) {
            
            ## NOTE: Whether the encoding is supported or not, an
            ## ASCII-compatible charset is not, is handled in the
            ## |_change_encoding| method.
            if ($self->_change_encoding
                    ($self->{t}->{attributes}->{charset}->{value},
                     $self->{t})) {
              return {type => ABORT_TOKEN};
            }
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                ->set_user_data (manakai_has_reference =>
                                     $self->{t}->{attributes}->{charset}
                                         ->{has_reference});
          } elsif ($self->{t}->{attributes}->{content} and
                   $self->{t}->{attributes}->{'http-equiv'}) {
            if ($self->{t}->{attributes}->{'http-equiv'}->{value}
                =~ /\A[Cc][Oo][Nn][Tt][Ee][Nn][Tt]-[Tt][Yy][Pp][Ee]\z/ and
                $self->{t}->{attributes}->{content}->{value}
                =~ /[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                    [\x09\x0A\x0C\x0D\x20]*=
                    [\x09\x0A\x0C\x0D\x20]*(?>"([^"]*)"|'([^']*)'|
                    ([^"'\x09\x0A\x0C\x0D\x20][^\x09\x0A\x0C\x0D\x20\x3B]*))
                   /x) {
              
              ## NOTE: Whether the encoding is supported or not, an
              ## ASCII-compatible charset is not, is handled in the
              ## |_change_encoding| method.
              if ($self->_change_encoding
                      (defined $1 ? $1 : defined $2 ? $2 : $3,
                       $self->{t})) {
                return {type => ABORT_TOKEN};
              }
              $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                  ->set_user_data (manakai_has_reference =>
                                       $self->{t}->{attributes}->{content}
                                             ->{has_reference});
            }
          }
        } else {
          if ($self->{t}->{attributes}->{charset}) {
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                ->set_user_data (manakai_has_reference =>
                                     $self->{t}->{attributes}->{charset}
                                         ->{has_reference});
          }
          if ($self->{t}->{attributes}->{content}) {
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'content')
                ->set_user_data (manakai_has_reference =>
                                     $self->{t}->{attributes}->{content}
                                         ->{has_reference});
          }
        }

        delete $self->{self_closing};
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'title') {
        
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->($self, $insert, $open_tables, 1); # RCDATA
        next B;

      } elsif ($self->{t}->{tag_name} eq 'body') {
        ## "In body" insertion mode, "body" start tag token.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body', text => 'body', token => $self->{t});
              
        if (@{$self->{open_elements}} == 1 or
            not ($self->{open_elements}->[1]->[1] == BODY_EL)) {
          
          ## Ignore the token
        } else {
          delete $self->{frameset_ok};
          my $body_el = $self->{open_elements}->[1]->[0];
          for my $attr_name (keys %{$self->{t}->{attributes}}) {
            unless ($body_el->has_attribute_ns (undef, $attr_name)) {
              
              $body_el->set_attribute_ns
                (undef, [undef, $attr_name],
                 $self->{t}->{attributes}->{$attr_name}->{value});
            }
          }
        }
        
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'frameset') {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body', text => $self->{t}->{tag_name},
                        token => $self->{t});

        if (@{$self->{open_elements}} == 1 or
            not ($self->{open_elements}->[1]->[1] == BODY_EL)) {
          
          ## Ignore the token.
        } elsif (not $self->{frameset_ok}) {
          
          ## Ignore the token.
        } else {
          
          
          ## 1. Remove the second element.
          my $body = $self->{open_elements}->[1]->[0];
          my $body_parent = $body->parent_node;
          $body_parent->remove_child ($body) if $body_parent;

          ## 2. Pop nodes.
          splice @{$self->{open_elements}}, 1;

          ## 3. Insert.
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  

          ## 4. Switch.
          $self->{insertion_mode} = IN_FRAMESET_IM;
        }

        
        $self->{t} = $self->_get_next_token;
        next B;

      } elsif ({
        ## "In body" insertion mode, non-phrasing flow-content
        ## elements start tags.

        address => 1, article => 1, aside => 1, blockquote => 1,
        center => 1, details => 1, dir => 1, div => 1, dl => 1,
        fieldset => 1, figcaption => 1, figure => 1, footer => 1,
        header => 1, hgroup => 1, menu => 1, nav => 1, ol => 1,
        p => 1, section => 1, ul => 1, summary => 1,
        # datagrid => 1,

        ## Closing any heading element
        h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1, 

        ## Ignoring any leading newline in content
        pre => 1, listing => 1,

        ## Form element pointer
        form => 1,
        
        ## A quirk & switching of insertion mode
        table => 1,

        ## Void element
        hr => 1,
      }->{$self->{t}->{tag_name}}) {

        ## 1. When there is an opening |form| element:
        if ($self->{t}->{tag_name} eq 'form' and defined $self->{form_element}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in form:form', token => $self->{t});
          ## Ignore the token
          
          $self->{t} = $self->_get_next_token;
          next B;
        }

        ## 2. Close the |p| element, if any.
        if ($self->{t}->{tag_name} ne 'table' or # The Hixie Quirk
            $self->{document}->manakai_compat_mode ne 'quirks') {
          ## "have a |p| element in button scope"
          INSCOPE: for (reverse @{$self->{open_elements}}) {
            if ($_->[1] == P_EL) {
              
              
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <form>
              $self->{t} = {type => END_TAG_TOKEN, tag_name => 'p',
                        line => $self->{t}->{line}, column => $self->{t}->{column}};
              next B;
            } elsif ($_->[1] & BUTTON_SCOPING_EL) {
              
              last INSCOPE;
            }
          } # INSCOPE
        }

        ## 3. Close the opening <hn> element, if any.
        if ({h1 => 1, h2 => 1, h3 => 1,
             h4 => 1, h5 => 1, h6 => 1}->{$self->{t}->{tag_name}}) {
          if ($self->{open_elements}->[-1]->[1] == HEADING_EL) {
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[-1]->[0]->manakai_local_name,
                            token => $self->{t});
            pop @{$self->{open_elements}};
          }
        }

        ## 4. Insertion.
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        if ($self->{t}->{tag_name} eq 'pre' or $self->{t}->{tag_name} eq 'listing') {
          
          $self->{t} = $self->_get_next_token;
          if ($self->{t}->{type} == CHARACTER_TOKEN) {
            $self->{t}->{data} =~ s/^\x0A//;
            unless (length $self->{t}->{data}) {
              
              $self->{t} = $self->_get_next_token;
            } else {
              
            }
          } else {
            
          }

          delete $self->{frameset_ok};
        } elsif ($self->{t}->{tag_name} eq 'form') {
          
          $self->{form_element} = $self->{open_elements}->[-1]->[0];

          
          $self->{t} = $self->_get_next_token;
        } elsif ($self->{t}->{tag_name} eq 'table') {
          
          push @{$open_tables}, [$self->{open_elements}->[-1]->[0]];

          delete $self->{frameset_ok};
          
          $self->{insertion_mode} = IN_TABLE_IM;

          
          $self->{t} = $self->_get_next_token;
        } elsif ($self->{t}->{tag_name} eq 'hr') {
          
          pop @{$self->{open_elements}};
          
          delete $self->{self_closing};

          delete $self->{frameset_ok};

          $self->{t} = $self->_get_next_token;
        } else {
          
          $self->{t} = $self->_get_next_token;
        }
        next B;

      } elsif ($self->{t}->{tag_name} eq 'li') {
        ## "In body" insertion mode, "li" start tag.  As normal, but
        ## imply </li> when there's another <li>.

        ## NOTE: Special, Scope (<li><foo><li> == <li><foo><li/></foo></li>)::
          ## Interpreted as <li><foo/></li><li/> (non-conforming):
          ## blockquote (O9.27), center (O), dd (Fx3, O, S3.1.2, IE7),
          ## dt (Fx, O, S, IE), dl (O), fieldset (O, S, IE), form (Fx, O, S),
          ## hn (O), pre (O), applet (O, S), button (O, S), marquee (Fx, O, S),
          ## object (Fx)
          ## Generate non-tree (non-conforming):
          ## basefont (IE7 (where basefont is non-void)), center (IE),
          ## form (IE), hn (IE)
        ## address, div, p (<li><foo><li> == <li><foo/></li><li/>)::
          ## Interpreted as <li><foo><li/></foo></li> (non-conforming):
          ## div (Fx, S)

        ## 1. Frameset-ng
        delete $self->{frameset_ok};

        my $non_optional;
        my $i = -1;

        ## 2.
        for my $node (reverse @{$self->{open_elements}}) {
          if ($node->[1] == LI_EL) {
            ## XXXgeneratetoken
            ## 3. (a) As if </li>
            {
              ## If no </li> - not applied
              #

              ## Otherwise

              ## 1. generate implied end tags, except for </li>
              #

              ## 2. If current node != "li", parse error
              if ($non_optional) {
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                text => $non_optional->[0]->manakai_local_name,
                                token => $self->{t});
                
              } else {
                
              }

              ## 3. Pop
              splice @{$self->{open_elements}}, $i;
            }

            last; ## 3. (b) goto 5.
          } elsif (
                   ## NOTE: "special" category
                   ($node->[1] & SPECIAL_EL or
                    $node->[1] & SCOPING_EL) and
                   ## NOTE: "li", "dt", and "dd" are in |SPECIAL_EL|.
                   (not $node->[1] & ADDRESS_DIV_P_EL)
                  ) {
            ## 4.
            
            last; ## goto 6.
          } elsif ($node->[1] & END_TAG_OPTIONAL_EL) {
            
            #
          } else {
            
            $non_optional ||= $node;
            #
          }
          ## 5.
          ## goto 3.
          $i--;
        }

        ## 6. (a) "have a |p| element in button scope".
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] == P_EL) {
            

            ## NOTE: |<p><li>|, for example.

            
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <x>
            $self->{t} = {type => END_TAG_TOKEN, tag_name => 'p',
                      line => $self->{t}->{line}, column => $self->{t}->{column}};
            next B;
          } elsif ($_->[1] & BUTTON_SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        ## 6. (b) insert
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        
        $self->{t} = $self->_get_next_token;
        next B;

      } elsif ($self->{t}->{tag_name} eq 'dt' or $self->{t}->{tag_name} eq 'dd') {
        ## "In body" insertion mode, "dt" or "dd" start tag.  As
        ## normal, but imply </dt> or </dd> when there's antoher <dt>
        ## or <dd>.

        ## 1. Frameset-ng
        delete $self->{frameset_ok};

        my $non_optional;
        my $i = -1;

        ## 2.
        for my $node (reverse @{$self->{open_elements}}) {
          if ($node->[1] == DTDD_EL) {
            ## XXXgeneratetoken
            ## 3. (a) As if </li>
            {
              ## If no </li> - not applied
              #

              ## Otherwise

              ## 1. generate implied end tags, except for </dt> or </dd>
              #

              ## 2. If current node != "dt"|"dd", parse error
              if ($non_optional) {
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                text => $non_optional->[0]->manakai_local_name,
                                token => $self->{t});
                
              } else {
                
              }

              ## 3. Pop
              splice @{$self->{open_elements}}, $i;
            }

            last; ## 3. (b) goto 5.
          } elsif (
                   ## NOTE: "special" category
                   ($node->[1] & SPECIAL_EL or $node->[1] & SCOPING_EL) and
                   ## NOTE: "li", "dt", and "dd" are in |SPECIAL_EL|.

                   (not $node->[1] & ADDRESS_DIV_P_EL)
                  ) {
            ## 4.
            
            last; ## goto 5.
          } elsif ($node->[1] & END_TAG_OPTIONAL_EL) {
            
            #
          } else {
            
            $non_optional ||= $node;
            #
          }
          ## 5.
          ## goto 3.
          $i--;
        }

        ## 6. (a) "have a |p| element in button scope".
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] == P_EL) {
            
            
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <x>
            $self->{t} = {type => END_TAG_TOKEN, tag_name => 'p',
                      line => $self->{t}->{line}, column => $self->{t}->{column}};
            next B;
          } elsif ($_->[1] & BUTTON_SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        ## 6. (b) insert
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        
        $self->{t} = $self->_get_next_token;
        next B;

      } elsif ($self->{t}->{tag_name} eq 'plaintext') {
        ## "In body" insertion mode, "plaintext" start tag.  As
        ## normal, but effectively ends parsing.

        ## "has a |p| element in scope".
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] == P_EL) {
            
            
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <plaintext>
            $self->{t} = {type => END_TAG_TOKEN, tag_name => 'p',
                      line => $self->{t}->{line}, column => $self->{t}->{column}};
            next B;
          } elsif ($_->[1] & BUTTON_SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        
        $self->{state} = PLAINTEXT_STATE;
          
        
        $self->{t} = $self->_get_next_token;
        next B;

      } elsif ($self->{t}->{tag_name} eq 'a') {
        AFE: for my $i (reverse 0..$#$active_formatting_elements) {
          my $node = $active_formatting_elements->[$i];
          if ($node->[1] == A_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in a:a', token => $self->{t});
            
            
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <a>
            $self->{t} = {type => END_TAG_TOKEN, tag_name => 'a',
                      line => $self->{t}->{line}, column => $self->{t}->{column}};
            $formatting_end_tag->($self, $active_formatting_elements,
                                  $open_tables, $self->{t});
            
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
        
        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);

        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        push_afe [$self->{open_elements}->[-1]->[0],
                  $self->{open_elements}->[-1]->[1],
                  $self->{t}]
            => $active_formatting_elements;

        
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'nobr') {
        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);

        ## has a |nobr| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] == NOBR_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in nobr:nobr', token => $self->{t});
            
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <nobr>
            $self->{t} = {type => END_TAG_TOKEN, tag_name => 'nobr',
                      line => $self->{t}->{line}, column => $self->{t}->{column}};
            next B;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        push_afe [$self->{open_elements}->[-1]->[0],
                  $self->{open_elements}->[-1]->[1],
                  $self->{t}]
            => $active_formatting_elements;
        
        
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'button') {
        ## has a button element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] == BUTTON_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in button:button', token => $self->{t});
            
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <button>
            $self->{t} = {type => END_TAG_TOKEN, tag_name => 'button',
                      line => $self->{t}->{line}, column => $self->{t}->{column}};
            next B;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
          
        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  

        ## TODO: associate with $self->{form_element} if defined

        delete $self->{frameset_ok};

        
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ({
                xmp => 1,
                iframe => 1,
                noembed => 1,
                noframes => 1, ## NOTE: This is an "as if in head" code clone.
                noscript => 0, ## TODO: 1 if scripting is enabled
               }->{$self->{t}->{tag_name}}) {
        if ($self->{t}->{tag_name} eq 'xmp') {
          ## "In body" insertion mode, "xmp" start tag.  As normal
          ## flow-content element start tag, but CDATA parsing.
          

          ## "have a |p| element in button scope".
          INSCOPE: for (reverse @{$self->{open_elements}}) {
            if ($_->[1] == P_EL) {
              
              
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <xmp>
              $self->{t} = {type => END_TAG_TOKEN, tag_name => 'p',
                        line => $self->{t}->{line}, column => $self->{t}->{column}};
              next B;
            } elsif ($_->[1] & BUTTON_SCOPING_EL) {
              
              last INSCOPE;
            }
          } # INSCOPE

          my $insert = $self->{insertion_mode} & TABLE_IMS
              ? $insert_to_foster : $insert_to_current;
          $reconstruct_active_formatting_elements
              ->($self, $insert, $active_formatting_elements,
                 $open_tables);

          delete $self->{frameset_ok};
        } elsif ($self->{t}->{tag_name} eq 'iframe') {
          
          delete $self->{frameset_ok};
        } else {
          
        }
        ## NOTE: There is an "as if in body" code clone.
        $parse_rcdata->($self, $insert, $open_tables, 0); # RAWTEXT
        next B;
      } elsif ($self->{t}->{tag_name} eq 'isindex') {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'isindex', token => $self->{t});
        
        if (defined $self->{form_element}) {
          
          ## Ignore the token
           ## NOTE: Not acknowledged.
          $self->{t} = $self->_get_next_token;
          next B;
        } else {
          delete $self->{self_closing};

          my $at = $self->{t}->{attributes};
          my $form_attrs;
          $form_attrs->{action} = $at->{action} if $at->{action};
          my $prompt_attr = $at->{prompt};
          $at->{name} = {name => 'name', value => 'isindex'};
          delete $at->{action};
          delete $at->{prompt};
          my @tokens = (
                        {type => START_TAG_TOKEN, tag_name => 'form',
                         attributes => $form_attrs,
                         line => $self->{t}->{line}, column => $self->{t}->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'hr',
                         line => $self->{t}->{line}, column => $self->{t}->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'label',
                         line => $self->{t}->{line}, column => $self->{t}->{column}},
                       );
          if ($prompt_attr) {
            
            push @tokens, {type => CHARACTER_TOKEN, data => $prompt_attr->{value},
                           #line => $self->{t}->{line}, column => $self->{t}->{column},
                          };
          } else {
            
            push @tokens, {type => CHARACTER_TOKEN,
                           data => 'This is a searchable index. Enter search keywords: ',
                           #line => $self->{t}->{line}, column => $self->{t}->{column},
                          }; # SHOULD
            ## TODO: make this configurable
          }
          push @tokens,
                        {type => START_TAG_TOKEN, tag_name => 'input', attributes => $at,
                         line => $self->{t}->{line}, column => $self->{t}->{column}},
                        #{type => CHARACTER_TOKEN, data => ''}, # SHOULD
                        {type => END_TAG_TOKEN, tag_name => 'label',
                         line => $self->{t}->{line}, column => $self->{t}->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'hr',
                         line => $self->{t}->{line}, column => $self->{t}->{column}},
                        {type => END_TAG_TOKEN, tag_name => 'form',
                         line => $self->{t}->{line}, column => $self->{t}->{column}};
          unshift @{$self->{token}}, (@tokens);
          $self->{t} = $self->_get_next_token;
          next B;
        }
      } elsif ($self->{t}->{tag_name} eq 'textarea') {
        ## 1. Insert
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        
        ## Step 2 # XXX
        ## TODO: $self->{form_element} if defined

        ## 2. Drop U+000A LINE FEED
        $self->{ignore_newline} = 1;

        ## 3. RCDATA
        $self->{state} = RCDATA_STATE;
        delete $self->{escape}; # MUST

        ## 4., 6. Insertion mode
        $self->{insertion_mode} |= IN_CDATA_RCDATA_IM;

        ## 5. Frameset-ng.
        delete $self->{frameset_ok};

        
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'optgroup' or
               $self->{t}->{tag_name} eq 'option') {
        if ($self->{open_elements}->[-1]->[1] == OPTION_EL) {
          
          ## XXXgeneratetoken
          ## NOTE: As if </option>
          
      $self->{t}->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $self->{t};
      delete $self->{self_closing};
     # <option> or <optgroup>
          $self->{t} = {type => END_TAG_TOKEN, tag_name => 'option',
                    line => $self->{t}->{line}, column => $self->{t}->{column}};
          next B;
        }

        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);

        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  

        
        $self->{t} = $self->_get_next_token;
        redo B;
      } elsif ($self->{t}->{tag_name} eq 'rt' or
               $self->{t}->{tag_name} eq 'rp') {
        ## has a |ruby| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] == RUBY_EL) {
            
            ## generate implied end tags
            while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
              
              pop @{$self->{open_elements}};
            }
            unless ($self->{open_elements}->[-1]->[1] == RUBY_EL) {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $self->{t});
            }
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  

        
        $self->{t} = $self->_get_next_token;
        redo B;
      } elsif ($self->{t}->{tag_name} eq 'math' or
               $self->{t}->{tag_name} eq 'svg') {
        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);

        ## "Adjust MathML attributes" ('math' only) - done in insert-element-f

        ## "adjust SVG attributes" ('svg' only) - done in insert-element-f

        ## "adjust foreign attributes" - done in insert-element-f
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS, [undef,   $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (
          @{
            $foreign_attr_xname->{$attr_name} ||
            [undef, [undef,
                     ($self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS) eq SVG_NS ?
                         ($svg_attr_name->{$attr_name} || $attr_name) :
                     ($self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS) eq MML_NS ?
                         ($mml_attr_name->{$attr_name} || $attr_name) :
                         $attr_name]]
          }
        );
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, ($el_category_f->{$self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS}->{ $self->{t}->{tag_name}} || 0) | FOREIGN_EL | (($self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS) eq SVG_NS ? SVG_EL : ($self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS) eq MML_NS ? MML_EL : 0)];

      if ( $self->{t}->{attributes}->{xmlns} and  $self->{t}->{attributes}->{xmlns}->{value} ne ($self->{t}->{tag_name} eq 'math' ? MML_NS : SVG_NS)) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad namespace', token =>  $self->{t});
## TODO: Error type documentation
      }
      if ( $self->{t}->{attributes}->{'xmlns:xlink'} and
           $self->{t}->{attributes}->{'xmlns:xlink'}->{value} ne q<http://www.w3.org/1999/xlink>) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad namespace', token =>  $self->{t});
      }
    }
  
        
        if ($self->{self_closing}) {
          pop @{$self->{open_elements}};
          delete $self->{self_closing};
        } else {
          
        }

        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                head => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
               }->{$self->{t}->{tag_name}}) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body',
                        text => $self->{t}->{tag_name}, token => $self->{t});
        ## Ignore the token
         ## NOTE: |<col/>| or |<frame/>| here is an error.
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'param' or
               $self->{t}->{tag_name} eq 'source' or
               $self->{t}->{tag_name} eq 'track') {
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  
        pop @{$self->{open_elements}};

        delete $self->{self_closing};
        $self->{t} = $self->_get_next_token;
        redo B;
      } else {
        if ($self->{t}->{tag_name} eq 'image') {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'image', token => $self->{t});
          $self->{t}->{tag_name} = 'img';
        } else {
          
        }

        ## NOTE: There is an "as if <br>" code clone.
        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  $self->{t}->{tag_name}]);
    
        for my $attr_name (keys %{  $self->{t}->{attributes}}) {
          my $attr_t =   $self->{t}->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
      $insert->($self, $el, $open_tables);
      push @{$self->{open_elements}}, [$el, $el_category->{$self->{t}->{tag_name}} || 0];
    }
  

        if ({
             applet => 1, marquee => 1, object => 1,
            }->{$self->{t}->{tag_name}}) {
          

          push @$active_formatting_elements, ['#marker', '', undef];

          delete $self->{frameset_ok};

          
        } elsif ({
                  b => 1, big => 1, code => 1, em => 1, font => 1, i => 1,
                  s => 1, small => 1, strike => 1,
                  strong => 1, tt => 1, u => 1,
                 }->{$self->{t}->{tag_name}}) {
          
          push_afe [$self->{open_elements}->[-1]->[0],
               $self->{open_elements}->[-1]->[1],
               $self->{t}]
              => $active_formatting_elements;
          
        } elsif ($self->{t}->{tag_name} eq 'input') {
          
          ## TODO: associate with $self->{form_element} if defined

          pop @{$self->{open_elements}};

          if ($self->{t}->{attributes}->{type}) {
            my $type = $self->{t}->{attributes}->{type}->{value};
            $type =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
            if ($type eq 'hidden') {
              #
            } else {
              delete $self->{frameset_ok};
            }
          } else {
            delete $self->{frameset_ok};
          }

          delete $self->{self_closing};
        } elsif ({
          area => 1, br => 1, embed => 1, img => 1, wbr => 1, keygen => 1,
        }->{$self->{t}->{tag_name}}) {
          

          pop @{$self->{open_elements}};

          delete $self->{frameset_ok};

          delete $self->{self_closing};
        } elsif ($self->{t}->{tag_name} eq 'select') {
          ## TODO: associate with $self->{form_element} if defined

          delete $self->{frameset_ok};
          
          if ($self->{insertion_mode} & TABLE_IMS or
              $self->{insertion_mode} & BODY_TABLE_IMS) {
            
            $self->{insertion_mode} = IN_SELECT_IN_TABLE_IM;
          } else {
            
            $self->{insertion_mode} = IN_SELECT_IM;
          }
          
        } else {
          
        }
        
        $self->{t} = $self->_get_next_token;
        next B;
      }
    } elsif ($self->{t}->{type} == END_TAG_TOKEN) {
      if ($self->{t}->{tag_name} eq 'body' or $self->{t}->{tag_name} eq 'html') {

        ## 1. If not "have an element in scope":
        ## "has a |body| element in scope"
        my $i;
        INSCOPE: {
          for (reverse @{$self->{open_elements}}) {
            if ($_->[1] == BODY_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($_->[1] & SCOPING_EL) {
              
              last;
            }
          }

          ## NOTE: |<marquee></body>|, |<svg><foreignobject></body>|,
          ## and fragment cases.

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## Ignore the token.  (</body> or </html>)
          $self->{t} = $self->_get_next_token;
          next B;
        } # INSCOPE

        ## 2. If unclosed elements:
        for (@{$self->{open_elements}}) {
          unless ($_->[1] & ALL_END_TAG_OPTIONAL_EL ||
                  $_->[1] == OPTGROUP_EL ||
                  $_->[1] == OPTION_EL ||
                  $_->[1] == RUBY_COMPONENT_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $_->[0]->manakai_local_name,
                            token => $self->{t});
            last;
          } else {
            
          }
        }

        ## 3. Switch the insertion mode.
        $self->{insertion_mode} = AFTER_BODY_IM;
        if ($self->{t}->{tag_name} eq 'body') {
          $self->{t} = $self->_get_next_token;
        } else { # html
          ## Reprocess.
        }
        next B;

      } elsif ({
        ## "In body" insertion mode, end tags for non-phrasing flow
        ## content elements.

                address => 1, article => 1, aside => 1, blockquote => 1,
                center => 1,
                #datagrid => 1,
                details => 1,
                dir => 1, div => 1, dl => 1, fieldset => 1, figure => 1,
                footer => 1, header => 1, hgroup => 1,
                listing => 1, menu => 1, nav => 1,
                ol => 1, pre => 1, section => 1, ul => 1,
                figcaption => 1, summary => 1,

                ## NOTE: As normal, but ... optional tags
                dd => 1, dt => 1, li => 1,

                applet => 1, button => 1, marquee => 1, object => 1,
               }->{$self->{t}->{tag_name}}) {
        ## XXXgeneraetetoken
        ## NOTE: Code for <li> start tags includes "as if </li>" code.
        ## Code for <dt> or <dd> start tags includes "as if </dt> or
        ## </dd>" code.

        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[0]->manakai_local_name eq $self->{t}->{tag_name}) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          } elsif ($self->{t}->{tag_name} eq 'li' and
                   {ul => 1, ol => 1}->{$node->[0]->manakai_local_name}) {
            ## Has an element in list item scope
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## NOTE: Ignore the token.
        } else {
          ## Step 1. generate implied end tags
          while ({
                  ## END_TAG_OPTIONAL_EL
                  dd => ($self->{t}->{tag_name} ne 'dd'),
                  dt => ($self->{t}->{tag_name} ne 'dt'),
                  li => ($self->{t}->{tag_name} ne 'li'),
                  option => 1,
                  optgroup => 1,
                  p => 1,
                  rt => 1,
                  rp => 1,
                 }->{$self->{open_elements}->[-1]->[0]->manakai_local_name}) {
            
            pop @{$self->{open_elements}};
          }

          ## Step 2.
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $self->{t}->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[-1]->[0]
                                ->manakai_local_name,
                            token => $self->{t});
          } else {
            
          }

          ## Step 3.
          splice @{$self->{open_elements}}, $i;

          ## Step 4.
          $clear_up_to_marker->($active_formatting_elements)
              if {
                applet => 1, marquee => 1, object => 1,
              }->{$self->{t}->{tag_name}};
        }
        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ($self->{t}->{tag_name} eq 'form') {
        ## NOTE: As normal, but interacts with the form element pointer

        undef $self->{form_element};

        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] == FORM_EL) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## NOTE: Ignore the token.
        } else {
          ## Step 1. generate implied end tags
          while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
            
            pop @{$self->{open_elements}};
          }
          
          ## Step 2. 
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $self->{t}->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[-1]->[0]
                                ->manakai_local_name,
                            token => $self->{t});
          } else {
            
          }  
          
          ## Step 3.
          splice @{$self->{open_elements}}, $i;
        }

        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ({
                ## NOTE: As normal, except acts as a closer for any ...
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$self->{t}->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] == HEADING_EL) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});
          ## NOTE: Ignore the token.
        } else {
          ## Step 1. generate implied end tags
          while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
            
            pop @{$self->{open_elements}};
          }
          
          ## Step 2.
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $self->{t}->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $self->{t}->{tag_name}, token => $self->{t});
          } else {
            
          }

          ## Step 3.
          splice @{$self->{open_elements}}, $i;
        }
        
        $self->{t} = $self->_get_next_token;
        next B;

      } elsif ($self->{t}->{tag_name} eq 'p') {
        ## "In body" insertion mode, "p" start tag. As normal, except
        ## </p> implies <p> and ...

        ## "have an element in button scope".
        my $non_optional;
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] == P_EL) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & BUTTON_SCOPING_EL) {
            
            last INSCOPE;
          } elsif ($node->[1] & END_TAG_OPTIONAL_EL) {
            ## NOTE: |END_TAG_OPTIONAL_EL| includes "p"
            
            #
          } else {
            
            $non_optional ||= $node;
            #
          }
        } # INSCOPE

        if (defined $i) {
          ## 1. Generate implied end tags
          #

          ## 2. If current node != "p", parse error
          if ($non_optional) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $non_optional->[0]->manakai_local_name,
                            token => $self->{t});
          } else {
            
          }

          ## 3. Pop
          splice @{$self->{open_elements}}, $i;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $self->{t}->{tag_name}, token => $self->{t});

          
          ## As if <p>, then reprocess the current token
          my $el;
          
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'p']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
          $insert->($self, $el, $open_tables);
          ## NOTE: Not inserted into |$self->{open_elements}|.
        }

        $self->{t} = $self->_get_next_token;
        next B;
      } elsif ({
                a => 1,
                b => 1, big => 1, code => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strike => 1,
                strong => 1, tt => 1, u => 1,
               }->{$self->{t}->{tag_name}}) {
        
        $formatting_end_tag->($self, $active_formatting_elements,
                              $open_tables, $self->{t});
        next B;
      } elsif ($self->{t}->{tag_name} eq 'br') {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => 'br', token => $self->{t});

        ## As if <br>
        my $insert = $self->{insertion_mode} & TABLE_IMS
            ? $insert_to_foster : $insert_to_current;
        $reconstruct_active_formatting_elements
            ->($self, $insert, $active_formatting_elements, $open_tables);
        
        my $el;
        
      $el = $self->{document}->create_element_ns
        (HTML_NS, [undef,  'br']);
    
        $el->set_user_data (manakai_source_line => $self->{t}->{line})
            if defined $self->{t}->{line};
        $el->set_user_data (manakai_source_column => $self->{t}->{column})
            if defined $self->{t}->{column};
      
        $insert->($self, $el, $open_tables);
        
        ## Ignore the token.
        $self->{t} = $self->_get_next_token;
        next B;
      } else {
        if ($self->{t}->{tag_name} eq 'sarcasm') {
          sleep 0.001; # take a deep breath
        }

        ## Step 1
        my $node_i = -1;
        my $node = $self->{open_elements}->[$node_i];

        ## Step 2
        LOOP: {
          my $node_tag_name = $node->[0]->manakai_local_name;
          $node_tag_name =~ tr/A-Z/a-z/; # for SVG camelCase tag names
          if ($node_tag_name eq $self->{t}->{tag_name}) {
            ## Step 1
            ## generate implied end tags
            while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL and
                   $self->{open_elements}->[-1]->[0]->manakai_local_name
                       ne $self->{t}->{tag_name}) {
              
              ## NOTE: |<ruby><rt></ruby>|.
              pop @{$self->{open_elements}};
              $node_i++;
            }
        
            ## Step 2
            my $current_tag_name
                = $self->{open_elements}->[-1]->[0]->manakai_local_name;
            $current_tag_name =~ tr/A-Z/a-z/;
            if ($current_tag_name ne $self->{t}->{tag_name}) {
              
              ## NOTE: <x><y></x>
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $self->{t});
            } else {
              
            }
            
            ## Step 3
            splice @{$self->{open_elements}}, $node_i if $node_i < 0;

            $self->{t} = $self->_get_next_token;
            last LOOP;
          } else {
            ## Step 3
            if ($node->[1] & SPECIAL_EL or $node->[1] & SCOPING_EL) { ## "Special"
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => $self->{t}->{tag_name}, token => $self->{t});
              ## Ignore the token
              $self->{t} = $self->_get_next_token;
              last LOOP;

              ## NOTE: |<span><dd></span>a|: In Safari 3.1.2 and Opera
              ## 9.27, "a" is a child of <dd> (conforming).  In
              ## Firefox 3.0.2, "a" is a child of <body>.  In WinIE 7,
              ## "a" is a child of both <body> and <dd>.
            }
            
            
          }
          
          ## Step 4
          $node_i--;
          $node = $self->{open_elements}->[$node_i];
          
          ## Step 5;
          redo LOOP;
        } # LOOP
	next B;
      }
    }
    next B;
  } # B

  ## Stop parsing # MUST
  
  ## TODO: script stuffs
} # _tree_construct_main

## XXX: How this method is organized is somewhat out of date, although
## it still does what the current spec documents.
sub set_inner_html ($$$$) {
  #my ($self, $string, $onerror, $get_wrapper) = @_;
  my ($class, $self);
  if (ref $_[0]) {
    $self = shift;
    $class = ref $self;
  } else {
    $class = shift;
    $self = $class->new;
  }
  my $node = shift; # /context/
  #my $s = \$_[0];
  my $onerror = $_[1];
  my $get_wrapper = $_[2] || sub ($) { return $_[0] };

  my $nt = $node->node_type;
  if ($nt == 9) { # Document (invoke the algorithm with no /context/ element)
    # MUST
    
    ## Step 1 # MUST
    ## TODO: If the document has an active parser, ...
    ## ISSUE: There is an issue in the spec.
    
    ## Step 2 # MUST
    for ($node->child_nodes->to_list) {
      $node->remove_child ($_);
    }

    ## Step 3, 4, 5 # MUST
    $self->parse_char_string ($_[0] => $node, $onerror, $get_wrapper);
  } elsif ($nt == 1) { # Element (invoke the algorithm with /context/ element)
    ## TODO: If non-html element

    ## NOTE: Most of this code is copied from |parse_string|

## TODO: Support for $get_wrapper

    ## F1. Create an HTML document.
    my $this_doc = $node->owner_document;
    my $doc = $this_doc->implementation->create_document;
    $doc->manakai_is_html (1);

    ## F2. Propagate quirkness flag
    my $node_doc = $node->owner_document;
    $doc->manakai_compat_mode ($node_doc->manakai_compat_mode);

    ## F3. Create an HTML parser
    my $p = $self;
    $p->{document} = $doc;

    ## Step 8 # MUST
    my $i = 0;
    $p->{line_prev} = $p->{line} = 1;
    $p->{column_prev} = -1;
    $p->{column} = 0;

    $self->{chars} = [split //, $_[0]];
    $self->{chars_pos} = 0;
    $self->{chars_pull_next} = sub { 0 };
    delete $self->{chars_was_cr};

    my $ponerror = $onerror || $self->onerror;
    $p->{parse_error} = sub {
      $ponerror->(line => $p->{line}, column => $p->{column}, @_);
    };

    $p->_initialize_tokenizer;
    $p->_initialize_tree_constructor;

    ## F4. If /context/ is not undef...

    ## F4.1. content model flag
    my $node_ns = $node->namespace_uri || '';
    my $node_ln = $node->manakai_local_name;
    if ($node_ns eq HTML_NS) {
      if ($node_ln eq 'title' or $node_ln eq 'textarea') {
        $p->{state} = RCDATA_STATE;
      } elsif ($node_ln eq 'script') {
        $p->{state} = SCRIPT_DATA_STATE;
      } elsif ({
        style => 1,
        script => 1,
        xmp => 1,
        iframe => 1,
        noembed => 1,
        noframes => 1,
        noscript => 1,
      }->{$node_ln}) {
        $p->{state} = RAWTEXT_STATE;
      } elsif ($node_ln eq 'plaintext') {
        $p->{state} = PLAINTEXT_STATE;
      }
      
      $p->{inner_html_node} = [$node, $el_category->{$node_ln}];
    } elsif ($node_ns eq SVG_NS) {
      $p->{inner_html_node} = [$node,
                               $el_category_f->{$node_ns}->{$node_ln}
                                   || FOREIGN_EL | SVG_EL];
    } elsif ($node_ns eq MML_NS) {
      $p->{inner_html_node} = [$node,
                               $el_category_f->{$node_ns}->{$node_ln}
                                   || FOREIGN_EL | MML_EL];
    } else {
      $p->{inner_html_node} = [$node, FOREIGN_EL];
    }

    ## F4.2. Root |html| element
    my $root = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, 'html']);

    ## F4.3.
    $doc->append_child ($root);

    ## F4.4.
    push @{$p->{open_elements}}, [$root, $el_category->{html}];
    $p->{open_tables} = [[$root]];

    undef $p->{head_element};

    ## F4.5.
    $p->_reset_insertion_mode;

    ## F4.6.
    my $anode = $node;
    AN: while (defined $anode) {
      if ($anode->node_type == 1) {
        my $nsuri = $anode->namespace_uri;
        if (defined $nsuri and $nsuri eq HTML_NS) {
          if ($anode->manakai_local_name eq 'form') {
            
            $p->{form_element} = $anode;
            last AN;
          }
        }
      }
      $anode = $anode->parent_node;
    } # AN

    ## F.5. Set the input stream.
    $p->{confident} = 1; ## Confident: irrelevant.

    ## F.6. Start the parser.
    $p->{t} = $p->_get_next_token;
    $p->_construct_tree;

    ## F.7.
    for ($node->child_nodes->to_list) {
      $node->remove_child ($_);
    }
    ## ISSUE: mutation events? read-only?

    ## Step 11 # MUST
    for ($root->child_nodes->to_list) {
      $this_doc->adopt_node ($_);
      $node->append_child ($_);
    }
    ## ISSUE: mutation events?

    $p->_terminate_tree_constructor;
    $p->_clear_refs;
  } else {
    die "$0: |set_inner_html| is not defined for node of type $nt";
  }
} # set_inner_html

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
