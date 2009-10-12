all: Parser.pm

Parser.pm: Parser.pm.src ../mkhtmlparser.pl
	perl ../mkhtmlparser.pl $< > $@
	perl -I../.. -c $@

clean:
	rm -frv *~ *.BAK .*~ .*.BAK
