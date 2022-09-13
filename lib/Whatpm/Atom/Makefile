MANAKAI_ROOT_DIR = ../../..

HTML_FILES = Aggregator.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(HTML_FILES)

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/Atom/$< > Whatpm/Atom/$@

## License: Public Domain.
