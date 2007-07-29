MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_TEST_DIR = $(MANAKAI_ROOT_DIR)t/

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

DOMTEST_TESTS_DIR = $(MANAKAI_ROOT_DIR)../domts/tests/
DOMTEST_PERL_DIR = $(MANAKAI_TEST_DIR)dom/
DOMTEST_FILE = *.xml

DOMTS2PERL_PL = $(MANAKAI_BIN_DIR)domts2perl.pl
DOMTS2PERL = $(PERL_) -I$(MANAKAI_BIN_DIR) $(DOMTS2PERL_PL)
DOMTEST2PERL_PL = $(MANAKAI_BIN_DIR)domtest2perl.pl

GENERATED_FILES = 

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
  test-module-dom

test-module-dom: 
	$(PERL_TEST_) DOM-*$(PT_SUFFIX)

clean: clean-dom1core-perl
	$(RMALL) $(GENERATED_FILES)

clean-dom1core-perl:
	$(RMALL) $(DOMTEST_PERL_DIR)level1/core/*
	$(RMALL) *~ .*~ *.BAK .*.BAK

distclean: clean

always:
