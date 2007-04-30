WGET = wget
MKDIR = mkdir

all: tokenizer-files tree-construction-files

tokenizer-files: tokenizer \
  tokenizer/test1.test tokenizer/test2.test tokenizer/contentModelFlags.test

tokenizer:
	$(MKDIR) $@

tokenizer/%.test:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/tests/$@

tree-construction-files: tree-construction \
  tree-construction/tests1.dat \
  tree-construction/tests2.dat \
  tree-construction/tests3.dat \
  tree-construction/tests4.dat

tree-construction:
	$(MKDIR) $@

tree-construction/%.dat:
	$(WGET) -O $@ http://html5lib.googlecode.com/svn/trunk/tests/$@

## License: Public Domain.
## $Date: 2007/04/30 14:12:02 $
