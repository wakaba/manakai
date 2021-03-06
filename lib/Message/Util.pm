
=head1 NAME

Message::Util -- Utilities for Message::* Perl modules.

=head1 DESCRIPTION

Useful functions for Message::* Perl modules.
This module is only intended for internal use.
Note that there is another module, Message::Tool.

=cut

package Message::Util;
#require 5.6.0;
use strict;
use vars qw(%FMT2STR %OPTION %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.27 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Carp;

=head1 REGEXPS (%Message::Util::REG)

=head2 Naming Rules

  key = *(prefix) [format] token-name
  
  prefix = 'M_'	;; With matching "(" ")"s
         / 'S_'	;; Simple (not strict) expression
         / 'NON_'	;; Negative character class
  format = E<lt>specification id, such as C<http>E<gt>	;; if necessary
  token-name = E<lt>BNF name =~ tr/-/_/E<gt>

=cut

	$REG{MATCH_NONE} = qr/(?!)/;
	$REG{MATCH_ALL} = qr/[\x00-\xFF]/;
## Whitespace
	$REG{WSP} = qr/[\x09\x20]/;
	$REG{FWS} = qr/[\x09\x20]*/;	## not same as 2822's
## Basic structure
	if (defined $^V) {	# $^V gt v6.5.0
	  $REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[^\x28\x29\x5C]|(??{$REG{comment}}))*\x29/;
	  $REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[^\x28\x29\x5C]|(??{$REG{comment}}))*)\x29/;
	} else {
	  $REG{comment} = qr/\x28(?:\x5C(?:.|[\x0A\x0D])|[^\x28\x29\x5C]|\x28(?:\x5C(?:.|[\x0A\x0D])|[^\x28\x29\x5C])*\x29)*\x29/;
	  $REG{M_comment} = qr/\x28((?:\x5C(?:.|[\x0A\x0D])|[^\x28\x29\x5C]|\x28(?:\x5C(?:.|[\x0A\x0D])|[^\x28\x29\x5C])*\x29)*)\x29/;
	}
	
	$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
	$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[^\x0D\x22\x5C])*)\x22/;
	
	$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;
	$REG{M_domain_literal} = qr/\x5B((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*)\x5D/;
	
	#$REG{angle_quoted} = qr/\x3C[\x09\x20\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]*\x3E/;
	$REG{angle_qcontent} = qr/(?:$REG{quoted_string}|$REG{domain_literal}|[^\x3C\x3E\x22\x5B])+/;
	$REG{angle_quoted} = qr/<$REG{angle_qcontent}>|<>/;
	$REG{M_angle_quoted} = qr/<($REG{angle_qcontent})>|<>/;
	

=head2 tokens

 atext  	NON_atext	822.atext
 atext_dot	NON_atext_dot	822.atext / "."
 		NON_atext_dot_wsp	822.atext / "." / WSP
 http_token	NON_http_token	http.token
 		NON_http_token_wsp	http.token / WSP
 attribute_char		rfc2231.attribute-char
 		NON_http_attribute_char	http.token AND rfc2231.attribute-char

=cut

	$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
	$REG{atext_dot} = qr/[\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
	$REG{atext_dot_wsp} = qr/[\x09\x20\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
	$REG{atext_dot8} = qr/[\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E\x80-\xFF]+/;
	$REG{token} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
	$REG{http_token} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]+/;
	$REG{attribute_char} = qr/[\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
	
	$REG{NON_atext} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
	$REG{NON_atext_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
	$REG{NON_atext_dot} = qr/[^\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
	$REG{NON_atext_dot_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
	$REG{NON_token} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/;
	$REG{NON_http_token} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
	$REG{NON_http_token_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
	$REG{NON_attribute_char} = qr/[^\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/;
	$REG{NON_http_attribute_char} = qr/[^\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
	$REG{NON_http_attribute_char_wsp} = qr/[^\x09\x20\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
		## Yes, C<attribute-char> does not appear in HTTP spec.
	
	$REG{S_uri} = qr#[\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]+#;
	
	$REG{NON_base64alphabet} = qr#[^A-Za-z0-9+/=]#;
	
	$REG{dot_atom} = qr/$REG{atext}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext})*/;
	$REG{dot_atom_dot} = qr/$REG{atext_dot}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext_dot})*/;
	$REG{dot_word} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext}|$REG{quoted_string}))*/;
	$REG{dot_word_dot} = qr/(?:$REG{atext_dot}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext_dot}|$REG{quoted_string}))*/;
	$REG{phrase} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{atext}|$REG{quoted_string}|\.|$REG{FWS})*/;
		## RFC 822 phrase (not strict)

	#$REG{domain} = qr/(?:$REG{dot_atom}|$REG{domain_literal})/;
	$REG{domain} = qr/(?:$REG{dot_atom_dot}|$REG{domain_literal})/;
	#$REG{addr_spec} = qr/$REG{dot_word}$REG{FWS}\x40$REG{FWS}$REG{domain}/;
	$REG{addr_spec} = qr/$REG{dot_word_dot}$REG{FWS}\x40$REG{FWS}$REG{domain}/;
	$REG{msg_id} = qr/<$REG{FWS}$REG{addr_spec}$REG{FWS}>/;
	
	$REG{M_addr_spec} = qr/($REG{dot_word_dot})$REG{FWS}\x40$REG{FWS}($REG{domain})/;
	
	$REG{date_time} = qr/(?:[A-Za-z]+$REG{FWS},$REG{FWS})?[0-9]+$REG{WSP}*[A-Za-z]+$REG{WSP}*[0-9]+$REG{WSP}+[0-9]+$REG{FWS}:$REG{WSP}*[0-9]+(?:$REG{FWS}:$REG{WSP}*[0-9]+)?$REG{FWS}(?:[A-Za-z]+|[+-]$REG{WSP}*[0-9]+)/;
	$REG{asctime} = qr/[A-Za-z]+$REG{WSP}*[A-Za-z]+$REG{WSP}*[0-9]+$REG{WSP}+[0-9]+$REG{FWS}:$REG{WSP}*[0-9]+$REG{FWS}:$REG{WSP}*[0-9]+$REG{WSP}+[0-9]+/;

## MIME encoded-word
	$REG{M_encoded_word} = qr/=\x3F($REG{attribute_char})(?:\x2A($REG{attribute_char}))?\x3F($REG{attribute_char})\x3F([\x21-\x3E\x40-\x7E]+)\x3F=/;
	$REG{S_encoded_word} = qr/=\x3F$REG{atext_dot}\x3F=/;
	#$REG{S_encoded_word_comment} = qr/=\x3F[\x21-\x27\x2A-\x5B\x5D-\x7E]+\x3F=/;
		## not used anywhere

## obsoleted
*FMT2STR = \%Message::Util::Formatter::FMT2STR;

=head1 STRUCTURED FIELD FUNCTIONS

=over 4

=item $nocomment:-) = Message::Util::delete_comment ($string)

Gets rid of all C<comment>s.  Inserts a SP instead.

=cut

sub delete_comment ($) {
  use re 'eval';
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal}|$REG{angle_quoted})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

sub delete_wsp ($) {
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|((?:$REG{token}|$REG{S_encoded_word})(?:$REG{WSP}+(?:$REG{token}|$REG{S_encoded_word}))+)|$REG{WSP}+}{
    my ($o,$p) = ($1,$2);
    if ($o) {$o}
    elsif ($p) {$p=~s/$REG{WSP}+/\x20/g;$p}
    else {''}
  }gex;
  $body;
}

sub remove_meaningless_wsp ($) {
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{WSP}+}{
    $1 || '';
  }gex;
  $body;
}

sub wsps_to_sp ($) {
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{WSP}+}{
    $1 || ' ';
  }gex;
  $body;
}

=item Message::Util::quote_ccontent ($yourself, $ccontent)

Quotes C<ccontent> (to be).

=cut

sub quote_ccontent ($;%) {
  my $ccontent = shift;
  my %option = @_;
  if ($option{strict_quoted_pair}) {
    $ccontent =~ s/([\x28\x29\x5C]|\x3D\x3F)/\x5C$1/g;
  } else {
    $ccontent =~ s/([\x28\x29\x5C]|\x3D\x3F)([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
  }
  $ccontent;
}

=item $unquoted = Message::Util::unquote_ccontent ($string)

Unquotes C<quoted-pair> in C<comment>s.

=cut

sub unquote_ccontent ($) {
  use re 'eval';
  my $comment = shift;
  $comment =~ s{$REG{M_comment}}{
    my $ctext = $1;
    $ctext =~ s/\x5C([\x00-\xFF])/$1/g;
    '('.$ctext.')';
  }goex;
  $comment;
}

=item $unquoted = Message::Util::unquote_quoted_string ($string)

Unquotes C<quoted-pair> in C<quoted-string>s and
unquotes C<quoted-string> (or gets rid of C<DQUOTE>s).

=cut

sub unquote_quoted_string ($) {
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

=item Message::Util::unquote_if_quoted_string ($string)

Unquotes if and only if given string is A C<quoted-string>.
This function returns two value, (C<$unquoted-string>, 
C<$was-quoted-string?>).

=cut

sub unquote_if_quoted_string ($) {
  my $quoted_string = shift;  my $isq = 0;
  $quoted_string =~ s{^$REG{M_quoted_string}$}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/gs;
    $isq = 1;
    $qtext;
  }goex;
  wantarray? ($quoted_string, $isq): $quoted_string;
}

sub unquote_if_angle_quoted ($) {
  my $quoted_string = shift;  my $isq = 0;
  $quoted_string =~ s{^$REG{M_angle_quoted}$}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $isq = 1;
    $qtext;
  }goex;
  wantarray? ($quoted_string, $isq): $quoted_string;
}

sub unquote_if_domain_literal ($) {
  my $quoted_string = shift;  my $isq = 0;
  $quoted_string =~ s{^$REG{M_domain_literal}$}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $isq = 1;
    $qtext;
  }goex;
  wantarray? ($quoted_string, $isq): $quoted_string;
}

=item $quoted = Message::Util::quote_unsafe_string ($string)

Quotes string itself by C<DQUOTES> if it contains of
I<unsafe> character.

Default I<unsafe> is defined as E<lt>not ( atom / "." / %x09 / %x20 ) E<gt>.

=cut

sub quote_unsafe_string ($;%) {
  my $string = shift;
  my %option = @_;
  $option{unsafe} ||= 'NON_atext_dot';
  $option{unsafe_regex} = $option{unsafe} if $option{unsafe} =~ /^\(\?-xism:/;
  $option{unsafe_regex} ||= qr/$REG{$option{unsafe}}|$REG{WSP}$REG{WSP}|^$REG{WSP}|$REG{WSP}$|^=\x3F/;
  my $r = qr/([\x22\x5C])([\x21-\x7E])?/;
  $r = qr/([\x22\x5C])/ if $option{strict};	## usefor-article
  if ($string =~ /$option{unsafe_regex}/) {
    $string =~ s/$r/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
    $string = '"'.$string.'"';
  }
  $string;
}

sub quote_unsafe_domain ($) {
  my $string = shift;
  if ($string =~ /^\[[^\[\]]+\]$/) {
    # 
  } elsif ($string =~ /$REG{NON_atext_dot}/ || $string =~ /^\.|\.$/) {
    $string =~ s/([\x0D\x5B-\x5D])/\x5C$1/g;
    $string = '['.$string.']';
  }
  $string;
}

sub remove_wsp ($) {
  my $s = shift;
  $s =~ s{($REG{quoted_string}|$REG{domain_literal}|$REG{angle_quoted})|$REG{WSP}+}{
    $1
  }gex;
  $s;
}

=item $encoded = Message::Util::encode_printable_string ($string)
=item $decoded = Message::Util::decode_printable_string ($string)

Encodes or decodes string in PrintableString, described in 
RFC 1327, RFC 2156.  These functions supports 8bit octets encoded
as '(ddd)' format, although RFC 2156 allows it for only 7bit
octets.

=cut

my %To_Printable_String = (
	'@'	=> '(a)',
	'%'	=> '(p)',
	'!'	=> '(b)',
	'"'	=> '(q)',
	'_'	=> '(u)',
	'('	=> '(l)',
	')'	=> '(r)',
);
my %From_Printable_String = reverse %To_Printable_String;
sub encode_printable_string ($) {
  my $s = shift;
  $s =~ s{ ([^0-9A-Za-z\x20'+,./:=?-]) }{
    my $c = $1;
    unless ($To_Printable_String{$c}) {
      $To_Printable_String{$c} = sprintf '(%03d)', ord $c;
    }
    $To_Printable_String{$c};
  }gex;
  $s;
}
sub decode_printable_string ($) {
  my $s = shift;
  $s =~ s{ \( ([0-9A-Za-z]+) \) }{
    my $c = lc $1;  my $p = "($c)";
    if ($c !~ /[^0-9]/) {
      $From_Printable_String{$p} = pack 'C', 0+$c;
    } elsif (!defined $From_Printable_String{$p}) {
      $From_Printable_String{$p} = $p;	## Invalid!
    }
    $From_Printable_String{$p};
  }gex;
  $s;
}

=item $encoded = Message::Util::encode_t61_string ($string)
=item $decoded = Message::Util::decode_t61_string ($string)

Encodes or decodes string in T.61String described in RFC 1327,
RFC 2056.

=cut

sub encode_t61_string ($) {
  my $s = shift;
  $s =~ s{ ([^0-9A-Za-z\x20'+,./:=?-]) }{
    sprintf '{%03d}', ord $1;
  }gex;
  $s;
}
sub decode_t61_string ($) {
  my $s = shift;
  $s =~ s{ \{ ([0-9]+) \} }{
    my $c = $1;  my $i = 0;
    my $r = '';
    while (my $d = substr ($c, $i * 3, 3)) {
      $r .= pack 'C', 0+$d;  $i++;
    }
    $r;
  }gex;
  $s;
}
=item $encoded = Message::Util::encode_printable_string ($string)
=item $decoded = Message::Util::decode_printable_string ($string)

Encodes or decodes string in RFC 822 with restricted encoding,
defined by RFC 1137.

=cut

my %To_Encoded_Atom = (
	"\x20"	=> '_',
	'_'	=> '#u#',
	'('	=> '#l#',
	')'	=> '#r#',
	','	=> '#m#',
	':'	=> '#c#',
	"\x5C"	=> '#b#',
	'#'	=> '#h#',
	'='	=> '#e#',
	'/'	=> '#s#',
);
my %From_Encoded_Atom = reverse %To_Encoded_Atom;
sub encode_restricted_rfc822 ($) {
  my $s = shift;
  $s =~ s{ ([^\x21\x24-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E\x60-\x7E]) }{
    my $c = $1;	## \x2E \x40
    unless ($To_Encoded_Atom{$c}) {
      $To_Encoded_Atom{$c} = sprintf '#%03d#', ord $c;
    }
    $To_Encoded_Atom{$c};
  }gex;
  $s;
}
sub decode_restricted_rfc822 ($) {
  my $s = shift;
  $s =~ s{ \# ([0-9A-Za-z]+) \# | _ }{
    my $c = lc $1;  my $p = "#$c#";
    if ($c !~ /[^0-9]/) {
      $From_Encoded_Atom{$p} = pack 'C', 0+$c;
    } elsif (!defined $From_Encoded_Atom{$p}) {
      $From_Encoded_Atom{$p} = $p;	## Invalid!
    }
    $From_Encoded_Atom{$p};
  }gex;
  $s;
}

=item $Message::Util::make_clone ($parent)

Returns clone.

=cut

sub make_clone ($) {
  my $s = shift;
  if (ref $s eq 'ARRAY') {
    $s = [map {make_clone ($_)} @$s];
  } elsif (ref $s eq 'HASH') {
    $s = {map {make_clone ($_)} (%$s)};
  } elsif (ref $s && ref $s ne 'CODE' && ref $s ne 'Regexp') {
    $s = $s->clone;
  }
  $s;
}

=head1 ENCODER and DECODER

=over 4

=item Message::Util::encode_header_string ($yourself, $string, [%options])

=cut

sub encode_header_string ($$;%) {
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_after_encode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  $o{current_charset} = Message::MIME::Charset::name_normalize ($o{current_charset});
  my ($t,%r) = Message::MIME::Charset::encode ($o{charset}, $s);
  my @o = (language => $o{language});
  if ($r{success}) {	## Convertion succeed
    $o{charset} = $r{charset} if $r{charset};
    $o{charset} = '' if $o{charset} =~ /\*/;
    (value => $t, @o, Message::MIME::Charset::name_minimumize ($o{charset}, $t));
  } else {	## Fault
    $o{current_charset} = '' if $o{current_charset} =~ /\*/;
    (value => $t, failed => 1, @o, 
     Message::MIME::Charset::name_minimumize ($o{current_charset}, $t));
  }
}

sub decode_header_string ($$;%) {
  require Message::MIME::Charset;
  require Message::MIME::EncodedWord;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_before_decode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  my ($t, %r);	## decoded-text, success?
  if ($o{type} !~ /quoted|encoded|domain|word/) {
    my (@s, @r);
    $s =~ s{(([\x09\x20]*(?:\x5C[\x00-\xFF]
      |[\x00-\x08\x0A-\x1F\x21-\x5B\x5D-\xFF])+|[\x09\x20]+$))}
      { push @s, $1; '' }goesx;
    for my $i (0..$#s) {
      if ($s[$i] =~ /^($REG{FWS})$REG{M_encoded_word}$/) {
        my ($t, $w) = ('', $1);
        ($t, $r[$i]) = (Message::MIME::EncodedWord::_decode_eword ($2, $3, $4, $5));
        if ($r[$i]) {
          $s[$i] = $t;
          if ($i == 0 || $r[$i-1] == 0) {
            $s[$i] = $w.$s[$i];
          }
        }
      } else {
        my ($u, %q) = ($s[$i]);
        $u =~ s/\x5C([\x00-\xFF])/$1/g unless $o{type} =~ /text/;
        ($u,%q) = Message::MIME::Charset::decode ($o{charset}, $u);
        $s[$i] = $u if $q{success};
      }
    }
    $t = join '', @s;  $r{success} = 1;
  } else {
    ($t,%r) = Message::MIME::Charset::decode ($o{charset}, $s);
  }
  $r{success} ? (value => $t, success => 1, language => $o{language}):	## suceess
  (value => $s, language => $o{language}, success => 0,
   charset => ($o{charset}=~/\*/?'':$o{charset}));	## fault
}

sub encode_body_string {
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_after_encode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  $o{current_charset} = Message::MIME::Charset::name_normalize ($o{current_charset});
  my ($t,%r) = Message::MIME::Charset::encode ($o{charset}, $s);
  my @o = ();
  if ($r{success}) {	## Convertion successed
    $o{charset} = $r{charset} if $r{charset};
    $o{charset} = '' if $o{charset} =~ /\*/;
    (value => $t, @o, Message::MIME::Charset::name_minimumize ($o{charset}, $t));
  } else {	## Fault
    $o{current_charset} = '' if $o{current_charset} =~ /\*/;
    (value => $t, failed => 1, @o, 
     Message::MIME::Charset::name_minimumize ($o{current_charset}, $t));
  }
}

sub decode_body_string {
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_before_decode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  my ($t,%r) = Message::MIME::Charset::decode ($o{charset}, $s);
  $r{success} ? (value => $t, success => 1):	## suceess
  (value => $s, success => 0,
   charset => ($o{charset}=~/\*/?'':$o{charset}));	## fault
}

=item Message::Util::decode_quoted_string ($yourself, $quoted-string)

Returns unquoted and decoded a given C<quoted-string>
or a string containing one or multiple C<quoted-string>s.

=cut

sub decode_quoted_string ($$;%) {
  my $yourself = shift;
  my $quoted_string = shift;
  my %option = @_;
  $option{type} ||= 'phrase';
  $quoted_string =~ s{$REG{M_quoted_string}|([^\x22]+)}{
    my ($qtext, $t) = ($1, $2);
    if (length $t) {
      $t =~ s/$REG{WSP}+/\x20/g;
      my %s = &{$yourself->{option}->{hook_decode_string}}
        ($yourself, $t, type => $option{type},
        charset => $option{charset});
      $s{value};
    } else {
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$yourself->{option}->{hook_decode_string}}
        ($yourself, $qtext, type => $option{type}.'/quoted',
        charset => $option{charset});
      $s{value};
    }
  }goex;
  $quoted_string;
}

=item Message::Util::encode_qcontent ($yourself, $string)

Encodes (by C<hook_encode_string> of C<$yourself-E<gt>{option}>)
C<qcontent> (content of C<quoted-string>) within C<$string>.

=cut

sub encode_qcontent ($$) {
  my $yourself = shift;
  my $quoted_strings = shift;
  $quoted_strings =~ s{$REG{M_quoted_string}}{
    my ($qtext) = ($1);
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$yourself->{option}->{hook_encode_string}} ($yourself, $qtext,
                type => 'phrase/quoted');
      $s{value} =~ s/([\x0D\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ges;
      '"'.$s{value}.'"';
  }goex;
  $quoted_strings;
}

=item Message::Util::decode_qcontent ($yourself, $string)

Decodes (by C<hook_decode_string> of C<$yourself-E<gt>{option}>)
C<qcontent> (content of C<quoted-string>) within C<$string>.

=cut

sub decode_qcontent ($$) {
  my $yourself = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my ($qtext) = ($1);
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$yourself->{option}->{hook_decode_string}} ($yourself, $qtext,
                type => 'phrase/quoted');
      $s{value} =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
      '"'.$s{value}.'"';
  }goex;
  $quoted_string;
}

=item @comments = Message::Util::comment_to_array ($youtself, $comments)

Replaces C<comment>s to C< > (a SP), decodes C<ccontent>s,
and returns them as array.

=cut

sub comment_to_array ($$) {
  use re 'eval';
  my $yourself = shift;
  my $body = shift;
  my @r = ();
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{M_comment}}{
    my ($o, $c) = ($1, $2);
    if ($o) {$o}
    else {
      require Message::MIME::EncodedWord;
      push @r, Message::MIME::EncodedWord::decode_ccontent ($yourself, $c);
      ' ';
    }
  }gex;
  @r;
}

sub delete_comment_to_array ($$;%) {
  use re 'eval';
  my $yourself = shift;
  my $body = shift;
  my %option = @_;
  my $areg = ''; $areg = '|'.$REG{angle_quoted} if $option{-use_angle_quoted};
  my @r = ();
  $body =~ s{($REG{quoted_string}|$REG{domain_literal}$areg)|$REG{M_comment}}{
    my ($o, $c) = ($1, $2);
    if ($o) {$o}
    else {
      require Message::MIME::EncodedWord;
      push @r, Message::MIME::EncodedWord::decode_ccontent ($yourself, $c);
      ' ';
    }
  }gex;
  ($body, @r);
}

=item Message::Util::encode_ccontent ($yourself, $ccontent)

Encodes C<ccontent> (content of C<comment>).

=cut

sub encode_ccontent ($$) {
  my $yourself = shift;
  my $ccontent = shift;
  my %f = &{$yourself->{option}->{hook_encode_string}} ($yourself, 
            $ccontent, type => 'ccontent');
  $f{value} =~ s/([\x28\x29\x5C]|\x3D\x3F)([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
  $f{value};
}

=item Message::Util::decode_ccontent ($yourself, $ccontent)

Decodes C<ccontent> (content of C<comment>).

=cut

sub decode_ccontent ($$) {
  require Message::MIME::EncodedWord;
  Message::MIME::EncodedWord::decode_ccontent ($_[0], $_[1]);
}

## obsoleted
sub sprintxf ($;\%) {
  require Message::Util::Formatter;
  Message::Util::Formatter->new->replace (@_);
}

sub decide_newline ($) {
  my $s = shift;
  my $nl = "\x0D\x0A";
      my $crlf = $s =~ s/\x0D\x0A/\x0D\x0A/gs;
      my $lfcr = $s =~ s/\x0A\x0D/\x0A\x0D/gs;
      my $cr = $s =~ s/\x0D(?!\x0A)/\x0D/gs;
      my $lf = $s =~ s/(?<!\x0D)\x0A/\x0A/gs;
      if ($crlf >= $cr && $crlf >= $lf && $crlf >= $lfcr ) { $nl = "\x0D\x0A" }
      elsif ($lfcr >= $cr && $lfcr >= $lf) { $nl = "\x0A\x0D" }
      elsif ($cr >= $lf) { $nl = "\x0D" }
      else { $nl = "\x0A" }
  $nl;
}

=item $fqdn = Message::Util::get_host_fqdn

Returns FQDN of THIS host.  If it is unable to get the FQDN,
returns undef.

=over 3

=item $Message::Util::OPTION{use_Net_Domain} = 1/0

Whether using Net::Domain module to get FQDN or not.

=item $Message::Util::OPTION{use_Sys_Hostname} = 1/0

Whether using Sys::Hostnamen module to get FQDN or not.

=item $Message::Util::OPTION{use_Sys_Hostname_Long} = 1/0

Whether using Sys::Hostnamen::Long module to get FQDN or not.

=back

Note that the value returned by Sys::Hostname::hostname
usually does not match with the FQDN.  This module is prepared
as the last way to get.  If you want not to get non-FQDN,
set 0 to use_Sys_Hostname.  Sys::Hostname is bundled with
Perl.  This is why its default is 1.

=cut

$OPTION{use_Net_Domain} = 1;
$OPTION{use_Sys_Hostname} = 1;
$OPTION{use_Sys_Hostname_Long} = 1;
$OPTION{use_cache_host_fqdn} = 1;
$OPTION{__cache_host_fqdn} = undef;

sub get_host_fqdn () {
  my $f = undef;
  return $OPTION{__cache_host_fqdn}
    if $OPTION{use_cache_host_fqdn} && $OPTION{__cache_host_fqdn};
  if ($OPTION{use_Net_Domain}) {
    eval q{require Net::Domain;
      $f = &Net::Domain::hostfqdn;
    } or Carp::carp ("get_host_fqdn: get by Net::Domain: $@");
    if ($f) {
      $OPTION{__cache_host_fqdn} = $f;
      return $f;
    }
  }
  if ($OPTION{use_Sys_Hostname_Long}) {
    eval q{require Sys::Hostname::Long;
      $f = &Sys::Hostname::Long::hostname_long;
    } or Carp::carp ("get_host_fqdn: get by Sys::Hostname::Long: $@");
    if ($f) {
      $OPTION{__cache_host_fqdn} = $f;
      return $f;
    }
  }
  if ($OPTION{use_Sys_Hostname}) {
    eval q{require Sys::Hostname;
      $f = &Sys::Hostname::hostname;
    } or Carp::carp ("get_host_fqdn: get by Sys::Hostname: $@");
    if ($f) {
      $OPTION{__cache_host_fqdn} = $f;
      return $f;
    }
  }
  undef;
}

sub is_utf8 ($) {
  my $s = shift;
  return Encode::is_utf8 ($s) if $Encode::VERSION;
  0;
}

sub enentity_html ($) {
  my $s = shift;
  $s =~ s/&/&amp;/;
  $s =~ s/</&lt;/;
  $s =~ s/>/&gt;/;
  $s =~ s/"/&quot;/;
  $s;
}

sub deentity_html ($) {
  my $s = shift;
  $s =~ s/&lt;/</;
  $s =~ s/&gt;/>/;
  $s =~ s/&quot;/"/;
  $s =~ s/&amp;/&/;
  $s;
}

package Message::Util::Wide;
use vars qw(%REG);

	$REG{M_quoted_string} = qr/\x22((?:\x5C.|[^\x0D\x22\x5C])*)\x22/;

sub unquote_if_quoted_string ($) {
  my $quoted_string = shift;  my $isq = 0;
  $quoted_string =~ s{^$REG{M_quoted_string}$}{
    my $qtext = $1;
    $qtext =~ s/\x5C(.)/$1/gs;
    $isq = 1;
    $qtext;
  }esx;
  wantarray? ($quoted_string, $isq): $quoted_string;
}

=head1 LICENSE

Copyright 2002 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=cut

1;
# $Date: 2003/01/04 03:14:14 $
