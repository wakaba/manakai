LS = ls
MAKE = make
SED = sed
XARGS = xargs

PERL = perl -I../../
PERL_CHK = $(PERL) -c

DIS2PM_PL = dis2pm.pl
DIS2PM = $(PERL) $(DIS2PM_PL)

IDL2DIS_PL = idl2dis.pl
IDL2DIS = $(PERL) $(IDL2DIS_PL)

all: dom-modules

dom-modules:
	$(LS) *.dis | $(SED) s/\.dis/.pm/ | $(XARGS) $(MAKE)

%.pm: %.dis $(DIS2PM_PL)
	$(DIS2PM) $< > $@
	$(PERL_CHK) $@
	

