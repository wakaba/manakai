package Whatpm::Charset::UnicodeChecker;
use strict;

## NOTE: For more information (including rationals of checks performed
## in this module), see
## <http://suika.fam.cx/gate/2005/sw/Unicode%E7%AC%A6%E5%8F%B7%E5%8C%96%E6%96%87%E5%AD%97%E5%88%97%E3%81%AE%E9%81%A9%E5%90%88%E6%80%A7>.

## NOTE: Unicode's definition for character string conformance is 
## very, very vague so that it is difficult to determine what error
## level is appropriate for each error.  The Unicode Standard abuses
## conformance-creteria-like terms such as "deprecated", "discouraged",
## "preferred", "better", "not encouraged", "should", and so on with no
## clear explanation of their difference (if any) or relationship to
## the conformance.  In fact, that specification does not define the
## conformance class for character strings.

sub new_handle ($$) {
  my $self = bless {
    queue => [],
    new_queue => [],
    onerror => sub {},
    level => {
      unicode_should => 'w',
      unicode_deprecated => 'w', # = unicode_should
      unicode_discouraged => 'w',
      unicode_preferred => 'w',
      ## NOTE: We do some "unification" of levels - for example,
      ## "not encouraged" is unified with "discouraged" and
      ## "better" is unified with "preferred".
    },
  }, shift;
  $self->{handle} = shift; # char stream
  return $self;
} # new_handle

## TODO: We need to do some perf optimization

sub getc ($) {
  my $self = $_[0];
  return shift @{$self->{queue}} if @{$self->{queue}};

  my $char;
  unless (@{$self->{new_queue}}) {
    my $s = '';
    $self->{handle}->read ($s, 1) or return undef;
    push @{$self->{new_queue}}, split //, $s;
  }  
  $char = shift @{$self->{new_queue}};

  my $char_code = ord $char;

  if ({
    0x0340 => 1, 0x0341 => 1, 0x17A3 => 1, 0x17D3 => 1,
    0x206A => 1, 0x206B => 1, 0x206C => 1, 0x206D => 1,
    0x206E => 1, 0x206F => 1, 0xE0001 => 1,
  }->{$char_code} or
  (0xE0020 <= $char_code and $char_code <= 0xE007F)) {
    ## NOTE: From Unicode 5.1.0 |PropList.txt| (Deprecated).
    $self->{onerror}->(type => 'unicode deprecated',
                       text => (sprintf 'U+%04X', $char_code),
                       layer => 'charset',
                       level => $self->{level}->{unicode_deprecated});
  } elsif ((0xFDD0 <= $char_code and $char_code <= 0xFDDF) or
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
           }->{$char_code}) {
    ## NOTE: From Unicode 5.1.0 |PropList.txt| (Noncharacter_Code_Point).
    $self->{onerror}->(type => 'nonchar',
                       text => (sprintf 'U+%04X', $char_code),
                       layer => 'charset',
                       level => $self->{level}->{unicode_should});
  } elsif ({
            0x0344 => 1, # COMBINING GREEK DIALYTIKA TONOS
            0x03D3 => 1, 0x03D4 => 1, # GREEK UPSILON WITH ...
            0x20A4 => 1, # LIRA SIGN

            0x2126 => 1, # OHM SIGN # also, discouraged
            0x212A => 1, # KELVIN SIGN
            0x212B => 1, # ANGSTROM SIGN
           }->{$char_code} or
           (0xFB50 <= $char_code and $char_code <= 0xFDFB) or
           (0xFE70 <= $char_code and $char_code <= 0xFEFE) or
           (0xFA30 <= $char_code and $char_code <= 0xFA6A) or
           (0xFA70 <= $char_code and $char_code <= 0xFAD9) or
           (0x2F800 <= $char_code and $char_code <= 0x2FA1D) or
           (0x239B <= $char_code and $char_code <= 0x23B3)) {
    ## NOTE: This case must come AFTER noncharacter checking, due to
    ## their range overwrap.
    if ({
         ## In the Arabic Presentation Forms-A block, but no character is
         ## assigned in Unicode 5.1.
         0xFBB2 => 1, 0xFBB3 => 1, 0xFBB4 => 1, 0xFBB5 => 1, 0xFBB6 => 1,
         0xFBB7 => 1, 0xFBB8 => 1, 0xFBB9 => 1, 0xFBBA => 1, 0xFBBB => 1,
         0xFBBC => 1, 0xFBBD => 1, 0xFBBE => 1, 0xFBBF => 1, 0xFBC0 => 1,
         0xFBC1 => 1, 0xFBC2 => 1, 0xFBC3 => 1, 0xFBC4 => 1, 0xFBC5 => 1,
         0xFBC6 => 1, 0xFBC7 => 1, 0xFBC8 => 1, 0xFBC9 => 1, 0xFBCA => 1,
         0xFBCB => 1, 0xFBCC => 1, 0xFBCD => 1, 0xFBCE => 1, 0xFBCF => 1,
         0xFBD0 => 1, 0xFBD1 => 1, 0xFBD2 => 1,
         0xFD40 => 1, 0xFD41 => 1, 0xFD42 => 1, 0xFD43 => 1, 0xFD44 => 1,
         0xFD45 => 1, 0xFD46 => 1, 0xFD47 => 1, 0xFD48 => 1, 0xFD49 => 1,
         0xFD4A => 1, 0xFD4B => 1, 0xFD4C => 1, 0xFD4D => 1, 0xFD4E => 1,
         0xFD4F => 1,
         0xFD90 => 1, 0xFD91 => 1,
         0xFDC8 => 1, 0xFDC9 => 1, 0xFDCA => 1, 0xFDCB => 1, 0xFDCC => 1,
         0xFDCD => 1, 0xFDCE => 1, 0xFDCF => 1,
         # 0xFDD0-0xFDEF noncharacters

         ## In Arabic Presentation Forms-A block, but explicitly
         ## allowed
         0xFD3E => 1, 0xFD3F => 1,

         ## In Arabic Presentation Forms-B block, unassigned
         0xFE75 => 1, 0xFEFD => 1, 0xFEFE => 1,
        }->{$char_code}) {
      #
    } else {
      $self->{onerror}->(type => 'unicode should',
                         text => (sprintf 'U+%04X', $char_code),
                         layer => 'charset',
                         level => $self->{level}->{unicode_should});
    }
  } elsif ({
            ## Styled overlines/underlines in CJK Compatibility Forms
            0xFE49 => 1, 0xFE4A => 1, 0xFE4B => 1, 0xFE4C => 1,
            0xFE4D => 1, 0xFE4E => 1, 0xFE4F => 1,
            
            0x037E => 1, 0x0387 => 1, # greek punctuations
            
            #0x17A3 => 1, # also, deprecated
            0x17A4 => 1, 0x17B4 => 1, 0x17B5 => 1, 0x17D8 => 1,

            0x2121 => 1, # tel
            0x213B => 1, # fax
            #0x2120 => 1, # SM (superscript)
            #0x2122 => 1, # TM (superscript)

            0xFFF9 => 1, 0xFFFA => 1, 0xFFFB => 1, # inline annotations
           }->{$char_code} or
           (0x2153 <= $char_code and $char_code <= 0x217F)) {
    $self->{onerror}->(type => 'unicode discouraged',
                       text => (sprintf 'U+%04X', $char_code),
                       layer => 'charset',
                       level => $self->{level}->{unicode_discouraged});
  } elsif ({
            0x055A => 1, 0x0559 =>1, # greek punctuations
            
            0x2103 => 1, 0x2109 => 1, # degree signs

            0xFEFE => 1, # strongly preferrs U+2060 WORD JOINTER
           }->{$char_code}) {
    $self->{onerror}->(type => 'unicode not preferred',
                       text => (sprintf 'U+%04X', $char_code),
                       layer => 'charset',
                       level => $self->{level}->{unicode_preferred});
  }

  ## TODO: "khanda ta" should be represented by U+09CE
  ## rather than <U+09A4, U+09CD, U+200D>.

  ## TODO: IDS syntax

  ## TODO: langtag syntax

  return $char;
} # getc

sub manakai_read_until ($$$;$) {
  #my ($self, $scalar, $pattern, $offset) = @_;
  my $self = shift;
  
  if (@{$self->{queue}}) {
    if ($self->{queue}->[0] =~ /^$_[1]/) {
      substr ($_[0], $_[2]) = shift @{$self->{queue}};
      return 1;
    } else {
      return 0;
    }
  }

  ## TODO: impl check
  
  return $self->{handle}->manakai_read_until (@_);
} # manakai_read_until

sub ungetc ($$) {
  unshift @{$_[0]->{queue}}, chr int ($_[1] or 0);
} # ungetc

sub close ($) {
  shift->{handle}->close;
} # close

sub charset ($) {
  shift->{handle}->charset;
} # charset

sub has_bom ($) {
  shift->{handle}->has_bom;
} # has_bom

sub input_encoding ($) {
  shift->{handle}->input_encoding;
} # input_encoding

sub onerror ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{handle}->onerror ($_[0]->{onerror} = $_[1]);
    } else {
      $_[0]->{handle}->onerror ($_[0]->{onerror} = sub {});
    }
  }

  return $_[0]->{onerror};
} # onerror

1;
