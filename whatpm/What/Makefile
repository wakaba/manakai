POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot ".."

all: HTML.pm ContentType.html HTML.html

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -c $@

%.html: %.pm
	$(POD2HTML) $< > $@

HTML.html: HTML.pod
	$(POD2HTML) $< > $@
