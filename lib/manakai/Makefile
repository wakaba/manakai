MANAKAI_ROOT_DIR = ../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

CD = cd
MAKE = make
RM = rm
PERL = perl
PERL_OPTIONS2 = -I$(MANAKAI_LIB_DIR)
PERL_OPTIONS = $(PERL_OPTIONS2)
PERL_ = $(PERL) $(PERL_OPTIONS)
PERLC = $(PERL) -c -w
PERLC_OPTIONS2 = $(PERL_OPTIONS)
PERLC_OPTIONS = $(PERLC_OPTIONS2)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS)

NS_DIS = http://suika.fam.cx/~wakaba/archive/2004/dis/

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS2 = --enable-assert
DAC2PM_OPTIONS = $(DAC2PM_OPTIONS2)
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS)

CORE_DAC_FILE = $(MANAKAI_LIB_DIR)manakai/all.dac

DIS_FILES = DISCore.dis DISLang.dis DISRDF.dis DISIDL.dis \
  DISPerl.dis XML.dis DISMarkup.dis NaturalLanguage.dis

GENERATED_FILES = all.dac

all: $(GENERATED_FILES)

all.dac: $(DIS_FILES) $(DAC_PL)
	$(DAC).$@.1.tmp DISPerl.dis
	$(DAC).$@.2.tmp --input-db-file-name=".$@.1.tmp" DISMarkup.dis
	$(DAC)$@ --input-db-file-name=".$@.2.tmp" NaturalLanguage.dis
	$(RM) .$@.1.tmp .$@.2.tmp

clean:
	$(RM) $(GENERATED_FILES) .*.tmp *~ .*~
