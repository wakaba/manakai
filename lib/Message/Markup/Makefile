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

NS_ATOM       = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup/Atom/
NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_MARKUP     = http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup\#

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)" \
      --dafx-file-suffix="$(DAFX_SUFFIX)"

DAF_OPTIONS =
DAF_PL = $(MANAKAI_BIN_DIR)daf.pl
DAF = $(PERL_) $(DAF_PL) $(DAF_OPTIONS) $(DIS_OPTIONS_ALL)

DIS_FILES = \
  SuikaWikiConfig21$(DIS_SUFFIX) \
  Atom$(DIS_SUFFIX) \
  SuikaWiki$(DIS_SUFFIX) \
  H2H$(DIS_SUFFIX)
ADDITIONAL_DIS_FILES = common$(DIS_SUFFIX)

PM_FILES = $(DIS_FILES:$(DIS_SUFFIX)=$(PM_SUFFIX))

GENERATED_FILES = $(PM_FILES)

all: $(GENERATED_FILES)

$(PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_MARKUP)$* $@"
	$(PERL_CHK) $@

## temporary
atom: $(DAF_PL)
	$(DAF) \
	  --load-module="$(NS_MARKUP)Atom" \
	  --create-dtd-modules="$(NS_ATOM)Atom . $(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --create-dtd-driver="$(NS_ATOM)Atom10 . $(NS_MANAKAIDOM)ManakaiDOMLatest"

clean:
	$(RMALL) $(GENERATED_FILES) .*.tmp *~ .*~

clean-db:
	$(RMALL) *$(DAEM_SUFFIX) *$(DAFX_SUFFIX)

distclean: clean clean-db

## $Date: 2006/09/10 11:19:24 $
## License: Public Domain.
