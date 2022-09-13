MANAKAI_ROOT_DIR = ../../..

HTML_FILES = Parser.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: Parser.pm build

build: $(HTML_FILES)

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Whatpm/XML/$< > Whatpm/XML/$@

Parser.pm: Parser.pm.src ../mkhtmlparser.pl
	perl ../mkhtmlparser.pl $< > $@
	perl -I../.. -c $@

clean:
	rm -frv *~ *.BAK .*~ .*.BAK

## License: Public Domain.
