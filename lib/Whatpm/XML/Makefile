POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."

HTML_FILES = Parser.html

all: Parser.pm

%.html: %.pod
	$(POD2HTML) $< > $@

Parser.pm: Parser.pm.src ../mkhtmlparser.pl
	perl ../mkhtmlparser.pl $< > $@
	perl -I../.. -c $@

clean:
	rm -frv *~ *.BAK .*~ .*.BAK
