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
PERLC_OPTIONS = $(PERL_OPTIONS3)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS)

NS_MARKUP     = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS3 = --enable-assert
DAC2PM_OPTIONS = $(DAC2PM_OPTIONS3)
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS)

DOM_CORE_DAC_FILE = $(MANAKAI_LIB_DIR)Message/DOM/core.dac

DIS_FILES = SuikaWikiConfig21.dis

GENERATED_FILES = all.dac SuikaWikiConfig21.pm

all: $(GENERATED_FILES)

all.dac: $(DOM_CORE_DAC_FILE) $(DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" SuikaWikiConfig21.dis

SuikaWikiConfig21.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_MARKUP)SuikaWikiConfig21" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

# $(DOM_CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)Message/DOM/core.dac: dummy
	$(CD) $(MANAKAI_LIB_DIR)Message/DOM/ && $(MAKE) core.dac

dummy:

clean:
	$(RM) $(GENERATED_FILES) .*.tmp *~ .*~
