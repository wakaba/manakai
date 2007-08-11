POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../../.."

RM = rm -v
RMALL = $(RM) -f

all: HTTP.html

%.html: %.pm
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp

distclean: clean

## License: Public Domain.
## $Date: 2007/08/11 13:37:09 $
