PM_FILES = Value.pm Perl.pm DNLite.pm \
  DISDump.pm DISDoc.pm Test.pm
DIS_PM_FILES = DIS/Value.pm DIS/Perl.pm DIS/DNLite.pm \
  DIS/DISDump.pm DIS/DISDoc.pm DIS/Test.pm

all: dummy
	cd .. && make $(DIS_PM_FILES)

$(PM_FILES): %: dummy
	cd .. && make DIS/$@

dummy:

clean:
	cd .. && make clean

## $Date: 2005/11/16 10:07:14 $
## License: Public Domain.
