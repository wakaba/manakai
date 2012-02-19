WGET = wget

all: _update

update: update-delete _update

update-delete:
	rm http-status-codes.xml

_update: _StatusCodes.pm

_StatusCodes.pm: http-status-codes.xml mkstatuscodelist.pl
	perl mkstatuscodelist.pl $< > $@
	perl -c $@

dataautoupdate: update dataautoupdate-git

dataautoupdate-git:
	git add _StatusCodes.pm

http-status-codes.xml:
	$(WGET) http://www.iana.org/assignments/http-status-codes/http-status-codes.xml

## License: Public Domain.