POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot ".."
WGET = wget
CP = cp
RM = rm
RMALL = $(RM) -fr

all: CSS-all \
  HTML.pm _NamedEntityList.pm _LinkTypeList.pm \
  ContentType.html HTML.html NanoDOM.html ContentChecker.html

CSS-all:
	cd CSS && make all

update: update-remove-old _NamedEntityList.pm _LinkTypeList.pm

update-remove-old: update-_NamedEntityList.pm \
  update-_LinkTypeList.pm

HTML.pm: HTML.pm.src mkhtmlparser.pl
	perl mkhtmlparser.pl $< > $@
	perl -c $@

%.html: %.pm
	$(POD2HTML) $< > $@

HTML.html ContentChecker.html:: %.html: %.pod
	$(POD2HTML) $< > $@

_NamedEntityList.pm: mkentitylist.pl Entities.html
	perl $< > $@.tmp
	perl -c -w $@.tmp
	$(CP) $@.tmp $@
	$(RMALL) $@.tmp

update-_NamedEntityList.pm:
	$(RMALL) Entities.html

Entities.html:
	$(WGET) -O $@ http://www.whatwg.org/specs/web-apps/current-work/multipage/section-entities.html

_LinkTypeList.pm: mklinktypelist.pl RelExtensions.html
	perl $< > $@
	perl -c -w $@

update-_LinkTypeList.pm:
	$(RMALL) RelExtensions.html

RelExtensions.html:
	$(WGET) http://wiki.whatwg.org/wiki/RelExtensions -O $@

clean: CSS-clean
	$(RMALL) *~ *.bak *.tmp

CSS-clean:
	cd CSS && make clean

## License: Public Domain.
## $Date: 2007/10/17 10:46:26 $
