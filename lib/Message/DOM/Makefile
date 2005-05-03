MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

CD = cd
MAKE = make
RM = rm
PERL = perl
PERL_OPTIONS3 = -I$(MANAKAI_LIB_DIR)
PERL_OPTIONS = $(PERL_OPTIONS3)
PERL_ = $(PERL) $(PERL_OPTIONS)
PERLC = $(PERL) -c -w
PERLC_OPTIONS3 = $(PERL_OPTIONS)
PERLC_OPTIONS = $(PERLC_OPTIONS3)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS)

NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS3 = --enable-assert
DAC2PM_OPTIONS = $(DAC2PM_OPTIONS3)
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS)

CORE_DAC_FILE = $(MANAKAI_LIB_DIR)manakai/all.dac
UTIL_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/all.dac

DIS_FILES = DOMMetaImpl.dis \
  DOMMain.dis DOMCore.dis DOMXML.dis

_DIS_FILES = DOMMain.dis DOMCore.dis DOMXML.dis \
  DOMLS.dis ManakaiDOMLS2003.dis \
  DOMEvents.dis DOMViews.dis \
  DOMHTML.dis DOMWebForms.dis \
  DOMMetaImpl.dis

GENERATED_FILES_DOMLATEST = core.cdis ev.cdis ls.cdis html.cdis \
  DOMMain.pm DOMCore.pm DOMXML.pm DOMLS.pm ManakaiDOMLS2003.pm \
  DOMEvents.pm DOMViews.pm \
  DOMHTML.pm DOMWebForms.pm \
  meta.cdis DOMMetaImpl.dis

GENERATED_FILES = all.dac DOMMain.pm DOMCore.pm DOMXML.pm
BOOT_GENERATED_FILES = boot.dac DOMMetaImpl.pm

all: $(GENERATED_FILES)

all.dac: $(DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$(CORE_DAC_FILE)" DOMCore.dis

DOMMain.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)DOMMain" > $@
	$(PERL_CHK) $@

DOMCore.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)DOMCore" > $@
	$(PERL_CHK) $@

DOMXML.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)DOMXML" > $@
	$(PERL_CHK) $@

boot: $(BOOT_GENERATED_FILES)

boot.dac: DOMMetaImpl.dis DOMBoot.dis $(DAC_PL) $(UTIL_DAC_FILE)
	$(DAC)$@ --input-db-file-name="$(UTIL_DAC_FILE)" DOMMetaImpl.dis

DOMMetaImpl.pm: boot.dac $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)DOMMetaImpl" > $@
	$(PERL_CHK) $@

# $(CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)manakai/all.dac: \
  $(MANAKAI_LIB_DIR)manakai/DISCore.dis \
  $(MANAKAI_LIB_DIR)manakai/DISRDF.dis \
  $(MANAKAI_LIB_DIR)manakai/DISLang.dis \
  $(MANAKAI_LIB_DIR)manakai/DISIDL.dis \
  $(MANAKAI_LIB_DIR)manakai/DISPerl.dis \
  $(MANAKAI_LIB_DIR)manakai/XML.dis
	$(CD) $(MANAKAI_ROOT_DIR)manakai/ && \
	  $(MAKE) all.dac

# $(UTIL_DAC_FILE)
$(MANAKAI_LIB_DIR)Message/Util/all.dac:
	$(CD) $(MANAKAI_ROOT_DIR)Message/Util/ && \
	  $(MAKE) all.dac

clean:
	$(RM) $(GENERATED_FILES) $(BOOT_GENERATED_FILES) .*.tmp *~ .*~

DOMEvents.pm: ev.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMEvents > $@
	$(PERL_CHK) $@

DOMViews.pm: ev.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMViews > $@
	$(PERL_CHK) $@

DOMLS.pm: ls.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMLS > $@
	$(PERL_CHK) $@

ManakaiDOMLS2003.pm: ls.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=ManakaiDOMLS2003 > $@
	$(PERL_CHK) $@

DOMHTML.pm: html.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMHTML > $@
	$(PERL_CHK) $@

DOMWebForms.pm: html.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMWebForms > $@
	$(PERL_CHK) $@

