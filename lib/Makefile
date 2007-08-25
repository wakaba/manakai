POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "."

RM = rm
RMALL = $(RM) -fv
MAKE = make
CD = cd

all: Error.html
	$(CD) Message/ && $(MAKE) all

%.html: %.pm
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp .*.tmp
	$(CD) Message/ && $(MAKE) clean

distclean:
	$(RMALL) *~ .*~ *.BAK .*.BAK
	$(CD) Message/ && $(MAKE) distclean
	$(RM) Error.html

## $Date: 2007/08/25 06:54:30 $
## License: Public Domain.
