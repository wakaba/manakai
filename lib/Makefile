MANAKAI_ROOT_DIR = ..

RM = rm
RMALL = $(RM) -fv
MAKE = make
CD = cd

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build Message-all Whatpm-all

build: Error.html
	cd Message && $(MAKE) build
	cd Whatpm && $(MAKE) build

Message-all:
	$(CD) Message/ && $(MAKE) all

Whatpm-all:
	$(CD) Whatpm/ && $(MAKE) all

%.html: %.pm $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" $< > $@

dataautoupdate:
	$(CD) Whatpm && $(MAKE) dataautoupdate

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp .*.tmp
	$(CD) Message/ && $(MAKE) clean

distclean:
	$(RMALL) *~ .*~ *.BAK .*.BAK
	$(CD) Message/ && $(MAKE) distclean
	$(RM) Error.html

## License: Public Domain.
