MANAKAI_ROOT_DIR = ../../..

HTML_FILES = Serializer.html Tokenizer.html ParserData.html Dumper.html \
  InputStream.html Parser.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(HTML_FILES) Tokenizer.pm Parser.pm

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/HTML/$< > Whatpm/HTML/$@

ParserData.html:: \
%.html: %.pm $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/HTML/$< > Whatpm/HTML/$@

Tokenizer.pm Parser.pm:: %: %.src
	cd .. && $(MAKE) HTML/$@

## License: Public Domain.
