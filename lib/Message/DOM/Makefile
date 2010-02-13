POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."
RM = rm
RMALL = $(RM) -fv

HTML_FILES = DOMImplementation.html

all: $(HTML_FILES)

%.html: %.pod
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *.tmp .*.tmp *~ .*~ *.BAK .*.BAK

distclean: clean
	$(RMALL) $(HTML_FILES)

## License: Public Domain.
