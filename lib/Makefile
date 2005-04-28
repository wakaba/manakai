MANAKAI_ROOT_DIR = ../
MANAKAI_LIB_DIR  = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_BIN_DIR  = $(MANAKAI_ROOT_DIR)bin/
TEMP_LIB_DIR = $(MANAKAI_LIB_DIR).phase1.tmp/
TEMP_LIB2_DIR = $(MANAKAI_LIB_DIR).phase2.tmp/

NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MARKUP    = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#
NS_UTIL      = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_UTIL_ERR  = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/

MKDIR = mkdir
RM = rm

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
      --output-file-name=

DAC2PM_OPTIONS =
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL2) \
      -MMessage::Util::Error::DOMException \
      $(DAC2PM_PL) $(DAC2PM_OPTIONS)

DIS_FILES_FOR_DOMMETAIMPL = \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMBoot.dis \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMMetaImpl.dis \
  $(MANAKAI_LIB_DIR)Message/Util/ManakaiNode.dis \
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

GENERATED_FILES = $(TEMP_LIB_DIR) \
  $(TEMP_LIB_DIR)Message/Util/ManakaiNode.pm \
  $(TEMP_LIB_DIR)Message/DOM/DOMMetaImpl.pm \
  $(TEMP_LIB_DIR)Message/Markup/SuikaWikiConfig21.pm \
  $(TEMP_LIB_DIR)Message/Util/Error/DOMException.pm \
  $(TEMP_LIB_DIR)Message/Util/PerlCode.pm \
  $(TEMP_LIB_DIR)Message/Util/DIS.pm \
  \
  $(TEMP_LIB2_DIR) \
  $(TEMP_LIB2_DIR)Message/Util/ManakaiNode.pm \
  $(TEMP_LIB2_DIR)Message/DOM/DOMMetaImpl.pm \
  $(TEMP_LIB2_DIR)Message/Markup/SuikaWikiConfig21.pm \
  $(TEMP_LIB2_DIR)Message/Util/Error/DOMException.pm \
  $(TEMP_LIB2_DIR)Message/Util/PerlCode.pm \
  $(TEMP_LIB2_DIR)Message/Util/DIS.pm

all: $(GENERATED_FILES)

## Phase 1 - Making Perl modules by old disc and cdis2pm tools

$(TEMP_LIB_DIR):
	$(MKDIR) -p $(TEMP_LIB_DIR)Message/Util/Error
	$(MKDIR) -p $(TEMP_LIB_DIR)Message/DOM
	$(MKDIR) -p $(TEMP_LIB_DIR)Message/Markup

$(TEMP_LIB_DIR)dom.cdis: $(DIS_FILES_FOR_DOMMETAIMPL) $(DISC_PL)
	$(DISC) $< --output-file-name="$@"

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
	$(PERL1_CHK) $@

## Phase 2 - Making Perl modules by dac tools generated 
##           by old disc and cdis2pm tools

$(TEMP_LIB2_DIR):
	$(MKDIR) -p $(TEMP_LIB2_DIR)Message/Util/Error
	$(MKDIR) -p $(TEMP_LIB2_DIR)Message/DOM
	$(MKDIR) -p $(TEMP_LIB2_DIR)Message/Markup

$(TEMP_LIB2_DIR)dom.dac: $(DIS_FILES_FOR_DOMMETAIMPL) $(DAC_PL)
	$(DAC)$@ $<

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

## Misc.

clean:
	$(RM) -frv $(TEMP_LIB_DIR)
	$(RM) -fv *~ .*~ *.BAK .*.BAK
