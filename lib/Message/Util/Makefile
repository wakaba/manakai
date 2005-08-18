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

DOMLS_DIS_FILE3 = $(MANAKAI_LIB_DIR)Message/DOM/DOMLS.dis
DOMLS_DIS_FILE = $(DOMLS_DIS_FILE3)

DOMBOOT_DIS_FILE3 = $(DOMLS_DIS_FILE)
                    ## Dummy
                    #$(MANAKAI_LIB_DIR)Message/DOM/DOMBoot.dis
DOMBOOT_DIS_FILE = $(DOMBOOT_DIS_FILE3)

BOOT_DIS_FILES = ManakaiNode.dis DIS.dis PerlCode.dis Error/DOMException.dis
DIS_FILES = $(BOOT_DIS_FILES) DIS/DISDoc.dis DIS/DISDump.dis

BOOT_GENERATED_FILES = base.dac min.dac ManakaiNode.pm DIS.pm PerlCode.pm \
  Error/DOMException.pm
GENERATED_FILES = $(BOOT_GENERATED_FILES) allbase.dac all.dac DIS/DISDoc.pm \
  DIS/DISDump.pm

all: $(GENERATED_FILES)

boot: $(BOOT_GENERATED_FILES)

all.dac: allbase.dac $(DIS_FILES) $(DAC_PL) \
  $(MANAKAI_LIB_DIR)manakai/NaturalLanguage.dis
	$(DAC)$@ --input-db-file-name="$<" DIS/DISDump.dis

allbase.dac: min.dac $(DAC_PL) \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMHTML.dis \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMWebForms.dis
	$(DAC)$@ --input-db-file-name="$<" \
	  $(MANAKAI_LIB_DIR)Message/DOM/DOMHTML.dis

min.dac: base.dac $(BOOT_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DIS.dis

base.dac: $(DAC_PL) \
  $(MANAKAI_LIB_DIR)Message/Markup/SuikaWikiConfig21.dis \
  $(MANAKAI_LIB_DIR)Message/DOM/DOMMetaImpl.dis \
  $(DOMBOOT_DIS_FILE) $(CORE_DAC_FILE) \
  $(DOMLS_DIS_FILE)
	$(DAC)$@.1.tmp --input-db-file-name="$(CORE_DAC_FILE)" \
	  $(DOMBOOT_DIS_FILE) \
	  --for="$(NS_MANAKAIDOM)ManakaiDOMLatest"
	$(DAC)$@.2.tmp --input-db-file-name="$@.1.tmp" $(DOMLS_DIS_FILE) \
	  --for="$(NS_MANAKAIDOM)ManakaiDOMLatest"
	$(DAC)$@ --input-db-file-name="$@.2.tmp" $(DOMLS_DIS_FILE) \
	  --for="$(NS_MANAKAIDOM)ManakaiDOM3"
	$(RM) $@.1.tmp $@.2.tmp

ManakaiNode.pm: min.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)ManakaiNode" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS.pm: min.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)DIS" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

PerlCode.pm: min.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)PerlCode" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

Error/DOMException.pm: min.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_ERR)DOMException" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS/DISDoc.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)DISDoc" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS/DISDump.pm: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)DISDump" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

# $(CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)manakai/all.dac: \
  $(MANAKAI_LIB_DIR)manakai/DISCore.dis \
  $(MANAKAI_LIB_DIR)manakai/DISRDF.dis \
  $(MANAKAI_LIB_DIR)manakai/DISLang.dis \
  $(MANAKAI_LIB_DIR)manakai/DISIDL.dis \
  $(MANAKAI_LIB_DIR)manakai/DISPerl.dis \
  $(MANAKAI_LIB_DIR)manakai/XML.dis
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && \
	  $(MAKE) all.dac

clean:
	$(RM) $(GENERATED_FILES) .*.tmp
