MANAKAI_ROOT_DIR = ../../..

RM = rm
RMALL = $(RM) -fv

HTML_FILES = Type.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(HTML_FILES)

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/MIME/$< > Message/MIME/$@

clean:
	$(RMALL) *.tmp .*.tmp *~ .*~ *.BAK .*.BAK

distclean: clean

## License: Public Domain.
