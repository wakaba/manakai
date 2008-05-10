POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot ".."
WGET = wget
CP = cp
RM = rm
RMALL = $(RM) -fr

all: Charset-all CSS-all HTML-all \
  HTML.pm _NamedEntityList.pm _LinkTypeList.pm \
  ContentType.html HTML.html NanoDOM.html ContentChecker.html \
  CacheManifest.html

Charset-all:
	cd Charset && make all

CSS-all:
	cd CSS && make all

HTML-all:
	cd HTML && make all

update: update-remove-old _NamedEntityList.pm _LinkTypeList.pm

update-remove-old: update-_NamedEntityList.pm \
  update-_LinkTypeList.pm

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -c $@

%.html: %.pm
	$(POD2HTML) $< > $@

HTML.html ContentChecker.html CacheManifest.html:: %.html: %.pod
	$(POD2HTML) $< > $@

_NamedEntityList.pm: mkentitylist.pl Entities.html
	perl $< > $@.tmp
	perl -c -w $@.tmp
	$(CP) $@.tmp $@
	$(RMALL) $@.tmp

update-_NamedEntityList.pm:
	$(RMALL) Entities.html

Entities.html:
	$(WGET) -O $@ http://www.whatwg.org/specs/web-apps/current-work/multipage/section-named.html

_LinkTypeList.pm: mklinktypelist.pl RelExtensions.html
	perl $< > $@
	perl -c -w $@

update-_LinkTypeList.pm:
	$(RMALL) RelExtensions.html

RelExtensions.html:
	$(WGET) http://wiki.whatwg.org/wiki/RelExtensions -O $@

clean: Charset-clean CSS-clean HTML-clean
	$(RMALL) *~ *.bak *.tmp

Charset-clean:
	cd Charset && make clean

CSS-clean:
	cd CSS && make clean

HTML-clean:
	cd HTML && make clean

## License: Public Domain.
## $Date: 2008/05/10 12:13:43 $
