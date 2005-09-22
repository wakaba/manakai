MANAKAI_ROOT_DIR = ../
MANAKAI_LIB_DIR  = $(MANAKAI_ROOT_DIR)lib/
MANAKAI_BIN_DIR  = $(MANAKAI_ROOT_DIR)bin/

MKDIR = mkdir
RM = rm
MAKE = make
CD = cd
CP = cp
ECHO = -echo

all: 
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) all
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) all

clean:
	$(RM) -fv *~ .*~ *.BAK .*.BAK
	$(CD) $(MANAKAI_LIB_DIR)manakai/ && $(MAKE) clean
	$(CD) $(MANAKAI_LIB_DIR)Message/ && $(MAKE) clean

## $Date: 2005/09/22 14:25:46 $
## License: Public Domain.
