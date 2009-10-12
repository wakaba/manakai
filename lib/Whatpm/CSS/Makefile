POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."
WGET = wget
RM = rm
RMALL = $(RM) -fr

all: SelectorsParser.html

%.html: %.pod
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ *.bak *.tmp

## License: Public Domain.
## $Date: 2007/10/17 09:47:36 $
