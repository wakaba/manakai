MANAKAI_ROOT_DIR = ../../..

RM = rm -v
RMALL = $(RM) -f

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: HTTP.html Carp.html Util.html

%.html: %.pm $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/CGI/$< > Message/CGI/$@

Util.html: Util.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/CGI/$< > Message/CGI/$@

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp

distclean: clean

## License: Public Domain.
