MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_TEST_DIR = $(MANAKAI_ROOT_DIR)t/

DIS_SUFFIX = .dis
DAEM_SUFFIX = .dafm
DAFX_SUFFIX = .dafx
PM_SUFFIX = .pm
PT_SUFFIX = .t

CD = cd
MAKE = make
MKDIR = mkdir -p
ECHO = echo

RM = rm
RMALL = $(RM) -fv

TEST_VERBOSE = 0
INST_ARCHLIB = $(MANAKAI_ROOT_DIR)blib/arch
INST_LIB = $(MANAKAI_ROOT_DIR)blib/lib

PERL = perl
PERL_OPTIONS =
PERL_OPTIONS_ALL = $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_ = $(PERL) $(PERL_OPTIONS_ALL)
PERLC = $(PERL) -c -w
PERLC_OPTIONS = 
PERLC_OPTIONS_ALL = $(PERLC_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS_ALL)
PERL_TEST_ = $(PERL) $(PERL_OPTIONS_ALL) \
             -MExtUtils::Command::MM \
             -e "test_harness ($(TEST_VERBOSE), '$(INST_LIB)', \
                                      '$(INST_ARCHLIB)')"

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)" \
      --dafx-file-suffix="$(DAFX_SUFFIX)"

DAF_OPTIONS =
DAF_PL = $(MANAKAI_BIN_DIR)daf.pl
DAF = $(PERL_) $(DAF_PL) $(DAF_OPTIONS) $(DIS_OPTIONS_ALL)

DOMTEST_TESTS_DIR = $(MANAKAI_ROOT_DIR)../domts/tests/
DOMTEST_PERL_DIR = $(MANAKAI_TEST_DIR)dom/
DOMTEST_FILE = *.xml

DOMTS2PERL_PL = $(MANAKAI_BIN_DIR)domts2perl.pl
DOMTS2PERL = $(PERL_) -I$(MANAKAI_BIN_DIR) $(DOMTS2PERL_PL)
DOMTEST2PERL_PL = $(MANAKAI_BIN_DIR)domtest2perl.pl

NS_CHARSET    = http://suika.fam.cx/~wakaba/archive/2005/manakai/Charset/
NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_MARKUP     = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#
NS_URI        = http://suika.fam.cx/~wakaba/archive/2005/manakai/URI/
NS_UTIL       = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_UTIL_DIS   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#

TEST_PM_FILES = \
  $(MANAKAI_LIB_DIR)Message/Util/DIS/Test$(PM_SUFFIX)

NS_CHARSET_PT_FILES = \
  charset-Encode$(PT_SUFFIX)
NS_MARKUP_PT_FILES = \
  markup-Atom$(PT_SUFFIX)
NS_MDOM_PT_FILES = \
  dom-DOMFeature$(PT_SUFFIX) dom-GenericLS$(PT_SUFFIX) \
  dom-DOMCore$(PT_SUFFIX) \
  dom-TreeCore$(PT_SUFFIX) dom-Document$(PT_SUFFIX) dom-Element$(PT_SUFFIX) \
  dom-CharacterData$(PT_SUFFIX) dom-XML$(PT_SUFFIX) dom-XDoctype$(PT_SUFFIX) \
  dom-DOMLS$(PT_SUFFIX) dom-XMLParser$(PT_SUFFIX) \
  dom-TreeStore$(PT_SUFFIX)
NS_URI_PT_FILES = \
  uri-Generic$(PT_SUFFIX)
NS_UTIL_PT_FILES = \
  util-PerlCode$(PT_SUFFIX) \
  util-DIS$(PT_SUFFIX)
NS_UTIL_DIS_PT_FILES = \
  util-dis-DNLite$(PT_SUFFIX) \
  util-dis-DPG$(PT_SUFFIX)

UTIL_MNTEST_PM = $(MANAKAI_LIB_DIR)Message/Util/ManakaiNodeTest$(PM_SUFFIX)

PT_FILES = \
  $(NS_MARKUP_PT_FILES) \
  $(NS_MDOM_PT_FILES) \
  $(NS_URI_PT_FILES) \
  $(NS_UTIL_PT_FILES) $(NS_UTIL_DIS_PT_FILES) util-ManakaiNodeTest$(PT_SUFFIX)

GENERATED_FILES = $(PT_FILES)

all: $(GENERATED_FILES)

dom1core-perl: $(DOMTS2PERL_PL)
	$(MKDIR) $(DOMTEST_PERL_DIR)level1/core/
	$(DOMTS2PERL) --test-directory="$(DOMTEST_TESTS_DIR)level1/core/" \
	              --output-directory="$(DOMTEST_PERL_DIR)level1/core/" \
	              --domtest2perl-path="$(DOMTEST2PERL_PL)"

dom1core:
	MANAKAI_DOMTEST_FILE_DIR=$(DOMTEST_TESTS_DIR)level1/core/files/ \
	  $(PERL_TEST_) $(DOMTEST_PERL_DIR)level1/core/$(DOMTEST_FILE).pl

test-module-all: \
  test-module-charset \
  test-module-dom \
  test-module-markup \
  test-module-uri \
  test-module-util

test-module-charset: $(NS_CHARSET_PT_FILES) $(TEST_PM_FILES)
	$(PERL_TEST_) charset-*$(PT_SUFFIX)

$(NS_CHARSET_PT_FILES): charset-%$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/Charset/%$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_CHARSET)$* $@"
	$(PERL_CHK) $@

test-module-dom: $(NS_MDOM_PT_FILES) $(TEST_PM_FILES)
	$(PERL_TEST_) dom-*$(PT_SUFFIX)

$(NS_MDOM_PT_FILES): dom-%$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/DOM/%$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_MDOM)$* $@"
	$(ECHO) "BEGIN {" >> $@
	$(ECHO) "  require 'manakai/mndebug.pl';" >> $@
	$(ECHO) "  manakai::mndebug::define_nodestem_destroy ();" >> $@
	#$(ECHO) "  manakai::mndebug::define_nodestem_destroy_all ();" >> $@
	#$(ECHO) "  manakai::mndebug::define_noderef_destroy_all ();" >> $@
	$(ECHO) "}" >> $@
	$(PERL_CHK) $@

test-module-markup: $(NS_MARKUP_PT_FILES) $(TEST_PM_FILES)
	$(PERL_TEST_) markup-*$(PT_SUFFIX)

$(NS_MARKUP_PT_FILES): markup-%$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/Markup/%$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_MARKUP)$* $@"
	$(PERL_CHK) $@

test-module-uri: $(NS_URI_PT_FILES) $(TEST_PM_FILES)
	$(PERL_TEST_) uri-*$(PT_SUFFIX)

$(NS_URI_PT_FILES): uri-%$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/URI/%$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_URI)$* $@"
	$(PERL_CHK) $@

test-module-util: $(NS_UTIL_PT_FILES) $(NS_UTIL_DIS_PT_FILES) \
  util-ManakaiNodeTest$(PT_SUFFIX) $(TEST_PM_FILES)
	$(PERL_TEST_) util-*$(PT_SUFFIX)

$(NS_UTIL_PT_FILES): util-%$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/Util/%$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_UTIL)$* $@"
	$(PERL_CHK) $@

util-ManakaiNodeTest$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/Util/ManakaiNodeTest$(DIS_SUFFIX) \
  $(UTIL_MNTEST_PM) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_UTIL)ManakaiNodeTest $@"
	$(ECHO) "BEGIN {" >> $@
	$(ECHO) "  require 'manakai/mndebug.pl';" >> $@
	$(ECHO) "  manakai::mndebug::define_nodestem_destroy ();" >> $@
	#$(ECHO) "  manakai::mndebug::define_nodestem_destroy_all ();" >> $@
	#$(ECHO) "  manakai::mndebug::define_noderef_destroy_all ();" >> $@
	$(ECHO) "}" >> $@
	$(PERL_CHK) $@

$(NS_UTIL_DIS_PT_FILES): util-dis-%$(PT_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/Util/DIS/%$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-test="$(NS_UTIL_DIS)$* $@"
	$(PERL_CHK) $@

$(UTIL_MNTEST_PM): $(MANAKAI_LIB_DIR)Message/Util/%: always
	$(CD) $(MANAKAI_LIB_DIR)Message/Util/ && $(MAKE) $*

$(MANAKAI_LIB_DIR)Message/Util/DIS/Test$(PM_SUFFIX): \
  $(MANAKAI_LIB_DIR)Message/Util/DIS/Test$(DIS_SUFFIX)
	$(CD) $(MANAKAI_LIB_DIR)Message/Util/ && $(MAKE) DIS/Test$(PM_SUFFIX)

clean: clean-dom1core-perl
	$(RMALL) $(GENERATED_FILES)

clean-dom1core-perl:
	$(RMALL) $(DOMTEST_PERL_DIR)level1/core/*
	$(RMALL) *~ .*~ *.BAK .*.BAK

distclean: clean

always:
