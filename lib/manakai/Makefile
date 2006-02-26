MANAKAI_ROOT_DIR = ../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

DIS_SUFFIX = .dis
DAEM_SUFFIX = .dafm
DAFX_SUFFIX = .dafx

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

NS_DIS = http://suika.fam.cx/~wakaba/archive/2004/dis/

DIS_FILES = DISCore.dis DISLang.dis DISRDF.dis DISIDL.dis \
  DISPerl.dis XML.dis DISMarkup.dis NaturalLanguage.dis Document.dis \
  DISSource.dis Java.dis Test.dis

GENERATED_FILES = 

all: $(GENERATED_FILES)

clean:
	$(RMALL) $(GENERATED_FILES) .*.tmp *~ .*~

distclean: clean
	$(RMALL) *$(DAEM_SUFFIX) *$(DAFX_SUFFIX)

## $Date: 2006/02/26 14:32:48 $
## License: Public Domain.
