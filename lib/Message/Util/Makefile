POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."
POD2HTML2 = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../../.."

MANAKAI_ROOT_DIR = ../../../
MANAKAI_LIB_DIR = $(MANAKAI_ROOT_DIR)lib/

CD = cd
MAKE = make
RM = rm
RMALL = $(RM) -fv
PERL = perl
PERL_OPTIONS =
PERL_OPTIONS_ALL = $(PERL_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_ = $(PERL) $(PERL_OPTIONS_ALL)
PERLC = $(PERL) -c -w
PERLC_OPTIONS = 
PERLC_OPTIONS_ALL = $(PERLC_OPTIONS) -I$(MANAKAI_LIB_DIR)
PERL_CHK = $(PERLC) $(PERLC_OPTIONS_ALL)
TOUCH = touch

HTML_FILES = Error.html \
  Formatter/Base.html Formatter/Boolean.html Formatter/Text.html \
  HostPermit.html QName/Filter.html

GENERATED_FILES = $(HTML_FILES)

all: $(GENERATED_FILES)

Error.html:: %.html: %.pod
	$(POD2HTML) $< > $@	

%.html: %.pm
	$(POD2HTML) $< > $@	

Formatter/%.html: %.pm
	$(POD2HTML2) $< > $@	

clean:
	$(RMALL) $(GENERATED_FILES)
	$(RMALL) *.tmp .*.tmp *~ .*~
	$(RMALL) Error/*~ Error/.*~
	$(RMALL) Formatter/*~ Formatter/.*~

distclean: clean

## $Date: 2007/08/25 07:02:11 $
## License: Public Domain.
