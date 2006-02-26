MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_LIB_MANAKAI_DIR = $(MANAKAI_LIB_DIR)manakai/

DIS_SUFFIX = .dis
DAEM_SUFFIX = .dafm
DAFX_SUFFIX = .dafx
PM_SUFFIX = .pm

CD = cd
MAKE = make
RM = rm
RMALL = $(RM) -fv
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
NS_UTIL_MUF   = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Formatter/

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)" \
      --dafx-file-suffix="$(DAFX_SUFFIX)"

DAF_OPTIONS =
DAF_PL = $(MANAKAI_BIN_DIR)daf.pl
DAF = $(PERL_) $(DAF_PL) $(DAF_OPTIONS) $(DIS_OPTIONS_ALL)

UTIL_CORE_DIS_FILES    = ManakaiNode.dis Error/DOMException.dis Error/Core.dis \
  Formatter/Muf2003$(DIS_SUFFIX)
UTIL_TEST_DIS_FILES    = ManakaiNodeTest$(DIS_SUFFIX)
DIS_CORE_DIS_FILES_    = DIS$(DIS_SUFFIX)
DIS_CORE_DIS_FILES_DIS = DIS/Perl.dis DIS/Value.dis DIS/DNLite.dis \
  DIS/DPG$(DIS_SUFFIX)
DIS_CORE_DIS_FILES     = $(DIS_CORE_DIS_FILES_) $(DIS_CORE_DIS_FILES_DIS)
DIS_DOC_DIS_FILES      = DIS/DISDoc.dis
DIS_DUMP_DIS_FILES     = DIS/DISDump.dis
DIS_TEST_DIS_FILES     = DIS/Test$(DIS_SUFFIX)
PC_DIS_FILES           = PerlCode$(DIS_SUFFIX)
UTIL_DIS_COMMON_DIS_FILE = DIS/common$(DIS_SUFFIX)
DIS_FILES = $(UTIL_CORE_DIS_FILES) $(UTIL_TEST_DIS_FILES) \
  $(DIS_CORE_DIS_FILES) \
  $(DIS_DOC_DIS_FILES) $(DIS_DUMP_DIS_FILES) $(DIS_TEST_DIS_FILES) \
  $(PC_DIS_FILES) $(UTIL_DIS_COMMON_DIS_FILE)

NS_UTIL_PM_FILES = \
  ManakaiNode$(PM_SUFFIX) ManakaiNodeTest$(PM_SUFFIX) \
  PerlCode$(PM_SUFFIX) \
  DIS$(PM_SUFFIX)
NS_UTIL_ERR_PM_FILES = \
  Error/DOMException$(PM_SUFFIX)
NS_UTIL_DIS_PM_FILES = \
  DIS/DNLite$(PM_SUFFIX) DIS/Value$(PM_SUFFIX) \
  DIS/DPG$(PM_SUFFIX) \
  DIS/Perl$(PM_SUFFIX) DIS/DISDoc$(PM_SUFFIX) DIS/DISDump$(PM_SUFFIX) \
  DIS/Test$(PM_SUFFIX)

GENERATED_FILES = \
  $(NS_UTIL_PM_FILES) $(NS_UTIL_ERR_PM_FILES) $(NS_UTIL_DIS_PM_FILES)

all: PerlCode$(PM_SUFFIX) .discore$(PM_SUFFIX) $(GENERATED_FILES)

$(NS_UTIL_PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_UTIL)$* $@"
	$(PERL_CHK) $@

$(NS_UTIL_ERR_PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_UTIL_ERR)$(*:Error/%=%) $@"
	$(PERL_CHK) $@

$(NS_UTIL_DIS_PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_UTIL_DIS)$(*:DIS/%=%) $@"
	$(PERL_CHK) $@

.discore$(PM_SUFFIX): $(DIS_CORE_DIS_FILES) $(DAF_PL)
	$(DAF) \
	  --create-perl-module="$(NS_UTIL)DIS        DIS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Value  DIS/Value$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Perl   DIS/Perl$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)DPG    DIS/DPG$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)DNLite DIS/DNLite$(PM_SUFFIX)"
	$(PERL_CHK) DIS$(PM_SUFFIX)
	$(PERL_CHK) DIS/Value$(PM_SUFFIX)
	$(PERL_CHK) DIS/Perl$(PM_SUFFIX)
	$(PERL_CHK) DIS/DNLite$(PM_SUFFIX)
	$(PERL_CHK) DIS/DPG$(PM_SUFFIX)
	$(TOUCH) $@

.discore-all$(PM_SUFFIX): $(DIS_CORE_DIS_FILES) $(DAF_PL)
	$(DAF) \
	  --create-perl-module="$(NS_UTIL)ManakaiNode ManakaiNode$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_ERR)DOMException Error/DOMException$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MARKUP)SuikaWikiConfig21 ../Markup/SuikaWikiConfig21$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL)DIS        DIS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Value  DIS/Value$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)Perl   DIS/Perl$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)DPG    DIS/DPG$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_UTIL_DIS)DNLite DIS/DNLite$(PM_SUFFIX)"
	$(PERL_CHK) ../Markup/SuikaWikiConfig21$(PM_SUFFIX)
	$(PERL_CHK) DIS$(PM_SUFFIX)
	$(PERL_CHK) DIS/Value$(PM_SUFFIX)
	$(PERL_CHK) DIS/Perl$(PM_SUFFIX)
	$(PERL_CHK) DIS/DPG$(PM_SUFFIX)
	$(PERL_CHK) DIS/DNLite$(PM_SUFFIX)
	$(TOUCH) .discore$(PM_SUFFIX)
	$(DAF) \
	  --create-perl-module="$(NS_UTIL)PerlCode   PerlCode$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMFeature ../DOM/DOMFeature$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)GenericLS  ../DOM/GenericLS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMMain    ../DOM/DOMMain$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMCore    ../DOM/DOMCore$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)Tree       ../DOM/Tree$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMXML     ../DOM/DOMXML$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)XDoctype   ../DOM/XDoctype$(PM_SUFFIX)"
	$(PERL_CHK) PerlCode$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMFeature$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/GenericLS$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMMain$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMCore$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/Tree$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/DOMXML$(PM_SUFFIX)
	$(PERL_CHK) ../DOM/XDoctype$(PM_SUFFIX)
	$(TOUCH) $@
	$(TOUCH) ../DOM/.core$(PM_SUFFIX)

clean:
	$(RMALL) $(GENERATED_FILES)
	$(RMALL) .*.tmp *~ .*~ .discore$(PM_SUFFIX) .discore-all$(PM_SUFFIX)
	$(RMALL) Error/*~ Error/.*~
	$(RMALL) Formatter/*~ Formatter/.*~
	$(RMALL) DIS/*~ DIS/.*~

distclean: clean
	$(RMALL) *$(DAEM_SUFFIX) *$(DAFX_SUFFIX)
	$(RMALL) Error/*$(DAEM_SUFFIX) Error/*$(DAFX_SUFFIX)
	$(RMALL) Formatter/*$(DAEM_SUFFIX) Formatter/*$(DAFX_SUFFIX)
	$(RMALL) DIS/*$(DAEM_SUFFIX) DIS/*$(DAFX_SUFFIX)

## $Date: 2006/02/26 14:32:43 $
## License: Public Domain.
