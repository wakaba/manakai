WGET = wget

all: _update

update: update-delete _update

update-delete:
	rm -f http-status-codes.xml http-methods.xml

dataautoupdate: update dataautoupdate-git

dataautoupdate-git:
	git add _StatusCodes.pm _Methods.pm

_update: _StatusCodes.pm _Methods.pm

_StatusCodes.pm: http-status-codes.xml mkstatuscodelist.pl
	perl mkstatuscodelist.pl $< > $@
	perl -c $@

_Methods.pm: http-methods.xml mkmethodlist.pl
	perl mkmethodlist.pl $< > $@
	perl -c $@

http-status-codes.xml:
	$(WGET) -O $@ http://www.iana.org/assignments/http-status-codes/http-status-codes.xml

http-methods.xml:
	$(WGET) -O $@ https://suika.suikawiki.org/~wakaba/wiki/sw/n/HTTP%20method?format=xml

## License: Public Domain.
