MANAKAI_ROOT_DIR = ../../..

WGET = wget
RM = rm
RMALL = $(RM) -fr

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: SelectorsParser.html Colors.html Parser.html Tokenizer.html

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/CSS/$< > Whatpm/CSS/$@

clean:
	$(RMALL) *~ *.bak *.tmp pod*.tmp

## License: Public Domain.
