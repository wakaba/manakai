POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "."

RM = rm
RMALL = $(RM) -fv
MAKE = make
CD = cd

all: Error.html Message-all Whatpm-all

Message-all:
	$(CD) Message/ && $(MAKE) all

Whatpm-all:
	$(CD) Whatpm/ && $(MAKE) all

%.html: %.pm
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp .*.tmp
	$(CD) Message/ && $(MAKE) clean

distclean:
	$(RMALL) *~ .*~ *.BAK .*.BAK
	$(CD) Message/ && $(MAKE) distclean
	$(RM) Error.html

## License: Public Domain.
