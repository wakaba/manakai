MKDIR = mkdir -p

RM = rm
RMALL = $(RM) -fv

MANAKAI_ROOT_DIR = ../
BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
TEST_DIR = $(MANAKAI_ROOT_DIR)t/

TEST_VERBOSE = 0
INST_ARCHLIB = $(MANAKAI_ROOT_DIR)blib/arch
INST_LIB = $(MANAKAI_ROOT_DIR)blib/lib

PERL = perl -I$(LIB_DIR)
PERLC = $(PERL) -c
PERL_TEST = $(PERL) -MExtUtils::Command::MM \
                    -e "test_harness ($(TEST_VERBOSE), '$(INST_LIB)', \
                                      '$(INST_ARCHLIB)')"

DOMTEST_TESTS_DIR = $(MANAKAI_ROOT_DIR)../domts/tests/
DOMTEST_PERL_DIR = $(TEST_DIR)dom/
DOMTEST_FILE = *.xml

DOMTS2PERL_PL = $(BIN_DIR)domts2perl.pl
DOMTS2PERL = $(PERL) -I$(BIN_DIR) $(DOMTS2PERL_PL)
DOMTEST2PERL_PL = $(BIN_DIR)domtest2perl.pl

dom1core-perl: $(DOMTS2PERL_PL)
	$(MKDIR) $(DOMTEST_PERL_DIR)level1/core/
	$(DOMTS2PERL) --test-directory=$(DOMTEST_TESTS_DIR)level1/core/ \
	              --output-directory=$(DOMTEST_PERL_DIR)level1/core/ \
	              --domtest2perl=$(DOMTEST2PERL_PL)

dom1core:
	MANAKAI_DOMTEST_FILE_DIR=$(DOMTEST_TESTS_DIR)level1/core/files/ \
	  $(PERL_TEST) $(DOMTEST_PERL_DIR)level1/core/$(DOMTEST_FILE).pl

clean: clean-dom1core-perl

clean-dom1core-perl:
	$(RMALL) $(DOMTEST_PERL_DIR)level1/core/*
	$(RMALL) *~ .*~ *.BAK .*.BAK
