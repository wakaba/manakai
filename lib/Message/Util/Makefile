MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_LIB_MANAKAI_DIR = $(MANAKAI_LIB_DIR)manakai/

DIS_SUFFIX = .dis
DAC_SUFFIX = .dae
DAEM_SUFFIX = .daem
PM_SUFFIX = .pm

CD = cd
MAKE = make
RM = rm
PERL = perl
PERL_OPTIONS =
PERL_OPTIONS_ALL = $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_ = $(PERL) $(PERL_OPTIONS_ALL)
PERLC = $(PERL) -c -w
PERLC_OPTIONS = 
PERLC_OPTIONS_ALL = $(PERLC_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS_ALL)
TOUCH = touch

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MARKUP     = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#
NS_DIS        = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#
NS_UTIL       = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/
NS_UTIL_ERR   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/
NS_UTIL_DIS   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)"

DAC_OPTIONS =
DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL_) $(DAC_PL) $(DAC_OPTIONS) $(DIS_OPTIONS_ALL) \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS3 = --enable-assert
DAC2PM_OPTIONS = $(DAC2PM_OPTIONS3)
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL_) $(DAC2PM_PL) $(DAC2PM_OPTIONS) $(DIS_OPTIONS_ALL)

CORE_DAC_FILE = $(MANAKAI_LIB_DIR)manakai/all$(DAC_SUFFIX)
DOM_CORE_DAC_FILE = $(MANAKAI_LIB_DIR)Message/DOM/core$(DAC_SUFFIX)
SWCFG_DAC_FILE = $(MANAKAI_LIB_DIR)Message/Markup/all$(DAC_SUFFIX)

UTIL_CORE_DIS_FILES    = ManakaiNode.dis Error/DOMException.dis Error/Core.dis
DIS_CORE_DIS_FILES_    = DIS$(DIS_SUFFIX)
DIS_CORE_DIS_FILES_DIS = DIS/Perl.dis DIS/Value.dis DIS/DNLite.dis
DIS_CORE_DIS_FILES     = $(DIS_CORE_DIS_FILES_) $(DIS_CORE_DIS_FILES_DIS)
DIS_DOC_DIS_FILES      = DIS/DISDoc.dis
DIS_DUMP_DIS_FILES     = DIS/DISDump.dis
PC_DIS_FILES           = PerlCode$(DIS_SUFFIX)
DIS_FILES = $(UTIL_CORE_DIS_FILES) $(DIS_CORE_DIS_FILES) \
  $(DIS_DOC_DIS_FILES) $(DIS_DUMP_DIS_FILES) $(PC_DIS_FILES)

GENERATED_FILES = \
  core$(DAC_SUFFIX)     ManakaiNode$(PM_SUFFIX) Error/DOMException$(PM_SUFFIX) \
  pc$(DAC_SUFFIX)       PerlCode$(PM_SUFFIX) \
  discore$(DAC_SUFFIX)  DIS$(PM_SUFFIX) \
                        DIS/Perl$(PM_SUFFIX) DIS/Value$(PM_SUFFIX) \
                        DIS/DNLite$(PM_SUFFIX) \
  disdoc$(DAC_SUFFIX)   DIS/DISDoc$(PM_SUFFIX) \
  disdump$(DAC_SUFFIX)  DIS/DISDump$(PM_SUFFIX)
GENERATED_DAC_FILES = core$(DAC_SUFFIX) discore$(DAC_SUFFIX) disdoc$(DAC_SUFFIX)

all: PerlCode$(PM_SUFFIX) .discore$(PM_SUFFIX) $(GENERATED_FILES)

core$(DAC_SUFFIX): $(CORE_DAC_FILE) $(UTIL_CORE_DIS_FILES) $(DAC_PL)
	$(DAC)$@.1.tmp --input-db-file-name="$<" ManakaiNode.dis
	$(DAC)$@ --input-db-file-name="$@.1.tmp" Error/DOMException.dis
	$(RM) $@.1.tmp

pc$(DAC_SUFFIX): $(SWCFG_DAC_FILE) $(PC_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" PerlCode$(DIS_SUFFIX)

discore$(DAC_SUFFIX): pc$(DAC_SUFFIX) $(DIS_CORE_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DIS/DNLite.dis

disdoc$(DAC_SUFFIX): discore$(DAC_SUFFIX) $(DIS_DOC_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DIS/DISDoc.dis

disdump$(DAC_SUFFIX): $(DOM_CORE_DAC_FILE) $(DIS_DUMP_DIS_FILES) $(DAC_PL)
	$(DAC)$@ --input-db-file-name="$<" DIS/DISDump.dis

ManakaiNode$(PM_SUFFIX): core$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)ManakaiNode" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

Error/DOMException$(PM_SUFFIX): core$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_ERR)DOMException" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

$(DIS_CORE_DIS_FILES_:.dis=$(PM_SUFFIX)): %$(PM_SUFFIX): discore$(DAC_SUFFIX) \
  $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)$*" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

$(DIS_CORE_DIS_FILES_DIS:.dis=$(PM_SUFFIX)): %$(PM_SUFFIX): \
  discore$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)$(*:DIS/%=%)" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

.discore$(PM_SUFFIX): discore$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --create-perl-module="$(NS_UTIL)DIS       DIS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Value DIS/Value$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Perl  DIS/Perl$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)DNLite DIS/DNLite$(PM_SUFFIX)"
	$(PERL_CHK) DIS$(PM_SUFFIX)
	$(PERL_CHK) DIS/Value$(PM_SUFFIX)
	$(PERL_CHK) DIS/Perl$(PM_SUFFIX)
	$(PERL_CHK) DIS/DNLite$(PM_SUFFIX)
	$(TOUCH) $@

$(PC_DIS_FILES:$(DIS_SUFFIX)=$(PM_SUFFIX)): %$(PM_SUFFIX): \
  pc$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)$*" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

.discore-all$(PM_SUFFIX): discore$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --create-perl-module="$(NS_UTIL)ManakaiNode ManakaiNode$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_ERR)DOMException Error/DOMException$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MARKUP)SuikaWikiConfig21 ../Markup/SuikaWikiConfig21$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL)DIS        DIS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Value  DIS/Value$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Perl   DIS/Perl$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)DNLite DIS/DNLite$(PM_SUFFIX)"
	$(PERL_CHK) ../Markup/SuikaWikiConfig21$(PM_SUFFIX)
	$(PERL_CHK) DIS$(PM_SUFFIX)
	$(PERL_CHK) DIS/Value$(PM_SUFFIX)
	$(PERL_CHK) DIS/Perl$(PM_SUFFIX)
	$(PERL_CHK) DIS/DNLite$(PM_SUFFIX)
	$(DAC2PM) $< \
	  --create-perl-module="$(NS_UTIL)PerlCode   PerlCode$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMFeature ../DOM/DOMFeature$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMMain    ../DOM/DOMMain$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMCore    ../DOM/DOMCore$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMXML     ../DOM/DOMXML$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMLS      ../DOM/DOMLS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)GenericLS  ../DOM/GenericLS$(PM_SUFFIX)"
	$(PERL_CHK) PerlCode$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMFeature$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMMain$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMCore$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMXML$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMLS$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/GenericLS$(PM_SUFFIX)
	$(TOUCH) $@

DIS/DISDoc$(PM_SUFFIX): disdoc$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)DISDoc" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

DIS/DISDump$(PM_SUFFIX): disdump$(DAC_SUFFIX) $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL_DIS)DISDump" \
	  --output-file-path="$@"
	$(PERL_CHK) $@

# $(CORE_DAC_FILE)
$(MANAKAI_LIB_DIR)manakai/all$(DAC_SUFFIX): dummy
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) all$(DAC_SUFFIX)

# $(SWCFG_DAC_FILE)
$(MANAKAI_LIB_DIR)Message/Markup/all$(DAC_SUFFIX): dummy
	$(CD) $(MANAKAI_LIB_DIR)Message/Markup/ && $(MAKE) all$(DAC_SUFFIX)

dummy:

clean:
	$(RM) $(GENERATED_FILES)
	$(RM) .*.tmp .discore$(PM_SUFFIX) .discore-all$(PM_SUFFIX)
