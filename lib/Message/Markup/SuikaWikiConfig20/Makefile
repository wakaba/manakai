MANAKAI_ROOT_DIR = ../../../..

HTML_FILES = Node.html Parser.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(HTML_FILES)

$(HTML_FILES):: %.html: %.pm $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/Markup/SuikaWikiConfig20/$< > \
	    Message/Markup/SuikaWikiConfig20/$@

## License: Public Domain.
