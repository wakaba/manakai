all: langtag

update: langtag/update

langtag: langtag/cldr-bcp47

langtag/update: langtag/cldr-bcp47/update

langtag/cldr-bcp47:
	mkdir -p langtag
	svn co http://www.unicode.org/repos/cldr/trunk/common/bcp47 $@

langtag/cldr-bcp47/update: langtag/cldr-bcp47
	cd langtag/cldr-bcp47 && svn update

always:

## License: Public domain.
