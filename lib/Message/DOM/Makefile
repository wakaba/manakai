LS = ls
MAKE = make
RM = rm
SED = sed
XARGS = xargs

MANAKAI_ROOT_DIR = ../../../
MANAKAI_BIN_DIR = $(MANAKAI_ROOT_DIR)bin/
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_LIB_MANAKAI_DIR = $(MANAKAI_LIB_DIR)manakai/

PERL = perl -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERL) -c -w

DISC_PL = $(MANAKAI_BIN_DIR)disc.pl
DISC = $(PERL) $(DISC_PL) -I=$(MANAKAI_LIB_MANAKAI_DIR)
CDIS2PM_PL = ../../../bin/cdis2pm.pl
CDIS2PM = $(PERL) $(CDIS2PM_PL)
DIS2POD_PL = ../../../bin/dis2pm.pl
DIS2POD = $(PERL) $(DIS2POD_PL) --output-pod=only

IDL2DIS_PL = idl2dis.pl
IDL2DIS = $(PERL) $(IDL2DIS_PL)

DIS_FILES = DOMMain.dis DOMCore.dis DOMXML.dis \
  ManakaiDOMCore.dis

MAIN_CDIS_FILE = mdom.cdis
GENERATED_FILES_DOMLATEST = DOMMain.pm DOMCore.pm
GENERATED_FILES = $(MAIN_CDIS_FILE) $(GENERATED_FILES_DOMLATEST)

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#

all: $(MAIN_CDIS_FILE) dom

dom: dom-latest
dom-latest: $(MAIN_CDIS_FILE) $(GENERATED_FILES_DOMLATEST) \
	DOMMain.pm-chk DOMCore.pm-chk

$(MAIN_CDIS_FILE): $(DIS_FILES) $(DISC_PL)
	$(DISC) DOMMain.dis --output-file-name=$@

DOMMain.pm: $(MAIN_CDIS_FILE) $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMCommon" \
	  --module-name=DOMMain > $@
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMMain >> $@

DOMMain.pm-chk:
	$(PERL_CHK) DOMMain.pm

DOMCore.pm: $(MAIN_CDIS_FILE) $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMCore > $@

DOMCore.pm-chk:
	$(PERL_CHK) DOMCore.pm
	
clean:
	$(RM) $(GENERATED_FILES)

