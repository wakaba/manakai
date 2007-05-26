POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot ".."
WGET = wget

all: HTML.pm _LinkTypeList.pm ContentType.html HTML.html NanoDOM.html

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -c $@

%.html: %.pm
	$(POD2HTML) $< > $@

HTML.html: HTML.pod
	$(POD2HTML) $< > $@

_LinkTypeList.pm: mklinktypelist.pl RelExtensions.html
	perl $< > $@
	perl -c -w $@

RelExtensions.html:
	$(WGET) http://wiki.whatwg.org/wiki/RelExtensions -O $@

## License: Public Domain.
## $Date: 2007/05/26 12:33:04 $
