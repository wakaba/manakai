
=head1 NAME

Message::Markup::XML::Parser --- manakai: Simple XML parser

=head1 DESCRIPTION

This is a simple XML parser intended to be used with Message::Markup::XML.
After parsing of the XML document, this module returns a Message::Markup::XML
object so that you can handle XML document with that module (and other modules
implementing same interface).

This module is part of manakai.

=cut

package Message::Markup::XML::Parser;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.21 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar InXMLChar
                        InXML_deprecated_noncharacter InXML_unicode_xml_not_suitable!;
require Message::Markup::XML;
require Message::Markup::XML::Error;
*_raise_error = \&Message::Markup::XML::Error::raise;
our %NS;
*NS = \%Message::Markup::XML::NS;

=head1 METHODS

WARNING: This module is under construction.  Interface of this module is not yet fixed.

=cut

our %xml_re;
# [1] document = prolog element *Misc
# [2] Char = %x09 / %x0A / %x0D / U+0020-U+D7FF / U+E000-U+FFFD / U+10000-U+10FFFF ;; 1.0
# [2] Char = %x09 / %x0A / %x0D / %x20-7E / U+0085 / U+00A0-U+D7FF / U+E000-U+FFFD
#          / U+10000-U+10FFFF                                                      ;; 1.1
# [3] s = 1*(%x20 / %x09 / %x0D / %x0A)
$xml_re{s} = qr/[\x09\x0A\x0D\x20]+/s;
$xml_re{_s__chars} = qr/\x09\x0A\x0D\x20/s;
# [4] NameChar = Letter / Digit / "." / "-" / "_" / ":" / CombiningChar / Extender ;; 1.0
# [4] NameStartChar = ":" / ALPHA / "_" / U+00C0-U+02FF / U+0370-U+037D
#                   / U+037F-U+1FFF / U+200C-U+200D / U+2070-U+218F
#                   / U+2C00-U+2FEF / U+3001-U+D7FF / U+F900-U+EFFFF               ;; 1.1
# [4a] NameChar = NameStartChar / "-" / "." / DIGIT / U+00B7 / U+0300-U+036F
#               / U+203F-U+2040                                                    ;; 1.1
#	$xml_re{NameChar} = qr/[A-Za-z0-9._:-]|[^\x00-\x7F]/;
#$xml_re{NameChar} = qr/\p{InXMLNameChar}/;
# [5] Name = (Letter / "_" / ":") *NameChar                                        ;; 1.0
# [5] Name = NameStartChar *NameChar                                               ;; 1.1
#	$xml_re{Name} = qr/(?:[A-Z_:]|[^\x00-\x7F])(?:$xml_re{NameChar})*/;
$xml_re{Name} = qr/\p{InXML_NameStartChar}\p{InXMLNameChar}*/;
# [6] Names = Name *(S Name)       ;; 1.0 FE & 1.0 FE-errata (2000-09-27) & 1.0 SE
# [6] Names = Name *(%x20 Name)    ;; 1.0 FE-errata (2000-04-09) & 1.0 SE-errata
#$xml_re{Names} = qr/$xml_re{Name}(?:$xml_re{s}$xml_re{Name})*/s;
# [7] Nmtoken = 1*NameChar
#$xml_re{Nmtoken} = qr/(?:$xml_re{NameChar})+/;
#$xml_re{Nmtoken} = qr/\p{InXMLNameChar}+/;
# [8] Nmtokens = Nmtoken *(S Nmtoken)    ;; 1.0 FE & 1.0 FE-errata (2000-09-27) & 1.0 SE
# [8] Nmtokens = Nmtoken *(%x20 Nmtoken) ;; 1.0 FE-errata (2000-04-09) & 1.0 SE-errata
#$xml_re{Nmtokens} = qr/$xml_re{Nmtoken}(?:$xml_re{s}$xml_re{Nmtoken})*/s;
# [9] EntityValue = <"> *((Char - ("%" / "&" / <">)) / PEReference / Reference) <">
#                 / "'" *((Char - ("%" / "&" / "'")) / PEReference / Reference) "'"
# [10] AttValue   = <"> *((Char - ("<" / "&" / <">)) / Reference) <">
#                 / "'" *((Char - ("<" / "&" / "'")) / Reference) "'"
$xml_re{__AttValue_simple} = qr/"[^"]*"|'[^']*'/s;
# [11] SystemLiteral = <"> *(Char - <">) <"> / "'" *(Char - "'") "'"
#$xml_re{SystemLiteral} = qr/"[^"]*"|'[^']*'/;
# [12] PublicLiteral = <"> *PubidChar <"> / "'" *(PubidChar - "'") "'"
# [13] PubidChar = %x20 / %x0D / %x0A / ALPHA / DIGIT / "-" / "'" / "(" / ")"
#                / "+" / "," / "." / "/" / ":" / "=" / "?" / ";" / "!" / "*"
#               / "#" / "@" / "$" / "_" / "%"
#$xml_re{PubidChar} = qr[[\x0D\x0A\x20!\x24#%'()+*,./0-9:;=?\x40A-Z_a-z-]];
#$xml_re{__non_PubidChar} = qr[[^\x0D\x0A\x20!\x24#%'()+*,./0-9:;=?\x40A-Z_a-z-]];
#$xml_re{__PubidChar2} = qr[[\x0D\x0A\x20!\x24#%()+*,./0-9:;=?\x40A-Z_a-z-]];
#$xml_re{PublicLiteral} = qr/"(?:$xml_re{PubidChar})*"|'(?:$xml_re{__PubidChar2})*'/;
# [14] CharData = *(Char - ("<" / "&")) - (*(Char - ("<" / "&")) "]]>" *(Char - ("<" / "&")))
#$xml_re{CharData} = qr/(?:(?!\]\]>)[^<&])*/s;
$xml_re{__CharDataP} = qr/(?:(?!\]\]>)[^<&])+/s;
# [15] Comment = "<!--" *((Char - "-") / ("-" (Char - "-")))) "-->"
#$xml_re{Comment_M} = qr/<!--((?:(?!--).)*)-->/s;
# [16] PI = "<?" PITarget [S (*Char - (*Char "?>" *Char))] "?>"
$xml_re{PI_M} = qr/<\?($xml_re{Name})(?:$xml_re{s}((?:(?!\?>).)*))?\?>/s;
$xml_re{_xml_PI_M} = qr/<\?xml(?:$xml_re{s}((?:(?!\?>).)*))?\?>/s;
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
#$xml_re{__doctypedecl_start_simple_M} = qr/(<!DOCTYPE$xml_re{s})($xml_re{Name})($xml_re{s}SYSTEM$xml_re{s}$xml_re{__AttValue_simple}|$xml_re{s}PUBLIC$xml_re{s}$xml_re{__AttValue_simple}$xml_re{s}$xml_re{__AttValue_simple})?/s;
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
#$xml_re{Attribute} = qr/$xml_re{Name}(?:$xml_re{s})?=(?:$xml_re{s})?$xml_re{__AttValue_simple}/s;
#$xml_re{Attribute_M} = qr/($xml_re{Name})(?:$xml_re{s})?=(?:$xml_re{s})?($xml_re{__AttValue_simple})/s;
#$xml_re{STag} = qr/<$xml_re{Name}(?:$xml_re{s}$xml_re{Attribute})*(?:$xml_re{s})?>/s;
# [42] ETag = "</" Name [S] ">"
$xml_re{ETag_M} = qr!</($xml_re{Name})(?:$xml_re{s})?>!s;
# [43] content = *(element / CharData / Reference / CDSect / PI / Comment) ;; 1.0 FE
# [43] content = [CharData] *((element / Reference / CDSect / PI / Comment) [CharData])
#                ;; 1.0 FE-errata & 1.0 SE
# [44] EmptyElemTag = "<" Name *(S Attribute) [S] "/>"
#$xml_re{__STag_or_EmptyElemTag} = qr!<$xml_re{Name}(?:$xml_re{s}$xml_re{Attribute})*(?:$xml_re{s})?/?>!s;
#$xml_re{__STag_or_EmptyElemTag_simple} = qr!<$xml_re{Name}(?:$xml_re{s}|$xml_re{Name}|$xml_re{__AttValue_simple}|=)*/?>!s;
# [45] elementdecl = '<!ELEMENT' S Name S contentspec [S] ">"
# [46] contentspec = 'EMPTY' / 'ANY' / Mixed / children
#$xml_re{__contentspec_simple} = qr/(?:$xml_re{Name}|\#PCDATA|[()|,?*+]|$xml_re{s})/s;
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
#$xml_re{AttValue} = qr/"(?:$xml_re{Reference}|[^&<"])*"|'(?:$xml_re{Reference}|[^&<'])*'/s;
# [69] PEReference = "%" Name ";"
$xml_re{PEReference} = qr/%(?:$xml_re{Name});/;
$xml_re{PEReference_M} = qr/%($xml_re{Name});/;
$xml_re{__elementdecl_simple} = qr/<!ELEMENT(?:$xml_re{s}|$xml_re{PEReference}|$xml_re{Name}|\#PCDATA|[()|,?*+])+>/s;
$xml_re{__AttlistDecl_simple} = qr/<!ATTLIST(?:$xml_re{PEReference}|$xml_re{Name}|[#()|]|$xml_re{s}|$xml_re{__AttValue_simple})*>/s;
# [70] EntityDecl = GEDecl / PEDecl
#$xml_re{__EntityDecl_simple} = qr/<!ENTITY(?:$xml_re{__AttValue_simple}|[^"'>])*>/s;
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
#$xml_re{__NotationDecl_simple} = qr/<!NOTATION(?:$xml_re{__AttValue_simple}|[^"'>])*>/s;
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
#$xml_re{__NCSTag} = qr/<$xml_re{QName}(?:$xml_re{s}$xml_re{Attribute})*(?:$xml_re{s})?>/s;
# [10] ETag = "</" QName [S] ">"
#$xml_re{__NCETag} = qr!</$xml_re{QName}(?:$xml_re{s})?>!s;
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


sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self;
}

sub parse_text ($$;$%) {
  my ($self, $s, $o, %opt) = @_;
  $o ||= {line => 0, pos => 0, entity_type => 'document_entity',
          uri => $self->{option}->{document_entity_uri}};
  my $r = Message::Markup::XML->new (type => '#document');
  $r->base_uri ($self->{option}->{document_entity_base_uri})
    if defined $self->{option}->{document_entity_base_uri};
  unless ($opt{entMan}) {
    $opt{entMan} = $r->_get_entity_manager;
    $opt{entMan}->option (uri_resolver => $self->{option}->{uri_resolver});
    $opt{entMan}->option (error_handler => $self->{option}->{error_handler});
  } else {
    $opt{entMan}->set_root_node ($r);
  }
  $r->flag (smxp__entity_manager => $opt{entMan});
  
  ## Line-break normalization
  $s =~ s/\x0D\x0A/\x0A/g;
  $s =~ tr/\x0D/\x0A/;
  
  ## NOTE: Even if there are more than one non-XML-Char, error is raised only one time.
  $self->_warn_char_val ($self->_make_clone_of ($o), $s);
  if ($s =~ s/^($xml_re{_xml_PI_M})//s) {	# <?xml?>
    my ($data, $all) = ($2, $1);
    $self->_clp (_____ => $o);
    if (length ($data)) {
      $self->_clp (_ => $o);	# <?xml* *ver...?>
      $self->_parse_xml_declaration ($r->append_new_node (type => '#pi',
                                                          local_name => 'xml'), $data, $o);
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
      $r->append_new_node (type => '#pi', local_name => 'xml')
        ->set_attribute (version => '1.0');
    }
    $self->_clp (__ => $o);
  }
  $self->_parse_document_entity ($r, \$s, $o, %opt);
  wantarray ? ($r, $o) : $r;
}

sub _parse_document_entity ($$\$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  $o->{entity_type} = 'document_entity';
  my %occur;
  my $no_doctype = sub {
      my ($o) = @_;
      $self->_raise_error ($o, c => $c, type => 'WARN_DOCTYPE_NOT_FOUND');
      if ($opt{alt_dtd_external_subset}) {
        my $D = $c->append_new_node (type => '#declaration', namespace_uri => $NS{SGML}.'doctype');
        $opt{entMan}->set_doctype_node ($D);
        $D->set_attribute (SYSTEM => $opt{alt_dtd_external_subset});
        $self->_raise_error ($o, type => 'MSG_EXTERNAL_DTD_SUBSET_USED',
        	t => [$opt{alt_dtd_external_subset}]);
        $self->_parse_dtd_external_subset ($o, $D, \%opt);
      }
  };
  while ($$s) {
    if ($$s =~ /^<$xml_re{Name}/) {	# <element/>
      &$no_doctype ($o) unless $occur{doctype};
      $self->_parse_element_content ($c, $s, $o, entMan => $opt{entMan});
      $occur{element} = 1;  $occur{pi} = 0;
    } elsif ($$s =~ s/^($xml_re{s})//s) {	# s
      $c->append_text ($1);
      $self->_clp ($1 => $o);
    } elsif ($$s =~ s/^<!DOCTYPE//) {
      my $D = $c->append_new_node (type => '#declaration', namespace_uri => $NS{SGML}.'doctype');
      $opt{entMan}->set_doctype_node ($D);
      $self->_clp (_________ => $o);
      if ($$s =~ s/^($xml_re{s}($xml_re{Name}))//s) {
        $D->set_attribute (qname => $2);
        $occur{doctype} = $2;
        $self->_clp ($1 => $o);
      } else {
        $occur{doctype} = 1;
        $self->_raise_error ($o, type => 'SYNTAX_DOCTYPE_NAME_NOT_FOUND', c => $D);
      }
      my $have_sysid = 0;
      if ($$s =~ s/^($xml_re{s}PUBLIC)//s) {
        $self->_clp ($1 => $o);
        if ($$s =~ s/^($xml_re{s})($xml_re{__AttValue_simple})//s) {
          $self->_clp ($1 => $o);
          my $pid = $2; $pid = substr ($pid, 1, length ($pid) - 2);
          $D->set_attribute (PUBLIC => $opt{entMan}->check_public_id ($o, $pid));
          $self->_clp ($2 => $o);
          $have_sysid = 1;
        } else {
          $self->_raise_error ($o, type => 'SYNTAX_DOCTYPE_PID_LITERAL_NOT_FOUND', c => $D);
        }
      } elsif ($$s =~ s/^($xml_re{s}SYSTEM)//s) {
        $self->_clp ($1 => $o);
        $have_sysid = 2;
      }
      if ($have_sysid) {
        if ($$s =~ s/^($xml_re{s})($xml_re{__AttValue_simple})//s) {
          $self->_clp ($1 => $o);
          my $sid = $2; $sid = substr ($sid, 1, length ($sid) - 2);
          $D->set_attribute (SYSTEM => $opt{entMan}->check_system_id ($o, $sid));
          $self->_clp ($2 => $o);
        } elsif ($have_sysid) {
          $self->_raise_error ($o, type => 'SYNTAX_DOCTYPE_SYSID_LITERAL_NOT_FOUND', c => $D);
          $D->set_attribute (SYSTEM => $NS{internal_invalid_sysid}) if $have_sysid == 1;
          undef $have_sysid if $have_sysid == 2;
        }
      }
      if ($opt{alt_dtd_external_subset}) {
        $D->remove_attribute ('PUBLIC');
        $D->set_attribute (SYSTEM => $opt{alt_dtd_external_subset});
        $self->_raise_error ($o, type => 'MSG_EXTERNAL_DTD_SUBSET_USED',
        	t => [$opt{alt_dtd_external_subset}]);
        $have_sysid = 1;
      }
      ## dso for the internal subset
      if ($$s =~ s/^((?:$xml_re{s})?\[)//s) {
        $self->_clp ($1 => $o);
        $self->_parse_dtd ($D, $s, $o, return_with_dsc => 1, validate_notation_declared => 1,
                           entMan => $opt{entMan});
        ## dsc and mdo is processed by _parse_dtd
      } elsif ($$s =~ s/^((?:$xml_re{s})?>)//s) {
        $self->_clp ($1 => $o);
      } else {
        $self->_raise_error ($o, type => 'SYNTAX_END_OF_MARKUP_NOT_FOUND', c => $D, t => $D);
      }
      ## Read and parse the external subset
      $self->_parse_dtd_external_subset ($o, $D, \%opt) if $have_sysid;
    } elsif ($$s =~ s/^($xml_re{PI_M})//s) {	# <?pi?>	## TODO: pi parsing
    ## PI before DOCTYPE declaration
      if ($2 eq 'xml') {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_XML_DECLARE_POSITION');
      } else {
        $c->append_new_node (type => '#pi', local_name => $2, value => $3)
          ->flag (smxp__src_pos => $self->_make_clone_of ($o));
        $self->_clp ($1 => $o);
      }
      $occur{pi} = 1;
    } elsif ($$s =~ /^<!--/) {
      $self->_parse_comment_declaration ($s, $c, $o);
      $occur{comment} = 1;
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      substr ($$s, 0, 1) = '';
    }
  }	# $$s
  
  unless ($occur{element}) {
    if ($occur{doctype} && ($occur{doctype} ne '1')) {	# root element type is known
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_ROOT_ELEMENT_NOT_FOUND',
                           t => $occur{doctype});
      $c->append_new_node (type => '#element', qname => ($occur{doctype} || 'root'));
    } else {	# root element type is unknown
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_ROOT_ELEMENT_NOT_FOUND',
                           t => '#IMPLIED');
      $c->append_new_node (type => '#element', local_name => 'root',
                           namespace_uri => $NS{internal_ns_invalid});
    }
    &$no_doctype ($o) unless $occur{doctype};
  }
  if ($occur{element} && $occur{doctype}) {
    my $root;
    for (@{$c->child_nodes}) {
      if ($_->node_type eq '#element') {
        $root = $_->qname;
        last;
      }
    }
    unless ($root eq $occur{doctype}) {
      $self->_raise_error ($o, type => 'VC_ROOT_ELEMENT_TYPE', c => $c,
                           t => [$occur{doctype}, $root]);
    }
  }
}

sub _parse_dtd_external_subset ($$$$) {
  my ($self, $o, $D, $opt) = @_;
        my $xsub = $D->set_attribute ('external-subset');
        my $o2 = $self->_make_clone_of ($o);
        $o2->{entity_type} = 'dtd_external_subset';
        $o2->{line} = 0;  $o2->{pos} = 0;
        my $ext_ent = $opt->{entMan}->get_external_entity ($self, $D, $o2);
        if ($ext_ent->{error}->{no_data}) {	## can't be retrived
          $self->_raise_error ($o, type => 'ERR_EXT_ENTITY_NOT_FOUND', c => $D,
                               t => ['<!DOCTYPE>', $o2->{uri}, $ext_ent->{error}->{reason_text}]);
        } else {
          $xsub->base_uri ($ext_ent->{base_uri});
          my $ev = $ext_ent->{text};
          $self->_parse_dtd ($xsub, \$ev, $o2, entMan => $opt->{entMan});
          $xsub->flag (smxp__ref_expanded => 1);
        }
}

sub _parse_element_content ($$$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  my $c_initial = overload::StrVal ($c);
  while ($$s) {
    if ($$s =~ m:^<[^!?/]:) {
      if ($c->node_type eq '#document' && $self->_is_brother_of_root_element ($c)) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT',
                             t => substr ($$s, 0, 10));
      }
      $c = $self->_parse_start_tag ($c, $s, $o, entMan => $opt{entMan});
    } elsif ($$s =~ s/^($xml_re{ETag_M})//s) {
      my $ename = $2;
      if ($ename eq $c->flag ('smxp__original_qname') || $ename eq $c->qname) {
        $c = $c->{parent};
      } else {	## Element type name does not match
        my $o_etn = $self->_make_clone_of ($o);
        $o_etn->{pos} += 2;
        $self->_raise_error ($o_etn, c => $c, type => 'WFC_ELEMENT_TYPE_MATCH',
                             t => [$ename, $c->qname]);
      }
      $self->_clp ($1 => $o);
    } elsif (($c->node_type eq '#document') && ($$s =~ s/^($xml_re{s})//s)) {
      $c->append_text ($1);
      $self->_clp ($1 => $o);
    } elsif ($$s =~ s/^($xml_re{__CharDataP})//s) {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT', t => $1)
        if $c->node_type eq '#document';
      $c->append_text ($1);
      $self->_clp ($1 => $o);
    } elsif ($$s =~ s/^($xml_re{Reference})//s) {	## &foo; | &#1234; | &#x12AB;
      my $entity_ref = $1;
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT',
                           t => $entity_ref) if $c->node_type eq '#document';
      my $eref = $self->_parse_reference ($c, $entity_ref, $o);
      unless (index ($eref->{namespace_uri}, 'char') > -1) {	## General entity reference
        my $entity = $opt{entMan}->get_entity ($eref);
        if (!ref ($entity) && {qw/&lt; 1 &gt; 1 &amp; 1 &quot; 1 &apos; 1/}->{$entity_ref}) {
          $self->_raise_error ($o, c => $c, type => 'WARN_PREDEFINED_ENTITY_NOT_DECLARED',
                               t => $entity_ref);
          $entity = $opt{entMan}->get_entity ($eref);
        }
        if (!ref $entity) {
          $self->_raise_error ($o, t => $entity_ref,
                       type => ($opt{entMan}->is_standalone_document_1?'WF':'V')
                                .'C_ENTITY_DECLARED');
        } else {
          if ($entity->flag ('smxp__declaration_may_not_be_read')) {
            $self->_raise_error ($o, type => 'WARN_EXTERNALLY_DEFINED_ENTITY_REFERRED',
                                 t => $entity_ref);
          }
          my $o2 = $self->_make_clone_of ($o);
          if ($o2->{__entities}->{$entity_ref}) {
            $self->_raise_error ($o, type => 'WFC_NO_RECURSION', t => $entity_ref);
          } else {
            $o2->{entity} = $entity_ref;
            my $entity_value = $entity->get_attribute ('value');
            if (ref $entity_value) {
              $o2->{__entities}->{$entity_ref} = 1;
              $o2->{uri} = $entity->flag ('smxp__uri_in_which_declaration_is');
              $o2->{line} = 0; $o2->{pos} = 0;
              my $ev = $entity_value->_entity_parameter_literal_value;
              $self->_parse_element_content ($eref, \$ev, $o2, entMan => $opt{entMan});
              $eref->flag (smxp__ref_expanded => 1);
            } else {	## External entity
              $o2->{entity_type} = 'external_general_parsed_entity';
              my $ext_ent = $opt{entMan}->get_external_entity ($self, $entity, $o2);
              if ($ext_ent->{NDATA}) {	## non-parsed entity
                $self->_raise_error ($o, type => 'WFC_PARSED_ENTITY',
                                     c => $entity, t => $entity_ref);
              } elsif ($ext_ent->{error}->{no_data}) {	## parsed entity but can't be retrived
                $self->_raise_error ($o, type => 'ERR_EXT_ENTITY_NOT_FOUND', c => $entity,
                                         t => [$entity_ref, $o2->{uri},
                                               $ext_ent->{error}->{reason_text}]);
              } else {	## parsed entity
                $o2->{__entities}->{$entity_ref} = 1;
                $eref->base_uri ($ext_ent->{base_uri});
                my $ev = $ext_ent->{text};
                $self->_parse_element_content ($eref, \$ev, $o2, entMan => $opt{entMan});
                $eref->flag (smxp__ref_expanded => 1);
              }
            }
          }
        }
      }	# if &foo;
    } elsif ($$s =~ /^<!--/) {
      $self->_parse_comment_declaration ($s, $c, $o);
    } elsif ($$s =~ s/^($xml_re{CDSect_M})//s) {	## TODO
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_DATA_OUT_OF_ROOT_ELEMENT', t => '<![')
        if $c->node_type eq '#document';
      $c->append_new_node (type => '#section', value => $2)
        ->set_attribute (status => 'CDATA');
      $self->_clp ($1 => $o);
    } elsif ($$s =~ s/^($xml_re{PI_M})//s) {	## TODO: warn unless declared
      my ($target, $data, $all) = ($2, $3, $1);
      if ($target eq 'xml') {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_XML_DECLARE_POSITION');
      } else {
        $c->append_new_node (type => '#pi', local_name => $target, value => $data);
        $self->_clp ($all => $o);
      }
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
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

sub _parse_start_tag ($$\$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  my ($type_pfx, $type_lname, $type_qname);
  ## Element type name (general identifier)
  if ($$s =~ s/^<($xml_re{Name})//) {
    $type_qname = $1;
    if (substr ($type_qname, 0, 1) eq ':' || substr ($type_qname, -1, 1) eq ':') {
      $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_QNNAME', t => $type_qname);
      $type_qname =~ tr/:/_/;
    }
    $self->_clp ('<'.$type_qname => $o);
    ($type_pfx, $type_lname) = $self->_ns_parse_qname ($type_qname);
    if ($type_pfx && $type_lname !~ /^\p{InXML_NameStartChar}/) {
      $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_LNAME_IS_NCNNAME', t => $type_lname);
      $type_lname = '_' . $type_lname;
    }
    $c = $c->append_new_node (type => '#element', local_name => $type_lname);
    $c->flag (smxp__original_qname => $type_qname);
  } else {
    $self->_clp (_ => $o);
    $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
    $$s =~ s/^<//;
    return $c;
  }
  
  my $defattr = $opt{entMan}->get_attr_definitions (qname => $type_qname);
  ## Attribute spec list
  my @attr;
  my %defined_attr;
  while ($$s) {
    if ($$s =~ s/^($xml_re{s})($xml_re{Name})//s) {
      my $attr_qname = $2;
      my ($attr_pfx, $attr_lname);
      my $ignore = 0;
      ## Isn't already defined?  Is valid QName?
      if ($defined_attr{$attr_qname}) {
        $self->_raise_error ($o, c => $c, type => 'WFC_UNIQUE_ATT_SPEC', t => $attr_qname);
        $ignore = 1;
      } elsif (substr ($attr_qname, 0, 1) eq ':' || substr ($attr_qname, -1, 1) eq ':') {
        $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_QNNAME', t => $attr_qname);
        $defined_attr{$attr_qname} = 1;
        $attr_qname =~ tr/:/_/;  $defined_attr{$attr_qname} = 1;
        ($attr_pfx, $attr_lname) = (undef, $attr_qname);
      } else {
        $defined_attr{$attr_qname} = 1;
        ($attr_pfx, $attr_lname) = $self->_ns_parse_qname ($attr_qname);
      }
      $self->_clp ($1.$attr_qname => $o);
      
      if ($attr_pfx && $attr_lname !~ /^\p{InXML_NameStartChar}/) {
        $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_LNAME_IS_NCNNAME', t => $attr_lname);
        $attr_lname = '_' . $attr_lname;
      }
      my $attr_node = ref ($c)->new (type => '#attribute', local_name => $attr_lname);
      
      if ($$s =~ s/^($xml_re{s})//s) {
        $self->_clp ($1);
      }
      if ($$s =~ s/^=//) {
        $self->_clp (_ => $o);
        if ($$s =~ s/^($xml_re{s})//s) {
          $self->_clp ($1);
        }
        
        if ($$s =~ s/^($xml_re{__AttValue_simple})//s) {
          next if $ignore;
          my $pcdata = substr ($1, 1, length ($1) - 2);
          $self->_clp (_ => $o);
          $self->_parse_attr_value_literal_data ($attr_node, \$pcdata, $o, entMan => $opt{entMan});
          $self->_clp (_ => $o);
          
          if (defined $attr_pfx and $attr_pfx eq 'xmlns') {
            $c->{ns_specified}->{$attr_lname} = $attr_node;
            $attr_node->namespace_uri ($NS{xmlns});
            $attr_node->{parent} = $c;	## Note: This code might be dangerous.
            my $ns_name = $attr_node->inner_text;
            $opt{entMan}->check_ns_uri ($o, $attr_lname => $ns_name) if length $ns_name;
            ## TODO: XML Names 1.1 support
            $ns_name = $c->resolve_relative_uri ($ns_name) if length ($ns_name) == 0;
            $c->define_new_namespace ($attr_lname => $ns_name);
          } elsif (!$attr_pfx && $attr_lname eq 'xmlns') {
            $c->{ns_specified}->{''} = $attr_node;
            $attr_node->{parent} = $c;	## Note: This code might be dangerous.
            my $ns_name = $attr_node->inner_text;
            if (length ($ns_name) || lc (substr ($ns_name, 0, 3)) eq 'xml') {
              $opt{entMan}->check_ns_uri ($o, '' => $ns_name);
            } else {
              $self->_raise_error ($o, type => 'WARN_XML_NS_URI_IS_RELATIVE', t => $attr_qname);
            }
            $c->define_new_namespace ('' => $ns_name);
          } else {
            push @attr, [$attr_pfx => $attr_lname, $attr_node];
          }
        } else {
          $self->_raise_error ($o, type => 'SYNTAX_ATTR_LITERAL_NOT_FOUND', t => $attr_qname);
          $attr_node->append_text ($attr_qname);
        }
      } else {
        $self->_raise_error ($o, type => 'SYNTAX_ATTR_NAME_OMITTED', t => $attr_qname);
        $attr_node->append_text ($attr_qname);
      }
    } elsif ($$s =~ s!^((?:$xml_re{s})?(/)?>)!!s) {
      $self->_clp ($1);
      $c->option (use_EmptyElemTag => 1) if $2;
      last;
    } elsif (substr ($$s, 0, 1) eq '<') {
      $self->_raise_error ($o, type => 'SYNTAX_TAG_NOT_CLOSED', t => substr ($$s, 0, 10));
      last;
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      substr ($$s, 0, 1) = '';
    }
  }	## while
  
  ## Default attributes
  for (keys %{$defattr->{attr}}) {
    unless ($defined_attr{$_}) {
      my $defval = $defattr->{attr}->{$_}->get_attribute ('default_value');
      if ($defval) {
        my ($attr_pfx, $attr_lname) = $self->_ns_parse_qname ($_);
        if ($attr_pfx eq 'xmlns') {
          $c->{ns_specified}->{$attr_lname} = 0;
          my $ns_name = $defval->inner_text;
          $opt{entMan}->check_ns_uri ($o, $attr_lname => $ns_name) if length $ns_name;
          if ($defattr->{attr_may_not_be_read}->{$_}
           && $c->defined_namespace_prefix ($attr_lname) ne $ns_name) {
            $self->_raise_error ($o, type => 'WARN_XMLNAMES_EXTERNAL_NS_ATTR',
                                 t => [$attr_lname => $ns_name]);
          }
          ## TODO: XML Names 1.1 support
          $ns_name = $c->resolve_relative_uri ($ns_name) if length ($ns_name) == 0;
          $c->define_new_namespace ($attr_lname => $ns_name);
        } elsif (!$attr_pfx && $attr_lname eq 'xmlns') {
          $c->{ns_specified}->{''} = 0;
          my $ns_name = $defval->inner_text;
          if (length ($ns_name) || lc (substr ($ns_name, 0, 3)) eq 'xml') {
            $opt{entMan}->check_ns_uri ($o, '' => $ns_name);
          } else {
            $self->_raise_error ($o, type => 'WARN_XML_NS_URI_IS_RELATIVE', t => $_);
          }
          if ($defattr->{attr_may_not_be_read}->{$_}
           && $c->defined_namespace_prefix ('') ne $ns_name) {
            $self->_raise_error ($o, type => 'WARN_XMLNAMES_EXTERNAL_NS_ATTR',
                                 t => ['#default' => $ns_name]);
          }
          $c->define_new_namespace ('' => $ns_name);
        } else {
          my $attr_node = ref ($c)->new (type => '#attribute', local_name => $attr_lname,
                                         value => $defval->inner_text);
          $attr_node->flag (smxp__is_dtd_default => 1);
          if ($defattr->{attr_may_not_be_read}->{$_}) {
            $self->_raise_error ($o, type => 'WARN_EXTERNAL_DEFAULT_ATTR', c => $c,
                                 t => $_);
          }
          push @attr, [$attr_pfx => $attr_lname, $attr_node];
        }
      }	# has default value
    }	# unspecified attr
  }
  
  ## Namespace of element type name
  {
    my $uri = $c->defined_namespace_prefix ($type_pfx || '');
    if (defined $uri) {
      $c->namespace_uri ($uri);
    } elsif (!$type_pfx) {	## Default
      ## <foo xmlns="">
      $c->define_new_namespace ('' => '');
    } else {
      $self->_raise_error ($o, c => $c, type => 'NC_PREFIX_NOT_DEFINED', t => $type_pfx);
      $c->namespace_uri ($NS{internal_ns_invalid}.$self->_uri_escape ($type_pfx));
    }
  }
  
  ## Namespace of attribute name
  my %ns_attr_defined;
  for (@attr) {
    unless ($_->[0]) {	## No prefix
      $c->append_node ($_->[2]);
    } else {
      my $uri = $c->defined_namespace_prefix ($_->[0]);
      if (defined $uri) {
        if ($ns_attr_defined{$uri}->{$_->[1]}) {
          $self->_raise_error ($o, c => $_->[2], type => 'NC_UNIQUE_ATT_SPEC',
                               t => [$_->[0].':'.$_->[1], $uri, $_->[1]]);
        } else {
          $_->[2]->namespace_uri ($uri);
          $ns_attr_defined{$uri}->{$_->[1]} = 1;
          $c->append_node ($_->[2]);
        }
      } else {
        $self->_raise_error ($o, c => $_->[2], type => 'NC_PREFIX_NOT_DEFINED', t => $_->[0]);
        $_->[2]->namespace_uri ($NS{internal_ns_invalid}.$self->_uri_escape ($_->[0]));
      }
    }	# have prefix
  }
  $c->option ('use_EmptyElemTag') ? $c->parent_node : $c;
}

sub _parse_dtd ($$$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  while ($$s) {
    if ($$s =~ s/^$xml_re{PEReference_M}//s) {
      my ($ref, $ename) = ('%'.$1.';', $1);
      $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ref)
        if index ($ename, ':') > -1;
      my $entity = $opt{entMan}->get_entity ($ename, namespace_uri => $NS{SGML}.'entity:parameter');
      my $eref = $c->append_new_node (type => '#reference', local_name => $ename,
                                      namespace_uri => $NS{SGML}.'entity:parameter');
      if (!ref $entity) {
        $self->_raise_error ($o, c => $c, type => 'VC_ENTITY_DECLARED', t => $ref);
      } else {
        my $o2 = $self->_make_clone_of ($o);
        if ($o2->{__entities}->{$ref}) {
          $self->_raise_error ($o, c => $c, type => 'WFC_NO_RECURSION', t => $ref);
        } else {
          $o2->{entity} = $ref;
          my $entity_value = $entity->get_attribute ('value');
          if (ref $entity_value) {	## Internal entity
            $o2->{__entities}->{$ref} = 1;
            $o2->{uri} = $entity->flag ('smxp__uri_in_which_declaration_is');
            $o2->{line} = 0;  $o2->{pos} = 0;
            my $ev = $entity_value->_entity_parameter_literal_value;
            $self->_parse_dtd ($eref, \$ev, $o2, entMan => $opt{entMan});
            $eref->flag (smxp__ref_expanded => 1);
          } else {	## External entity
            $o2->{entity_type} = 'external_parameter_entity';
            $c->root_node->flag (smxp__declaration_may_not_be_read => 1)
              if !(index ($o->{entity_type}, 'external') > -1)
              || !$opt{entMan}->is_standalone_document;
            my $ext_ent = $opt{entMan}->get_external_entity ($self, $entity, $o2);
            if ($ext_ent->{NDATA}) {	## non-parsed entity
              $self->_raise_error ($o, type => 'WFC_PARSED_ENTITY', c => $entity, t => $ref);
            } elsif ($ext_ent->{error}->{no_data}) {	## parsed entity but can't be retrived
              $self->_raise_error ($o, type => 'ERR_EXT_ENTITY_NOT_FOUND', c => $entity,
                                       t => [$ref, $o2->{uri}, $ext_ent->{error}->{reason_text}]);
              ## Don't process ENTITY/ATTLIST declaration any more
              $c->root_node->flag (smxp__stop_read_dtd => 1)
                unless $opt{entMan}->is_standalone_document;
            } else {	## parsed entity
              $o2->{__entities}->{$ref} = 1;
              $eref->base_uri ($ext_ent->{base_uri});
              my $ev = $ext_ent->{text};
              $self->_parse_dtd ($eref, \$ev, $o2, entMan => $opt{entMan});
              $eref->flag (smxp__ref_expanded => 1);
            }	# external parsed entity
          }	# external entity
        }	# not recursive
      }	# entity defined
      $self->_clp ($ref => $o);
    } elsif ($$s =~ s/^($xml_re{s})//s) {
      $c->append_text ($1);
      $self->_clp ($1 => $o);
    } elsif ($$s =~ m/^<!/) {
      if ($$s =~ m/^<!(?:ENTITY|NOTATION)(?:$xml_re{s}|%)?/s) {
        $self->_parse_entity_declaration ($s, $c, $o, entMan => $opt{entMan});
      } elsif ($$s =~ m/^<!ELEMENT(?:$xml_re{s}|%)?/s) {
        $self->_parse_element_declaration ($s, $c, $o, entMan => $opt{entMan});
      } elsif ($$s =~ m/^<!ATTLIST(?:$xml_re{s}|%)?/s) {
        $self->_parse_attlist_declaration ($s, $c, $o, entMan => $opt{entMan});
      } elsif ($$s =~ m/^<!--/) {
        $self->_parse_comment_declaration ($s, $c, $o);
      ## Markup section start (= mdo + mso)
      } elsif ($$s =~ s/^<!\[//) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_MS_IN_INTERNAL_SUBSET')
          if $o->{entity_type} eq 'document_entity';
        $self->_clp (___ => $o);
        ## Status keyword list
        if ($$s =~ s/^([^[]*)\[//s) {
          my $skl = $1;
          my $ms = $c->append_new_node (type => '#section');
          my ($status, @params);
          my $t = $self->_parse_md_params ($ms->set_attribute ('status_list'), \$skl, $o,
                                           entMan => $opt{entMan});
          if ($t =~ /^(?:$xml_re{s})?(I(?:GNORE|NCLUDE))(?:$xml_re{s})?$/s) {
            $status = $1;
          } else {
            unless ($status) {
              $self->_raise_error ($o, c => $ms, type => 'SYNTAX_MS_NO_STATUS_KEYWORD');
            } else {
              $self->_raise_error ($o, c => $ms, type => 'SYNTAX_MS_INVALID_STATUS_STRING',
                                   t => $t);
            }
            $status = index ($t, 'IGNORE') > -1 ? 'IGNORE' : 'INCLUDE';
          }
          $self->_clp ($skl.'[' => $o);
          $ms->set_attribute (status => $status);
          ## Content and markup section end
          if ($status eq 'INCLUDE') {
            $self->_parse_dtd ($ms, $s, $o, return_with_mse => 1, entMan => $opt{entMan});
          } else {
            $self->_parse_ignored_marked_section ($ms, $s, $o);
          }
        } else {	## Fatal error: Status keyword not found
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_MS_NO_STATUS');
          ## Note: parse as a section is stopped (following is parsed as DTD)
        }
      } else {	# <!UNKNOWN
        if ($$s =~ s/^<!(([A-Za-z]+)[^>"']*(?:[^>"']|"[^"]*"|'[^']*')*)>//s) {
          $self->_clp (__ => $o);
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_UNKNOWN_KWD', t => $2);
          $c->append_new_node (type => '#comment', value => $1);
          $self->_clp ($1.'_' => $o);
        } elsif ($$s =~ s/^<!>//) {
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_COMMENT_DECL_EMPTY');
          $c->append_new_node (type => '#comment', value => '');
          $self->_clp (___ => $o);
        } else {
          $self->_clp (__ => $o);
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_KWD_EXPECTED',
                               t => substr ($$s, 0, 10));
          $c->append_new_node (type => '#comment', value => '');
          substr ($$s, 0, 2) = '';
        }
      }
    ## Markup section end (= msc + mdc)
    } elsif ($opt{return_with_mse} && ($$s =~ s/^\]\]>//)) {
      $self->_clp (___ => $o);
      return undef;
    ## DOCTYPE declaration end
    } elsif ($opt{return_with_dsc} && ($$s =~ s/^(\](?:$xml_re{s})?>)//s)) {
      $self->_clp ($1 => $o);
      $c = $c->{parent};
      return undef;
    } elsif ($$s =~ s/^($xml_re{PI_M})//s) {
      if ($2 eq 'xml') {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_XML_DECLARE_POSITION');
      } else {
        $c->append_new_node (type => '#pi', local_name => $2, value => $3)
          ->flag (smxp__src_pos => $self->_make_clone_of ($o));
        ## Notation declared warning is checked after rest of the DTD is read
      }
      $self->_clp ($1 => $o);
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      $self->_clp (substr ($$s, 0, 1) => $o);
      substr ($$s, 0, 1) = '';
    }
  }	# while $$s
  if ($opt{return_with_mse} || $opt{return_with_dsc}) {
    $self->_raise_error ($o, type => 'SYNTAX_END_OF_MARKUP_NOT_FOUND', t => $c);
  }
  undef;
}

## Note: don't give empty comment declaration (<!>) or broken start (<! -- foo -->)
sub _parse_comment_declaration ($$$$;%) {
  my ($self, $s, $c, $o, %opt) = @_;
  my $in_com = 0;
  my $has_com = 0;
  substr ($$s, 0, 2) = '';	# <!
  $self->_clp (__ => $o);
  while ($$s) {
    if ($in_com && ($$s =~ s/^([^-]+(?:[^-]|-[^-])*|-[^-](?:[^-]|-[^-])*)//s)) {
      $c->append_new_node (type => '#comment', value => $1);
      $self->_clp ($1 => $o);
    } elsif ($$s =~ s/^--//) {
      unless ($in_com) {	# open
        $in_com = 1;
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_COMMENT_MULTIPLE')
          if $has_com;
        $has_com = 1;
      } else {	# close
        $in_com = 0;
      }
      $self->_clp (__ => $o);
    } elsif (!$in_com && ($$s =~ s/^($xml_re{s})//s)) {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_COMMENT_DS');
      $self->_clp ($1 => $o);
    } elsif (!$in_com && ($$s =~ s/^>//)) {
      $self->_clp (_ => $o);
      return undef;
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      $self->_clp (substr ($$s, 0, 1) => $o);
      substr ($$s, 0, 1) = '';
    }
  }
  $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_COMMENT_COM_NOT_CLOSED')
    if $in_com;
  $self->_raise_error ($o, c => $c, type => 'SYNTAX_MD_NOT_CLOSED');
  undef;
}

sub _parse_attr_value_literal_data ($$$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  my $rt = '';
  while (length $$s) {
    if ($$s =~ s/^&#(?:x([0-9A-Fa-f]+)|([0-9]+));//) {
      my $char = chr (defined $1 ? hex $1 : 0 + $2);
      $self->_warn_char_val ($o, $char, ref => 1);
      $c->append_new_node (type => '#reference', value => ord $char,
                           namespace_uri => $NS{SGML}.'char:ref'.(defined $1?':hex':''));
      $rt .= $char;
    } elsif ($$s =~ s/^&($xml_re{Name});//) {
      my ($ename, $entity_ref) = ($1, '&'.$1.';');
      $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ename)
        if index ($ename, ':') > -1;
      my $eref_node = $c->append_new_node (type => '#reference', local_name => $ename,
                                           namespace_uri => $NS{SGML}.'entity');
      my $entity = $opt{entMan}->get_entity ($ename, dont_use_predefined_entities => 1);
      if (!ref ($entity) && {qw/lt 1 gt 1 amp 1 quot 1 apos 1/}->{$ename}) {
        $self->_raise_error ($o, c => $eref_node, type => 'WARN_PREDEFINED_ENTITY_NOT_DECLARED',
                             t => $entity_ref);
        $entity = $opt{entMan}->get_entity ($ename);
      }
      if (!ref $entity) {
        $self->_raise_error ($o, c => $eref_node,
                             type => ($opt{entMan}->is_standalone_document_1?
                                      'WF':'V').'C_ENTITY_DECLARED',
                             t => $entity_ref);
        $rt .= $entity_ref;
      } else {
        my $o2 = $self->_make_clone_of ($o);
        if ($o2->{__entities}->{$entity_ref}) {
          $self->_raise_error ($o, c => $eref_node, type => 'WFC_NO_RECURSION', t => $entity_ref);
          $rt .= $entity_ref;
        } else {
          my $entity_value = $entity->get_attribute ('value');
          if (ref $entity_value) {
            $o2->{__entities}->{$entity_ref} = 1;
            $o2->{uri} = $entity->flag ('smxp__uri_in_which_declaration_is');
            $o2->{entity} = $entity_ref; $o2->{line} = 0; $o2->{pos} = 0;
            my $ev = $entity_value->_entity_parameter_literal_value;
            $rt .= $self->_parse_attr_value_literal_data ($eref_node, \$ev, $o2,
                                                          entMan => $opt{entMan});
            $eref_node->flag (smxp__ref_expanded => 1);
          } else {
            $self->_raise_error ($o, type => 'WFC_NO_EXTERNAL_ENTITY_REFERENCE', 
                                 c => $eref_node, t => $entity_ref);
            $rt .= $entity_ref;
          }
        }	# ref recursive?
      }	# entity declared or not declared
      $self->_clp ($entity_ref => $o);
    } elsif ($$s =~ s/^([^&<]+)//s) {
      my $tt = $1;
      $tt =~ tr/\x09\x0A\x0D/\x20\x20\x20/;
      $c->append_text ($tt);
      $rt .= $tt;
      $self->_clp ($tt => $o);
    } elsif ($$s =~ s/^<//) {
      $self->_raise_error ($o, c => $c, type => 'WFC_NO_LE_IN_ATTRIBUTE_VALUE');
      $rt .= '<';
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      $rt .= substr ($$s, 0, 1);
      substr ($$s, 0, 1) = '';
    }
  }	# $$s
  ## Note: Implementation of normalize for non-CDATA attribute values should be done
  ##       out of this module.
  #if ({qw/ID 1 IDREF 1 IDREFS 1 NMTOKEN 1 NMTOKENS 1
  #        NOTATION 1 NOTATIONS 1/}->{$opt{attr_type}}) {
  #  $rt =~ s/\x20\x20+/\x20/g;
  #  $rt =~ s/^\x20+//;  $rt =~ s/\x20+$//;
  #}
  $rt;
}

sub _parse_rpdata ($$\$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  my $tt = '';
  while ($$s) {
    if ($$s =~ s/^$xml_re{PEReference_M}//) {
      my ($ref, $ename) = ('%'.$1.';', $1);
      $self->_raise_error ($o, type => 'WFC_PE_IN_INTERNAL_SUBSET', t => $ref)
        if $o->{entity_type} eq 'document_entity';
      $self->_raise_error ($o, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ref)
        if index ($ename, ':') > -1;
      my $eref = $c->append_new_node (type => '#reference', local_name => $ename,
                                      namespace_uri => $NS{SGML}.'entity:parameter');
      unless ($opt{dont_resolve_entity_ref}) {
        my $entity = $opt{entMan}->get_entity ($ename,
                                               namespace_uri => $NS{SGML}.'entity:parameter');
        if (!ref $entity) {
          $self->_raise_error ($o, c => $c, type => 'VC_ENTITY_DECLARED', t => $ref);
        } else {
          my $o2 = $self->_make_clone_of ($o);
          if ($o2->{__entities}->{$ref}) {
            $self->_raise_error ($o, c => $c, type => 'WFC_NO_RECURSION', t => $ref);
          } elsif (defined ($entity->flag ('smxp__entity_replacement_text_rpdata'))) {
            my $ev = $entity->flag ('smxp__entity_replacement_text_rpdata');
            $eref->append_text ($ev);
            $tt .= $ev;
          } else {
            $o2->{entity} = $ref;
            my $entity_value = $entity->get_attribute ('value');
            if (ref $entity_value) {	## Internal entity
              $o2->{__entities}->{$ref} = 1;
              $o2->{uri} = $entity->flag ('smxp__uri_in_which_declaration_is');
              $o2->{line} = 0; $o2->{pos} = 0;
              my $ev = $entity_value->_entity_parameter_literal_value;
              $ev = $self->_parse_rpdata ($eref, \$ev, $o2, entMan => $opt{entMan});
              $entity->flag (smxp__entity_replacement_text_rpdata => $ev);
              $tt .= $ev;
            } else {	## External entity
              $o2->{entity_type} = 'external_parameter_entity';
              $c->root_node->flag (smxp__declaration_may_not_be_read => 1)
                if !(index ($o->{entity_type}, 'external') > -1)
                || !$opt{entMan}->is_standalone_document;
              my $ext_ent = $opt{entMan}->get_external_entity ($self, $entity, $o2);
              if ($ext_ent->{NDATA}) {	## non-parsed entity
                $self->_raise_error ($o, type => 'WFC_PARSED_ENTITY', c => $entity, t => $ref);
              } elsif ($ext_ent->{error}->{no_data}) {	## parsed entity but can't be retrived
                $self->_raise_error ($o, type => 'ERR_EXT_ENTITY_NOT_FOUND', c => $entity,
                                         t => [$ref, $o2->{uri}, $ext_ent->{error}->{reason_text}]);
                $c->root_node->flag (smxp__stop_read_dtd => 1)
                  unless $opt{entMan}->is_standalone_document;
              } else {	## parsed entity
                $o2->{__entities}->{$ref} = 1;
                my $ev = $ext_ent->{text};
                $ev = $self->_parse_rpdata ($eref, \$ev, $o2, entMan => $opt{entMan});
                $entity->flag (smxp__entity_replacement_text_rpdata => $ev);
                $tt .= $ev;
                $eref->flag (smxp__ref_expanded => 1);
              }	# external parsed entity
            }	# external entity
          }	# not recursive
        }	# entity defined
      }	# read not stopped
      $self->_clp ($ref => $o);
    } elsif ($$s =~ s/^([^%]+)//) {
      my $t = $1; my $r = '';
      while ($t) {
        if ($t =~ s/^&#(?:x([0-9A-Fa-f]+)|([0-9]+));//) {
          for (chr ($1 ? hex ($1) : $2)) {
            $self->_warn_char_val ($o, $_, ref => 1);
            $r .= $_;
            $c->append_new_node (type => '#reference', value => ord $_,
                                 namespace_uri => $NS{SGML}.'char:ref'.(defined $1 ? ':hex' : ''));
          }
          $self->_clp ((defined $1 ? '___':'__').$1 => $o);
        } elsif ($t =~ s/^&($xml_re{Name});//) {
          my ($entity_ref, $eref) = ($1, '&'.$1.';');
          $r .= $entity_ref;
          $self->_raise_error ($o, type => 'NS_SYNTAX_NAME_IS_NCNAME', c => $c, t => $entity_ref)
            if index ($eref, ':') > -1;
          my $entity = $opt{entMan}->get_entity ($eref);
          if (ref ($entity) && ref ($entity->get_attribute ('NDATA'))) {
            $self->_raise_error ($o, type => 'ERR_XML_NDATA_REF_IN_ENTITY_VALUE',
                                 c => $c, t => $entity_ref);
            ## Note: this error is not raisen when the entity referred is declared after
            ##       the EntityValue occurs.
            ## Note: this error was a fatal error, but refined by XML 1.0 SE Errata.
          }
          $c->append_new_node (type => '#reference', namespace_uri => $NS{SGML}.'entity',
                               local_name => $eref);
          $self->_clp ($entity_ref => $o);
        } elsif ($t =~ s/^&//) {
          $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', c => $c, t => '&');
          $r .= '&';
          $c->append_new_node (type => '#reference', namespace_uri => $NS{SGML}.'char:ref',
                               value => 0x26);
          $self->_clp (_ => $o);
        } elsif ($t =~ s/^([^&]+)//s) {
          $r .= $1;
          $c->append_new_node (type => '#text', value => $1);
          $self->_clp ($1 => $o);
        }
      }
      $tt .= $r;
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      $self->_clp (substr ($$s, 0, 1) => $o);
      substr ($$s, 0, 1) = '';
    }
  }	# while $$s
  $tt;
}

sub _parse_md_params ($$$$$;%) {
  my ($self, $c, $s, $o, %opt) = @_;
  my $t = '';
  while ($$s) {
    if ($$s =~ s/^$xml_re{PEReference_M}//) {
      my ($ref, $ename) = ('%'.$1.';', $1);
      $self->_raise_error ($o, c => $c, type => 'WFC_PE_IN_INTERNAL_SUBSET', t => $ref)
        if $o->{entity_type} eq 'document_entity';
      $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ref)
        if index ($ename, ':') > -1;
      my $eref = $c->append_new_node (type => '#reference', local_name => $ename,
                                      namespace_uri => $NS{SGML}.'entity:parameter');
      unless ($opt{dont_resolve_entity_ref}) {
        my $entity = $opt{entMan}->get_entity ($ename,
                                               namespace_uri => $NS{SGML}.'entity:parameter');
        if (!ref $entity) {
          $self->_raise_error ($o, c => $c, type => 'VC_ENTITY_DECLARED', t => $ref);
        } else {
          if ($o->{__entities}->{$ref}) {
            $self->_raise_error ($o, c => $c, type => 'WFC_NO_RECURSION', t => $ref);
          } elsif (defined ($entity->flag ('smxp__entity_replacement_text_md_params'))) {
            $t .= ' '.$entity->flag ('smxp__entity_replacement_text_md_params').' ';
          } else {
            my $o2 = $self->_make_clone_of ($o);
            $o2->{entity} = $ref;
            my $entity_value = $entity->get_attribute ('value');
            if (ref $entity_value) {	## Internal entity
              $o2->{__entities}->{$ref} = 1;
              $o2->{uri} = $entity->flag ('smxp__uri_in_which_declaration_is');
              $o2->{line} = 0; $o2->{pos} = 0;
              my $ev = $entity_value->_entity_parameter_literal_value;
              $ev = $self->_parse_md_params ($eref, \$ev, $o2, entMan => $opt{entMan});
              $entity->flag (smxp__entity_replacement_text_md_params => $ev);
              $t .= ' '.$ev.' ';
              $eref->flag (smxp__ref_expanded => 1);
            } else {	## External entity
              $o2->{entity_type} = 'external_parameter_entity';
              $c->root_node->flag (smxp__declaration_may_not_be_read => 1)
                if !(index ($o->{entity_type}, 'external') > -1)
                || !$opt{entMan}->is_standalone_document;
              my $ext_ent = $opt{entMan}->get_external_entity ($self, $entity, $o2);
              if ($ext_ent->{NDATA}) {	## non-parsed entity
                $self->_raise_error ($o, type => 'WFC_PARSED_ENTITY', c => $entity, t => $ref);
              } elsif ($ext_ent->{error}->{no_data}) {	## parsed entity but can't be retrived
                $self->_raise_error ($o, type => 'ERR_EXT_ENTITY_NOT_FOUND', c => $entity,
                                         t => [$ref, $o2->{uri}, $ext_ent->{error}->{reason_text}]);
                $c->root_node->flag (smxp__stop_read_dtd => 1)
                  unless $opt{entMan}->is_standalone_document;
              } else {	## parsed entity
                $o2->{__entities}->{$ref} = 1;
                my $ev = $ext_ent->{text};
                $ev = $self->_parse_md_params ($eref, \$ev, $o2, entMan => $opt{entMan});
                $entity->flag (smxp__entity_replacement_text_md_params => $ev);
                $t .= ' '.$ev.' ';
                $eref->flag (smxp__ref_expanded => 1);
              }	# external parsed entity
            }	# external entity
          }	# not recursive
        }	# entity defined
      }	# not stopped
      $c->flag (smxp__defined_with_param_ref => 1);
      $self->_clp ($ref => $o);
    } elsif ($$s =~ s/^($xml_re{__AttValue_simple})//s) {
      my $all = $1;
      $t .= $all;
      $c->append_new_node (type => '#xml', value => $all);	## Note: is this safe?
      $self->_clp ($all => $o);
    } elsif ($$s =~ s/^(\p{InXMLNameChar}+)//) {
      $c->append_text ($1);
      $t .= $1;
      $self->_clp ($1 => $o);
      if ($$s =~ s/^([+*?])//) {
        $c->append_text ($1);
        $t .= $1;
        $self->_clp (_ => $o);
      }
    } elsif ($$s =~ s/^\(//) {
      $c->append_text ('(');
      my $grp = $c->append_new_node (type => '#element', namespace_uri => $NS{SGML}.'group');
      $t .= '('.$self->_parse_md_params ($grp, $s, $o, entMan => $opt{entMan}, return_by_grpc => 1);
      $c->flag (smxp__defined_with_param_ref => 1)
        if $grp->flag ('smxp__defined_with_param_ref');
    } elsif ($$s =~ s/^([%#,|])//) {
      $c->append_text ($1);
      $t .= $1;
      $self->_clp ($1 => $o);
    } elsif ($$s =~ s/^($xml_re{s})//s) {
      $c->append_text ($1);
      $t .= $1;
      $self->_clp ($1 => $o);
    } elsif ($opt{return_by_mdc} && ($$s =~ s/^>//)) {	## mdc
      $self->_clp (_ => $o);
      return $t;
    } elsif (($opt{return_by_mdc}||$opt{return_by_grpc}) && ($$s =~ m/^</)) {	## maybe mdo
      $self->_raise_error ($o, type => 'SYNTAX_END_OF_MARKUP_NOT_FOUND', t => $c, c => $c);
      return $t;
    } elsif ($opt{return_by_grpc} && ($$s =~ s/^\)//)) {	## grpc
      $self->_clp (_ => $o);
      $t .= ')';
      $c->parent_node->append_text (')');
      if ($$s =~ s/^([+*?])//) {
        $t .= $1;
        $c->parent_node->append_text ($1);
        $self->_clp (_ => $o);
      }
      return $t;
    } else {
      $self->_raise_error ($o, type => 'SYNTAX_INVALID_CHAR', t => substr ($$s, 0, 10));
      $self->_clp (substr ($$s, 0, 1) => $o);
      substr ($$s, 0, 1) = '';
    }
  }	# while
  if ($opt{return_by_grpc}) {
    $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_GROUP_NOT_CLOSED');
    $t .= ')';
  }
  $t;
}

sub _warn_char_val ($$$%) {
  my ($self, $o, $ch, %o) = @_;
  if ($ch =~ /^(.*?)(\P{InXMLChar})/) {
    $self->_clp ($1 => $o);
    $self->_raise_error ($o, type => (($o{ref}?'WFC':'SYNTAX').'_LEGAL_CHARACTER'), t => ord $2);
  } elsif ($ch =~ /^(.*?)(\p{InXML_deprecated_noncharacter})/) {
    $self->_clp ($1 => $o);
    $self->_raise_error ($o, type => 'WARN_UNICODE_NONCHARACTER', t => ord $2);
  } elsif ($ch =~ /^(.*?)(\p{Compat})/) {
    $self->_clp ($1 => $o);
    $self->_raise_error ($o, type => 'WARN_UNICODE_COMPAT_CHARACTER', t => ord $2);
  } elsif ($ch =~ /^(.*?)(\p{InXML_unicode_xml_not_suitable})/) {
    $self->_clp ($1 => $o);
    $self->_raise_error ($o, type => 'WARN_UNICODE_XML_NOT_SUITABLE_CHARACTER', t => ord $2);
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
                                namespace_uri => $NS{SGML}.'char:ref:hex');
    } elsif ($ref =~ /([0-9]+)/) {
      my $ch = 0+$1;
      $self->_warn_char_val ($o, chr $ch, ref => 1);
      $r = $c->append_new_node (type => '#reference', value => $ch,
                                namespace_uri => $NS{SGML}.'char:ref');
    } else {
      $self->_raise_error ($o, type => 'UNKNOWN', t => $ref);
    }
  $self->_clp ($ref => $o);
  $r;
}

sub _parse_ignored_marked_section ($$\$$;%) {
  my ($self, $c, $s, $o) = @_;
  while ($$s) {
    if ($$s =~ s/^<!\[//) {
      $self->_clp (___ => $o);
      $self->_parse_ignored_marked_section ($c->append_new_node (type => '#section'), $s, $o);
    } elsif ($$s =~ s/^\]\]>//) {
      $self->_clp (___ => $o);
      return undef;
    } elsif ($$s =~ s/^((?:(?!<!\[|\]\]>).)+)//s) {
      $c->append_text ($1);
      $self->_clp ($1 => $o);
    }
  }	# $$s
  $self->_raise_error ($o, c => $c, type => 'SYNTAX_END_OF_MARKUP_NOT_FOUND', t => $c);
  undef;
}

sub _parse_xml_or_text_declaration ($$\$$) {
  my ($self, $c, $s, $o) = @_;
  if ($$s =~ s/^$xml_re{_xml_PI_M}//s) {
    my $data = $1;
    $self->_clp (_____ => $o);
    if (length $data) {
      $self->_parse_xml_declaration ($c, $data, $o);
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
    }
    $self->_clp (__ => $o);
  }
}
sub _parse_xml_declaration ($$$$) {
  my ($self, $c, $attrs, $o) = @_;
  my $stage = 0;	# 0: <?xml, 1: version="", 2: encoding="", 3: standalone="", 4: ?>
  $attrs = ' ' . $attrs;
  while ($attrs) {
    if ($attrs =~ s/^($xml_re{s}version(?:$xml_re{s})?=(?:$xml_re{s})?("[A-Za-z0-9_.:-]+"|'[A-Za-z0-9_.:-]+'))//s) {
      my $version = substr ($2, 1, length ($2) - 2);
      if ($stage > 0) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => 'version');
      }
      $c->set_attribute (version => $version);
      ## TODO: XML 1.1 support
      if ($version ne '1.0') {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_UNSUPPORTED_XML_VERSION', t => $version);
      }
      $self->_clp ($1 => $o); $stage++;
    } elsif ($attrs =~ s/^($xml_re{s}encoding(?:$xml_re{s})?=(?:$xml_re{s})?("[A-Za-z0-9_.-]+"|'[A-Za-z0-9_.:-]+'))//s) {
      if ($stage > 2) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => 'encoding');
      } elsif ($stage == 0) {	## No version pseudo-attr
        if ($o->{entity_type} eq 'document_entity') {
          $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_VERSION_ATTR');
          $c->set_attribute (version => '1.0');
        } else {
          $self->_raise_error ($o, c => $attrs, type => 'WARN_XML_DECLARE_NO_VERSION_ATTR');
          $o->{entity_type} = 'external_parsed_entity';
        }
      }
      $c->set_attribute (encoding => substr ($2, 1, length ($2) - 2));
      $self->_clp ($1 => $o); $stage = 2;
    } elsif ($attrs =~ s/^($xml_re{s}standalone(?:$xml_re{s})?=(?:$xml_re{s})?("(?:yes|no)"|'(?:yes|no)'))//s) {
      if ($stage == 0) {	## 'version' or 'encoding' is expected
        if ($o->{entity_type} eq 'document_entity') {	## XML declaration
          $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_VERSION_ATTR');
          $c->set_attribute (version => '1.0');
        } else {	## Text declaration
          $self->_raise_error ($o, c => $attrs, type => 'WARN_XML_DECLARE_NO_VERSION_ATTR');
          $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ENCODING_ATTR');
          $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_STANDALONE_ATTR');
        }
      } elsif ($stage > 3) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => 'standalone');
      }
      $c->set_attribute (standalone => (substr ($2, 1, 1) eq 'y' ? 'yes' : 'no'));
      $self->_clp ($1 => $o); $stage = 3;
    } elsif ($attrs =~ s/^($xml_re{s})//s) {
      my $s = $1;
      if ($stage == 0) {
        $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
        $c->set_attribute (version => '1.0');
      }
      $self->_clp ($s, $o); $stage = 4;
    } else {
      $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE', t => $attrs);
      $self->_clp ($attrs => $o); undef $attrs;
    }
  }	# while
  if ($stage == 0) {
    $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ATTR');
    $c->set_attribute (version => '1.0');
  } elsif ($stage == 1 && index ($o->{entity_type}, 'external') > -1) {
    $self->_raise_error ($o, c => $attrs, type => 'SYNTAX_XML_DECLARE_NO_ENCODING_ATTR');
  }
}

sub _parse_entity_declaration ($$$$;%) {
    my ($self, $s, $c, $o, %opt) = @_;
    my $p;	## notation ? 'n' : parameter entity ? '%' : undef;
    my $root_node = $c->root_node;
    my $e = $c->append_new_node (type => '#declaration');
      $e->flag (smxp__uri_in_which_declaration_is => $o->{uri});
      $e->flag (smxp__declaration_may_not_be_read
                => $root_node->flag ('smxp__declaration_may_not_be_read'));
    ## Entity? or notation?
    if ($$s =~ s/^<!ENTITY//) {
      $e->namespace_uri ($NS{SGML}.'entity');
      $self->_clp (________ => $o);
    } else {
      $$s =~ s/^<!NOTATION//;
      $e->namespace_uri ($NS{SGML}.'notation');
      $self->_clp (__________ => $o); $p = 'n';
    }
    ## Parameters
    my $t;
    my $dont_process = $root_node->flag ('smxp__stop_read_dtd');
    $t = $self->_parse_md_params ($e, $s, $o, dont_resolve_entity_ref => $dont_process,
                                  return_by_mdc => 1, entMan => $opt{entMan});
    $dont_process = $root_node->flag ('smxp__stop_read_dtd');
    unless ($dont_process) {
      my $o = $self->_make_clone_of ($o);
      my $is_internal = 1;
      $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
        unless $t =~ s/^$xml_re{s}//s;
      if ($t =~ s/^%//) {
        if ($p eq 'n') {
          $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => '%');
        } else {
          $e->namespace_uri ($NS{SGML}.'entity:parameter'); $p = '%';
        }
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
          unless $t =~ s/^$xml_re{s}//s;
      }
      my $ename;
      if ($t =~ s/^($xml_re{Name})//) {
        $ename = $1;
        if ($opt{entMan}->is_declared_entity ($ename, namespace_uri => $e->namespace_uri,
                                         dont_use_predefined_entities => 1,
                                         seek => 0)) {
          if ($p eq 'n') {
            $self->_raise_error ($o, c => $e,
                                 type => 'VC_UNIQUE_NOTATION_NAME', t => $ename);
          } else {
            $self->_raise_error ($o, c => $e, t => $ename,
                                 type => 'WARN_UNIQUE_'.($p eq '%' ? 'PARAMETER_' : '').'ENTITY_NAME');
          }
        } else {	## Regist to entMan
          $opt{entMan}->is_declared_entity ($ename, namespace_uri => $e->namespace_uri,
                                       dont_use_predefined_entities => 1,
                                       set_value => $e, seek => 0);
        }
        $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_NCNAME', t => $ename)
          if index ($ename, ':') > -1;
        $e->local_name ($ename);
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
          unless $t =~ s/^$xml_re{s}//s;
      } else {
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_MD_NAME_NOT_FOUND',
                             t => substr ($t, 0, 10));
      }
      if ($t =~ s/^PUBLIC//) {
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
          unless $t =~ s/^$xml_re{s}//s;
        unless ($t =~ s/^($xml_re{__AttValue_simple})//s) {	## TODO: new error
          $self->_raise_error ($o, c => $e, type => 'SYNTAX_MD_PID_NOT_FOUND',
                               t => substr ($t, 0, 10));
        } else {
          $e->set_attribute (PUBLIC => $opt{entMan}->check_public_id
                                                      ($o, substr ($1, 1, length ($1) - 2)));
          my $f = $t =~ s/^$xml_re{s}//s ? 1 : 0;
          if ($t =~ s/^($xml_re{__AttValue_simple})//s) {
            $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
              unless $f;
            $e->set_attribute (SYSTEM => $opt{entMan}->check_system_id
                                                        ($o, substr ($1, 1, length ($1) - 2)));
          } else {
            if ($p ne 'n') {
              $self->_raise_error ($o, c => $e, type => 'SYNTAX_MD_SYSID_NOT_FOUND',
                                   t => substr ($t, 0, 10));
              $e->set_attribute (SYSTEM => $NS{internal_invalid_sysid});
            }
          }
        }
        $is_internal = 0;
      } elsif ($t =~ s/^SYSTEM//) {
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
          unless $t =~ s/^$xml_re{s}//s;
        if ($t =~ s/^($xml_re{__AttValue_simple})//s) {
          $e->set_attribute (SYSTEM => $opt{entMan}->check_system_id
                                                      ($o, substr ($1, 1, length ($1) - 2)));
        } else {	## TODO: error text
          $self->_raise_error ($o, c => $e, type => 'SYNTAX_MD_SYSID_NOT_FOUND',
                               t => substr ($t, 0, 10));
          $e->set_attribute (SYSTEM => $NS{internal_invalid_sysid});
        }
        $is_internal = 0;
      } elsif ($p ne 'n' && $t =~ s/^($xml_re{__AttValue_simple})//s) {	## EntityValue (ENTITY only)
        ## TOTO: $o
        my $ev = $1; $ev = substr ($ev, 1, length ($ev) - 2);
        $ev = $self->_parse_rpdata ($e->set_attribute ('value'), \$ev, $o, entMan => $opt{entMan});
        unless (defined $e->flag ('smxp__entity_replacement_text_rpdata')) {
          $e->flag (smxp__entity_replacement_text_rpdata => $ev);
        }
              if (($p ne '%') && {qw/lt 1 gt 1 amp 1 quot 1 apos 1/}->{$ename}) {
                ## TODO: check when external entity too
                $self->_raise_error ($o, c => $e,
                                     type => 'FATAL_ERR_PREDEFINED_ENTITY', t => [$ename, $ev])
                  unless {qw/lt|&#60;  1 gt|&#62;  1 amp|&#38;  1 apos|&#39;  1 quot|&#34;  1
                             lt|&#x3c; 1 gt|&#x3e; 1 amp|&#x26; 1 apos|&#x27; 1 quot|&#x22; 1
                                         gt|>      1              apos|'      1 quot|"      1
                            /}->{$ename.'|'.lc ($ev)};
              }
      }
      if ($t =~ s/^$xml_re{s}NDATA//s) {
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10))
          unless $t =~ s/^$xml_re{s}//s;
        unless ($t =~ s/^($xml_re{Name})//s) {
          $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10));
        } else {
          my $nname = $1;
          if ($p eq '%') {	## parameter entity
            $self->_raise_error ($o, c => $e, type => 'SYNTAX_PE_NDATA', t => $nname);
          } elsif ($is_internal) {
            $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_KEYWORD', t => 'NDATA');
          } else {
            $e->set_attribute (NDATA => $nname)
              ->flag (smxp__src_pos => $o);
          }
        }
      }
      $t =~ s/^$xml_re{s}//s;
      if (length $t) {
        $self->_raise_error ($o, c => $e, type => 'SYNTAX_INVALID_MD', t => $t);
      }
    } else {	## dont_process
      $c->flag (smxp__non_processed_declaration => 1);
      $self->_raise_error ($o, c => $c, type => 'WARN_ENTITY_DECLARATION_NOT_PROCESSED');
    }
}

sub _parse_element_declaration ($$$$;%) {
  my ($self, $s, $c, $o, %opt) = (@_);
  $c = $c->append_new_node (type => '#declaration', namespace_uri => $NS{SGML}.'element');
  unless ($$s =~ s/^<!ELEMENT//s) {
    $self->_raise_error ($o, type => 'UNKNOWN', c => $c, t => substr ($$s, 0, 10));
    return;
  }
  $self->_clp (_________ => $o);
  
  my $t = $self->_parse_md_params ($c, $s, $o, entMan => $opt{entMan}, return_by_mdc => 1);
  
  ## Element type name
  if ($t =~ s/^($xml_re{s}($xml_re{Name}))//s) {
    my $type_qname = $2;
    if (substr ($type_qname, 0, 1) eq ':' || substr ($type_qname, -1, 1) eq ':') {
      $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_QNNAME', t => $type_qname);
      $type_qname =~ tr/:/_/;
    }
    if ($opt{entMan}->is_declared_entity ($type_qname, namespace_uri => $NS{SGML}.'element',
                                          seek => 0)) {
      $self->_raise_error ($o, c => $c,
                           type => 'VC_UNIQUE_ELEMENT_TYPE_NAME', t => $type_qname);
    } else {	## Regist to entMan
      $opt{entMan}->is_declared_entity ($type_qname, namespace_uri => $NS{SGML}.'element',
                                        set_value => $c, seek => 0);
    }
    $c->set_attribute (qname => $type_qname);
  } else {
    $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10));
    return;
  }
  
  ## No content model declaration
  $t =~ s/^$xml_re{s}//s;
  unless ($t) {
    $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10));
    return;
  }
  
  ## Content model
  my $delimited = 1;
  my $in_group = 0;
  my @grp_connector;
  my $is_pcdata;
  my $r = $c;
  while ($t) {
    if ($t =~ s/^$xml_re{s}//s) {
      #
    } elsif ($t =~ s/^($xml_re{Name})//) {
      my $name = $1;
      if ($in_group) {
        unless ($delimited) {
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_NO_DELIMITER',
                               t => $name);
        } else {
          $delimited = 0;
        }
        if (substr ($name, 0, 1) eq ':' || substr ($name, -1, 1) eq ':') {
          $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_QNNAME', t => $name);
          $name =~ tr/:/_/;
        }
        my $enode = $c->append_new_node (type => '#element', namespace_uri => $NS{SGML}.'element',
                                         local_name => 'element');
        $enode->set_attribute (qname => $name);
        if ($t =~ s/^([+*?])//) {
          $enode->set_attribute (occurence => $1);
        }
      } else {
        if ({qw/EMPTY 1 ANY 1/}->{$name}) {
          # 
        } elsif ({qw/PCDATA 1 CDATA 1/}->{$name}) {
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_SGML_KWD',
                               t => $name);
        } else {
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_UNKNOWN_KWD',
                               t => $name);
        }
        $r->set_attribute (content => $name);
        last;
      }	# out of group
    } elsif ($in_group && $t =~ s/^\#($xml_re{Name})//) {
      my $kwd = $1;
      unless ($delimited) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_NO_DELIMITER',
                             t => $kwd);
      } else {
        $delimited = 0;
      }
      if ($in_group > 1 || $grp_connector[$in_group]) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_KWD_POSITION',
                             t => $kwd);
      }
      if ($kwd ne 'PCDATA') {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_UNKNOWN_KWD',
                             t => $kwd);
      } else {
        $is_pcdata = 1;
        $r->set_attribute (content => 'mixed');
      }
    } elsif ($in_group && $t =~ s/^([|,&])//) {
      my $connector = $1;
      if ($delimited) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_INVALID_CONNECTOR',
                             t => $connector.substr ($t, 0, 9));
      } else {
        $delimited = 1;
      }
      if ($connector eq '&') {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_SGML_CONNECTOR',
                             t => $connector);
        $connector = ',';
      } elsif ($is_pcdata && $connector ne '|') {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_PCDATA_CONNECTOR',
                             t => $connector);
        $connector = '|';
      }
      unless ($grp_connector[$in_group]) {
        $grp_connector[$in_group] = $connector;
        $c->set_attribute (connector => $connector);
      } elsif ($grp_connector[$in_group] ne $connector) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_SAME_CONNECTOR',
                             t => [$grp_connector[$in_group], $connector]);
      }
    } elsif ($t =~ s/^\(//) {
      unless ($delimited) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_NO_DELIMITER',
                             t => '('.substr ($t, 0, 9));
      }
      if ($is_pcdata) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_MIXED_NESTED');
      } else {
        $c = $c->append_new_node (type => '#element', namespace_uri => $NS{SGML}.'element',
                                  local_name => 'group');
      }
      $in_group++;
      $grp_connector[$in_group] = undef;
      $delimited = 1;
    } elsif ($in_group && $t =~ s/^\)//) {
      if ($delimited) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_INVALID_CONNECTOR',
                             t => ')'.substr ($t, 0, 9));
        $delimited = 0;
      }
      if ($t =~ s/^([+*?])//) {
        my $occur = $1;
        if ($is_pcdata && $occur ne '*') {
          $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_MIXED_OCCURENCE',
                               t => $occur);
        }
        $c->set_attribute (occurence => $occur);
      } elsif ($is_pcdata && $grp_connector[$in_group]) {
        $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_MIXED_OCCURENCE');
      }
      $c = $c->parent_node;
      $in_group--;
      last if !$in_group;
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10));
      substr ($t, 0, 1) = '';
    }
  }	# $t
  if ($in_group) {
    ## Note: Maybe this error will not happen since md_params parsing report it
    $self->_raise_error ($o, c => $c, type => 'SYNTAX_ELEMENT_CMODEL_GROUP_NOT_CLOSED');
  }
  
  if ($t =~ /[^$xml_re{_s__chars}]/) {
    $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_MD', t => $t);
  }
}


sub _parse_attlist_declaration ($$$$;%) {
  my ($self, $s, $c, $o, %opt) = (@_);
  my $root_node = $c->root_node;
  $c = $c->append_new_node (type => '#declaration', namespace_uri => $NS{SGML}.'attlist');
      $c->flag (smxp__declaration_may_not_be_read
                => $root_node->flag ('smxp__declaration_may_not_be_read'));
  unless ($$s =~ s/^<!ATTLIST//s) {
    $self->_raise_error ($o, type => 'UNKNOWN', c => $c, t => substr ($$s, 0, 10));
    return;
  }
  $self->_clp (_________ => $o);
  
  my $dont_process = $root_node->flag ('smxp__stop_read_dtd');
  my $t = $self->_parse_md_params ($c, $s, $o, entMan => $opt{entMan}, return_by_mdc => 1);
  $dont_process = $root_node->flag ('smxp__stop_read_dtd');
  
  unless ($dont_process) {
    ## Element type name
    my $type_qname;
    if ($t =~ s/^($xml_re{s}($xml_re{Name}))//s) {
      $type_qname = $2;
      if (substr ($type_qname, 0, 1) eq ':' || substr ($type_qname, -1, 1) eq ':') {
        $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_QNNAME', t => $type_qname);
        $type_qname =~ tr/:/_/;
      }
      if ($opt{entMan}->is_declared_entity ($type_qname, namespace_uri => $NS{SGML}.'attlist',
                                            dont_use_predefined_entities => 1,
                                            seek => 0)) {
        $self->_raise_error ($o, c => $c,
                             type => 'WARN_XML_ATTLIST_AT_MOST_ONE_DECLARATION', t => $type_qname);
      } else {	## Regist to entMan
        $opt{entMan}->is_declared_entity ($type_qname, namespace_uri => $NS{SGML}.'attlist',
                                          dont_use_predefined_entities => 1,
                                          set_value => $c, seek => 0)
      }
      $c->set_attribute (qname => $type_qname);
    } else {
      $self->_raise_error ($o, c => $c, type => 'SYNTAX_INVALID_MD', t => substr ($t, 0, 10));
      return;
    }
    
    ## Definition
    my %defined;
    while ($t) {
      if ($t =~ s/^$xml_re{s}($xml_re{Name})//s) {
        my %attr = (name => $1, type => undef);
        if (substr ($attr{name}, 0, 1) eq ':' || substr ($attr{name}, -1, 1) eq ':') {
          $self->_raise_error ($o, c => $c, type => 'NS_SYNTAX_NAME_IS_QNNAME', t => $attr{name});
          $attr{name} =~ tr/:/_/;
        }
        if ($defined{$attr{name}}) {
          $self->_raise_error ($o, c => $c, type => 'WARN_XML_ATTLIST_AT_MOST_ONE_ATTR_DEF',
                               t => $attr{name});
        } else {
          $defined{$attr{name}} = 1;
        }
        $attr{node} = $c->append_new_node (type => '#element', namespace_uri => $NS{XML}.'attlist',
                                           local_name => 'AttDef');
        $attr{node}->set_attribute (qname => $attr{name});
        if ($t =~ s/^$xml_re{s}//s) {
          if ($t =~ s/^NOTATION//) {
            $attr{type} = 'NOTATION';
            unless ($t =~ s/^$xml_re{s}//s) {
              $self->_raise_error ($o, type => 'SYNTAX_INVALID_MD', c => $c,
                                   t => substr ($t, 0, 10));
            }
          }
          if (!$attr{type} && $t =~ s/^([A-Za-z]+)//) {	# attname type
            $attr{type} = $1;
            unless ({qw/CDATA 1 ID 1 IDREF 1 IDREFS 1 NMTOKEN 1 NMTOKENS 1
                        ENTITY 1 ENTITIES 1/}->{$attr{type}}) {
              $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_UNKNOWN_TYPE',
                                   c => $c, t => $attr{type});
            }
          } elsif ($t =~ s/^\(([^)]+)\)//) {	# attname (group)
            my $grp = $1;
            if (index ($grp, '(') > -1) {
              $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_NESTED_GROUP',
                                   c => $c, t => $grp);
            }
            if (index ($grp, '&') > -1 || index ($grp, ',') > -1) {
              $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_NON_BAR_CONNECTOR',
                                   c => $c, t => $grp);
            }
            if ($grp =~ s/([^\p{InXMLNameChar}$xml_re{_s__chars}|])//s) {
              $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_GROUP_INVALID_CHAR',
                                   c => $c, t => $1);
              $grp =~ s/([^\p{InXMLNameChar}$xml_re{_s__chars}|])//sg;
            } else {
              $grp =~ tr/\x09\x0A\x0D\x20//d;	# $xml_re{_s__chars}
              if ($grp =~ /(^\||\|\||\|$)/) {
                $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_GROUP_INVALID_CONNECTOR',
                                     c => $c, t => $1);
              }
            }
            my @grp = grep {$_} split /\P{InXMLNameChar}+/, $grp;
            if ($attr{type}) {	## NOTATION
              for (@grp) {
                $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_GROUP_NOTATION_NAME',
                                     c => $c, t => $_)
                  unless /^$xml_re{Name}$/;
              }
            } else {
              $attr{type} = 'enum';
            }
            for (@grp) {
              if ($attr{enum}->{$_}) {
                $self->_raise_error ($o, type => 'VC_NO_DUPLICATE_TOKENS', c => $c, t => $_);
              } else {
                $attr{enum}->{$_} = 1;
                $attr{node}->append_new_node (type => '#element',
                                              namespace_uri => $NS{XML}.'attlist',
                                              local_name => 'enum')
                           ->append_text ($_);
              }
            }
          } else {	# attname #somewhat or attname NOTATION non-group
            $self->_raise_error ($o, type => 'SYNTAX_INVALID_MD', c => $c, t => substr ($t, 0, 10));
            $attr{type} ||= 'CDATA';
            next;
          }
          $attr{node}->set_attribute (type => $attr{type});
          
          ## DefaultDecl
          if ($t =~ s/^$xml_re{s}\#FIXED//s) {
            $attr{deftype} = 'FIXED';
            $attr{node}->set_attribute (default_type => $attr{deftype});
          }
          if ($t =~ s/^$xml_re{s}//s) {
            if (!$attr{deftype} && $t =~ s/^\#([A-Za-z-]+)//) {
              $attr{deftype} = $1;
              unless ({qw/IMPLIED 1 REQUIRED 1/}->{$attr{deftype}}) {
                $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_UNKNOWN_DEFAULT', c => $c,
                                     t => '#'.$attr{deftype});
              }
              $attr{node}->set_attribute (default_type => $attr{deftype});
            } elsif ($t =~ s/^($xml_re{__AttValue_simple})//s) {	# attname type "literal"
              $attr{defvalue} = $attr{node}->set_attribute ('default_value');
              my $pcdata = substr ($1, 1, length ($1) - 2);
              $self->_parse_attr_value_literal_data ($attr{defvalue}, \$pcdata, $o,
                                                     entMan => $opt{entMan});
            } elsif ($attr{deftype}) {	# deftype eq FIXED
              $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_FIXED_NO_LITERAL', c => $c,
                                   t => [$attr{name}, substr ($t, 0, 10)]);
              next;
            } else {	# attname type $invalid
              $self->_raise_error ($o, type => 'SYNTAX_INVALID_MD', c => $c,
                                   t => substr ($t, 0, 10));
              next;
            }
          } elsif ($attr{deftype}) {	# deftype eq FIXED
            $self->_raise_error ($o, type => 'SYNTAX_ATTLIST_ATTDEF_FIXED_NO_LITERAL', c => $c,
                                 t => [$attr{name}, substr ($t, 0, 10)]);
            next;
          } else {	# attname type$invalid
            $self->_raise_error ($o, type => 'SYNTAX_INVALID_MD', c => $c, t => substr ($t, 0, 10));
            next;
          }
        } else {	# attname#somewhat
          $self->_raise_error ($o, type => 'SYNTAX_INVALID_MD', c => $c, t => substr ($t, 0, 10));
          next;
        }
      } elsif ($t =~ s/$xml_re{s}$//s) {
      } else {
        $self->_raise_error ($o, type => 'SYNTAX_INVALID_MD', c => $c, t => substr ($t, 0, 10));
        substr ($t, 0, 1) = '';
      }
    }	# $t
    unless (scalar keys %defined) {
      $self->_raise_error ($o, c => $c, type => 'WARN_XML_ATTLIST_AT_LEAST_ONE_ATTR_DEF',
                           t => $type_qname);
    }
  } else {	## dont_process
    $c->flag (smxp__non_processed_declaration => 1);
    $self->_raise_error ($o, c => $c, type => 'WARN_ATTLIST_DECLARATION_NOT_PROCESSED');
  }
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

## [internal] URI escaping unsafe characters
## $s = $parser->_uri_escape ($s)
sub _uri_escape ($$) {
  shift;
  my $s = shift;	## TODO: support utf8 flag
  $s =~ s/([^0-9A-Za-z_.-])/sprintf '%%%02X', ord $1/ge;
  $s;
}

## [internal] Duplication of HASH reference
## $ref = $parser->_make_clone_of ($ref)
sub _make_clone_of ($$;%) {
  my ($self, $mother, %o) = @_;
  if (ref $mother eq 'HASH') {
    my $child = {};
    $o{m_vs_c}->{$mother} = $child;
    for (keys %$mother) {
      if (ref ($mother->{$_}) eq 'HASH') {
        $child->{$_} = $o{m_vs_c}->{$mother->{$_}} || $self->_make_clone_of ($mother->{$_});
      } elsif (index (ref ($mother->{$_}), 'URI') > -1) {
        $child->{$_} = $mother->{$_}->clone;
        	## BUG: $mother->{$A} === $mother->{$B}, then two clones are created
      ## BUG: if CODE, ARRAY, blessed,...
      } else {
        $child->{$_} = $mother->{$_};
      }
    }
    return $child;
  } else {
    ## BUG: not supported
  }
}

## [internal] Count up line/position
## $self->_clp ($string, $o)
sub _clp ($$$) {
  my (undef, $s => $o) = @_;
  $s =~ s/\G[^\x0A]*\x0A/($o->{line}++, $o->{pos} = 0, '')/ges;
  $o->{pos} += length $s;
}

## [internal] Split QName into prefix and NCName
## ($prefix or undef, $NCName) = $parser->_ns_parse_qname ($QName)
sub _ns_parse_qname ($$) {
  my $qname = $_[1];
  if ($qname =~ /:/) {
    return split /:/, $qname, 2;
  } else {
    return (undef, $qname);
  }
}


sub option ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
}

sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
}

=head1 FLAG NAMES DEFINED BY THIS MODULE

=head2 Flag for Message::Markup::XML instance

=over 4

=item smxp__declaration_may_not_be_read = 1/0 (root node)

Whether after this flag is trued entity/attlist declarations may not
be processed (bacause of declared in external entity or declared after
some external entity reference) or not.

=item smxp__declaration_may_not_be_read = 1/0 (#declaration node)

Whether entity/attlist declaration may not be processed or not.

=item smxp__defined_with_param_ref = 1/0 (#declaration node)

Whether the declaration is defined with one or more parameter entity or not.

=item smxp__entity_manager = instance of entity manager (root node)

=item smxp__entity_replacement_text_md_params = semi-parsed text (Parameter entity #declaration node)

=item smxp__entity_replacement_text_rpdata = semi-parsed text (Parameter entity #declaration node)

=item smxp__is_dtd_default = 1/0 (#attribute node)

Whether the attribute (name and value) is not specified explicily in STag
so completed from DTD's attlist declaration or not.

=item smxp__non_processed_declaration = 1/0 (Entity/attlist #declaration node)

Whether the declaration is not read 'cause of smxp__stop_read_dtd'ed or not.

=item smxp__original_qname = QName as specified in STag

(Only used to check STag-ETag matching.)

=item smxp__ref_expanded = 1/0 (#reference node)

Whether the reference is expanded or not

=item smxp__src_pos = "$o" object

Start position in source entity (is this flag obsolete??)

=item smxp__stop_read_dtd = 1/0 (root node)

Whether reading entity/attlist declaration is stopped 'cause of
some of external entity required to interpret the DTD is not processed
or not.

=item smxp__uri_in_which_declaration_is = uri (Entity #declaration node)

=cut

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/10/10 06:12:11 $
