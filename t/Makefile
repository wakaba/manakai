MANAKAI_ROOT_DIR = ../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_TEST_DIR = $(MANAKAI_ROOT_DIR)t/

CD = cd
MKDIR = mkdir -p
ECHO = echo

RM = rm
RMALL = $(RM) -frv

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
PROVE = prove

DOMTEST_TESTS_DIR = $(MANAKAI_ROOT_DIR)../domts/tests/
DOMTEST_PERL_DIR = $(MANAKAI_TEST_DIR)dom/
DOMTEST_FILE = *.xml

DOMTS2PERL_PL = $(MANAKAI_BIN_DIR)domts2perl.pl
DOMTS2PERL = $(PERL_) -I$(MANAKAI_BIN_DIR) $(DOMTS2PERL_PL)
DOMTEST2PERL_PL = $(MANAKAI_BIN_DIR)domtest2perl.pl

PT_SUFFIX = .t

all: whatpm

whatpm: \
  content-type-files \
  tokenizer-files \
  tree-construction-files \
  xml-result.txt \
  results/SWML-Parser.txt \
  content-checker-files \
  langtag-files

update: clean-remote-files \
  tokenizer-remote-files \
  tree-construction-remote-files \
  update-data

update-data:
	cd data && $(MAKE) all

dom1core-perl: $(DOMTS2PERL_PL)
	$(MKDIR) $(DOMTEST_PERL_DIR)level1/core/
	$(DOMTS2PERL) --test-directory="$(DOMTEST_TESTS_DIR)level1/core/" \
	              --output-directory="$(DOMTEST_PERL_DIR)level1/core/" \
	              --domtest2perl-path="$(DOMTEST2PERL_PL)"

dom1core:
	MANAKAI_DOMTEST_FILE_DIR=$(DOMTEST_TESTS_DIR)level1/core/files/ \
	  $(PERL_TEST_) $(DOMTEST_PERL_DIR)level1/core/$(DOMTEST_FILE).pl

test: 
	$(PROVE) \
	  DOM-Node.t DOM-Document.t DOM-Element.t DOM-DOMStringList.t \
	  URI-URIReference.t \
          MIME-Type.t IMT-InternetMediaType.t \
	  CGI-*.t \
	  Whatpm-*.t \
	  Message-*.t

test-module-all: \
  test-module-dom

test-module-dom: 
	$(PERL_TEST_) DOM-*$(PT_SUFFIX)

content-type-files: content-type-result.txt

content-type-result.txt: always
	-cd .. && $(PERL_) t/ContentType.t &> t/$@

tokenizer-files: tokenizer-result.txt

tokenizer-result.txt: always
	-cd .. && $(PERL_) t/HTML-tokenizer.t &> t/$@

tree-construction-files: tree-construction-result.txt

tree-construction-result.txt: always
	-cd .. && $(PERL_) t/HTML-tree.t &> t/$@

xml-result.txt: always
	-cd .. && $(PERL_) t/XML-Parser.t &> t/$@

results/SWML-Parser.txt: always
	-cd .. && $(PERL_) t/SWML-Parser.t &> t/$@

content-checker-files: \
  results/content-checker-html.txt \
  content-checker-atom-result.txt \
  content-checker-xml-result.txt

results/content-checker-html.txt: always
	-$(PERL_) ContentChecker-HTML.t &> $@

content-checker-atom-result.txt: always
	-$(PERL_) ContentChecker-Atom.t &> $@

content-checker-xml-result.txt: always
	-$(PERL_) ContentChecker-XML.t &> $@

langtag-files: results/LangTag.txt

results/LangTag.txt: always
	-cd .. && $(PERL_) t/LangTag.t &> t/$@

clean: clean-dom1core-perl

clean-dom1core-perl:
	$(RMALL) $(DOMTEST_PERL_DIR)level1/core/*
	$(RMALL) *~ .*~ *.BAK .*.BAK

distclean: clean

always:

## License: Public Domain.
