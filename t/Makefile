MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_TEST_DIR = $(MANAKAI_ROOT_DIR)t/

DIS_SUFFIX = .dis
DAC_SUFFIX = .dae
DAEM_SUFFIX = .daem

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

dom1core-perl: $(DOMTS2PERL_PL)
	$(MKDIR) $(DOMTEST_PERL_DIR)level1/core/
	$(DOMTS2PERL) --test-directory="$(DOMTEST_TESTS_DIR)level1/core/" \
	              --output-directory="$(DOMTEST_PERL_DIR)level1/core/" \
	              --domtest2perl-path="$(DOMTEST2PERL_PL)"

dom1core:
	MANAKAI_DOMTEST_FILE_DIR=$(DOMTEST_TESTS_DIR)level1/core/files/ \
	  $(PERL_TEST_) $(DOMTEST_PERL_DIR)level1/core/$(DOMTEST_FILE).pl

clean: clean-dom1core-perl

clean-dom1core-perl:
	$(RMALL) $(DOMTEST_PERL_DIR)level1/core/*
	$(RMALL) *~ .*~ *.BAK .*.BAK
