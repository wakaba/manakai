POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../../.."

RM = rm -v
RMALL = $(RM) -f

all: HTTP.html Carp.html Util.html

%.html: %.pm
	$(POD2HTML) $< > $@

Util.html: Util.pod
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp

distclean: clean

## License: Public Domain.
