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
CDIS2PM_OPTIONS = --enable-assert
                  ## TODO: Official release should remove this option.
CDIS2PM_PL = ../../../bin/cdis2pm.pl
CDIS2PM = $(PERL) $(CDIS2PM_PL) $(CDIS2PM_OPTIONS)
DIS2POD_PL = ../../../bin/dis2pm.pl
DIS2POD = $(PERL) $(DIS2POD_PL) --output-pod=only

IDL2DIS_PL = idl2dis.pl
IDL2DIS = $(PERL) $(IDL2DIS_PL)

DIS_FILES = DOMMain.dis DOMCore.dis DOMXML.dis \
  DOMLS.dis ManakaiDOMLS2003.dis \
  DOMEvents.dis DOMViews.dis \
  DOMHTML.dis DOMWebForms.dis

GENERATED_FILES_DOMLATEST = core.cdis ev.cdis ls.cdis html.cdis \
  DOMMain.pm DOMCore.pm DOMXML.pm DOMLS.pm ManakaiDOMLS2003.pm \
  DOMEvents.pm DOMViews.pm \
  DOMHTML.pm DOMWebForms.pm
GENERATED_FILES = $(MAIN_CDIS_FILE) $(GENERATED_FILES_DOMLATEST)

NS_MANAKAIDOM = http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom\#

all: dom

dom: dom-latest
dom-latest: $(GENERATED_FILES_DOMLATEST)

core.cdis: DOMCore.dis DOMMain.dis DOMXML.dis $(DISC_PL)
	$(DISC) DOMCore.dis --output-file-name=$@

ev.cdis: core.cdis DOMEvents.dis DOMViews.dis $(DISC_PL)
	$(DISC) DOMEvents.dis --input-cdis-file-name=$< \
	                    --output-file-name=.$@.1.tmp
	$(DISC) DOMViews.dis --input-cdis-file-name=.$@.1.tmp \
	                    --output-file-name=$@
	$(RM) .$@.1.tmp

ls.cdis: ev.cdis DOMLS.dis ManakaiDOMLS2003.dis $(DISC_PL)
	$(DISC) DOMLS.dis --input-cdis-file-name=$< \
	                    --output-file-name=.$@.1.tmp
	$(DISC) ManakaiDOMLS2003.dis --input-cdis-file-name=.$@.1.tmp \
	                    --output-file-name=$@
	$(RM) .$@.1.tmp

html.cdis: ls.cdis DOMHTML.dis DOMWebForms.dis $(DISC_PL)
	$(DISC) DOMHTML.dis --input-cdis-file-name=$< \
	                    --output-file-name=.$@.1.tmp
	$(DISC) DOMWebForms.dis --input-cdis-file-name=.$@.1.tmp \
	                    --output-file-name=$@
	$(RM) .$@.1.tmp

DOMMain.pm: core.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMCommon" \
	  --module-name=DOMMain --nooutput-module-version > $@
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMMain >> $@
	$(PERL_CHK) $@

DOMCore.pm: core.cdis DOMMain.pm $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMCore > $@
	$(PERL_CHK) $@

DOMXML.pm: core.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMXML > $@
	$(PERL_CHK) $@

DOMEvents.pm: ev.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMEvents > $@
	$(PERL_CHK) $@

DOMViews.pm: ev.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMViews > $@
	$(PERL_CHK) $@

DOMLS.pm: ls.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMLS > $@
	$(PERL_CHK) $@

ManakaiDOMLS2003.pm: ls.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=ManakaiDOMLS2003 > $@
	$(PERL_CHK) $@

DOMHTML.pm: html.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMHTML > $@
	$(PERL_CHK) $@

DOMWebForms.pm: html.cdis $(CDIS2PM_PL)
	$(CDIS2PM) $< --for="$(NS_MANAKAIDOM)ManakaiDOMLatest" \
	  --module-name=DOMWebForms > $@
	$(PERL_CHK) $@
	
clean:
	$(RM) $(GENERATED_FILES) .*.tmp

