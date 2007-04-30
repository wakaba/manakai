all: HTML.pm ContentType.html

%.html: %.pm
	pod2html --css "http://suika.fam.cx/www/style/html/pod.css" $< > $@

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -c $@
