MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

DAC_SUFFIX = .dac
PM_SUFFIX = .pm

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

UTIL_CORE_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/core$(DAC_SUFFIX)

DOM_CORE_DIS_FILES = DOMFeature.dis DOMMain.dis DOMCore.dis DOMXML.dis DOMLS.dis
DOM_HTML_DIS_FILES = DOMHTML.dis DOMWebForms.dis
DIS_FILES = $(DOM_CORE_DIS_FILES) $(DOM_HTML_DIS_FILES)

_DIS_FILES = \
  ManakaiDOMLS2003.dis \
  DOMEvents.dis DOMViews.dis

GENERATED_FILES = \
  core$(DAC_SUFFIX)  DOMFeature$(PM_SUFFIX) DOMMain$(PM_SUFFIX) \
                     DOMCore$(PM_SUFFIX) DOMXML$(PM_SUFFIX) DOMLS$(PM_SUFFIX) \
  html$(DAC_SUFFIX)  DOMHTML$(PM_SUFFIX) DOMWebForms$(PM_SUFFIX)

all: $(GENERATED_FILES)

core$(DAC_SUFFIX): $(UTIL_CORE_DAC_FILE) $(DOM_CORE_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DOMLS.dis

html$(DAC_SUFFIX): core$(DAC_SUFFIX) $(DOM_HTML_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DOMHTML.dis

$(DOM_CORE_DIS_FILES:.dis=$(PM_SUFFIX)): core$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

$(DOM_HTML_DIS_FILES:.dis=$(PM_SUFFIX)): html$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" > $@
	$(PERL_CHK) $@

# $(UTIL_CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)Message/Util/core$(DAC_SUFFIX): dummy
	$(CD) $(MANAKAI_LIB_DIR)Message/Util/ && $(MAKE) core$(DAC_SUFFIX)

dummy:

clean:
	$(RM) $(GENERATED_FILES) .*.tmp *~ .*~ *.BAK .*.BAK

