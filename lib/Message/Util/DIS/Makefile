PM_FILES = Value.pm Perl.pm DNLite.pm \
  DISDump.pm DISDoc.pm
DIS_PM_FILES = DIS/Value.pm DIS/Perl.pm DIS/DNLite.pm \
  DIS/DISDump.pm DIS/DISDoc.pm

all: dummy
	cd .. && make $(DIS_PM_FILES)

$(PM_FILES): %: dummy
	cd .. && make DIS/$@

dummy:

clean:
	cd .. && make clean

## $Date: 2005/09/25 14:53:05 $
## License: Public Domain.
