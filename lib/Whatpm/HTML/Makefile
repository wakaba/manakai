POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."

HTML_FILES = Serializer.html

all: $(HTML_FILES)

%.html: %.pod
	$(POD2HTML) $< > $@

## License: Public Domain.
## $Date: 2007/11/11 04:59:36 $
