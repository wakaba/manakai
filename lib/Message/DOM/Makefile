MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

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

NS_MDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#ManakaiDOM.
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)" \
      --dafx-file-suffix="$(DAFX_SUFFIX)"

DAF_OPTIONS =
DAF_PL = $(MANAKAI_BIN_DIR)daf.pl
DAF = $(PERL_) $(DAF_PL) $(DAF_OPTIONS) $(DIS_OPTIONS_ALL)

DOM_FEATURE_DIS_FILES = DOMFeature$(DIS_SUFFIX) GenericLS$(DIS_SUFFIX)
DOM_CORE_DIS_FILES = DOMMain.dis DOMCore.dis DOMXML.dis \
                     Tree$(DIS_SUFFIX) \
                     XDoctype$(DIS_SUFFIX)
DOM_LS_DIS_FILES   = SimpleLS$(DIS_SUFFIX) DOMLS$(DIS_SUFFIX) \
  ManakaiDOMLS2003$(DIS_SUFFIX)
XP_DIS_FILES       = XMLParser$(DIS_SUFFIX)
DOM_HTML_DIS_FILES = DOMHTML.dis DOMWebForms.dis
DIS_FILES = $(DOM_FEATURE_DIS_FILES) $(DOM_CORE_DIS_FILES) \
  $(DOM_LS_DIS_FILES) $(DOM_HTML_DIS_FILES) $(XP_DIS_FILES)
DOT_CORE_DIS_FILES = \
  $(DOM_FEATURE_DIS_FILES) \
  $(DOM_CORE_DIS_FILES)

PM_FILES = \
  DOMFeature$(PM_SUFFIX) GenericLS$(PM_SUFFIX) \
  DOMMain$(PM_SUFFIX) DOMCore$(PM_SUFFIX) Tree$(PM_SUFFIX) \
  TreeCore$(PM_SUFFIX) \
  DOMXML$(PM_SUFFIX) XDoctype$(PM_SUFFIX) \
  DOMLS$(PM_SUFFIX) XMLParser$(PM_SUFFIX) \
  SimpleLS$(PM_SUFFIX) ManakaiDOMLS2003$(PM_SUFFIX) \
  DOMHTML$(PM_SUFFIX) DOMWebForms$(PM_SUFFIX)

GENERATED_FILES = $(PM_FILES)

all: .core$(PM_SUFFIX) $(PM_FILES)

$(PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_MDOM)$* $@"
	$(PERL_CHK) $@

.core$(PM_SUFFIX): $(DOT_CORE_DIS_FILES) $(DAF_PL)
	$(DAF) \
	  --create-perl-module="$(NS_MDOM)DOMFeature DOMFeature$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)GenericLS  GenericLS$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMMain    DOMMain$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMCore    DOMCore$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)Tree       Tree$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)DOMXML     DOMXML$(PM_SUFFIX)" \
	  --create-perl-module="$(NS_MDOM)XDoctype   XDoctype$(PM_SUFFIX)"
	$(PERL_CHK) DOMFeature$(PM_SUFFIX)
	$(PERL_CHK) GenericLS$(PM_SUFFIX)
	$(PERL_CHK) DOMMain$(PM_SUFFIX)
	$(PERL_CHK) DOMCore$(PM_SUFFIX)
	$(PERL_CHK) Tree$(PM_SUFFIX)
	$(PERL_CHK) DOMXML$(PM_SUFFIX)
	$(PERL_CHK) XDoctype$(PM_SUFFIX)
	$(TOUCH) $@
  ## NOTE: When you modify this rule, update |../Util/Makefile|, too.

clean:
	$(RMALL) $(GENERATED_FILES)
	$(RMALL) .*.tmp *~ .*~ *.BAK .*.BAK
	$(RMALL) .core$(PM_SUFFIX)

distclean: clean
	$(RMALL) *$(DAEM_SUFFIX) *$(DAFX_SUFFIX)

## $Date: 2006/03/17 08:06:20 $
## License: Public Domain.
