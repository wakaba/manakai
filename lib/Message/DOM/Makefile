LS = ls
MAKE = make
RM = rm
SED = sed
XARGS = xargs

PERL = perl -I../../
PERL_CHK = $(PERL) -c -w

DIS2PM_PL = ../../../bin/dis2pm.pl
DIS2PM = $(PERL) $(DIS2PM_PL)
DIS2POD_PL = ../../../bin/dis2pm.pl
DIS2POD = $(PERL) $(DIS2POD_PL) --output-pod=only

IDL2DIS_PL = idl2dis.pl
IDL2DIS = $(PERL) $(IDL2DIS_PL)

all: dom-modules

dom-modules: ManakaiDOMMain.pm DOMMain.pm DOMCore.pm ManakaiDOMCore.pm
	$(LS) *.dis | $(SED) s/\.dis/.pm/ | $(XARGS) $(MAKE)

%.pm: %.dis $(DIS2PM_PL)
	$(DIS2PM) --output-pod=file --output-pod-file=$(@:.pm=.pod) $< > $@
	$(PERL_CHK) $@

%.pod: %.dis $(DIS2POD_PL)
	$(DIS2POD) $< > $@
	
clean:
	$(LS) *.dis | $(SED) s/\.dis/.pm/ | $(XARGS) $(RM)

