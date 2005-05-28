MANAKAI_ROOT_DIR = ../
MANAKAI_LIB_DIR  = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_BIN_DIR  = $(MANAKAI_ROOT_DIR)bin/
TEMP_LIB_DIR = $(MANAKAI_LIB_DIR).phase1.tmp/
TEMP_LIB2_DIR = $(MANAKAI_LIB_DIR).phase2.tmp/

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MARKUP    = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#
NS_UTIL      = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_UTIL_ERR  = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/

MKDIR = mkdir
RM = rm
MAKE = make
CD = cd
CP = cp
ECHO = -echo

PERL = perl
PERL1 = $(PERL) -I$(MANAKAI_LIB_DIR)
PERL1_CHK = $(PERL) -I$(TEMP_LIB_DIR) -I$(MANAKAI_LIB_DIR) -c -w
PERL2 = $(PERL) -I$(TEMP_LIB_DIR) -I$(MANAKAI_LIB_DIR)
PERL2_CHK = $(PERL) -I$(TEMP_LIB2_DIR) -I$(TEMP_LIB_DIR) -I$(MANAKAI_LIB_DIR)

DISC_PL = $(MANAKAI_BIN_DIR)disc.pl
DISC = $(PERL1) $(DISC_PL) \
                -I=$(MANAKAI_LIB_DIR)manakai/ \
                -I=$(MANAKAI_LIB_DIR)Message/Util/ \
                -I=$(MANAKAI_LIB_DIR)Message/Util/Error/ \
                -I=$(MANAKAI_LIB_DIR)Message/Markup/ \
                -I=$(MANAKAI_LIB_DIR)Message/DOM/ 
CDIS2PM_OPTIONS = 
CDIS2PM_PL = $(MANAKAI_BIN_DIR)cdis2pm.pl
CDIS2PM = $(PERL1) $(CDIS2PM_PL) $(CDIS2PM_OPTIONS)

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL2) \
      -MMessage::Util::Error::DOMException \
      $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --implementation-registry-package \
        "Message::DOM::DOMMetaImpl::ManakaiDOMImplementationRegistryCompat" \
      --output-file-name=

DAC2PM_OPTIONS =
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL2) \
      -MMessage::Util::Error::DOMException \
      $(DAC2PM_PL) \
      --implementation-registry-package \
        "Message::DOM::DOMMetaImpl::ManakaiDOMImplementationRegistryCompat" \
      $(DAC2PM_OPTIONS)

PHASE3_PERL_OPTIONS = 
PHASE3_DAC2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.

DIS_FILES_FOR_DOMMETAIMPL = \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMBoot.dis \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMMetaImpl.dis \
  $(MANAKAI_LIB_DIR)Message/Util/ManakaiNode.dis \
  $(MANAKAI_LIB_DIR)Message/Util/Error/DOMException.dis \
  $(MANAKAI_LIB_DIR)manakai/DISCore.dis \
  $(MANAKAI_LIB_DIR)manakai/DISRDF.dis \
  $(MANAKAI_LIB_DIR)manakai/DISLang.dis \
  $(MANAKAI_LIB_DIR)manakai/DISIDL.dis \
  $(MANAKAI_LIB_DIR)manakai/DISPerl.dis \
  $(MANAKAI_LIB_DIR)manakai/XML.dis
## NOTE: DOMBoot.dis must be first

DIS_FILES_FOR_DIS = \
  $(MANAKAI_LIB_DIR)Message/Util/DIS.dis \
  $(MANAKAI_LIB_DIR)Message/Markup/SuikaWikiConfig21.dis \
  $(MANAKAI_LIB_DIR)Message/Util/Error/DOMException.dis \
  $(MANAKAI_LIB_DIR)Message/Util/PerlCode.dis
## NOTE: DIS.dis must be first

PHASE1_DOMLS_DIS_FILE = $(TEMP_LIB_DIR)Message/DOM/DOMLS.dis
PHASE1_DOMLS_PM_FILE = $(TEMP_LIB_DIR)Message/DOM/DOMLS.pm
PHASE2_DOMLS_PM_FILE = $(TEMP_LIB2_DIR)Message/DOM/DOMLS.pm

PHASE1_PM_FILES = \
  $(TEMP_LIB_DIR)Message/Util/ManakaiNode.pm \
  $(TEMP_LIB_DIR)Message/DOM/DOMMetaImpl.pm \
  $(TEMP_LIB_DIR)Message/Markup/SuikaWikiConfig21.pm \
  $(TEMP_LIB_DIR)Message/Util/Error/DOMException.pm \
  $(TEMP_LIB_DIR)Message/Util/PerlCode.pm \
  $(TEMP_LIB_DIR)Message/Util/DIS.pm

PHASE2_PM_FILES = \
  $(TEMP_LIB2_DIR)Message/Util/ManakaiNode.pm \
  $(TEMP_LIB2_DIR)Message/DOM/DOMMetaImpl.pm \
  $(TEMP_LIB2_DIR)Message/Markup/SuikaWikiConfig21.pm \
  $(TEMP_LIB2_DIR)Message/Util/Error/DOMException.pm \
  $(TEMP_LIB2_DIR)Message/Util/PerlCode.pm \
  $(TEMP_LIB2_DIR)Message/Util/DIS.pm

GENERATED_FILES = $(TEMP_LIB_DIR) $(PHASE1_DOMLS_DIS_FILE) \
  $(PHASE1_DOMLS_PM_FILE) $(PHASE1_PM_FILES) \
  \
  $(TEMP_LIB2_DIR) $(PHASE2_DOMLS_PM_FILE) $(PHASE2_PM_FILES)

all: $(GENERATED_FILES) phase3

## Phase 1 - Making Perl modules by old disc and cdis2pm tools

$(TEMP_LIB_DIR):
	$(MKDIR) -p $(TEMP_LIB_DIR)Message/Util/Error
	$(MKDIR) -p $(TEMP_LIB_DIR)Message/DOM
	$(MKDIR) -p $(TEMP_LIB_DIR)Message/Markup

$(TEMP_LIB_DIR)dom.cdis: $(DIS_FILES_FOR_DOMMETAIMPL) $(DISC_PL) \
  $(PHASE1_DOMLS_DIS_FILE)
	$(DISC) $< --output-file-name="$@.tmp"
	$(DISC) $(PHASE1_DOMLS_DIS_FILE) --input-cdis-file-name="$@.tmp" \
	  --output-file-name="$@"
	$(RM) $@.tmp

$(TEMP_LIB_DIR)dis.cdis: $(DIS_FILES_FOR_DIS) \
  $(TEMP_LIB_DIR)dom.cdis $(DISC_PL)
	$(DISC) $< --input-cdis-file-name="$(TEMP_LIB_DIR)dom.cdis" \
	  --output-file-name="$@"

$(TEMP_LIB_DIR)Message/DOM/DOMMetaImpl.pm: $(TEMP_LIB_DIR)dom.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=DOMMetaImpl > $@
	$(PERL1_CHK) $@

$(TEMP_LIB_DIR)Message/Util/ManakaiNode.pm: $(TEMP_LIB_DIR)dom.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=ManakaiNode > $@
	$(PERL1_CHK) $@

$(TEMP_LIB_DIR)Message/Util/DIS.pm: $(TEMP_LIB_DIR)dis.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=DIS > $@
	$(PERL1_CHK) $@

$(TEMP_LIB_DIR)Message/Util/PerlCode.pm: $(TEMP_LIB_DIR)dis.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=PerlCode > $@
	$(PERL1_CHK) $@

$(TEMP_LIB_DIR)Message/Util/Error/DOMException.pm: $(TEMP_LIB_DIR)dis.cdis \
  $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=DOMException > $@
	$(PERL1_CHK) $@

$(TEMP_LIB_DIR)Message/Markup/SuikaWikiConfig21.pm: $(TEMP_LIB_DIR)dis.cdis \
  $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=SuikaWikiConfig21 > $@
	$(ECHO) "require Message::DOM::DOMLS;" >> $@
	$(PERL1_CHK) $@

## Phase 2 - Making Perl modules by dac tools generated 
##           by old disc and cdis2pm tools

$(TEMP_LIB2_DIR):
	$(MKDIR) -p $(TEMP_LIB2_DIR)Message/Util/Error
	$(MKDIR) -p $(TEMP_LIB2_DIR)Message/DOM
	$(MKDIR) -p $(TEMP_LIB2_DIR)Message/Markup

$(PHASE2_DOMLS_PM_FILE): $(PHASE1_DOMLS_PM_FILE)
	$(CP) $< $@

$(TEMP_LIB2_DIR)dom.dac: $(DIS_FILES_FOR_DOMMETAIMPL) \
  $(DAC_PL) $(PHASE1_PM_FILES) $(PHASE1_DOMLS_DIS_FILE)
	$(DAC)$@.1.tmp $<
	$(DAC)$@.2.tmp --input-db-file-name="$@.1.tmp" $(PHASE1_DOMLS_DIS_FILE) \
	  --for="$(NS_MANAKAIDOM)ManakaiDOMLatest"
	$(DAC)$@ --input-db-file-name="$@.2.tmp" $(PHASE1_DOMLS_DIS_FILE) \
	  --for="$(NS_MANAKAIDOM)ManakaiDOM3"

$(TEMP_LIB2_DIR)dis.dac: $(DIS_FILES_FOR_DIS) $(TEMP_LIB2_DIR)dom.dac $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$(TEMP_LIB2_DIR)dom.dac" $<

$(TEMP_LIB2_DIR)Message/DOM/DOMMetaImpl.pm: \
  $(TEMP_LIB2_DIR)dom.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)DOMMetaImpl" > $@
	$(PERL2_CHK) $@

$(TEMP_LIB2_DIR)Message/Markup/SuikaWikiConfig21.pm: \
  $(TEMP_LIB2_DIR)dis.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MARKUP)SuikaWikiConfig21" > $@
	$(PERL2_CHK) $@

$(TEMP_LIB2_DIR)Message/Util/ManakaiNode.pm: \
  $(TEMP_LIB2_DIR)dom.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_UTIL)ManakaiNode" > $@
	$(PERL2_CHK) $@

$(TEMP_LIB2_DIR)Message/Util/DIS.pm: \
  $(TEMP_LIB2_DIR)dis.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_UTIL)DIS" > $@
	$(PERL2_CHK) $@

$(TEMP_LIB2_DIR)Message/Util/PerlCode.pm: \
  $(TEMP_LIB2_DIR)dis.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_UTIL)PerlCode" > $@
	$(PERL2_CHK) $@

$(TEMP_LIB2_DIR)Message/Util/Error/DOMException.pm: \
  $(TEMP_LIB2_DIR)dis.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_UTIL_ERR)DOMException" > $@
	$(PERL2_CHK) $@

## Phase 3 - Making Perl modules by dac tools generated by dac tools

phase3: $(PHASE2_PM_FILES) $(MANAKAI_LIB_DIR)Message/DOM/DOMLS.pm
	$(CD) $(MANAKAI_LIB_DIR)Message/Util && \
	  $(MAKE) boot \
	    PERL_OPTIONS2="-I../../lib/$(TEMP_LIB2_DIR) \
	                   -I../../lib/$(MANAKAI_LIB_DIR) \
	                  $(PHASE3_PERL_OPTIONS)" \
	    PERLC_OPTIONS2="-I../../lib/$(MANAKAI_LIB_DIR) \
	                    $(PHASE3_PERL_OPTIONS)" \
	    DAC2PM_OPTIONS2="$(PHASE3_DAC2PM_OPTIONS)" \
	    DOMLS_DIS_FILE2="../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMLS.dis" \
	    DOMBOOT_DIS_FILE2="../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMBoot.dis" \
	    PERL_OPTIONS3="-I../../../lib/$(TEMP_LIB2_DIR) \
	                   -I../../../lib/$(MANAKAI_LIB_DIR) \
	                  $(PHASE3_PERL_OPTIONS)" \
	    PERLC_OPTIONS3="-I../../../lib/$(MANAKAI_LIB_DIR) \
	                    $(PHASE3_PERL_OPTIONS)" \
	    DAC2PM_OPTIONS3="$(PHASE3_DAC2PM_OPTIONS)" \
	    DOMLS_DIS_FILE3="../../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMLS.dis" \
	    DOMBOOT_DIS_FILE3="../../../lib/Message/DOM/DOMBoot.dis"
	$(CD) $(MANAKAI_LIB_DIR)Message/Markup && \
	  $(MAKE) all \
	    PERL_OPTIONS2="-I../../lib/$(TEMP_LIB2_DIR) \
	                   -I../../lib/$(MANAKAI_LIB_DIR) \
	                  $(PHASE3_PERL_OPTIONS)" \
	    PERLC_OPTIONS2="-I../../lib/$(MANAKAI_LIB_DIR) \
	                    $(PHASE3_PERL_OPTIONS)" \
	    DAC2PM_OPTIONS2="$(PHASE3_DAC2PM_OPTIONS)" \
	    DOMLS_DIS_FILE2="../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMLS.dis" \
	    PERL_OPTIONS3="-I../../../lib/$(TEMP_LIB2_DIR) \
	                   -I../../../lib/$(MANAKAI_LIB_DIR) \
	                  $(PHASE3_PERL_OPTIONS)" \
	    PERLC_OPTIONS3="-I../../../lib/$(MANAKAI_LIB_DIR) \
	                    $(PHASE3_PERL_OPTIONS)" \
	    DAC2PM_OPTIONS3="$(PHASE3_DAC2PM_OPTIONS)"
	    DOMLS_DIS_FILE3="../../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMLS.dis"
	$(CD) $(MANAKAI_LIB_DIR)Message/DOM && \
	  $(MAKE) boot \
	    PERL_OPTIONS2="-I../../lib/$(TEMP_LIB2_DIR) \
	                   -I../../lib/$(MANAKAI_LIB_DIR) \
	                  $(PHASE3_PERL_OPTIONS)" \
	    PERLC_OPTIONS2="-I../../lib/$(MANAKAI_LIB_DIR) \
	                    $(PHASE3_PERL_OPTIONS)" \
	    DAC2PM_OPTIONS2="$(PHASE3_DAC2PM_OPTIONS)" \
	    DOMLS_DIS_FILE2="../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMLS.dis" \
	    PERL_OPTIONS3="-I../../../lib/$(TEMP_LIB2_DIR) \
	                   -I../../../lib/$(MANAKAI_LIB_DIR) \
	                  $(PHASE3_PERL_OPTIONS)" \
	    PERLC_OPTIONS3="-I../../../lib/$(MANAKAI_LIB_DIR) \
	                    $(PHASE3_PERL_OPTIONS)" \
	    DAC2PM_OPTIONS3="$(PHASE3_DAC2PM_OPTIONS)"
	    DOMLS_DIS_FILE3="../../../lib/$(TEMP_LIB_DIR)Message/DOM/DOMLS.dis"

## TODO: Make other modules

$(MANAKAI_LIB_DIR)Message/DOM/DOMLS.pm: $(PHASE1_DOMLS_PM_FILE)
	$(CP) $< $@

## Misc.

clean:
	$(RM) -frv $(TEMP_LIB_DIR)
	$(RM) -fv *~ .*~ *.BAK .*.BAK
	$(CD) $(MANAKAI_LIB_DIR)Message/Util && $(MAKE) clean

## Files

$(PHASE1_DOMLS_DIS_FILE): 
	$(ECHO) "Module:" > $@
	$(ECHO) " @QName:" >> $@
	$(ECHO) "   MDOM:DOMLS" >> $@
	$(ECHO) " @Namespace:" >> $@
	$(ECHO) "   http://suika.fam.cx/~wakaba/archive/2004/dom/ls#" >> $@

	$(ECHO) " @DefaultFor:" >> $@
	$(ECHO) "  ManakaiDOM:ManakaiDOMLatest" >> $@

	$(ECHO) "Namespace:" >> $@
	$(ECHO) " @dis:" >> $@
	$(ECHO) "  http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--" \
	  >> $@
	$(ECHO) " @DISLang:" >> $@
	$(ECHO) "  http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#" >> $@
	$(ECHO) " @DOMMain:" >> $@
	$(ECHO) "  http://suika.fam.cx/~wakaba/archive/2004/dom/main#" >> $@
	$(ECHO) " @lang:" >> $@
	$(ECHO) "  http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#" >> $@
	$(ECHO) " @ManakaiDOM:" >> $@
	$(ECHO) "  http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#" \
	  >> $@
	$(ECHO) " @MDOM:" >> $@
	$(ECHO) "  $(NS_MDOM)" >> $@
	$(ECHO) " @rdf:" >> $@
	$(ECHO) "  http://www.w3.org/1999/02/22-rdf-syntax-ns#" >> $@

	$(ECHO) "ResourceDef:" >> $@
	$(ECHO) " @QName: LSInput" >> $@
	$(ECHO) " @rdf:type:" >> $@
	$(ECHO) "  ManakaiDOM:IF" >> $@

	$(ECHO) " @ResourceDef:" >> $@
	$(ECHO) "  @@rdf:type:" >> $@
	$(ECHO) "    DISLang:InputProcessor" >> $@
	$(ECHO) "  @@Def:" >> $@
	$(ECHO) "   @@@ContentType:" >> $@
	$(ECHO) "    lang:Perl" >> $@
	$(ECHO) "   @@@@:" >> $@ 
	$(ECHO) '    $$INPUT = bless $$INPUT,<ClassName::ManakaiDOMLSInput' >> $@
	$(ECHO) '                           ::ManakaiDOM:ManakaiDOMLatest>' >> $@
	$(ECHO) '     if ref $$INPUT eq "HASH";' >> $@
	$(ECHO) " @ManakaiDOM:inputNormalizer:" >> $@
	$(ECHO) "  @@ContentType:" >> $@
	$(ECHO) "   lang:Perl" >> $@
	$(ECHO) "  @@@:" >> $@
	$(ECHO) '   $$INPUT = bless $$INPUT, ' >> $@
	$(ECHO) "            <ClassName::DOMLS:ManakaiDOMLSInput" >> $@
	$(ECHO) "                      ::ManakaiDOM:ManakaiDOMLatest>" >> $@
	$(ECHO) '    if ref $$INPUT eq "HASH";' >> $@

	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: characterStream" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: byteStream" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: stringData" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: systemId" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: publicId" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: baseURI" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: encoding" >> $@
	$(ECHO) " @Attr:" >> $@
	$(ECHO) "  @@Name: certifiedText" >> $@

	$(ECHO) "ResourceDef:" >> $@
	$(ECHO) " @QName: ManakaiDOMLSInput" >> $@
	$(ECHO) " @rdf:type:" >> $@
	$(ECHO) "  ManakaiDOM:Class" >> $@

	$(ECHO) "ElementTypeBinding:" >> $@
	$(ECHO) " @Name: Attr" >> $@
	$(ECHO) " @ElementType:" >> $@
	$(ECHO) "   dis:ResourceDef" >> $@
	$(ECHO) " @ShadowContent:" >> $@
	$(ECHO) "   @@rdf:type:" >> $@
	$(ECHO) "     DISLang:Attribute" >> $@
	$(ECHO) "   @@ResourceDef:" >> $@
	$(ECHO) "     @@@rdf:type:" >> $@
	$(ECHO) "       DISLang:AttributeGet" >> $@
	$(ECHO) "   @@ResourceDef:" >> $@
	$(ECHO) "     @@@rdf:type:" >> $@
	$(ECHO) "       DISLang:AttributeSet" >> $@
	$(ECHO) "   @@Type:" >> $@
	$(ECHO) "     DOMMain:any" >> $@

$(PHASE1_DOMLS_PM_FILE): 
	$(ECHO) "package Message::DOM::DOMLS::ManakaiDOMLSInput;" > $@
	$(ECHO) "sub character_stream {shift->{character_stream}}" >> $@
	$(ECHO) "sub byte_stream {shift->{byte_stream}}" >> $@
	$(ECHO) 'sub string_data {ref $$_[0]->{string_data} eq "SCALAR" ?' >> $@
	$(ECHO) '  $${$$_[0]->{string_data}} : $$_[0]->{string_data}}' >> $@
	$(ECHO) "sub public_id {shift->{public_id}}" >> $@
	$(ECHO) "sub system_id {shift->{system_id}}" >> $@
	$(ECHO) "sub base_uri {shift->{base_uri}}" >> $@
	$(ECHO) "sub certified_text {shift->{certified_text}}" >> $@
	$(ECHO) "sub encoding {shift->{encoding}}" >> $@
	$(ECHO) "1;" >> $@

