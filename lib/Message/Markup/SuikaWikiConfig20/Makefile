POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../../.."
HTML_FILES = Node.html Parser.html

all: $(HTML_FILES)

%.html: %.pm
	$(POD2HTML) $< > $@

## License: Public Domain.
