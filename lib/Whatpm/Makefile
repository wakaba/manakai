POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot ".."
WGET = wget
CP = cp
RM = rm
RMALL = $(RM) -fr

LANGUAGE_SUBTAG_REGISTRY = language-subtag-registry
LANGUAGE_SUBTAG_REGISTRY_PM = _LangTagReg.pm

all: \
  _update \
  Charset-all CSS-all HTML-all XML-all \
  HTML/Tokenizer.pm \
  HTML.pm _NamedEntityList.pm _LinkTypeList.pm \
  ContentType.html HTML.html NanoDOM.html ContentChecker.html \
  CacheManifest.html WebIDL.html

Charset-all:
	cd Charset && make all

CSS-all:
	cd CSS && make all

HTML-all:
	cd HTML && make all

XML-all:
	cd XML && make all

update: update-remove-old _update

_update:_NamedEntityList.pm _LinkTypeList.pm \
  $(LANGUAGE_SUBTAG_REGISTRY_PM)

update-remove-old: update-_NamedEntityList.pm \
  update-_LinkTypeList.pm \
  update-$(LANGUAGE_SUBTAG_REGISTRY_PM)

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -I.. -c $@

HTML/Tokenizer.pm: HTML/Tokenizer.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -I.. -c $@

%.html: %.pm
	$(POD2HTML) $< > $@

HTML.html ContentChecker.html CacheManifest.html WebIDL.html:: %.html: %.pod
	$(POD2HTML) $< > $@

_NamedEntityList.pm: mkentitylist.pl Entities.html
	perl $< > $@.tmp
	perl -c -w $@.tmp
	$(CP) $@.tmp $@
	$(RMALL) $@.tmp

update-_NamedEntityList.pm:
	$(RMALL) Entities.html

Entities.html:
	$(WGET) -O $@ http://www.whatwg.org/specs/web-apps/current-work/multipage/named.html

_LinkTypeList.pm: mklinktypelist.pl RelExtensions.html
	perl $< > $@
	perl -c -w $@

update-_LinkTypeList.pm:
	$(RMALL) RelExtensions.html

RelExtensions.html:
	$(WGET) http://wiki.whatwg.org/wiki/RelExtensions -O $@

$(LANGUAGE_SUBTAG_REGISTRY):
	$(WGET) http://www.iana.org/assignments/language-subtag-registry -O $@

$(LANGUAGE_SUBTAG_REGISTRY_PM): $(LANGUAGE_SUBTAG_REGISTRY) mklangreg.pl
	perl mklangreg.pl $< > $@

update-$(LANGUAGE_SUBTAG_REGISTRY_PM):
	$(RMALL) $(LANGUAGE_SUBTAG_REGISTRY)

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
## $Date: 2008/10/14 02:27:58 $