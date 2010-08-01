POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."

HTML_FILES = Serializer.html

all: $(HTML_FILES) Tokenizer.pm

%.html: %.pod
	$(POD2HTML) $< > $@

Tokenizer.pm: Tokenizer.pm.src
	cd .. && make HTML/Tokenizer.pm

## License: Public Domain.
