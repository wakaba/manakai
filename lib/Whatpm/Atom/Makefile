POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."

HTML_FILES = Aggregator.html

all: $(HTML_FILES)

%.html: %.pod
	$(POD2HTML) $< > $@

## License: Public Domain.
