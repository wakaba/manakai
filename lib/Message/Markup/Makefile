MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_LIB_MANAKAI_DIR = $(MANAKAI_LIB_DIR)manakai/

RM = rm
PERL = perl -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERL) -c -w

DISC_PL = $(MANAKAI_BIN_DIR)disc.pl
DISC = $(PERL) $(DISC_PL) \
                -I=$(MANAKAI_LIB_MANAKAI_DIR) \
                -I=$(MANAKAI_LIB_DIR)Message/Util/ \
                -I=$(MANAKAI_LIB_DIR)Message/Util/Error/ 
CDIS2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.
CDIS2PM_PL = ../../../bin/cdis2pm.pl
CDIS2PM = $(PERL) $(CDIS2PM_PL) $(CDIS2PM_OPTIONS)

DIS_FILES = SuikaWikiConfig21.dis
GENERATED_FILES = swcfg.cdis SuikaWikiConfig21.pm

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_SWCFG21    = http://suika.fam.cx/~wakaba/archive/2005/swcfg21\#

all: $(GENERATED_FILES)

swcfg.cdis: SuikaWikiConfig21.dis $(DISC_PL)
	$(DISC) $< --output-file-name=$@

SuikaWikiConfig21.pm: swcfg.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_SWCFG21)ForLatest" \
	  --module-name=SuikaWikiConfig21 > $@
	$(PERL_CHK) $@

clean:
	$(RM) $(GENERATED_FILES) .*.tmp
