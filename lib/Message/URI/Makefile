MANAKAI_ROOT_DIR = ../../..

RM = rm
RMALL = $(RM) -fv

HTML_FILES = URIReference.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(HTML_FILES)

$(HTML_FILES):: %.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/URI/$< > Message/URI/$@

clean:
	$(RMALL) .*.tmp *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMALL) $(HTML_FILES)

## License: Public Domain.
