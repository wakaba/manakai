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
                -I=$(MANAKAI_LIB_DIR)Message/Markup/ \
                -I=$(MANAKAI_LIB_DIR)Message/DOM/ 
CDIS2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.
CDIS2PM_PL = ../../../bin/cdis2pm.pl
CDIS2PM = $(PERL) $(CDIS2PM_PL) $(CDIS2PM_OPTIONS)

DIS_FILES = ManakaiNode.dis
GENERATED_FILES = mnode.cdis ManakaiNode.pm \
                  dis.cdis DIS.pm \
                  Error/err.cdis Error/DOMException.pm \
                  pc.cdis PerlCode.pm

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_DIS = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#

all: $(GENERATED_FILES)

mnode.cdis: ManakaiNode.dis $(DISC_PL)
	$(DISC) $< --output-file-name=$@

ManakaiNode.pm: mnode.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< \
	  --module-name=ManakaiNode > $@
	$(PERL_CHK) $@

dis.cdis: DIS.dis mnode.cdis $(DISC_PL)
	$(DISC) $< --input-cdis-file-name=mnode.cdis --output-file-name=$@

DIS.pm: dis.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --module-name=DIS > $@
	$(PERL_CHK) $@

Error/err.cdis: Error/DOMException.dis $(DISC_PL)
	$(DISC) $< --output-file-name=$@

Error/DOMException.pm: Error/err.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< \
	  --module-name=DOMException > $@
	$(PERL_CHK) $@

pc.cdis: PerlCode.dis $(DISC_PL)
	$(DISC) $< --output-file-name=$@

PerlCode.pm: pc.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< \
	  --module-name=PerlCode > $@
	$(PERL_CHK) $@

clean:
	$(RM) $(GENERATED_FILES) .*.tmp
