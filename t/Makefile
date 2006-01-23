MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_TEST_DIR = $(MANAKAI_ROOT_DIR)t/

DIS_SUFFIX = .dis
DAC_SUFFIX = .dae
DAEM_SUFFIX = .daem
PM_SUFFIX = .pm

CD = cd
MAKE = make
MKDIR = mkdir -p

RM = rm
RMALL = $(RM) -fv

TEST_VERBOSE = 0
INST_ARCHLIB = $(MANAKAI_ROOT_DIR)blib/arch
INST_LIB = $(MANAKAI_ROOT_DIR)blib/lib

PERL_OPTIONS =
PERL = perl
PERL_ = $(PERL) $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERLC = $(PERL) -c
PERLC_ = $(PERLC) $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_TEST_ = $(PERL) \
             $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR) \
             -MExtUtils::Command::MM \
             -e "test_harness ($(TEST_VERBOSE), '$(INST_LIB)', \
                                      '$(INST_ARCHLIB)')"

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
  --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
  --dis-file-suffix="$(DIS_SUFFIX)" \
  --daem-file-suffix="$(DAEM_SUFFIX)"

DOMTEST_TESTS_DIR = $(MANAKAI_ROOT_DIR)../domts/tests/
DOMTEST_PERL_DIR = $(MANAKAI_TEST_DIR)dom/
DOMTEST_FILE = *.xml

DOMTS2PERL_PL = $(MANAKAI_BIN_DIR)domts2perl.pl
DOMTS2PERL = $(PERL_) -I$(MANAKAI_BIN_DIR) $(DOMTS2PERL_PL)
DOMTEST2PERL_PL = $(MANAKAI_BIN_DIR)domtest2perl.pl

DAC2TEST_OPTIONS = 
DAC2TEST_PL = $(MANAKAI_BIN_DIR)dac2test.pl
DAC2TEST = $(PERL_) $(DAC2TEST_PL) $(DAC2TEST_OPTIONS) $(DIS_OPTIONS_ALL)

DOM_FEATURE_DAC = $(MANAKAI_LIB_DIR)Message/DOM/feature$(DAC_SUFFIX)
DOM_CORE_DAC = $(MANAKAI_LIB_DIR)Message/DOM/core$(DAC_SUFFIX)
DOM_LS_DAC = $(MANAKAI_LIB_DIR)Message/DOM/ls$(DAC_SUFFIX)
DOM_XP_DAC = $(MANAKAI_LIB_DIR)Message/DOM/xp$(DAC_SUFFIX)
DOM_DAC_FILES = $(DOM_FEATURE_DAC) $(DOM_CORE_DAC) $(DOM_LS_DAC) $(DOM_XP_DAC)

UTIL_TEST_DAC = $(MANAKAI_LIB_DIR)Message/Util/coretest$(DAC_SUFFIX)
UTIL_MNTEST_PM = $(MANAKAI_LIB_DIR)Message/Util/ManakaiNodeTest$(PM_SUFFIX)
UTIL_PC_DAC = $(MANAKAI_LIB_DIR)Message/Util/pc$(DAC_SUFFIX)
DIS_CORE_DAC = $(MANAKAI_LIB_DIR)Message/Util/discore$(DAC_SUFFIX)

NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_UTIL = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_DIS  = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#

GENERATED_FILES = \
  util-mntest.t \
  util-perlcode.t dom-feature.t dom-tree.t dom-genericls.t \
  dom-core.t dom-xdoctype.t dom-xmlparser.t \
  dom-mdomls2003.t util-dis-dnlite.t

all: $(GENERATED_FILES)

dom1core-perl: $(DOMTS2PERL_PL)
	$(MKDIR) $(DOMTEST_PERL_DIR)level1/core/
	$(DOMTS2PERL) --test-directory="$(DOMTEST_TESTS_DIR)level1/core/" \
	              --output-directory="$(DOMTEST_PERL_DIR)level1/core/" \
	              --domtest2perl-path="$(DOMTEST2PERL_PL)"

dom1core:
	MANAKAI_DOMTEST_FILE_DIR=$(DOMTEST_TESTS_DIR)level1/core/files/ \
	  $(PERL_TEST_) $(DOMTEST_PERL_DIR)level1/core/$(DOMTEST_FILE).pl

test-module-all: test-module-dom test-module-util

test-module-dom: \
  dom-feature.t \
  dom-core.t dom-tree.t dom-xdoctype.t \
  dom-genericls.t \
  dom-mdomls2003.t dom-xmlparser.t
	$(PERL_TEST_) dom-*.t

dom-feature.t: $(DOM_FEATURE_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)DOMFeature" > $@

dom-genericls.t: $(DOM_CORE_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)GenericLS" > $@

dom-tree.t: $(DOM_CORE_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)Tree" > $@

dom-core.t: $(DOM_CORE_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)DOMCore" > $@

dom-xdoctype.t: $(DOM_CORE_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)XDoctype" > $@

dom-mdomls2003.t: $(DOM_LS_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)ManakaiDOMLS2003" > $@

dom-xmlparser.t: $(DOM_XP_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_MDOM)XMLParser" > $@

test-module-util: \
  util-mntest.t \
  util-perlcode.t \
  util-dis-dnlite.t
	$(PERL_TEST_) util-*.t

util-mntest.t: $(UTIL_TEST_DAC) $(UTIL_MNTEST_PM) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_UTIL)ManakaiNodeTest" > $@

util-perlcode.t: $(UTIL_PC_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_UTIL)PerlCode" > $@

util-dis-dnlite.t: $(DIS_CORE_DAC) $(DAC2TEST_PL)
	$(DAC2TEST) $< --source-module="$(NS_DIS)DNLite" > $@

$(DOM_DAC_FILES): $(MANAKAI_LIB_DIR)Message/DOM/%: always
	$(CD) $(MANAKAI_LIB_DIR)Message/DOM/ && $(MAKE) $*

$(UTIL_TEST_DAC) $(UTIL_MNTEST_PM) $(UTIL_PC_DAC) $(DIS_CORE_DAC): \
  $(MANAKAI_LIB_DIR)Message/Util/%: always
	$(CD) $(MANAKAI_LIB_DIR)Message/Util/ && $(MAKE) $*

clean: clean-dom1core-perl
	$(RMALL) $(GENERATED_FILES)

clean-dom1core-perl:
	$(RMALL) $(DOMTEST_PERL_DIR)level1/core/*
	$(RMALL) *~ .*~ *.BAK .*.BAK

always:
