POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "."
MANAKAI_ROOT_DIR = ../
MANAKAI_LIB_DIR  = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_BIN_DIR  = $(MANAKAI_ROOT_DIR)bin/

MKDIR = mkdir
RM = rm
RMALL = $(RM) -fv
MAKE = make
CD = cd
CP = cp
ECHO = -echo

all: Error.html
	$(CD) $(MANAKAI_LIB_DIR)Message/Util/AutoLoad/ && $(MAKE) all
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) all
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) all

%.html: %.pm
	$(POD2HTML) $< > $@

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK *.tmp .*.tmp
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) clean
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) clean

clean-db:
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) clean-db
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) clean-db

distclean:
	$(RMALL) *~ .*~ *.BAK .*.BAK
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) distclean
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) distclean
	$(RM) Error.html

## $Date: 2007/07/29 07:25:06 $
## License: Public Domain.
