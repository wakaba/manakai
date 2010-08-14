POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."
WGET = wget
RM = rm
RMALL = $(RM) -fr

all: SelectorsParser.html Colors.html

%.html: %.pod
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ *.bak *.tmp pod*.tmp

## License: Public Domain.
