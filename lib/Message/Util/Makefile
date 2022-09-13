MANAKAI_ROOT_DIR = ../../../
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

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

HTML_FILES = Error.html \
  Formatter/Base.html Formatter/Boolean.html Formatter/Text.html \
  HostPermit.html QName/Filter.html

GENERATED_FILES = $(HTML_FILES)

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(GENERATED_FILES)

Error.html:: %.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/Util/$< > Message/Util/$@
%.html: %.pm $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/Util/$< > Message/Util/$@
Formatter/%.html: %.pm $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/Util/$< > Message/Util/$@

clean:
	$(RMALL) *.tmp .*.tmp *~ .*~
	$(RMALL) Error/*~ Error/.*~
	$(RMALL) Formatter/*~ Formatter/.*~

distclean: clean
	$(RMALL) $(GENERATED_FILES)

## License: Public Domain.
