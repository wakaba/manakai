package Whatpm::HTML;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.177 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Error qw(:try);

## ISSUE:
## var doc = implementation.createDocument (null, null, null);
## doc.write ('');
## alert (doc.compatMode);

require IO::Handle;

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;
my $MML_NS = q<http://www.w3.org/1998/Math/MathML>;
my $SVG_NS = q<http://www.w3.org/2000/svg>;
my $XLINK_NS = q<http://www.w3.org/1999/xlink>;
my $XML_NS = q<http://www.w3.org/XML/1998/namespace>;
my $XMLNS_NS = q<http://www.w3.org/2000/xmlns/>;

sub A_EL () { 0b1 }
sub ADDRESS_EL () { 0b10 }
sub BODY_EL () { 0b100 }
sub BUTTON_EL () { 0b1000 }
sub CAPTION_EL () { 0b10000 }
sub DD_EL () { 0b100000 }
sub DIV_EL () { 0b1000000 }
sub DT_EL () { 0b10000000 }
sub FORM_EL () { 0b100000000 }
sub FORMATTING_EL () { 0b1000000000 }
sub FRAMESET_EL () { 0b10000000000 }
sub HEADING_EL () { 0b100000000000 }
sub HTML_EL () { 0b1000000000000 }
sub LI_EL () { 0b10000000000000 }
sub NOBR_EL () { 0b100000000000000 }
sub OPTION_EL () { 0b1000000000000000 }
sub OPTGROUP_EL () { 0b10000000000000000 }
sub P_EL () { 0b100000000000000000 }
sub SELECT_EL () { 0b1000000000000000000 }
sub TABLE_EL () { 0b10000000000000000000 }
sub TABLE_CELL_EL () { 0b100000000000000000000 }
sub TABLE_ROW_EL () { 0b1000000000000000000000 }
sub TABLE_ROW_GROUP_EL () { 0b10000000000000000000000 }
sub MISC_SCOPING_EL () { 0b100000000000000000000000 }
sub MISC_SPECIAL_EL () { 0b1000000000000000000000000 }
sub FOREIGN_EL () { 0b10000000000000000000000000 }
sub FOREIGN_FLOW_CONTENT_EL () { 0b100000000000000000000000000 }
sub MML_AXML_EL () { 0b1000000000000000000000000000 }
sub RUBY_EL () { 0b10000000000000000000000000000 }
sub RUBY_COMPONENT_EL () { 0b100000000000000000000000000000 }

sub TABLE_ROWS_EL () {
  TABLE_EL |
  TABLE_ROW_EL |
  TABLE_ROW_GROUP_EL
}

## NOTE: Used in "generate implied end tags" algorithm.
## NOTE: There is a code where a modified version of END_TAG_OPTIONAL_EL
## is used in "generate implied end tags" implementation (search for the
## function mae).
sub END_TAG_OPTIONAL_EL () {
  DD_EL |
  DT_EL |
  LI_EL |
  P_EL |
  RUBY_COMPONENT_EL
}

## NOTE: Used in </body> and EOF algorithms.
sub ALL_END_TAG_OPTIONAL_EL () {
  DD_EL |
  DT_EL |
  LI_EL |
  P_EL |

  BODY_EL |
  HTML_EL |
  TABLE_CELL_EL |
  TABLE_ROW_EL |
  TABLE_ROW_GROUP_EL
}

sub SCOPING_EL () {
  BUTTON_EL |
  CAPTION_EL |
  HTML_EL |
  TABLE_EL |
  TABLE_CELL_EL |
  MISC_SCOPING_EL
}

sub TABLE_SCOPING_EL () {
  HTML_EL |
  TABLE_EL
}

sub TABLE_ROWS_SCOPING_EL () {
  HTML_EL |
  TABLE_ROW_GROUP_EL
}

sub TABLE_ROW_SCOPING_EL () {
  HTML_EL |
  TABLE_ROW_EL
}

sub SPECIAL_EL () {
  ADDRESS_EL |
  BODY_EL |
  DIV_EL |

  DD_EL |
  DT_EL |
  LI_EL |
  P_EL |

  FORM_EL |
  FRAMESET_EL |
  HEADING_EL |
  OPTION_EL |
  OPTGROUP_EL |
  SELECT_EL |
  TABLE_ROW_EL |
  TABLE_ROW_GROUP_EL |
  MISC_SPECIAL_EL
}

my $el_category = {
  a => A_EL | FORMATTING_EL,
  address => ADDRESS_EL,
  applet => MISC_SCOPING_EL,
  area => MISC_SPECIAL_EL,
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
  col => MISC_SPECIAL_EL,
  colgroup => MISC_SPECIAL_EL,
  dd => DD_EL,
  dir => MISC_SPECIAL_EL,
  div => DIV_EL,
  dl => MISC_SPECIAL_EL,
  dt => DT_EL,
  em => FORMATTING_EL,
  embed => MISC_SPECIAL_EL,
  fieldset => MISC_SPECIAL_EL,
  font => FORMATTING_EL,
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
  hr => MISC_SPECIAL_EL,
  html => HTML_EL,
  i => FORMATTING_EL,
  iframe => MISC_SPECIAL_EL,
  img => MISC_SPECIAL_EL,
  input => MISC_SPECIAL_EL,
  isindex => MISC_SPECIAL_EL,
  li => LI_EL,
  link => MISC_SPECIAL_EL,
  listing => MISC_SPECIAL_EL,
  marquee => MISC_SCOPING_EL,
  menu => MISC_SPECIAL_EL,
  meta => MISC_SPECIAL_EL,
  nobr => NOBR_EL | FORMATTING_EL,
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
  small => FORMATTING_EL,
  spacer => MISC_SPECIAL_EL,
  strike => FORMATTING_EL,
  strong => FORMATTING_EL,
  style => MISC_SPECIAL_EL,
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
};

my $el_category_f = {
  $MML_NS => {
    'annotation-xml' => MML_AXML_EL,
    mi => FOREIGN_FLOW_CONTENT_EL,
    mo => FOREIGN_FLOW_CONTENT_EL,
    mn => FOREIGN_FLOW_CONTENT_EL,
    ms => FOREIGN_FLOW_CONTENT_EL,
    mtext => FOREIGN_FLOW_CONTENT_EL,
  },
  $SVG_NS => {
    foreignObject => FOREIGN_FLOW_CONTENT_EL,
    desc => FOREIGN_FLOW_CONTENT_EL,
    title => FOREIGN_FLOW_CONTENT_EL,
  },
  ## NOTE: In addition, FOREIGN_EL is set to non-HTML elements.
};

my $svg_attr_name = {
  attributename => 'attributeName',
  attributetype => 'attributeType',
  basefrequency => 'baseFrequency',
  baseprofile => 'baseProfile',
  calcmode => 'calcMode',
  clippathunits => 'clipPathUnits',
  contentscripttype => 'contentScriptType',
  contentstyletype => 'contentStyleType',
  diffuseconstant => 'diffuseConstant',
  edgemode => 'edgeMode',
  externalresourcesrequired => 'externalResourcesRequired',
  filterres => 'filterRes',
  filterunits => 'filterUnits',
  glyphref => 'glyphRef',
  gradienttransform => 'gradientTransform',
  gradientunits => 'gradientUnits',
  kernelmatrix => 'kernelMatrix',
  kernelunitlength => 'kernelUnitLength',
  keypoints => 'keyPoints',
  keysplines => 'keySplines',
  keytimes => 'keyTimes',
  lengthadjust => 'lengthAdjust',
  limitingconeangle => 'limitingConeAngle',
  markerheight => 'markerHeight',
  markerunits => 'markerUnits',
  markerwidth => 'markerWidth',
  maskcontentunits => 'maskContentUnits',
  maskunits => 'maskUnits',
  numoctaves => 'numOctaves',
  pathlength => 'pathLength',
  patterncontentunits => 'patternContentUnits',
  patterntransform => 'patternTransform',
  patternunits => 'patternUnits',
  pointsatx => 'pointsAtX',
  pointsaty => 'pointsAtY',
  pointsatz => 'pointsAtZ',
  preservealpha => 'preserveAlpha',
  preserveaspectratio => 'preserveAspectRatio',
  primitiveunits => 'primitiveUnits',
  refx => 'refX',
  refy => 'refY',
  repeatcount => 'repeatCount',
  repeatdur => 'repeatDur',
  requiredextensions => 'requiredExtensions',
  requiredfeatures => 'requiredFeatures',
  specularconstant => 'specularConstant',
  specularexponent => 'specularExponent',
  spreadmethod => 'spreadMethod',
  startoffset => 'startOffset',
  stddeviation => 'stdDeviation',
  stitchtiles => 'stitchTiles',
  surfacescale => 'surfaceScale',
  systemlanguage => 'systemLanguage',
  tablevalues => 'tableValues',
  targetx => 'targetX',
  targety => 'targetY',
  textlength => 'textLength',
  viewbox => 'viewBox',
  viewtarget => 'viewTarget',
  xchannelselector => 'xChannelSelector',
  ychannelselector => 'yChannelSelector',
  zoomandpan => 'zoomAndPan',
};

my $foreign_attr_xname = {
  'xlink:actuate' => [$XLINK_NS, ['xlink', 'actuate']],
  'xlink:arcrole' => [$XLINK_NS, ['xlink', 'arcrole']],
  'xlink:href' => [$XLINK_NS, ['xlink', 'href']],
  'xlink:role' => [$XLINK_NS, ['xlink', 'role']],
  'xlink:show' => [$XLINK_NS, ['xlink', 'show']],
  'xlink:title' => [$XLINK_NS, ['xlink', 'title']],
  'xlink:type' => [$XLINK_NS, ['xlink', 'type']],
  'xml:base' => [$XML_NS, ['xml', 'base']],
  'xml:lang' => [$XML_NS, ['xml', 'lang']],
  'xml:space' => [$XML_NS, ['xml', 'space']],
  'xmlns' => [$XMLNS_NS, [undef, 'xmlns']],
  'xmlns:xlink' => [$XMLNS_NS, ['xmlns', 'xlink']],
};

## ISSUE: xmlns:xlink="non-xlink-ns" is not an error.

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

sub parse_byte_string ($$$$;$) {
  my $self = shift;
  my $charset_name = shift;
  open my $input, '<', ref $_[0] ? $_[0] : \($_[0]);
  return $self->parse_byte_stream ($charset_name, $input, @_[1..$#_]);
} # parse_byte_string

sub parse_byte_stream ($$$$;$$) {
  # my ($self, $charset_name, $byte_stream, $doc, $onerror, $get_wrapper) = @_;
  my $self = ref $_[0] ? shift : shift->new;
  my $charset_name = shift;
  my $byte_stream = $_[0];

  my $onerror = $_[2] || sub {
    my (%opt) = @_;
    warn "Parse error ($opt{type})\n";
  };
  $self->{parse_error} = $onerror; # updated later by parse_char_string

  my $get_wrapper = $_[3] || sub ($) {
    return $_[0]; # $_[0] = byte stream handle, returned = arg to char handle
  };

  ## HTML5 encoding sniffing algorithm
  require Message::Charset::Info;
  my $charset;
  my $buffer;
  my ($char_stream, $e_status);

  SNIFFING: {
    ## NOTE: By setting |allow_fallback| option true when the
    ## |get_decode_handle| method is invoked, we ignore what the HTML5
    ## spec requires, i.e. unsupported encoding should be ignored.
      ## TODO: We should not do this unless the parser is invoked
      ## in the conformance checking mode, in which this behavior
      ## would be useful.

    ## Step 1
    if (defined $charset_name) {
      $charset = Message::Charset::Info->get_by_html_name ($charset_name);
          ## TODO: Is this ok?  Transfer protocol's parameter should be
          ## interpreted in its semantics?

      ## ISSUE: Unsupported encoding is not ignored according to the spec.
      ($char_stream, $e_status) = $charset->get_decode_handle
          ($byte_stream, allow_error_reporting => 1,
           allow_fallback => 1);
      if ($char_stream) {
        $self->{confident} = 1;
        last SNIFFING;
      } else {
        ## TODO: unsupported error
      }
    }

    ## Step 2
    my $byte_buffer = '';
    for (1..1024) {
      my $char = $byte_stream->getc;
      last unless defined $char;
      $byte_buffer .= $char;
    } ## TODO: timeout

    ## Step 3
    if ($byte_buffer =~ /^\xFE\xFF/) {
      $charset = Message::Charset::Info->get_by_html_name ('utf-16be');
      ($char_stream, $e_status) = $charset->get_decode_handle
          ($byte_stream, allow_error_reporting => 1,
           allow_fallback => 1, byte_buffer => \$byte_buffer);
      $self->{confident} = 1;
      last SNIFFING;
    } elsif ($byte_buffer =~ /^\xFF\xFE/) {
      $charset = Message::Charset::Info->get_by_html_name ('utf-16le');
      ($char_stream, $e_status) = $charset->get_decode_handle
          ($byte_stream, allow_error_reporting => 1,
           allow_fallback => 1, byte_buffer => \$byte_buffer);
      $self->{confident} = 1;
      last SNIFFING;
    } elsif ($byte_buffer =~ /^\xEF\xBB\xBF/) {
      $charset = Message::Charset::Info->get_by_html_name ('utf-8');
      ($char_stream, $e_status) = $charset->get_decode_handle
          ($byte_stream, allow_error_reporting => 1,
           allow_fallback => 1, byte_buffer => \$byte_buffer);
      $self->{confident} = 1;
      last SNIFFING;
    }

    ## Step 4
    ## TODO: <meta charset>

    ## Step 5
    ## TODO: from history

    ## Step 6
    require Whatpm::Charset::UniversalCharDet;
    $charset_name = Whatpm::Charset::UniversalCharDet->detect_byte_string
        ($byte_buffer);
    if (defined $charset_name) {
      $charset = Message::Charset::Info->get_by_html_name ($charset_name);

      ## ISSUE: Unsupported encoding is not ignored according to the spec.
      require Whatpm::Charset::DecodeHandle;
      $buffer = Whatpm::Charset::DecodeHandle::ByteBuffer->new
          ($byte_stream);
      ($char_stream, $e_status) = $charset->get_decode_handle
          ($buffer, allow_error_reporting => 1,
           allow_fallback => 1, byte_buffer => \$byte_buffer);
      if ($char_stream) {
        $buffer->{buffer} = $byte_buffer;
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'sniffing:chardet',
                        text => $charset_name,
                        level => $self->{level}->{info},
                        layer => 'encode',
                        line => 1, column => 1);
        $self->{confident} = 0;
        last SNIFFING;
      }
    }

    ## Step 7: default
    ## TODO: Make this configurable.
    $charset = Message::Charset::Info->get_by_html_name ('windows-1252');
        ## NOTE: We choose |windows-1252| here, since |utf-8| should be 
        ## detectable in the step 6.
    require Whatpm::Charset::DecodeHandle;
    $buffer = Whatpm::Charset::DecodeHandle::ByteBuffer->new
        ($byte_stream);
    ($char_stream, $e_status)
        = $charset->get_decode_handle ($buffer,
                                       allow_error_reporting => 1,
                                       allow_fallback => 1,
                                       byte_buffer => \$byte_buffer);
    $buffer->{buffer} = $byte_buffer;
    $self->{parse_error}->(level => $self->{level}->{must}, type => 'sniffing:default',
                    text => 'windows-1252',
                    level => $self->{level}->{info},
                    line => 1, column => 1,
                    layer => 'encode');
    $self->{confident} = 0;
  } # SNIFFING

  if ($e_status & Message::Charset::Info::FALLBACK_ENCODING_IMPL ()) {
    $self->{input_encoding} = $charset->get_iana_name; ## TODO: Should we set actual charset decoder's encoding name?
    $self->{parse_error}->(level => $self->{level}->{must}, type => 'chardecode:fallback',
                    #text => $self->{input_encoding},
                    level => $self->{level}->{uncertain},
                    line => 1, column => 1,
                    layer => 'encode');
  } elsif (not ($e_status &
                Message::Charset::Info::ERROR_REPORTING_ENCODING_IMPL ())) {
    $self->{input_encoding} = $charset->get_iana_name;
    $self->{parse_error}->(level => $self->{level}->{must}, type => 'chardecode:no error',
                    text => $self->{input_encoding},
                    level => $self->{level}->{uncertain},
                    line => 1, column => 1,
                    layer => 'encode');
  } else {
    $self->{input_encoding} = $charset->get_iana_name;
  }

  $self->{change_encoding} = sub {
    my $self = shift;
    $charset_name = shift;
    my $token = shift;

    $charset = Message::Charset::Info->get_by_html_name ($charset_name);
    ($char_stream, $e_status) = $charset->get_decode_handle
        ($byte_stream, allow_error_reporting => 1, allow_fallback => 1,
         byte_buffer => \ $buffer->{buffer});
    
    if ($char_stream) { # if supported
      ## "Change the encoding" algorithm:

      ## Step 1    
      if ($charset->{category} &
          Message::Charset::Info::CHARSET_CATEGORY_UTF16 ()) {
        $charset = Message::Charset::Info->get_by_html_name ('utf-8');
        ($char_stream, $e_status) = $charset->get_decode_handle
            ($byte_stream,
             byte_buffer => \ $buffer->{buffer});
      }
      $charset_name = $charset->get_iana_name;
      
      ## Step 2
      if (defined $self->{input_encoding} and
          $self->{input_encoding} eq $charset_name) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'charset label:matching',
                        text => $charset_name,
                        level => $self->{level}->{info});
        $self->{confident} = 1;
        return;
      }

      $self->{parse_error}->(level => $self->{level}->{must}, type => 'charset label detected',
                      text => $self->{input_encoding},
                      value => $charset_name,
                      level => $self->{level}->{warn},
                      token => $token);
      
      ## Step 3
      # if (can) {
        ## change the encoding on the fly.
        #$self->{confident} = 1;
        #return;
      # }
      
      ## Step 4
      throw Whatpm::HTML::RestartParser ();
    }
  }; # $self->{change_encoding}

  my $char_onerror = sub {
    my (undef, $type, %opt) = @_;
    $self->{parse_error}->(level => $self->{level}->{must}, layer => 'encode',
                    line => $self->{line}, column => $self->{column} + 1,
                    %opt, type => $type);
    if ($opt{octets}) {
      ${$opt{octets}} = "\x{FFFD}"; # relacement character
    }
  };

  my $wrapped_char_stream = $get_wrapper->($char_stream);
  $wrapped_char_stream->onerror ($char_onerror);

  my @args = @_; shift @args; # $s
  my $return;
  try {
    $return = $self->parse_char_stream ($wrapped_char_stream, @args);  
  } catch Whatpm::HTML::RestartParser with {
    ## NOTE: Invoked after {change_encoding}.

    if ($e_status & Message::Charset::Info::FALLBACK_ENCODING_IMPL ()) {
      $self->{input_encoding} = $charset->get_iana_name; ## TODO: Should we set actual charset decoder's encoding name?
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'chardecode:fallback',
                      level => $self->{level}->{uncertain},
                      #text => $self->{input_encoding},
                      line => 1, column => 1,
                      layer => 'encode');
    } elsif (not ($e_status &
                  Message::Charset::Info::ERROR_REPORTING_ENCODING_IMPL ())) {
      $self->{input_encoding} = $charset->get_iana_name;
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'chardecode:no error',
                      text => $self->{input_encoding},
                      level => $self->{level}->{uncertain},
                      line => 1, column => 1,
                      layer => 'encode');
    } else {
      $self->{input_encoding} = $charset->get_iana_name;
    }
    $self->{confident} = 1;

    $wrapped_char_stream = $get_wrapper->($char_stream);
    $wrapped_char_stream->onerror ($char_onerror);

    $return = $self->parse_char_stream ($wrapped_char_stream, @args);
  };
  return $return;
} # parse_byte_stream

## NOTE: HTML5 spec says that the encoding layer MUST NOT strip BOM
## and the HTML layer MUST ignore it.  However, we does strip BOM in
## the encoding layer and the HTML layer does not ignore any U+FEFF,
## because the core part of our HTML parser expects a string of character,
## not a string of bytes or code units or anything which might contain a BOM.
## Therefore, any parser interface that accepts a string of bytes,
## such as |parse_byte_string| in this module, must ensure that it does
## strip the BOM and never strip any ZWNBSP.

sub parse_char_string ($$$;$$) {
  #my ($self, $s, $doc, $onerror, $get_wrapper) = @_;
  my $self = shift;
  my $s = ref $_[0] ? $_[0] : \($_[0]);
  require Whatpm::Charset::DecodeHandle;
  my $input = Whatpm::Charset::DecodeHandle::CharString->new ($s);
  if ($_[3]) {
    $input = $_[3]->($input);
  }
  return $self->parse_char_stream ($input, @_[1..$#_]);
} # parse_char_string
*parse_string = \&parse_char_string; ## NOTE: Alias for backward compatibility.

my $disallowed_control_chars =
{
 0xFFFE => 1, 0xFFFF => 1, 0x1FFFE => 1, 0x1FFFF => 1,
 0x2FFFE => 1, 0x2FFFF => 1, 0x3FFFE => 1, 0x3FFFF => 1,
 0x4FFFE => 1, 0x4FFFF => 1, 0x5FFFE => 1, 0x5FFFF => 1,
 0x6FFFE => 1, 0x6FFFF => 1, 0x7FFFE => 1, 0x7FFFF => 1,
 0x8FFFE => 1, 0x8FFFF => 1, 0x9FFFE => 1, 0x9FFFF => 1,
 0xAFFFE => 1, 0xAFFFF => 1, 0xBFFFE => 1, 0xBFFFF => 1,
 0xCFFFE => 1, 0xCFFFF => 1, 0xDFFFE => 1, 0xDFFFF => 1,
 0xEFFFE => 1, 0xEFFFF => 1, 0xFFFFE => 1, 0xFFFFF => 1,
 0x10FFFE => 1, 0x10FFFF => 1,
};
$disallowed_control_chars->{$_} = 1
    for 0x0001 .. 0x0008, 0x000E .. 0x001F, 0x007F .. 0x009F,
        0xD800 .. 0xDFFF, 0xFDD0 .. 0xFDDF;
## ISSUE: U+FDE0-U+FDEF are not excluded

sub parse_char_stream ($$$;$) {
  my $self = ref $_[0] ? shift : shift->new;
  my $input = $_[0];
  $self->{document} = $_[1];
  @{$self->{document}->child_nodes} = ();

  ## NOTE: |set_inner_html| copies most of this method's code

  $self->{confident} = 1 unless exists $self->{confident};
  $self->{document}->input_encoding ($self->{input_encoding})
      if defined $self->{input_encoding};
## TODO: |{input_encoding}| is needless?

  my $i = 0;
  $self->{line_prev} = $self->{line} = 1;
  $self->{column_prev} = -1;
  $self->{column} = 0;
  $self->{set_next_char} = \&stream_getc;sub stream_getc {
    my $self = shift;

    my $char = '';
    if (defined $self->{next_next_char}) {
      $char = $self->{next_next_char};
      delete $self->{next_next_char};
      $self->{next_char} = ord $char;
    } else {
      $self->{char_buffer} = '';
      $self->{char_buffer_pos} = 0;

      my $count = $input->manakai_read_until
         ($self->{char_buffer},
          qr/(?![\x{FDD0}-\x{FDDF}\x{FFFE}\x{FFFF}\x{1FFFE}\x{1FFFF}\x{2FFFE}\x{2FFFF}\x{3FFFE}\x{3FFFF}\x{4FFFE}\x{4FFFF}\x{5FFFE}\x{5FFFF}\x{6FFFE}\x{6FFFF}\x{7FFFE}\x{7FFFF}\x{8FFFE}\x{8FFFF}\x{9FFFE}\x{9FFFF}\x{AFFFE}\x{AFFFF}\x{BFFFE}\x{BFFFF}\x{CFFFE}\x{CFFFF}\x{DFFFE}\x{DFFFF}\x{EFFFE}\x{EFFFF}\x{FFFFE}\x{FFFFF}])[\x20-\x7E\xA0-\x{D7FF}\x{E000}-\x{10FFFD}]/,
          $self->{char_buffer_pos});
      if ($count) {
        $self->{line_prev} = $self->{line};
        $self->{column_prev} = $self->{column};
        $self->{column}++;
        $self->{next_char}
            = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
        return;
      }

      if ($input->read ($char, 1)) {
        $self->{next_char} = ord $char;
      } else {
        $self->{next_char} = -1;
        return;
      }
    }

    ($self->{line_prev}, $self->{column_prev})
        = ($self->{line}, $self->{column});
    $self->{column}++;
    
    if ($self->{next_char} == 0x000A) { # LF
      
      $self->{line}++;
      $self->{column} = 0;
    } elsif ($self->{next_char} == 0x000D) { # CR
      
## TODO: support for abort/streaming
      my $next = '';
      if ($input->read ($next, 1) and $next ne "\x0A") {
        $self->{next_next_char} = $next;
      }
      $self->{next_char} = 0x000A; # LF # MUST
      $self->{line}++;
      $self->{column} = 0;
    } elsif ($self->{next_char} > 0x10FFFF) {
      
      $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    } elsif ($self->{next_char} == 0x0000) { # NULL
      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
      $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
    } elsif ($disallowed_control_chars->{$self->{next_char}}) {
      
      if ($self->{next_char} < 0x10000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'control char',
                        text => (sprintf 'U+%04X', $self->{next_char}));
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'control char',
                        text => (sprintf 'U-%08X', $self->{next_char}));
      }
    }
  };

  $self->{read_until} = sub {
    #my ($scalar, $specials_range, $offset) = @_;
    return 0 if defined $self->{next_next_char};

    my $pattern = qr/(?![$_[1]\x{FDD0}-\x{FDDF}\x{FFFE}\x{FFFF}\x{1FFFE}\x{1FFFF}\x{2FFFE}\x{2FFFF}\x{3FFFE}\x{3FFFF}\x{4FFFE}\x{4FFFF}\x{5FFFE}\x{5FFFF}\x{6FFFE}\x{6FFFF}\x{7FFFE}\x{7FFFF}\x{8FFFE}\x{8FFFF}\x{9FFFE}\x{9FFFF}\x{AFFFE}\x{AFFFF}\x{BFFFE}\x{BFFFF}\x{CFFFE}\x{CFFFF}\x{DFFFE}\x{DFFFF}\x{EFFFE}\x{EFFFF}\x{FFFFE}\x{FFFFF}])[\x20-\x7E\xA0-\x{D7FF}\x{E000}-\x{10FFFD}]/;
    my $offset = $_[2] || 0;

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      pos ($self->{char_buffer}) = $self->{char_buffer_pos};
      if ($self->{char_buffer} =~ /\G(?>$pattern)+/) {
        substr ($_[0], $offset)
            = substr ($self->{char_buffer}, $-[0], $+[0] - $-[0]);
        my $count = $+[0] - $-[0];
        if ($count) {
          $self->{column} += $count;
          $self->{char_buffer_pos} += $count;
          $self->{line_prev} = $self->{line};
          $self->{column_prev} = $self->{column} - 1;
          $self->{prev_char} = [-1, -1, -1];
          $self->{next_char} = -1;
        }
        return $count;
      } else {
        return 0;
      }
    } else {
      my $count = $input->manakai_read_until ($_[0], $pattern, $_[2]);
      if ($count) {
        $self->{column} += $count;
        $self->{line_prev} = $self->{line};
        $self->{column_prev} = $self->{column} - 1;
        $self->{prev_char} = [-1, -1, -1];
        $self->{next_char} = -1;
      }
      return $count;
    }
  }; # $self->{read_until}

  my $onerror = $_[2] || sub {
    my (%opt) = @_;
    my $line = $opt{token} ? $opt{token}->{line} : $opt{line};
    my $column = $opt{token} ? $opt{token}->{column} : $opt{column};
    warn "Parse error ($opt{type}) at line $line column $column\n";
  };
  $self->{parse_error} = sub {
    $onerror->(line => $self->{line}, column => $self->{column}, @_);
  };

  $self->_initialize_tokenizer;
  $self->_initialize_tree_constructor;
  $self->_construct_tree;
  $self->_terminate_tree_constructor;

  delete $self->{parse_error}; # remove loop

  return $self->{document};
} # parse_char_stream

sub new ($) {
  my $class = shift;
  my $self = bless {
    level => {must => 'm',
              should => 's',
              warn => 'w',
              info => 'i',
              uncertain => 'u'},
  }, $class;
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
#sub ENTITY_DATA_STATE () { 1 }
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
#sub ENTITY_IN_ATTRIBUTE_VALUE_STATE () { 12 }
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
sub SELF_CLOSING_START_TAG_STATE () { 34 }
sub CDATA_SECTION_STATE () { 35 }
sub MD_HYPHEN_STATE () { 36 } # "markup declaration open state" in the spec
sub MD_DOCTYPE_STATE () { 37 } # "markup declaration open state" in the spec
sub MD_CDATA_STATE () { 38 } # "markup declaration open state" in the spec
sub CDATA_PCDATA_CLOSE_TAG_STATE () { 39 } # "close tag open state" in the spec
sub CDATA_SECTION_MSE1_STATE () { 40 } # "CDATA section state" in the spec
sub CDATA_SECTION_MSE2_STATE () { 41 } # "CDATA section state" in the spec
sub PUBLIC_STATE () { 42 } # "after DOCTYPE name state" in the spec
sub SYSTEM_STATE () { 43 } # "after DOCTYPE name state" in the spec
## NOTE: "Entity data state", "entity in attribute value state", and
## "consume a character reference" algorithm are jointly implemented
## using the following six states:
sub ENTITY_STATE () { 44 }
sub ENTITY_HASH_STATE () { 45 }
sub NCR_NUM_STATE () { 46 }
sub HEXREF_X_STATE () { 47 }
sub HEXREF_HEX_STATE () { 48 }
sub ENTITY_NAME_STATE () { 49 }

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
sub SELECT_IMS ()     { 0b10000000000 }
sub IN_FOREIGN_CONTENT_IM () { 0b100000000000 }
    ## NOTE: "in foreign content" insertion mode is special; it is combined
    ## with the secondary insertion mode.  In this parser, they are stored
    ## together in the bit-or'ed form.

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
sub IN_SELECT_IM () { SELECT_IMS | 0b01 }
sub IN_SELECT_IN_TABLE_IM () { SELECT_IMS | 0b10 }
sub IN_COLUMN_GROUP_IM () { 0b10 }

## Implementations MUST act as if state machine in the spec

sub _initialize_tokenizer ($) {
  my $self = shift;
  $self->{state} = DATA_STATE; # MUST
  #$self->{state_keyword}; # initialized when used
  #$self->{entity__value}; # initialized when used
  #$self->{entity__match}; # initialized when used
  $self->{content_model} = PCDATA_CONTENT_MODEL; # be
  undef $self->{current_token};
  undef $self->{current_attribute};
  undef $self->{last_emitted_start_tag_name};
  #$self->{prev_state}; # initialized when used
  delete $self->{self_closing};
  $self->{char_buffer} = '';
  $self->{char_buffer_pos} = 0;
  $self->{prev_char} = [-1, -1, -1];
  $self->{next_char} = -1;
  
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
## NOTE: The "self-closing flag" is hold as |$self->{self_closing}|.
##     |->{self_closing}| is used to save the value of |$self->{self_closing}|
##     while the token is pushed back to the stack.

## Emitted token MUST immediately be handled by the tree construction state.

## Before each step, UA MAY check to see if either one of the scripts in
## "list of scripts that will execute as soon as possible" or the first
## script in the "list of scripts that will execute asynchronously",
## has completed loading.  If one has, then it MUST be executed
## and removed from the list.

## TODO: Polytheistic slash SHOULD NOT be used. (Applied only to atheists.)
## (This requirement was dropped from HTML5 spec, unfortunately.)

sub _get_next_token ($) {
  my $self = shift;

  if ($self->{self_closing}) {
    $self->{parse_error}->(level => $self->{level}->{must}, type => 'nestc', token => $self->{current_token});
    ## NOTE: The |self_closing| flag is only set by start tag token.
    ## In addition, when a start tag token is emitted, it is always set to
    ## |current_token|.
    delete $self->{self_closing};
  }

  if (@{$self->{token}}) {
    $self->{self_closing} = $self->{token}->[0]->{self_closing};
    return shift @{$self->{token}};
  }

  A: {
    if ($self->{state} == DATA_STATE) {
      if ($self->{next_char} == 0x0026) { # &
	if ($self->{content_model} & CM_ENTITY and # PCDATA | RCDATA
            not $self->{escape}) {
          
          ## NOTE: In the spec, the tokenizer is switched to the 
          ## "entity data state".  In this implementation, the tokenizer
          ## is switched to the |ENTITY_STATE|, which is an implementation
          ## of the "consume a character reference" algorithm.
          $self->{entity_additional} = -1;
          $self->{prev_state} = DATA_STATE;
          $self->{state} = ENTITY_STATE;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
        return  ({type => END_OF_FILE_TOKEN,
                  line => $self->{line}, column => $self->{column}});
        last A; ## TODO: ok?
      } else {
        
      }
      # Anything else
      my $token = {type => CHARACTER_TOKEN,
                   data => chr $self->{next_char},
                   line => $self->{line}, column => $self->{column},
                  };
      $self->{read_until}->($token->{data}, q[-!<>&], length $token->{data});

      ## Stay in the data state
      
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

      return  ($token);

      redo A;
    } elsif ($self->{state} == TAG_OPEN_STATE) {
      if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
        if ($self->{next_char} == 0x002F) { # /
          
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          $self->{state} = CLOSE_TAG_OPEN_STATE;
          redo A;
        } else {
          
          ## reconsume
          $self->{state} = DATA_STATE;

          return  ({type => CHARACTER_TOKEN, data => '<',
                    line => $self->{line_prev},
                    column => $self->{column_prev},
                   });

          redo A;
        }
      } elsif ($self->{content_model} & CM_FULL_MARKUP) { # PCDATA
        if ($self->{next_char} == 0x0021) { # !
          
          $self->{state} = MARKUP_DECLARATION_OPEN_STATE;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          redo A;
        } elsif ($self->{next_char} == 0x002F) { # /
          
          $self->{state} = CLOSE_TAG_OPEN_STATE;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          redo A;
        } elsif (0x0041 <= $self->{next_char} and
                 $self->{next_char} <= 0x005A) { # A..Z
          
          $self->{current_token}
            = {type => START_TAG_TOKEN,
               tag_name => chr ($self->{next_char} + 0x0020),
               line => $self->{line_prev},
               column => $self->{column_prev}};
          $self->{state} = TAG_NAME_STATE;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          redo A;
        } elsif (0x0061 <= $self->{next_char} and
                 $self->{next_char} <= 0x007A) { # a..z
          
          $self->{current_token} = {type => START_TAG_TOKEN,
                                    tag_name => chr ($self->{next_char}),
                                    line => $self->{line_prev},
                                    column => $self->{column_prev}};
          $self->{state} = TAG_NAME_STATE;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          redo A;
        } elsif ($self->{next_char} == 0x003E) { # >
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty start tag',
                          line => $self->{line_prev},
                          column => $self->{column_prev});
          $self->{state} = DATA_STATE;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

          return  ({type => CHARACTER_TOKEN, data => '<>',
                    line => $self->{line_prev},
                    column => $self->{column_prev},
                   });

          redo A;
        } elsif ($self->{next_char} == 0x003F) { # ?
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'pio',
                          line => $self->{line_prev},
                          column => $self->{column_prev});
          $self->{state} = BOGUS_COMMENT_STATE;
          $self->{current_token} = {type => COMMENT_TOKEN, data => '',
                                    line => $self->{line_prev},
                                    column => $self->{column_prev},
                                   };
          ## $self->{next_char} is intentionally left as is
          redo A;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare stago',
                          line => $self->{line_prev},
                          column => $self->{column_prev});
          $self->{state} = DATA_STATE;
          ## reconsume

          return  ({type => CHARACTER_TOKEN, data => '<',
                    line => $self->{line_prev},
                    column => $self->{column_prev},
                   });

          redo A;
        }
      } else {
        die "$0: $self->{content_model} in tag open";
      }
    } elsif ($self->{state} == CLOSE_TAG_OPEN_STATE) {
      ## NOTE: The "close tag open state" in the spec is implemented as
      ## |CLOSE_TAG_OPEN_STATE| and |CDATA_PCDATA_CLOSE_TAG_STATE|.

      my ($l, $c) = ($self->{line_prev}, $self->{column_prev} - 1); # "<"of"</"
      if ($self->{content_model} & CM_LIMITED_MARKUP) { # RCDATA | CDATA
        if (defined $self->{last_emitted_start_tag_name}) {
          $self->{state} = CDATA_PCDATA_CLOSE_TAG_STATE;
          $self->{state_keyword} = '';
          ## Reconsume.
          redo A;
        } else {
          ## No start tag token has ever been emitted
          ## NOTE: See <http://krijnhoetmer.nl/irc-logs/whatwg/20070626#l-564>.
          
          $self->{state} = DATA_STATE;
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN, data => '</',
                    line => $l, column => $c,
                   });
          redo A;
        }
      }

      if (0x0041 <= $self->{next_char} and
          $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_token}
            = {type => END_TAG_TOKEN,
               tag_name => chr ($self->{next_char} + 0x0020),
               line => $l, column => $c};
        $self->{state} = TAG_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif (0x0061 <= $self->{next_char} and
               $self->{next_char} <= 0x007A) { # a..z
        
        $self->{current_token} = {type => END_TAG_TOKEN,
                                  tag_name => chr ($self->{next_char}),
                                  line => $l, column => $c};
        $self->{state} = TAG_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty end tag',
                        line => $self->{line_prev}, ## "<" in "</>"
                        column => $self->{column_prev} - 1);
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare etago');
        $self->{state} = DATA_STATE;
        # reconsume

        return  ({type => CHARACTER_TOKEN, data => '</',
                  line => $l, column => $c,
                 });

        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus end tag');
        $self->{state} = BOGUS_COMMENT_STATE;
        $self->{current_token} = {type => COMMENT_TOKEN, data => '',
                                  line => $self->{line_prev}, # "<" of "</"
                                  column => $self->{column_prev} - 1,
                                 };
        ## NOTE: $self->{next_char} is intentionally left as is.
        ## Although the "anything else" case of the spec not explicitly
        ## states that the next input character is to be reconsumed,
        ## it will be included to the |data| of the comment token
        ## generated from the bogus end tag, as defined in the
        ## "bogus comment state" entry.
        redo A;
      }
    } elsif ($self->{state} == CDATA_PCDATA_CLOSE_TAG_STATE) {
      my $ch = substr $self->{last_emitted_start_tag_name}, length $self->{state_keyword}, 1;
      if (length $ch) {
        my $CH = $ch;
        $ch =~ tr/a-z/A-Z/;
        my $nch = chr $self->{next_char};
        if ($nch eq $ch or $nch eq $CH) {
          
          ## Stay in the state.
          $self->{state_keyword} .= $nch;
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          redo A;
        } else {
          
          $self->{state} = DATA_STATE;
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN,
                    data => '</' . $self->{state_keyword},
                    line => $self->{line_prev},
                    column => $self->{column_prev} - 1 - length $self->{state_keyword},
                   });
          redo A;
        }
      } else { # after "<{tag-name}"
        unless ({
                 0x0009 => 1, # HT
                 0x000A => 1, # LF
                 0x000B => 1, # VT
                 0x000C => 1, # FF
                 0x0020 => 1, # SP
                 0x003E => 1, # >
                 0x002F => 1, # /
                 -1 => 1, # EOF
                }->{$self->{next_char}}) {
          
          ## Reconsume.
          $self->{state} = DATA_STATE;
          return  ({type => CHARACTER_TOKEN,
                    data => '</' . $self->{state_keyword},
                    line => $self->{line_prev},
                    column => $self->{column_prev} - 1 - length $self->{state_keyword},
                   });
          redo A;
        } else {
          
          $self->{current_token}
              = {type => END_TAG_TOKEN,
                 tag_name => $self->{last_emitted_start_tag_name},
                 line => $self->{line_prev},
                 column => $self->{column_prev} - 1 - length $self->{state_keyword}};
          $self->{state} = TAG_NAME_STATE;
          ## Reconsume.
          redo A;
        }
      }
    } elsif ($self->{state} == TAG_NAME_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
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
        
        $self->{state} = SELF_CLOSING_START_TAG_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{current_token}->{tag_name} .= chr $self->{next_char};
          # start tag or end tag
        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_attribute}
            = {name => chr ($self->{next_char} + 0x0020),
               value => '',
               line => $self->{line}, column => $self->{column}};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
        $self->{state} = SELF_CLOSING_START_TAG_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad attribute name');
        } else {
          
        }
        $self->{current_attribute}
            = {name => chr ($self->{next_char}),
               value => '',
               line => $self->{line}, column => $self->{column}};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_NAME_STATE) {
      my $before_leave = sub {
        if (exists $self->{current_token}->{attributes} # start tag or end tag
            ->{$self->{current_attribute}->{name}}) { # MUST
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate attribute', text => $self->{current_attribute}->{name}, line => $self->{current_attribute}->{line}, column => $self->{current_attribute}->{column});
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003D) { # =
        
        $before_leave->();
        $self->{state} = BEFORE_ATTRIBUTE_VALUE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        $before_leave->();
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_attribute}->{name} .= chr ($self->{next_char} + 0x0020);
        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
        $before_leave->();
        $self->{state} = SELF_CLOSING_START_TAG_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        $before_leave->();
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad attribute name');
        } else {
          
        }
        $self->{current_attribute}->{name} .= chr ($self->{next_char});
        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003D) { # =
        
        $self->{state} = BEFORE_ATTRIBUTE_VALUE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x005A) { # A..Z
        
        $self->{current_attribute}
            = {name => chr ($self->{next_char} + 0x0020),
               value => '',
               line => $self->{line}, column => $self->{column}};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
        $self->{state} = SELF_CLOSING_START_TAG_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad attribute name');
        } else {
          
        }
        $self->{current_attribute}
            = {name => chr ($self->{next_char}),
               value => '',
               line => $self->{line}, column => $self->{column}};
        $self->{state} = ATTRIBUTE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty unquoted attribute value');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad attribute value');
        } else {
          
        }
        $self->{current_attribute}->{value} .= chr ($self->{next_char});
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        ## NOTE: In the spec, the tokenizer is switched to the 
        ## "entity in attribute value state".  In this implementation, the
        ## tokenizer is switched to the |ENTITY_STATE|, which is an
        ## implementation of the "consume a character reference" algorithm.
        $self->{prev_state} = $self->{state};
        $self->{entity_additional} = 0x0022; # "
        $self->{state} = ENTITY_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed attribute value');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
        $self->{read_until}->($self->{current_attribute}->{value},
                              q["&],
                              length $self->{current_attribute}->{value});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        ## NOTE: In the spec, the tokenizer is switched to the 
        ## "entity in attribute value state".  In this implementation, the
        ## tokenizer is switched to the |ENTITY_STATE|, which is an
        ## implementation of the "consume a character reference" algorithm.
        $self->{entity_additional} = 0x0027; # '
        $self->{prev_state} = $self->{state};
        $self->{state} = ENTITY_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed attribute value');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
        $self->{read_until}->($self->{current_attribute}->{value},
                              q['&],
                              length $self->{current_attribute}->{value});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0026) { # &
        
        ## NOTE: In the spec, the tokenizer is switched to the 
        ## "entity in attribute value state".  In this implementation, the
        ## tokenizer is switched to the |ENTITY_STATE|, which is an
        ## implementation of the "consume a character reference" algorithm.
        $self->{entity_additional} = -1;
        $self->{prev_state} = $self->{state};
        $self->{state} = ENTITY_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
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
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad attribute value');
        } else {
          
        }
        $self->{current_attribute}->{value} .= chr ($self->{next_char});
        $self->{read_until}->($self->{current_attribute}->{value},
                              q["'=& >],
                              length $self->{current_attribute}->{value});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == AFTER_ATTRIBUTE_VALUE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0009 or # HT
          $self->{next_char} == 0x000A or # LF
          $self->{next_char} == 0x000B or # VT
          $self->{next_char} == 0x000C or # FF
          $self->{next_char} == 0x0020) { # SP
        
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == 0x002F) { # /
        
        $self->{state} = SELF_CLOSING_START_TAG_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag'); 
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## Reconsume.
        return  ($self->{current_token}); # start tag or end tag
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space between attributes');
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        ## reconsume
        redo A;
      }
    } elsif ($self->{state} == SELF_CLOSING_START_TAG_STATE) {
      if ($self->{next_char} == 0x003E) { # >
        if ($self->{current_token}->{type} == END_TAG_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'nestc', token => $self->{current_token});
          ## TODO: Different type than slash in start tag
          $self->{content_model} = PCDATA_CONTENT_MODEL; # MUST
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            
          }
          ## TODO: Test |<title></title/>|
        } else {
          
          $self->{self_closing} = 1;
        }

        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # start tag or end tag

        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
        if ($self->{current_token}->{type} == START_TAG_TOKEN) {
          
          $self->{last_emitted_start_tag_name} = $self->{current_token}->{tag_name};
        } elsif ($self->{current_token}->{type} == END_TAG_TOKEN) {
          if ($self->{current_token}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }
        } else {
          die "$0: $self->{current_token}->{type}: Unknown token type";
        }
        $self->{state} = DATA_STATE;
        ## Reconsume.
        return  ($self->{current_token}); # start tag or end tag
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'nestc');
        ## TODO: This error type is wrong.
        $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == BOGUS_COMMENT_STATE) {
      ## (only happen if PCDATA state)

      ## NOTE: Unlike spec's "bogus comment state", this implementation
      ## consumes characters one-by-one basis.
      
      if ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # comment
        redo A;
      } elsif ($self->{next_char} == -1) { 
        
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment
        redo A;
      } else {
        
        $self->{current_token}->{data} .= chr ($self->{next_char}); # comment
        $self->{read_until}->($self->{current_token}->{data},
                              q[>],
                              length $self->{current_token}->{data});

        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == MARKUP_DECLARATION_OPEN_STATE) {
      ## (only happen if PCDATA state)
      
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = MD_HYPHEN_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0044 or # D
               $self->{next_char} == 0x0064) { # d
        ## ASCII case-insensitive.
        
        $self->{state} = MD_DOCTYPE_STATE;
        $self->{state_keyword} = chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{insertion_mode} & IN_FOREIGN_CONTENT_IM and
               $self->{open_elements}->[-1]->[1] & FOREIGN_EL and
               $self->{next_char} == 0x005B) { # [
                        
        $self->{state} = MD_CDATA_STATE;
        $self->{state_keyword} = '[';
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
      }

      $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                      line => $self->{line_prev},
                      column => $self->{column_prev} - 1);
      ## Reconsume.
      $self->{state} = BOGUS_COMMENT_STATE;
      $self->{current_token} = {type => COMMENT_TOKEN, data => '',
                                line => $self->{line_prev},
                                column => $self->{column_prev} - 1,
                               };
      redo A;
    } elsif ($self->{state} == MD_HYPHEN_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{current_token} = {type => COMMENT_TOKEN, data => '',
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 2,
                                 };
        $self->{state} = COMMENT_START_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 2);
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{current_token} = {type => COMMENT_TOKEN,
                                  data => '-',
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 2,
                                 };
        redo A;
      }
    } elsif ($self->{state} == MD_DOCTYPE_STATE) {
      ## ASCII case-insensitive.
      if ($self->{next_char} == [
            undef,
            0x004F, # O
            0x0043, # C
            0x0054, # T
            0x0059, # Y
            0x0050, # P
          ]->[length $self->{state_keyword}] or
          $self->{next_char} == [
            undef,
            0x006F, # o
            0x0063, # c
            0x0074, # t
            0x0079, # y
            0x0070, # p
          ]->[length $self->{state_keyword}]) {
        
        ## Stay in the state.
        $self->{state_keyword} .= chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ((length $self->{state_keyword}) == 6 and
               ($self->{next_char} == 0x0045 or # E
                $self->{next_char} == 0x0065)) { # e
        
        $self->{state} = DOCTYPE_STATE;
        $self->{current_token} = {type => DOCTYPE_TOKEN,
                                  quirks => 1,
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 7,
                                 };
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
                
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1 - length $self->{state_keyword});
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{current_token} = {type => COMMENT_TOKEN,
                                  data => $self->{state_keyword},
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 1 - length $self->{state_keyword},
                                 };
        redo A;
      }
    } elsif ($self->{state} == MD_CDATA_STATE) {
      if ($self->{next_char} == {
            '[' => 0x0043, # C
            '[C' => 0x0044, # D
            '[CD' => 0x0041, # A
            '[CDA' => 0x0054, # T
            '[CDAT' => 0x0041, # A
          }->{$self->{state_keyword}}) {
        
        ## Stay in the state.
        $self->{state_keyword} .= chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{state_keyword} eq '[CDATA' and
               $self->{next_char} == 0x005B) { # [
        
        $self->{current_token} = {type => CHARACTER_TOKEN,
                                  data => '',
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 7};
        $self->{state} = CDATA_SECTION_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1 - length $self->{state_keyword});
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{current_token} = {type => COMMENT_TOKEN,
                                  data => $self->{state_keyword},
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 1 - length $self->{state_keyword},
                                 };
        redo A;
      }
    } elsif ($self->{state} == COMMENT_START_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_START_DASH_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment');
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} # comment
            .= chr ($self->{next_char});
        $self->{state} = COMMENT_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_START_DASH_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_END_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment');
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} # comment
            .= '-' . chr ($self->{next_char});
        $self->{state} = COMMENT_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_END_DASH_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} .= chr ($self->{next_char}); # comment
        $self->{read_until}->($self->{current_token}->{data},
                              q[-],
                              length $self->{current_token}->{data});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_END_DASH_STATE) {
      if ($self->{next_char} == 0x002D) { # -
        
        $self->{state} = COMMENT_END_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{current_token}->{data} .= '-' . chr ($self->{next_char}); # comment
        $self->{state} = COMMENT_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == COMMENT_END_STATE) {
      if ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # comment

        redo A;
      } elsif ($self->{next_char} == 0x002D) { # -
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'dash in comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev});
        $self->{current_token}->{data} .= '-'; # comment
        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # comment

        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'dash in comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev});
        $self->{current_token}->{data} .= '--' . chr ($self->{next_char}); # comment
        $self->{state} = COMMENT_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before DOCTYPE name');
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # DOCTYPE (quirks)

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # DOCTYPE (quirks)

        redo A;
      } else {
        
        $self->{current_token}->{name} = chr $self->{next_char};
        delete $self->{current_token}->{quirks};
## ISSUE: "Set the token's name name to the" in the spec
        $self->{state} = DOCTYPE_NAME_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{name}
          .= chr ($self->{next_char}); # DOCTYPE
        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == 0x0050 or # P
               $self->{next_char} == 0x0070) { # p
        $self->{state} = PUBLIC_STATE;
        $self->{state_keyword} = chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0053 or # S
               $self->{next_char} == 0x0073) { # s
        $self->{state} = SYSTEM_STATE;
        $self->{state_keyword} = chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after DOCTYPE name');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == PUBLIC_STATE) {
      ## ASCII case-insensitive
      if ($self->{next_char} == [
            undef, 
            0x0055, # U
            0x0042, # B
            0x004C, # L
            0x0049, # I
          ]->[length $self->{state_keyword}] or
          $self->{next_char} == [
            undef, 
            0x0075, # u
            0x0062, # b
            0x006C, # l
            0x0069, # i
          ]->[length $self->{state_keyword}]) {
        
        ## Stay in the state.
        $self->{state_keyword} .= chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ((length $self->{state_keyword}) == 5 and
               ($self->{next_char} == 0x0043 or # C
                $self->{next_char} == 0x0063)) { # c
        
        $self->{state} = BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after DOCTYPE name',
                        line => $self->{line_prev},
                        column => $self->{column_prev} + 1 - length $self->{state_keyword});
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == SYSTEM_STATE) {
      ## ASCII case-insensitive
      if ($self->{next_char} == [
            undef, 
            0x0059, # Y
            0x0053, # S
            0x0054, # T
            0x0045, # E
          ]->[length $self->{state_keyword}] or
          $self->{next_char} == [
            undef, 
            0x0079, # y
            0x0073, # s
            0x0074, # t
            0x0065, # e
          ]->[length $self->{state_keyword}]) {
        
        ## Stay in the state.
        $self->{state_keyword} .= chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ((length $self->{state_keyword}) == 5 and
               ($self->{next_char} == 0x004D or # M
                $self->{next_char} == 0x006D)) { # m
        
        $self->{state} = BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after DOCTYPE name',
                        line => $self->{line_prev},
                        column => $self->{column_prev} + 1 - length $self->{state_keyword});
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE) {
      if ({
            0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, 0x0020 => 1,
            #0x000D => 1, # HT, LF, VT, FF, SP, CR
          }->{$self->{next_char}}) {
        
        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} eq 0x0022) { # "
        
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} eq 0x0027) { # '
        
        $self->{current_token}->{public_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} eq 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no PUBLIC literal');

        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after PUBLIC');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{public_identifier} # DOCTYPE
            .= chr $self->{next_char};
        $self->{read_until}->($self->{current_token}->{public_identifier},
                              q[">],
                              length $self->{current_token}->{public_identifier});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{public_identifier} # DOCTYPE
            .= chr $self->{next_char};
        $self->{read_until}->($self->{current_token}->{public_identifier},
                              q['>],
                              length $self->{current_token}->{public_identifier});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after PUBLIC literal');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0022) { # "
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x0027) { # '
        
        $self->{current_token}->{system_identifier} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no SYSTEM literal');
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after SYSTEM');
        $self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0022) { # "
        
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{system_identifier} # DOCTYPE
            .= chr $self->{next_char};
        $self->{read_until}->($self->{current_token}->{system_identifier},
                              q[">],
                              length $self->{current_token}->{system_identifier});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE) {
      if ($self->{next_char} == 0x0027) { # '
        
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{current_token}->{system_identifier} # DOCTYPE
            .= chr $self->{next_char};
        $self->{read_until}->($self->{current_token}->{system_identifier},
                              q['>],
                              length $self->{current_token}->{system_identifier});

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
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
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{current_token}->{quirks} = 1;
        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after SYSTEM literal');
        #$self->{current_token}->{quirks} = 1;

        $self->{state} = BOGUS_DOCTYPE_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == BOGUS_DOCTYPE_STATE) {
      if ($self->{next_char} == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } elsif ($self->{next_char} == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{current_token}); # DOCTYPE

        redo A;
      } else {
        
        my $s = '';
        $self->{read_until}->($s, q[>], 0);

        ## Stay in the state
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }
    } elsif ($self->{state} == CDATA_SECTION_STATE) {
      ## NOTE: "CDATA section state" in the state is jointly implemented
      ## by three states, |CDATA_SECTION_STATE|, |CDATA_SECTION_MSE1_STATE|,
      ## and |CDATA_SECTION_MSE2_STATE|.
      
      if ($self->{next_char} == 0x005D) { # ]
        
        $self->{state} = CDATA_SECTION_MSE1_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == -1) {
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        if (length $self->{current_token}->{data}) { # character
          
          return  ($self->{current_token}); # character
        } else {
          
          ## No token to emit. $self->{current_token} is discarded.
        }        
        redo A;
      } else {
        
        $self->{current_token}->{data} .= chr $self->{next_char};
        $self->{read_until}->($self->{current_token}->{data},
                              q<]>,
                              length $self->{current_token}->{data});

        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      }

      ## ISSUE: "text tokens" in spec.
    } elsif ($self->{state} == CDATA_SECTION_MSE1_STATE) {
      if ($self->{next_char} == 0x005D) { # ]
        
        $self->{state} = CDATA_SECTION_MSE2_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{current_token}->{data} .= ']';
        $self->{state} = CDATA_SECTION_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == CDATA_SECTION_MSE2_STATE) {
      if ($self->{next_char} == 0x003E) { # >
        $self->{state} = DATA_STATE;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        if (length $self->{current_token}->{data}) { # character
          
          return  ($self->{current_token}); # character
        } else {
          
          ## No token to emit. $self->{current_token} is discarded.
        }
        redo A;
      } elsif ($self->{next_char} == 0x005D) { # ]
         # character
        $self->{current_token}->{data} .= ']'; ## Add first "]" of "]]]".
        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{current_token}->{data} .= ']]'; # character
        $self->{state} = CDATA_SECTION_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == ENTITY_STATE) {
      if ({
        0x0009 => 1, 0x000A => 1, 0x000B => 1, 0x000C => 1, # HT, LF, VT, FF,
        0x0020 => 1, 0x003C => 1, 0x0026 => 1, -1 => 1, # SP, <, &
        $self->{entity_additional} => 1,
      }->{$self->{next_char}}) {
        
        ## Don't consume
        ## No error
        ## Return nothing.
        #
      } elsif ($self->{next_char} == 0x0023) { # #
        
        $self->{state} = ENTITY_HASH_STATE;
        $self->{state_keyword} = '#';
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ((0x0041 <= $self->{next_char} and
                $self->{next_char} <= 0x005A) or # A..Z
               (0x0061 <= $self->{next_char} and
                $self->{next_char} <= 0x007A)) { # a..z
        
        require Whatpm::_NamedEntityList;
        $self->{state} = ENTITY_NAME_STATE;
        $self->{state_keyword} = chr $self->{next_char};
        $self->{entity__value} = $self->{state_keyword};
        $self->{entity__match} = 0;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare ero');
        ## Return nothing.
        #
      }

      ## NOTE: No character is consumed by the "consume a character
      ## reference" algorithm.  In other word, there is an "&" character
      ## that does not introduce a character reference, which would be
      ## appended to the parent element or the attribute value in later
      ## process of the tokenizer.

      if ($self->{prev_state} == DATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => '&',
                  line => $self->{line_prev},
                  column => $self->{column_prev},
                 });
        redo A;
      } else {
        
        $self->{current_attribute}->{value} .= '&';
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == ENTITY_HASH_STATE) {
      if ($self->{next_char} == 0x0078 or # x
          $self->{next_char} == 0x0058) { # X
        
        $self->{state} = HEXREF_X_STATE;
        $self->{state_keyword} .= chr $self->{next_char};
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif (0x0030 <= $self->{next_char} and
               $self->{next_char} <= 0x0039) { # 0..9
        
        $self->{state} = NCR_NUM_STATE;
        $self->{state_keyword} = $self->{next_char} - 0x0030;
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare nero',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1);

        ## NOTE: According to the spec algorithm, nothing is returned,
        ## and then "&#" is appended to the parent element or the attribute 
        ## value in the later processing.

        if ($self->{prev_state} == DATA_STATE) {
          
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN,
                    data => '&#',
                    line => $self->{line_prev},
                    column => $self->{column_prev} - 1,
                   });
          redo A;
        } else {
          
          $self->{current_attribute}->{value} .= '&#';
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          redo A;
        }
      }
    } elsif ($self->{state} == NCR_NUM_STATE) {
      if (0x0030 <= $self->{next_char} and 
          $self->{next_char} <= 0x0039) { # 0..9
        
        $self->{state_keyword} *= 10;
        $self->{state_keyword} += $self->{next_char} - 0x0030;
        
        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003B) { # ;
        
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        #
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no refc');
        ## Reconsume.
        #
      }

      my $code = $self->{state_keyword};
      my $l = $self->{line_prev};
      my $c = $self->{column_prev};
      if ($code == 0 or (0xD800 <= $code and $code <= 0xDFFF)) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U+%04X', $code),
                        line => $l, column => $c);
        $code = 0xFFFD;
      } elsif ($code > 0x10FFFF) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U-%08X', $code),
                        line => $l, column => $c);
        $code = 0xFFFD;
      } elsif ($code == 0x000D) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'CR character reference',
                        line => $l, column => $c);
        $code = 0x000A;
      } elsif (0x80 <= $code and $code <= 0x9F) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'C1 character reference',
                        text => (sprintf 'U+%04X', $code),
                        line => $l, column => $c);
        $code = $c1_entity_char->{$code};
      }

      if ($self->{prev_state} == DATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => chr $code,
                  line => $l, column => $c,
                 });
        redo A;
      } else {
        
        $self->{current_attribute}->{value} .= chr $code;
        $self->{current_attribute}->{has_reference} = 1;
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == HEXREF_X_STATE) {
      if ((0x0030 <= $self->{next_char} and $self->{next_char} <= 0x0039) or
          (0x0041 <= $self->{next_char} and $self->{next_char} <= 0x0046) or
          (0x0061 <= $self->{next_char} and $self->{next_char} <= 0x0066)) {
        # 0..9, A..F, a..f
        
        $self->{state} = HEXREF_HEX_STATE;
        $self->{state_keyword} = 0;
        ## Reconsume.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare hcro',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 2);

        ## NOTE: According to the spec algorithm, nothing is returned,
        ## and then "&#" followed by "X" or "x" is appended to the parent
        ## element or the attribute value in the later processing.

        if ($self->{prev_state} == DATA_STATE) {
          
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN,
                    data => '&' . $self->{state_keyword},
                    line => $self->{line_prev},
                    column => $self->{column_prev} - length $self->{state_keyword},
                   });
          redo A;
        } else {
          
          $self->{current_attribute}->{value} .= '&' . $self->{state_keyword};
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          redo A;
        }
      }
    } elsif ($self->{state} == HEXREF_HEX_STATE) {
      if (0x0030 <= $self->{next_char} and $self->{next_char} <= 0x0039) {
        # 0..9
        
        $self->{state_keyword} *= 0x10;
        $self->{state_keyword} += $self->{next_char} - 0x0030;
        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif (0x0061 <= $self->{next_char} and
               $self->{next_char} <= 0x0066) { # a..f
        
        $self->{state_keyword} *= 0x10;
        $self->{state_keyword} += $self->{next_char} - 0x0060 + 9;
        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif (0x0041 <= $self->{next_char} and
               $self->{next_char} <= 0x0046) { # A..F
        
        $self->{state_keyword} *= 0x10;
        $self->{state_keyword} += $self->{next_char} - 0x0040 + 9;
        ## Stay in the state.
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        redo A;
      } elsif ($self->{next_char} == 0x003B) { # ;
        
        
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
        #
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no refc',
                        line => $self->{line},
                        column => $self->{column});
        ## Reconsume.
        #
      }

      my $code = $self->{state_keyword};
      my $l = $self->{line_prev};
      my $c = $self->{column_prev};
      if ($code == 0 or (0xD800 <= $code and $code <= 0xDFFF)) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U+%04X', $code),
                        line => $l, column => $c);
        $code = 0xFFFD;
      } elsif ($code > 0x10FFFF) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U-%08X', $code),
                        line => $l, column => $c);
        $code = 0xFFFD;
      } elsif ($code == 0x000D) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'CR character reference', line => $l, column => $c);
        $code = 0x000A;
      } elsif (0x80 <= $code and $code <= 0x9F) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'C1 character reference', text => (sprintf 'U+%04X', $code), line => $l, column => $c);
        $code = $c1_entity_char->{$code};
      }

      if ($self->{prev_state} == DATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => chr $code,
                  line => $l, column => $c,
                 });
        redo A;
      } else {
        
        $self->{current_attribute}->{value} .= chr $code;
        $self->{current_attribute}->{has_reference} = 1;
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } elsif ($self->{state} == ENTITY_NAME_STATE) {
      if (length $self->{state_keyword} < 30 and
          ## NOTE: Some number greater than the maximum length of entity name
          ((0x0041 <= $self->{next_char} and # a
            $self->{next_char} <= 0x005A) or # x
           (0x0061 <= $self->{next_char} and # a
            $self->{next_char} <= 0x007A) or # z
           (0x0030 <= $self->{next_char} and # 0
            $self->{next_char} <= 0x0039) or # 9
           $self->{next_char} == 0x003B)) { # ;
        our $EntityChar;
        $self->{state_keyword} .= chr $self->{next_char};
        if (defined $EntityChar->{$self->{state_keyword}}) {
          if ($self->{next_char} == 0x003B) { # ;
            
            $self->{entity__value} = $EntityChar->{$self->{state_keyword}};
            $self->{entity__match} = 1;
            
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
            #
          } else {
            
            $self->{entity__value} = $EntityChar->{$self->{state_keyword}};
            $self->{entity__match} = -1;
            ## Stay in the state.
            
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
            redo A;
          }
        } else {
          
          $self->{entity__value} .= chr $self->{next_char};
          $self->{entity__match} *= 2;
          ## Stay in the state.
          
    pop @{$self->{prev_char}};
    unshift @{$self->{prev_char}}, $self->{next_char};

    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{next_char}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_next_char}->($self);
    }
  
          redo A;
        }
      }

      my $data;
      my $has_ref;
      if ($self->{entity__match} > 0) {
        
        $data = $self->{entity__value};
        $has_ref = 1;
        #
      } elsif ($self->{entity__match} < 0) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no refc');
        if ($self->{prev_state} != DATA_STATE and # in attribute
            $self->{entity__match} < -1) {
          
          $data = '&' . $self->{state_keyword};
          #
        } else {
          
          $data = $self->{entity__value};
          $has_ref = 1;
          #
        }
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare ero',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - length $self->{state_keyword});
        $data = '&' . $self->{state_keyword};
        #
      }
  
      ## NOTE: In these cases, when a character reference is found,
      ## it is consumed and a character token is returned, or, otherwise,
      ## nothing is consumed and returned, according to the spec algorithm.
      ## In this implementation, anything that has been examined by the
      ## tokenizer is appended to the parent element or the attribute value
      ## as string, either literal string when no character reference or
      ## entity-replaced string otherwise, in this stage, since any characters
      ## that would not be consumed are appended in the data state or in an
      ## appropriate attribute value state anyway.
 
      if ($self->{prev_state} == DATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN,
                  data => $data,
                  line => $self->{line_prev},
                  column => $self->{column_prev} + 1 - length $self->{state_keyword},
                 });
        redo A;
      } else {
        
        $self->{current_attribute}->{value} .= $data;
        $self->{current_attribute}->{has_reference} = 1 if $has_ref;
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } else {
      die "$0: $self->{state}: Unknown state";
    }
  } # A   

  die "$0: _get_next_token: unexpected case";
} # _get_next_token

sub _initialize_tree_constructor ($) {
  my $self = shift;
  ## NOTE: $self->{document} MUST be specified before this method is called
  $self->{document}->strict_error_checking (0);
  ## TODO: Turn mutation events off # MUST
  ## TODO: Turn loose Document option (manakai extension) on
  $self->{document}->manakai_is_html (1); # MUST
  $self->{document}->set_user_data (manakai_source_line => 1);
  $self->{document}->set_user_data (manakai_source_column => 1);
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
      $doctype_name =~ tr/a-z/A-Z/; # ASCII case-insensitive
      if (not defined $token->{name} or # <!DOCTYPE>
          defined $token->{system_identifier}) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'not HTML5', token => $token);
      } elsif ($doctype_name ne 'HTML') {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'not HTML5', token => $token);
      } elsif (defined $token->{public_identifier}) {
        if ($token->{public_identifier} eq 'XSLT-compat') {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'XSLT-compat', token => $token,
                          level => $self->{level}->{should});
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not HTML5', token => $token);
        }
      } else {
        
        #
      }
      
      my $doctype = $self->{document}->create_document_type_definition
        ($token->{name}); ## ISSUE: If name is missing (e.g. <!DOCTYPE>)?
      ## NOTE: Default value for both |public_id| and |system_id| attributes
      ## are empty strings, so that we don't set any value in missing cases.
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
        my $prefix = [
          "+//SILMARIL//DTD HTML PRO V0R11 19970101//",
          "-//ADVASOFT LTD//DTD HTML 3.0 ASWEDIT + EXTENSIONS//",
          "-//AS//DTD HTML 3.0 ASWEDIT + EXTENSIONS//",
          "-//IETF//DTD HTML 2.0 LEVEL 1//",
          "-//IETF//DTD HTML 2.0 LEVEL 2//",
          "-//IETF//DTD HTML 2.0 STRICT LEVEL 1//",
          "-//IETF//DTD HTML 2.0 STRICT LEVEL 2//",
          "-//IETF//DTD HTML 2.0 STRICT//",
          "-//IETF//DTD HTML 2.0//",
          "-//IETF//DTD HTML 2.1E//",
          "-//IETF//DTD HTML 3.0//",
          "-//IETF//DTD HTML 3.2 FINAL//",
          "-//IETF//DTD HTML 3.2//",
          "-//IETF//DTD HTML 3//",
          "-//IETF//DTD HTML LEVEL 0//",
          "-//IETF//DTD HTML LEVEL 1//",
          "-//IETF//DTD HTML LEVEL 2//",
          "-//IETF//DTD HTML LEVEL 3//",
          "-//IETF//DTD HTML STRICT LEVEL 0//",
          "-//IETF//DTD HTML STRICT LEVEL 1//",
          "-//IETF//DTD HTML STRICT LEVEL 2//",
          "-//IETF//DTD HTML STRICT LEVEL 3//",
          "-//IETF//DTD HTML STRICT//",
          "-//IETF//DTD HTML//",
          "-//METRIUS//DTD METRIUS PRESENTATIONAL//",
          "-//MICROSOFT//DTD INTERNET EXPLORER 2.0 HTML STRICT//",
          "-//MICROSOFT//DTD INTERNET EXPLORER 2.0 HTML//",
          "-//MICROSOFT//DTD INTERNET EXPLORER 2.0 TABLES//",
          "-//MICROSOFT//DTD INTERNET EXPLORER 3.0 HTML STRICT//",
          "-//MICROSOFT//DTD INTERNET EXPLORER 3.0 HTML//",
          "-//MICROSOFT//DTD INTERNET EXPLORER 3.0 TABLES//",
          "-//NETSCAPE COMM. CORP.//DTD HTML//",
          "-//NETSCAPE COMM. CORP.//DTD STRICT HTML//",
          "-//O'REILLY AND ASSOCIATES//DTD HTML 2.0//",
          "-//O'REILLY AND ASSOCIATES//DTD HTML EXTENDED 1.0//",
          "-//O'REILLY AND ASSOCIATES//DTD HTML EXTENDED RELAXED 1.0//",
          "-//SOFTQUAD SOFTWARE//DTD HOTMETAL PRO 6.0::19990601::EXTENSIONS TO HTML 4.0//",
          "-//SOFTQUAD//DTD HOTMETAL PRO 4.0::19971010::EXTENSIONS TO HTML 4.0//",
          "-//SPYGLASS//DTD HTML 2.0 EXTENDED//",
          "-//SQ//DTD HTML 2.0 HOTMETAL + EXTENSIONS//",
          "-//SUN MICROSYSTEMS CORP.//DTD HOTJAVA HTML//",
          "-//SUN MICROSYSTEMS CORP.//DTD HOTJAVA STRICT HTML//",
          "-//W3C//DTD HTML 3 1995-03-24//",
          "-//W3C//DTD HTML 3.2 DRAFT//",
          "-//W3C//DTD HTML 3.2 FINAL//",
          "-//W3C//DTD HTML 3.2//",
          "-//W3C//DTD HTML 3.2S DRAFT//",
          "-//W3C//DTD HTML 4.0 FRAMESET//",
          "-//W3C//DTD HTML 4.0 TRANSITIONAL//",
          "-//W3C//DTD HTML EXPERIMETNAL 19960712//",
          "-//W3C//DTD HTML EXPERIMENTAL 970421//",
          "-//W3C//DTD W3 HTML//",
          "-//W3O//DTD W3 HTML 3.0//",
          "-//WEBTECHS//DTD MOZILLA HTML 2.0//",
          "-//WEBTECHS//DTD MOZILLA HTML//",
        ]; # $prefix
        my $match;
        for (@$prefix) {
          if (substr ($prefix, 0, length $_) eq $_) {
            $match = 1;
            last;
          }
        }
        if ($match or
            $pubid eq "-//W3O//DTD W3 HTML STRICT 3.0//EN//" or
            $pubid eq "-/W3C/DTD HTML 4.0 TRANSITIONAL/EN" or
            $pubid eq "HTML") {
          
          $self->{document}->manakai_compat_mode ('quirks');
        } elsif ($pubid =~ m[^-//W3C//DTD HTML 4.01 FRAMESET//] or
                 $pubid =~ m[^-//W3C//DTD HTML 4.01 TRANSITIONAL//]) {
          if (defined $token->{system_identifier}) {
            
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
      if (defined $token->{system_identifier}) {
        my $sysid = $token->{system_identifier};
        $sysid =~ tr/A-Z/a-z/;
        if ($sysid eq "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd") {
          ## NOTE: Ensure that |PUBLIC "(limited quirks)" "(quirks)"| is 
          ## marked as quirks.
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
      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE', token => $token);
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

      $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE', token => $token);
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
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#DOCTYPE', token => $token);
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
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          my $attr_t =  $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $root_element->set_attribute_node_ns ($attr);
        }
      
        $root_element->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $root_element->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
          $self->{document}->append_child ($root_element);
          push @{$self->{open_elements}},
              [$root_element, $el_category->{html}];

          if ($token->{attributes}->{manifest}) {
            
            $self->{application_cache_selection}
                ->($token->{attributes}->{manifest}->{value});
            ## ISSUE: Spec is unclear on relative references.
            ## According to Hixie (#whatwg 2008-03-19), it should be
            ## resolved against the base URI of the document in HTML
            ## or xml:base of the element in XHTML.
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
        ($HTML_NS, [undef,  'html']);
    
        $root_element->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $root_element->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
    $self->{document}->append_child ($root_element);
    push @{$self->{open_elements}}, [$root_element, $el_category->{html}];

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
      if ($self->{open_elements}->[0]->[0] eq $node->[0]) {
        $last = 1;
        if (defined $self->{inner_html_node}) {
          
          $node = $self->{inner_html_node};
        } else {
          die "_reset_insertion_mode: t27";
        }
      }
      
      ## Step 4..14
      my $new_mode;
      if ($node->[1] & FOREIGN_EL) {
        
        ## NOTE: Strictly spaking, the line below only applies to MathML and
        ## SVG elements.  Currently the HTML syntax supports only MathML and
        ## SVG elements as foreigners.
        $new_mode = IN_BODY_IM | IN_FOREIGN_CONTENT_IM;
      } elsif ($node->[1] & TABLE_CELL_EL) {
        if ($last) {
          
          #
        } else {
          
          $new_mode = IN_CELL_IM;
        }
      } else {
        
        $new_mode = {
                      select => IN_SELECT_IM,
                      ## NOTE: |option| and |optgroup| do not set
                      ## insertion mode to "in select" by themselves.
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
      $self->{insertion_mode} = $new_mode and return if defined $new_mode;
      
      ## Step 15
      if ($node->[1] & HTML_EL) {
        unless (defined $self->{head_element}) {
          
          $self->{insertion_mode} = BEFORE_HEAD_IM;
        } else {
          ## ISSUE: Can this state be reached?
          
          $self->{insertion_mode} = AFTER_HEAD_IM;
        }
        return;
      } else {
        
      }
      
      ## Step 16
      $self->{insertion_mode} = IN_BODY_IM and return if $last;
      
      ## Step 17
      $i--;
      $node = $self->{open_elements}->[$i];
      
      ## Step 18
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

  my $insert;

  my $parse_rcdata = sub ($) {
    my ($content_model_flag) = @_;

    ## Step 1
    my $start_tag_name = $token->{tag_name};
    my $el;
    
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $start_tag_name]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          my $attr_t =  $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      

    ## Step 2
    $insert->($el);

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
    } else {
      ## NOTE: An end-of-file token.
      if ($content_model_flag == CDATA_CONTENT_MODEL) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in CDATA:#eof', token => $token);
      } elsif ($content_model_flag == RCDATA_CONTENT_MODEL) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in RCDATA:#eof', token => $token);
      } else {
        die "$0: $content_model_flag in parse_rcdata";
      }
    }
    $token = $self->_get_next_token;
  }; # $parse_rcdata

  my $script_start_tag = sub () {
    my $script_el;
    
      $script_el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'script']);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          my $attr_t =  $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $script_el->set_attribute_node_ns ($attr);
        }
      
        $script_el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $script_el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
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
      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in CDATA:#eof', token => $token);
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

  ## NOTE: $open_tables->[-1]->[0] is the "current table" element node.
  ## NOTE: $open_tables->[-1]->[1] is the "tainted" flag.
  my $open_tables = [[$self->{open_elements}->[0]->[0]]];

  my $formatting_end_tag = sub {
    my $end_tag_token = shift;
    my $tag_name = $end_tag_token->{tag_name};

    ## NOTE: The adoption agency algorithm (AAA).

    FET: {
      ## Step 1
      my $formatting_element;
      my $formatting_element_i_in_active;
      AFE: for (reverse 0..$#$active_formatting_elements) {
        if ($active_formatting_elements->[$_]->[0] eq '#marker') {
          
          last AFE;
        } elsif ($active_formatting_elements->[$_]->[0]->manakai_local_name
                     eq $tag_name) {
          
          $formatting_element = $active_formatting_elements->[$_];
          $formatting_element_i_in_active = $_;
          last AFE;
        }
      } # AFE
      unless (defined $formatting_element) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag', text => $tag_name, token => $end_tag_token);
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
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $token->{tag_name},
                            token => $end_tag_token);
            ## Ignore the token
            $token = $self->_get_next_token;
            return;
          }
        } elsif ($node->[1] & SCOPING_EL) {
          
          $in_scope = 0;
        }
      } # INSCOPE
      unless (defined $formatting_element_i_in_open) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => $token->{tag_name},
                        token => $end_tag_token);
        pop @$active_formatting_elements; # $formatting_element
        $token = $self->_get_next_token; ## TODO: ok?
        return;
      }
      if (not $self->{open_elements}->[-1]->[0] eq $formatting_element->[0]) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                        text => $self->{open_elements}->[-1]->[0]
                            ->manakai_local_name,
                        token => $end_tag_token);
      }
      
      ## Step 2
      my $furthest_block;
      my $furthest_block_i_in_open;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        my $node = $self->{open_elements}->[$_];
        if (not ($node->[1] & FORMATTING_EL) and 
            #not $phrasing_category->{$node->[1]} and
            ($node->[1] & SPECIAL_EL or
             $node->[1] & SCOPING_EL)) { ## Scoping is redundant, maybe
          
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
      if ($common_ancestor_node->[1] & TABLE_ROWS_EL) {
        my $foster_parent_element;
        my $next_sibling;
        OE: for (reverse 0..$#{$self->{open_elements}}) {
          if ($self->{open_elements}->[$_]->[1] & TABLE_EL) {
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
        $foster_parent_element->insert_before ($last_node->[0], $next_sibling);
        $open_tables->[-1]->[1] = 1; # tainted
      } else {
        
        $common_ancestor_node->[0]->append_child ($last_node->[0]);
      }
      
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

  $insert = my $insert_to_current = sub {
    $self->{open_elements}->[-1]->[0]->append_child ($_[0]);
  }; # $insert_to_current

  my $insert_to_foster = sub {
    my $child = shift;
    if ($self->{open_elements}->[-1]->[1] & TABLE_ROWS_EL) {
      # MUST
      my $foster_parent_element;
      my $next_sibling;
      OE: for (reverse 0..$#{$self->{open_elements}}) {
        if ($self->{open_elements}->[$_]->[1] & TABLE_EL) {
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
      $open_tables->[-1]->[1] = 1; # tainted
    } else {
      
      $self->{open_elements}->[-1]->[0]->append_child ($child);
    }
  }; # $insert_to_foster

  B: while (1) {
    if ($token->{type} == DOCTYPE_TOKEN) {
      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'in html:#DOCTYPE', token => $token);
      ## Ignore the token
      ## Stay in the phase
      $token = $self->_get_next_token;
      next B;
    } elsif ($token->{type} == START_TAG_TOKEN and
             $token->{tag_name} eq 'html') {
      if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html', text => 'html', token => $token);
        $self->{insertion_mode} = AFTER_BODY_IM;
      } elsif ($self->{insertion_mode} == AFTER_HTML_FRAMESET_IM) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html', text => 'html', token => $token);
        $self->{insertion_mode} = AFTER_FRAMESET_IM;
      } else {
        
      }

      
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'not first start tag', token => $token);
      my $top_el = $self->{open_elements}->[0]->[0];
      for my $attr_name (keys %{$token->{attributes}}) {
        unless ($top_el->has_attribute_ns (undef, $attr_name)) {
          
          $top_el->set_attribute_ns
            (undef, [undef, $attr_name], 
             $token->{attributes}->{$attr_name}->{value});
        }
      }
      
      $token = $self->_get_next_token;
      next B;
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
      next B;
    } elsif ($self->{insertion_mode} & IN_FOREIGN_CONTENT_IM) {
      if ($token->{type} == CHARACTER_TOKEN) {
        
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ((not {mglyph => 1, malignmark => 1}->{$token->{tag_name}} and
             $self->{open_elements}->[-1]->[1] & FOREIGN_FLOW_CONTENT_EL) or
            not ($self->{open_elements}->[-1]->[1] & FOREIGN_EL) or
            ($token->{tag_name} eq 'svg' and
             $self->{open_elements}->[-1]->[1] & MML_AXML_EL)) {
          ## NOTE: "using the rules for secondary insertion mode"then"continue"
          
          #
        } elsif ({
                  b => 1, big => 1, blockquote => 1, body => 1, br => 1,
                  center => 1, code => 1, dd => 1, div => 1, dl => 1, dt => 1,
                  em => 1, embed => 1, font => 1, h1 => 1, h2 => 1, h3 => 1,
                  h4 => 1, h5 => 1, h6 => 1, head => 1, hr => 1, i => 1,
                  img => 1, li => 1, listing => 1, menu => 1, meta => 1,
                  nobr => 1, ol => 1, p => 1, pre => 1, ruby => 1, s => 1,
                  small => 1, span => 1, strong => 1, strike => 1, sub => 1,
                  sup => 1, table => 1, tt => 1, u => 1, ul => 1, var => 1,
                 }->{$token->{tag_name}}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                          text => $self->{open_elements}->[-1]->[0]
                              ->manakai_local_name,
                          token => $token);

          pop @{$self->{open_elements}}
              while $self->{open_elements}->[-1]->[1] & FOREIGN_EL;

          $self->{insertion_mode} &= ~ IN_FOREIGN_CONTENT_IM;
          ## Reprocess.
          next B;
        } else {
          my $nsuri = $self->{open_elements}->[-1]->[0]->namespace_uri;
          my $tag_name = $token->{tag_name};
          if ($nsuri eq $SVG_NS) {
            $tag_name = {
               altglyph => 'altGlyph',
               altglyphdef => 'altGlyphDef',
               altglyphitem => 'altGlyphItem',
               animatecolor => 'animateColor',
               animatemotion => 'animateMotion',
               animatetransform => 'animateTransform',
               clippath => 'clipPath',
               feblend => 'feBlend',
               fecolormatrix => 'feColorMatrix',
               fecomponenttransfer => 'feComponentTransfer',
               fecomposite => 'feComposite',
               feconvolvematrix => 'feConvolveMatrix',
               fediffuselighting => 'feDiffuseLighting',
               fedisplacementmap => 'feDisplacementMap',
               fedistantlight => 'feDistantLight',
               feflood => 'feFlood',
               fefunca => 'feFuncA',
               fefuncb => 'feFuncB',
               fefuncg => 'feFuncG',
               fefuncr => 'feFuncR',
               fegaussianblur => 'feGaussianBlur',
               feimage => 'feImage',
               femerge => 'feMerge',
               femergenode => 'feMergeNode',
               femorphology => 'feMorphology',
               feoffset => 'feOffset',
               fepointlight => 'fePointLight',
               fespecularlighting => 'feSpecularLighting',
               fespotlight => 'feSpotLight',
               fetile => 'feTile',
               feturbulence => 'feTurbulence',
               foreignobject => 'foreignObject',
               glyphref => 'glyphRef',
               lineargradient => 'linearGradient',
               radialgradient => 'radialGradient',
               #solidcolor => 'solidColor', ## NOTE: Commented in spec (SVG1.2)
               textpath => 'textPath',  
            }->{$tag_name} || $tag_name;
          }

          ## "adjust SVG attributes" (SVG only) - done in insert-element-f

          ## "adjust foreign attributes" - done in insert-element-f

          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($nsuri, [undef,   $tag_name]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (
          @{
            $foreign_attr_xname->{$attr_name} ||
            [undef, [undef,
                     ($nsuri) eq $SVG_NS ?
                         ($svg_attr_name->{$attr_name} || $attr_name) :
                     ($nsuri) eq $MML_NS ?
                         ($attr_name eq 'definitionurl' ?
                             'definitionURL' : $attr_name) :
                         $attr_name]]
          }
        );
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, ($el_category_f->{$nsuri}->{ $tag_name} || 0) | FOREIGN_EL];

      if ( $token->{attributes}->{xmlns} and  $token->{attributes}->{xmlns}->{value} ne ($nsuri)) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad namespace', token =>  $token);
## TODO: Error type documentation
      }
    }
  

          if ($self->{self_closing}) {
            pop @{$self->{open_elements}};
            delete $self->{self_closing};
          } else {
            
          }

          $token = $self->_get_next_token;
          next B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
        ## NOTE: "using the rules for secondary insertion mode" then "continue"
        
        #
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                        text => $self->{open_elements}->[-1]->[0]
                            ->manakai_local_name,
                        token => $token);

        pop @{$self->{open_elements}}
            while $self->{open_elements}->[-1]->[1] & FOREIGN_EL;

        $self->{insertion_mode} &= ~ IN_FOREIGN_CONTENT_IM;
        ## Reprocess.
        next B;
      } else {
        die "$0: $token->{type}: Unknown token type";        
      }
    }

    if ($self->{insertion_mode} & HEAD_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          unless ($self->{insertion_mode} == BEFORE_HEAD_IM) {
            
            $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
            #
          } else {
            
            ## Ignore the token.
            #
          }
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
            next B;
          }
## TODO: set $token->{column} appropriately
        }

        if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          
          ## As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
          $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
          push @{$self->{open_elements}},
              [$self->{head_element}, $el_category->{head}];

          ## Reprocess in the "in head" insertion mode...
          pop @{$self->{open_elements}};

          ## Reprocess in the "after head" insertion mode...
        } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
          
          ## As if </noscript>
          pop @{$self->{open_elements}};
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:#text', token => $token);
          
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
        ($HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        next B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($token->{tag_name} eq 'head') {
          if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
            
            
      $self->{head_element} = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          my $attr_t =  $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $self->{head_element}->set_attribute_node_ns ($attr);
        }
      
        $self->{head_element}->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
            $self->{open_elements}->[-1]->[0]->append_child
                ($self->{head_element});
            push @{$self->{open_elements}},
                [$self->{head_element}, $el_category->{head}];
            $self->{insertion_mode} = IN_HEAD_IM;
            
            $token = $self->_get_next_token;
            next B;
          } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head', text => 'head',
                            token => $token);
            ## Ignore the token
            
            $token = $self->_get_next_token;
            next B;
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in head:head',
                            token => $token); # or in head noscript
            ## Ignore the token
            
            $token = $self->_get_next_token;
            next B;
          }
        } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          
          ## As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
          $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
          push @{$self->{open_elements}},
              [$self->{head_element}, $el_category->{head}];

          $self->{insertion_mode} = IN_HEAD_IM;
          ## Reprocess in the "in head" insertion mode...
        } else {
          
        }

            if ($token->{tag_name} eq 'base') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'base',
                                token => $token);
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } else {
                
              }

              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                                text => $token->{tag_name}, token => $token);
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];
              } else {
                
              }
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
              pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.
              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              
              $token = $self->_get_next_token;
              next B;
            } elsif ($token->{tag_name} eq 'link') {
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                                text => $token->{tag_name}, token => $token);
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];
              } else {
                
              }
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
              pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.
              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              delete $self->{self_closing};
              $token = $self->_get_next_token;
              next B;
            } elsif ($token->{tag_name} eq 'meta') {
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                                text => $token->{tag_name}, token => $token);
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];
              } else {
                
              }
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
              my $meta_el = pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.

              unless ($self->{confident}) {
                if ($token->{attributes}->{charset}) {
                  
                  ## NOTE: Whether the encoding is supported or not is handled
                  ## in the {change_encoding} callback.
                  $self->{change_encoding}
                      ->($self, $token->{attributes}->{charset}->{value},
                         $token);
                  
                  $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                      ->set_user_data (manakai_has_reference =>
                                           $token->{attributes}->{charset}
                                               ->{has_reference});
                } elsif ($token->{attributes}->{content}) {
                  if ($token->{attributes}->{content}->{value}
                      =~ /[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                          [\x09-\x0D\x20]*=
                          [\x09-\x0D\x20]*(?>"([^"]*)"|'([^']*)'|
                          ([^"'\x09-\x0D\x20][^\x09-\x0D\x20\x3B]*))/x) {
                    
                    ## NOTE: Whether the encoding is supported or not is handled
                    ## in the {change_encoding} callback.
                    $self->{change_encoding}
                        ->($self, defined $1 ? $1 : defined $2 ? $2 : $3,
                           $token);
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

              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              delete $self->{self_closing};
              $token = $self->_get_next_token;
              next B;
            } elsif ($token->{tag_name} eq 'title') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'title',
                                token => $token);
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                                text => $token->{tag_name}, token => $token);
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];
              } else {
                
              }

              ## NOTE: There is a "as if in head" code clone.
              my $parent = defined $self->{head_element} ? $self->{head_element}
                  : $self->{open_elements}->[-1]->[0];
              $parse_rcdata->(RCDATA_CONTENT_MODEL);
              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              next B;
            } elsif ($token->{tag_name} eq 'style' or
                     $token->{tag_name} eq 'noframes') {
              ## NOTE: Or (scripting is enabled and tag_name eq 'noscript' and
              ## insertion mode IN_HEAD_IM)
              ## NOTE: There is a "as if in head" code clone.
              if ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                                text => $token->{tag_name}, token => $token);
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];
              } else {
                
              }
              $parse_rcdata->(CDATA_CONTENT_MODEL);
              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              next B;
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_IM) {
                
                ## NOTE: and scripting is disalbed
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
                $self->{insertion_mode} = IN_HEAD_NOSCRIPT_IM;
                
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'noscript',
                                token => $token);
                ## Ignore the token
                
                $token = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
            } elsif ($token->{tag_name} eq 'script') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript', text => 'script',
                                token => $token);
              
                $self->{insertion_mode} = IN_HEAD_IM;
                ## Reprocess in the "in head" insertion mode...
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'after head',
                                text => $token->{tag_name}, token => $token);
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];
              } else {
                
              }

              ## NOTE: There is a "as if in head" code clone.
              $script_start_tag->();
              pop @{$self->{open_elements}} # <head>
                  if $self->{insertion_mode} == AFTER_HEAD_IM;
              next B;
            } elsif ($token->{tag_name} eq 'body' or
                     $token->{tag_name} eq 'frameset') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript',
                                text => $token->{tag_name}, token => $token);
                
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
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
              if ($token->{tag_name} eq 'body') {
                
                $self->{insertion_mode} = IN_BODY_IM;
              } elsif ($token->{tag_name} eq 'frameset') {
                
                $self->{insertion_mode} = IN_FRAMESET_IM;
              } else {
                die "$0: tag name: $self->{tag_name}";
              }
              
              $token = $self->_get_next_token;
              next B;
            } else {
              
              #
            }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:/',
                              text => $token->{tag_name}, token => $token);
              
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
        ($HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
            $self->{insertion_mode} = IN_BODY_IM;
            ## reprocess
            
            next B;
          } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'head') {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                ## As if <head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                push @{$self->{open_elements}},
                    [$self->{head_element}, $el_category->{head}];

                ## Reprocess in the "in head" insertion mode...
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## As if </noscript>
                pop @{$self->{open_elements}};
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:/',
                                text => 'head', token => $token);
                
                ## Reprocess in the "in head" insertion mode...
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
                
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag', text => 'head',
                                token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } else {
                die "$0: $self->{insertion_mode}: Unknown insertion mode";
              }
            } elsif ($token->{tag_name} eq 'noscript') {
              if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = IN_HEAD_IM;
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == BEFORE_HEAD_IM or
                       $self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => 'noscript', token => $token);
                ## Ignore the token ## ISSUE: An issue in the spec.
                $token = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
            } elsif ({
                      body => 1, html => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM or
                  $self->{insertion_mode} == IN_HEAD_IM or
                  $self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == AFTER_HEAD_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } else {
                die "$0: $self->{insertion_mode}: Unknown insertion mode";
              }
            } elsif ($token->{tag_name} eq 'p') {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => $token->{tag_name}, token => $token);
              ## Ignore the token
              $token = $self->_get_next_token;
              next B;
            } elsif ($token->{tag_name} eq 'br') {
              if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
                
                ## (before head) as if <head>, (in head) as if </head>
                
      $self->{head_element} = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
                $self->{open_elements}->[-1]->[0]->append_child ($self->{head_element});
                $self->{insertion_mode} = AFTER_HEAD_IM;
  
                ## Reprocess in the "after head" insertion mode...
              } elsif ($self->{insertion_mode} == IN_HEAD_IM) {
                
                ## As if </head>
                pop @{$self->{open_elements}};
                $self->{insertion_mode} = AFTER_HEAD_IM;
  
                ## Reprocess in the "after head" insertion mode...
              } elsif ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
                
                ## ISSUE: Two parse errors for <head><noscript></br>
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => 'br', token => $token);
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

              ## ISSUE: does not agree with IE7 - it doesn't ignore </br>.
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => 'br', token => $token);
              ## Ignore the token
              $token = $self->_get_next_token;
              next B;
            } else {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => $token->{tag_name}, token => $token);
              ## Ignore the token
              $token = $self->_get_next_token;
              next B;
            }

            if ($self->{insertion_mode} == IN_HEAD_NOSCRIPT_IM) {
              
              ## As if </noscript>
              pop @{$self->{open_elements}};
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:/',
                              text => $token->{tag_name}, token => $token);
              
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
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => $token->{tag_name}, token => $token);
              ## Ignore the token ## ISSUE: An issue in the spec.
              $token = $self->_get_next_token;
              next B;
            } else {
              
            }

            ## "after head" insertion mode
            ## As if <body>
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
            $self->{insertion_mode} = IN_BODY_IM;
            ## reprocess
            next B;
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        if ($self->{insertion_mode} == BEFORE_HEAD_IM) {
          

          ## NOTE: As if <head>
          
      $self->{head_element} = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'head']);
    
        $self->{head_element}->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $self->{head_element}->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
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
          

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in noscript:#eof', token => $token);

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
        ($HTML_NS, [undef,  'body']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'body'} || 0];
    }
  
        $self->{insertion_mode} = IN_BODY_IM;
        ## NOTE: Reprocess.
        next B;
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
            next B;
          } elsif ($token->{type} == START_TAG_TOKEN) {
            if ({
                 caption => 1, col => 1, colgroup => 1, tbody => 1,
                 td => 1, tfoot => 1, th => 1, thead => 1, tr => 1,
                }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} == IN_CELL_IM) {
                ## have an element in table scope
                for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] & TABLE_CELL_EL) {
                    

                    ## Close the cell
                    
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <x>
                    $token = {type => END_TAG_TOKEN,
                              tag_name => $node->[0]->manakai_local_name,
                              line => $token->{line},
                              column => $token->{column}};
                    next B;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    ## ISSUE: This case can never be reached, maybe.
                    last;
                  }
                }

                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'start tag not allowed',
                    text => $token->{tag_name}, token => $token);
                ## Ignore the token
                
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_CAPTION_IM) {
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'caption',
                                token => $token);
                
                ## NOTE: As if </caption>.
                ## have a table element in table scope
                my $i;
                INSCOPE: {
                  for (reverse 0..$#{$self->{open_elements}}) {
                    my $node = $self->{open_elements}->[$_];
                    if ($node->[1] & CAPTION_EL) {
                      
                      $i = $_;
                      last INSCOPE;
                    } elsif ($node->[1] & TABLE_SCOPING_EL) {
                      
                      last;
                    }
                  }

                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'start tag not allowed',
                                  text => $token->{tag_name}, token => $token);
                  ## Ignore the token
                  
                  $token = $self->_get_next_token;
                  next B;
                } # INSCOPE
                
                ## generate implied end tags
                while ($self->{open_elements}->[-1]->[1]
                           & END_TAG_OPTIONAL_EL) {
                  
                  pop @{$self->{open_elements}};
                }

                unless ($self->{open_elements}->[-1]->[1] & CAPTION_EL) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                  text => $self->{open_elements}->[-1]->[0]
                                      ->manakai_local_name,
                                  token => $token);
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                ## reprocess
                
                next B;
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
                  if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
                    $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                    text => $token->{tag_name},
                                    token => $token);
                    ## Ignore the token
                    $token = $self->_get_next_token;
                    next B;
                  }
                
                ## generate implied end tags
                while ($self->{open_elements}->[-1]->[1]
                           & END_TAG_OPTIONAL_EL) {
                  
                  pop @{$self->{open_elements}};
                }

                if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                        ne $token->{tag_name}) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                  text => $self->{open_elements}->[-1]->[0]
                                      ->manakai_local_name,
                                  token => $token);
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_ROW_IM;
                
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_CAPTION_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
            } elsif ($token->{tag_name} eq 'caption') {
              if ($self->{insertion_mode} == IN_CAPTION_IM) {
                ## have a table element in table scope
                my $i;
                INSCOPE: {
                  for (reverse 0..$#{$self->{open_elements}}) {
                    my $node = $self->{open_elements}->[$_];
                    if ($node->[1] & CAPTION_EL) {
                      
                      $i = $_;
                      last INSCOPE;
                    } elsif ($node->[1] & TABLE_SCOPING_EL) {
                      
                      last;
                    }
                  }

                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $token->{tag_name}, token => $token);
                  ## Ignore the token
                  $token = $self->_get_next_token;
                  next B;
                } # INSCOPE
                
                ## generate implied end tags
                while ($self->{open_elements}->[-1]->[1]
                           & END_TAG_OPTIONAL_EL) {
                  
                  pop @{$self->{open_elements}};
                }
                
                unless ($self->{open_elements}->[-1]->[1] & CAPTION_EL) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                  text => $self->{open_elements}->[-1]->[0]
                                      ->manakai_local_name,
                                  token => $token);
                } else {
                  
                }
                
                splice @{$self->{open_elements}}, $i;
                
                $clear_up_to_marker->();
                
                $self->{insertion_mode} = IN_TABLE_IM;
                
                $token = $self->_get_next_token;
                next B;
              } elsif ($self->{insertion_mode} == IN_CELL_IM) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
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
              INSCOPE: {
                for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
                    
                    $i = $_;

                    ## Close the cell
                    
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # </x>
                    $token = {type => END_TAG_TOKEN, tag_name => $tn,
                              line => $token->{line},
                              column => $token->{column}};
                    next B;
                  } elsif ($node->[1] & TABLE_CELL_EL) {
                    
                    $tn = $node->[0]->manakai_local_name;
                    ## NOTE: There is exactly one |td| or |th| element
                    ## in scope in the stack of open elements by definition.
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    ## ISSUE: Can this be reached?
                    
                    last;
                  }
                }

                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                    text => $token->{tag_name}, token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } # INSCOPE
            } elsif ($token->{tag_name} eq 'table' and
                     $self->{insertion_mode} == IN_CAPTION_IM) {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'caption',
                              token => $token);

              ## As if </caption>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] & CAPTION_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => 'caption', token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              }
              
              ## generate implied end tags
              while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
                
                pop @{$self->{open_elements}};
              }

              unless ($self->{open_elements}->[-1]->[1] & CAPTION_EL) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                text => $self->{open_elements}->[-1]->[0]
                                    ->manakai_local_name,
                                token => $token);
              } else {
                
              }

              splice @{$self->{open_elements}}, $i;

              $clear_up_to_marker->();

              $self->{insertion_mode} = IN_TABLE_IM;

              ## reprocess
              next B;
            } elsif ({
                      body => 1, col => 1, colgroup => 1, html => 1,
                     }->{$token->{tag_name}}) {
              if ($self->{insertion_mode} & BODY_TABLE_IMS) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } else {
                
                #
              }
            } elsif ({
                      tbody => 1, tfoot => 1,
                      thead => 1, tr => 1,
                     }->{$token->{tag_name}} and
                     $self->{insertion_mode} == IN_CAPTION_IM) {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => $token->{tag_name}, token => $token);
              ## Ignore the token
              $token = $self->_get_next_token;
              next B;
            } else {
              
              #
            }
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        for my $entry (@{$self->{open_elements}}) {
          unless ($entry->[1] & ALL_END_TAG_OPTIONAL_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $token);
            last;
          }
        }

        ## Stop parsing.
        last B;
      } else {
        die "$0: $token->{type}: Unknown token type";
      }

      $insert = $insert_to_current;
      #
    } elsif ($self->{insertion_mode} & TABLE_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if (not $open_tables->[-1]->[1] and # tainted
            $token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
            next B;
          } else {
            
          }
        }

        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table:#text', token => $token);

            ## As if in body, but insert into foster parent element
            ## ISSUE: Spec says that "whenever a node would be inserted
            ## into the current node" while characters might not be
            ## result in a new Text node.
            $reconstruct_active_formatting_elements->($insert_to_foster);
            
            if ($self->{open_elements}->[-1]->[1] & TABLE_ROWS_EL) {
              # MUST
              my $foster_parent_element;
              my $next_sibling;
              my $prev_sibling;
              OE: for (reverse 0..$#{$self->{open_elements}}) {
                if ($self->{open_elements}->[$_]->[1] & TABLE_EL) {
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
          $open_tables->[-1]->[1] = 1; # tainted
        } else {
          
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
        }
            
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ({
             tr => ($self->{insertion_mode} != IN_ROW_IM),
             th => 1, td => 1,
            }->{$token->{tag_name}}) {
          if ($self->{insertion_mode} == IN_TABLE_IM) {
            ## Clear back to table context
            while (not ($self->{open_elements}->[-1]->[1]
                            & TABLE_SCOPING_EL)) {
              
              pop @{$self->{open_elements}};
            }
            
            
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'tbody']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'tbody'} || 0];
    }
  
            $self->{insertion_mode} = IN_TABLE_BODY_IM;
            ## reprocess in the "in table body" insertion mode...
          }
          
          if ($self->{insertion_mode} == IN_TABLE_BODY_IM) {
            unless ($token->{tag_name} eq 'tr') {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'missing start tag:tr', token => $token);
            }
                
            ## Clear back to table body context
            while (not ($self->{open_elements}->[-1]->[1]
                            & TABLE_ROWS_SCOPING_EL)) {
              
              ## ISSUE: Can this case be reached?
              pop @{$self->{open_elements}};
            }
                
                $self->{insertion_mode} = IN_ROW_IM;
                if ($token->{tag_name} eq 'tr') {
                  
                  
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
                  
                  $token = $self->_get_next_token;
                  next B;
                } else {
                  
                  
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'tr']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
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
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
              $self->{insertion_mode} = IN_CELL_IM;

              push @$active_formatting_elements, ['#marker', ''];
              
              
              $token = $self->_get_next_token;
              next B;
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
                  if ($node->[1] & TABLE_ROW_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) { 
                  
## TODO: This type is wrong.
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmacthed end tag',
                                  text => $token->{tag_name}, token => $token);
                  ## Ignore the token
                  
                  $token = $self->_get_next_token;
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
                if ($token->{tag_name} eq 'tr') {
                  
                  ## reprocess
                  
                  next B;
                } else {
                  
                  ## reprocess in the "in table body" insertion mode...
                }
              }

              if ($self->{insertion_mode} == IN_TABLE_BODY_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] & TABLE_ROW_GROUP_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
## TODO: This erorr type is wrong.
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $token->{tag_name}, token => $token);
                  ## Ignore the token
                  
                  $token = $self->_get_next_token;
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

              if ($token->{tag_name} eq 'col') {
                ## Clear back to table context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_SCOPING_EL)) {
                  
                  ## ISSUE: Can this state be reached?
                  pop @{$self->{open_elements}};
                }
                
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'colgroup']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{'colgroup'} || 0];
    }
  
                $self->{insertion_mode} = IN_COLUMN_GROUP_IM;
                ## reprocess
                
                next B;
              } elsif ({
                        caption => 1,
                        colgroup => 1,
                        tbody => 1, tfoot => 1, thead => 1,
                       }->{$token->{tag_name}}) {
                ## Clear back to table context
                while (not ($self->{open_elements}->[-1]->[1]
                                & TABLE_SCOPING_EL)) {
                  
                  ## ISSUE: Can this state be reached?
                  pop @{$self->{open_elements}};
                }
                
                push @$active_formatting_elements, ['#marker', '']
                    if $token->{tag_name} eq 'caption';
                
                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
                $self->{insertion_mode} = {
                                           caption => IN_CAPTION_IM,
                                           colgroup => IN_COLUMN_GROUP_IM,
                                           tbody => IN_TABLE_BODY_IM,
                                           tfoot => IN_TABLE_BODY_IM,
                                           thead => IN_TABLE_BODY_IM,
                                          }->{$token->{tag_name}};
                $token = $self->_get_next_token;
                
                next B;
              } else {
                die "$0: in table: <>: $token->{tag_name}";
              }
            } elsif ($token->{tag_name} eq 'table') {
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $token);

              ## As if </table>
              ## have a table element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] & TABLE_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
## TODO: The following is wrong, maybe.
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag', text => 'table',
                                token => $token);
                ## Ignore tokens </table><table>
                
                $token = $self->_get_next_token;
                next B;
              }
              
## TODO: Followings are removed from the latest spec. 
              ## generate implied end tags
              while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
                
                pop @{$self->{open_elements}};
              }

              unless ($self->{open_elements}->[-1]->[1] & TABLE_EL) {
                
                ## NOTE: |<table><tr><table>|
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                                text => $self->{open_elements}->[-1]->[0]
                                    ->manakai_local_name,
                                token => $token);
              } else {
                
              }

              splice @{$self->{open_elements}}, $i;
              pop @{$open_tables};

              $self->_reset_insertion_mode; 

          ## reprocess
          
          next B;
        } elsif ($token->{tag_name} eq 'style') {
          if (not $open_tables->[-1]->[1]) { # tainted
            
            ## NOTE: This is a "as if in head" code clone.
            $parse_rcdata->(CDATA_CONTENT_MODEL);
            next B;
          } else {
            
            #
          }
        } elsif ($token->{tag_name} eq 'script') {
          if (not $open_tables->[-1]->[1]) { # tainted
            
            ## NOTE: This is a "as if in head" code clone.
            $script_start_tag->();
            next B;
          } else {
            
            #
          }
        } elsif ($token->{tag_name} eq 'input') {
          if (not $open_tables->[-1]->[1]) { # tainted
            if ($token->{attributes}->{type}) { ## TODO: case
              my $type = lc $token->{attributes}->{type}->{value};
              if ($type eq 'hidden') {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table',
                                text => $token->{tag_name}, token => $token);

                
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  

                ## TODO: form element pointer

                pop @{$self->{open_elements}};

                $token = $self->_get_next_token;
                delete $self->{self_closing};
                next B;
              } else {
                
                #
              }
            } else {
              
              #
            }
          } else {
            
            #
          }
        } else {
          
          #
        }

        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table', text => $token->{tag_name},
                        token => $token);

        $insert = $insert_to_foster;
        #
      } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'tr' and
                $self->{insertion_mode} == IN_ROW_IM) {
              ## have an element in table scope
              my $i;
              INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                my $node = $self->{open_elements}->[$_];
                if ($node->[1] & TABLE_ROW_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                
                $token = $self->_get_next_token;
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
              $token = $self->_get_next_token;
              
              next B;
            } elsif ($token->{tag_name} eq 'table') {
              if ($self->{insertion_mode} == IN_ROW_IM) {
                ## As if </tr>
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] & TABLE_ROW_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
## TODO: The following is wrong.
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $token->{type}, token => $token);
                  ## Ignore the token
                  
                  $token = $self->_get_next_token;
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

              if ($self->{insertion_mode} == IN_TABLE_BODY_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] & TABLE_ROW_GROUP_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                unless (defined $i) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                  text => $token->{tag_name}, token => $token);
                  ## Ignore the token
                  
                  $token = $self->_get_next_token;
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
                if ($node->[1] & TABLE_EL) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                
                $token = $self->_get_next_token;
                next B;
              }
                
              splice @{$self->{open_elements}}, $i;
              pop @{$open_tables};
              
              $self->_reset_insertion_mode;
              
              $token = $self->_get_next_token;
              next B;
            } elsif ({
                      tbody => 1, tfoot => 1, thead => 1,
                     }->{$token->{tag_name}} and
                     $self->{insertion_mode} & ROW_IMS) {
              if ($self->{insertion_mode} == IN_ROW_IM) {
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
                    $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                    text => $token->{tag_name}, token => $token);
                    ## Ignore the token
                    
                    $token = $self->_get_next_token;
                    next B;
                  }
                
                ## As if </tr>
                ## have an element in table scope
                my $i;
                INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
                  my $node = $self->{open_elements}->[$_];
                  if ($node->[1] & TABLE_ROW_EL) {
                    
                    $i = $_;
                    last INSCOPE;
                  } elsif ($node->[1] & TABLE_SCOPING_EL) {
                    
                    last INSCOPE;
                  }
                } # INSCOPE
                  unless (defined $i) {
                    
                    $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                    text => 'tr', token => $token);
                    ## Ignore the token
                    
                    $token = $self->_get_next_token;
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
                if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
                  
                  $i = $_;
                  last INSCOPE;
                } elsif ($node->[1] & TABLE_SCOPING_EL) {
                  
                  last INSCOPE;
                }
              } # INSCOPE
              unless (defined $i) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => $token->{tag_name}, token => $token);
                ## Ignore the token
                
                $token = $self->_get_next_token;
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
              
              $token = $self->_get_next_token;
              next B;
            } elsif ({
                      body => 1, caption => 1, col => 1, colgroup => 1,
                      html => 1, td => 1, th => 1,
                      tr => 1, # $self->{insertion_mode} == IN_ROW_IM
                      tbody => 1, tfoot => 1, thead => 1, # $self->{insertion_mode} == IN_TABLE_IM
                     }->{$token->{tag_name}}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);
          ## Ignore the token
          
           $token = $self->_get_next_token;
          next B;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in table:/',
                          text => $token->{tag_name}, token => $token);

          $insert = $insert_to_foster;
          #
        }
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        unless ($self->{open_elements}->[-1]->[1] & HTML_EL and
                @{$self->{open_elements}} == 1) { # redundant, maybe
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $token);
          
          #
        } else {
          
          #
        }

        ## Stop parsing
        last B;
      } else {
        die "$0: $token->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} == IN_COLUMN_GROUP_IM) {
          if ($token->{type} == CHARACTER_TOKEN) {
            if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
              $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
              unless (length $token->{data}) {
                
                $token = $self->_get_next_token;
                next B;
              }
            }
            
            
            #
          } elsif ($token->{type} == START_TAG_TOKEN) {
            if ($token->{tag_name} eq 'col') {
              
              
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
              pop @{$self->{open_elements}};
              delete $self->{self_closing};
              $token = $self->_get_next_token;
              next B;
            } else { 
              
              #
            }
          } elsif ($token->{type} == END_TAG_TOKEN) {
            if ($token->{tag_name} eq 'colgroup') {
              if ($self->{open_elements}->[-1]->[1] & HTML_EL) {
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                                text => 'colgroup', token => $token);
                ## Ignore the token
                $token = $self->_get_next_token;
                next B;
              } else {
                
                pop @{$self->{open_elements}}; # colgroup
                $self->{insertion_mode} = IN_TABLE_IM;
                $token = $self->_get_next_token;
                next B;             
              }
            } elsif ($token->{tag_name} eq 'col') {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => 'col', token => $token);
              ## Ignore the token
              $token = $self->_get_next_token;
              next B;
            } else {
              
              # 
            }
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        if ($self->{open_elements}->[-1]->[1] & HTML_EL and
            @{$self->{open_elements}} == 1) { # redundant, maybe
          
          ## Stop parsing.
          last B;
        } else {
          ## NOTE: As if </colgroup>.
          
          pop @{$self->{open_elements}}; # colgroup
          $self->{insertion_mode} = IN_TABLE_IM;
          ## Reprocess.
          next B;
        }
      } else {
        die "$0: $token->{type}: Unknown token type";
      }

          ## As if </colgroup>
          if ($self->{open_elements}->[-1]->[1] & HTML_EL) {
            
## TODO: Wrong error type?
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => 'colgroup', token => $token);
            ## Ignore the token
            
            $token = $self->_get_next_token;
            next B;
          } else {
            
            pop @{$self->{open_elements}}; # colgroup
            $self->{insertion_mode} = IN_TABLE_IM;
            
            ## reprocess
            next B;
          }
    } elsif ($self->{insertion_mode} & SELECT_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        
        $self->{open_elements}->[-1]->[0]->manakai_append_text ($token->{data});
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($token->{tag_name} eq 'option') {
          if ($self->{open_elements}->[-1]->[1] & OPTION_EL) {
            
            ## As if </option>
            pop @{$self->{open_elements}};
          } else {
            
          }

          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
          
          $token = $self->_get_next_token;
          next B;
        } elsif ($token->{tag_name} eq 'optgroup') {
          if ($self->{open_elements}->[-1]->[1] & OPTION_EL) {
            
            ## As if </option>
            pop @{$self->{open_elements}};
          } else {
            
          }

          if ($self->{open_elements}->[-1]->[1] & OPTGROUP_EL) {
            
            ## As if </optgroup>
            pop @{$self->{open_elements}};
          } else {
            
          }

          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
          
          $token = $self->_get_next_token;
          next B;
        } elsif ({
                   select => 1, input => 1, textarea => 1,
                 }->{$token->{tag_name}} or
                 ($self->{insertion_mode} == IN_SELECT_IN_TABLE_IM and
                  {
                   caption => 1, table => 1,
                   tbody => 1, tfoot => 1, thead => 1,
                   tr => 1, td => 1, th => 1,
                  }->{$token->{tag_name}})) {
          ## TODO: The type below is not good - <select> is replaced by </select>
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed', text => 'select',
                          token => $token);
          ## NOTE: As if the token were </select> (<select> case) or
          ## as if there were </select> (otherwise).
          ## have an element in table scope
          my $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[1] & SELECT_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] & TABLE_SCOPING_EL) {
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => 'select', token => $token);
            ## Ignore the token
            
            $token = $self->_get_next_token;
            next B;
          }
              
          
          splice @{$self->{open_elements}}, $i;

          $self->_reset_insertion_mode;

          if ($token->{tag_name} eq 'select') {
            
            $token = $self->_get_next_token;
            next B;
          } else {
            
            
            ## Reprocess the token.
            next B;
          }
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in select',
                          text => $token->{tag_name}, token => $token);
          ## Ignore the token
          
          $token = $self->_get_next_token;
          next B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($token->{tag_name} eq 'optgroup') {
          if ($self->{open_elements}->[-1]->[1] & OPTION_EL and
              $self->{open_elements}->[-2]->[1] & OPTGROUP_EL) {
            
            ## As if </option>
            splice @{$self->{open_elements}}, -2;
          } elsif ($self->{open_elements}->[-1]->[1] & OPTGROUP_EL) {
            
            pop @{$self->{open_elements}};
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $token->{tag_name}, token => $token);
            ## Ignore the token
          }
          
          $token = $self->_get_next_token;
          next B;
        } elsif ($token->{tag_name} eq 'option') {
          if ($self->{open_elements}->[-1]->[1] & OPTION_EL) {
            
            pop @{$self->{open_elements}};
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $token->{tag_name}, token => $token);
            ## Ignore the token
          }
          
          $token = $self->_get_next_token;
          next B;
        } elsif ($token->{tag_name} eq 'select') {
          ## have an element in table scope
          my $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[1] & SELECT_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] & TABLE_SCOPING_EL) {
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $token->{tag_name}, token => $token);
            ## Ignore the token
            
            $token = $self->_get_next_token;
            next B;
          }
              
          
          splice @{$self->{open_elements}}, $i;

          $self->_reset_insertion_mode;

          
          $token = $self->_get_next_token;
          next B;
        } elsif ($self->{insertion_mode} == IN_SELECT_IN_TABLE_IM and
                 {
                  caption => 1, table => 1, tbody => 1,
                  tfoot => 1, thead => 1, tr => 1, td => 1, th => 1,
                 }->{$token->{tag_name}}) {
## TODO: The following is wrong?
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);
              
          ## have an element in table scope
          my $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] & TABLE_SCOPING_EL) {
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            
            ## Ignore the token
            
            $token = $self->_get_next_token;
            next B;
          }
              
          ## As if </select>
          ## have an element in table scope
          undef $i;
          INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
            my $node = $self->{open_elements}->[$_];
            if ($node->[1] & SELECT_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($node->[1] & TABLE_SCOPING_EL) {
## ISSUE: Can this state be reached?
              
              last INSCOPE;
            }
          } # INSCOPE
          unless (defined $i) {
            
## TODO: The following error type is correct?
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => 'select', token => $token);
            ## Ignore the </select> token
            
            $token = $self->_get_next_token; ## TODO: ok?
            next B;
          }
              
          
          splice @{$self->{open_elements}}, $i;

          $self->_reset_insertion_mode;

          
          ## reprocess
          next B;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in select:/',
                          text => $token->{tag_name}, token => $token);
          ## Ignore the token
          
          $token = $self->_get_next_token;
          next B;
        }
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        unless ($self->{open_elements}->[-1]->[1] & HTML_EL and
                @{$self->{open_elements}} == 1) { # redundant, maybe
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $token);
        } else {
          
        }

        ## Stop parsing.
        last B;
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
            next B;
          }
        }
        
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html:#text', token => $token);

          ## Reprocess in the "after body" insertion mode.
        } else {
          
        }
        
        ## "after body" insertion mode
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after body:#text', token => $token);

        $self->{insertion_mode} = IN_BODY_IM;
        ## reprocess
        next B;
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html',
                          text => $token->{tag_name}, token => $token);
          
          ## Reprocess in the "after body" insertion mode.
        } else {
          
        }

        ## "after body" insertion mode
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after body',
                        text => $token->{tag_name}, token => $token);

        $self->{insertion_mode} = IN_BODY_IM;
        
        ## reprocess
        next B;
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($self->{insertion_mode} == AFTER_HTML_BODY_IM) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html:/',
                          text => $token->{tag_name}, token => $token);
          
          $self->{insertion_mode} = AFTER_BODY_IM;
          ## Reprocess in the "after body" insertion mode.
        } else {
          
        }

        ## "after body" insertion mode
        if ($token->{tag_name} eq 'html') {
          if (defined $self->{inner_html_node}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => 'html', token => $token);
            ## Ignore the token
            $token = $self->_get_next_token;
            next B;
          } else {
            
            $self->{insertion_mode} = AFTER_HTML_BODY_IM;
            $token = $self->_get_next_token;
            next B;
          }
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'after body:/',
                          text => $token->{tag_name}, token => $token);

          $self->{insertion_mode} = IN_BODY_IM;
          ## reprocess
          next B;
        }
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        
        ## Stop parsing
        last B;
      } else {
        die "$0: $token->{type}: Unknown token type";
      }
    } elsif ($self->{insertion_mode} & FRAME_IMS) {
      if ($token->{type} == CHARACTER_TOKEN) {
        if ($token->{data} =~ s/^([\x09\x0A\x0B\x0C\x20]+)//) {
          $self->{open_elements}->[-1]->[0]->manakai_append_text ($1);
          
          unless (length $token->{data}) {
            
            $token = $self->_get_next_token;
            next B;
          }
        }
        
        if ($token->{data} =~ s/^[^\x09\x0A\x0B\x0C\x20]+//) {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in frameset:#text', token => $token);
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after frameset:#text', token => $token);
          } else { # "after after frameset"
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after html:#text', token => $token);
          }
          
          ## Ignore the token.
          if (length $token->{data}) {
            
            ## reprocess the rest of characters
          } else {
            
            $token = $self->_get_next_token;
          }
          next B;
        }
        
        die qq[$0: Character "$token->{data}"];
      } elsif ($token->{type} == START_TAG_TOKEN) {
        if ($token->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
          
          $token = $self->_get_next_token;
          next B;
        } elsif ($token->{tag_name} eq 'frame' and
                 $self->{insertion_mode} == IN_FRAMESET_IM) {
          
          
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $self->{open_elements}->[-1]->[0]->append_child ($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
          pop @{$self->{open_elements}};
          delete $self->{self_closing};
          $token = $self->_get_next_token;
          next B;
        } elsif ($token->{tag_name} eq 'noframes') {
          
          ## NOTE: As if in head.
          $parse_rcdata->(CDATA_CONTENT_MODEL);
          next B;

          ## NOTE: |<!DOCTYPE HTML><frameset></frameset></html><noframes></noframes>|
          ## has no parse error.
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in frameset',
                            text => $token->{tag_name}, token => $token);
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after frameset',
                            text => $token->{tag_name}, token => $token);
          } else { # "after after frameset"
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after after frameset',
                            text => $token->{tag_name}, token => $token);
          }
          ## Ignore the token
          
          $token = $self->_get_next_token;
          next B;
        }
      } elsif ($token->{type} == END_TAG_TOKEN) {
        if ($token->{tag_name} eq 'frameset' and
            $self->{insertion_mode} == IN_FRAMESET_IM) {
          if ($self->{open_elements}->[-1]->[1] & HTML_EL and
              @{$self->{open_elements}} == 1) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $token->{tag_name}, token => $token);
            ## Ignore the token
            $token = $self->_get_next_token;
          } else {
            
            pop @{$self->{open_elements}};
            $token = $self->_get_next_token;
          }

          if (not defined $self->{inner_html_node} and
              not ($self->{open_elements}->[-1]->[1] & FRAMESET_EL)) {
            
            $self->{insertion_mode} = AFTER_FRAMESET_IM;
          } else {
            
          }
          next B;
        } elsif ($token->{tag_name} eq 'html' and
                 $self->{insertion_mode} == AFTER_FRAMESET_IM) {
          
          $self->{insertion_mode} = AFTER_HTML_FRAMESET_IM;
          $token = $self->_get_next_token;
          next B;
        } else {
          if ($self->{insertion_mode} == IN_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in frameset:/',
                            text => $token->{tag_name}, token => $token);
          } elsif ($self->{insertion_mode} == AFTER_FRAMESET_IM) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after frameset:/',
                            text => $token->{tag_name}, token => $token);
          } else { # "after after html"
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'after after frameset:/',
                            text => $token->{tag_name}, token => $token);
          }
          ## Ignore the token
          $token = $self->_get_next_token;
          next B;
        }
      } elsif ($token->{type} == END_OF_FILE_TOKEN) {
        unless ($self->{open_elements}->[-1]->[1] & HTML_EL and
                @{$self->{open_elements}} == 1) { # redundant, maybe
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body:#eof', token => $token);
        } else {
          
        }
        
        ## Stop parsing
        last B;
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
        $script_start_tag->();
        next B;
      } elsif ($token->{tag_name} eq 'style') {
        
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->(CDATA_CONTENT_MODEL);
        next B;
      } elsif ({
                base => 1, link => 1,
               }->{$token->{tag_name}}) {
        
        ## NOTE: This is an "as if in head" code clone, only "-t" differs
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
        pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.
        delete $self->{self_closing};
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'meta') {
        ## NOTE: This is an "as if in head" code clone, only "-t" differs
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
        my $meta_el = pop @{$self->{open_elements}}; ## ISSUE: This step is missing in the spec.

        unless ($self->{confident}) {
          if ($token->{attributes}->{charset}) {
            
            ## NOTE: Whether the encoding is supported or not is handled
            ## in the {change_encoding} callback.
            $self->{change_encoding}
                ->($self, $token->{attributes}->{charset}->{value}, $token);
            
            $meta_el->[0]->get_attribute_node_ns (undef, 'charset')
                ->set_user_data (manakai_has_reference =>
                                     $token->{attributes}->{charset}
                                         ->{has_reference});
          } elsif ($token->{attributes}->{content}) {
            if ($token->{attributes}->{content}->{value}
                =~ /[Cc][Hh][Aa][Rr][Ss][Ee][Tt]
                    [\x09-\x0D\x20]*=
                    [\x09-\x0D\x20]*(?>"([^"]*)"|'([^']*)'|
                    ([^"'\x09-\x0D\x20][^\x09-\x0D\x20\x3B]*))/x) {
              
              ## NOTE: Whether the encoding is supported or not is handled
              ## in the {change_encoding} callback.
              $self->{change_encoding}
                  ->($self, defined $1 ? $1 : defined $2 ? $2 : $3, $token);
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

        delete $self->{self_closing};
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'title') {
        
        ## NOTE: This is an "as if in head" code clone
        $parse_rcdata->(RCDATA_CONTENT_MODEL);
        next B;
      } elsif ($token->{tag_name} eq 'body') {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body', text => 'body', token => $token);
              
        if (@{$self->{open_elements}} == 1 or
            not ($self->{open_elements}->[1]->[1] & BODY_EL)) {
          
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
        next B;
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1, 
                div => 1, dl => 1, fieldset => 1,
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
                menu => 1, ol => 1, p => 1, ul => 1,
                pre => 1, listing => 1,
                form => 1,
                table => 1,
                hr => 1,
               }->{$token->{tag_name}}) {
        if ($token->{tag_name} eq 'form' and defined $self->{form_element}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in form:form', token => $token);
          ## Ignore the token
          
          $token = $self->_get_next_token;
          next B;
        }

        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] & P_EL) {
            
            
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <form>
            $token = {type => END_TAG_TOKEN, tag_name => 'p',
                      line => $token->{line}, column => $token->{column}};
            next B;
          } elsif ($_->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
        if ($token->{tag_name} eq 'pre' or $token->{tag_name} eq 'listing') {
          
          $token = $self->_get_next_token;
          if ($token->{type} == CHARACTER_TOKEN) {
            $token->{data} =~ s/^\x0A//;
            unless (length $token->{data}) {
              
              $token = $self->_get_next_token;
            } else {
              
            }
          } else {
            
          }
        } elsif ($token->{tag_name} eq 'form') {
          
          $self->{form_element} = $self->{open_elements}->[-1]->[0];

          
          $token = $self->_get_next_token;
        } elsif ($token->{tag_name} eq 'table') {
          
          push @{$open_tables}, [$self->{open_elements}->[-1]->[0]];
          
          $self->{insertion_mode} = IN_TABLE_IM;

          
          $token = $self->_get_next_token;
        } elsif ($token->{tag_name} eq 'hr') {
          
          pop @{$self->{open_elements}};
        
          
          $token = $self->_get_next_token;
        } else {
          
          $token = $self->_get_next_token;
        }
        next B;
      } elsif ({li => 1, dt => 1, dd => 1}->{$token->{tag_name}}) {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] & P_EL) {
            
            
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <x>
            $token = {type => END_TAG_TOKEN, tag_name => 'p',
                      line => $token->{line}, column => $token->{column}};
            next B;
          } elsif ($_->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
          
        ## Step 1
        my $i = -1;
        my $node = $self->{open_elements}->[$i];
        my $li_or_dtdd = {li => {li => 1},
                          dt => {dt => 1, dd => 1},
                          dd => {dt => 1, dd => 1}}->{$token->{tag_name}};
        LI: {
          ## Step 2
          if ($li_or_dtdd->{$node->[0]->manakai_local_name}) {
            if ($i != -1) {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $token);
            } else {
              
            }
            splice @{$self->{open_elements}}, $i;
            last LI;
          } else {
            
          }
          
          ## Step 3
          if (not ($node->[1] & FORMATTING_EL) and
              #not $phrasing_category->{$node->[1]} and
              ($node->[1] & SPECIAL_EL or
               $node->[1] & SCOPING_EL) and
              not ($node->[1] & ADDRESS_EL) and
              not ($node->[1] & DIV_EL)) {
            
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
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
        
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'plaintext') {
        ## has a p element in scope
        INSCOPE: for (reverse @{$self->{open_elements}}) {
          if ($_->[1] & P_EL) {
            
            
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <plaintext>
            $token = {type => END_TAG_TOKEN, tag_name => 'p',
                      line => $token->{line}, column => $token->{column}};
            next B;
          } elsif ($_->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
          
        $self->{content_model} = PLAINTEXT_CONTENT_MODEL;
          
        
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'a') {
        AFE: for my $i (reverse 0..$#$active_formatting_elements) {
          my $node = $active_formatting_elements->[$i];
          if ($node->[1] & A_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in a:a', token => $token);
            
            
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <a>
            $token = {type => END_TAG_TOKEN, tag_name => 'a',
                      line => $token->{line}, column => $token->{column}};
            $formatting_end_tag->($token);
            
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
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
        push @$active_formatting_elements, $self->{open_elements}->[-1];

        
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'nobr') {
        $reconstruct_active_formatting_elements->($insert_to_current);

        ## has a |nobr| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & NOBR_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in nobr:nobr', token => $token);
            
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <nobr>
            $token = {type => END_TAG_TOKEN, tag_name => 'nobr',
                      line => $token->{line}, column => $token->{column}};
            next B;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  
        push @$active_formatting_elements, $self->{open_elements}->[-1];
        
        
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'button') {
        ## has a button element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & BUTTON_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'in button:button', token => $token);
            
      $token->{self_closing} = $self->{self_closing};
      unshift @{$self->{token}}, $token;
      delete $self->{self_closing};
     # <button>
            $token = {type => END_TAG_TOKEN, tag_name => 'button',
                      line => $token->{line}, column => $token->{column}};
            next B;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE
          
        $reconstruct_active_formatting_elements->($insert_to_current);
          
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  

        ## TODO: associate with $self->{form_element} if defined

        push @$active_formatting_elements, ['#marker', ''];

        
        $token = $self->_get_next_token;
        next B;
      } elsif ({
                xmp => 1,
                iframe => 1,
                noembed => 1,
                noframes => 1, ## NOTE: This is an "as if in head" code clone.
                noscript => 0, ## TODO: 1 if scripting is enabled
               }->{$token->{tag_name}}) {
        if ($token->{tag_name} eq 'xmp') {
          
          $reconstruct_active_formatting_elements->($insert_to_current);
        } else {
          
        }
        ## NOTE: There is an "as if in body" code clone.
        $parse_rcdata->(CDATA_CONTENT_MODEL);
        next B;
      } elsif ($token->{tag_name} eq 'isindex') {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'isindex', token => $token);
        
        if (defined $self->{form_element}) {
          
          ## Ignore the token
           ## NOTE: Not acknowledged.
          $token = $self->_get_next_token;
          next B;
        } else {
          delete $self->{self_closing};

          my $at = $token->{attributes};
          my $form_attrs;
          $form_attrs->{action} = $at->{action} if $at->{action};
          my $prompt_attr = $at->{prompt};
          $at->{name} = {name => 'name', value => 'isindex'};
          delete $at->{action};
          delete $at->{prompt};
          my @tokens = (
                        {type => START_TAG_TOKEN, tag_name => 'form',
                         attributes => $form_attrs,
                         line => $token->{line}, column => $token->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'hr',
                         line => $token->{line}, column => $token->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'p',
                         line => $token->{line}, column => $token->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'label',
                         line => $token->{line}, column => $token->{column}},
                       );
          if ($prompt_attr) {
            
            push @tokens, {type => CHARACTER_TOKEN, data => $prompt_attr->{value},
                           #line => $token->{line}, column => $token->{column},
                          };
          } else {
            
            push @tokens, {type => CHARACTER_TOKEN,
                           data => 'This is a searchable index. Insert your search keywords here: ',
                           #line => $token->{line}, column => $token->{column},
                          }; # SHOULD
            ## TODO: make this configurable
          }
          push @tokens,
                        {type => START_TAG_TOKEN, tag_name => 'input', attributes => $at,
                         line => $token->{line}, column => $token->{column}},
                        #{type => CHARACTER_TOKEN, data => ''}, # SHOULD
                        {type => END_TAG_TOKEN, tag_name => 'label',
                         line => $token->{line}, column => $token->{column}},
                        {type => END_TAG_TOKEN, tag_name => 'p',
                         line => $token->{line}, column => $token->{column}},
                        {type => START_TAG_TOKEN, tag_name => 'hr',
                         line => $token->{line}, column => $token->{column}},
                        {type => END_TAG_TOKEN, tag_name => 'form',
                         line => $token->{line}, column => $token->{column}};
          unshift @{$self->{token}}, (@tokens);
          $token = $self->_get_next_token;
          next B;
        }
      } elsif ($token->{tag_name} eq 'textarea') {
        my $tag_name = $token->{tag_name};
        my $el;
        
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{ $token->{attributes}}) {
          my $attr_t =  $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
        
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
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'in RCDATA:#eof', token => $token);
        }
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'rt' or
               $token->{tag_name} eq 'rp') {
        ## has a |ruby| element in scope
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & RUBY_EL) {
            
            ## generate implied end tags
            while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
              
              pop @{$self->{open_elements}};
            }
            unless ($self->{open_elements}->[-1]->[1] & RUBY_EL) {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $token);
              pop @{$self->{open_elements}}
                  while not $self->{open_elements}->[-1]->[1] & RUBY_EL;
            }
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  

        
        $token = $self->_get_next_token;
        redo B;
      } elsif ($token->{tag_name} eq 'math' or
               $token->{tag_name} eq 'svg') {
        $reconstruct_active_formatting_elements->($insert_to_current);

        ## "Adjust MathML attributes" ('math' only) - done in insert-element-f

        ## "adjust SVG attributes" ('svg' only) - done in insert-element-f

        ## "adjust foreign attributes" - done in insert-element-f
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($token->{tag_name} eq 'math' ? $MML_NS : $SVG_NS, [undef,   $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (
          @{
            $foreign_attr_xname->{$attr_name} ||
            [undef, [undef,
                     ($token->{tag_name} eq 'math' ? $MML_NS : $SVG_NS) eq $SVG_NS ?
                         ($svg_attr_name->{$attr_name} || $attr_name) :
                     ($token->{tag_name} eq 'math' ? $MML_NS : $SVG_NS) eq $MML_NS ?
                         ($attr_name eq 'definitionurl' ?
                             'definitionURL' : $attr_name) :
                         $attr_name]]
          }
        );
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, ($el_category_f->{$token->{tag_name} eq 'math' ? $MML_NS : $SVG_NS}->{ $token->{tag_name}} || 0) | FOREIGN_EL];

      if ( $token->{attributes}->{xmlns} and  $token->{attributes}->{xmlns}->{value} ne ($token->{tag_name} eq 'math' ? $MML_NS : $SVG_NS)) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad namespace', token =>  $token);
## TODO: Error type documentation
      }
    }
  
        
        if ($self->{self_closing}) {
          pop @{$self->{open_elements}};
          delete $self->{self_closing};
        } else {
          
          $self->{insertion_mode} |= IN_FOREIGN_CONTENT_IM;
          ## NOTE: |<body><math><mi><svg>| -> "in foreign content" insertion
          ## mode, "in body" (not "in foreign content") secondary insertion
          ## mode, maybe.
        }

        $token = $self->_get_next_token;
        next B;
      } elsif ({
                caption => 1, col => 1, colgroup => 1, frame => 1,
                frameset => 1, head => 1, option => 1, optgroup => 1,
                tbody => 1, td => 1, tfoot => 1, th => 1,
                thead => 1, tr => 1,
               }->{$token->{tag_name}}) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'in body',
                        text => $token->{tag_name}, token => $token);
        ## Ignore the token
         ## NOTE: |<col/>| or |<frame/>| here is an error.
        $token = $self->_get_next_token;
        next B;
        
        ## ISSUE: An issue on HTML5 new elements in the spec.
      } else {
        if ($token->{tag_name} eq 'image') {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'image', token => $token);
          $token->{tag_name} = 'img';
        } else {
          
        }

        ## NOTE: There is an "as if <br>" code clone.
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        
    {
      my $el;
      
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  $token->{tag_name}]);
    
        for my $attr_name (keys %{  $token->{attributes}}) {
          my $attr_t =   $token->{attributes}->{$attr_name};
          my $attr = $self->{document}->create_attribute_ns (undef, [undef, $attr_name]);
          $attr->value ($attr_t->{value});
          $attr->set_user_data (manakai_source_line => $attr_t->{line});
          $attr->set_user_data (manakai_source_column => $attr_t->{column});
          $el->set_attribute_node_ns ($attr);
        }
      
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
      $insert->($el);
      push @{$self->{open_elements}}, [$el, $el_category->{$token->{tag_name}} || 0];
    }
  

        if ({
             applet => 1, marquee => 1, object => 1,
            }->{$token->{tag_name}}) {
          
          push @$active_formatting_elements, ['#marker', ''];
          
        } elsif ({
                  b => 1, big => 1, em => 1, font => 1, i => 1,
                  s => 1, small => 1, strile => 1,
                  strong => 1, tt => 1, u => 1,
                 }->{$token->{tag_name}}) {
          
          push @$active_formatting_elements, $self->{open_elements}->[-1];
          
        } elsif ($token->{tag_name} eq 'input') {
          
          ## TODO: associate with $self->{form_element} if defined
          pop @{$self->{open_elements}};
          delete $self->{self_closing};
        } elsif ({
                  area => 1, basefont => 1, bgsound => 1, br => 1,
                  embed => 1, img => 1, param => 1, spacer => 1, wbr => 1,
                  #image => 1,
                 }->{$token->{tag_name}}) {
          
          pop @{$self->{open_elements}};
          delete $self->{self_closing};
        } elsif ($token->{tag_name} eq 'select') {
          ## TODO: associate with $self->{form_element} if defined
        
          if ($self->{insertion_mode} & TABLE_IMS or
              $self->{insertion_mode} & BODY_TABLE_IMS or
              $self->{insertion_mode} == IN_COLUMN_GROUP_IM) {
            
            $self->{insertion_mode} = IN_SELECT_IN_TABLE_IM;
          } else {
            
            $self->{insertion_mode} = IN_SELECT_IM;
          }
          
        } else {
          
        }
        
        $token = $self->_get_next_token;
        next B;
      }
    } elsif ($token->{type} == END_TAG_TOKEN) {
      if ($token->{tag_name} eq 'body') {
        ## has a |body| element in scope
        my $i;
        INSCOPE: {
          for (reverse @{$self->{open_elements}}) {
            if ($_->[1] & BODY_EL) {
              
              $i = $_;
              last INSCOPE;
            } elsif ($_->[1] & SCOPING_EL) {
              
              last;
            }
          }

          $self->{parse_error}->(level => $self->{level}->{must}, type => 'start tag not allowed',
                          text => $token->{tag_name}, token => $token);
          ## NOTE: Ignore the token.
          $token = $self->_get_next_token;
          next B;
        } # INSCOPE

        for (@{$self->{open_elements}}) {
          unless ($_->[1] & ALL_END_TAG_OPTIONAL_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $_->[0]->manakai_local_name,
                            token => $token);
            last;
          } else {
            
          }
        }

        $self->{insertion_mode} = AFTER_BODY_IM;
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'html') {
        ## TODO: Update this code.  It seems that the code below is not
        ## up-to-date, though it has same effect as speced.
        if (@{$self->{open_elements}} > 1 and
            $self->{open_elements}->[1]->[1] & BODY_EL) {
          ## ISSUE: There is an issue in the spec.
          unless ($self->{open_elements}->[-1]->[1] & BODY_EL) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[1]->[0]
                                ->manakai_local_name,
                            token => $token);
          } else {
            
          }
          $self->{insertion_mode} = AFTER_BODY_IM;
          ## reprocess
          next B;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);
          ## Ignore the token
          $token = $self->_get_next_token;
          next B;
        }
      } elsif ({
                address => 1, blockquote => 1, center => 1, dir => 1,
                div => 1, dl => 1, fieldset => 1, listing => 1,
                menu => 1, ol => 1, pre => 1, ul => 1,
                dd => 1, dt => 1, li => 1,
                applet => 1, button => 1, marquee => 1, object => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);
          ## NOTE: Ignore the token.
        } else {
          ## Step 1. generate implied end tags
          while ({
                  ## END_TAG_OPTIONAL_EL
                  dd => ($token->{tag_name} ne 'dd'),
                  dt => ($token->{tag_name} ne 'dt'),
                  li => ($token->{tag_name} ne 'li'),
                  p => 1,
                  rt => 1,
                  rp => 1,
                 }->{$self->{open_elements}->[-1]->[0]->manakai_local_name}) {
            
            pop @{$self->{open_elements}};
          }

          ## Step 2.
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $token->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[-1]->[0]
                                ->manakai_local_name,
                            token => $token);
          } else {
            
          }

          ## Step 3.
          splice @{$self->{open_elements}}, $i;

          ## Step 4.
          $clear_up_to_marker->()
              if {
                applet => 1, button => 1, marquee => 1, object => 1,
              }->{$token->{tag_name}};
        }
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'form') {
        undef $self->{form_element};

        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & FORM_EL) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);
          ## NOTE: Ignore the token.
        } else {
          ## Step 1. generate implied end tags
          while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
            
            pop @{$self->{open_elements}};
          }
          
          ## Step 2. 
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $token->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[-1]->[0]
                                ->manakai_local_name,
                            token => $token);
          } else {
            
          }  
          
          ## Step 3.
          splice @{$self->{open_elements}}, $i;
        }

        $token = $self->_get_next_token;
        next B;
      } elsif ({
                h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1, h6 => 1,
               }->{$token->{tag_name}}) {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & HEADING_EL) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        unless (defined $i) { # has an element in scope
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);
          ## NOTE: Ignore the token.
        } else {
          ## Step 1. generate implied end tags
          while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
            
            pop @{$self->{open_elements}};
          }
          
          ## Step 2.
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $token->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                            text => $token->{tag_name}, token => $token);
          } else {
            
          }

          ## Step 3.
          splice @{$self->{open_elements}}, $i;
        }
        
        $token = $self->_get_next_token;
        next B;
      } elsif ($token->{tag_name} eq 'p') {
        ## has an element in scope
        my $i;
        INSCOPE: for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & P_EL) {
            
            $i = $_;
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            
            last INSCOPE;
          }
        } # INSCOPE

        if (defined $i) {
          if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                  ne $token->{tag_name}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                            text => $self->{open_elements}->[-1]->[0]
                                ->manakai_local_name,
                            token => $token);
          } else {
            
          }

          splice @{$self->{open_elements}}, $i;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                          text => $token->{tag_name}, token => $token);

          
          ## As if <p>, then reprocess the current token
          my $el;
          
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'p']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
          $insert->($el);
          ## NOTE: Not inserted into |$self->{open_elements}|.
        }

        $token = $self->_get_next_token;
        next B;
      } elsif ({
                a => 1,
                b => 1, big => 1, em => 1, font => 1, i => 1,
                nobr => 1, s => 1, small => 1, strile => 1,
                strong => 1, tt => 1, u => 1,
               }->{$token->{tag_name}}) {
        
        $formatting_end_tag->($token);
        next B;
      } elsif ($token->{tag_name} eq 'br') {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => 'br', token => $token);

        ## As if <br>
        $reconstruct_active_formatting_elements->($insert_to_current);
        
        my $el;
        
      $el = $self->{document}->create_element_ns
        ($HTML_NS, [undef,  'br']);
    
        $el->set_user_data (manakai_source_line => $token->{line})
            if defined $token->{line};
        $el->set_user_data (manakai_source_column => $token->{column})
            if defined $token->{column};
      
        $insert->($el);
        
        ## Ignore the token.
        $token = $self->_get_next_token;
        next B;
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
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                        text => $token->{tag_name}, token => $token);
        ## Ignore the token
        $token = $self->_get_next_token;
        next B;
        
        ## ISSUE: Issue on HTML5 new elements in spec
        
      } else {
        ## Step 1
        my $node_i = -1;
        my $node = $self->{open_elements}->[$node_i];

        ## Step 2
        S2: {
          if ($node->[0]->manakai_local_name eq $token->{tag_name}) {
            ## Step 1
            ## generate implied end tags
            while ($self->{open_elements}->[-1]->[1] & END_TAG_OPTIONAL_EL) {
              
              ## NOTE: |<ruby><rt></ruby>|.
              ## ISSUE: <ruby><rt></rt> will also take this code path,
              ## which seems wrong.
              pop @{$self->{open_elements}};
              $node_i++;
            }
        
            ## Step 2
            if ($self->{open_elements}->[-1]->[0]->manakai_local_name
                    ne $token->{tag_name}) {
              
              ## NOTE: <x><y></x>
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'not closed',
                              text => $self->{open_elements}->[-1]->[0]
                                  ->manakai_local_name,
                              token => $token);
            } else {
              
            }
            
            ## Step 3
            splice @{$self->{open_elements}}, $node_i if $node_i < 0;

            $token = $self->_get_next_token;
            last S2;
          } else {
            ## Step 3
            if (not ($node->[1] & FORMATTING_EL) and
                #not $phrasing_category->{$node->[1]} and
                ($node->[1] & SPECIAL_EL or
                 $node->[1] & SCOPING_EL)) {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'unmatched end tag',
                              text => $token->{tag_name}, token => $token);
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
	next B;
      }
    }
    next B;
  } continue { # B
    if ($self->{insertion_mode} & IN_FOREIGN_CONTENT_IM) {
      ## NOTE: The code below is executed in cases where it does not have
      ## to be, but it it is harmless even in those cases.
      ## has an element in scope
      INSCOPE: {
        for (reverse 0..$#{$self->{open_elements}}) {
          my $node = $self->{open_elements}->[$_];
          if ($node->[1] & FOREIGN_EL) {
            last INSCOPE;
          } elsif ($node->[1] & SCOPING_EL) {
            last;
          }
        }
        
        ## NOTE: No foreign element in scope.
        $self->{insertion_mode} &= ~ IN_FOREIGN_CONTENT_IM;
      } # INSCOPE
    }
  } # B

  ## Stop parsing # MUST
  
  ## TODO: script stuffs
} # _tree_construct_main

sub set_inner_html ($$$$;$) {
  my $class = shift;
  my $node = shift;
  #my $s = \$_[0];
  my $onerror = $_[1];
  my $get_wrapper = $_[2] || sub ($) { return $_[0] };

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
    $class->parse_char_string ($_[0] => $node, $onerror, $get_wrapper);
  } elsif ($nt == 1) {
    ## TODO: If non-html element

    ## NOTE: Most of this code is copied from |parse_string|

## TODO: Support for $get_wrapper

    ## Step 1 # MUST
    my $this_doc = $node->owner_document;
    my $doc = $this_doc->implementation->create_document;
    $doc->manakai_is_html (1);
    my $p = $class->new;
    $p->{document} = $doc;

    ## Step 8 # MUST
    my $i = 0;
    $p->{line_prev} = $p->{line} = 1;
    $p->{column_prev} = $p->{column} = 0;
    require Whatpm::Charset::DecodeHandle;
    my $input = Whatpm::Charset::DecodeHandle::CharString->new (\($_[0]));
    $input = $get_wrapper->($input);
    $p->{set_next_char} = sub {
      my $self = shift;

      my $char = '';
      if (defined $self->{next_next_char}) {
        $char = $self->{next_next_char};
        delete $self->{next_next_char};
        $self->{next_char} = ord $char;
      } else {
        $self->{char_buffer} = '';
        $self->{char_buffer_pos} = 0;
        
        my $count = $input->manakai_read_until
            ($self->{char_buffer},
             qr/(?![\x{FDD0}-\x{FDDF}\x{FFFE}\x{FFFF}\x{1FFFE}\x{1FFFF}\x{2FFFE}\x{2FFFF}\x{3FFFE}\x{3FFFF}\x{4FFFE}\x{4FFFF}\x{5FFFE}\x{5FFFF}\x{6FFFE}\x{6FFFF}\x{7FFFE}\x{7FFFF}\x{8FFFE}\x{8FFFF}\x{9FFFE}\x{9FFFF}\x{AFFFE}\x{AFFFF}\x{BFFFE}\x{BFFFF}\x{CFFFE}\x{CFFFF}\x{DFFFE}\x{DFFFF}\x{EFFFE}\x{EFFFF}\x{FFFFE}\x{FFFFF}])[\x20-\x7E\xA0-\x{D7FF}\x{E000}-\x{10FFFD}]/,
               $self->{char_buffer_pos});
        if ($count) {
          $self->{line_prev} = $self->{line};
          $self->{column_prev} = $self->{column};
          $self->{column}++;
          $self->{next_char}
              = ord substr ($self->{char_buffer},
                            $self->{char_buffer_pos}++, 1);
          return;
        }
        
        if ($input->read ($char, 1)) {
          $self->{next_char} = ord $char;
        } else {
          $self->{next_char} = -1;
          return;
        }
      }

      ($p->{line_prev}, $p->{column_prev}) = ($p->{line}, $p->{column});
      $p->{column}++;

      if ($self->{next_char} == 0x000A) { # LF
        $p->{line}++;
        $p->{column} = 0;
        
      } elsif ($self->{next_char} == 0x000D) { # CR
## TODO: support for abort/streaming
        my $next = '';
        if ($input->read ($next, 1) and $next ne "\x0A") {
          $self->{next_next_char} = $next;
        }
        $self->{next_char} = 0x000A; # LF # MUST
        $p->{line}++;
        $p->{column} = 0;
        
      } elsif ($self->{next_char} > 0x10FFFF) {
        $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
        
      } elsif ($self->{next_char} == 0x0000) { # NULL
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{next_char} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
      } elsif ($self->{next_char} <= 0x0008 or
               (0x000E <= $self->{next_char} and 
                $self->{next_char} <= 0x001F) or
               (0x007F <= $self->{next_char} and
                $self->{next_char} <= 0x009F) or
               (0xD800 <= $self->{next_char} and
                $self->{next_char} <= 0xDFFF) or
               (0xFDD0 <= $self->{next_char} and
                $self->{next_char} <= 0xFDDF) or
               {
                0xFFFE => 1, 0xFFFF => 1, 0x1FFFE => 1, 0x1FFFF => 1,
                0x2FFFE => 1, 0x2FFFF => 1, 0x3FFFE => 1, 0x3FFFF => 1,
                0x4FFFE => 1, 0x4FFFF => 1, 0x5FFFE => 1, 0x5FFFF => 1,
                0x6FFFE => 1, 0x6FFFF => 1, 0x7FFFE => 1, 0x7FFFF => 1,
                0x8FFFE => 1, 0x8FFFF => 1, 0x9FFFE => 1, 0x9FFFF => 1,
                0xAFFFE => 1, 0xAFFFF => 1, 0xBFFFE => 1, 0xBFFFF => 1,
                0xCFFFE => 1, 0xCFFFF => 1, 0xDFFFE => 1, 0xDFFFF => 1,
                0xEFFFE => 1, 0xEFFFF => 1, 0xFFFFE => 1, 0xFFFFF => 1,
                0x10FFFE => 1, 0x10FFFF => 1,
               }->{$self->{next_char}}) {
        
        if ($self->{next_char} < 0x10000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'control char',
                          text => (sprintf 'U+%04X', $self->{next_char}));
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'control char',
                          text => (sprintf 'U-%08X', $self->{next_char}));
        }
      }
    };

    $p->{read_until} = sub {
      #my ($scalar, $specials_range, $offset) = @_;
      return 0 if defined $p->{next_next_char};

      my $pattern = qr/(?![$_[1]\x{FDD0}-\x{FDDF}\x{FFFE}\x{FFFF}\x{1FFFE}\x{1FFFF}\x{2FFFE}\x{2FFFF}\x{3FFFE}\x{3FFFF}\x{4FFFE}\x{4FFFF}\x{5FFFE}\x{5FFFF}\x{6FFFE}\x{6FFFF}\x{7FFFE}\x{7FFFF}\x{8FFFE}\x{8FFFF}\x{9FFFE}\x{9FFFF}\x{AFFFE}\x{AFFFF}\x{BFFFE}\x{BFFFF}\x{CFFFE}\x{CFFFF}\x{DFFFE}\x{DFFFF}\x{EFFFE}\x{EFFFF}\x{FFFFE}\x{FFFFF}])[\x20-\x7E\xA0-\x{D7FF}\x{E000}-\x{10FFFD}]/;
      my $offset = $_[2] || 0;
      
      if ($p->{char_buffer_pos} < length $p->{char_buffer}) {
        pos ($p->{char_buffer}) = $p->{char_buffer_pos};
        if ($p->{char_buffer} =~ /\G(?>$pattern)+/) {
          substr ($_[0], $offset)
              = substr ($p->{char_buffer}, $-[0], $+[0] - $-[0]);
          my $count = $+[0] - $-[0];
          if ($count) {
            $p->{column} += $count;
            $p->{char_buffer_pos} += $count;
            $p->{line_prev} = $p->{line};
            $p->{column_prev} = $p->{column} - 1;
            $p->{prev_char} = [-1, -1, -1];
            $p->{next_char} = -1;
          }
          return $count;
        } else {
          return 0;
        }
      } else {
        my $count = $input->manakai_read_until ($_[0], $pattern, $_[2]);
        if ($count) {
          $p->{column} += $count;
          $p->{column_prev} += $count;
          $p->{prev_char} = [-1, -1, -1];
          $p->{next_char} = -1;
        }
        return $count;
      }
    }; # $p->{read_until}

    my $ponerror = $onerror || sub {
      my (%opt) = @_;
      my $line = $opt{line};
      my $column = $opt{column};
      if (defined $opt{token} and defined $opt{token}->{line}) {
        $line = $opt{token}->{line};
        $column = $opt{token}->{column};
      }
      warn "Parse error ($opt{type}) at line $line column $column\n";
    };
    $p->{parse_error} = sub {
      $ponerror->(line => $p->{line}, column => $p->{column}, @_);
    };
    
    my $char_onerror = sub {
      my (undef, $type, %opt) = @_;
      $ponerror->(layer => 'encode',
                  line => $p->{line}, column => $p->{column} + 1,
                  %opt, type => $type);
    }; # $char_onerror
    $input->onerror ($char_onerror);

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

    $p->{inner_html_node} = [$node, $el_category->{$node_ln}];
      ## TODO: Foreign element OK?

    ## Step 3
    my $root = $doc->create_element_ns
      ('http://www.w3.org/1999/xhtml', [undef, 'html']);

    ## Step 4 # MUST
    $doc->append_child ($root);

    ## Step 5 # MUST
    push @{$p->{open_elements}}, [$root, $el_category->{html}];

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

    delete $p->{parse_error}; # delete loop
  } else {
    die "$0: |set_inner_html| is not defined for node of type $nt";
  }
} # set_inner_html

} # tree construction stage

package Whatpm::HTML::RestartParser;
push our @ISA, 'Error';

1;
# $Date: 2008/09/15 02:54:12 $
