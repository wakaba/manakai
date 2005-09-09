MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_LIB_MANAKAI_DIR = $(MANAKAI_LIB_DIR)manakai/

CD = cd
MAKE = make
RM = rm
PERL = perl
PERL_OPTIONS3 = -I$(MANAKAI_LIB_DIR)
PERL_OPTIONS = $(PERL_OPTIONS3)
PERL_ = $(PERL) $(PERL_OPTIONS)
PERLC = $(PERL) -c -w
PERLC_OPTIONS3 = $(PERL_OPTIONS)
PERLC_OPTIONS = $(PERLC_OPTIONS3)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS)

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_DIS        = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#
NS_UTIL       = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_UTIL_ERR   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/
NS_UTIL_DIS   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS3 = --enable-assert
DAC2PM_OPTIONS = $(DAC2PM_OPTIONS3)
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS)

CORE_DAC_FILE = $(MANAKAI_LIB_DIR)manakai/all.dac
SWCFG_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Markup/all.dac

UTIL_CORE_DIS_FILES = ManakaiNode.dis Error/DOMException.dis Error/Core.dis
DIS_CORE_DIS_FILES = DIS.dis PerlCode.dis
DIS_DOC_DIS_FILES = DIS/DISDoc.dis DIS/DISDump.dis
DIS_FILES = $(UTIL_CORE_DIS_FILES) $(DIS_CORE_DIS_FILES) \
  $(DIS_DOC_DIS_FILES)

GENERATED_FILES = \
  core.dac     ManakaiNode.pm Error/DOMException.pm \
  discore.dac  DIS.pm PerlCode.pm \
  disdoc.dac   DIS/DISDoc.pm DIS/DISDump.pm

all: $(GENERATED_FILES)

core.dac: $(CORE_DAC_FILE) $(UTIL_CORE_DIS_FILES) $(DAC_PL)
	$(DAC)$@.1.tmp --input-db-file-name="$<" ManakaiNode.dis
	$(DAC)$@ --input-db-file-name="$@.1.tmp" Error/DOMException.dis
	$(RM) $@.1.tmp

discore.dac: $(SWCFG_DAC_FILE) $(DIS_CORE_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DIS.dis

disdoc.dac: discore.dac $(DIS_DOC_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DIS/DISDump.dis

ManakaiNode.pm: core.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)ManakaiNode" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS.pm: discore.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)DIS" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

PerlCode.pm: discore.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)PerlCode" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

Error/DOMException.pm: core.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_ERR)DOMException" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS/DISDoc.pm: disdoc.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)DISDoc" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS/DISDump.pm: disdoc.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)DISDump" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

# $(CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)manakai/all.dac: dummy
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) all.dac

# $(SWCFG_DAC_FILE)
$(MANAKAI_LIB_DIR)Message/Markup/all.dac: dummy
	$(CD) $(MANAKAI_LIB_DIR)Message/Markup/ && $(MAKE) all.dac

dummy:

clean:
	$(RM) $(GENERATED_FILES) .*.tmp
