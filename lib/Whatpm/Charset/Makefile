MANAKAI_ROOT_DIR = ../../..

WGET = wget
RM = rm
RMALL = $(RM) -fr

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: UniversalCharDet.html

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/Charset/$< > Whatpm/Charset/$@

clean:
	$(RMALL) *~ *.bak *.tmp

## License: Public Domain.
## $Date: 2007/11/19 12:18:27 $
