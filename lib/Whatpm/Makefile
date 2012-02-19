POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot ".."
POD2HTML_SUB = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."
WGET = wget
CP = cp
RM = rm
RMALL = $(RM) -fr

LANGUAGE_SUBTAG_REGISTRY = language-subtag-registry
LANGUAGE_TAGEXT_REGISTRY = language-tag-extensions-registry
LANGUAGE_SUBTAG_REGISTRY_PM = _LangTagReg.pm
LANGUAGE_SUBTAG_REGISTRY_FULL_PM = _LangTagReg_Full.pm

LANGTAG_XML_FILES = \
  ../../data/langtag/cldr-bcp47/calendar.xml \
  ../../data/langtag/cldr-bcp47/collation.xml \
  ../../data/langtag/cldr-bcp47/currency.xml \
  ../../data/langtag/cldr-bcp47/number.xml \
  ../../data/langtag/cldr-bcp47/timezone.xml \
  ../../data/langtag/cldr-bcp47/variant.xml \
  ../../data/langtag/cldr-bcp47/transform.xml

all: \
  _update \
  Atom-all Charset-all CSS-all HTML-all XML-all ContentChecker-all \
  HTML/Tokenizer.pm \
  HTML.pm _NamedEntityList.pm _LinkTypeList.pm \
  ContentType.html HTML.html NanoDOM.html ContentChecker.html \
  CacheManifest.html WebIDL.html mklinktypelist.html \
  SWML/Parser.html LangTag.html

Atom-all:
	cd Atom && make all

Charset-all:
	cd Charset && make all

CSS-all:
	cd CSS && make all

HTML-all:
	cd HTML && make all

XML-all:
	cd XML && make all

ContentChecker-all:
	cd ContentChecker && make all

update: update-remove-old _update update-http

_update:_NamedEntityList.pm _LinkTypeList.pm \
  $(LANGUAGE_SUBTAG_REGISTRY_PM) \
  $(LANGUAGE_SUBTAG_REGISTRY_FULL_PM)

update-remove-old: update-_NamedEntityList.pm \
  update-_LinkTypeList.pm \
  update-$(LANGUAGE_SUBTAG_REGISTRY_PM)

update-http:
	cd HTTP && make update

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -I.. -c $@

HTML/Tokenizer.pm: HTML/Tokenizer.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -I.. -c $@

%.html: %.pm
	$(POD2HTML) $< > $@

HTML.html ContentChecker.html CacheManifest.html WebIDL.html LangTag.html:: %.html: %.pod
	$(POD2HTML) $< > $@

SWML/Parser.html:: %.html: %.pod
	$(POD2HTML_SUB) $< > $@

mklinktypelist.html: mklinktypelist.pl
	$(POD2HTML) $< > $@
	perl -n -i -e 's/%s/[gmtime]->[5]+1900/ge; print' $@

_NamedEntityList.pm: mkentitylist.pl Entities.html
	perl $< > $@.tmp
	perl -c -w $@.tmp
	$(CP) $@.tmp $@
	$(RMALL) $@.tmp

update-_NamedEntityList.pm:
	$(RMALL) Entities.html

Entities.html:
	$(WGET) -O $@ http://www.whatwg.org/specs/web-apps/current-work/multipage/named-character-references.html

_LinkTypeList.pm: mklinktypelist.pl RelExtensions.html
	perl $< > $@
	perl -c -w $@

update-_LinkTypeList.pm:
	$(RMALL) RelExtensions.html

RelExtensions.html:
	$(WGET) http://wiki.whatwg.org/wiki/RelExtensions -O $@

$(LANGUAGE_SUBTAG_REGISTRY):
	$(WGET) http://www.iana.org/assignments/language-subtag-registry -O $@
$(LANGUAGE_TAGEXT_REGISTRY):
	$(WGET) http://www.iana.org/assignments/language-tag-extensions-registry -O $@

$(LANGUAGE_SUBTAG_REGISTRY_PM): $(LANGUAGE_SUBTAG_REGISTRY) mklangreg.pl \
  langtag-data $(LANGTAG_XML_FILES)
	perl mklangreg.pl $< $(LANGTAG_XML_FILES) > $@

$(LANGUAGE_SUBTAG_REGISTRY_FULL_PM): \
  $(LANGUAGE_SUBTAG_REGISTRY) $(LANGUAGE_TAGEXT_REGISTRY) mklangreg.pl \
  langtag-data $(LANGTAG_XML_FILES)
	MKLANGREG_FULL=1 perl mklangreg.pl $< $(LANGUAGE_TAGEXT_REGISTRY) \
	  $(LANGTAG_XML_FILES) > $@

langtag-data:
	cd ../../data && make langtag

update-langtag: update-$(LANGUAGE_SUBTAG_REGISTRY_PM) \
  $(LANGUAGE_SUBTAG_REGISTRY_PM) $(LANGUAGE_SUBTAG_REGISTRY_FULL_PM)

update-$(LANGUAGE_SUBTAG_REGISTRY_PM): update-langtag-data
	$(RMALL) $(LANGUAGE_SUBTAG_REGISTRY)

update-langtag-data:
	cd ../../data && make langtag/update

dataautoupdate: \
  update-$(LANGUAGE_SUBTAG_REGISTRY_PM) \
  $(LANGUAGE_SUBTAG_REGISTRY_PM) $(LANGUAGE_SUBTAG_REGISTRY_FULL_PM) \
  dataautoupdate-http
	git add \
	    $(LANGUAGE_SUBTAG_REGISTRY_PM) \
	    $(LANGUAGE_SUBTAG_REGISTRY_FULL_PM)

dataautoupdate-http:
	cd HTTP && make dataautoupdate

clean: Charset-clean CSS-clean HTML-clean XML-clean
	$(RMALL) *~ *.bak *.tmp
	$(RMALL) $(LANGUAGE_SUBTAG_REGISTRY)

Charset-clean:
	cd Charset && make clean

CSS-clean:
	cd CSS && make clean

HTML-clean:
	cd HTML && make clean

XML-clean:
	cd XML && make clean

## License: Public Domain.
