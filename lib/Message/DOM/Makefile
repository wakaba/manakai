MANAKAI_ROOT_DIR = ../../..

RM = rm
RMALL = $(RM) -fv

HTML_FILES = DOMImplementation.html Document.html \
  Node.html NodeList.html \
  TextTrack.html TextTrackCue.html TextTrackCueList.html WebVTTCue.html

_P2H = local/p2h
P2H = $(MANAKAI_ROOT_DIR)/$(_P2H)

all: build

build: $(HTML_FILES)

%.html: %.pod $(P2H)
	cd $(MANAKAI_ROOT_DIR)/lib && \
	../$(_P2H) "manakai" Message/DOM/$< > Message/DOM/$@

clean:
	$(RMALL) *.tmp .*.tmp *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMALL) $(HTML_FILES)

## License: Public Domain.
