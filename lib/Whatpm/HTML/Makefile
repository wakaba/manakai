POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."

HTML_FILES = Serializer.html Tokenizer.html ParserData.html Dumper.html

all: $(HTML_FILES) Tokenizer.pm Parser.pm

%.html: %.pod
	$(POD2HTML) $< > $@

ParserData.html:: %.html: %.pm
	$(POD2HTML) $< > $@

Tokenizer.pm Parser.pm:: %: %.src
	cd .. && $(MAKE) HTML/$@

## License: Public Domain.
