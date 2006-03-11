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

NS_CHARSET = http://suika.fam.cx/~wakaba/archive/2005/manakai/Charset/

DIS_OPTIONS = 
DIS_OPTIONS_ALL = $(DIS_OPTIONS) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --dis-file-suffix="$(DIS_SUFFIX)" \
      --daem-file-suffix="$(DAEM_SUFFIX)" \
      --dafx-file-suffix="$(DAFX_SUFFIX)"

DAF_OPTIONS =
DAF_PL = $(MANAKAI_BIN_DIR)daf.pl
DAF = $(PERL_) $(DAF_PL) $(DAF_OPTIONS) $(DIS_OPTIONS_ALL)

DIS_FILES = Encode$(DIS_SUFFIX)

PM_FILES = Encode$(PM_SUFFIX)

GENERATED_FILES = $(PM_FILES)

all: $(PM_FILES)

$(PM_FILES): %$(PM_SUFFIX): %$(DIS_SUFFIX) $(DAF_PL)
	$(DAF) --create-perl-module="$(NS_CHARSET)$* $@"
	$(PERL_CHK) $@

clean:
	$(RMALL) $(GENERATED_FILES)
	$(RMALL) .*.tmp *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMALL) *$(DAEM_SUFFIX) *$(DAFX_SUFFIX)

## $Date: 2006/03/11 12:12:38 $
## License: Public Domain.
