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
CDIS2PM_PL = $(MANAKAI_BIN_DIR)cdis2pm.pl
CDIS2PM = $(PERL) $(CDIS2PM_PL) $(CDIS2PM_OPTIONS)

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#
NS_DIS        = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS\#
NS_UTIL       = http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/

DAC_PL = $(MANAKAI_BIN_DIR)dac.pl
DAC = $(PERL) $(DAC_PL) \
      --search-path-catalog-file-name="$(MANAKAI_LIB_DIR)manakai/dis-catalog" \
      --db-base-directory-path="$(MANAKAI_ROOT_DIR)" \
      --output-file-name=

DAC2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.
DAC2PM_PL = $(MANAKAI_BIN_DIR)dac2pm.pl
DAC2PM = $(PERL) $(DAC2PM_PL) $(DAC2PM_OPTIONS)

DIS_FILES = ManakaiNode.dis DIS.dis PerlCode.dis
GENERATED_FILES = mnode.cdis ManakaiNode.pm \
                  dis.cdis DIS.pm \
                  Error/err.cdis Error/DOMException.pm \
                  pc.cdis PerlCode.pm \
                  all.dac ManakaiNode.pm2 DIS.pm2 PerlCode.pm2

all: $(GENERATED_FILES)

all.dac: $(DIS_FILES) $(DAC_PL)
	$(DAC)$@ DIS.dis
## NOTE: PerlCode and ManakaiNode is referenced by DIS.

ManakaiNode.pm2: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)ManakaiNode" > $@
	$(PERL_CHK) $@
DIS.pm2: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)DIS" > $@
	$(PERL_CHK) $@
PerlCode.pm2: all.dac $(DAC2PM_PL)
	$(DAC2PM) $< \
	  --module-uri="$(NS_UTIL)PerlCode" > $@
	$(PERL_CHK) $@

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
