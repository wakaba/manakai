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

all: 
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) all
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) all

clean:
	$(RMALL) *~ .*~ *.BAK .*.BAK
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) clean
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) clean

clean-db:
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) clean-db
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) clean-db

distclean:
	$(RMALL) *~ .*~ *.BAK .*.BAK
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) distclean
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) distclean

## $Date: 2006/03/31 16:44:23 $
## License: Public Domain.
