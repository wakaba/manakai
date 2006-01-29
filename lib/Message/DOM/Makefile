MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

DIS_SUFFIX = .dis
DAC_SUFFIX = .dae
DAEM_SUFFIX = .daem
PM_SUFFIX = .pm

CD = cd
MAKE = make
RM = rm
PERL = perl
PERL_OPTIONS =
PERL_OPTIONS_ALL = $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_ = $(PERL) $(PERL_OPTIONS_ALL)
PERLC = $(PERL) -c -w
PERLC_OPTIONS = 
PERLC_OPTIONS_ALL = $(PERLC_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS_ALL)
TOUCH = touch

NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)"

DAC_OPTIONS =
DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) $(DAC_OPTIONS) $(DIS_OPTIONS_ALL) \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS3 = --enable-assert
DAC2PM_OPTIONS = $(DAC2PM_OPTIONS3)
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS) $(DIS_OPTIONS_ALL)

UTIL_CORE_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Util/core$(DAC_SUFFIX)

DOM_FEATURE_DIS_FILES = DOMFeature$(DIS_SUFFIX) GenericLS$(DIS_SUFFIX)
DOM_CORE_DIS_FILES = DOMMain.dis DOMCore.dis DOMXML.dis \
                     Tree$(DIS_SUFFIX) \
                     XDoctype$(DIS_SUFFIX)
DOM_LS_DIS_FILES   = SimpleLS$(DIS_SUFFIX) DOMLS$(DIS_SUFFIX) \
  ManakaiDOMLS2003$(DIS_SUFFIX)
XP_DIS_FILES       = XMLParser$(DIS_SUFFIX)
DOM_HTML_DIS_FILES = DOMHTML.dis DOMWebForms.dis
DIS_FILES = $(DOM_FEATURE_DIS_FILES) $(DOM_CORE_DIS_FILES) \
  $(DOM_LS_DIS_FILES) $(DOM_HTML_DIS_FILES) $(XP_DIS_FILES)

GENERATED_FILES = \
  feature$(DAC_SUFFIX) DOMFeature$(PM_SUFFIX) GenericLS$(PM_SUFFIX) \
  core$(DAC_SUFFIX)  DOMMain$(PM_SUFFIX) \
                     DOMCore$(PM_SUFFIX) DOMXML$(PM_SUFFIX) \
                     Tree$(PM_SUFFIX) \
                     XDoctype$(PM_SUFFIX) \
  ls$(DAC_SUFFIX)    SimpleLS$(PM_SUFFIX) ManakaiDOMLS2003$(PM_SUFFIX) \
                     DOMLS$(PM_SUFFIX) \
  xp$(DAC_SUFFIX)    XMLParser$(PM_SUFFIX) \
  html$(DAC_SUFFIX)  DOMHTML$(PM_SUFFIX) DOMWebForms$(PM_SUFFIX)
GENERATED_DAC_FILES = feature$(DAC_SUFFIX) \
  core$(DAC_SUFFIX) ls$(DAC_SUFFIX) html$(DAC_SUFFIX) xp$(DAC_SUFFIX)

all: .core$(PM_SUFFIX) .html$(PM_SUFFIX) \
  $(GENERATED_DAC_FILES) \
  XMLParser$(PM_SUFFIX)

feature$(DAC_SUFFIX): $(UTIL_CORE_DAC_FILE) $(DOM_FEATURE_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" GenericLS.dis

core$(DAC_SUFFIX): feature$(DAC_SUFFIX) $(DOM_CORE_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" XDoctype.dis

ls$(DAC_SUFFIX): core$(DAC_SUFFIX) $(DOM_LS_DIS_FILES) $(DAC_PL)
	$(DAC)$@.tmp.1 --input-db-file-name="$<" SimpleLS.dis
	$(DAC)$@.tmp.2 --input-db-file-name="$@.tmp.1" ManakaiDOMLS2003.dis
	$(DAC)$@ --input-db-file-name="$@.tmp.2" DOMLS.dis
	$(RM) $@.tmp.1 $@.tmp.2

xp$(DAC_SUFFIX): ls$(DAC_SUFFIX) $(XP_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" XMLParser.dis

html$(DAC_SUFFIX): core$(DAC_SUFFIX) $(DOM_HTML_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DOMHTML.dis

$(DOM_FEATURE_DIS_FILES:$(DIS_SUFFIX)=$(PM_SUFFIX)): \
  feature$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

$(DOM_CORE_DIS_FILES:.dis=$(PM_SUFFIX)): core$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

.core$(PM_SUFFIX): core$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --create-perl-module="$(NS_MDOM)DOMFeature DOMFeature$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)GenericLS  GenericLS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMMain    DOMMain$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMCore    DOMCore$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)Tree       Tree$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMXML     DOMXML$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)XDoctype   XDoctype$(PM_SUFFIX)"
	$(PERL_CHK) DOMFeature$(PM_SUFFIX)
	$(PERL_CHK) GenericLS$(PM_SUFFIX)
	$(PERL_CHK) DOMMain$(PM_SUFFIX)
	$(PERL_CHK) DOMCore$(PM_SUFFIX)
	$(PERL_CHK) Tree$(PM_SUFFIX)
	$(PERL_CHK) DOMXML$(PM_SUFFIX)
	$(PERL_CHK) XDoctype$(PM_SUFFIX)
	$(TOUCH) $@
  ## NOTE: When you modify this rule, update |../Util/Makefile|, too.

$(DOM_LS_DIS_FILES:$(DIS_SUFFIX)=$(PM_SUFFIX)): ls$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

$(XP_DIS_FILES:$(DIS_SUFFIX)=$(PM_SUFFIX)): xp$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

$(DOM_HTML_DIS_FILES:.dis=$(PM_SUFFIX)): html$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< --module-uri="$(NS_MDOM)$(@:$(PM_SUFFIX)=)" > $@
	$(PERL_CHK) $@

feature-spec$(DAC_SUFFIX): feature$(DAC_SUFFIX) DOMFeature.dis $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DOMFeature.dis \
	  --for="$(NS_MANAKAIDOM)ForSpecLatest"

# $(UTIL_CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)Message/Util/core$(DAC_SUFFIX): dummy
	$(CD) $(MANAKAI_LIB_DIR)Message/Util/ && $(MAKE) core$(DAC_SUFFIX)

dummy:

clean:
	$(RM) $(GENERATED_FILES)
	$(RM) .*.tmp *~ .*~ *.BAK .*.BAK
	$(RM) .core$(PM_SUFFIX)

## $Date: 2006/01/29 13:58:54 $
## License: Public Domain.
