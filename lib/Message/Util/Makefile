MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_LIB_MANAKAI_DIR = $(MANAKAI_LIB_DIR)manakai/

RM = rm
PERL = perl
PERL_OPTIONS = -I$(MANAKAI_LIB_DIR)
PERL_ = $(PERL) $(PERL_OPTIONS)
PERLC = $(PERL) -c -w
PERLC_OPTIONS = $(PERL_OPTIONS)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS)

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_DIS        = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#
NS_UTIL       = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_UTIL_ERR   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS)

DIS_FILES = ManakaiNode.dis DIS.dis PerlCode.dis Error/DOMException.dis

GENERATED_FILES = all.dac ManakaiNode.pm DIS.pm PerlCode.pm \
  Error/DOMException.pm

all: $(GENERATED_FILES)

all.dac: $(DIS_FILES) $(DAC_PL)
	$(DAC)$@ DIS.dis

ManakaiNode.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)ManakaiNode" > $@
	$(PERL_CHK) $@

DIS.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)DIS" > $@
	$(PERL_CHK) $@

PerlCode.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)PerlCode" > $@
	$(PERL_CHK) $@

Error/DOMException.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_ERR)DOMException" > $@
	$(PERL_CHK) $@

clean:
	$(RM) $(GENERATED_FILES) .*.tmp
