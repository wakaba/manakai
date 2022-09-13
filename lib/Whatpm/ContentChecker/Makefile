MANAKAI_ROOT_DIR = ../../..

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: HTML.html

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/ContentChecker/$< > \
	    Whatpm/ContentChecker/$@

## License: Public Domain.
