
=head1 NAME

SuikaWiki::Markup::XML::Parser --- SuikaWiki: Simple XML parser

=head1 DESCRIPTION

This is a simple XML parser intended to be used with SuikaWiki::Markup::XML.
After parsing of the XML document, this module returns a SuikaWiki::Markup::XML
object so that you can handle XML document with that module (and other modules
implementing same interface).

This module is part of SuikaWiki.

=cut

package SuikaWiki::Markup::XML::Parser;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar InXML_NCNameStartChar InXMLNCNameChar InXMLChar InXML_deprecated_noncharacter InXML_unicode_xml_not_suitable!;
use SuikaWiki::Markup::XML;
require SuikaWiki::Markup::XML::Error;
*_raise_error = \&SuikaWiki::Markup::XML::Error::raise;

my %NS = (
	SGML	=> 'urn:x-suika-fam-cx:markup:sgml:',
	internal_ns_invalid	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#',
	internal_attr_duplicate	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/invalid-attr#',
);

=head1 METHODS

WARNING: This module is under construction.  Interface of this module is not yet fixed.

=cut

my %xml_re;
# [1] document = prolog element *Misc
# [2] Char = %x09 / %x0A / %x0D / U+0020-U+D7FF / U+E000-U+FFFD / U+10000-U+10FFFF ;; 1.0
# [2] Char = %x09 / %x0A / %x0D / %x20-7E / U+0085 / U+00A0-U+D7FF / U+E000-U+FFFD
#          / U+10000-U+10FFFF                                                      ;; 1.1
# [3] s = 1*(%x20 / %x09 / %x0D / %x0A)
$xml_re{s} = qr/[\x09\x0D\x0A\x20]+/s;
# [4] NameChar = Letter / Digit / "." / "-" / "_" / ":" / CombiningChar / Extender ;; 1.0
# [4] NameStartChar = ":" / ALPHA / "_" / U+00C0-U+02FF / U+0370-U+037D
#                   / U+037F-U+1FFF / U+200C-U+200D / U+2070-U+218F
#                   / U+2C00-U+2FEF / U+3001-U+D7FF / U+F900-U+EFFFF               ;; 1.1
# [4a] NameChar = NameStartChar / "-" / "." / DIGIT / U+00B7 / U+0300-U+036F
#               / U+203F-U+2040                                                    ;; 1.1
#	$xml_re{NameChar} = qr/[A-Za-z0-9._:-]|[^\x00-\x7F]/;
$xml_re{NameChar} = qr/\p{InXMLNameChar}/;
# [5] Name = (Letter / "_" / ":") *NameChar                                        ;; 1.0
# [5] Name = NameStartChar *NameChar                                               ;; 1.1
#	$xml_re{Name} = qr/(?:[A-Z_:]|[^\x00-\x7F])(?:$xml_re{NameChar})*/;
$xml_re{Name} = qr/\p{InXML_NameStartChar}\p{InXMLNameChar}*/;
# [6] Names = Name *(S Name)       ;; 1.0 FE & 1.0 FE-errata (2000-09-27) & 1.0 SE
# [6] Names = Name *(%x20 Name)    ;; 1.0 FE-errata (2000-04-09) & 1.0 SE-errata
$xml_re{Names} = qr/$xml_re{Name}(?:$xml_re{s}$xml_re{Name})*/s;
# [7] Nmtoken = 1*NameChar
#$xml_re{Nmtoken} = qr/(?:$xml_re{NameChar})+/;
$xml_re{Nmtoken} = qr/\p{InXMLNameChar}+/;
# [8] Nmtokens = Nmtoken *(S Nmtoken)    ;; 1.0 FE & 1.0 FE-errata (2000-09-27) & 1.0 SE
# [8] Nmtokens = Nmtoken *(%x20 Nmtoken) ;; 1.0 FE-errata (2000-04-09) & 1.0 SE-errata
$xml_re{Nmtokens} = qr/$xml_re{Nmtoken}(?:$xml_re{s}$xml_re{Nmtoken})*/s;
# [9] EntityValue = <"> *((Char - ("%" / "&" / <">)) / PEReference / Reference) <">
#                 / "'" *((Char - ("%" / "&" / "'")) / PEReference / Reference) "'"
# [10] AttValue   = <"> *((Char - ("<" / "&" / <">)) / Reference) <">
#                 / "'" *((Char - ("<" / "&" / "'")) / Reference) "'"
$xml_re{__AttValue_simple} = qr/"[^"]*"|'[^']*'/s;
# [11] SystemLiteral = <"> *(Char - <">) <"> / "'" *(Char - "'") "'"
$xml_re{SystemLiteral} = qr/"[^"]*"|'[^']*'/;
# [12] PublicLiteral = <"> *PubidChar <"> / "'" *(PubidChar - "'") "'"
# [13] PubidChar = %x20 / %x0D / %x0A / ALPHA / DIGIT / "-" / "'" / "(" / ")"
#                / "+" / "," / "." / "/" / ":" / "=" / "?" / ";" / "!" / "*"
#               / "#" / "@" / "$" / "_" / "%"
$xml_re{PubidChar} = qr[[\x0D\x0A\x20!\x24#%'()+*,./0-9:;=?\x40A-Z_a-z-]];
$xml_re{__non_PubidChar} = qr[[^\x0D\x0A\x20!\x24#%'()+*,./0-9:;=?\x40A-Z_a-z-]];
$xml_re{__PubidChar2} = qr[[\x0D\x0A\x20!\x24#%()+*,./0-9:;=?\x40A-Z_a-z-]];
$xml_re{PublicLiteral} = qr/"(?:$xml_re{PubidChar})*"|'(?:$xml_re{PubidChar2})*'/;
# [14] CharData = *(Char - ("<" / "&")) - (*(Char - ("<" / "&")) "]]>" *(Char - ("<" / "&")))
$xml_re{CharData} = qr/(?:(?!\]\]>)[^<&])*/s;
$xml_re{__CharDataP} = qr/(?:(?!\]\]>)[^<&])+/s;
# [15] Comment = "<!--" *((Char - "-") / ("-" (Char - "-")))) "-->"
$xml_re{Comment_M} = qr/<!--((?:(?!--).)*)-->/s;
# [16] PI = "<?" PITarget [S (*Char - (*Char "?>" *Char))] "?>"
$xml_re{PI_M} = qr/<\?($xml_re{Name})(?:$xml_re{s}((?:(?!\?>).)*))?\?>/s;
# [17] PITarget = Name - "xml"
# [18] CDSect = CDStart CData CDEnd
# [19] CDStart = '<![CDATA['
# [20] CDATA = (*Char - (*Char "]]>" *Char))
# [21] CDEnd = "]]>"
$xml_re{CDSect_M} = qr/<!\[CDATA\[((?:(?!\]\]>).)*)\]\]>/s;
# [22] prolog = [XMLDecl] *Misc [doctypedecl *Misc]
# [23] XMLDecl = '<?xml' VersionInfo [EncodingDecl] [SDDecl] [S] "?>"
# [24] VersionInfo = S 'version' Eq ("'" VersionNum "'" / <"> VersionNum <">)
# [25] Eq = [S] "=" [S]
# [26] VersionNum = 1*(ALPHA / DIGIT / "_" / "." / ":" / "-")    ;; 1.0 FE & 1.0 SE
# [26] VersionNum = "1.0"                                        ;; 1.0 SE-errata
# [26] VersionNum = "1.1"                                        ;; 1.1
# [27] Misc = Comment / PI / S
# [28] doctypedecl = '<!DOCTYPE' S Name [S ExternalID] [S]
#                    ["[" *(markupdecl / PEReference / S) "]" [S]] ">"    ;; 1.0 FE
# [28] doctypedecl = '<!DOCTYPE' S Name [S ExternalID] [S] ["[" *(markupdecl / DeclSep) "]" [S]] ">"
#                                                                         ;; 1.0 FE-errata & 1.0 SE
# [28] doctypedecl = '<!DOCTYPE' S Name [S ExternalID] [S] ["[" intSubset "]" [S]] ">"
#                                                                         ;; 1.0 SE-errata
$xml_re{__doctypedecl_start_simple_M} = qr/(<!DOCTYPE$xml_re{s})($xml_re{Name})($xml_re{s}SYSTEM$xml_re{s}$xml_re{__AttValue_simple}|$xml_re{s}PUBLIC$xml_re{s}$xml_re{__AttValue_simple}$xml_re{s}$xml_re{__AttValue_simple})?/s;
# [28a] DeclSep = PEReference / S                                         ;; 1.0 FE-errata & 1.0 SE
# [28b] intSubset = *(markupdecl / DeclSep)                               ;; 1.0 SE-errata
# [29] markupdecl = elementdecl / AttlistDecl / EntityDecl / NotationDecl / PI / Comment
# [30] extSubset = [TextDecl] extSubsetDecl
# [31] extSubsetDecl = *(markupdecl / conditionalSect / PEReference / S)  ;; 1.0 FE
# [31] extSubsetDecl = *(markupdecl / conditionalSect / DeclSep)          ;; 1.0 FE-errata & 1.0 SE
# [32] SDDecl = S 'standalone' Eq ("'" ('yes' / 'no') "'" / <"> ('yes' / 'no') <">)
# [33] LanguageID = Langcode *("-" Subcode)               ;; 1.0 FE (removed by 1.0 SE)
# [34] Langcode = ISO639Cocde / IanaCode / UserCode       ;; 1.0 FE (ditto)
# [35] ISO639Code = 2ALPHA                                ;; 1.0 FE (ditto)
# [36] IanaCode = "i-" 1*ALPHA                            ;; 1.0 FE (ditto)
# [37] UserCode = "x-" 1*ALPHA                            ;; 1.0 FE (ditto)
# [38] Subcode = 1*ALPHA                                  ;; 1.0 FE (ditto)
# [39] element = EmptyElemTag / STag content ETag
# [40] STag = "<" Name *(S Attribute) [S] ">"
# [41] Attribute = Name Eq AttValue
$xml_re{Attribute} = qr/$xml_re{Name}(?:$xml_re{s})?=(?:$xml_re{s})?$xml_re{__AttValue_simple}/s;
$xml_re{Attribute_M} = qr/($xml_re{Name})(?:$xml_re{s})?=(?:$xml_re{s})?($xml_re{__AttValue_simple})/s;
$xml_re{STag} = qr/<$xml_re{Name}(?:$xml_re{s}$xml_re{Attribute})*(?:$xml_re{s})?>/s;
# [42] ETag = "</" Name [S] ">"
$xml_re{ETag_M} = qr!</($xml_re{Name})(?:$xml_re{s})?>!s;
# [43] content = *(element / CharData / Reference / CDSect / PI / Comment) ;; 1.0 FE
# [43] content = [CharData] *((element / Reference / CDSect / PI / Comment) [CharData])
#                ;; 1.0 FE-errata & 1.0 SE
# [44] EmptyElemTag = "<" Name *(S Attribute) [S] "/>"
$xml_re{__STag_or_EmptyElemTag} = qr!<$xml_re{Name}(?:$xml_re{s}$xml_re{Attribute})*(?:$xml_re{s})?/?>!s;
$xml_re{__STag_or_EmptyElemTag_simple} = qr!<$xml_re{ame}(?:$xml_re{s}|$xml_re{Name}|$xml_re{__AttValue_simple}|=)*/?>!s;
# [45] elementdecl = '<!ELEMENT' S Name S contentspec [S] ">"
# [46] contentspec = 'EMPTY' / 'ANY' / Mixed / children
$xml_re{__contentspec_simple} = qr/(?:$xml_re{Name}|\#PCDATA|[()|,?*+]|$xml_re{s})/s;
# [47] children = (choice / seq) ["?" / "*" / "+"]
# [48] cp = (Name / choice / seq) ["?" / "*" / "+"]
# [49] choice = "(" [S] cp *([S] "|" [S] cp) [S] ")"    ;; 1.0 FE
# [49] choice = "(" [S] cp 1*([S] "|" [S] cp) [S] ")"   ;; 1.0 FE-errata & 1.0 SE
# [50] seq = "(" [S] cp *([S] "," [S] cp) [S] ")"
# [51] Mixed = "(" [S] '#PCDATA' *([S] "|" [S] Name) [S] ")*"
#            / "(" [S] '#PCDATA' [S] ")"
#$xml_re{seq} = qr/\($xml_re{cp}(?:(?:$xml_re{s})?,(?:$xml_re{s})?$xml_re{cp})*(?:$xml_re{s})?\)/;
#$xml_re{cp} = qr/(?:$xml_re{Name}|$xml_re{choice}|$xml_re{seq})[?*+]/;
#$xml_re{choice} = qr/\($xml_re{cp}(?:(?:$xml_re{s})?\|(?:$xml_re{s})?$xml_re{cp})+(?:$xml_re{s})?\)/;
#$xml_re{children} = qr/(?:$xml_re{choice}|$xml_re{seq})[?*+]/;
#$xml_re{Mixed} = qr/(?:\((?:$xml_re{s})?\#PCDATA(?:$xml_re{s})?(?:(?:$xml_re{s})?|(?:$xml_re{s})?$xml_re{Name})*(?:$xml_re{s})?\)|\((?:$xml_re{s})?\#PCDATA(?:$xml_re{s})?\))/;
#$xml_re{contentspec} = qr/(?:EMPTY|ANY|$xml_re{Mixed}|$xml_re{children})/;
# [52] AttlistDecl = '<!ATTLIST' S Name *AttDef [S] ">"
# [53] AttDef = S Name S AttType S DefaultDecl
# [54] AttType = StringType / TokenizedType / EnumeratedType
# [55] StringType = 'CDATA'
# [56] TokenizedType = 'ID' / 'IDREF' / 'IDREFS' / 'ENTITY' / 'ENTITIES' / 'NMTOKEN' / 'NMTOKENS'
# [57] EnumeratedType = NotationType / Enumeration
# [58] NotationType = 'NOTATION' S "(" [S] Name *([S] "|" [S] Name) [S] ")"
# [59] Enumeration = "(" [S] Nmtoken *([S] "|" [S] Nmtoken) [S} ")"
# [60] DefaultDecl = '#REQUIRED' / '#IMPLIED' / ['#FIXED' S] AttValue
# [61] conditionalSect = includeSect / ignoreSect
# [62] includeSect = "<![" [S} 'INCLUDE' [S] "[" extSubsetDecl "]]>"
# [63] ignoreSect = "<![" [S] 'IGNORE' [S] "[" *ignoreSectContents "]]>"
# [64] ignoreSectContents = Ignore *("<![" ignoreSectContents "]]>" Ignore)
# [65] Ignore = *Char - (*Char ("<![" / "]]>") *Char)
# [66] CharRef = '&#' 1*DIGIT ";" / '&#x' 1*HEXDIGIT ";"
$xml_re{CharRef} = qr/&#[0-9]+;|&#x[0-9A-Fa-f]+;/;
# [67] Reference = EntityRef / CharRef
# [68] EntityRef = "&" Name ";"
$xml_re{EntityRef} = qr/&$xml_re{Name};/;
$xml_re{EntityRef_M} = qr/&($xml_re{Name});/;
$xml_re{Reference} = qr/$xml_re{EntityRef}|$xml_re{CharRef}/;
$xml_re{AttValue} = qr/"(?:$xml_re{Reference}|[^&<"])*"|'(?:$xml_re{Reference}|[^&<'])*'/s;
# [69] PEReference = "%" Name ";"
$xml_re{PEReference} = qr/%(?:$xml_re{Name});/;
$xml_re{PEReference_M} = qr/%($xml_re{Name});/;
$xml_re{__elementdecl_simple} = qr/<!ELEMENT(?:$xml_re{s}|$xml_re{PEReference}|$xml_re{Name}|\#PCDATA|[()|,?*+])+>/s;
$xml_re{__AttlistDecl_simple} = qr/<!ATTLIST(?:$xml_re{PEReference}|$xml_re{Name}|\#$xml_re{Name}|$xml_re{s}|$xml_re{__AttValue_simple})*>/s;
# [70] EntityDecl = GEDecl / PEDecl
$xml_re{__EntityDecl_simple} = qr/<!ENTITY(?:$xml_re{__AttValue_simple}|[^"'>])*>/s;
# [71] GEDecl = '<!ENTITY' S Name S EntityDef [S] ">"
# [72] PEDecl = '<!ENTITY' S "%" S Name S PEDef [S] ">"
# [73] EntityDef = EntityValue / ExternalID [NDataDecl]
# [74] PEDef = EntityValue / ExternalID
# [75] ExternalID = 'SYSTEM' S SystemLiteral / 'PUBLIC' S PublicLiteral S SystemLiteral
# [76] NDataDecl = S 'NDATA' S Name
# [77] TextDecl = '?xml' [VersionInfo] EncodingDecl [S] "?>"
# [78] extParsedEnt = [TextDecl] content
# [79] extPE  ;; 1.0 FE (removed by errata)
# [80] EncodingDecl = S 'encoding' Eq (<"> EncName <"> / "'" EncName "'")
# [81] EncName = ALPHA *(ALPHA / DIGIT / "." / "_" / "-")
# [82] NotationDecl = '<!NOTATION' S Name S (ExternalID / PublicID) [S] ">"
$xml_re{__NotationDecl_simple} = qr/<!NOTATION(?:$xml_re{__AttValue_simple}|[^"'>])*>/s;
# [83] PublicID = 'PUBLIC' S PubidLiteral
# [84] Letter = BaseChar / Ideographic
# [85] Basechar = ...
# [86] Ideographic = ...
# [87] CombiningChar = ...
# [88] Digit = ...
# [89] Extender = U+00B7 / U+02D0 / U+02D1 / U+0387 / U+0640 / U+0E46 / U+0EC6
#               / U+3005 / U+3031-U+3035 / U+309D / U+309E / U+30FC-U+30FE
## [84]-[89] removed by 1.1

# [XMLNames]
# [1] NSAttName = PrefixedAttName / DefaultAttName
# [2] PrefixedAttName = 'xmlns:' NCName
# [3] DefaultAttName = 'xmlns'
# [4] NCName = (Letter / "_") *NCNameChar     ;; 1.0
# [4] NCName = NCNameStartChar *NCNameChar    ;; 1.1
# [5] NCNameChar = Letter / Digit / "." / "-" / "_" / CombiningChar / Extender ;; 1.0
# [5] NCNameChar = NameChar - ":"             ;; 1.1
# [5a] NCNameStartChar = NameStartChar - ":"  ;; 1.1
# [6] QName = [Prefix ":"] LocalPart          ;; 1.0
# [6] QName = PrefixedName / UnprefixedName   ;; 1.1
# [6a] PrefixedName = Prefix ":" LocalPart    ;; 1.1
# [6b] UnprefixedName = LocalPart             ;; 1.1
# [7] Prefix = NCName
# [8] LocalPart = NCName
# [9] STag = "<" QName *(S Attribute) [S] ">"
$xml_re{__NCSTag} = qr/<$xml_re{QName}(?:$xml_re{s}$xml_re{Attribute})*(?:$xml_re{s})?>/s;
# [10] ETag = "</" QName [S] ">"
$xml_re{__NCETag} = qr!</$xml_re{QName}(?:$xml_re{s})?>!s;
# [11] EmptyElemTag = "<" QName *(S Attribute) [S] "/>"
# [12] Attribute = NSAttName Eq AttValue / QName Eq AttValue
# [13] doctypedecl = '<!DOCTYPE' S QName [S ExternalID] [S]
#      ["[" *(markupdecl / PEReference / S) "]" [S]] ">"
# [14] elementdecl = '<!ELEMENT' S QName S contentspec [S] ">"
# [15] cp = (QName / choice / sep) ["?" / "*" / "+"]
# [16] Mixed = "(" [S] '#PCDATA' *([S] "|" [S] QName) [S] ")*" / "(" [S] '#PCDATA' [S] ")"
# [17] AttlistDecl = '<!ATTLIST' S QName *AttDef [S] ">"
# [18] AttDef = S (QName / NSAttName) S AttType S DefaultDecl
# [19] Name = NameStartChar *NameChar  ;; 1.1 draft
# [20] NameChar = {XML1.1}.NameChar    ;; 1.1 draft
# [21] NameStartChar = {XML1.1}.NameStartChar ;; 1.1 draft


sub new ($) {
  bless {}, shift;
}

sub parse_text ($$;$) {
  my $self = shift;
  my $s = shift;
  my $o = shift || {line => 0, pos => 0, entity_type => ''};
  my $r = SuikaWiki::Markup::XML->new (type => '#document');
  my $c = $r;
  ## NOTE: Even if there are more than one non-XML-Char, error is raised only one time.
  $self->_warn_char_val ($self->_make_clone_of ($o), $s);
  if ($s =~ s/^$xml_re{PI_M}//s && $1 eq 'xml') {	# <?xml?>
    my ($data, $all) = ($2, $&);
      _count_lp ('<?xml', $o);
      if (length ($data)) {
        $self->_parse_xml_declaration ($c->append_new_node (type => '#pi', local_name => 'xml'), $data, $o);
      } else {
        $self->_raise_error ($o, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
      }
      _count_lp ('?>', $o);
  }
  while ($s) {
    if ($s =~ /^$xml_re{__STag_or_EmptyElemTag_simple}/s) {	# <element/>
      $o->{entity_type} ||= 'document_entity';
      if ($o->{entity_type} eq 'document_entity'
       || $o->{entity_type} eq 'external_general_parsed_entity') {
        $self->_parse_element_content ($c, \$s, $o);
      } else {
        $self->_raise_error ($o, p => $c, type => 'SYNTAX_INVALID_POSITION', t => $&);
      }
    } elsif ($s =~ s/^$xml_re{s}//s) {	# s
      $c->append_text ($&);
      _count_lp ($&, $o);
    } elsif ($s =~ s/^$xml_re{__doctypedecl_start_simple_M}//s) {	# <!DOCTYPE>
      my ($d, $name, $extid) = ($1, $2, $3);
      $o->{entity_type} ||= 'document_entity';
      if ($o->{entity_type} ne 'document_entity') {
        $self->_raise_error ($o, p => $c, type => 'SYNTAX_INVALID_POSITION', t => '<!DOCTYPE');
      }
    my $D = $c->append_new_node (type => '#declaration', namespace_uri => $NS{SGML}.'doctype');
    $D->flag (p_o_start => $self->_make_clone_of ($o));
    $D->set_attribute (qname => $name);
    _count_lp ($d.$name, $o);
    if ($extid =~ s/^$xml_re{s}SYSTEM$xml_re{s}//s) {
      $D->set_attribute (SYSTEM => substr ($extid, 1, length ($extid) - 2));
      _count_lp ($extid, $o);
    } elsif ($extid =~ s/^($xml_re{s}PUBLIC$xml_re{s})($xml_re{__AttValue_simple})//s) {
      _count_lp ($1.'"', $o);
      my $pubid = substr ($2, 1, length ($2) - 2);
      if ($pubid =~ /^($xml_re{PubidChar})*($xml_re{__non_PubidChar})/s) {
        _count_lp ($1, $o);
        _raise_fatal_error ($o, desc => 'INVALID_PUBID_CHAR', t => $2);
      } else {
        $D->set_attribute (PUBLIC => $pubid);
        _count_lp ($pubid.'"'.$extid, $o);
      }
      $extid =~ s/^$xml_re{s}//s;
      $D->set_attribute (SYSTEM => substr ($extid, 1, length ($extid) - 2));
    }
    _count_lp ($1, $o) if $s =~ s/^($xml_re{s})//s;
    if ($s =~ s/^\[//s) {
      _count_lp ('[', $o);
      $self->_parse_dtd ($D, \$s, $o, return_with_dsc => 1, validate_ndata => 1);
    } elsif ($s =~ s/^>//s) {
      _count_lp ('>', $o);
    } else {
      _raise_fatal_error ($o, desc => 'INVALID_DECLARE_SYNTAX', t => substr ($s, 0, 1));
      substr ($s, 0, 1) = '';
    }
      $self->_parse_element_content ($c, \$s, $o);
    } elsif ($s =~ s/^$xml_re{PI_M}//s) {	# <?pi?>
      my ($target, $data, $all) = ($1, $2, $&);
      if ($target eq 'xml') {
        _raise_fatal_error ($o, desc => 'INVALID_XML_DECLARE');
      } else {
        $c->append_new_node (type => '#pi', local_name => $1, value => $2);
        _count_lp ($all, $o);
      }
    } elsif ($s =~ s/^$xml_re{Comment_M}//s) {	# <!-- -->
      $c->append_new_node (type => '#comment', value => $1);
      _count_lp ($&, $o);
    } elsif ($s =~ /^<![A-Z]/) {	# <!DECLARATION>
      $o->{entity_type} ||= 'dtd_external_subset';
      $self->_parse_dtd ($c, \$s, $o, validate_ndata => 1);
    ## TODO: ext.general parsed entity
    } else {
      $self->_raise_error ($o, p => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($s, 0, 1));
      substr ($s, 0, 1) = '';
    }
  }
  wantarray ? ($r, $o) : $r;
}

sub _uri_escape ($$) {
  shift;
  my $s = shift;	## TODO: support utf8 flag
  $s =~ s/([^0-9A-Za-z_.-])/sprintf '%%%02X', ord $1/ge;
  $s;
}

sub _make_clone_of ($$;%) {
  my ($self, $mother, %o) = @_;
  if (ref $mother eq 'HASH') {
    my $child = {};
    $o{m_vs_c}->{$mother} = $child;
    for (keys %$mother) {
      if (ref $mother->{$_}) {
        $child->{$_} = $o{m_vs_c}->{$mother->{$_}} || $self->_make_clone_of ($mother->{$_});
      } else {
        $child->{$_} = $mother->{$_};
      }
    }
    return $child;
  } else {
    ## BUG: not supported
  }
}

sub _count_lp ($$) {
  my ($s, $o) = @_;
  $s =~ s/[^\x0A\x0D]*(?:\x0D\x0A?|\x0A)/$o->{line}++;$o->{pos}=0;''/ges;
  $o->{pos} += length $s;
}
sub _ns_parse_qname ($) {
  my $qname = shift;
  if ($qname =~ /:/) {
    return split /:/, $qname, 2;
  } else {
    return (undef, $qname);
  }
}

sub _parse_element_content ($$\$$) {
  my ($self, $c, $s, $o) = @_;
  my $c_initial = overload::StrVal ($c);
  my $entMan;
  while ($$s) {
    if ($$s =~ s/^($xml_re{__STag_or_EmptyElemTag_simple})//s) {
      my ($stag) = ($1);
      if ($c->node_type eq '#document'
       && $self->_is_brother_of_root_element ($c)) {
          $self->_raise_error ($o, p => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT', t => $stag);
      }
      ## Parse element type name
      $stag =~ s/^<($xml_re{Name})//s;
      my ($prefix, $lname) = _ns_parse_qname ($1);	## TODO: invalid qname valid name
      $c = $c->append_new_node (local_name => $lname);
      $c->flag (p_original_qname => $1);
      $c->flag (p_o_start => $self->_make_clone_of ($o));
      _count_lp ($&, $o);
      ## Parse attributes
      $stag =~ s/>$//;
      my $etag = 0;
      if ($stag =~ s!/$!!) {	# empty element
        $c->option (use_EmptyElemTag => 1);
        $etag = 1;
      }
      $self->_parse_attribute_spec_list ($c, $stag, $o) if $stag;
      _count_lp (($etag ? '/>' : '>'), $o);
      ## Parse element type name (namespace)
      my $uri = $c->defined_namespace_prefix ($prefix || '');
      if (defined $uri) {
        $c->namespace_uri ($uri);
      } elsif (!$prefix) {	## Default NS
        #$c->namespace_uri ('');
        $c->define_new_namespace ('' => '');
      } else {
        my $o_etypename = $self->_make_clone_of ($c->flag ('p_o_start'));
        $o_etypename->{pos}++;	# '<'
        $self->_raise_error ($o_etypename, type => 'NC_PREFIX_NOT_DEFINED', t => $prefix);
        my $uri = $NS{internal_ns_invalid}.$self->_uri_escape ($prefix);
        $c->namespace_uri ($uri);
        $c->define_new_namespace ($prefix => $uri);
      }
      ## Ending the element if EmptyElemTag
      if ($etag) {
        $c = $c->{parent};
      }
    } elsif ($$s =~ s/^$xml_re{ETag_M}//s) {
      my $ename = $1;
      if ($ename eq $c->flag ('p_original_qname') || $ename eq $c->qname) {
        $c = $c->{parent};
      } else {	## Element type name does not match
        my $o_etn = $self->_make_clone_of ($o);
        $o_etn->{pos} += 2;
        $self->_raise_error ($o_etn, p => $c, type => 'WFC_ELEMENT_TYPE_MATCH', t => [$ename, $c->qname]);
      }
      _count_lp ($&, $o);
    } elsif (($c->node_type eq '#document') && ($$s =~ s/^$xml_re{s}//s)) {
      $c->append_text ($&);
      _count_lp ($&, $o);
    } elsif ($$s =~ s/^$xml_re{__CharDataP}//s) {
      if ($c->node_type eq '#document') {
        $self->_raise_error ($o, p => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT', t => $&);
      }
      $c->append_text ($&);
      _count_lp ($&, $o);
    } elsif ($$s =~ s/^($xml_re{Reference})//s) {	## &foo; | &#1234; | &#x12AB;
      if ($c->node_type eq '#document') {
        if ($self->_is_brother_of_root_element ($c)) {
          $self->_raise_error ($o, p => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT', t => $1);
        }
      }
      my $entity_ref = $1;
      my $eref = $self->_parse_reference ($c, $entity_ref, $o);
      if ($eref->{namespace_uri} !~ 'char') {
        $entMan ||= $c->_get_entity_manager;
        my $entity = $entMan->get_entity ($eref, dont_use_predefined_entities => 1);
        if (!$entity && {qw/&lt; 1 &gt; 1 &amp; 1 &quot; 1 &apos; 1/}->{$entity_ref}) {
          $self->_raise_error ($o, c => $c, type => 'WARN_PREDEFINED_ENTITY_NOT_DECLARED',
                               t => $entity_ref);
          $entity = $entMan->get_entity ($eref);
        }
        if (!$entity) {
          $self->_raise_error ($o,
                          type => ($entMan->is_standalone_document_1?'WF':'V').'C_ENTITY_DECLARED',
                          t => $entity_ref);
        } else {
          my $o2 = $self->_make_clone_of ($o);
          if ($o2->{__entities}->{$entity_ref}) {
            $self->_raise_error ($o, type => 'WFC_NO_RECURSION', t => $entity_ref);
          } else {
            my $entity_value = $entity->get_attribute ('value');
            ## TODO: support external entity
            if (ref $entity_value) {
              $o2->{__entities}->{$entity_ref} = 1;
              $o2->{entity} = $entity_ref; $o2->{line} = 0; $o2->{pos} = 0;
              my $ev = $entity_value->_entity_parameter_literal_value;
              $self->_parse_element_content ($eref, \$ev, $o2);
              $eref->flag (smxp__ref_expanded => 1);
            } else {	## External non-parsed entity
              $self->_raise_error ($o, type => 'WFC_NO_EXTERNAL_ENTITY_REFERENCE', t => $entity_ref);
            }
          }
        }
      }	# if &foo;
    } elsif ($$s =~ s/^$xml_re{CDSect_M}//s) {
      if ($c->node_type eq '#document') {
        if ($self->_is_brother_of_root_element ($c)) {
          $self->_raise_error ($o, p => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT', t => '<![');
        }
      }
      $c->append_new_node (type => '#section', namespace_uri => $NS{SGML}.'section:cdata', value => $1);
      _count_lp ($&, $o);
    } elsif ($$s =~ s/^$xml_re{Comment_M}//s) {
      $c->append_new_node (type => '#comment', value => $1);
      _count_lp ($&, $o);
    } elsif ($$s =~ s/^$xml_re{PI_M}//s) {
      my ($target, $data, $all) = ($1, $2, $&);
      if ($target eq 'xml') {
        if ($c->node_type eq '#document' && $c->count == 0) {
          _count_lp ('<?xml', $o);
          if (length ($data)) {
            $self->_parse_xml_declaration ($c->append_new_node (type => '#pi', local_name => 'xml'), $data, $o);
          } else {
            $self->_raise_error ($o, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
          }
          _count_lp ('?>', $o);
        } else {
          _raise_fatal_error ($o, desc => 'INVALID_XML_DECLARE');
        }
      } else {
        $c->append_new_node (type => '#pi', local_name => $1, value => $2);
        _count_lp ($all, $o);
      }
    } else {
      $self->_raise_error ($o, p => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 1));
      substr ($$s, 0, 1) = '';
    }
  }	# while $s
  while ($c_initial ne overload::StrVal ($c)) {
    if (ref $c->{parent}) {
      if ($c->node_type eq '#element') {
        $self->_raise_error ($o, type => 'SYNTAX_END_TAG_NOT_FOUND', t => $c);
      }
      $c = $c->{parent};
    } else {
      last;
    }
  }
}

sub _parse_dtd ($$\$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  my $c_initial = overload::StrVal ($c);
  my $entMan;
  while ($$s) {
    if ($$s =~ s/^$xml_re{PEReference_M}//s) {
      my $ename = $1;
      if (index ($ename, ':') > -1) {
        $self->_raise_error ($o, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => '%'.$ename.';');
      }
      $entMan ||= $c->_get_entity_manager;
      my $entity = $entMan->get_entity ($ename, namespace_uri => $NS{SGML}.'entity:parameter');
      my $eref = $c->append_new_node (type => '#reference', local_name => $ename,
                                      namespace_uri => $NS{SGML}.'entity:parameter');
      if (!$entity) {	## TODO: if internal subset, flag
        $self->_raise_error ($o, type => 'VC_ENTITY_DECLARED', t => '%'.$ename.';');
      } else {
        my $o2 = $self->_make_clone_of ($o);
        if ($o2->{__entities}->{'%'.$ename.';'}) {
          $self->_raise_error ($o, type => 'WFC_NO_RECURSION', t => '%'.$ename.';');
        } else {
          my $entity_value = $entity->get_attribute ('value');
          ## TODO: support external entity
          if (ref $entity_value) {
            $o2->{__entities}->{'%'.$ename.';'} = 1;
            $o2->{entity} = '%'.$ename.';'; $o2->{line} = 0; $o2->{pos} = 0;
            my $ev = $entity_value->entity_value; $ev = substr ($ev, 1, length ($ev) - 2);
            $self->_parse_dtd ($eref, \$ev, $o2);
            $eref->flag (smxp__ref_expanded => 1);
          } else {
            $self->_raise_error ($o, type => 'UNKNOWN', t => '%'.$ename.';');
          }
        }	# not recursive
      }	# entity defined
      _count_lp ($ename.'%;', $o);
    } elsif ($$s =~ s/^$xml_re{s}//s) {
      $c->append_text ($&);
      _count_lp ($&, $o);
    } elsif ($$s =~ s/^$xml_re{Comment_M}//s) {
      $c->append_new_node (type => '#comment', value => $1);
      _count_lp ($&, $o);
    } elsif ($$s =~ s/^($xml_re{__EntityDecl_simple})//s) {
      $self->_parse_entity_declaration ($1, $c, $o);
    } elsif ($$s =~ s/^($xml_re{__elementdecl_simple})//s) {
      $self->_parse_element_declaration ($1, $c, $o);
    } elsif ($$s =~ s/^($xml_re{__AttlistDecl_simple})//s) {
      $self->_parse_attlist_declaration ($1, $c, $o);
    } elsif ($opt{return_with_dsc} && $$s =~ s/^\](?:$xml_re{s})?>//s) {
      _count_lp ($&, $o);
      $c = $c->{parent};
      last;
    } elsif ($$s =~ s/^($xml_re{__NotationDecl_simple})//s) {
      $self->_parse_entity_declaration ($1, $c, $o);
    } elsif ($$s =~ s/^$xml_re{PI_M}//s) {
      my ($target, $data, $all) = ($1, $2, $&);
      if ($target eq 'xml') {
        if ($c->node_type eq '#document' && $c->count == 0) {
          _count_lp ('<?xml', $o);
          if (length ($data)) {
            $self->_parse_xml_declaration ($c->append_new_node (type => '#pi', local_name => 'xml'), $data, $o);
          } else {
            $self->_raise_error ($o, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
          }
          _count_lp ('?>', $o);
        } else {
          _raise_fatal_error ($o, desc => 'INVALID_XML_DECLARE');
        }
      } else {
        $c->append_new_node (type => '#pi', local_name => $1, value => $2);
        _count_lp ($all, $o);
      }
    } else {
      $self->_raise_error ($o, p => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 1));
      substr ($$s, 0, 1) = '';
      _count_lp (' ', $o);
    ## TODO: markup section
    }
  }	# while $$s
  while ($c_initial ne overload::StrVal ($c)) {
    if (ref $c->{parent}) {
      $self->_raise_error ($o, type => 'SYNTAX_END_OF_MARKUP_NOT_FOUND', t => $c);
      $c = $c->{parent};
    } else {
      last;
    }
  }	# while
  if ($opt{validate_ndata}) {
    my $l = [];
    my $entMan = $c->_get_entity_manager;
    $entMan->get_entities ($l, namespace_uri => $NS{SGML}.'entity');
    my %defined;
    for my $ent (@$l) {
      for ($ent->get_attribute ('NDATA')) {
      if (ref $_) {
        my $nname = $_->inner_text;
        if ($defined{$nname} > 0
         || $entMan->get_entity ($nname, namespace_uri => $NS{SGML}.'notation')) {
          $defined{$nname} = 1;
        } else {
          $self->_raise_error ($_->flag ('smxp__src_pos'), type => 'VC_NOTATION_DECLARED',
                               t => $nname, c => $_);
          $defined{$nname} = -1;
        }
      }}	# NDATA exist
    }
  }
}


sub _parse_attribute_spec_list ($$$$) {
  my ($self, $c, $attrs, $o) = @_;
  my @attrs;
  my (%defined_attr, %defined_ns_attr);
  my $no_s = 0;
  while ($attrs) {
    if (!$no_s && $attrs =~ s/^$xml_re{Attribute_M}//s) {
      my ($qname, $qvalue) = ($1, $2);
      my ($prefix, $name) = _ns_parse_qname ($qname);
      push @attrs, {prefix => $prefix, lname => $name, qvalue => $qvalue, qname => $qname,
                    o => {line => $o->{line}, pos => ($o->{pos} + length ($&) - length ($qvalue))},
                    o_attr_start => {line => $o->{line}, pos => $o->{pos}}};
      _count_lp ($&, $o);
      $no_s = 1;
    } elsif ($attrs =~ s/^($xml_re{s})//s) {
      _count_lp ($1, $o);
      $no_s = 0;
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($attrs, 0, 1));
      substr ($attrs, 0, 1) = '';
      $no_s = 1;
    }
  }
  for (grep {($_->{prefix} eq 'xmlns') || (!$_->{prefix} && ($_->{lname} eq 'xmlns'))} @attrs) {
    my $value = SuikaWiki::Markup::XML->new (type => '#text');
    _count_lp ('"', $_->{o});
    my $av = substr ($_->{qvalue}, 1, length ($_->{qvalue}) - 2);
    $self->_parse_attribute_value ($value, \$av, $_->{o});
    _count_lp ('"', $_->{o});
    if (!$defined_attr{$_->{qname}}) {
      if ($_->{prefix} eq 'xmlns') {
        $c->define_new_namespace ($_->{lname} => $value);	# BUG: Reference
      } else {
        $c->define_new_namespace ('' => $value);	# BUG: Reference
      }
      $defined_attr{$_->{qname}} = 1;
    } else {	## Already defined
      $self->_raise_error ($_->{o_attr_start}, type => 'WFC_UNIQUE_ATT_SPEC', t => $_->{qname});
      my $attr;
      if ($_->{prefix} eq 'xmlns') {
        $attr = $c->set_attribute ($_->{lname} => '', namespace_uri => $NS{internal_attr_duplicate}.'xmlns');
      } else {	## BUG: xmlns="" (1.1)
        $attr = $c->set_attribute (xmlns => '', namespace_uri => $NS{internal_attr_duplicate});
      }
      $attr->append_node ($value);
    }
  }
  for (grep {($_->{prefix} ne 'xmlns') && !(!$_->{prefix} && ($_->{lname} eq 'xmlns'))} @attrs) {
    my $attr;
    my $uri; $uri = $c->defined_namespace_prefix ($_->{prefix}) if $_->{prefix};
    if ($defined_attr{$_->{qname}}) {	## Already-defined-attr is found
      $self->_raise_error ($_->{o_attr_start}, type => 'WFC_UNIQUE_ATT_SPEC', t => $_->{qname});
      $uri = $NS{internal_attr_duplicate} . $defined_attr{$_->{qname}};
      $_->{prefix} = 'dup.' . $defined_attr{$_->{qname}} . ($_->{prefix} ? '.'.$_->{prefix}:'');
      $c->define_new_namespace ($_->{prefix} => $uri);
      $defined_attr{$_->{qname}}++;
    } elsif (defined $uri && $defined_ns_attr{$_->{lname}.':'.$uri}) {
    ## ns:attr="a" ns2:attr="b" xmlns:ns="ns" xmlns:ns2="ns"
      $self->_raise_error ($_->{o_attr_start}, type => 'NC_unique_att_spec', t => $_->{qname});
      my $i = $defined_ns_attr{$_->{lname}.':'.$uri}++;
      $uri = $NS{internal_attr_duplicate} . 'ns.' . $i;
      $_->{prefix} = 'dup.ns.' . $i . ($_->{prefix} ? '.'.$_->{prefix}:'');
      $c->define_new_namespace ($_->{prefix} => $uri);
    } else {
      $defined_attr{$_->{qname}} = 1;
      $defined_ns_attr{$_->{lname}.':'.$uri} = 1;
    }
    if ($_->{prefix}) {
      if (defined $uri) {
        $attr = $c->set_attribute ($_->{lname} => '', namespace_uri => $uri);
      } else {
        $self->_raise_error ($o, type => 'NC_PREFIX_NOT_DEFINED', t => $_->{prefix});
        my $uri = $NS{internal_ns_invalid}.$self->_uri_escape ($_->{prefix});
        $attr = $c->set_attribute ($_->{lname} => '', namespace_uri => $uri);
        $c->define_new_namespace ($_->{prefix} => $uri);
      }
    } else {
      $attr = $c->set_attribute ($_->{lname} => '');
    }
    _count_lp ('"', $_->{o});
    my $av = substr ($_->{qvalue}, 1, length ($_->{qvalue}) - 2);
    $self->_parse_attribute_value ($attr, \$av, $_->{o}) if $attr;
    _count_lp ('"', $_->{o});
  }
}

sub _parse_attribute_value ($$\$$) {
  my ($self, $attr, $s, $o) = @_;
  my $entMan;
  while ($$s) {
    if ($$s =~ s/^($xml_re{Reference})//) {
      my $entity_ref = $1;
      my $eref = $self->_parse_reference ($attr, $entity_ref);
      if ($eref->{namespace_uri} !~ 'char') {	## general entity ref.
        $entMan ||= $attr->_get_entity_manager;
        my $entity = $entMan->get_entity ($eref, dont_use_predefined_entities => 1);
        if (!$entity && {qw/&lt; 1 &gt; 1 &amp; 1 &quot; 1 &apos; 1/}->{$entity_ref}) {
          $self->_raise_error ($o, c => $attr, type => 'WARN_PREDEFINED_ENTITY_NOT_DECLARED',
                               t => $entity_ref);
          $entity = $entMan->get_entity ($eref);
        }
        if (!$entity) {
          $self->_raise_error ($o,
                          type => ($entMan->is_standalone_document_1?'WF':'V').'C_ENTITY_DECLARED',
                          t => $entity_ref);
        } else {
          my $o2 = $self->_make_clone_of ($o);
          if ($o2->{__entities}->{$entity_ref}) {
            $self->_raise_error ($o, type => 'WFC_NO_RECURSION', t => $entity_ref);
          } else {
            my $entity_value = $entity->get_attribute ('value');
            if (ref $entity_value) {
              $o2->{__entities}->{$entity_ref} = 1;
              $o2->{entity} = $entity_ref; $o2->{line} = 0; $o2->{pos} = 0;
              my $ev = $entity_value->_entity_parameter_literal_value;
              $self->_parse_attribute_value ($eref, \$ev, $o2);
              $eref->flag (smxp__ref_expanded => 1);
            } else {
              $self->_raise_error ($o, type => 'WFC_NO_EXTERNAL_ENTITY_REFERENCE', t => $entity_ref);
            }
          }
        }
      }
      _count_lp ($entity_ref, $o);
    } elsif ($$s =~ s/^([^&<]+)//) {
      $attr->append_text ($1);
      _count_lp ($1, $o);
    } elsif ($$s =~ s/^<//) {
      $self->_raise_error ($o, type => 'WFC_NO_LE_IN_ATTRIBUTE_VALUE');
      substr ($$s, 0, 1) = '';
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      substr ($$s, 0, 1) = '';
    }
  }
}

sub _parse_rpdata ($$\$$) {
  my ($self, $c, $s, $o) = @_;
  my $entMan;
  while ($$s) {
    if ($$s =~ s/^($xml_re{PEReference_M})//) {
      my ($ref, $ename) = ($1, $2);
      if ($o->{entity_type} eq 'document_entity') {
        $self->_raise_error ($o, type => 'WFC_PE_IN_INTERNAL_SUBSET', t => $ref);
      }
      if (index ($ename, ':') > -1) {
        $self->_raise_error ($o, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ref);
      }
      $entMan ||= $c->_get_entity_manager;
      my $eref = $c->append_new_node (type => '#reference', local_name => $ename,
                                      namespace_uri => $NS{SGML}.'entity:parameter');
      my $entity = $entMan->get_entity ($ename, namespace_uri => $NS{SGML}.'entity:parameter');
      if (!$entity) { ## TODO:
          $self->_raise_error ($o, c => $c,
                            type => 'VC_ENTITY_DECLARED',
                            t => $ref);
      } else {
        my $o2 = $self->_make_clone_of ($o);
        if ($o2->{__entities}->{$ref}) {
          $self->_raise_error ($o, c => $c, type => 'WFC_NO_RECURSION', t => $ref);
        } else {
          my $entity_value = $entity->get_attribute ('value');
          if (ref $entity_value) {
            $o2->{__entities}->{$ref} = 1;
            $o2->{entity} = $ref; $o2->{line} = 0; $o2->{pos} = 0;
            my $ev = $entity_value->entity_value; $ev = substr ($ev, 1, length ($ev) - 2);
            $self->_parse_rpdata ($eref, \$ev, $o2);
          } else {	## External non-parsed entity	## TODO:
            $self->_raise_error ($o, c => $eref, type => 'WFC_NO_EXTERNAL_ENTITY_REFERENCE', t => $ref);
          }
        }
      }
      _count_lp ($1.'%;', $o);
    } elsif ($$s =~ s/^([^%]+)//) {
      my $t = $1; my $r = '';
      while ($t) {
        if ($t =~ s/^&#(?:x([0-9A-Fa-f]+)|([0-9]+));//) {
          my $char = chr ($1 ? hex $1 : 0+$2);
          $self->_warn_char_val ($o, $char, ref => 1);
          $r .= $char;
          _count_lp ($&, $o);
        } elsif ($t =~ s/^(&$xml_re{Name};)//) {
          $r .= $1;
          if (index ($1, ':') > -1) {
            $self->_raise_error ($o, type => 'NS_SYNTAX_NAME_IS_NCNAME', c => $c, t => $1);
          }
          _count_lp ($1, $o);
        } elsif ($t =~ s/^&//) {
          $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', c => $c, t => '&');
          $r .= '&';
          _count_lp ('&', $o);
        } elsif ($t =~ s/^([^&]+)//s) {
          $r .= $1;
          _count_lp ($1, $o);
        }
      }
      $c->append_new_node (type => '#text', value => $r);
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 1));
      substr ($$s, 0, 1) = '';
      _count_lp (' ', $o);
    }
  }
}

sub _parse_markup_declaration_parameters ($$$$$) {
  my ($self, $c, $s, $o, $params) = @_;
  my $entMan;
  while ($$s) {
    if ($$s =~ s/^$xml_re{PEReference_M}//) {
      my $ename = $1;
      if ($o->{entity_type} eq 'document_entity') {	## Internal Subset
        $self->_raise_error ($o, type => 'WFC_PE_IN_INTERNAL_SUBSET', t => $ename);
      }
      if (index ($ename, ':') > -1) {
        $self->_raise_error ($o, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => '%'.$ename.';');
      }
      $entMan ||= $c->_get_entity_manager;
      my $entity = $entMan->get_entity ($ename, namespace_uri => $NS{SGML}.'entity:parameter');
      my $eref = $c->append_new_node (type => '#reference', local_name => $ename,
                                      namespace_uri => $NS{SGML}.'entity:parameter');
      if (!$entity) {
        $self->_raise_error ($o, type => 'VC_ENTITY_DECLARED', t => '%'.$ename.';');
      } else {
        my $o2 = $self->_make_clone_of ($o);
        if ($o2->{__entities}->{'%'.$ename.';'}) {
          $self->_raise_error ($o, type => 'WFC_NO_RECURSION', t => '%'.$ename.';');
        } else {
          my $entity_value = $entity->get_attribute ('value');
          ## TODO: support external entity
          if (ref $entity_value) {
            $o2->{__entities}->{'%'.$ename.';'} = 1;
            $o2->{entity} = '%'.$ename.';'; $o2->{line} = 0; $o2->{pos} = 0;
            push @$params, $c->append_text (' ');
              $$params[$#$params]->flag (smxp__pmdp_type => 'S');
              my $ev = $entity_value->_entity_parameter_literal_value;
              my $o22 = $self->_make_clone_of ($o);
              $$params[$#$params]->flag (smxp__src_pos => $o22);
            $self->_parse_markup_declaration_parameters ($eref, \$ev, $o2, $params);
            push @$params, $c->append_text (' ');
              $$params[$#$params]->flag (smxp__pmdp_type => 'S');
              $$params[$#$params]->flag (smxp__src_pos => $o22);
            $eref->flag (smxp__ref_expanded => 1);
          } else {
            $self->_raise_error ($o, type => 'UNKNOWN', t => '%'.$ename.';');
          }
        }	# not recursive
      }	# entity defined
      $c->flag (smxp__defined_with_param_ref => 1);
      _count_lp ($ename.'%;', $o);
    } elsif ($$s =~ s/^($xml_re{__AttValue_simple})//s) {
      my $all = $1;
      $c->append_new_node (type => '#xml', value => substr ($all, 0, 1));	# lit(a)
      push @$params, $c->append_new_node (type => '#xml', value => substr ($1, 1, length ($all) - 2));
        $$params[$#$params]->flag (smxp__pmdp_type => 'literal');
        $$params[$#$params]->flag (smxp__src_pos => $self->_make_clone_of ($o));
      $c->append_new_node (type => '#xml', value => substr ($all, -1, 1));	# lit(a)
      _count_lp ($all, $o);
    } elsif ($$s =~ s/^($xml_re{Name})//) {
      push @$params, $c->append_text ($1);
        $$params[$#$params]->flag (smxp__pmdp_type => 'Name');
        $$params[$#$params]->flag (smxp__src_pos => $self->_make_clone_of ($o));
      _count_lp ($1, $o);
    } elsif ($$s =~ s/^([%#(),|+?])//) {
      push @$params, $c->append_text ($1);
        $$params[$#$params]->flag (smxp__pmdp_type => 'delimiter');
        $$params[$#$params]->flag (smxp__src_pos => $self->_make_clone_of ($o));
      _count_lp ($1, $o);
    } elsif ($$s =~ s/^($xml_re{s})//s) {
      push @$params, $c->append_text ($1);
        $$params[$#$params]->flag (smxp__pmdp_type => 'S');
        $$params[$#$params]->flag (smxp__src_pos => $self->_make_clone_of ($o));
      _count_lp ($1, $o);
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      substr ($$s, 0, 1) = '';
      _count_lp (' ', $o);
    }
  }	# while
}

sub _warn_char_val ($$$%) {
  my ($self, $o, $ch, %o) = @_;
  if ($ch =~ /(\P{InXMLChar})/) {
    _count_lp ($`, $o);
    $self->_raise_error ($o, type => (($o{ref}?'WFC':'SYNTAX').'_LEGAL_CHARACTER'), t => ord $1);
  } elsif ($ch =~ /(\p{InXML_deprecated_noncharacter})/) {
    _count_lp ($`, $o);
    $self->_raise_error ($o, type => 'WARN_UCS_NONCHARACTER', t => ord $1);
  } elsif ($ch =~ /(\p{Compat})/) {
    _count_lp ($`, $o);
    $self->_raise_error ($o, type => 'WARN_UNICODE_COMPAT_CHARACTER', t => ord $1);
  } elsif ($ch =~ /(\p{InXML_unicode_xml_not_suitable})/) {
    _count_lp ($`, $o);
    $self->_raise_error ($o, type => 'WARN_UNICODE_XML_NOT_SUITABLE_CHARACTER', t => ord $1);
  }
}
sub _parse_reference ($$$$) {
  my ($self, $c, $ref, $o) = @_;
  my $r;
    if ($ref =~ /$xml_re{EntityRef_M}/) {	## BUG: QName
      $r = $c->append_new_node (type => '#reference', local_name => $1,
                                namespace_uri => $NS{SGML}.'entity');
    } elsif ($ref =~ /x([0-9A-Fa-f]+)/) {
      my $ch = hex $1;
      $self->_warn_char_val ($o, chr $ch, ref => 1);
      $r = $c->append_new_node (type => '#reference', value => $ch,
                                namespace_uri => 'urn:x-suika-fam-cx:markup:sgml:char:ref:hex');
    } elsif ($ref =~ /([0-9]+)/) {
      my $ch = 0+$1;
      $self->_warn_char_val ($o, chr $ch, ref => 1);
      $r = $c->append_new_node (type => '#reference', value => $ch,
                                namespace_uri => 'urn:x-suika-fam-cx:markup:sgml:char:ref');
    } else {
      $self->_raise_error ($o, type => 'UNKNOWN', t => $ref);
    }
  _count_lp ($ref, $o);
  $r;
}
sub _parse_xml_declaration ($$$$) {
  my ($self, $c, $attrs, $o) = @_;
  my $stage = 0;	# 0: <?xml, 1: version="", 2: encoding="", 3: standalone="", 4: ?>
  $attrs = ' ' . $attrs;
  while ($attrs) {
    if ($attrs =~ s/^$xml_re{s}version(?:$xml_re{s})?=(?:$xml_re{s})?("[A-Za-z0-9_.:-]+"|'[A-Za-z0-9_.:-]+')//s) {
      my $version = substr ($1, 1, length ($1) - 2);
      if ($stage > 0) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => 'version');
      }
      if ($version eq '1.0') {
        $c->set_attribute (version => $version);
      } else {
        _raise_fatal_error ($o, desc => 'UNSUPPORTED_XML_VERSION', t => $version);
      }
      _count_lp ($&, $o); $stage++;
    } elsif ($attrs =~ s/^$xml_re{s}encoding(?:$xml_re{s})?=(?:$xml_re{s})?("[A-Za-z0-9_.-]+"|'[A-Za-z0-9_.:-]+')//s) {
      if ($stage > 2) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => 'encoding');
      } elsif ($stage == 0) {	## No version pseudo-attr
        if ($o->{entity_type} eq 'document_entity') {
          $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ATTR', t => 'version');
          $c->set_attribute (version => '1.0');
        } else {
          $o->{entity_type} = 'external_parsed_entity';
        }
      }
      $c->set_attribute (encoding => substr ($1, 1, length ($1) - 2));
      _count_lp ($&, $o); $stage = 2;
    } elsif ($attrs =~ s/^$xml_re{s}standalone(?:$xml_re{s})?=(?:$xml_re{s})?("(?:yes|no)"|'(?:yes|no)')//s) {
      if ($stage == 0 || $stage > 3 || $o->{entity_type} eq 'external_parsed_entity'
       || $o->{entity_type} eq 'dtd_external_subset'
       || $o->{entity_type} eq 'general_external_parsed_entity') {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ATTR', t => 'standalone');
      }
      $c->set_attribute (standalone => (substr ($1, 1, 1) eq 'y' ? 'yes' : 'no'));
      _count_lp ($&, $o); $stage = 3;
    } elsif ($attrs =~ s/^($xml_re{s})//s) {
      my $s = $1;
      if ($stage == 0) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
        $c->set_attribute (version => '1.0');
      }
      _count_lp ($s, $o); $stage = 4;
    } else {
      $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => $attrs);
      _count_lp ($attrs, $o); undef $attrs;
    }
  }	# while
  if ($stage == 0) {
    $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
    $c->set_attribute (version => '1.0');
  }
}
sub _parse_entity_declaration ($$$$) {
    my ($self, $all, $c, $o) = @_;
    my $p;	## notation ? 'n' : parameter entity ? '%' : undef;
    my $entMan;
    my $e = $c->append_new_node (type => '#declaration');
    ## Entity/notation type
    if ($all =~ s/^<!ENTITY//s) {
      $e->namespace_uri ($NS{SGML}.'entity');
      _count_lp ($&, $o);
    } elsif ($all =~ s/^<!NOTATION//s) {
      $e->namespace_uri ($NS{SGML}.'notation');
      _count_lp ($&, $o); $p = 'n';
    }
    substr ($all, -1) = '';	# mdc (>)
    my @params;
    $self->_parse_markup_declaration_parameters ($e, \$all, $o, \@params);
    push @params, ref ($e)->new (type => '#text');	## dummy
    shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
    ## Entity/notation name
    if ($p ne 'n' && $params[0]->inner_text eq '%') {	## parameter entity
      shift @params;	# '%'
      $e->namespace_uri ($NS{SGML}.'entity:parameter'); $p = '%';
      if ($params[0]->flag ('smxp__pmdp_type') eq 'S') {
        shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
      } else {	## <!ENTITY %foo...>
        my $part = $params[0];
        $self->_raise_error (($part->flag ('smxp__src_pos')||$o), c => $e,
                             type => 'SYNTAX_INVALID_MD', t => ($part->inner_text||'>'));
      }
    }
    if ($params[0]->flag ('smxp__pmdp_type') ne 'Name') {
      $self->_raise_error ((shift (@params)->flag ('smxp__src_pos') || $o), c => $e,
                           type => 'SYNTAX_MD_NAME_NOT_FOUND');
    } else {	## Name exist
      my $part = shift (@params);
      my $ename = $part->inner_text;
      $entMan ||= $c->_get_entity_manager;
      if ($entMan->get_entity ($ename, namespace_uri => $e->namespace_uri,
                                       dont_use_predefined_entities => 1)) {
        if ($p eq 'n') {
          $self->_raise_error (($part->flag ('smxp__src_pos') || $o), c => $e,
                               type => 'VC_UNIQUE_NOTATION_NAME', t => $ename);
        } else {
          $self->_raise_error (($part->flag ('smxp__src_pos') || $o), c => $e,
                               type => 'WARN_UNIQUE_'.($p eq '%' ? 'PARAMETER_' : '')
                                                     .'ENTITY_NAME', t => $ename);
        }
      }
      if (index ($ename, ':') > -1) {
        $self->_raise_error (($part->flag ('smxp__src_pos') || $o), c => $c,
                             type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ename);
      }
      $e->local_name ($ename);
      if ($params[0]->flag ('smxp__pmdp_type') eq 'S') {
        shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
        my ($extid_type_obj, $extid_type);
        if ($params[0]->flag ('smxp__pmdp_type') eq 'Name') {	# PUBLIC or SYSTEM
          $extid_type_obj = shift (@params);
          $extid_type = $extid_type_obj->inner_text;
          if ($extid_type ne 'PUBLIC' && $extid_type ne 'SYSTEM') {
            $self->_raise_error ($extid_type_obj->flag ('smxp__src_pos'), c => $e,
                                 type => 'SYNTAX_INVALID_KEYWORD', t => $extid_type);
            undef $extid_type;
          }
          if ($params[0]->flag ('smxp__pmdp_type') eq 'S') {
            shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
          } else {	# <!ENTITY PUBLIC>
            $self->_raise_error ($extid_type_obj->flag ('smxp__src_pos'), c => $e,
                                 type => 'SYNTAX_INVALID_KEYWORD', t => $extid_type);
          }
        }
        if ($params[0]->flag ('smxp__pmdp_type') eq 'literal') {
          if ($extid_type eq 'SYSTEM') {	## System ID
          my $sysid = shift (@params)->inner_text;
            $e->set_attribute (SYSTEM => $sysid);
          } elsif ($extid_type eq 'PUBLIC') {	## Public ID
            my $pubid = shift (@params)->inner_text;
            $e->set_attribute (PUBLIC => $pubid);
          } elsif ($p ne 'n') {	## EntityValue (ENTITY only)
            my $part = shift (@params);
            my $vv = $part->inner_text;
            my $o2 = $self->_make_clone_of ($part->flag ('smxp__src_pos')); _count_lp ('"', $o2);
            $self->_parse_rpdata ($e->set_attribute ('value'), \$vv, $o2);
            if (($p ne '%') && {qw/lt 1 gt 1 amp 1 quot 1 apos 1/}->{$ename}) {
              ## TODO: check when external entity
              my $ev = $e->get_attribute ('value')->_entity_parameter_literal_value;
              unless ({qw/lt|&#60;  1 gt|>&#62; 1 amp|&#38;  1 apos|&#39;  1 quot|&#34;  1
                          lt|&#x3c; 1 gt|&#x3e; 1 amp|&#x26; 1 apos|&#x27; 1 quot|&#x22; 1
                                      gt|>      1              apos|'      1 quot|"      1
                         /}->{$ename.'|'.lc ($ev)}) {
                $self->_raise_error ($part->flag ('smxp__src_pos'), c => $e,
                                     type => 'ERR_PREDEFINED_ENTITY', t => [$ename, $ev]);
              }
            }
          } else {
            $self->_raise_error (shift (@params)->flag ('smxp__src_pos'), c => $e,
                                 type => 'SYNTAX_INVALID_LITERAL');
          }
        }	# literal 1
        if ($params[0]->flag ('smxp__pmdp_type') eq 'S') {
          shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
          my $s_exist = 1;
          if ($params[0]->flag ('smxp__pmdp_type') eq 'literal') {
            $s_exist = 0;
            if ($extid_type eq 'PUBLIC') {	## System ID following Public ID
              my $pubid = shift (@params)->inner_text;
              $e->set_attribute (SYSTEM => $pubid);
            } else {
              my $param = shift @params;
              $self->_raise_error ($param->flag ('smxp__src_pos'), c => $e,
                                   type => 'SYNTAX_INVALID_LITERAL', t => $param);
            }
            if ($p ne 'n' && $params[0]->flag ('smxp__pmdp_type') eq 'S') {
              shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
              $s_exist = 1;
            }
          } elsif ($p ne 'n' && $extid_type eq 'PUBLIC') {	## System ID required
            $self->_raise_error (($params[0]->flag ('smxp__src_pos')||$o), c => $e,
                                 type => 'SYNTAX_MD_SYSID_NOT_FOUND');
            $e->set_attribute (SYSTEM => 'http://system.identifier.invalid/');
          }
          ## NDATA (General entity only)
          if ($params[0]->flag ('smxp__pmdp_type') eq 'Name' && $params[0]->inner_text eq 'NDATA') {
            if ($p eq '%') {	## parameter entity
              $self->_raise_error (shift (@params)->flag ('smxp__src_pos'), c => $e,
                                   type => 'SYNTAX_PE_NDATA');
            } elsif (!$extid_type) {	## internal entity
              $self->_raise_error (shift (@params)->flag ('smxp__src_pos'), c => $e,
                                   type => 'SYNTAX_INVALID_KEYWORD', t => 'NDATA');
            } else {
              shift @params;	# 'NDATA'
            }
            if ($p ne 'n' && $params[0]->flag ('smxp__pmdp_type') eq 'S') {
              shift @params while ($params[0]->flag ('smxp__pmdp_type') eq 'S');
            } else {	# <!ENTITY...NDATA> or <!ENTITY...NDATA"foo">, etc.
              my $part = shift (@params);
              $self->_raise_error ($part->flag ('smxp__src_pos'), c => $e,
                                   type => 'SYNTAX_INVALID_MD', t => ($part->inner_text||'>'));
            }
            ## Notation name
            if ($p ne 'n' && $params[0]->flag ('smxp__pmdp_type') eq 'Name') {
              my $part = shift (@params);
              my $nname = $part->inner_text;
              $entMan ||= $c->_get_entity_manager;
              ## Whether notation declared is validated after all of DTD is read
              #my $notation = $entMan->get_entity ($nname, namespace_uri => $NS{SGML}.'notation');
              #if (!$notation) {
              #  $self->_raise_error ($part->flag ('smxp__src_pos'), type => 'VC_NOTATION_DECLARED',
              #                       t => $nname, c => $e);
              #}
              $e->set_attribute (NDATA => $nname)
                ->flag (smxp__src_pos => $part->flag ('smxp__src_pos'));
            }	# Notation Name
          }	# NDATA
        } else {	# no literal 2 nor NDATA
          if ($p ne 'n' && $extid_type eq 'PUBLIC') {	## System ID required
            $self->_raise_error (shift (@params)->flag ('smxp__src_pos'), c => $e,
                                 type => 'SYNTAX_MD_SYSID_NOT_FOUND');
            $e->set_attribute (SYSTEM => 'http://system.identifier.invalid/');
          }
        }	# no literal 2
      } else {	# <!ENTITY name>
        my $part = shift (@params);
        $self->_raise_error ($part->flag ('smxp__src_pos'), c => $e,
                             type => 'SYNTAX_INVALID_MD', t => ($part->inner_text||'>'));
      }
    }	# Name exist
    while (@params) {
      my $param = shift (@params);
      last unless $param->flag ('smxp__pmdp_type');	## dummy parameter
      if ($param->flag ('smxp__pmdp_type') ne 'S') {
        $self->_raise_error ($param->flag ('smxp__src_pos'), c => $e,
                             type => 'SYNTAX_INVALID_MD', t => $param->inner_text);
      }
    }
    _count_lp ('>', $o);
}

sub _parse_element_declaration ($$$$) {
    my ($self, $all, $c, $o) = (@_);
    my $e = undef;
    $e = $c->append_new_node (type => '#declaration',
                             namespace_uri => 'urn:x-suika-fam-cx:markup:sgml:element');
    $all =~ s/^<!ELEMENT//s;
    _count_lp ('<!ELEMENT', $o);
    ## Element type name
    if ($all =~ s/^$xml_re{s}($xml_re{Name})//s) {
      $e->set_attribute (qname => $1);
      _count_lp ($&, $o);
    }
    ## contentspec / PEReference
    if ($all =~ s/^(?:$xml_re{s})?(?:$xml_re{PEReference}|$xml_re{Name}|\#PCDATA|\()(?:$xml_re{s}|$xml_re{PEReference}|$xml_re{Name}|\#PCDATA|[()|,+*?])*//s) {
      $e->append_new_node (type => '#xml', value => $&);	# TODO: temporary
      _count_lp ($&, $o);
    }
    if ($all =~ s/^((?:$xml_re{s})?>)$//s) {
      _count_lp ($1, $o);
    } else {
      _raise_fatal_error ($o, desc => 'INVALID_DECLARE_SYNTAX', t => $all);
    }
}


sub _parse_attlist_declaration ($$$$) {
    my ($self, $all, $c, $o) = (@_);
    my $e = undef;
    $e = $c->append_new_node (type => '#declaration', local_name => 'ATTLIST');
    $all =~ s/^<!ATTLIST//s;
    _count_lp ('<!ATTLIST', $o);
    ## Element type name
    if ($all =~ s/^$xml_re{s}($xml_re{Name})//s) {
      $e->target_name ($1);
      _count_lp ($&, $o);
    }
    ## Definition
    if ($all =~ s/^(?:$xml_re{PEReference}|$xml_re{Name}|\#$xml_re{Name}|$xml_re{s}|$xml_re{__AttValue_simple})+//s) {
      $e->append_new_node (type => '#xml', value => $&);	# TODO: temporary
      _count_lp ($&, $o);
    }
    if ($all =~ s/^((?:$xml_re{s})?>)$//s) {
      _count_lp ($1, $o);
    } else {
      _raise_fatal_error ($o, desc => 'INVALID_DECLARE_SYNTAX', t => $all);
    }
}

## TODO: remove this function.  this function is already obsoleted.
sub _raise_fatal_error ($%) {
  require Carp;
  my ($o, %o) = @_;
  $o{desc} = {
  	INVALID_CHAR	=> 'Invalid character (%s) at this context',
  	INVALID_XML_DECLARE	=> 'XML declaration must be at the top of the entity',
  	NONDECLARED_NS_PREFIX	=> 'Undeclared namespace prefix (%s) is used',
  	NONMATCH_ETAG	=> 'End tag (element type name = '.$o{_end_qname}.') does not match with start tag (element type name = '.$o{_start_qname}.')',
  	NOT_ALLOWED_HERE	=> 'This type of markup (%s) cannot appear here',
  	NOT_ALLOWED_THIS_MODE	=> 'This type of markup (%s) cannot be used '.({
  		document_entity 	=> 'out of DTD',
  		dtd_internal_subset	=> 'in internal subset of DTD',
  		dtd_external_subset	=> 'in external parsed entity (external subset of DTD)',
  	}->{$o->{entity_type}||'document_entity'}||'in '.$o->{entity_type}),
  	UNKNOWN	=> 'Unknown error (%s)',
  }->{$o{desc}} || $o{desc};
  $o{desc} .= ' (%s)' if length $o{t} && $o{desc} !~ /%s/;
  Carp::croak ("Line $o->{line}, position $o->{pos}: ".sprintf $o{desc}, $o{t});
}

sub _is_brother_of_root_element ($$) {
  my ($self, $c) = @_;
      for (@{$c->child_nodes}) {
        if ($_->node_type eq '#element') {
          return 1;
        }
      }
  return 0;
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/06/17 12:25:07 $
