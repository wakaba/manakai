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
                -I=$(MANAKAI_LIB_DIR)Message/Util/Error/ \
                -I=$(MANAKAI_LIB_DIR)Message/DOM/ 
CDIS2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.
CDIS2PM_PL = ../../../bin/cdis2pm.pl
CDIS2PM = $(PERL) $(CDIS2PM_PL) $(CDIS2PM_OPTIONS)

DIS_FILES = ManakaiNode.dis
GENERATED_FILES = mnode.cdis ManakaiNode.pm

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#

all: $(GENERATED_FILES)

mnode.cdis: ManakaiNode.dis $(DISC_PL)
	$(DISC) $< --output-file-name=$@

ManakaiNode.pm: mnode.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)Perl" \
	  --module-name=ManakaiNode > $@
	$(PERL_CHK) $@

clean:
	$(RM) $(GENERATED_FILES) .*.tmp
